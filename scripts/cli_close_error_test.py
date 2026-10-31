#!/usr/bin/env python3
"""Process-local read/close fault regression. Real close occurs before injected EIO."""
from pathlib import Path
import subprocess, tempfile, os, json, hashlib
ROOT=Path(__file__).resolve().parents[1]
subprocess.run(['scripts/moon-local.sh','build','--target','js','-j','1','-d'],cwd=ROOT,check=True)
with tempfile.TemporaryDirectory(prefix='abnf-close-error-') as tmp:
 p=Path(tmp); files={'g.abnf':b's = %s"A"\r\n','a':b'A','target':b'A','z':b'A'}
 for name,data in files.items(): (p/name).write_bytes(data)
 for stage in ['grammar','input']:
  for mode in ['none','read','close','both']:
   target=p/('g.abnf' if stage=='grammar' else 'target')
   cmd=['node','--require',str(ROOT/'scripts/cli_fs_fault.cjs'),str(ROOT/'_build/js/debug/build/cmd/main/main.js'),'batch',str(p/'g.abnf'),'s',str(p/'a'),str(p/'target'),str(p/'z')]
   r=subprocess.run(cmd,cwd=ROOT,env=os.environ|{'REVIEW_FAULT_TARGET':str(target),'REVIEW_FAULT_MODE':mode},text=True,capture_output=True,timeout=10)
   rows=[json.loads(x) for x in r.stdout.splitlines()]
   expected=['matched']*3 if mode=='none' else (['io-error'] if stage=='grammar' else ['matched','io-error','matched'])
   assert [x['status'] for x in rows]==expected,(stage,mode,r.stdout,r.stderr)
   assert r.returncode==(0 if mode=='none' else 2),(stage,mode,r.returncode)
   if mode!='none':
    row=rows[0 if stage=='grammar' else 1];assert row['stage']==stage and row['file']==str(target)
   assert ('INJECTED_READ_EIO' in r.stderr)==(mode in ['read','both'])
   assert ('INJECTED_CLOSE_EIO' in r.stderr)==(mode in ['close','both'])
   assert 'LEAKED_FDS' not in r.stderr
   for name,data in files.items():assert (p/name).read_bytes()==data
   print(json.dumps({'stage':stage,'mode':mode,'exit':r.returncode,'rows':len(rows)}))

#!/usr/bin/env python3
"""Actual shell I/O failures remain ordered, structured, bounded and nonzero."""
import json,os,shutil,subprocess,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix='abnf-io-json-') as tmp:
 p=Path(tmp);root=p/'source';shutil.copytree(ROOT,root,ignore=shutil.ignore_patterns('.git','_build','target','.mooncakes','.toolchains','__pycache__','evidence'))
 grammar=p/'g.abnf';grammar.write_bytes(b'x = 1*DIGIT\r\n');yes=p/'yes';yes.write_bytes(b'123');bad=p/'bad';bad.write_bytes(b'abc');missing=p/'missing';fifo=p/'fifo';os.mkfifo(fifo);large=p/'large';large.write_bytes(b'1'*65537)
 cases=[('cold-grammar-missing',['check',missing],2,['io-error']),('grammar-directory',['check',p],2,['io-error']),('grammar-fifo',['check',fifo],2,['io-error']),('input-missing',['match',grammar,'x',missing],2,['io-error']),('input-directory',['match',grammar,'x',p],2,['io-error']),('input-fifo',['match',grammar,'x',fifo],2,['io-error']),('ordered-batch',['batch',grammar,'x',yes,missing,bad,yes],2,['matched','io-error','no-match','matched']),('budget-before-io',['batch',grammar,'x',large,missing,yes],3,['budget-exceeded:input-bytes','io-error','matched']),('io-before-budget',['batch',grammar,'x',missing,large,yes],3,['io-error','budget-exceeded:input-bytes','matched']),('repeat-hot-batch',['batch',grammar,'x',yes,missing,yes],2,['matched','io-error','matched'])]
 for label,args,code,statuses in cases:
  q=subprocess.run(['sh','scripts/cli.sh',*map(str,args)],cwd=root,text=True,capture_output=True,timeout=180)
  rows=[json.loads(line) for line in q.stdout.splitlines()];assert q.returncode==code,(label,q.returncode,q.stderr);assert [r['status'] for r in rows]==statuses,(label,rows);assert 'I/O:' in q.stderr,(label,q.stderr)
  for row in rows:
   if row['status']=='io-error':assert row['stage'] in ('grammar','input') and 'file' in row and 'offset' not in row
  print(json.dumps({'case':label,'exit':q.returncode,'rows':len(rows)}))

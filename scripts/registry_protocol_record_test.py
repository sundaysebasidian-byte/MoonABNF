#!/usr/bin/env python3
"""Replay the existing JS protocol contract against an exact registry release, never a workspace."""
import argparse, hashlib, json, os, re, time
from pathlib import Path
from bounded_run import execute
from consumer_contract import registry_version
ROOT=Path(__file__).resolve().parents[1]
def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--output',required=True,type=Path);p.add_argument('--release-version',default='0.2.0',type=registry_version);a=p.parse_args();out=a.output.resolve();version=a.release_version
 if out.exists() or out==ROOT or ROOT in out.parents:p.error('Use a new output directory outside the source tree')
 for parent in [out,*out.parents]:
  if any((parent/name).exists() for name in ['moon.work','moon.work.json']):p.error('Output ancestry must not contain a workspace')
 sdk=os.environ.get('MOONABNF_SDK') or os.environ.get('MOON_HOME')
 if not sdk:p.error('Set the existing trusted MOONABNF_SDK')
 out.mkdir(parents=True);consumer=out/'consumer';consumer.mkdir();templates=ROOT/'integration/protocol_consumer';hashes={};generated={};golden=(templates/'expected-record.json').read_bytes();hashes['expected-record.json']=hashlib.sha256(golden).hexdigest()
 for name in ['moon.mod','moon.pkg','main.mbt','contract_wbtest.mbt']:
  data=(templates/(name+'.in')).read_text();hashes[name]=hashlib.sha256(data.encode()).hexdigest()
  if name=='moon.mod':data=re.sub(r'moonabnf@\d+\.\d+\.\d+','moonabnf@'+version,data)
  (consumer/name).write_text(data);generated[name]=hashlib.sha256(data.encode()).hexdigest()
 env=dict(os.environ,MOON_HOME=sdk,RUST_LOG='error');env['PATH']=sdk+'/bin:'+env['PATH'];moon=sdk+'/bin/moon';started=time.monotonic();rows=[];report={'status':'failed','version':version,'scope':'registry-only JS application adapter; not root JSON API','commands':rows,'template_sha256':hashes,'generated_consumer_sha256':generated}
 def run(name,args,expected=0):
  remaining=120-(time.monotonic()-started)
  if remaining<=0:raise RuntimeError('120 second total deadline')
  row=execute([moon,*args],consumer,out,name,env,seconds=remaining);rows.append(row)
  if row['stop_reason'] or row['exit_code']!=expected:raise RuntimeError(name+' failed; logs retained')
  row['status']='passed';return (out/(name+'.stdout.txt')).read_text()
 try:
  run('registry-update',['update'])
  tree=json.loads(run('tree',['tree','--json']));module=next(m for m in tree['modules'] if m['name']=='sundaysebasidian-byte/moonabnf')
  if module['version']!=version or module['source']['kind']!='registry' or module['workspace_member']:raise RuntimeError('Registry dependency substituted')
  report['resolution']=module
  run('registry-install',['build','--target','js','-j','1']);run('check',['check','--target','js','--frozen','-j','1'])
  tests=run('contracts',['test','contract_wbtest.mbt','--target','js','--frozen','-j','1'])
  if 'Total tests: 4, passed: 4, failed: 0.' not in tests:raise RuntimeError('Contracts were not executed')
  base=['run','.','--target','js','--frozen','-j','1','--','--json']
  actual=json.loads(run('accept',base+['http://www.ietf.org/rfc/rfc2396.txt','SID=31d4d96e407aad42; lang=en-US']))
  if actual!=json.loads(golden):raise RuntimeError('Golden mismatch')
  for name,args,code,decision in [('reject',['http://example.test/%GG','a=bad value'],1,'reject'),('budget',['/ok','a=b','1'],3,'defer'),('config',['/ok','a=b','0'],2,'invalid-node-budget')]:
   d=json.loads(run(name,base+args,code))
   if d['decision']!=decision or (name in ['reject','budget'] and (d['components'] or d['cookies'])):raise RuntimeError('Decision/field isolation failed')
  for name,digest in generated.items():
   if hashlib.sha256((consumer/name).read_bytes()).hexdigest()!=digest:raise RuntimeError('Consumer mutated: '+name)
  report['status']='passed'
 except Exception as error:report['error']=str(error)
 (out/'summary.json').write_text(json.dumps(report,indent=2));print(json.dumps({'status':report['status'],'commands':[(r['name'],r['exit_code']) for r in rows]}));return 0 if report['status']=='passed' else 1
if __name__=='__main__':raise SystemExit(main())

#!/usr/bin/env python3
"""Five fresh benchmark processes; warm build cache, not a cold-machine claim."""
import argparse,json,os,platform,subprocess,hashlib,re
from pathlib import Path
from bounded_run import execute
ROOT=Path(__file__).resolve().parents[1]
def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--output',type=Path,required=True);a=p.parse_args();out=a.output.resolve()
 if out.exists() or ROOT in out.parents:p.error('Use a new external output directory')
 sdk=os.environ.get('MOONABNF_SDK') or os.environ.get('MOON_HOME')
 if not sdk:p.error('Set existing SDK')
 out.mkdir(parents=True);env=dict(os.environ,MOON_HOME=sdk,RUST_LOG='error');env['PATH']=sdk+'/bin:'+env['PATH'];moon=sdk+'/bin/moon'
 meta={'scope':'five separate benchmark processes, each contains five adaptive groups; no p95','machine':platform.platform(),'architecture':platform.machine(),'sdk':subprocess.check_output([moon,'version','--all'],env=env,text=True),'node':subprocess.check_output(['node','--version'],env=env,text=True),'cache':'release artifact prebuilt once; filesystem cache not flushed; each process starts fresh runtime/JIT and performs its own adaptive warm-up','workload_source_sha256':hashlib.sha256((ROOT/'benchmarks/workloads_test.mbt').read_bytes()).hexdigest(),'trials':[]}
 meta['grammar_sha256']={str(f.relative_to(ROOT)):hashlib.sha256(f.read_bytes()).hexdigest() for f in (ROOT/'fixtures/protocols').glob('*.abnf')}
 meta['inputs']={'uri_hex':b'https://[2001:db8::1]:8443/a%20b?q=1#top'.hex(),'cookie_hex':b'session=abc; theme="dark"; empty='.hex(),'binary':{'length':4096,'repeated_octet':255,'sha256':hashlib.sha256(bytes([255])*4096).hexdigest()}}
 meta['hardware']=subprocess.check_output(['sysctl','-n','hw.model','hw.memsize','hw.logicalcpu'],text=True).splitlines() if platform.system()=='Darwin' else 'see platform'
 command=[moon,'bench','benchmarks','--target','js','--release','--frozen','--no-parallelize','-j','1']
 build=execute([*command,'--build-only'],ROOT,out,'prebuild',env);meta['prebuild']=build
 if build['status']!='passed':(out/'summary.json').write_text(json.dumps(meta,indent=2));return 1
 for i in range(1,6):
  row=execute(command,ROOT,out,'trial-'+str(i),env);row['trial']=i;row['means_us']={}
  text=(out/('trial-'+str(i)+'.stdout.txt')).read_text()
  for line in text.splitlines():
   match=re.match('^(compile_\\S+|recognize_\\S+|tree_\\S+)\\s+(\\d+(?:\\.\\d+)?)\\s+(ns|µs|ms)\\s',line)
   if match:row['means_us'][match[1]]=float(match[2])*{'ns':.001,'µs':1,'ms':1000}[match[3]]
  required={'compile_cookie','compile_uri','compile_binary','recognize_uri_ipv6_40B','tree_uri_ipv6_40B','recognize_binary_4096B','tree_binary_4096B'}
  if not required <= row['means_us'].keys():row['status']='failed-missing-metrics'
  meta['trials'].append(row);(out/'summary.json').write_text(json.dumps(meta,indent=2));print('trial',i,row['status'],flush=True)
  if row['status']!='passed':return 1
 meta['status']='passed';meta['summary_of_independent_means_us']={k:{'min':min(t['means_us'][k] for t in meta['trials']),'max':max(t['means_us'][k] for t in meta['trials'])} for k in meta['trials'][0]['means_us']};(out/'summary.json').write_text(json.dumps(meta,indent=2));return 0
if __name__=='__main__':raise SystemExit(main())

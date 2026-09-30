#!/usr/bin/env python3
"""Sequential, low-concurrency acceptance with raw stdout/stderr and exit codes."""
import argparse
import hashlib
import json
import platform
import subprocess
import time
from datetime import datetime, timezone
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--output', type=Path, default=ROOT / 'evidence' / 'acceptance')
args = parser.parse_args()
out = args.output.resolve(); out.mkdir(parents=True, exist_ok=True)
commands = [
 ('toolchain', ['scripts/moon-local.sh', 'version', '--all']),
 ('format', ['scripts/moon-local.sh', 'fmt', '--check']),
 ('check-wasm', ['scripts/moon-local.sh', 'check', '--target', 'wasm', '-j', '1', '-d']),
 ('build-wasm', ['scripts/moon-local.sh', 'build', '--target', 'wasm', '-j', '1', '-d']),
 ('test-wasm', ['scripts/moon-local.sh', 'test', '--target', 'wasm', '-j', '1', '-d']),
 ('check-js', ['scripts/moon-local.sh', 'check', '--target', 'js', '-j', '1', '-d']),
 ('build-js', ['scripts/moon-local.sh', 'build', '--target', 'js', '-j', '1', '-d']),
 ('test-js', ['scripts/moon-local.sh', 'test', '--target', 'js', '-j', '1', '-d']),
 ('check-native', ['scripts/moon-local.sh', 'check', '--target', 'native', '-j', '1', '-d']),
 ('build-native', ['scripts/moon-local.sh', 'build', '--target', 'native', '-j', '1', '-d']),
 ('test-native', ['scripts/moon-local.sh', 'test', '--target', 'native', '-j', '1', '-d']),
 ('test-wasm-gc', ['scripts/moon-local.sh', 'test', '--target', 'wasm-gc', '-j', '1', '-d']),
 ('examples', ['scripts/moon-local.sh', 'run', 'examples', '-j', '1']),
 ('cli', ['python3', 'scripts/cli_test.py']),
 ('differential', ['python3', 'scripts/differential.py']),
]
records = []
for name, command in commands:
    start = time.monotonic()
    r = subprocess.run(command, cwd=ROOT, capture_output=True, text=True, timeout=120)
    (out / f'{name}.stdout.txt').write_text(r.stdout)
    (out / f'{name}.stderr.txt').write_text(r.stderr)
    record = {'name':name, 'command':command, 'exit_code':r.returncode,
              'status':'passed' if r.returncode == 0 else 'failed',
              'elapsed_seconds':round(time.monotonic() - start, 3)}
    records.append(record)
    print(f'{name}: {record["status"]} ({record["elapsed_seconds"]}s)', flush=True)
    if r.returncode != 0: print(r.stdout + r.stderr, flush=True)
sha = subprocess.run(['git','rev-parse','HEAD'], cwd=ROOT, capture_output=True, text=True).stdout.strip()
dirty = subprocess.run(['git','status','--porcelain'], cwd=ROOT, capture_output=True, text=True).stdout
summary = {'time_utc':datetime.now(timezone.utc).isoformat(), 'host':platform.platform(),
           'git_head_at_run':sha, 'working_tree_at_run':dirty,
           'status':'passed' if all(r['exit_code'] == 0 for r in records) else 'failed',
           'commands':records, 'not_tested':['remote GitHub CI', 'registry installation', 'Linux/Windows execution', 'third-party complete ABNF parser differential']}
(out / 'summary.json').write_text(json.dumps(summary, ensure_ascii=False, indent=2))
manifest = {p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(out.iterdir()) if p.is_file() and p.name != 'SHA256.json'}
(out / 'SHA256.json').write_text(json.dumps(manifest, indent=2))
raise SystemExit(0 if summary['status'] == 'passed' else 1)

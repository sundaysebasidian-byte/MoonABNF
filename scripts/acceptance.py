#!/usr/bin/env python3
"""Sequential, low-concurrency acceptance with raw stdout/stderr and exit codes."""
import argparse
import hashlib
import json
import platform
import os
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
 ('installer-guards', ['python3', '-m', 'unittest', 'discover', '-s', 'scripts', '-p', 'test_install_ci_sdk.py']),
 ('scalar-example', ['scripts/moon-local.sh', 'run', 'examples/scalar_prose', '--target', 'native']),
 ('consumer-guards', ['python3', '-m', 'unittest', 'discover', '-s', 'scripts', '-p', 'test_consumer*.py']),
 ('protocol-fixtures', ['python3', 'scripts/verify_protocol_fixtures.py']),
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
 ('example-request-line', ['python3', 'scripts/example_request_line.py', '--output', str(out / 'example-request-line')]),
 ('example-input-diagnostics', ['scripts/moon-local.sh', 'run', 'examples/diagnostics', '--target', 'js', '--frozen', '-j', '1']),
 ('cli', ['python3', 'scripts/cli_test.py']),
 ('shell-cli-json', ['python3', 'scripts/shell_cli_json_test.py']),
 ('cli-io-json', ['python3', 'scripts/cli_io_json_test.py']),
 ('cli-close-error', ['python3', 'scripts/cli_close_error_test.py']),
 ('diagnostic-cli', ['python3', 'scripts/diagnostic_cli_test.py']),
 ('differential', ['python3', 'scripts/differential.py']),
 ('downstream', ['python3', 'scripts/downstream.py', '--output', str(out / 'downstream')]),
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
source_hashes = {str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest()
    for p in sorted(ROOT.rglob('*')) if p.is_file() and '.git' not in p.parts and '_build' not in p.parts and 'evidence' not in p.parts and 'recheck-evidence' not in p.parts and '.toolchains' not in p.parts and '__pycache__' not in p.parts}
sha = subprocess.run(['git','rev-parse','HEAD'], cwd=ROOT, capture_output=True, text=True).stdout.strip()
dirty = subprocess.run(['git','status','--porcelain'], cwd=ROOT, capture_output=True, text=True).stdout
summary = {'time_utc':datetime.now(timezone.utc).isoformat(), 'host':platform.platform(),
           'git_head_at_run':sha, 'working_tree_at_run':dirty,
           'status':'passed' if all(r['exit_code'] == 0 for r in records) else 'failed',
           'source_sha256':source_hashes, 'commands':records,
           'not_tested':['registry installation', 'Windows execution', 'third-party complete ABNF parser differential', 'Artemis interoperability', 'LibreOffice compatibility']
             + ([] if platform.system() == 'Linux' else ['Linux execution'])
             + ([] if os.getenv('GITHUB_ACTIONS') == 'true' else ['remote GitHub CI'])}
(out / 'summary.json').write_text(json.dumps(summary, ensure_ascii=False, indent=2))
manifest = {p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(out.iterdir()) if p.is_file() and p.name != 'SHA256.json'}
(out / 'SHA256.json').write_text(json.dumps(manifest, indent=2))
raise SystemExit(0 if summary['status'] == 'passed' else 1)

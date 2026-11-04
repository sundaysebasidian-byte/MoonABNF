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
from bounded_run import execute
ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--output', type=Path, default=ROOT / 'evidence' / 'acceptance')
args = parser.parse_args()
out = args.output.resolve()
if out.exists():
    parser.error('Use a new output directory; prior evidence is never reused or overwritten')
out.mkdir(parents=True, exist_ok=False)
source_metadata_errors = []


def source_snapshot(phase):
    """Bind both ends of the run; generated evidence is never source input."""
    hashes = {}
    excluded = {'.git', '_build', 'evidence', 'recheck-evidence',
                '.toolchains', '__pycache__'}

    def walk_error(error):
        source_metadata_errors.append({'phase': phase, 'path': error.filename,
                                       'error': type(error).__name__})

    for directory, dirs, files in os.walk(ROOT, onerror=walk_error):
        parent = Path(directory)
        dirs[:] = sorted(name for name in dirs
                         if name not in excluded and parent / name != out)
        for name in sorted(files):
            path = parent / name
            relative = str(path.relative_to(ROOT))
            try:
                if path.is_file():
                    hashes[relative] = hashlib.sha256(path.read_bytes()).hexdigest()
            except OSError as error:
                source_metadata_errors.append({'phase': phase, 'path': relative,
                                               'error': type(error).__name__})
    return hashes


source_before = source_snapshot('before')
commands = [
 ('toolchain', ['scripts/moon-local.sh', 'version', '--all']),
 ('format', ['scripts/moon-local.sh', 'fmt', '--check']),
 ('installer-guards', ['python3', '-m', 'unittest', 'discover', '-s', 'scripts', '-p', 'test_install_ci_sdk.py']),
 ('scalar-example', ['scripts/moon-local.sh', 'run', 'examples/scalar_prose', '--target', 'native']),
 ('consumer-guards', ['python3', '-m', 'unittest', 'discover', '-s', 'scripts', '-p', 'test_consumer*.py']),
 ('process-group-guards', ['python3', '-m', 'unittest', 'discover', '-s', 'scripts', '-p', 'test_bounded_run.py']),
 ('acceptance-evidence-guards', ['python3', '-m', 'unittest', 'discover', '-s', 'scripts', '-p', 'test_acceptance_evidence.py']),
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
    try:
        # Reuse the repository's task-owned process group runner. Direct log
        # files retain raw bytes and cannot hang on descendant-held pipe FDs.
        # Preserve acceptance's prior lack of a memory cap; retain RSS telemetry.
        record = execute(command, ROOT, out, name, seconds=120, rss_mib=None)
        if record['stop_reason'] == 'wall timeout':
            record['process_exit_code'] = record['exit_code']
            record['exit_code'] = 124
        record['status'] = 'passed' if record['status'] == 'passed' else 'failed'
    except (OSError, subprocess.SubprocessError) as error:
        # Includes launch errors and resource-monitor preflight failure.
        # Do not overwrite any partial logs that execute already created.
        for stream in ('stdout', 'stderr'):
            path = out / f'{name}.{stream}.txt'
            if not path.exists():
                path.write_bytes(b'')
        record = {'name': name, 'command': command, 'exit_code': 127,
                  'status': 'failed',
                  'stop_reason': 'runner failed: ' + type(error).__name__ + ': ' + str(error),
                  'elapsed_seconds': round(time.monotonic() - start, 3)}
    stdout = (out / f'{name}.stdout.txt').read_bytes()
    stderr = (out / f'{name}.stderr.txt').read_bytes()
    records.append(record)
    print(f'{name}: {record["status"]} ({record["elapsed_seconds"]}s)', flush=True)
    if record['status'] != 'passed': print((stdout + stderr).decode('utf-8', errors='replace'), flush=True)
source_hashes = source_snapshot('after')
source_changes = {
    'added': sorted(source_hashes.keys() - source_before.keys()),
    'removed': sorted(source_before.keys() - source_hashes.keys()),
    'modified': sorted(name for name in source_before.keys() & source_hashes.keys()
                       if source_before[name] != source_hashes[name]),
}
metadata_errors = []
def git_metadata(command):
    try:
        result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True,
                                errors='replace', timeout=5)
        if result.returncode != 0:
            metadata_errors.append({'command': command, 'error': 'nonzero exit',
                                    'exit_code': result.returncode})
        return result.stdout
    except (OSError, subprocess.TimeoutExpired) as error:
        metadata_errors.append({'command': command, 'error': type(error).__name__})
        return ''
sha = git_metadata(['git', 'rev-parse', 'HEAD']).strip()
dirty = git_metadata(['git', 'status', '--porcelain'])
summary = {'time_utc':datetime.now(timezone.utc).isoformat(), 'host':platform.platform(),
           'git_head_at_run':sha, 'working_tree_at_run':dirty,
           'status':'passed' if all(r['status'] == 'passed' for r in records) and not metadata_errors
                    and not source_metadata_errors and not any(source_changes.values()) else 'failed',
           'metadata_errors':metadata_errors,
           'source_binding_method':'before/after content snapshots, not an atomic filesystem snapshot',
           'source_sha256_before':source_before, 'source_sha256':source_hashes,
           'source_changes':source_changes, 'source_metadata_errors':source_metadata_errors,
           'commands':records,
           'not_tested':['registry installation', 'Windows execution', 'third-party complete ABNF parser differential', 'Artemis interoperability', 'LibreOffice compatibility']
             + ([] if platform.system() == 'Linux' else ['Linux execution'])
             + ([] if os.getenv('GITHUB_ACTIONS') == 'true' else ['remote GitHub CI'])}
(out / 'summary.json').write_text(json.dumps(summary, ensure_ascii=False, indent=2))
manifest = {p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(out.iterdir()) if p.is_file() and p.name != 'SHA256.json'}
(out / 'SHA256.json').write_text(json.dumps(manifest, indent=2))
raise SystemExit(0 if summary['status'] == 'passed' else 1)

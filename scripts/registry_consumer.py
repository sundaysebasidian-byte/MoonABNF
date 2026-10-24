#!/usr/bin/env python3
"""Verify an exact published release in a fresh registry-only downstream module.

Run after publication. Uses the normal MoonBit package manager and its supported
authentication; never reads credentials. Does not publish or use a moon.work.
"""
import argparse
import hashlib
import json
import re
import subprocess
import tempfile
from pathlib import Path
from consumer_contract import registry_version, require

ROOT = Path(__file__).resolve().parents[1]
manifest = (ROOT / 'moon.mod').read_text()
MODULE = re.search(r'^name\s*=\s*"([^"]+)"', manifest, re.M).group(1)
parser = argparse.ArgumentParser()
parser.add_argument('--output', required=True, type=Path)
parser.add_argument('--release-version', required=True,
                    help='Explicit approved published version with the input-tree API; never inferred from local metadata')
parser.add_argument('--moon', type=Path, default=ROOT / 'scripts/moon-local.sh',
                    help='Explicit trusted moon executable for compatibility runs; default retains pinned SDK gate')
args = parser.parse_args()
try:
    VERSION = registry_version(args.release_version)
except ValueError as error:
    parser.error(str(error))
out = args.output.resolve()
if out.exists() and (not out.is_dir() or any(out.iterdir())):
    parser.error('Use an empty evidence directory; existing evidence is never overwritten.')
out.mkdir(parents=True, exist_ok=True)
moon = str(args.moon.resolve())
records = []

def run(name, command, cwd):
    r = subprocess.run(command, cwd=cwd, capture_output=True, text=True, timeout=180)
    (out / (name + '.stdout.txt')).write_text(r.stdout)
    (out / (name + '.stderr.txt')).write_text(r.stderr)
    records.append({'name': name, 'command': command, 'exit_code': r.returncode})
    if r.returncode:
        (out / 'failure.json').write_text(json.dumps({'status': 'failed', 'commands': records}, indent=2))
        raise RuntimeError(name + ' failed; see retained original stdout/stderr')
    print(name + ': passed', flush=True)
    return r

(ROOT / '_build').mkdir(exist_ok=True)
with tempfile.TemporaryDirectory(prefix='registry-consumer-', dir=ROOT / '_build') as td:
    consumer = Path(td)
    (consumer / 'moon.mod').write_text('name = "local/moonabnf-registry-consumer"\nversion = "0.1.0"\npreferred_target = "wasm"\nimport { "' + MODULE + '@' + VERSION + '" }\n')
    (consumer / 'moon.pkg').write_text('import { "' + MODULE + '" @abnf }\noptions(is_main: true)\n')
    template = ROOT / 'integration/consumer/main.mbt.in'
    (consumer / 'main.mbt').write_bytes(template.read_bytes())
    run('registry-update', [moon, 'update'], consumer)
    run('registry-build-install', [moon, 'build', '--target', 'wasm', '-j', '1', '-d'], consumer)
    tree = json.loads(run('registry-tree', [moon, 'tree', '--json'], consumer).stdout)
    module = next(m for m in tree['modules'] if m['name'] == MODULE)
    require(module['version'] == VERSION, 'Registry version mismatch: ' + repr(module))
    require(module['source']['kind'] == 'registry', 'Expected registry source: ' + repr(module))
    require(not module['workspace_member'], 'Registry dependency is a workspace member: ' + repr(module))
    run('consumer-format', [moon, 'fmt', str(consumer)], consumer)
    expected = '\n'.join([
        'protocol/accept: matched offset=13', 'protocol/reject: no-match offset=6',
        'config/accept: matched offset=7', 'config/reject: no-match offset=6',
        'fixture/accept-0: matched offset=3', 'fixture/accept-1: matched offset=3',
        'fixture/accept-2: matched offset=6', 'fixture/reject: no-match offset=5',
        'api/budget-and-independent-reuse: passed',
        'api/undefined-rule: undefined-rule', 'api/ast-incremental: passed']) + '\n'
    for backend in ['wasm', 'wasm-gc', 'js', 'native']:
        r = run('registry-' + backend, [moon, 'run', '.', '--target', backend,
            '--frozen', '-j', '1', '-d'], consumer)
        require(r.stdout == expected, 'Unexpected consumer output for ' + backend + ': ' + repr(r.stdout))

summary = {'status': 'passed', 'module': MODULE, 'version': VERSION,
           'version_selection': 'explicit --release-version; not local candidate metadata',
           'api_contract': 'input-tree API consumer',
           'resolution': module, 'commands': records, 'local_workspace_override': False,
           'template_sha256': hashlib.sha256(template.read_bytes()).hexdigest(),
           'scope': 'fresh downstream registry install, three complete scenarios and public API assertions on four backends'}
(out / 'summary.json').write_text(json.dumps(summary, indent=2))
print(MODULE + '@' + VERSION + ': registry consumer passed all assertions', flush=True)

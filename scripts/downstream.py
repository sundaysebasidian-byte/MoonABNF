#!/usr/bin/env python3
"""Consume an actual moon package archive from an isolated local workspace.

No registry calls, publication, original source import or copied core implementation.
Only the consumer template and the unzipped package's public API are used.
"""
import argparse
import hashlib
import json
import re
import subprocess
import tempfile
import zipfile
from pathlib import Path
from consumer_contract import bind_candidate, require

ROOT = Path(__file__).resolve().parents[1]
manifest = (ROOT / 'moon.mod').read_text()
MODULE = re.search(r'^name\s*=\s*"([^"]+)"', manifest, re.M).group(1)
VERSION = re.search(r'^version\s*=\s*"([^"]+)"', manifest, re.M).group(1)
parser = argparse.ArgumentParser()
parser.add_argument('--output', type=Path, default=ROOT / 'evidence' / 'downstream-20261001')
parser.add_argument('--moon', type=Path, default=ROOT / 'scripts/moon-local.sh',
                    help='Explicit trusted moon executable for compatibility runs; default retains pinned SDK gate')
args = parser.parse_args()
out = args.output.resolve()
if out.exists() and (not out.is_dir() or any(out.iterdir())):
    parser.error('Use an empty evidence directory; existing evidence is never overwritten.')
out.mkdir(parents=True, exist_ok=True)
moon = str(args.moon.resolve())
records = []

def run(name, command, cwd):
    r = subprocess.run(command, cwd=cwd, capture_output=True, text=True, timeout=120)
    (out / (name + '.stdout.txt')).write_text(r.stdout)
    (out / (name + '.stderr.txt')).write_text(r.stderr)
    records.append({'name': name, 'command': command, 'exit_code': r.returncode,
                    'status': 'passed' if r.returncode == 0 else 'failed'})
    print(name + ': ' + records[-1]['status'], flush=True)
    if r.returncode:
        (out / 'failure.json').write_text(json.dumps({'status': 'failed', 'commands': records}, indent=2))
        print(r.stdout + r.stderr, flush=True)
        raise RuntimeError(name + ' failed; original output preserved')
    return r

run('candidate-package', [moon, 'package', '--frozen'], ROOT)
archive = ROOT / '_build' / 'publish' / (MODULE.replace('/', '-') + '-' + VERSION + '.zip')
(out / archive.name).write_bytes(archive.read_bytes())
with zipfile.ZipFile(archive) as z:
    candidate = bind_candidate(z, ROOT)
    (out / 'candidate-manifest.json').write_text(json.dumps(candidate, indent=2))
    work_parent = ROOT / '_build'
    with tempfile.TemporaryDirectory(prefix='downstream-', dir=work_parent) as td:
        work = Path(td)
        library = work / 'candidate'
        library.mkdir()
        for info in z.infolist():
            p = Path(info.filename)
            if p.is_absolute() or '..' in p.parts:
                raise RuntimeError('Unsafe archive member')
        z.extractall(library)
        consumer = work / 'consumer'
        consumer.mkdir()
        (work / 'moon.work').write_text('members = ["candidate", "consumer"]\n')
        (consumer / 'moon.mod').write_text('name = "local/moonabnf-downstream"\nversion = "0.1.0"\npreferred_target = "wasm"\nimport { "' + MODULE + '@' + VERSION + '" }\n')
        (consumer / 'moon.pkg').write_text('import { "' + MODULE + '" @abnf }\noptions(is_main: true)\n')
        (consumer / 'main.mbt').write_bytes((ROOT / 'integration' / 'consumer' / 'main.mbt.in').read_bytes())
        tree = json.loads(run('consumer-tree', [moon, 'tree', '--json'], consumer).stdout)
        module = next(m for m in tree['modules'] if m['name'] == MODULE)
        require(Path(module['source']['path']).resolve() == library.resolve(), 'Local candidate resolution path mismatch')
        require(module['source']['kind'] == 'local', 'Expected local candidate source')
        run('consumer-format', [moon, 'fmt', str(consumer)], consumer)
        expected = '\n'.join([
            'protocol/accept: matched offset=13', 'protocol/reject: no-match offset=6',
            'config/accept: matched offset=7', 'config/reject: no-match offset=6',
            'fixture/accept-0: matched offset=3', 'fixture/accept-1: matched offset=3',
            'fixture/accept-2: matched offset=6', 'fixture/reject: no-match offset=5',
            'api/budget-and-independent-reuse: passed',
            'api/undefined-rule: undefined-rule', 'api/ast-incremental: passed']) + '\n'
        for backend in ['wasm', 'wasm-gc', 'js', 'native']:
            result = run('consumer-' + backend, [moon, 'run', '.', '--target', backend,
                '--frozen', '-j', '1', '-d'], consumer)
            require(result.stdout == expected, 'Unexpected consumer output for ' + backend + ': ' + repr(result.stdout))
        for name, sha in candidate.items():
            require(hashlib.sha256((library / name).read_bytes()).hexdigest() == sha, 'Candidate changed during consumption: ' + name)

summary = {'status': 'passed', 'delivery': 'unpublished moon package ZIP',
           'source_binding': 'every packaged file SHA-256 equals current source before extraction',
           'api_contract': 'input-tree API consumer',
           'archive_sha256': hashlib.sha256(archive.read_bytes()).hexdigest(),
           'manifest': 'candidate-manifest.json', 'commands': records,
           'resolution': 'isolated workspace module dependency, consumer imports only public API',
           'registry_consumption': 'not tested; no registry calls or publication',
           'consumer_template_sha256': hashlib.sha256((ROOT / 'integration/consumer/main.mbt.in').read_bytes()).hexdigest()}
(out / 'summary.json').write_text(json.dumps(summary, indent=2))
print('Unpublished candidate consumer: all assertions passed', flush=True)

#!/usr/bin/env python3
"""End-to-end harness rejection tests using an isolated fake SDK, never a registry."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
EXPECTED = '\n'.join([
    'protocol/accept: matched offset=13', 'protocol/reject: no-match offset=6',
    'config/accept: matched offset=7', 'config/reject: no-match offset=6',
    'fixture/accept-0: matched offset=3', 'fixture/accept-1: matched offset=3',
    'fixture/accept-2: matched offset=6', 'fixture/reject: no-match offset=5',
    'api/budget-and-independent-reuse: passed',
    'api/undefined-rule: undefined-rule', 'api/ast-incremental: passed']) + '\n'
FAKE = r'''
import json, os, pathlib, sys, zipfile
root = pathlib.Path(__file__).resolve().parent
mode = os.environ['TEST_MODE']
fault = os.environ['TEST_FAULT']
cmd = sys.argv[1]
if cmd == 'package':
    out = root / '_build/publish/sundaysebasidian-byte-moonabnf-0.1.0.zip'
    out.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(out, 'w') as z:
        for p in root.iterdir():
            if p.name.endswith(('.mbt', '.mbti')) or p.name in ('moon.mod', 'moon.pkg'):
                z.write(p, p.name)
elif cmd == 'tree':
    candidate = pathlib.Path.cwd().parent / 'candidate'
    source = {'kind': 'registry'} if mode == 'registry' else {'kind': 'local', 'path': str(candidate)}
    if fault == 'source': source['kind'] = 'local' if mode == 'registry' else 'registry'
    if fault == 'path': source['path'] = str(root)
    m = {'name': 'sundaysebasidian-byte/moonabnf', 'version': '9.8.7', 'source': source, 'workspace_member': False}
    if fault == 'version': m['version'] = '0.1.0'
    if fault == 'workspace': m['workspace_member'] = True
    print(json.dumps({'modules': [m]}))
elif cmd == 'run':
    if fault == 'mutation':
        (pathlib.Path.cwd().parent / 'candidate/types.mbt').write_text('changed')
    print('WRONG OUTPUT' if fault == 'output' else EXPECTED, end='')
'''

class OptimizedConsumerTests(unittest.TestCase):
    def test_acceptance_guards_survive_all_python_modes(self):
        for mode, faults in [('registry', ['none', 'version', 'source', 'workspace', 'output']),
                             ('local', ['none', 'path', 'source', 'output', 'mutation'])]:
            for flags, optimize in [([], ''), (['-O'], ''), ([], '1')]:
                for fault in faults:
                    with self.subTest(mode=mode, flags=flags, optimize=optimize, fault=fault):
                        with tempfile.TemporaryDirectory() as td:
                            root = Path(td)
                            for name in ['moon.mod', 'moon.pkg', 'pkg.generated.mbti', 'input_tree.mbt',
                                         'compiler.mbt', 'parser.mbt', 'recognizer.mbt', 'types.mbt',
                                         'analysis.mbt', 'core.mbt']:
                                shutil.copy2(ROOT / name, root / name)
                            (root / 'scripts').mkdir()
                            for name in ['consumer_contract.py', 'registry_consumer.py', 'downstream.py']:
                                shutil.copy2(ROOT / 'scripts' / name, root / 'scripts' / name)
                            (root / 'integration/consumer').mkdir(parents=True)
                            shutil.copy2(ROOT / 'integration/consumer/main.mbt.in', root / 'integration/consumer/main.mbt.in')
                            fake = root / 'fake-moon'
                            fake.write_text('#!' + sys.executable + '\nEXPECTED = ' + repr(EXPECTED) + '\n' + FAKE)
                            fake.chmod(0o755)
                            out = root / 'results'
                            script = 'registry_consumer.py' if mode == 'registry' else 'downstream.py'
                            args = [sys.executable] + flags + [str(root / 'scripts' / script), '--output', str(out), '--moon', str(fake)]
                            if mode == 'registry': args += ['--release-version', '9.8.7']
                            env = os.environ.copy()
                            env.pop('PYTHONOPTIMIZE', None)
                            if optimize: env['PYTHONOPTIMIZE'] = optimize
                            env.update(TEST_MODE=mode, TEST_FAULT=fault)
                            run = subprocess.run(args, env=env, capture_output=True, text=True)
                            if fault == 'none':
                                self.assertEqual(run.returncode, 0, run.stderr)
                                self.assertEqual(json.loads((out / 'summary.json').read_text())['status'], 'passed')
                            else:
                                self.assertNotEqual(run.returncode, 0, run.stdout)
                                self.assertFalse((out / 'summary.json').exists())
                                self.assertIn('RuntimeError', run.stderr)

if __name__ == '__main__':
    unittest.main(verbosity=2)

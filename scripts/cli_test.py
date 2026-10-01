#!/usr/bin/env python3
"""Real CLI integration: exit codes, byte-preserving files, batch and budgets."""
import json
import os
import subprocess
import tempfile
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
CLI = ROOT / '_build/js/debug/build/cmd/main/main.js'
checks = []

def invoke(args, code, status=None):
    r = subprocess.run(['node', str(CLI), *map(str, args)], capture_output=True, text=True, timeout=10)
    assert r.returncode == code, (args, r.returncode, r.stdout, r.stderr)
    rows = [json.loads(x) for x in r.stdout.splitlines() if x.startswith('{')]
    if status is not None: assert rows[0]['status'] == status, rows
    checks.append({'command': [str(a) for a in args], 'exit_code': r.returncode, 'stdout': r.stdout, 'stderr': r.stderr})
    return rows

with tempfile.TemporaryDirectory(prefix='moonabnf-cli-') as directory:
    d = Path(directory)
    g = d / 'g.abnf'; g.write_bytes(b'x = *OCTET\r\ns = %s"abc"\r\n')
    yes = d / 'yes.bin'; yes.write_bytes(b'abc')
    no = d / 'no.bin'; no.write_bytes(b'abZ')
    empty = d / 'empty.bin'; empty.write_bytes(b'')
    binary = d / 'binary.bin'; binary.write_bytes(b'\x00\xff')
    huge = d / 'huge.bin'; huge.write_bytes(b'a' * 65537)
    bad = d / 'bad.abnf'; bad.write_bytes(b'x = x / "a"\r\n')
    lf = d / 'lf.abnf'; lf.write_bytes(b'x = "a"\n')
    huge_grammar = d / 'huge.abnf'; huge_grammar.write_bytes(b';' + b'a' * 65534 + b'\r\n')
    invoke(['check', g], 0, 'valid')
    invoke(['match', g, 's', yes], 0, 'matched')
    rows = invoke(['match', g, 's', no], 1, 'no-match'); assert rows[0]['offset'] == 2
    invoke(['match', g, 'x', empty], 0, 'matched')
    invoke(['match', g, 'x', binary], 0, 'matched')
    invoke(['match', g, 'x', huge], 3, 'budget-exceeded:input-bytes')
    invoke(['match', g, 'x', yes, 1], 3, 'budget-exceeded:work')
    invoke(['match', g, 'missing', yes], 2, 'unknown-rule')
    invoke(['match', g, 'x', yes, 0], 2, 'invalid-work-budget')
    invoke(['match', g, 'x', yes, '10000001'], 2, 'invalid-work-budget')
    invoke(['match', g, 'x', yes, '-1'], 2, 'invalid-work-budget')
    invoke(['match', g, 'x', yes, ''], 2, 'invalid-work-budget')
    invoke(['check', bad], 2, 'grammar-error')
    invoke(['check', lf], 2, 'grammar-error')
    rows = invoke(['check', huge_grammar], 2, 'grammar-error'); assert rows[0]['code'] == 'parse-budget'
    invoke(['check', d / 'missing.abnf'], 2)
    invoke(['check', d], 2)
    if hasattr(os, 'mkfifo'):
        fifo = d / 'pipe'; os.mkfifo(fifo)
        invoke(['check', fifo], 2)
    rows = invoke(['batch', g, 's', yes, no], 1); assert len(rows) == 2
    rows = invoke(['batch', g, 'x', huge, yes], 3); assert len(rows) == 2
    rows = invoke(['batch', g, 's', d / 'missing.bin', yes], 2)
    assert len(rows) == 1 and rows[0]['status'] == 'matched' and rows[0]['file'] == str(yes)
    assert 'I/O:' in checks[-1]['stderr']
    rows = invoke(['batch', g, 'x', d / 'missing.bin', huge], 3)
    assert len(rows) == 1 and rows[0]['status'] == 'budget-exceeded:input-bytes'
    assert 'I/O:' in checks[-1]['stderr']
    invoke(['batch', g, 'x', *([yes] * 257)], 2, 'usage-error')
    invoke(['check', g, 'unexpected'], 2, 'usage-error')
# Strip non-reproducible temporary directory identities, retaining inputs/results.
for check in checks:
    check['command'] = [x.replace(directory, '<temp>') for x in check['command']]
    check['stdout'] = check['stdout'].replace(directory, '<temp>')
    check['stderr'] = check['stderr'].replace(directory, '<temp>')
print(json.dumps({'status':'passed', 'checks':len(checks), 'results':checks}, indent=2))

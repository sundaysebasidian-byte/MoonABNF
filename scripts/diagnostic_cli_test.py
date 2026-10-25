#!/usr/bin/env python3
"""Source CLI controls; never publish and never read credentials."""
import json, os, subprocess, tempfile
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
SDK = os.environ.get('MOONABNF_SDK') or os.environ.get('MOON_HOME')
if not SDK:
    raise SystemExit('Set an existing trusted SDK')
with tempfile.TemporaryDirectory(prefix='abnf-diagnostic-') as td:
    root = Path(td); grammar = root/'case.abnf'; data = root/'case.bin'
    grammar.write_bytes(b's = %s"abc"\r\n'); data.write_bytes(b'abX')
    for mode, rule, budget, code in [('match', 's', [], 1), ('diagnose', 's', [], 1), ('diagnose', 's', ['1'], 3), ('diagnose', 'missing', [], 2)]:
        result = subprocess.run([str(Path(SDK)/'bin/moon'), 'run', 'cmd/main', '--target', 'js', '--frozen', '-j', '1', '--', mode, str(grammar), rule, str(data), *budget], cwd=ROOT, capture_output=True, text=True, timeout=60)
        if result.returncode != code:
            raise RuntimeError(f'{mode}/{rule}: expected exit {code}, got {result.returncode}: {result.stderr}')
        record = json.loads(result.stdout)
        if mode == 'match':
            assert 'diagnostic' not in record
        elif code == 1:
            failure = record['diagnostic']['failure']
            assert failure['offset'] == 2 and failure['actual'] == 88
            assert failure['expected'][0]['lo'] == 99 and failure['expected'][0]['grammar_offset'] == 4
        else:
            assert record['diagnostic']['failure'] is None
        print(mode, rule, code, 'passed')
    data.write_bytes(b'abc')
    result = subprocess.run([str(Path(SDK)/'bin/moon'), 'run', 'cmd/main', '--target', 'js', '--frozen', '-j', '1', '--', 'diagnose', str(grammar), 's', str(data)], cwd=ROOT, capture_output=True, text=True, timeout=60)
    assert result.returncode == 0
    record = json.loads(result.stdout); assert record['status'] == 'matched' and record['diagnostic']['failure'] is None
    print('diagnose success 0 passed')

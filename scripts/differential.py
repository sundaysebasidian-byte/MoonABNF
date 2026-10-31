#!/usr/bin/env python3
"""Independent Python bytes-regex oracle; no MoonABNF AST/evaluator reused.
Generated regular ABNF subset only: not a full ABNF conformance certification.
No external Python packages. Fixed seed and full mismatch details.
"""
import itertools
import json
import random
import re
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CLI = ROOT / '_build/js/debug/build/cmd/main/main.js'
SEED = 20260930
rng = random.Random(SEED)

# Each constructor directly creates ABNF text and an independently compiled
# regex. No parsing of MoonABNF's output or dependence on its endpoint algorithm.
def atom():
    k = rng.randrange(7)
    if k < 3:
        text = rng.choice([b'', b'a', b'B', b'ab', b'aB', b'0', b' '])
        prefix = ['', '%s', '%i'][k]
        abnf = prefix + '"' + text.decode('ascii') + '"'
        pattern = re.escape(text)
        if k != 1: pattern = b'(?i:' + pattern + b')'
        return abnf, pattern
    if k == 3: return '%x00-FF', b'[\x00-\xff]'
    if k == 4: return '%d48-49', b'[01]'
    if k == 5: return '%b01100001.01100010', b'ab'
    return 'DIGIT', b'[0-9]'

def make(depth):
    if depth == 0 or rng.randrange(4) == 0: return atom()
    k = rng.randrange(4)
    a, ra = make(depth - 1)
    if k in (0, 1):
        b, rb = make(depth - 1)
        return (f'({a} / {b})', b'(?:' + ra + b'|' + rb + b')') if k == 0 else (f'({a} {b})', b'(?:' + ra + rb + b')')
    if k == 2:
        lo = rng.randrange(3); hi = rng.randrange(lo, 4)
        return f'{lo}*{hi}({a})', b'(?:' + ra + b'){' + str(lo).encode() + b',' + str(hi).encode() + b'}'
    return f'[{a}]', b'(?:' + ra + b')?'

def run():
    cases = 0; mismatches = []
    with tempfile.TemporaryDirectory(prefix='moonabnf-diff-') as temp:
        temp = Path(temp)
        for g in range(80):
            expr, pattern = make(3)
            # Exercise references, increments, comment-folding and mixed name case.
            source = f'Start = piece ; independent oracle\r\nPiece = {expr}\r\nPIECE =/ %s"Z"\r\n'.encode('ascii')
            pattern = b'(?:' + pattern + b'|Z)'
            grammar = temp / 'grammar.abnf'; grammar.write_bytes(source)
            candidates = [b'', b'Z', b'\x00', b'\xff', b'\r\n', b'9', b'aB', b' ', b'aaaa']
            candidates += [bytes(x) for n in range(1, 4) for x in itertools.product(b'aB0', repeat=n)]
            candidates += [bytes(rng.choice(b'abAB01 \x00\xff') for _ in range(rng.randrange(9))) for _ in range(20)]
            paths = []
            for i, value in enumerate(candidates):
                p = temp / f'input-{i}.bin'; p.write_bytes(value); paths.append(str(p))
            out = subprocess.run(['node', str(CLI), 'batch', str(grammar), 'START', *paths], capture_output=True, text=True, timeout=15)
            if out.returncode not in (0, 1): raise RuntimeError(f'CLI failed: {out.returncode} {out.stdout} {out.stderr}')
            reports = [json.loads(line) for line in out.stdout.splitlines()]
            if len(reports) != len(candidates): raise AssertionError('missing batch reports')
            for value, report in zip(candidates, reports):
                expected = re.fullmatch(pattern, value) is not None
                actual = report['status'] == 'matched'
                cases += 1
                if actual != expected:
                    mismatches.append({'grammar': source.decode(), 'input_hex': value.hex(), 'expected': expected, 'actual': report})
    evidence = {'status': 'passed' if not mismatches else 'failed', 'seed': SEED,
                'grammars': 80, 'comparisons': cases, 'mismatch_count': len(mismatches), 'mismatches': mismatches,
                'oracle': 'Python stdlib re.fullmatch on bytes, independently generated regular subset',
                'not_tested': ['third-party full ABNF grammar parser', 'left-recursive recognition (outside this regular-subset oracle)', 'general recursive grammars against regex oracle']}
    print(json.dumps(evidence, ensure_ascii=False, indent=2))
    if mismatches: raise SystemExit(1)

if __name__ == '__main__': run()

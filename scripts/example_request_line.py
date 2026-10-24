#!/usr/bin/env python3
"""Run examples/request_line/cmd on several backends and compare with the golden output.

The example parses one valid request line and four invalid ones, so a pass covers
both the accepted tree/field extraction and the rejection offsets. Output must be
byte-identical to examples/request_line/cmd/expected_output.txt on every backend.
"""
import argparse
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXPECTED = ROOT / 'examples' / 'request_line' / 'cmd' / 'expected_output.txt'

def check(actual: str, expected: str) -> list:
    """Return human-readable problems; an empty list means the output is acceptable."""
    problems = []
    if actual != expected:
        a, e = actual.splitlines(), expected.splitlines()
        for i in range(max(len(a), len(e))):
            x = a[i] if i < len(a) else '<missing>'
            y = e[i] if i < len(e) else '<missing>'
            if x != y:
                problems.append(f'line {i + 1}: got {x!r}, expected {y!r}')
                break
        else:
            problems.append('line endings or trailing bytes differ')
    if expected.count('rejected ') != 4 or 'request-line [0,39)' not in expected:
        problems.append('golden file lost its accepted tree or one of the 4 rejection cases')
    return problems

def self_test(expected: str) -> None:
    """Negative controls: the comparison must reject altered output."""
    assert check(expected, expected) == []
    for bad in (expected[:-1], expected + 'x', expected.replace('1', '2', 1),
                expected.replace('\n', '\r\n', 1), expected.split('---')[0]):
        assert check(bad, expected), 'comparison accepted a mutated output'

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--targets', default='js,wasm-gc,native')
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    expected = EXPECTED.read_text()
    self_test(expected)
    records, failed = [], False
    for target in args.targets.split(','):
        r = subprocess.run([str(ROOT / 'scripts/moon-local.sh'), 'run', 'examples/request_line/cmd',
                            '--target', target, '-j', '1'],
                           cwd=ROOT, capture_output=True, text=True, timeout=120)
        problems = check(r.stdout, expected) if r.returncode == 0 else [f'exit code {r.returncode}']
        failed |= bool(problems)
        records.append({'target': target, 'exit_code': r.returncode, 'problems': problems,
                        'stdout_matches_golden': r.stdout == expected})
        print(f'request_line {target}: {"passed" if not problems else "FAILED " + "; ".join(problems)}')
        if r.returncode != 0:
            print(r.stderr, file=sys.stderr)
    if args.output:
        args.output.mkdir(parents=True, exist_ok=True)
        (args.output / 'request_line.json').write_text(json.dumps(records, indent=2))
    return 1 if failed else 0

if __name__ == '__main__':
    raise SystemExit(main())

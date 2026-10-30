#!/usr/bin/env python3
"""Cold/hot public shell entrypoint: stdout must be exclusively JSONL."""
import json
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
# A fresh copy without build/cache artifacts tests the actual first-use command.
with tempfile.TemporaryDirectory(prefix='moonabnf-shell-json-') as temp:
    root = Path(temp) / 'source'
    shutil.copytree(ROOT, root, ignore=shutil.ignore_patterns('.git', '_build', 'target', '.mooncakes', '.toolchains', '__pycache__', 'evidence'))
    grammar = Path(temp) / 'grammar.abnf'
    grammar.write_bytes(b'x = %s"abc"\r\n')
    yes = Path(temp) / 'yes'; yes.write_bytes(b'abc')
    no = Path(temp) / 'no'; no.write_bytes(b'bad')
    cases = [('cold', ['check', grammar], 0, ['valid']),
             ('hot', ['match', grammar, 'x', yes], 0, ['matched']),
             ('hot-no-match', ['match', grammar, 'x', no], 1, ['no-match']),
             ('hot-batch', ['batch', grammar, 'x', yes, no], 1, ['matched', 'no-match'])]
    for label, args, expected_code, statuses in cases:
        result = subprocess.run(['sh', 'scripts/cli.sh', *map(str,args)], cwd=root, capture_output=True, text=True, timeout=180)
        if result.returncode != expected_code:
            raise RuntimeError((label, result.returncode, result.stdout, result.stderr))
        # Never discard build chatter or select only lines beginning with '{'.
        rows = [json.loads(line) for line in result.stdout.splitlines()]
        if [row['status'] for row in rows] != statuses:
            raise RuntimeError((label, rows))
        print(json.dumps({'case':label, 'exit_code':result.returncode, 'json_rows':len(rows), 'stderr_bytes':len(result.stderr)}))

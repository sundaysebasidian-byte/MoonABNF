#!/usr/bin/env python3
"""Bind embedded protocol grammar bytes to attributed CRLF source fixtures."""
import hashlib
import json
import re
from pathlib import Path

root = Path(__file__).resolve().parents[1]
source = (root / 'examples/protocols/grammar.mbt').read_text()
manifest = json.loads((root / 'fixtures/protocols/sources.json').read_text())
for name, record in manifest.items():
    block = re.search(r'pub fn ' + name + r'_grammar\(\) -> Bytes \{\s*let lines = \[(.*?)\]\s*@utf8', source, re.S)
    if block is None:
        raise SystemExit('missing embedded grammar: ' + name)
    lines = [json.loads(s) for s in re.findall(r'"(?:[^"\\]|\\.)*"', block[1])]
    embedded = ('\r\n'.join(lines) + '\r\n').encode()
    fixture = (root / 'fixtures/protocols' / (name + '.abnf')).read_bytes()
    if embedded != fixture or hashlib.sha256(fixture).hexdigest() != record['grammar_sha256']:
        raise SystemExit('protocol grammar bytes/hash mismatch: ' + name)
    print(name + ': embedded bytes and attributed fixture hash match')

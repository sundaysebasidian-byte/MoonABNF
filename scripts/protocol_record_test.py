#!/usr/bin/env python3
"""Source-bound local package test; distinct from published registry consumers."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import time
import zipfile
from bounded_run import execute
from consumer_contract import bind_candidate

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--diagnostics', action='store_true', help='Unpublished opt-in source diagnostic extension; never used by registry consumer')
    args = parser.parse_args()
    out = args.output.resolve()
    if out == ROOT or ROOT in out.parents:
        parser.error('Output must be outside source')
    if out.exists() and (not out.is_dir() or any(out.iterdir())):
        parser.error('Use an empty output directory; existing evidence is never overwritten')
    sdk = os.environ.get('MOONABNF_SDK') or os.environ.get('MOON_HOME')
    if not sdk:
        parser.error('Set MOONABNF_SDK to the existing trusted SDK')
    out.mkdir(parents=True, exist_ok=True)
    env = dict(os.environ, MOON_HOME=sdk, RUST_LOG='error')
    env['PATH'] = str(Path(sdk) / 'bin') + os.pathsep + env.get('PATH', '')
    moon = str(Path(sdk) / 'bin/moon')
    manifest = (ROOT / 'moon.mod').read_text()
    version = re.search(r'^version\s*=\s*"([^"]+)"', manifest, re.M).group(1)
    started = time.monotonic()
    records = []
    summary = {'status': 'failed', 'scope': 'source-bound unpublished local package; JS adapter only',
               'registry_test': False, 'commands': records}

    def run(name, command, cwd=ROOT, expected=0):
        remaining = 120 - (time.monotonic() - started)
        if remaining <= 0:
            raise RuntimeError('Whole protocol test exceeded 120 seconds')
        record = execute(command, cwd, out, name, env, seconds=remaining)
        records.append(record)
        if record['stop_reason'] or record['exit_code'] != expected:
            raise RuntimeError(name + ' failed; partial logs retained')
        # Expected nonzero application decisions are successful controls.
        record['status'] = 'passed'
        print(name + ': passed (exit ' + str(record['exit_code']) + ')', flush=True)
        return (out / (name + '.stdout.txt')).read_text()

    try:
        summary['sdk'] = run('sdk', [moon, 'version', '--all'])
        summary['git_head'] = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
        summary['dirty_diff_sha256'] = hashlib.sha256(subprocess.check_output(['git', 'diff', 'HEAD'], cwd=ROOT)).hexdigest()
        run('package', [moon, 'package', '--frozen'])
        archive = ROOT / '_build/publish' / ('sundaysebasidian-byte-moonabnf-' + version + '.zip')
        work = out / 'workspace'
        candidate = work / 'candidate'
        consumer = work / 'consumer'
        candidate.mkdir(parents=True)
        consumer.mkdir()
        with zipfile.ZipFile(archive) as bundle:
            hashes = bind_candidate(bundle, ROOT)
            for name in bundle.namelist():
                p = Path(name)
                if p.is_absolute() or '..' in p.parts:
                    raise RuntimeError('Unsafe archive path')
            bundle.extractall(candidate)
        binding = {'source_files_sha256': hashes, 'archive_sha256': hashlib.sha256(archive.read_bytes()).hexdigest(),
                   'version': version, 'resolution': 'local source-bound workspace, not registry'}
        (out / 'source-binding.json').write_text(json.dumps(binding, indent=2))
        (work / 'moon.work').write_text('members = ["candidate", "consumer"]\n')
        templates = ROOT / 'integration/protocol_consumer'
        for name in ['moon.mod', 'moon.pkg', 'main.mbt', 'contract_wbtest.mbt']:
            text = (templates / ('main.diagnostics.mbt.in' if name == 'main.mbt' and args.diagnostics else name + '.in')).read_text()
            if name == 'moon.mod':
                text = re.sub(r'moonabnf@\d+\.\d+\.\d+', 'moonabnf@' + version, text)
            (consumer / name).write_text(text)
        run('check-js', [moon, 'check', '--target', 'js', '--frozen', '-j', '1'], consumer)
        run('contract-js', [moon, 'test', 'contract_wbtest.mbt', '--target', 'js', '--frozen', '-j', '1'], consumer)
        tree = json.loads(run('tree', [moon, 'tree', '--json'], consumer))
        module = next(m for m in tree['modules'] if m['name'] == 'sundaysebasidian-byte/moonabnf')
        if module['source']['kind'] != 'local' or Path(module['source']['path']).resolve() != candidate.resolve():
            raise RuntimeError('Wrong source binding')
        base = [moon, 'run', '.', '--target', 'js', '--frozen', '-j', '1', '--', '--json']
        actual = json.loads(run('accept', base + ['http://www.ietf.org/rfc/rfc2396.txt', 'SID=31d4d96e407aad42; lang=en-US'], consumer))
        if actual != json.loads((templates / 'expected-record.json').read_text()):
            raise RuntimeError('JSON golden mismatch')
        for name, arguments, code, decision in [
                ('reject', ['http://example.test/%GG', 'a=bad value'], 1, 'reject'),
                ('budget', ['/ok', 'a=b', '1'], 3, 'defer'),
                ('config', ['/ok', 'a=b', '0'], 2, 'invalid-node-budget')]:
            report = json.loads(run(name, base + arguments, consumer, code))
            if report['decision'] != decision:
                raise RuntimeError('Wrong decision: ' + name)
            if name in ['reject', 'budget'] and (report['components'] or report['cookies']):
                raise RuntimeError('Rejected/deferred record leaked partial fields')
        if args.diagnostics:
            d = json.loads(run('diagnostic-reject', base + ['http://example.test/%GG', 'a=bad value', '--diagnostics'], consumer, 1))
            if d['uri_diagnostic']['failure']['offset'] != 21 or d['cookie_diagnostic']['failure']['actual'] != 32:
                raise RuntimeError('Protocol diagnostic byte mismatch')
            if d['components'] or d['cookies'] or d['decision'] != 'reject':
                raise RuntimeError('Diagnostic changed rejection/field isolation')
            d = json.loads(run('diagnostic-budget', base + ['/ok', 'a=b', '1', '--diagnostics'], consumer, 3))
            if d['decision'] != 'defer' or 'uri_diagnostic' in d or 'cookie_diagnostic' in d:
                raise RuntimeError('Diagnostic overwrote tree-budget indeterminacy')
        for name, digest in hashes.items():
            if hashlib.sha256((candidate / name).read_bytes()).hexdigest() != digest:
                raise RuntimeError('Candidate mutated during test: ' + name)
        summary.update(status='passed', source_binding='source-binding.json',
                       program_reuse='existing contract_wbtest reuses the same Program after budget/config failures')
    except Exception as error:
        summary['error'] = str(error)
    finally:
        (out / 'commands.json').write_text(json.dumps(records, indent=2))
        (out / 'summary.json').write_text(json.dumps(summary, indent=2))
    return 0 if summary['status'] == 'passed' else 1


if __name__ == '__main__':
    raise SystemExit(main())

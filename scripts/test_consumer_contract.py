#!/usr/bin/env python3
"""Offline regression checks. No MoonBit SDK, registry, or publication involved."""
import io
import subprocess
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path
from consumer_contract import bind_candidate, registry_version

ROOT = Path(__file__).resolve().parents[1]
REQUIRED = ('moon.mod', 'moon.pkg', 'pkg.generated.mbti', 'input_tree.mbt',
            'compiler.mbt', 'parser.mbt', 'recognizer.mbt', 'types.mbt',
            'analysis.mbt', 'core.mbt')

class ConsumerContractTests(unittest.TestCase):
    def test_old_release_rejected(self):
        with self.assertRaisesRegex(ValueError, 'lacks the input-tree API'):
            registry_version('0.1.0')

    def test_explicit_version_syntax_only(self):
        # Synthetic value tests syntax, not release existence or authorization.
        self.assertEqual(registry_version('9.8.7'), '9.8.7')
        for version in ('', 'latest', '../0.2.0', '0.2.0"', '01.2.3', '0.2.0-beta'):
            with self.subTest(version=version), self.assertRaises(ValueError):
                registry_version(version)

    def test_cli_rejects_before_output_or_sdk(self):
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp) / 'not-created'
            for extra in ([], ['--release-version', '0.1.0']):
                result = subprocess.run([sys.executable, str(ROOT / 'scripts/registry_consumer.py'),
                    '--output', str(out)] + extra, capture_output=True, text=True)
                self.assertEqual(result.returncode, 2)
                self.assertFalse(out.exists())
                self.assertNotIn('Traceback', result.stderr)

    def test_existing_success_evidence_is_never_reused(self):
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp)
            old = out / 'summary.json'
            old.write_text('{"status":"passed","old":true}')
            for script, extra in [('registry_consumer.py', ['--release-version', '9.8.7']),
                                  ('downstream.py', [])]:
                result = subprocess.run([sys.executable, str(ROOT / 'scripts' / script),
                    '--output', str(out)] + extra, capture_output=True, text=True)
                self.assertEqual(result.returncode, 2)
                self.assertIn('empty evidence directory', result.stderr)
                self.assertEqual(old.read_text(), '{"status":"passed","old":true}')

    def archive(self, root, changes=None, omitted=()):
        stream = io.BytesIO()
        with zipfile.ZipFile(stream, 'w') as archive:
            for name in REQUIRED:
                (root / name).write_bytes(name.encode())
                if name not in omitted:
                    archive.writestr(name, (changes or {}).get(name, name.encode()))
            for name, data in (changes or {}).items():
                if name not in REQUIRED:
                    archive.writestr(name, data)
        stream.seek(0)
        return zipfile.ZipFile(stream)

    def test_current_candidate_bound(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            with self.archive(root) as archive:
                self.assertEqual(set(bind_candidate(archive, root)), set(REQUIRED))

    def test_stale_candidate_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            with self.archive(root, {'input_tree.mbt': b'old'}) as archive:
                with self.assertRaisesRegex(ValueError, 'Candidate/source mismatch'):
                    bind_candidate(archive, root)

    def test_missing_tree_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            with self.archive(root, omitted=('input_tree.mbt',)) as archive:
                with self.assertRaisesRegex(ValueError, 'lacks required'):
                    bind_candidate(archive, root)

    def test_unknown_archive_member_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            with self.archive(root, {'unknown.mbt': b'unknown'}) as archive:
                with self.assertRaisesRegex(ValueError, 'no source binding'):
                    bind_candidate(archive, root)

    def test_traversal_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            with self.archive(root, {'../escape': b'bad'}) as archive:
                with self.assertRaisesRegex(ValueError, 'Unsafe'):
                    bind_candidate(archive, root)

if __name__ == '__main__':
    unittest.main(verbosity=2)

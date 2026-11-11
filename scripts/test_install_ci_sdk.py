"""Offline guard tests only: no SDK download or installation."""
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('install_ci_sdk', ROOT / 'scripts/install-ci-sdk.py')
installer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(installer)


class InstallerGuards(unittest.TestCase):
    def test_lock_uses_this_projects_exact_release(self):
        lock = installer.checked_lock(ROOT / 'TOOLCHAIN.lock')
        self.assertEqual(lock['compiler'], '0.10.20+65efd5b93')
        self.assertEqual(lock['sdk_sha256'], '80d987523308fa490eba9f1baf98df996a5a7891e118357553b7c2608c0597c5')
        self.assertEqual(lock['core_sha256'], '8ec2a2c01335501d703867bb4eef5f92d3cd7e1ae1ee5f7f14d54d16d2c7c2b5')

    def test_origin_exactness(self):
        self.assertTrue(installer.official_url('https://cli.moonbitlang.com/a'))
        for bad in ('https://cli.moonbitlang.com.evil.test/a', 'http://cli.moonbitlang.com/a',
                    'https://user@cli.moonbitlang.com/a', 'https://cli.moonbitlang.com/a?b'):
            self.assertFalse(installer.official_url(bad))

    def test_destination_does_not_overwrite_or_leave_project(self):
        with self.assertRaises(ValueError):
            installer.destination(ROOT)
        with self.assertRaises(ValueError):
            installer.destination(ROOT.parent / 'outside-sdk')
        with tempfile.TemporaryDirectory(dir=ROOT) as tmp:
            with self.assertRaises(ValueError):
                installer.destination(Path(tmp))
            dest = Path(tmp) / 'new-sdk'
            self.assertEqual(installer.destination(dest), dest)
            self.assertFalse(dest.exists())

    def test_drift_and_bad_hash_rejected(self):
        original = json.loads((ROOT / 'TOOLCHAIN.lock').read_text())
        for key, value in [('sdk_url', 'https://cli.moonbitlang.com/binaries/latest/moonbit-linux-x86_64.tar.gz'),
                           ('core_sha256', 'wrong')]:
            with tempfile.TemporaryDirectory() as tmp:
                changed = {**original, key: value}
                path = Path(tmp) / 'lock.json'
                path.write_text(json.dumps(changed))
                with self.assertRaises(ValueError):
                    installer.checked_lock(path)


if __name__ == '__main__':
    unittest.main()

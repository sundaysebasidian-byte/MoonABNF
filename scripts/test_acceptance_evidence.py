"""Acceptance harness tests; real synthetic processes, stubbed SDK stages."""
import contextlib
import hashlib
import io
import json
import os
from pathlib import Path
import platform
import runpy
import shutil
import signal
import subprocess
import sys
import tempfile
import time
import unittest
from unittest.mock import patch
import bounded_run

SOURCE = Path(__file__).with_name('acceptance.py')
REAL_EXECUTE = bounded_run.execute
REAL_RUN = subprocess.run
platform.platform()


def live(pid):
    state = REAL_RUN(['ps', '-o', 'stat=', '-p', str(pid)], capture_output=True, text=True, timeout=2).stdout.strip()
    return bool(state) and not state.startswith('Z')


class AcceptanceEvidenceTests(unittest.TestCase):
    def invoke(self, source, seconds=.3, metadata_error=None, monitor_error=False, high_rss=False, source_fault=None, in_source_output=False):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / 'repo'
            (root / 'scripts').mkdir(parents=True)
            script = root / 'scripts/acceptance.py'
            shutil.copyfile(SOURCE, script)
            out = root / 'results' if in_source_output else Path(tmp) / 'evidence'
            marker = root / 'source.mbt'
            marker.write_bytes(b'original source')
            removed = root / 'removed.mbt'
            removed.write_bytes(b'removed source')
            count = 0

            def execute(command, cwd, output, name, **kwargs):
                nonlocal count
                self.assertIn('rss_mib', kwargs)
                self.assertIsNone(kwargs['rss_mib'])
                count += 1
                if count == 1:
                    if source_fault == 'mutated':
                        marker.write_bytes(b'changed source')
                        removed.unlink()
                        (root / 'added.mbt').write_bytes(b'new source')
                    actual = ['/nonexistent-moonabnf-test-executable'] if source is None else [sys.executable, '-c', source]
                    if monitor_error:
                        failure = subprocess.CalledProcessError(1, ['ps', '-axo', 'pid=,ppid=,rss=']) if monitor_error == 'nonzero' else OSError('synthetic preflight failure')
                        with patch('bounded_run.process_rss', side_effect=failure):
                            return REAL_EXECUTE(actual, cwd, output, name, seconds=seconds, rss_mib=None)
                    if high_rss:
                        with patch('bounded_run.process_rss', return_value=1024 * 1024 * 1024):
                            return REAL_EXECUTE(actual, cwd, output, name, seconds=seconds, rss_mib=None)
                    return REAL_EXECUTE(actual, cwd, output, name, seconds=seconds, rss_mib=None)
                (output / f'{name}.stdout.txt').write_bytes(b'ok\n')
                (output / f'{name}.stderr.txt').write_bytes(b'')
                return {'name': name, 'command': command, 'exit_code': 0, 'status': 'passed', 'stop_reason': None, 'elapsed_seconds': 0}

            def run(command, **kwargs):
                if command[0] != 'git':
                    return REAL_RUN(command, **kwargs)
                self.assertEqual(kwargs['timeout'], 5)
                if metadata_error == 'timeout':
                    raise subprocess.TimeoutExpired(command, 5)
                if metadata_error == 'missing':
                    raise FileNotFoundError('synthetic git missing')
                return subprocess.CompletedProcess(command, 9 if metadata_error == 'nonzero' else 0,
                    'test-head\n' if command[1] == 'rev-parse' else '', '')

            original_read = Path.read_bytes

            def read_bytes(path):
                if source_fault == 'unreadable' and path == marker:
                    raise PermissionError('synthetic source read failure')
                return original_read(path)

            started = time.monotonic()
            with patch('pathlib.Path.read_bytes', read_bytes), patch.object(sys, 'argv', [str(script), '--output', str(out)]), patch('bounded_run.execute', side_effect=execute), patch('subprocess.run', side_effect=run), contextlib.redirect_stdout(io.StringIO()):
                with self.assertRaises(SystemExit) as stopped:
                    runpy.run_path(str(script), run_name='__main__')
            elapsed = time.monotonic() - started
            summary = json.loads((out / 'summary.json').read_text())
            manifest = json.loads((out / 'SHA256.json').read_text())
            for name, digest in manifest.items():
                self.assertEqual(hashlib.sha256((out / name).read_bytes()).hexdigest(), digest)
            self.assertEqual(count, len(summary['commands']))
            self.assertGreater(count, 1)
            self.assertTrue(all(x['status'] == 'passed' for x in summary['commands'][1:]))
            return stopped.exception.code, summary, (out / 'toolchain.stdout.txt').read_bytes(), (out / 'toolchain.stderr.txt').read_bytes(), elapsed

    def test_real_timeout_preserves_both_streams_and_summary(self):
        code, summary, stdout, stderr, _ = self.invoke("import os,time; os.write(1,b'partial stdout\\n'); os.write(2,b'partial stderr\\n'); time.sleep(20)")
        self.assertEqual((stdout, stderr), (b'partial stdout\n', b'partial stderr\n'))
        self.assertEqual((code, summary['status']), (1, 'failed'))
        self.assertEqual(summary['commands'][0]['exit_code'], 124)
        self.assertEqual(summary['commands'][0]['stop_reason'], 'wall timeout')

    def test_real_binary_stdout_preserved(self):
        code, summary, stdout, stderr, _ = self.invoke("import os; os.write(1,b'\\xff\\x00\\r\\n'); os.write(2,b'\\xfe')")
        self.assertEqual((stdout, stderr), (b'\xff\x00\r\n', b'\xfe'))
        self.assertEqual((code, summary['status']), (0, 'passed'))

    def test_real_success_stays_passed(self):
        code, summary, stdout, stderr, _ = self.invoke("print('success')")
        self.assertEqual(stdout, b'success\n')
        self.assertEqual((code, summary['status']), (0, 'passed'))

    def test_real_timeout_keeps_incomplete_utf8(self):
        code, summary, stdout, stderr, _ = self.invoke("import os,time; os.write(1,b'\\xe2\\x82'); os.write(2,b'\\xff'); time.sleep(20)")
        self.assertEqual((stdout, stderr), (b'\xe2\x82', b'\xff'))
        self.assertEqual((code, summary['status']), (1, 'failed'))

    def test_real_nonzero_is_failed(self):
        code, summary, stdout, stderr, _ = self.invoke("import os,sys; os.write(1,b'\\xff'); sys.exit(7)")
        self.assertEqual(stdout, b'\xff')
        self.assertEqual(summary['commands'][0]['exit_code'], 7)
        self.assertEqual((code, summary['status']), (1, 'failed'))

    def test_real_spawn_failure_is_recorded(self):
        code, summary, stdout, stderr, _ = self.invoke(None)
        self.assertEqual((stdout, stderr), (b'', b''))
        self.assertEqual(summary['commands'][0]['exit_code'], 127)
        self.assertIn('FileNotFoundError', summary['commands'][0]['stop_reason'])
        self.assertEqual((code, summary['status']), (1, 'failed'))

    def test_empty_timeout_output(self):
        code, summary, stdout, stderr, _ = self.invoke('import time; time.sleep(20)')
        self.assertEqual((stdout, stderr), (b'', b''))
        self.assertEqual((code, summary['status']), (1, 'failed'))

    def test_timeout_cleans_term_ignoring_descendant_and_does_not_hang(self):
        source = "import subprocess,sys,time; c=subprocess.Popen([sys.executable,'-c','import signal,time; signal.signal(signal.SIGTERM,signal.SIG_IGN); print(\\\"child-ready\\\",flush=True); time.sleep(20)']); print(c.pid,flush=True); time.sleep(20)"
        code, summary, stdout, stderr, elapsed = self.invoke(source, seconds=.6)
        pid = int(stdout.splitlines()[0])
        try:
            self.assertIn(b'child-ready', stdout)
            self.assertFalse(live(pid))
            self.assertLess(elapsed, 7)
            self.assertEqual((code, summary['status']), (1, 'failed'))
        finally:
            if live(pid): os.kill(pid, signal.SIGKILL)

    def test_orphan_after_zero_exit_is_not_passed(self):
        source = "import subprocess,sys; c=subprocess.Popen([sys.executable,'-c','import time; time.sleep(20)']); print(c.pid,flush=True)"
        code, summary, stdout, stderr, _ = self.invoke(source)
        pid = int(stdout.strip())
        try:
            self.assertFalse(live(pid))
            self.assertEqual(summary['commands'][0]['exit_code'], 0)
            self.assertEqual((code, summary['status']), (1, 'failed'))
        finally:
            if live(pid): os.kill(pid, signal.SIGKILL)

    def test_metadata_failures_preserve_summary(self):
        for error in ('timeout', 'missing', 'nonzero'):
            with self.subTest(error=error):
                code, summary, stdout, stderr, _ = self.invoke("print('done')", metadata_error=error)
                self.assertEqual(len(summary['metadata_errors']), 2)
                self.assertEqual((code, summary['status']), (1, 'failed'))
                self.assertEqual(summary['commands'][0]['status'], 'passed')

    def test_monitor_preflight_failure_is_failed_not_aborted(self):
        for error in ('missing', 'nonzero'):
            with self.subTest(error=error):
                code, summary, stdout, stderr, _ = self.invoke("print('not run')", monitor_error=error)
                self.assertEqual((stdout, stderr), (b'', b''))
                self.assertEqual((code, summary['status']), (1, 'failed'))

    def test_existing_output_directory_is_rejected_unchanged(self):
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp) / 'old-evidence'
            out.mkdir()
            prior = out / 'toolchain.stdout.txt'
            prior.write_bytes(b'prior-run-evidence')
            with patch.object(sys, 'argv', [str(SOURCE), '--output', str(out)]), patch('bounded_run.execute') as launch, contextlib.redirect_stderr(io.StringIO()):
                with self.assertRaises(SystemExit) as stopped:
                    runpy.run_path(str(SOURCE), run_name='__main__')
            self.assertEqual(stopped.exception.code, 2)
            launch.assert_not_called()
            self.assertEqual(prior.read_bytes(), b'prior-run-evidence')
            self.assertFalse((out / 'summary.json').exists())

    def test_acceptance_does_not_impose_new_rss_limit(self):
        code, summary, stdout, stderr, _ = self.invoke("import time; print('success',flush=True); time.sleep(.1)", high_rss=True)
        self.assertEqual((code, summary['status']), (0, 'passed'))
        self.assertIsNone(summary['commands'][0]['rss_limit_bytes'])
        self.assertEqual(summary['commands'][0]['sampled_process_tree_rss_peak_bytes'], 1024 * 1024 * 1024)

    def test_source_mutation_addition_and_removal_fail_evidence_binding(self):
        code, summary, _, _, _ = self.invoke("print('done')", source_fault='mutated')
        self.assertEqual((code, summary['status']), (1, 'failed'))
        self.assertTrue(all(row['status'] == 'passed' for row in summary['commands']))
        self.assertEqual(summary['source_changes'], {
            'added': ['added.mbt'], 'removed': ['removed.mbt'], 'modified': ['source.mbt']})
        self.assertNotEqual(summary['source_sha256_before']['source.mbt'],
                            summary['source_sha256']['source.mbt'])

    def test_unreadable_source_preserves_failed_summary(self):
        code, summary, _, _, _ = self.invoke("print('done')", source_fault='unreadable')
        self.assertEqual((code, summary['status']), (1, 'failed'))
        self.assertEqual(summary['source_metadata_errors'], [
            {'phase': phase, 'path': 'source.mbt', 'error': 'PermissionError'}
            for phase in ('before', 'after')])

    def test_in_source_output_never_becomes_source_input(self):
        code, summary, _, _, _ = self.invoke("print('done')", in_source_output=True)
        self.assertEqual((code, summary['status']), (0, 'passed'))
        self.assertEqual(summary['source_sha256_before'], summary['source_sha256'])
        self.assertEqual(set(summary['source_sha256']),
                         {'scripts/acceptance.py', 'source.mbt', 'removed.mbt'})
        self.assertEqual(summary['source_changes'], {'added': [], 'removed': [], 'modified': []})

    def test_existing_runner_default_rss_limit_is_unchanged(self):
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp)
            with patch('bounded_run.process_rss', return_value=1024 * 1024 * 1024):
                record = REAL_EXECUTE([sys.executable, '-c', 'import time; time.sleep(20)'], out, out, 'default')
            self.assertEqual(record['stop_reason'], 'RSS limit exceeded')
            self.assertEqual(record['rss_limit_bytes'], 512 * 1024 * 1024)
            self.assertNotEqual(record['status'], 'passed')


if __name__ == '__main__':
    unittest.main()

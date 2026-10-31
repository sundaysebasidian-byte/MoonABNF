"""Own process-group regressions. Synthetic sleepers only; never user processes."""
import json,os,signal,subprocess,sys,tempfile,time,unittest,shlex
from pathlib import Path
from unittest.mock import patch
from bounded_run import execute, process_rss, process_group_running

def live(pid):
    p=subprocess.run(['ps','-o','stat=','-p',str(pid)],capture_output=True,text=True)
    return bool(p.stdout.strip()) and not p.stdout.strip().startswith('Z')

class GroupCleanup(unittest.TestCase):
    def run_case(self,source,seconds=.5):
        with tempfile.TemporaryDirectory() as tmp:
            d=Path(tmp)
            record=execute([sys.executable,'-c',source],d,d,'probe',seconds=seconds)
            output=(d/'probe.stdout.txt').read_text()
            return record,output

    def test_normal_and_nonzero_exit_controls(self):
        r,out=self.run_case('print("normal")')
        self.assertEqual(r['status'],'passed');self.assertEqual(out,'normal\n')
        r,_=self.run_case('raise SystemExit(7)')
        self.assertEqual(r['exit_code'],7);self.assertNotEqual(r['status'],'passed')

    def test_orphan_after_success_is_cleaned_and_not_passed(self):
        r,out=self.run_case("import subprocess,sys; c=subprocess.Popen([sys.executable,'-c','import time;time.sleep(20)']); print(c.pid,flush=True)")
        pid=int(out.strip())
        try:
            self.assertFalse(live(pid));self.assertEqual(r['exit_code'],0)
            self.assertEqual(r['stop_reason'],'descendants remained after command exit')
            self.assertNotEqual(r['status'],'passed')
        finally:
            if live(pid):os.kill(pid,signal.SIGKILL)

    def test_timeout_leader_exit_does_not_leave_stubborn_descendant(self):
        r,out=self.run_case("import subprocess,sys,time; c=subprocess.Popen([sys.executable,'-c','import signal,time;signal.signal(signal.SIGTERM,signal.SIG_IGN);time.sleep(20)']); print(c.pid,flush=True);time.sleep(20)")
        pid=int(out.strip())
        try:self.assertFalse(live(pid));self.assertEqual(r['stop_reason'],'wall timeout')
        finally:
            if live(pid):os.kill(pid,signal.SIGKILL)

    def test_failed_monitor_still_cleans_owned_group(self):
        with patch('bounded_run.process_group_running',side_effect=OSError('synthetic ps failure')):
            r,_=self.run_case('print("done")')
        self.assertNotEqual(r['status'],'passed');self.assertIn('resource monitor failed',r['stop_reason'])

    def test_monitor_commands_cannot_wait_forever_for_ps(self):
        with tempfile.TemporaryDirectory() as tmp:
            fake = Path(tmp) / 'ps'
            # exec keeps the synthetic sleeper as the direct child, not an orphan.
            fake.write_text('#!/bin/sh\nexec ' + shlex.quote(sys.executable) +
                            ' -c ' + shlex.quote('import time; time.sleep(20)') + '\n')
            fake.chmod(0o755)
            with patch.dict(os.environ, {'PATH': tmp + os.pathsep + os.environ['PATH']}):
                start = time.monotonic()
                for monitor in (process_rss, process_group_running):
                    with self.assertRaises(subprocess.TimeoutExpired):
                        monitor(os.getpid())
                self.assertLess(time.monotonic() - start, 10)

    def test_monitor_preflight_failure_starts_nothing(self):
        with patch('bounded_run.process_rss',side_effect=OSError('preflight')),patch('bounded_run.subprocess.Popen') as launch:
            with self.assertRaises(OSError):self.run_case('print("never")')
            launch.assert_not_called()

if __name__=='__main__':unittest.main()

"""Keep first-reader diagnostic streams even when its collector is interrupted."""
import argparse
import base64
import hashlib
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import time

ROOT = Path(__file__).resolve().parents[3]
AUDIT = 'docs/audits/original-join-parent-acceptance-20261018/'
SELF = AUDIT + 'profile_first_reader.py'
FILES = ('started.json', 'samples.jsonl', 'stdout.bin', 'stderr.bin')


def blob(body):
    return dict(bytes=len(body), sha256=hashlib.sha256(body).hexdigest(),
                body_base64=base64.b64encode(body).decode())


def durable(path, body):
    with path.open('xb') as stream:
        stream.write(body)
        stream.flush()
        os.fsync(stream.fileno())


def local(path):
    assert path.is_relative_to(ROOT / '.artifacts/tmp/tests')
    for member in (*reversed(path.parents), path):
        if member == ROOT or not member.is_relative_to(ROOT):
            continue
        assert not member.is_symlink(), 'ordinary local diagnostic path'
        if member.exists():
            assert member.stat().st_dev == ROOT.stat().st_dev
            assert not (member.is_dir() and (member / '.git').exists()), 'primary repository only'
            assert not ((member / 'HEAD').exists() and (member / 'objects').exists()), 'no foreign bare repository'
    return path


def sample(argv):
    result = subprocess.run(argv, cwd=ROOT, stdin=subprocess.DEVNULL, capture_output=True, timeout=15)
    return dict(command=argv, status=result.returncode, stdout=blob(result.stdout), stderr=blob(result.stderr))


def monitor(directory, command, fixture=False):
    local(directory)
    directory.mkdir()
    durable(directory / 'started.json', (json.dumps(dict(command=command,
        programme=blob((ROOT / SELF).read_bytes()), fixture=fixture), sort_keys=True) + '\n').encode())
    with (directory / 'stdout.bin').open('xb', buffering=0) as stdout, (directory / 'stderr.bin').open('xb', buffering=0) as stderr, (directory / 'samples.jsonl').open('xb', buffering=0) as samples:
        process = subprocess.Popen(command, cwd=ROOT, stdin=subprocess.DEVNULL, stdout=stdout, stderr=stderr)
        while True:
            row = dict(fixture=True) if fixture else dict(host=[sample(['sysctl', '-n', 'hw.memsize']), sample(['vm_stat'])],
                processes=sample(['ps', '-axo', 'pid=,ppid=,rss=']))
            samples.write((json.dumps(row, sort_keys=True) + '\n').encode())
            os.fsync(samples.fileno())
            if process.poll() is not None:
                break
            time.sleep(0.5)
        status = process.wait()
        os.fsync(stdout.fileno())
        os.fsync(stderr.fileno())
        if fixture:
            # The harmless child is complete and reaped. Interrupt only this
            # collector before final publication; no background child survives.
            durable(directory / 'ready', b'child reaped; streams flushed\n')
            while True:
                time.sleep(1)
    durable(directory / 'finished.json', (json.dumps(dict(status=status)) + '\n').encode())


def retained(directory):
    result = {}
    for name in FILES:
        path = directory / name
        assert path.is_file() and not path.is_symlink(), 'complete partial member: ' + name
        result[name] = blob(path.read_bytes())
    assert not (directory / 'finished.json').exists(), 'partial evidence never means completed'
    return result


def self_test():
    parent = local(ROOT / '.artifacts/tmp/tests')
    assert parent.is_dir() and not parent.is_symlink() and parent.stat().st_dev == ROOT.stat().st_dev
    with tempfile.TemporaryDirectory(prefix='first-reader-retention-', dir=parent) as temporary:
        directory = Path(temporary) / 'capture'
        process = subprocess.Popen(['python3', '-B', SELF, '--fixture', str(directory.relative_to(ROOT))],
                                   cwd=ROOT, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        try:
            deadline = time.monotonic() + 10
            while not (directory / 'ready').exists():
                assert process.poll() is None, 'fixture collector unexpectedly stopped'
                assert time.monotonic() < deadline, 'fixture readiness deadline'
                time.sleep(0.02)
            before = retained(directory)
            process.send_signal(signal.SIGTERM)
            stdout, stderr = process.communicate(timeout=10)
            assert process.returncode == -signal.SIGTERM and stdout == stderr == b''
            after = retained(directory)
            assert before == after, 'all flushed partial evidence survives collector termination'
            assert base64.b64decode(after['stdout.bin']['body_base64']) == b'fixture stdout\n'
            assert base64.b64decode(after['stderr.bin']['body_base64']) == b'fixture stderr\n'
            controls = []
            for name in FILES:
                path = directory / name
                body = path.read_bytes()
                path.unlink()
                try:
                    retained(directory)
                except AssertionError as error:
                    controls.append(dict(omitted=name, refusal=str(error)))
                else:
                    raise AssertionError('missing partial member admitted')
                durable(path, body)
            return dict(schema='fsmgen.first_reader_retention_test.v1', source=blob((ROOT / SELF).read_bytes()),
                before=before, after=after, collector_status=process.returncode, controls=controls,
                scope='Actual harmless child completed and was reaped; its collector was then terminated before final publication. Exact started/sample/child-stream bytes survive, and real missing-file controls refuse. This proves partial retention only, not original saved-reader phase/resource attribution.')
        finally:
            if process.poll() is None:
                process.terminate()
                process.communicate(timeout=10)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument('--self-test', action='store_true')
    mode.add_argument('--fixture')
    mode.add_argument('--run', action='store_true')
    args = parser.parse_args()
    if args.self_test:
        print(json.dumps(self_test(), sort_keys=True))
        return
    if args.fixture:
        relative = Path(args.fixture)
        assert not relative.is_absolute() and '..' not in relative.parts
        directory = ROOT / relative
        assert directory.parent.is_relative_to(ROOT / '.artifacts/tmp/tests')
        command = ['python3', '-B', '-c', 'import sys; print("fixture stdout"); print("fixture stderr", file=sys.stderr)']
        monitor(directory, command, fixture=True)
        return
    # An outer caller supplies the unchanged RAM guard. The diagnostic's own
    # guard protects the reader even if the collector is lost. The directory
    # is printed before launch so its partial streams remain discoverable.
    parent = local(ROOT / '.artifacts/tmp/tests')
    directory = Path(tempfile.mkdtemp(prefix='first-reader-profile-', dir=parent))
    directory.rmdir()
    print(str(directory.relative_to(ROOT)), flush=True)
    tracer = "import json,resource,runpy,sys\nnames={'load','sources','failed','controls','diagnosis','validate_sources','premises'}\ndef profile(frame,event,arg):\n    if event in ('call','return') and frame.f_code.co_name in names and '/original-join-parent-acceptance-20261018/' in frame.f_code.co_filename:\n        print(json.dumps({'event':event,'function':frame.f_code.co_name,'source':frame.f_code.co_filename.split('/original-join-parent-acceptance-20261018/')[-1],'maxrss_raw':resource.getrusage(resource.RUSAGE_SELF).ru_maxrss}),file=sys.stderr,flush=True)\nsys.path.insert(0,'docs/audits/original-join-parent-acceptance-20261018')\nsys.setprofile(profile)\nrunpy.run_path('docs/audits/original-join-parent-acceptance-20261018/verify_failed.py',run_name='__main__')\n"
    command = ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', '-c', tracer]
    monitor(directory, command)
    print('Retained complete diagnostic at', directory.relative_to(ROOT))


if __name__ == '__main__':
    if not __debug__:
        raise SystemExit('Acceptance assertions must be enabled.')
    main()

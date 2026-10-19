"""Retain the next actual complete helper, including interrupted partial files."""
import base64
import hashlib
import json
import os
from pathlib import Path
import shlex
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[3]
AUDIT = 'docs/audits/original-join-parent-acceptance-20261018/'
SELF = AUDIT + 'run_complete_reader_sequence.py'
HELPER = AUDIT + 'verify_claim_readers.sh'
TASK = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'


def blob(body):
    return dict(bytes=len(body), sha256=hashlib.sha256(body).hexdigest(),
                body_base64=base64.b64encode(body).decode())


def native(*args):
    result = subprocess.run(['git', '--no-replace-objects', *args], cwd=ROOT,
                            stdin=subprocess.DEVNULL, capture_output=True, timeout=30)
    assert result.returncode == 0 and result.stderr == b''
    return result.stdout


def boundary():
    revision = native('rev-parse', 'HEAD').decode().strip()
    assert native('diff', '--cached', '--name-only') == b''
    assert native('diff', '--name-only').decode().splitlines() == [TASK]
    status = native('status', '--porcelain=v1', '--untracked-files=all').decode().splitlines()
    assert [line for line in status if not line.startswith('?? ')] == [' M ' + TASK]
    allowed = {SELF, AUDIT + 'complete-reader-sequence-capture.json.gz', AUDIT + 'complete-reader-later-host.json.gz'}
    assert {line[3:] for line in status if line.startswith('?? ')} <= allowed, 'exact owning worktree boundary'
    sources = {path: (ROOT / path).read_bytes() for path in
               (HELPER, AUDIT + 'live_operand_route.py', AUDIT + 'frozen_operand_route.py',
                AUDIT + 'rollover_source_card.py')}
    for path, body in sources.items():
        assert body == native('show', revision + ':' + path), 'native current source: ' + path
    return dict(revision=revision, native_tree=blob(native('ls-tree', '--full-tree', '-r', '-z', revision)),
        status=status, task=blob((ROOT / TASK).read_bytes()), programme=blob((ROOT / SELF).read_bytes()),
        route_sources={path: blob(body) for path, body in sources.items()})


def publish(directory, name, value):
    with (directory / name).open('xb') as stream:
        stream.write((json.dumps(value, sort_keys=True) + '\n').encode())
        stream.flush()
        os.fsync(stream.fileno())


def main():
    parent = ROOT / '.artifacts/tmp/tests'
    for member in (*reversed(parent.parents), parent):
        if member == ROOT or not member.is_relative_to(ROOT):
            continue
        assert not member.is_symlink() and member.stat().st_dev == ROOT.stat().st_dev
        assert not (member / '.git').exists()
        assert not ((member / 'HEAD').exists() and (member / 'objects').exists())
    directory = Path(tempfile.mkdtemp(prefix='complete-reader-sequence-', dir=parent))
    print(str(directory.relative_to(ROOT)), flush=True)
    before = boundary()
    publish(directory, 'started.json', before)
    listing = subprocess.run(['bash', HELPER, '--list'], cwd=ROOT, stdin=subprocess.DEVNULL, capture_output=True)
    commands = [shlex.split(line) for line in listing.stdout.decode().splitlines()]
    publish(directory, 'listing.json', dict(command=['bash', HELPER, '--list'], status=listing.returncode,
        stdout=blob(listing.stdout), stderr=blob(listing.stderr), commands=commands))
    assert listing.returncode == 0 and listing.stderr == b''
    assert commands[-1] == ['python3', '-B', AUDIT + 'live_operand_route.py', '--current']
    command = ['scripts/run_with_ram_guard.sh', '--', 'bash', HELPER]
    with (directory / 'stdout.bin').open('xb', buffering=0) as stdout, (directory / 'stderr.bin').open('xb', buffering=0) as stderr:
        result = subprocess.run(command, cwd=ROOT, stdin=subprocess.DEVNULL, stdout=stdout, stderr=stderr)
        os.fsync(stdout.fileno())
        os.fsync(stderr.fileno())
    # Actual streams and status survive even a later source-boundary refusal.
    publish(directory, 'finished.json', dict(command=command, status=result.returncode))
    try:
        after = boundary()
        assert after == before, 'whole tracked/owning boundary unchanged'
    except Exception as error:
        publish(directory, 'after.json', dict(value=None, error_type=type(error).__name__, error=str(error)))
        raise
    publish(directory, 'after.json', dict(value=after, error_type=None, error=None))
    print('Complete helper status:', result.returncode, flush=True)
    raise SystemExit(result.returncode)


if __name__ == '__main__':
    if not __debug__:
        raise SystemExit('Acceptance assertions must be enabled.')
    main()

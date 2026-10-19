"""Retain one actual advertised current-authorizer sequence, including failure."""
import argparse
import base64
import gzip
import hashlib
import json
from pathlib import Path
import shlex
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[3]
AUDIT = 'docs/audits/original-join-parent-acceptance-20261018/'
SELF = AUDIT + 'run_reader_sequence.py'
HELPER = AUDIT + 'verify_claim_readers.sh'
TASK = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
REVISION = '0213f8268b3b3caad5dabc96a3eb81e270565dfe'
OUTPUT = AUDIT + 'reader-sequence-first.json.gz'


def blob(body):
    return dict(bytes=len(body), sha256=hashlib.sha256(body).hexdigest(),
                body_base64=base64.b64encode(body).decode())


def run(command):
    value = subprocess.run(command, cwd=ROOT, stdin=subprocess.DEVNULL, capture_output=True)
    return dict(command=command, status=value.returncode,
                stdout=blob(value.stdout), stderr=blob(value.stderr))


def git(*args):
    result = run(['git', '--no-replace-objects', *args])
    assert result['status'] == 0 and result['stderr']['bytes'] == 0, result
    return base64.b64decode(result['stdout']['body_base64'])


def boundary():
    assert git('rev-parse', 'HEAD').decode().strip() == REVISION, 'exact sequence input revision'
    changed = git('diff', '--name-only').decode().splitlines()
    assert changed == [TASK], 'only owning task progress may differ from HEAD'
    assert git('diff', '--cached', '--name-only') == b'', 'no concurrent staged slice'
    status = git('status', '--porcelain=v1', '--untracked-files=all').decode().splitlines()
    assert status == [' M ' + TASK, '?? ' + SELF], 'complete primary worktree input boundary'
    helper = (ROOT / HELPER).read_bytes()
    assert helper == git('show', REVISION + ':' + HELPER), 'native exact helper source'
    # Native current gate and all other tracked sources/data are identified by
    # the complete tree below. This is no claim about ignored inputs, inherited
    # environment, transitive runtime effects or original prelaunch custody.
    return dict(revision=REVISION, tree=blob(git('ls-tree', '--full-tree', '-r', '-z', REVISION)),
        status=status, task=blob((ROOT / TASK).read_bytes()),
        programme=blob((ROOT / SELF).read_bytes()), helper=blob(helper))


def main():
    if not __debug__:
        raise SystemExit('Acceptance assertions must be enabled.')
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true', required=True)
    parser.parse_args()
    output = ROOT / OUTPUT
    assert not output.exists() and not output.is_symlink(), 'exclusive first sequence capture'
    before = boundary()
    listing = run(['bash', HELPER, '--list'])
    assert listing['status'] == 0 and listing['stderr']['bytes'] == 0, listing
    commands = [shlex.split(line) for line in base64.b64decode(listing['stdout']['body_base64']).decode().splitlines()]
    assert commands[-1] == ['python3', '-B', AUDIT + 'live_operand_route.py', '--current']
    actual = run(['scripts/run_with_ram_guard.sh', '--', 'bash', HELPER])
    after = boundary()
    assert after == before, 'complete tracked/owning-input boundary unchanged during sequence'
    value = dict(schema='fsmgen.actual_reader_sequence.v1', before=before, after=after,
        listing=listing, commands=commands, actual=actual,
        python_version=sys.version,
        scope='Actual complete advertised helper under the unchanged RAM guard. The full native tracked tree, owning progress, producer/helper bodies, listing and complete streams/status retain. Static helper protocol and its current gate establish ordered child membership; this capture does not infer per-child timing or original callable/default/effect/runtime/native/private authority. Ignored-input and inherited-environment closure remain outside this tracked boundary and under existing original-source/effects/custody owners. No original semantic cohort or spent capture is invoked.')
    with output.open('xb') as stream:
        stream.write(gzip.compress((json.dumps(value, sort_keys=True) + '\n').encode(), mtime=0))
    print('Actual reader sequence exit status:', actual['status'])
    print(base64.b64decode(actual['stdout']['body_base64']).decode())
    print(base64.b64decode(actual['stderr']['body_base64']).decode(), file=sys.stderr)
    raise SystemExit(actual['status'])


if __name__ == '__main__':
    main()

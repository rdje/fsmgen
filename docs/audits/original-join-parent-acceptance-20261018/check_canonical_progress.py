"""Exercise saved/current role separation and actual legitimate task progress."""
import argparse
import contextlib
import gzip
import io
import json
from pathlib import Path
import subprocess
import sys

import canonical_contracts as contracts
import prepare

ROOT, AUDIT = prepare.ROOT, prepare.AUDIT
SELF = AUDIT / 'check_canonical_progress.py'
PATH = AUDIT / 'canonical-contract-progress-qualified.json.gz'
LEAF = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.4.3.3.2.2.3.3.2.3.3.2.1.3.2.1.2.3.5.3.3.2'
SCOPE = ('Actual current own-progress-only task change passes saved and explicit current CLI; exact bytes restore. '
         'Real denied-read and narrowed-source-image interventions distinguish frozen/current roles. '
         'No original semantic/cohort, source mutation outside this owned task, or original native/private permission follows.')
SAVED_LINE = 'Saved canonical Goal/Acceptance, complete membership and archive/inline controls qualify; original semantic admission remains unchanged.\n'
CURRENT_LINE = 'Current original obligations also conserve through canonical task storage.\n'


def role(current, image=None):
    previous_read, previous_argv = Path.read_bytes, sys.argv
    attempted, output = [], io.StringIO()

    def controlled(path):
        if path == ROOT / prepare.TASK:
            attempted.append(prepare.TASK)
            if image is None:
                raise AssertionError('deliberately denied live task read')
            return image
        return previous_read(path)

    try:
        Path.read_bytes = controlled
        sys.argv = ['canonical_contracts.py', *(['--current'] if current else [])]
        with contextlib.redirect_stdout(output):
            try:
                contracts.main()
            except AssertionError as error:
                return dict(current=current, reads=attempted, stdout=output.getvalue(), error=str(error))
            return dict(current=current, reads=attempted, stdout=output.getvalue(), error=None)
    finally:
        Path.read_bytes, sys.argv = previous_read, previous_argv


def collect():
    task = ROOT / prepare.TASK
    before = task.read_bytes()
    graph = prepare.nodes(before)
    assert prepare.field(graph[LEAF], 'Status') == 'in_progress'
    candidate = before.replace(graph[LEAF], contracts.changed_field(graph[LEAF], 'Status', 'pending'), 1)
    actual = []
    try:
        task.write_bytes(candidate)
        for flags in ([], ['--current']):
            command = ['python3', '-B', str(AUDIT / 'canonical_contracts.py'), *flags]
            result = subprocess.run(command, cwd=ROOT, stdin=subprocess.DEVNULL, capture_output=True)
            actual.append(dict(command=command, status=result.returncode, stdout=prepare.blob(result.stdout), stderr=prepare.blob(result.stderr)))
            assert result.returncode == 0 and not result.stderr
    finally:
        task.write_bytes(before)
    assert task.read_bytes() == before
    denied_saved, denied_current = role(False), role(True)
    assert denied_saved['reads'] == [] and denied_saved['error'] is None
    assert denied_current['reads'] == [prepare.TASK] and denied_current['error'] == 'deliberately denied live task read'
    plan, _, original, _ = prepare.premises()
    family = graph[plan['family']]
    narrowed = before.replace(family, contracts.changed_field(family, 'Goal', 'narrowed current original scope'), 1)
    changed_saved, changed_current = role(False, narrowed), role(True, narrowed)
    assert changed_saved['reads'] == [] and changed_saved['error'] is None
    assert changed_current['reads'] == [prepare.TASK] and 'Goal' in changed_current['error']
    return dict(schema='fsmgen.canonical_progress_roles.v1', leaf=LEAF,
        before=prepare.blob(before), candidate=prepare.blob(candidate), actual=actual,
        roles=dict(denied_saved=denied_saved, denied_current=denied_current,
                   changed_saved=changed_saved, changed_current=changed_current),
        narrowed=prepare.blob(narrowed), source=prepare.blob((ROOT / SELF).read_bytes()),
        scope=SCOPE)


def review(value):
    assert set(value) == {'schema', 'leaf', 'before', 'candidate', 'actual', 'roles', 'narrowed', 'source', 'scope'}
    contracts.equal(value['schema'], 'fsmgen.canonical_progress_roles.v1')
    contracts.equal(value['leaf'], LEAF)
    contracts.equal(value['scope'], SCOPE)
    contracts.equal(value['source'], prepare.blob((ROOT / SELF).read_bytes()))
    before, candidate = prepare.unblob(value['before']), prepare.unblob(value['candidate'])
    body = prepare.nodes(before)[LEAF]
    assert candidate == before.replace(body, contracts.changed_field(body, 'Status', 'pending'), 1)
    plan, _, original, _ = prepare.premises()
    assert prepare.check_contracts(before, original, plan) and prepare.check_contracts(candidate, original, plan)
    for row, flags in zip(value['actual'], ([], ['--current'])):
        contracts.equal(row['command'], ['python3', '-B', str(AUDIT / 'canonical_contracts.py'), *flags])
        contracts.equal(row['status'], 0)
        assert prepare.unblob(row['stderr']) == b''
        contracts.equal(prepare.unblob(row['stdout']), (SAVED_LINE + (CURRENT_LINE if flags else '')).encode())
    assert len(value['actual']) == 2
    family = prepare.nodes(before)[plan['family']]
    expected_narrowed = before.replace(family, contracts.changed_field(family, 'Goal', 'narrowed current original scope'), 1)
    contracts.equal(value['narrowed'], prepare.blob(expected_narrowed))
    contracts.equal(value['roles'], dict(
        denied_saved=dict(current=False, reads=[], stdout=SAVED_LINE, error=None),
        changed_saved=dict(current=False, reads=[], stdout=SAVED_LINE, error=None),
        denied_current=dict(current=True, reads=[prepare.TASK], stdout='', error='deliberately denied live task read'),
        changed_current=dict(current=True, reads=[prepare.TASK], stdout='', error=str((plan['family'], 'Goal')))))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    value = collect() if args.write else json.loads(gzip.decompress((ROOT / PATH).read_bytes()))
    review(value)
    if args.write:
        with (ROOT / PATH).open('xb') as stream:
            stream.write(gzip.compress(prepare.encoded(value), mtime=0))
    print('Actual legitimate progress and denied/changed live-task interventions preserve distinct saved/current roles.')


if __name__ == '__main__':
    if not __debug__:
        raise SystemExit('Acceptance assertions must be enabled.')
    main()

"""Qualify captured instrument identities without loosening operational intake."""
import argparse
import contextlib
import copy
import gzip
import json
from pathlib import Path
import subprocess

import prepare
import selected_intake as intake

ROOT, AUDIT = prepare.ROOT, prepare.AUDIT
SELF = AUDIT / 'qualify_selected_intake_roles.py'
PATH = AUDIT / 'selected-intake-roles-qualified.json.gz'
BASE = 'bf34e8bf402896c8d6d5a331a815191117f9403f'
SCOPE = ('Captured selected-intake instrument identities only: exact native Git data, unchanged saved '
         'profile, explicit failed-custody consumer and strict operational defaults. Other evidence and '
         'manifest dependencies retain their existing exact checks. Source-image/denied-read and metadata '
         'predicate interventions are inert controls, never original cohort execution or live admission. '
         'The actual current CLI remains refused; no original native0 custody gap, spent cohort, source '
         'model, semantic/native/private/HIAL or full-CI gate closes.')
SAVED_LINE = ('Closed selected-checkout intake preserves all original commands/contracts and three failed '
              'intakes; no semantic reader executes.\n')
FAILED_LINE = ('Retained native0 prerequisites and exact after-cache custody gap qualify as failed acceptance; '
               'complete later source/cache/query and genuine refusal controls pass.\n')


def native(path):
    return intake.execute.command(['git', '--no-replace-objects', 'show', BASE + ':' + str(path)])


def sources():
    return {name: prepare.blob((ROOT / AUDIT / name).read_bytes()) for name in
            ('selected_intake.py', 'verify_selected_failed.py', 'qualify_selected_intake_roles.py')}


def unblob(row):
    body = prepare.unblob(row)
    intake.exact(row, prepare.blob(body))
    return body


def reference():
    body = native(AUDIT / 'selected-intake.json.gz')
    assert (ROOT / AUDIT / 'selected-intake.json.gz').read_bytes() == body, 'original saved profile unchanged'
    value = json.loads(gzip.decompress(body))
    intake.exact(value, intake.profile(captured=True))
    instruments = {}
    for name in intake.INSTRUMENTS:
        path = AUDIT / name
        raw = intake.execute.command(['git', '--no-replace-objects', 'show', intake.REVISION + ':' + str(path)])
        assert raw == intake.captured_instrument(name)
        intake.exact(value['instruments'][name], prepare.identity(raw))
        instruments[name] = prepare.blob(raw)
    return dict(profile=prepare.blob(body), instruments=instruments,
                revision=intake.REVISION, retention_contract='fsmgen_required_history')


@contextlib.contextmanager
def supplied_instruments(bodies, denied=False):
    read = intake.execute.read
    attempted = []

    def provider(path):
        if str(path) == str(AUDIT / 'prepare.py'):
            attempted.append(str(path))
            if denied:
                raise AssertionError('deliberately denied current prepare instrument')
            return bodies['prepare.py']
        return read(path)

    try:
        intake.execute.read = provider
        yield attempted
    finally:
        intake.execute.read = read


def outcome(action):
    try:
        action()
    except AssertionError as error:
        return dict(accepted=False, error=str(error))
    return dict(accepted=True, error=None)


def controls(fixed):
    profile = json.loads(gzip.decompress(unblob(fixed['profile'])))
    bodies = {name: unblob(row) for name, row in fixed['instruments'].items()}
    rows = []
    # Supply only the historical prepare image. All other sources and evidence
    # keep their ordinary checks. This is not an actual current source image.
    for role, supplied, denied in (
        ('historical-image', bodies, False),
        ('changed-image', dict(bodies, **{'prepare.py': b'x' + bodies['prepare.py'][1:]}), False),
        ('denied-image', bodies, True)):
        for captured in (False, True):
            with supplied_instruments(supplied, denied) as attempted:
                result = outcome(lambda: intake.validate(profile, captured=captured))
            expected = role == 'historical-image' or captured
            assert result['accepted'] is expected, (role, captured, result)
            assert attempted == ([] if captured else [str(AUDIT / 'prepare.py')])
            rows.append(dict(role=role, captured=captured, reads=attempted, result=result))
    # The actual operational path must continue through the strict default.
    for label, action in (
        ('validate', lambda: intake.validate(profile)),
        ('effective', lambda: intake.effective(profile)),
        ('cwd', lambda: intake.cwd('prerequisites', profile)),
        ('observation', lambda: intake.validate_observation('prerequisites', None, profile))):
        with supplied_instruments(bodies, True) as attempted:
            result = outcome(action)
        assert result == dict(accepted=False, error='deliberately denied current prepare instrument')
        assert attempted == [str(AUDIT / 'prepare.py')]
        rows.append(dict(role='strict-operational-' + label, reads=attempted, result=result))
    # Isolate the exact profile predicate, matching the retained before-fix
    # float intervention. Integrated actual CLI/consumer runs are separate.
    original = intake.profile
    try:
        intake.profile = lambda **kwargs: profile
        for label in ('float-bytes', 'missing-instrument', 'changed-evidence', 'changed-command', 'changed-scope'):
            candidate = copy.deepcopy(profile)
            name = next(iter(candidate['instruments']))
            if label == 'float-bytes': candidate['instruments'][name]['bytes'] = float(candidate['instruments'][name]['bytes'])
            elif label == 'missing-instrument': del candidate['instruments'][name]
            elif label == 'changed-evidence': candidate['evidence'][next(iter(candidate['evidence']))]['sha256'] = '0' * 64
            elif label == 'changed-command': candidate['commands']['prerequisites'] = ['true']
            else: candidate['scope'] += ' borrowed admission'
            result = outcome(lambda: intake.validate(candidate, captured=True))
            assert not result['accepted'], label
            rows.append(dict(role='metadata-' + label, candidate=candidate, result=result))
    finally:
        intake.profile = original
    rows.append(dict(role='closed-native-member', result=outcome(lambda: intake.captured_instrument('../prepare.py'))))
    assert not rows[-1]['result']['accepted']
    # A real native reader with a separating same-length show result must
    # refuse its disagreement with cat-file, rather than trusting one body.
    command = intake.execute.command
    try:
        def changed_show(argv):
            raw = command(argv)
            return b'x' + raw[1:] if argv[2] == 'show' else raw
        intake.execute.command = changed_show
        result = outcome(lambda: intake.captured_instrument('prepare.py'))
        assert not result['accepted']
        rows.append(dict(role='changed-native-show-body', result=result))
    finally:
        intake.execute.command = command
    return rows


def collect():
    fixed = reference()
    actual = []
    for name, flags in (('selected_intake', []), ('selected_intake', ['--current']), ('verify_selected_failed', [])):
        command = ['python3', '-B', str(AUDIT / (name + '.py')), *flags]
        result = subprocess.run(command, cwd=ROOT, stdin=subprocess.DEVNULL, capture_output=True)
        actual.append(dict(command=command, status=result.returncode,
                           stdout=prepare.blob(result.stdout), stderr=prepare.blob(result.stderr)))
    return dict(schema='fsmgen.selected_intake_roles.v1', native=fixed, sources=sources(),
                controls=controls(fixed), actual=actual, scope=SCOPE)


def review(value):
    assert set(value) == {'schema', 'native', 'sources', 'controls', 'actual', 'scope'}
    intake.exact(value['schema'], 'fsmgen.selected_intake_roles.v1')
    intake.exact(value['scope'], SCOPE)
    fixed = reference()
    intake.exact(value['native'], fixed)
    intake.exact(value['sources'], sources())
    intake.exact(value['controls'], controls(fixed))
    actual = value['actual']
    assert type(actual) is list and len(actual) == 3
    for row, name, flags, success, output in zip(actual,
            ('selected_intake', 'selected_intake', 'verify_selected_failed'),
            ([], ['--current'], []), (True, False, True), (SAVED_LINE, '', FAILED_LINE)):
        assert set(row) == {'command', 'status', 'stdout', 'stderr'}
        intake.exact(row['command'], ['python3', '-B', str(AUDIT / (name + '.py')), *flags])
        intake.exact(row['status'], 0 if success else 1)
        intake.exact(unblob(row['stdout']), output.encode())
        stderr = unblob(row['stderr'])
        if success:
            assert stderr == b''
        else:
            assert stderr.startswith(b'Traceback (most recent call last):\n') and stderr.endswith(b'AssertionError\n')
            assert b'in fixed\n' in stderr and b'body == execute.command' in stderr


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    value = collect() if args.write else json.loads(gzip.decompress((ROOT / PATH).read_bytes()))
    review(value)
    if args.write:
        with (ROOT / PATH).open('xb') as stream:
            stream.write(gzip.compress(prepare.encoded(value), mtime=0))
    print('Captured instrument identity and unchanged failed custody qualify; strict operational source admission remains refused.')


if __name__ == '__main__':
    if not __debug__:
        raise SystemExit('Acceptance assertions must be enabled.')
    main()

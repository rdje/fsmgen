"""Consume actual independent results and the retained comparison conditions."""
import copy
import hashlib
import json
import re
from pathlib import Path

BASE = Path('docs/audits/coordinate-native-semantic-checks-20261008')
MODEL = Path('docs/audits/record-value-coordinate-native-semantic-20261008')


def need(value, cause):
    if not value:
        raise ValueError(cause)


def pin(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def check(row):
    script = BASE / 'verify_saved.py'
    paths = [BASE / 'run.py', Path('scripts/run_with_ram_guard.sh'), script]
    expected = 'PASS independent complete binary-source/native-wire semantic refusals and positive wrong-root coordinates; no original identity or whole-public promotion.\n'
    need(type(row['status']) is int and row['status'] == 0, 'actual independent reader integer success')
    need(row['command'] == ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', str(script)]
         and row['stdout'] == expected
         and re.fullmatch(r'ram-guard: PID \d+; host [0-9.]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n', row['stderr'])
         and json.dumps(row['instruments'], sort_keys=True) == json.dumps(
             {str(p): pin(p.read_bytes()) for p in paths}, sort_keys=True), 'whole actual independent reader command/streams/instruments')


def main():
    actual = json.loads((BASE / 'saved-result.json').read_bytes()); check(actual)
    controls = []
    for name, mutate, cause in [
        ('Boolean-status', lambda c: c.update(status=False), 'actual independent reader integer success'),
        ('borrowed-instrument', lambda c: c['instruments'].pop(str(BASE / 'verify_saved.py')),
         'whole actual independent reader command/streams/instruments'),
        ('lost-actual-output', lambda c: c.update(stdout=''), 'whole actual independent reader command/streams/instruments'),
    ]:
        candidate = copy.deepcopy(actual); mutate(candidate)
        need(candidate != actual or type(candidate['status']) is not type(actual['status']), 'genuine actual result mutation')
        try:
            check(candidate)
        except ValueError as error:
            need(str(error) == cause, 'intended actual result refusal')
            controls.append(dict(control=name, cause=cause, status=1, candidate=candidate))
        else:
            raise ValueError('false-green actual result control')
    inputs = json.loads((MODEL / 'inputs.json').read_bytes())
    good = inputs['good_wire']; native = inputs['wire']; comparisons = {}
    for name in ('executable_before', 'executable_after'):
        need(good['tools']['executable_identity'] == native['tools'][name],
             'same captured opaque interpreter bytes for controlled comparison')
        comparisons[name] = good['tools']['executable_identity']
    need(good['tools']['modules']['stdout'] == native['tools']['modules']['stdout'],
         'same captured public module versions for controlled comparison')
    comparisons['public_modules'] = json.loads(good['tools']['modules']['stdout'])
    comparisons['environment'] = []
    for row in good['runs'] + native['runs']:
        need(row['environment'] == dict(PERL5OPT='', PERL5LIB='',
            temporary_root=row['actual']['cwd'] + '/.tmp', runtime_absolute_temporary_values=True),
            'same isolated environment recipe with retained actual root')
        comparisons['environment'].append(dict(invocation=row['invocation'], environment=row['environment']))
    proof = dict(actual=actual, controls=controls, comparison_conditions=comparisons,
        independent_proof_identity=pin((BASE / 'proof.json').read_bytes()),
        scope='Dated fixed inputs and actual readers only; no spent capture replay, unmeasured original identity or whole-public signoff.')
    path = BASE / 'actual-proof.json'; raw = json.dumps(proof, sort_keys=True, indent=2) + '\n'
    if path.exists():
        need(path.read_text() == raw, 'whole retained actual proof')
    else:
        path.write_text(raw)
    print('PASS actual independent reader custody and explicit captured comparison conditions; original identities and whole-public qualification remain pending.')


if __name__ == '__main__':
    main()

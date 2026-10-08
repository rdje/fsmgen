"""Qualify the schema mapping and preserve its original actual failure."""
import copy
import hashlib
import json
from pathlib import Path

BASE = Path('docs/audits/coordinate-native-semantic-checks-20261008')
MODEL = Path('docs/audits/record-value-coordinate-native-semantic-20261008')


def need(value, cause):
    if not value:
        raise ValueError(cause)


def check(good, native):
    need(good == native['executable_before'] == native['executable_after'],
         'captured interpreter identities must agree across declared schema fields')


def main():
    first = BASE / 'first-consume_actual.py.txt'; raw = first.read_bytes()
    actual = json.loads((BASE / 'actual-consumption.json').read_bytes())
    identity = dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())
    need(type(actual['status']) is int and actual['status'] == 1
         and actual['stderr'].endswith("KeyError: 'executable_before'\n")
         and actual['instruments'][str(BASE / 'consume_actual.py')] == identity,
         'whole first failed actual and original programme identity')
    first_programme = {'__name__': 'first_comparison_schema'}
    exec(compile(raw, str(first), 'exec'), first_programme)
    try:
        first_programme['main']()
    except KeyError as error:
        need(error.args == ('executable_before',), 'exact original schema failure reproduces')
    else:
        raise ValueError('original schema failure no longer reproduces')
    inputs = json.loads((MODEL / 'inputs.json').read_bytes())
    good = inputs['good_wire']['tools']['executable_identity']; native = inputs['wire']['tools']
    check(good, native)
    controls = []
    for name in ('executable_before', 'executable_after'):
        candidate = copy.deepcopy(native); candidate[name]['sha256'] = '0' * 64
        try:
            check(good, candidate)
        except ValueError as error:
            controls.append(dict(control=name, status=1, cause=str(error), candidate=candidate[name]))
        else:
            raise ValueError('false-green changed interpreter identity')
    proof = dict(original_programme=identity, first_actual=actual, controls=controls,
                 good_identity=good, before=native['executable_before'], after=native['executable_after'],
                 scope='Exact declared historical/new field mapping only; no capture, source or seal changes.')
    path = BASE / 'comparison-proof.json'; saved = json.dumps(proof, sort_keys=True, indent=2) + '\n'
    if path.exists():
        need(path.read_text() == saved, 'whole retained comparison repair proof')
    else:
        path.write_text(saved)
    print('PASS original schema failure, exact identity-field mapping and genuine changed-identity controls; no capture executes.')


if __name__ == '__main__':
    main()

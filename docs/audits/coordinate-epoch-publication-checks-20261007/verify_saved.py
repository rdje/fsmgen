"""Independently consume whole sealed epoch publication and actual seal result."""
import copy
import json
import re
from pathlib import Path

BASE = Path('docs/audits/record-value-coordinate-epoch-publication-20261007')
CHECKS = Path('docs/audits/coordinate-epoch-publication-checks-20261007')
ns = {'__name__': 'independent_epoch_fact', '__file__': str(BASE / 'verify.py')}
exec(compile((BASE / 'verify.py').read_bytes(), ns['__file__'], 'exec'), ns)
require, load, identity = (ns[k] for k in ('require', 'load', 'identity'))


def check(actual):
    require(type(actual['status']) is int and actual['status'] == 0, 'actual epoch seal integer success')
    require(set(actual) == {'command', 'status', 'stdout', 'stderr'} and actual['command'] ==
        ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', str(BASE / 'verify.py'), '--seal']
        and actual['stdout'] == 'PASS complete saved zero-growth epoch fact/source/question/native/actual-result proof; no later current currency or coordinate meaning.\n'
        and re.fullmatch(r'ram-guard: PID [0-9]+; host [0-9.]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n', actual['stderr']),
        'whole actual epoch seal command streams and unchanged guard')


def main():
    manifest = load(BASE / 'manifest.json')
    members = {p.name:identity(p.read_bytes()) for p in BASE.iterdir() if p.name != 'manifest.json'}
    require(ns['current'].same(manifest, members), 'whole independent epoch publication seal')
    proof = ns['derive']()
    require(ns['current'].same(proof, load(BASE / 'source-proof.json')), 'whole independently regenerated source/question/census/allocation proof')
    ns['saved_current'](proof)
    require(ns['current'].same(ns['controls'](proof), load(BASE / 'controls.json')), 'whole independently regenerated epoch result controls')
    actual = load(CHECKS / 'seal.json'); check(actual)
    controls = []
    for status in (True, 0.0, 1):
        candidate = {**actual, 'status': status}
        try:
            check(candidate)
        except ValueError as error:
            require(str(error) == 'actual epoch seal integer success', 'intended actual seal kind/status refusal')
            controls.append(dict(status=repr(status), cause=str(error)))
        else:
            raise ValueError('false-green actual seal status')
    borrowed = load(CHECKS / 'current.json')
    require(type(borrowed['status']) is int and borrowed['status'] == 0, 'genuine current-only successful result')
    try:
        check(borrowed)
    except ValueError as error:
        require(str(error) == 'whole actual epoch seal command streams and unchanged guard', 'intended real borrowed current-only success refusal')
        controls.append(dict(control='borrowed-current-only-success', cause=str(error)))
    else:
        raise ValueError('borrowed current-only success accepted as seal')
    changed = copy.deepcopy(manifest); changed.pop('clause-review.json')
    require(not ns['current'].same(changed, members), 'lost whole semantic clause review refuses complete member conservation')
    print(json.dumps(dict(scope='Complete saved original/added question, zero-growth semantic review, source/query/native/input/instrument/actual-result epoch; no later currency or coordinate meaning.',
        members=len(manifest), controls=controls), sort_keys=True))


if __name__ == '__main__':
    main()

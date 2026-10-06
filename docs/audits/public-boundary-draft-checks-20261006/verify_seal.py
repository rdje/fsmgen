"""Consume the actual draft-only seal; no publication assurance is borrowed."""
import copy
import hashlib
import json
from pathlib import Path

BASE = Path('docs/audits/record-value-public-boundary-draft-20261006')
CHECKS = Path('docs/audits/public-boundary-draft-checks-20261006')
COMMAND = ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', str(BASE / 'verify_draft.py'), '--seal']
SUCCESS = 'PASS exact source-bound draft construction, ordered questions, protected section and non-growing budget; semantic retention/publication remain unqualified.\n'
ns = {'__name__': 'independent_public_boundary_draft'}
exec(compile((BASE / 'verify_draft.py').read_bytes(), str(BASE / 'verify_draft.py'), 'exec'), ns)
require = ns['require']


def load(path):
    return json.loads(path.read_bytes())


def members():
    paths = list(BASE.iterdir())
    require(all(p.is_file() and not p.is_symlink() for p in paths), 'whole regular sealed draft population')
    return {p.name: dict(bytes=len(p.read_bytes()), sha256=hashlib.sha256(p.read_bytes()).hexdigest()) for p in paths}


def header(receipt):
    require(type(receipt['status']) is int and receipt['status'] == 0, 'actual draft seal integer success')
    require(receipt['command'] == COMMAND and receipt['stdout'] == SUCCESS, 'exact actual draft-only seal command/result')
    require(all(type(pin['bytes']) is int and pin['bytes'] >= 0 for pin in receipt['whole_sealed_members'].values()),
            'actual draft receipt discrete member count kinds')
    actual = members()
    require(receipt['whole_sealed_members'] == actual, 'whole actual draft receipt member pins')
    manifest = load(BASE / 'draft-manifest.json')
    require(set(actual) == set(manifest) | {'draft-manifest.json'} and
            all(actual[name] == pin for name, pin in manifest.items()), 'whole immutable draft seal')
    return actual


def main():
    receipt = load(CHECKS / 'sealed-replay.json'); before = header(receipt)
    draft = load(BASE / 'first-card-proposal.json')
    require(ns['check'](draft) == load(BASE / 'draft-proof.json'), 'regenerated whole draft source/question/section/budget proof')
    require(ns['controls'](draft) == load(BASE / 'draft-controls.json'), 'regenerated genuine draft controls and missing semantic leg')
    require(header(receipt) == before, 'every sealed draft byte conserved after independent regeneration')
    tests = []

    def refuse(name, candidate, cause):
        try:
            header(candidate)
        except ValueError as error:
            require(str(error) == cause, 'intended draft receipt refusal: ' + name)
            tests.append(dict(control=name, status=1, cause=str(error)))
        else:
            raise ValueError('false-green draft receipt: ' + name)

    for status in (True, 0.0, 1):
        refuse('status-' + repr(status), {**receipt, 'status': status}, 'actual draft seal integer success')
    for count in (True, 0.0):
        changed = copy.deepcopy(receipt); next(iter(changed['whole_sealed_members'].values()))['bytes'] = count
        refuse('member-count-' + repr(count), changed, 'actual draft receipt discrete member count kinds')
    borrowed = load(Path('docs/audits/public-boundary-join-checks-20261006/sealed-replay.json'))
    require(type(borrowed['status']) is int and borrowed['status'] == 0, 'genuine completed public-header seal success')
    refuse('borrowed-public-header-success', borrowed, 'exact actual draft-only seal command/result')
    print('PASS independently consumed draft seal and regenerated source/control/budget products; semantic retention/publication remain unqualified.')
    for test in tests:
        print(test['control'] + ': refused at ' + test['cause'])


if __name__ == '__main__':
    main()

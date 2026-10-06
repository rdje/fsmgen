"""Consume actual public-profile seal and independently regenerate snapshots."""
import json
from pathlib import Path

BASE = Path('docs/audits/record-value-public-framework-profile-20261006')
CHECKS = Path('docs/audits/public-framework-profile-checks-20261006')
COMMAND = ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', str(BASE / 'verify.py'), '--current', '--seal']
STDOUT = 'PASS complete dated public framework/profile clauses and raw-output replay; original framework/native meanings remain open.\n'


def require(value, cause):
    if not value:
        raise ValueError(cause)


def check(receipt):
    require(type(receipt['status']) is int and receipt['status'] == 0, 'actual public-profile seal integer success')
    require(receipt['command'] == COMMAND and receipt['stdout'] == STDOUT,
            'exact actual current public-profile seal command/result')
    ns = {'__name__': 'public_profile_saved_result'}
    exec(compile((BASE / 'verify.py').read_bytes(), str(BASE / 'verify.py'), 'exec'), ns)
    require(all(type(pin['bytes']) is int and pin['bytes'] >= 0 for pin in receipt['whole_sealed_members'].values()),
            'actual public-profile receipt discrete byte-count kind')
    actual = {p.name: ns['identity'](p.read_bytes()) for p in BASE.iterdir()}
    require(ns['same'](actual, receipt['whole_sealed_members']), 'complete actual sealed public-profile byte identities')
    manifest = ns['load'](BASE / 'manifest.json')
    require(set(actual) == set(manifest) | {'manifest.json'}, 'whole actual public-profile sealed membership')
    for name, pin in manifest.items():
        require(type(pin['bytes']) is int and ns['same'](pin, actual[name]), 'whole public-profile member identity/kind')
    prerequisite = ns['authenticate']()
    record = ns['load'](BASE / 'public-profile.json')
    proof = ns['load'](BASE / 'proofs.json')
    require(ns['same'](proof['clauses'], ns['check'](record))
            and ns['same'](proof['controls'], ns['controls'](record))
            and ns['same'](proof['prior_public_reader'], prerequisite)
            and ns['same'](proof['native_wire_replay'], ns['load'](BASE / 'native-wire.json')),
            'whole independent public contract/control/prior/wire snapshot regeneration')
    first = ns['module'](BASE / 'initial-reader.py.txt')
    first_proof = ns['load'](BASE / 'initial-proofs.json')
    require(ns['same'](first_proof['clauses'], first['check'](record))
            and ns['same'](first_proof['controls'], first['controls'](record)),
            'complete retained first successful programme/products regenerate')
    require(ns['same'](ns['module'](BASE / 'book.py')['proof']((BASE / 'book-input.html').read_text()),
                       ns['load'](BASE / 'book-proof.json')), 'whole saved native public-profile guide/control snapshot')
    require(actual == {p.name: ns['identity'](p.read_bytes()) for p in BASE.iterdir()},
            'every public-profile sealed byte conserved')


def main():
    receipt = json.loads((CHECKS / 'sealed-replay.json').read_bytes())
    check(receipt)
    for status in (True, 0.0, 1):
        try:
            check({**receipt, 'status': status})
        except ValueError as error:
            require(str(error) == 'actual public-profile seal integer success', 'intended public-profile receipt status refusal')
        else:
            raise ValueError('false-green public-profile receipt status')
    changed = json.loads(json.dumps(receipt))
    next(iter(changed['whole_sealed_members'].values()))['bytes'] = True
    try:
        check(changed)
    except ValueError as error:
        require(str(error) == 'actual public-profile receipt discrete byte-count kind', 'intended public-profile receipt byte-kind refusal')
    else:
        raise ValueError('false-green public-profile receipt byte kind')
    borrowed = json.loads(Path('docs/audits/parser-path-publication-checks-20261006/sealed-replay.json').read_bytes())
    require(type(borrowed['status']) is int and borrowed['status'] == 0, 'genuine prior actual successful parser receipt')
    try:
        check(borrowed)
    except ValueError as error:
        require(str(error) == 'exact actual current public-profile seal command/result',
                'actual borrowed parser-only success refuses')
    else:
        raise ValueError('false-green borrowed parser success')
    print('PASS actual public-profile seal, whole saved contract/native/control regeneration and typed/borrowed-result refusals.')


if __name__ == '__main__':
    main()

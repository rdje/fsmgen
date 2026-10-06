"""Independently consume the actual seal and regenerate finite saved roles."""
import copy
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-public-native-fixtures-20261006')
CHECKS = Path('docs/audits/public-native-fixture-checks-20261006')
ns = {'__name__': 'independent_actual_public_fixture_seal'}
exec(compile((BASE / 'verify.py').read_bytes(), str(BASE / 'verify.py'), 'exec'), ns)
require, same, load, identity = (ns[k] for k in ('require', 'same', 'load', 'identity'))
COMMAND = ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', str(BASE / 'verify.py'), '--current', '--seal']
SUCCESS = 'PASS finite independent public callback/eval/load/trace roles and genuine source/native controls; historical/private identities remain open.\n'


def check(receipt):
    require(receipt['command'] == COMMAND and receipt['stdout'] == SUCCESS,
            'exact actual public fixture seal command/result')
    require(type(receipt['status']) is int and receipt['status'] == 0, 'actual public fixture seal integer success')
    actual = {p.name: identity(p.read_bytes()) for p in BASE.iterdir()}
    pins = receipt['whole_sealed_members']
    require(all(type(pin['bytes']) is int for pin in pins.values()), 'actual public fixture discrete member byte-count kind')
    require(same(pins, actual), 'actual complete public fixture sealed byte population')
    before = ns['members']()
    require(same(load(BASE / 'manifest.json'), before), 'whole public fixture manifest population')
    ns['validate_pre'](load(BASE / 'pre-native.json'))
    native = load(BASE / 'native.json'); proof = load(BASE / 'proofs.json')
    require(same(proof['source_model'], ns['check'](native)), 'regenerated full finite public fixture source model')
    require(same(proof['observation_controls'], ns['observation_controls'](native)), 'regenerated genuine public observation controls')
    require(same(proof['source_controls'], ns['source_controls'](load(BASE / 'pre-native.json'))), 'regenerated full public source controls')
    require(same(proof['first_refusal'], ns['first_refusal']()), 'regenerated retained first fixture refusal')
    controls = ns['native_controls'](False)
    require(same(controls, load(BASE / 'native-controls.json')), 'regenerated complete actual native behavioral source/products')
    require(same(proof['native_controls'], {k:dict(status=v['semantic_status'], cause=v['cause']) for k,v in controls.items()}),
            'whole native behavioral separating results')
    book = ns['module'](BASE / 'book.py')
    require(same(load(BASE / 'book-proof.json'), book['proof']((BASE / 'book-input.html').read_text())),
            'regenerated full native fixture guide/control snapshot')
    initial = ns['module'](BASE / 'initial-reader.py.txt')
    try:
        initial['first_refusal']()
    except ValueError as error:
        require(str(error) == 'intended complete first fixture model refusal', 'retained initial serialization-order refusal')
    else:
        raise ValueError('false-green initial reader serialization order')
    command = ['python3', '-B', str(BASE / 'verify.py')]
    p = subprocess.run(command, capture_output=True)
    require(p.returncode == 0 and p.stdout.decode() == SUCCESS and p.stderr == b'', 'actual fresh saved-profile public fixture replay')
    require(ns['members']() == before, 'complete public fixture sealed bytes conserved after regeneration')


def main():
    receipt = load(CHECKS / 'sealed-replay.json'); check(receipt)
    for status in (True, 0.0, 1):
        candidate = {**receipt, 'status': status}
        try:
            check(candidate)
        except ValueError as error:
            require(str(error) == 'actual public fixture seal integer success', 'intended actual receipt status refusal')
        else:
            raise ValueError('false-green public fixture receipt status')
    candidate = copy.deepcopy(receipt)
    next(iter(candidate['whole_sealed_members'].values()))['bytes'] = True
    try:
        check(candidate)
    except ValueError as error:
        require(str(error) == 'actual public fixture discrete member byte-count kind', 'intended receipt member count refusal')
    else:
        raise ValueError('false-green public fixture receipt member count')
    borrowed = load(Path('docs/audits/public-framework-profile-checks-20261006/sealed-replay.json'))
    require(type(borrowed['status']) is int and borrowed['status'] == 0, 'genuine actual prior public-profile-only successful seal')
    try:
        check(borrowed)
    except ValueError as error:
        require(str(error) == 'exact actual public fixture seal command/result', 'actual borrowed public-profile success refuses')
    else:
        raise ValueError('false-green borrowed public-profile-only seal')
    print('PASS actual public fixture seal, complete source/native/first/guide regeneration and typed/borrowed-result refusals.')


if __name__ == '__main__':
    main()

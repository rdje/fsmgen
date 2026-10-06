"""Consume the actual sealed replay and independently verify its file pins."""
import hashlib
import json
from pathlib import Path

BASE = Path('docs/audits/record-value-parser-context-join-20261006')
RECEIPT = Path('docs/audits/parser-context-join-checks-20261006/sealed-replay.json')


def require(value, cause):
    if not value:
        raise ValueError(cause)


def identity(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def check(receipt):
    require(type(receipt['status']) is int and receipt['status'] == 0,
            'actual seal replay integer success')
    require(receipt['command'] == ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B',
                                  str(BASE / 'verify.py'), '--seal'], 'exact actual seal replay command')
    require(receipt['stdout'] == 'PASS complete finite own parser/API/observer/helper/subtest context join and completed nested allocations; opaque native meanings remain open.\n',
            'complete actual context-join replay result')
    require(all(type(pin['bytes']) is int and pin['bytes'] >= 0
                for pin in receipt['whole_sealed_members'].values()),
            'actual seal receipt discrete byte-count kind')
    actual = {p.name: identity(p.read_bytes()) for p in BASE.iterdir() if p.is_file() and not p.is_symlink()}
    require(actual == receipt['whole_sealed_members'], 'whole actual sealed receipt file pins')
    manifest = json.loads((BASE / 'manifest.json').read_bytes())
    require(set(actual) == set(manifest) | {'manifest.json'}, 'complete sealed reader membership')
    for name, pin in manifest.items():
        require(type(pin['bytes']) is int and pin['bytes'] >= 0
                and actual[name] == pin, 'exact sealed reader member identity')
    ns = {'__name__': 'saved_parser_context_join_result'}
    exec(compile((BASE / 'verify.py').read_bytes(), str(BASE / 'verify.py'), 'exec'), ns)
    models = ns['models']()
    native = ns['load'](ns['RAW'] / 'proofs.json')['inventories']
    nested = ns['nested_records'](models)
    saved = ns['load'](BASE / 'proofs.json')
    require(ns['same'](saved['models'], models), 'regenerated complete source model result')
    require(ns['same'](saved['observations'], ns['check'](models, models, native, native, nested, nested))
            and ns['same'](saved['controls'], ns['controls'](models, native, nested)),
            'regenerated whole context-join result and rejecting controls')
    require(actual == {p.name: identity(p.read_bytes()) for p in BASE.iterdir()},
            'sealed programme and product identity unchanged by verification')


def main():
    receipt = json.loads(RECEIPT.read_bytes())
    check(receipt)
    # These receipt controls are separate from the source/native semantic
    # controls already reexecuted above. They prove consumed-result identity.
    for status in (True, 0.0, 1):
        try:
            check({**receipt, 'status': status})
        except ValueError as error:
            require(str(error) == 'actual seal replay integer success', 'intended receipt kind/status refusal')
        else:
            raise ValueError('false-green seal receipt status')
    for byte_count in (True, 0.0):
        changed = json.loads(json.dumps(receipt))
        next(iter(changed['whole_sealed_members'].values()))['bytes'] = byte_count
        try:
            check(changed)
        except ValueError as error:
            require(str(error) == 'actual seal receipt discrete byte-count kind',
                    'intended receipt byte-count kind refusal')
        else:
            raise ValueError('false-green seal receipt byte-count kind')
    print('PASS actual sealed replay, complete file pins, source/context/control regeneration and typed receipt refusals.')


if __name__ == '__main__':
    main()

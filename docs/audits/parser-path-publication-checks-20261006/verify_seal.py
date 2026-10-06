"""Independently consume actual full-publication seal and regenerate snapshots."""
import hashlib
import json
from pathlib import Path

BASE = Path('docs/audits/record-value-parser-path-publication-20261006')
CHECKS = Path('docs/audits/parser-path-publication-checks-20261006')
COMMAND = ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', str(BASE / 'verify.py'),
           '--current', '--build', '.artifacts/parser-path-publication-book', '--seal']
STDOUT = 'PASS complete parser source/visible/context joins with scoped current facts, queries and saved snapshot; broader native meanings remain open.\n'


def require(value, cause):
    if not value:
        raise ValueError(cause)


def identity(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def check(receipt):
    require(type(receipt['status']) is int and receipt['status'] == 0,
            'actual publication seal integer success')
    require(receipt['command'] == COMMAND, 'exact actual source/current/native seal command')
    require(receipt['stdout'] == STDOUT, 'complete actual publication seal output')
    require(all(type(pin['bytes']) is int and pin['bytes'] >= 0 for pin in receipt['whole_sealed_members'].values()),
            'actual publication receipt discrete byte-count kind')
    paths = list(BASE.iterdir())
    require(all(p.is_file() and not p.is_symlink() for p in paths), 'whole regular sealed publication membership')
    actual = {p.name: identity(p.read_bytes()) for p in paths}
    require(actual == receipt['whole_sealed_members'], 'whole actual publication receipt file identities')
    manifest = json.loads((BASE / 'manifest.json').read_bytes())
    require(set(actual) == set(manifest) | {'manifest.json'}, 'complete actual sealed publication domain')
    for name, pin in manifest.items():
        require(type(pin['bytes']) is int and pin['bytes'] >= 0 and actual[name] == pin,
                'complete publication seal member/kind identity')
    ns = {'__name__': 'independent_saved_full_parser_publication'}
    exec(compile((BASE / 'verify.py').read_bytes(), str(BASE / 'verify.py'), 'exec'), ns)
    ns['authenticate'](replay=False)
    require(ns['same'](ns['transform'](), ns['load'](BASE / 'publication.json'))
            and ns['same'](ns['source_proof'](), ns['load'](BASE / 'source-proof.json')),
            'whole regenerated original source publication and population proof')
    saved = ns['load'](BASE / 'current-input.json')
    ns['check_current'](saved)
    require(ns['same'](ns['controls'](saved), ns['load'](BASE / 'current-controls.json')),
            'whole independently regenerated saved snapshot and current controls')
    require(ns['same'](ns['native_proof']((BASE / 'book-input.html').read_text()),
                       ns['load'](BASE / 'book-proofs.json')),
            'whole independently regenerated saved native snapshot and controls')
    ns['verify_recoveries']()
    require(actual == {p.name: identity(p.read_bytes()) for p in BASE.iterdir()},
            'whole sealed publication identity conserved by snapshot verification')


def main():
    receipt = json.loads((CHECKS / 'sealed-replay.json').read_bytes())
    check(receipt)
    for status in (True, 0.0, 1):
        try:
            check({**receipt, 'status': status})
        except ValueError as error:
            require(str(error) == 'actual publication seal integer success', 'intended publication status-kind refusal')
        else:
            raise ValueError('false-green publication seal status')
    for count in (True, 0.0):
        changed = json.loads(json.dumps(receipt))
        next(iter(changed['whole_sealed_members'].values()))['bytes'] = count
        try:
            check(changed)
        except ValueError as error:
            require(str(error) == 'actual publication receipt discrete byte-count kind', 'intended publication byte-kind refusal')
        else:
            raise ValueError('false-green publication receipt byte kind')
    historical = json.loads(Path('docs/audits/parser-context-join-checks-20261006/sealed-replay.json').read_bytes())
    require(type(historical['status']) is int and historical['status'] == 0,
            'genuine prior actual context seal success')
    try:
        check(historical)
    except ValueError as error:
        require(str(error) == 'exact actual source/current/native seal command',
                'actual borrowed historical-only success refuses')
    else:
        raise ValueError('false-green borrowed historical context success')
    print('PASS actual full-publication seal, complete source/snapshot/control regeneration and typed/borrowed-result refusals.')


if __name__ == '__main__':
    main()

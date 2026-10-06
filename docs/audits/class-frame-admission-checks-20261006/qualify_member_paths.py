"""Separate a genuine nested same-basename insertion from the old seal."""
import json
from pathlib import Path

BASE = Path('docs/audits/record-value-class-frame-admission-20261006')
CHECKS = Path('docs/audits/class-frame-admission-checks-20261006')
WORK = Path('.artifacts/class-frame-admission-member-controls')


def module(path):
    ns = {'__name__': 'actual_member_path_control', '__file__': str(path)}
    exec(compile(path.read_bytes(), str(path), 'exec'), ns)
    return ns


def main():
    current = module(BASE / 'verify.py'); legacy = module(CHECKS / 'fresh-reader.py.txt')
    require, same, identity = (current[k] for k in ('require', 'same', 'identity'))
    paths = {WORK / 'baseline/member.txt': b'owned immutable record\n',
             WORK / 'mutated/member.txt': b'owned immutable record\n',
             WORK / 'mutated/nested/member.txt': b'owned immutable record\n'}
    for path, raw in paths.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        require(path.parent.resolve().is_relative_to(Path.cwd()) and path.parent.stat().st_dev == Path.cwd().stat().st_dev,
                'own actual member control same-volume contained workspace')
        if path.exists():
            require(not path.is_symlink() and path.read_bytes() == raw, 'whole retained own member-control input')
        else:
            path.write_bytes(raw)
    require({p for p in WORK.rglob('*') if p.is_file()} == set(paths), 'complete actual member-control input population')
    before, after = {}, {}
    for name, ns in (('legacy', legacy), ('current', current)):
        ns['BASE'] = WORK / 'baseline'; before[name] = ns['members']()
        ns['BASE'] = WORK / 'mutated'; after[name] = ns['members']()
    require(same(before['legacy'], after['legacy']), 'genuine old manifest false-green on inserted same-basename byte copy')
    require(same(before['legacy'], before['current']), 'whole original flat manifest preserved by path repair')
    # This independently stated physical-path domain is deliberately not
    # derived from either manifest projection.
    wanted = {'member.txt':identity(paths[WORK / 'mutated/member.txt']),
              'nested/member.txt':identity(paths[WORK / 'mutated/nested/member.txt'])}
    require(same(after['current'], wanted), 'full independent actual nested member-address population')
    try:
        require(same(before['current'], after['current']), 'whole immutable admission manifest')
    except ValueError as error:
        require(str(error) == 'whole immutable admission manifest', 'intended actual nested-member insertion refusal')
        refusal = dict(status=1, cause=str(error))
    else:
        raise ValueError('false-green repaired actual nested-member seal')
    record = dict(workspace=str(WORK), physical_inputs={str(p):identity(raw) for p, raw in paths.items()},
        sources={str(BASE / 'verify.py'):identity((BASE / 'verify.py').read_bytes()),
                 str(CHECKS / 'fresh-reader.py.txt'):identity((CHECKS / 'fresh-reader.py.txt').read_bytes())},
        before=before, after=after, legacy_status=0, repaired_refusal=refusal,
        legs=dict(rederive='independently stated full physical nested address domain and whole actual input bytes',
                  falsify='real same-basename exact-byte insertion passes legacy manifest but fails repaired seal',
                  durability='both whole invocation programmes, actual fixture/member pins, producer and actual process result'))
    destination = CHECKS / 'member-path-proof.json'
    if destination.exists():
        require(same(current['load'](destination), record), 'whole immutable actual member-path proof')
    else:
        destination.write_text(json.dumps(record, sort_keys=True, indent=2) + '\n')
    print('PASS actual nested same-basename insertion separates old false-green and repaired full-path seal; flat manifest bytes retain.')


if __name__ == '__main__':
    main()

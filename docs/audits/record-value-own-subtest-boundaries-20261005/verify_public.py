"""Qualify captured public documentation as current interface evidence only."""
import copy
import hashlib
import json
from pathlib import Path

BASE = Path('docs/audits/record-value-own-subtest-boundaries-20261005')


def require(condition, cause):
    if not condition:
        raise ValueError(cause)


def check(record):
    names = {'do', 'require', 'subtest', 'versions', 'documentation_path', 'scope'}
    require(set(record) == names, 'complete public interface capture membership')
    for name in names - {'scope'}:
        row = record[name]
        require(type(row['status']) is int and row['status'] == 0, 'public capture status kind/value')
        raw = row['stdout'].encode()
        require(type(row['bytes']) is int and len(raw) == row['bytes'] and
                hashlib.sha256(raw).hexdigest() == row['sha256'], 'whole public capture byte identity')
    require(record['versions']['stdout'] == 'v5.34.1 1.302183\n', 'captured current public metadata profile')
    require('subtest $name => \\&code, @args;' in record['subtest']['stdout'] and
            'Extra arguments given to "subtest" are passed to the callback.' in
            ' '.join(record['subtest']['stdout'].split()), 'public named callback/extra-argument interface')
    do = ' '.join(record['do']['stdout'].split())
    require('returns "undef" and sets an error message in $@' in do and
            'returns undef and sets $! to the error' in do and
            'returns the value of the last expression evaluated' in do,
            'public do-file return/error interface')
    require('file is included via the do-FILE mechanism' in
            ' '.join(record['require']['stdout'].split()), 'public require/do interface distinction')
    require('unmeasured original Test::More version' in record['scope'] and
            'No external implementation is inspected or copied.' in record['scope'],
            'current-public versus original-identity scope')


def main():
    record = json.loads((BASE / 'public-interface.json').read_text())
    check(record)
    controls = []
    for name, mutate, cause in [
        ('missing-public-member', lambda r: r.pop('do'), 'complete public interface capture membership'),
        ('changed-public-body', lambda r: r['subtest'].update(stdout='borrowed'), 'whole public capture byte identity'),
        ('Boolean-public-status', lambda r: r['do'].update(status=False), 'public capture status kind/value'),
        ('borrowed-current-version', lambda r: r['versions'].update(stdout='borrowed'), 'whole public capture byte identity'),
        ('invented-original-version', lambda r: r.update(scope='original version measured'), 'current-public versus original-identity scope'),
    ]:
        changed = copy.deepcopy(record)
        mutate(changed)
        try:
            check(changed)
        except ValueError as error:
            require(str(error) == cause, 'intended public-interface control cause')
            controls.append({'control': name, 'status': 1, 'cause': str(error)})
        else:
            raise ValueError('false-green public interface control: ' + name)
    proof = {'controls': controls, 'scope': record['scope']}
    target = BASE / 'public-proofs.json'
    if target.exists():
        require(json.loads(target.read_text()) == proof, 'whole saved public interface proof')
    else:
        require(not (BASE / 'manifest.json').exists(), 'sealed public reader cannot publish')
        target.write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    print('PASS whole public POD/current metadata interfaces and genuine controls; original framework version remains unmeasured.')


if __name__ == '__main__':
    main()

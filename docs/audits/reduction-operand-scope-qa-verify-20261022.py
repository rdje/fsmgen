"""Verify dated operand-task closure without executing source or native probes."""
import gzip
import hashlib
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / 'docs/audits'
LIMIT = 2 * 1024 * 1024


def read(name):
    path = BASE / name
    path.resolve().relative_to(ROOT)
    assert path.is_file() and not path.is_symlink() and path.stat().st_dev == ROOT.stat().st_dev
    with gzip.open(path, 'rb') as stream:
        data = stream.read(LIMIT + 1)
    assert len(data) <= LIMIT
    return json.loads(data)


def nodes(text):
    result = {}
    for block in re.split(r'(?m)(?=^- ID: `)', text):
        match = re.match(r'- ID: `([^`]+)`', block)
        if not match:
            continue
        assert match[1] not in result
        fields = re.findall(r'(?m)^  (Status|Goal|Acceptance|Verification|Commit|Children|Blocked by): `([^\n]*)`$', block)
        assert len(fields) == len(dict(fields))
        result[match[1]] = dict(fields)
    assert result
    return result


def compare(before, after, expected):
    left, right = nodes(before), nodes(after)
    assert set(left) == set(right)
    changes = {}
    for identity in left:
        assert set(left[identity]) == set(right[identity])
        for field in ('Goal', 'Acceptance', 'Children', 'Blocked by'):
            assert left[identity].get(field) == right[identity].get(field)
        changed = [field for field in left[identity] if left[identity][field] != right[identity][field]]
        if changed:
            assert set(changed) <= {'Status', 'Verification', 'Commit'}
            assert left[identity]['Status'] == 'active' and right[identity]['Status'] == 'done'
            changes[identity] = changed
    assert changes == expected


def main():
    original = read('reduction-operand-scope-qa-final-20261022.json.gz')
    closure = read('reduction-operand-scope-qa-closure-20261022.json.gz')
    delivery = read('reduction-operand-scope-qa-delivery-20261022.json.gz')
    before = next(row['text'] for row in original['files'] if row['path'] == 'docs/tasks/ISF-REDUCTION-DELIVERY.md')
    snapshot = delivery['task']
    after = snapshot['text']
    assert type(snapshot['bytes']) is int and snapshot['bytes'] == len(after.encode())
    assert snapshot['sha256'] == hashlib.sha256(after.encode()).hexdigest()
    assert delivery['producer_sha256'] == hashlib.sha256(Path(__file__).read_bytes()).hexdigest()
    for field in ('node_ids_equal', 'goals_acceptances_children_blockers_equal'):
        assert closure[field] is True
    expected = closure['changed_node_fields']
    compare(before, after, expected)
    identity = next(iter(expected))
    goal = nodes(after)[identity]['Goal']
    children_owner = next(key for key in expected if 'Children' in nodes(after)[key])
    children = nodes(after)[children_owner]['Children']
    wrong_cases = [
        after.replace('  Goal: `' + goal + '`', '  Goal: `narrowed retained goal`', 1),
        after.replace('  Children: `' + children + '`', '  Children: `omitted child`', 1),
        after.replace('- ID: `' + identity + '`', '- ID: `CHANGED-IDENTITY`', 1),
    ]
    for wrong in wrong_cases:
        assert wrong != after
        try:
            compare(before, wrong, expected)
        except AssertionError:
            continue
        raise AssertionError('invalid semantic task closure admitted')
    print('PASS dated complete node/Goal/Acceptance/Children preservation and genuine semantic controls; no probes execute.')


if __name__ == '__main__':
    main()

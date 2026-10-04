"""Closed native graph protocol reader; no production clone algorithm oracle."""
import hashlib
import json
import re
from collections import Counter
from pathlib import Path

JOINT = {'joint_input_result', 'input_reference_count', 'result_reference_count', 'shared_with_input'}


def identity(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def exact(a, b):
    if type(a) is not type(b):
        return False
    if isinstance(a, dict):
        return set(a) == set(b) and all(exact(a[k], b[k]) for k in a)
    if isinstance(a, list):
        return len(a) == len(b) and all(exact(x, y) for x, y in zip(a, b))
    return a == b


def base(row):
    return {key: value for key, value in row.items() if key not in JOINT}


def graph(value, seen=None, path=''):
    if type(value) not in (dict, list):
        assert value is None or type(value) in (str, int, float)
        return value
    seen = {} if seen is None else seen
    address = id(value)
    if address in seen:
        return ['reference', seen[address]]
    seen[address] = path
    if isinstance(value, dict):
        return ['hash', {key: graph(value[key], seen, path + '/' + key.replace('~', '~0').replace('/', '~1')) for key in sorted(value)}]
    return ['array', [graph(child, seen, path + '/' + str(i)) for i, child in enumerate(value)]]


def topology(encoded):
    """Build the complete declared-node edge table, then traverse referent sets.

    An alias to a ten-node root reaches all ten referents, not one marker.
    Reconstructed separate graphs also preserve exact primitive kinds.
    """
    nodes, objects, references = {}, {}, []

    def declare(node, path):
        if type(node) is not list:
            assert node is None or type(node) in (str, int, float)
            return
        assert len(node) == 2 and node[0] in ('hash', 'array', 'reference')
        kind, body = node
        if kind == 'reference':
            assert type(body) is str
            references.append(body)
            return
        assert path not in nodes
        assert type(body) is (dict if kind == 'hash' else list)
        children = list(body.items()) if kind == 'hash' else list(enumerate(body))
        objects[path] = {} if kind == 'hash' else []
        nodes[path] = [(key, child, path + '/' + str(key).replace('~', '~0').replace('/', '~1')) for key, child in children]
        for key, child, child_path in nodes[path]:
            declare(child, child_path)

    declare(encoded, '')
    assert all(target in nodes for target in references), 'every native reference resolves a declared full container'
    populated = set()

    def value(node, path):
        if type(node) is not list:
            return node
        if node[0] == 'reference':
            return value_at(node[1])
        return value_at(path)

    def value_at(path):
        result = objects[path]
        if path in populated:
            return result
        populated.add(path)
        for key, child, child_path in nodes[path]:
            child_value = value(child, child_path)
            if isinstance(result, dict):
                result[key] = child_value
            else:
                result.append(child_value)
        return result

    def reachable(node, path):
        pending, visited = [(node, path)], set()
        while pending:
            item, current = pending.pop()
            if type(item) is not list:
                continue
            target = item[1] if item[0] == 'reference' else current
            if target in visited:
                continue
            visited.add(target)
            pending.extend((child, child_path) for _, child, child_path in nodes[target])
        return visited

    result = value(encoded, '')
    assert exact(graph(result), encoded), 'complete native graph roundtrip including alias topology and kinds'
    return result, reachable


def check_joint(row, require_detached=True):
    joint = row['joint_input_result']
    assert joint[0] == 'hash' and set(joint[1]) == {'input', 'result'}
    decoded, reachable = topology(joint)
    inputs = reachable(joint[1]['input'], '/input')
    results = reachable(joint[1]['result'], '/result')
    actual_counts = (len(inputs), len(results), len(inputs & results))
    observed = tuple(row[name] for name in ('input_reference_count', 'result_reference_count', 'shared_with_input'))
    assert all(type(n) is int for n in observed) and actual_counts == observed, 'independent reachable referents match actual input/result/shared census'
    arguments, _ = topology(row['before'])
    assert len(arguments) == 2 and arguments[0] == 'FSM::Package::AggregatePathSupport'
    assert exact(graph(arguments[1]), graph(decoded['input'])), 'whole joint input ties original before arguments'
    assert exact(row['before'], row['after']), 'whole original clone caller kinds retain'
    assert exact(graph(decoded['result']), row['result']), 'joint topology ties whole separate result values/kinds'
    assert exact(graph(decoded['input']), graph(decoded['result'])), 'complete separate clone value/kind equality'
    if require_detached:
        assert not inputs & results, 'actual complete structured clone input/result referents must be detached'
    return {'container': type(arguments[1]) in (dict, list), 'input': sorted(inputs), 'result': sorted(results), 'shared': sorted(inputs & results)}


def conserved(old, new, extended):
    """Exact stable products; explicitly inventory raw process/source exceptions.

    Full exception strings are preserved in each profile. They are not rewritten
    or offered as a full-cause qualification; that has a separate owner.
    """
    assert set(old) == set(new) == {'api', 'copies', 'helpers', 'consumers', 'parses', 'host', 'warnings'}
    assert old['host'] == new['host'] and old['warnings'] == new['warnings'] == []
    assert exact(old['copies'], new['copies']) and len(new['copies']) == 697
    assert exact(old['helpers'], new['helpers']) and len(new['helpers']) == 43
    assert len(old['api']) == len(new['api']) == 9283
    expected = {'scope': 40, 'reference': 68, 'copy': 22, 'capture': 227, 'snapshot': 220, 'range': 437, 'structured-clone': 8251, 'identity': 14, 'payload': 4}
    assert Counter(row['kind'] for row in new['api']) == expected
    deltas = []
    for i, (left, right) in enumerate(zip(old['api'], new['api'])):
        assert set(right) == set(left) | (JOINT if left['kind'] == 'structured-clone' and extended else set())
        left, right = base(left), base(right)
        differing = [key for key in left if not exact(left[key], right[key])]
        if differing:
            assert differing == ['error'] and left['accepted'] == right['accepted'] == 0
            assert left['primary'] == right['primary'] == left['error'].split('\n')[0] == right['error'].split('\n')[0]
            deltas.append({'section': 'api', 'index': i, 'field': 'error', 'before': left['error'], 'after': right['error']})
    assert len(old['consumers']) == len(new['consumers']) == 125
    for i, (left, right) in enumerate(zip(old['consumers'], new['consumers'])):
        assert set(left) == set(right) and left['passed'] == right['passed'] == 1
        differing = [key for key in left if not exact(left[key], right[key])]
        if differing:
            assert i == 3 and differing == ['actual'] and left['label'] == 'known bad full trace contains the caller pattern'
            assert left['actual'].startswith('Deliberately wrong diagnostic\n') and right['actual'].startswith('Deliberately wrong diagnostic\n')
            deltas.append({'section': 'consumer', 'index': i, 'field': 'actual', 'before': left['actual'], 'after': right['actual']})
    assert len(old['parses']) == len(new['parses']) == 4
    for i, (left, right) in enumerate(zip(old['parses'], new['parses'])):
        assert set(left) == set(right)
        for key in left:
            if exact(left[key], right[key]):
                continue
            if i == 1 and key in ('before', 'after'):
                a, _ = topology(left[key]); b, _ = topology(right[key])
                assert a[0] == b[0] and len(a) == len(b) == 2
                assert all(re.fullmatch(r'\$\{REPO_ROOT\}/\.artifacts/tmp/tests/[A-Za-z0-9_]+/imported\.isf', path) for path in (a[1], b[1]))
            else:
                assert i in (2, 3) and key == 'error' and left['accepted'] == right['accepted'] == 0
                assert left['primary'] == right['primary'] == left['error'].split('\n')[0] == right['error'].split('\n')[0]
            deltas.append({'section': 'parse', 'index': i, 'field': key, 'before': left[key], 'after': right[key]})
    return deltas

"""Independent finite source models and complete native graph qualification.

The models describe object identity, edges and typed leaves. They do not call
the candidate's snapshot, copy, reference collector or assertion helpers.
"""
import copy
import hashlib
import json
import re
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-copy-reader-20261004')
CAPTURE = Path('docs/audits/record-value-copy-probes-20261004')
INPUTS = Path('docs/audits/record-value-copy-inputs-20261004')
MODES = ('ordinary', 'storable', 'alias', 'split-sharing', 'cycle-alias',
         'mutate-input', 'numeric-result')
CASES = ('null', 'number', 'string', 'empty-array', 'tree', 'shared',
         'hash-cycle', 'array-cycle')
SUFFIXES = ('copy preserves original kinds and sharing',
            'copy preserves kinds and sharing',
            'copy preserves reference population', 'copy is isolated from source')
FAILURES = {'ordinary': (), 'storable': (17,), 'alias': (23,),
            'split-sharing': (21, 22), 'cycle-alias': (25, 26, 27),
            'mutate-input': (16,), 'numeric-result': (17,)}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def identity(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def load(path):
    return json.loads(path.read_text())


def same(left, right):
    """JSON type equality: numeric 1 cannot stand in for string '1' or true."""
    if type(left) is not type(right):
        return False
    if isinstance(left, dict):
        return left.keys() == right.keys() and all(same(left[k], right[k]) for k in left)
    if isinstance(left, list):
        return len(left) == len(right) and all(same(a, b) for a, b in zip(left, right))
    return left == right


class Node:
    def __init__(self, kind, edges):
        self.kind = kind
        self.edges = edges


def specimen(name):
    """Authored expectations, separately reviewed against whole specimen source."""
    if name == 'null':
        return None
    if name == 'number':
        return 1
    if name == 'string':
        return '1'
    if name == 'empty-array':
        return Node('array', {})
    if name == 'tree':
        return Node('hash', {'number': 1, 'string': '1',
                            'children': Node('array', {'0': None,
                                '1': Node('hash', {'width': 7})})})
    if name == 'shared':
        child = Node('hash', {'number': 1, 'string': '1'})
        return Node('hash', {'left': child, 'right': child})
    if name == 'hash-cycle':
        root = Node('hash', {'number': 1})
        root.edges['self'] = root
        return root
    if name == 'array-cycle':
        root = Node('array', {'0': 1, '1': '1'})
        root.edges['2'] = root
        return root
    raise ValueError('unknown specimen')


def expected(name, mode):
    before, after, result = (specimen(name) for _ in range(3))
    if name == 'tree' and mode in ('storable', 'numeric-result'):
        result.edges['number'] = '1'
    if name == 'tree' and mode == 'mutate-input':
        after.edges['number'] = '1'
    if name == 'shared' and mode == 'alias':
        result = after
    if name == 'shared' and mode == 'split-sharing':
        result.edges['right'] = Node('hash', {'number': 1, 'string': '1'})
    if name == 'hash-cycle' and mode == 'cycle-alias':
        result.edges['self'] = after
    return before, after, result, Node('hash', {'input': after, 'result': result})


class Graph:
    """Resolve every serialized edge once, then compare with a model bijection."""
    def __init__(self, value):
        self.nodes = {}
        self.root = self.read(value, '')

    def read(self, value, path):
        if type(value) in (type(None), int, str):
            return ('scalar', type(value).__name__, value)
        require(type(value) is list and len(value) == 2, 'malformed graph entry')
        kind, payload = value
        if kind == 'reference':
            require(type(payload) is str and payload in self.nodes,
                    'unresolved or forward graph reference')
            return ('node', payload)
        require(kind in ('hash', 'array'), 'unknown graph kind')
        require(type(payload) is (dict if kind == 'hash' else list), 'graph shape mismatch')
        require(path not in self.nodes, 'duplicate graph definition')
        self.nodes[path] = (kind, {})
        items = sorted(payload.items()) if kind == 'hash' else enumerate(payload)
        for key, child in items:
            key = str(key)
            escaped = key.replace('~', '~0').replace('/', '~1')
            self.nodes[path][1][key] = self.read(child, path + '/' + escaped)
        return ('node', path)

    def matches(self, model):
        forward, reverse = {}, {}

        def visit(actual, wanted):
            if not isinstance(wanted, Node):
                require(actual == ('scalar', type(wanted).__name__, wanted),
                        'primitive value/kind disagrees with authored source model')
                return
            require(actual[0] == 'node', 'expected container missing')
            address, target = actual[1], id(wanted)
            if address in forward or target in reverse:
                require(forward.get(address) == target and reverse.get(target) == address,
                        'graph sharing/cycle/identity differs from source model')
                return
            forward[address], reverse[target] = target, address
            kind, edges = self.nodes[address]
            require(kind == wanted.kind and edges.keys() == wanted.edges.keys(),
                    'container kind/complete edge set differs from source model')
            for key in edges:
                visit(edges[key], wanted.edges[key])

        visit(self.root, model)
        require(set(forward) == set(self.nodes), 'unreachable graph definition')

    def reachable(self, root):
        found, pending = set(), [root]
        while pending:
            edge = pending.pop()
            if edge[0] == 'node' and edge[1] not in found:
                found.add(edge[1])
                pending.extend(self.nodes[edge[1]][1].values())
        return found


def check_record(record, mode):
    require(set(record) == {'mode', 'cases', 'assertions', 'native', 'host'}, 'record schema')
    require(record['mode'] == mode, 'wrong mode')
    require([c['name'] for c in record['cases']] == list(CASES), 'complete case membership')
    require(len(record['assertions']) == 32, 'complete assertion membership')
    for number, case in enumerate(record['cases']):
        name = case['name']
        require(set(case) == {'name', 'before', 'after', 'result', 'joint',
                             'assertion_start', 'assertion_end'}, 'case schema')
        require(case['assertion_start'] == 4 * number and case['assertion_end'] == 4 * number + 4,
                'assertion owner interval')
        models = expected(name, mode)
        graphs = []
        for field, model in zip(('before', 'after', 'result', 'joint'), models):
            graph = Graph(case[field])
            graph.matches(model)
            graphs.append(graph)
        joint = graphs[-1]
        edges = joint.nodes[''][1]
        inputs, outputs = joint.reachable(edges['input']), joint.reachable(edges['result'])
        # Standalone and joint observations must describe the same complete domains.
        require(len(inputs) == len(graphs[1].nodes) and len(outputs) == len(graphs[2].nodes),
                'joint/standalone population disagreement')
        for index, suffix in enumerate(SUFFIXES):
            assertion = record['assertions'][4 * number + index]
            require(set(assertion) == {'actual', 'expected', 'case', 'label', 'passed'},
                    'assertion schema')
            require(assertion['case'] == name and assertion['label'] == name + ' ' + suffix,
                    'assertion source/label ownership')
            if index < 2:
                actual = json.loads(assertion['actual'])
                wanted = json.loads(assertion['expected'])
                require(same(actual, case['after' if index == 0 else 'result'])
                        and same(wanted, case['before']), 'full snapshot assertion operands')
            else:
                actual = len(outputs) if index == 2 else len(inputs & outputs)
                wanted = len(graphs[0].nodes) if index == 2 else 0
                require(type(assertion['actual']) is int and type(assertion['expected']) is int
                        and assertion['actual'] == actual and assertion['expected'] == wanted,
                        'independent population/detachment assertion operands')
            passed = int(same(actual, wanted))
            require(type(assertion['passed']) is int and assertion['passed'] == passed,
                    'false assertion outcome')
            require((not passed) == (4 * number + index in FAILURES[mode]),
                    'genuine failure does not reach intended assertion')
    require(len(record['native']) == 4, 'complete native boundary membership')
    for index, native in enumerate(record['native']):
        require(set(native) == {'before', 'after', 'operation', 'accepted', 'error'}, 'native schema')
        wanted_class = ('CoverageCauseSentinel', 'CopyProbeNativeSentinel')[index // 2]
        operation = ('copy', 'snapshot')[index % 2]
        before = native['before']
        require(set(before) == {'class', 'identity', 'keys', 'reftype'}, 'native shape schema')
        require(before['class'] == wanted_class and before['reftype'] == 'HASH'
                and before['keys'] == [] and type(before['identity']) is int
                and before['identity'] > 0 and same(before, native['after']),
                'native class/shape/identity/readonly mismatch')
        if index % 2:
            require(same(before, record['native'][index - 1]['before']),
                    'native operations lost their actual same-object identity')
        cause, line = (('unexpected source reference', 10) if operation == 'copy'
                       else ('unexpected native snapshot reference', 32))
        require(native['operation'] == operation and type(native['accepted']) is int
                and native['accepted'] == 0 and native['error'] ==
                f'{cause} at ./{CAPTURE}/candidate.pl line {line}.\n', 'complete native cause')
    require(set(record['host']) == {'perl', 'json_pp', 'storable'}
            and all(type(v) is str and v for v in record['host'].values()), 'complete host context')


def check_receipt(receipt, record, directory):
    mode = record['mode']
    require(set(receipt) == {'command', 'working_directory', 'status', 'output', 'programs'},
            'receipt schema')
    require(receipt['command'] == ['perl', str(CAPTURE / 'probe.pl'), mode,
                                  str(CAPTURE / (mode + '.json'))], 'actual command identity')
    require(receipt['programs'] == {n: identity((CAPTURE / n).read_bytes())
                                   for n in ('probe.pl', 'candidate.pl')}, 'program identity')
    require(receipt['working_directory'] == directory, 'working root identity')
    require(type(receipt['status']) is int and receipt['status'] == len(FAILURES[mode]),
            'actual native exit status')
    tap = re.findall(r'^(not ok|ok) (\d+) - (.*)$', receipt['output'], re.M)
    require(len(tap) == 36 and [int(row[1]) for row in tap] == list(range(1, 37)),
            'complete numbered TAP domain')
    labels = [row['label'] for row in record['assertions']] + [
        f'{row["before"]["class"]} {row["operation"]} refuses unsupported native reference'
        for row in record['native']]
    require([row[2] for row in tap] == labels, 'whole TAP assertion ownership')
    require([i for i, row in enumerate(tap) if row[0] == 'not ok'] == list(FAILURES[mode])
            and receipt['output'].count('\n1..36\n') == 1, 'TAP failure/plan disagreement')


def authenticate(contract=None):
    contract = load(BASE / 'source-contract.json') if contract is None else contract
    for directory, manifest in ((CAPTURE, contract['capture_manifest']),
                                (INPUTS, contract['copy_input_manifest'])):
        require(load(directory / 'manifest.json') == manifest, 'changed canonical manifest')
        require({p.name for p in directory.iterdir()} == set(manifest) | {'manifest.json'},
                'sealed complete member domain')
        for name, row in manifest.items():
            require(identity((directory / name).read_bytes()) == row, 'sealed member identity: ' + name)
    require(contract['source_directory'] == str(CAPTURE), 'source directory authority')
    for name, body in contract['programs'].items():
        original = subprocess.check_output(['git', 'show',
            contract['revision'] + ':' + str(CAPTURE / name)])
        require(original == body.encode() == (CAPTURE / name).read_bytes(), 'whole original source authority')
    transform = load(CAPTURE / 'recipe-transform.json')
    recipes = load(INPUTS / 'recipes.json')
    require(transform['names'] == [r['name'] for r in recipes]
            and transform['before'] == ''.join(r['body'] for r in recipes), 'complete recipe authority')
    body = transform['before']
    for before, after in transform['replacements']:
        require(body.count(before) == 1, 'recipe transformation cardinality')
        body = body.replace(before, after)
    require(body == transform['after'] and transform['prefix'] + body + transform['suffix']
            == contract['programs']['candidate.pl'], 'exact strict plain adaptation')


def source_controls():
    controls = []
    original = load(BASE / 'source-contract.json')
    for name in ('candidate.pl', 'probe.pl'):
        contract = copy.deepcopy(original)
        contract['programs'][name] += '\n# unauthorized source change\n'
        try:
            authenticate(contract)
        except ValueError as error:
            controls.append({'control': 'changed-' + name, 'status': 1,
                             'error': str(error), 'contract': contract})
        else:
            raise ValueError('false-green source authority control')
    return controls


def check_population(directory, working_directory):
    receipts = load(directory / 'native-receipts.json')
    require([r['command'][2] for r in receipts] == list(MODES), 'whole mode membership')
    records = {}
    for receipt, mode in zip(receipts, MODES):
        record = load(directory / (mode + '.json'))
        check_record(record, mode)
        check_receipt(receipt, record, working_directory)
        records[mode] = record
    ordinary = records['ordinary']
    targets = {'storable': 'tree', 'alias': 'shared', 'split-sharing': 'shared',
               'cycle-alias': 'hash-cycle', 'mutate-input': 'tree', 'numeric-result': 'tree'}
    for mode, record in records.items():
        require(same(record['host'], ordinary['host']), 'mode host drift')
        for case, original in zip(record['cases'], ordinary['cases']):
            if case['name'] != targets.get(mode):
                require(same(case, original), 'non-target case conservation')
                start = case['assertion_start']
                require(same(record['assertions'][start:start + 4],
                             ordinary['assertions'][start:start + 4]), 'non-target assertion conservation')
    return records


def reader_controls(records):
    """Corrupt full retained objects; the semantic reader must reject each."""
    controls = []

    def rejects(name, mode, mutate):
        record = copy.deepcopy(records[mode])
        mutate(record)
        try:
            check_record(record, mode)
        except ValueError as error:
            controls.append({'control': name, 'status': 1, 'error': str(error), 'record': record})
            return
        raise ValueError('false-green reader control: ' + name)

    rejects('missing-case', 'ordinary', lambda r: r['cases'].pop())
    rejects('numeric-kind', 'ordinary', lambda r: r['cases'][4]['joint'][1]['input'][1].update(number='1'))
    rejects('borrowed-alias-joint', 'ordinary', lambda r: r['cases'].__setitem__(5,
            copy.deepcopy(records['alias']['cases'][5])))
    rejects('shared-child-target', 'ordinary', lambda r:
            r['cases'][5]['joint'][1]['result'][1].update(right=['reference', '/input/left']))
    rejects('cycle-target', 'ordinary', lambda r:
            r['cases'][6]['joint'][1]['result'][1].update(self=['reference', '/input']))
    rejects('unresolved-target', 'ordinary', lambda r:
            r['cases'][6]['joint'][1]['result'][1].update(self=['reference', '/absent']))
    rejects('missing-edge', 'ordinary', lambda r: r['cases'][4]['result'][1].pop('string'))
    rejects('false-green-control', 'storable', lambda r: r['assertions'][17].update(passed=1))
    rejects('native-identity', 'ordinary', lambda r: r['native'][0]['after'].update(identity=1))
    rejects('native-cause', 'ordinary', lambda r: r['native'][0].update(error=r['native'][0]['error'] + 'other cause'))
    return controls


def check_replay(replay, original):
    require(replay['same_volume'] is True and replay['fixture'].startswith(
            '.artifacts/record-value-copy-reader-20261004/replay-'), 'fresh fixture declaration')
    require(len(replay['receipts']) == len(replay['streams']) == len(MODES)
            and set(replay['records']) == set(MODES), 'complete replay membership')
    old_receipts = load(CAPTURE / 'native-receipts.json')
    for mode, receipt, streams, old_receipt in zip(
            MODES, replay['receipts'], replay['streams'], old_receipts):
        record = replay['records'][mode]
        check_record(record, mode)
        check_receipt(receipt, record, replay['fixture'])
        require(streams['mode'] == mode and streams['stdout'] + streams['stderr']
                == receipt['output'] == old_receipt['output'], 'complete raw replay TAP/diagnostics')
        prior = original[mode]
        for key in ('mode', 'cases', 'assertions', 'host'):
            require(same(record[key], prior[key]), 'complete old/fresh model/product conservation: ' + key)
        # Native addresses are retained, not erased or compared across lifetimes.
        # Each exact object has independently passed within-capture class, shape,
        # readonly and copy/snapshot identity checks above, including full errors.
        for current, old in zip(record['native'], prior['native']):
            for key in ('operation', 'accepted', 'error'):
                require(same(current[key], old[key]), 'old/fresh native cause contract')
            for phase in ('before', 'after'):
                for key in ('class', 'reftype', 'keys'):
                    require(same(current[phase][key], old[phase][key]), 'old/fresh native source shape')
    require(same(replay['controls'], reader_controls(replay['records'])), 'whole actual reader RED records')
    require(same(replay['source_controls'], source_controls()), 'whole source authority RED records')


def main():
    authenticate()
    proof = load(BASE / 'book-transform.json')
    book = subprocess.check_output(['git', 'show', proof['source_revision'] + ':' + proof['path']])
    require(identity(book) == proof['before'], 'book original authority')
    for replacement in proof['replacements']:
        before, after = (replacement[k].encode() for k in ('before', 'after'))
        require(book.count(before) == 1, 'book transformation cardinality')
        book = book.replace(before, after)
    require(identity(book) == proof['after'], 'complete bounded book afterimage')
    records = check_population(CAPTURE, '.')
    reader_controls(records)
    source_controls()
    replay = load(BASE / 'replay.json')
    require(replay['qualification'] == 'PASS', 'saved replay qualification incomplete')
    check_replay(replay, records)
    manifest = load(BASE / 'manifest.json')
    require({p.name for p in BASE.iterdir()} == set(manifest) | {'manifest.json'}, 'reader member domain')
    for name, row in manifest.items():
        require(identity((BASE / name).read_bytes()) == row, 'reader member identity: ' + name)
    print('PASS independent complete source/typed graph/native/TAP models and reader RED controls; finite profile only.')


if __name__ == '__main__':
    main()

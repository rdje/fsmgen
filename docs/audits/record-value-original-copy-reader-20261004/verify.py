"""Independent original input models and whole copy/joint graph qualification.

This inherits the separately qualified original source/field models and typed
edge interpreter. It never invokes a candidate copier, snapshot or collector.
Complete API/consumer semantics and alias downstream causes remain a sibling.
"""
import copy
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-original-copy-reader-20261004')
CAPTURE = Path('docs/audits/record-value-original-candidate-20261004')
INPUTS = Path('docs/audits/record-value-copy-inputs-20261004')
FINITE = Path('docs/audits/record-value-copy-reader-20261004')
PREFIX = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.'


def require(condition, message):
    if not condition:
        raise ValueError(message)


def load(path):
    return json.loads(path.read_text())


def identity(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def sealed(path):
    manifest = load(path / 'manifest.json')
    require({p.name for p in path.iterdir()} == set(manifest) | {'manifest.json'}, 'complete archive population')
    for name, expected in manifest.items():
        require(identity((path / name).read_bytes()) == expected, 'archive identity: ' + str(path / name))
    return manifest


def authenticate():
    binding = load(BASE / 'binding.json')
    require([r['id'] for r in binding['owners']] == [PREFIX + '1', PREFIX + '2.2', PREFIX + '3.2'], 'complete own prerequisite owners')
    task = subprocess.check_output(['git', 'show', binding['revision'] + ':' + binding['task_path']], text=True)
    require(task == binding['task_body'], 'complete original owner context')
    for owner in binding['owners']:
        start = task.index('- ID: `' + owner['id'] + '`'); end = task.index('\n- ID:', start + 1)
        require(task[start:end] == owner['body'] and '\n  Status: `done`\n' in owner['body'], 'complete done owner source')
    require(set(binding['archives']) == {str(CAPTURE), str(INPUTS), str(FINITE)}, 'complete source archives')
    for path, manifest in binding['archives'].items():
        require(load(Path(path) / 'manifest.json') == manifest == sealed(Path(path)), 'whole current prerequisite archive')
        for name in (*manifest, 'manifest.json'):
            raw = subprocess.check_output(['git', 'show', binding['revision'] + ':' + str(Path(path) / name)])
            require(raw == (Path(path) / name).read_bytes(), 'complete committed prerequisite body')
    finite = {'__name__': 'finite_typed_reader'}
    exec(compile((FINITE / 'verify.py').read_bytes(), str(FINITE / 'verify.py'), 'exec'), finite)
    finite['authenticate']()
    observer = {'__name__': 'original_capture_reader'}
    exec(compile((CAPTURE / 'check_capture.py').read_bytes(), str(CAPTURE / 'check_capture.py'), 'exec'), observer)
    observer['main']()
    if (BASE / 'manifest.json').exists():
        sealed(BASE)
    return finite


def original_model(value, Node):
    """Translate the authenticated original tree authority, never new output."""
    if type(value) in (type(None), int, str):
        return value
    require(type(value) is list and len(value) == 2, 'original tree grammar')
    kind, payload = value
    require(kind in ('hash', 'array'), 'original input is not a plain tree')
    require(type(payload) is (dict if kind == 'hash' else list), 'original tree shape')
    children = payload.items() if kind == 'hash' else enumerate(payload)
    return Node(kind, {str(k): original_model(v, Node) for k, v in children})


def source_calls(model, Node):
    return 1 + sum(source_calls(v, Node) for v in model.edges.values()) if isinstance(model, Node) else 1


def check_one(row, original, provider, assertions, label, finite):
    Graph, Node, same = (finite[k] for k in ('Graph', 'Node', 'same'))
    expected_input = original_model(original['native']['before'], Node)
    expected_after = original_model(original['native']['before'], Node)
    expected_result = expected_after if provider == 'alias' else original_model(
        original['native']['copy' if provider == 'storable' else 'before'], Node)
    require(row['caller'] == original['native']['caller'], 'complete original caller allocation')
    require(type(row['candidate_calls']) is int and row['candidate_calls'] == source_calls(expected_input, Node), 'complete actual recursive candidate execution')
    graphs = []
    for key, model in (('before', expected_input), ('after', expected_after),
                       ('result', expected_result), ('joint', Node('hash', {'input': expected_after, 'result': expected_result}))):
        graph = Graph(row[key]); graph.matches(model); graphs.append(graph)
    before, after, result, joint = graphs
    edges = joint.nodes[''][1]
    inputs, outputs = joint.reachable(edges['input']), joint.reachable(edges['result'])
    require(len(inputs) == len(after.nodes) == len(before.nodes)
            and len(outputs) == len(result.nodes), 'whole standalone/joint graph populations')
    require(len(assertions) == 4, 'complete actual assertion allocation')
    suffixes = finite['SUFFIXES']
    for number, (assertion, suffix) in enumerate(zip(assertions, suffixes)):
        require(assertion['copy'] == original['index'] and assertion['label'] == label + ' ' + suffix, 'complete copy assertion/source ownership')
        if number < 2:
            actual, expected = json.loads(assertion['actual']), json.loads(assertion['expected'])
            require(same(actual, row['after' if number == 0 else 'result'])
                    and same(expected, original['native']['before']), 'full source snapshot assertion operands')
        else:
            actual = len(outputs) if number == 2 else len(inputs & outputs)
            expected = len(before.nodes) if number == 2 else 0
            require(type(assertion['actual']) is int and type(assertion['expected']) is int
                    and assertion['actual'] == actual and assertion['expected'] == expected, 'independent population/isolation assertion operands')
        wanted = int(same(actual, expected))
        require(type(assertion['passed']) is int and assertion['passed'] == wanted, 'actual false-green assertion outcome')
    require(not (inputs & outputs) if provider != 'alias' else inputs == outputs,
            'actual source/result detachment relation')
    return {'original_index': original['index'], 'provider': provider,
            'input_referents': len(inputs), 'result_referents': len(outputs),
            'shared_referents': len(inputs & outputs), 'candidate_calls': row['candidate_calls'],
            'failures': [a['label'] for a in assertions if a['passed'] == 0]}


def check_records(records, finite):
    originals = load(INPUTS / 'inputs.json')['rows']
    require(set(records) == {'ordinary', 'storable', 'controls'}, 'complete unchanged-input mode domain')
    proofs = []
    for mode in ('ordinary', 'storable', 'controls'):
        record = records[mode]
        copies = [(i, r) for i, r in enumerate(record['copies']) if r['kind'] == 'test']
        require([i for i, r in copies] == [r['index'] for r in originals], 'complete original test-copy membership')
        for (index, captured), original in zip(copies, originals):
            start = captured['assertion_end'] - 4
            row = {'before': captured['before'], 'after': captured['after'], 'result': captured['copy'],
                   'joint': captured['joint_input_result'], 'caller': captured['caller'],
                   'candidate_calls': captured['candidate_calls']}
            proof = check_one(row, original, 'storable' if mode == 'storable' else 'ordinary',
                              record['copy_assertions'][start:captured['assertion_end']],
                              'original copy ' + str(index), finite)
            require(captured['original_reference_count'] == proof['input_referents']
                    and captured['copy_reference_count'] == proof['result_referents']
                    and captured['shared_with_original'] == proof['shared_referents'], 'actual native reference population')
            proofs.append({'mode': mode, 'kind': 'returned', **proof})
        if mode == 'controls':
            require(len(record['trials']) == 2 * len(originals), 'complete unchanged-input trial membership')
            for original, trials in zip(originals, [record['trials'][i:i + 2] for i in range(0, len(record['trials']), 2)]):
                for provider, trial in zip(('storable', 'alias'), trials):
                    require(trial['provider'] == provider and trial['copy'] == original['index'], 'actual trial/source allocation')
                    proof = check_one(trial, original, provider,
                                      record['copy_assertions'][trial['assertion_start']:trial['assertion_end']],
                                      'original copy ' + str(original['index']) + ' ' + provider + ' control', finite)
                    proofs.append({'mode': mode, 'kind': 'trial', **proof})
        else:
            require(record['trials'] == [], 'complete mode trial domain')
    return proofs


def controls(records, finite):
    rows = []

    def rejects(name, change):
        bad = copy.deepcopy(records)
        change(bad)
        try:
            check_records(bad, finite)
        except ValueError as error:
            rows.append({'control': name, 'status': 1, 'error': str(error)})
        else:
            raise ValueError('false-green graph control: ' + name)

    rejects('omit-copy', lambda r: r['ordinary']['copies'].pop(614))
    rejects('legacy-copy-as-candidate', lambda r: r['ordinary']['copies'][80].update(copy=r['storable']['copies'][80]['copy']))
    rejects('borrow-alias-joint', lambda r: r['ordinary']['copies'][8].update(joint_input_result=r['controls']['trials'][1]['joint']))
    rejects('unresolved-joint-target', lambda r: r['ordinary']['copies'][8]['joint_input_result'][1].update(result=['reference', '/absent']))
    rejects('kind-only-input', lambda r: r['ordinary']['copies'][80]['before'][1].update(watchdog=65535))
    rejects('missing-result-edge', lambda r: r['ordinary']['copies'][8]['copy'][1].pop('role'))
    rejects('false-green-storable', lambda r: r['storable']['copy_assertions'][5].update(passed=1))
    rejects('false-green-alias', lambda r: r['controls']['copy_assertions'][7].update(passed=1))
    rejects('incomplete-recursion', lambda r: r['controls']['trials'][0].update(candidate_calls=1))
    rejects('status-kind-promotion', lambda r: r['ordinary']['copy_assertions'][0].update(passed=True))
    rejects('omit-trial', lambda r: r['controls']['trials'].pop())
    return rows


def main():
    finite = authenticate()
    records = {m: load(CAPTURE / (m + '.json')) for m in ('ordinary', 'storable', 'controls')}
    proofs = check_records(records, finite)
    rejected = controls(records, finite)
    result = {'proofs': proofs, 'controls': rejected}
    destination = BASE / 'proofs.json'
    if destination.exists():
        require(finite['same'](load(destination), result), 'whole independent saved proof')
    else:
        destination.write_text(json.dumps(result, sort_keys=True, indent=2) + '\n')
    print('PASS independently qualified original17 unchanged-input copy/joint/kind/readonly/identity/isolation graphs and genuine Storable/alias trials; full API/consumer and alias downstream semantics remain open.')


if __name__ == '__main__':
    main()

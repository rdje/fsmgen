import argparse
import copy
import hashlib
import json
import re
import subprocess
from pathlib import Path

BASE = Path('docs/audits/reservation-coverage-snapshot-normal-fields-20261003')
CAPTURE = Path('docs/audits/reservation-coverage-snapshot-capture-20261003')
MODULE = Path('docs/audits/reservation-coverage-module-capture-20261003')
parser = argparse.ArgumentParser()
parser.add_argument('--trust-storable', action='store_true')
parser.add_argument('--trust-seed', action='store_true')
options = parser.parse_args()


def same(a, b):
    if type(a) is not type(b): return False
    if isinstance(a, dict): return a.keys() == b.keys() and all(same(a[k], b[k]) for k in a)
    if isinstance(a, list): return len(a) == len(b) and all(same(x, y) for x, y in zip(a, b))
    return a == b


def plain(value):
    if isinstance(value, list) and len(value) == 2:
        if value[0] == 'hash': return {k: plain(v) for k, v in value[1].items()}
        if value[0] == 'array': return [plain(v) for v in value[1]]
    return value


def expressions(text):
    roots, stack = [], []
    for token in re.findall(r'\(|\)|[^\s()]+', re.sub(r';[^\n]*', '', text)):
        if token == '(':
            node = []; (stack[-1] if stack else roots).append(node); stack.append(node)
        elif token == ')':
            assert stack; stack.pop()
        else:
            assert stack; stack[-1].append(token)
    assert not stack
    return roots


def named(rows, name):
    found = [r for r in rows if isinstance(r, list) and r and r[0] == name]
    assert len(found) == 1, name
    return found[0]


def differences(a, b):
    paths, pending = set(), [('', a, b)]
    while pending:
        path, x, y = pending.pop()
        if type(x) is not type(y):
            assert type(x) is int and type(y) is str and str(x) == y, path
            paths.add(path)
        elif isinstance(x, dict):
            assert x.keys() == y.keys(), path
            pending.extend((path + '/' + k, x[k], y[k]) for k in x)
        elif isinstance(x, list):
            assert len(x) == len(y), path
            pending.extend((path + '/' + str(i), xx, yy) for i, (xx, yy) in enumerate(zip(x, y)))
        else:
            assert x == y, path
    return paths


if (BASE / 'manifest.json').exists():
    manifest = json.loads((BASE / 'manifest.json').read_text())
    assert {p.name for p in BASE.iterdir()} == set(manifest) | {'manifest.json'}
    for name, r in manifest.items():
        raw = (BASE / name).read_bytes()
        assert len(raw) == r['bytes'] and hashlib.sha256(raw).hexdigest() == r['sha256'], name
subprocess.run(['python3', '-B', str(CAPTURE / 'verify.py')], check=True)
contracts = json.loads((BASE / 'source-contracts.json').read_text())
for path, r in contracts['sources'].items():
    raw = subprocess.check_output(['git', 'show', contracts['revision'] + ':' + path])
    assert len(raw) == r['bytes'] and hashlib.sha256(raw).hexdigest() == r['sha256'] and raw.decode() == r['body']
source = json.loads((CAPTURE / 'bindings.json').read_text())['sources']['t/1960-isf-formal-reservation-coverage.t']['body']
bodies = json.loads((MODULE / 'bindings.json').read_text())['sources']
lowerer = bodies['perl/FSM/Scheduler/ISF/LoweringIR.pm']
for literal in ("{ lhs => 'can_accept', rhs => 1, op => '=' }", "rhs=>1,op=>'<1',source_kind=>'complete_pulse'", 'rhs              => $assignment->{rhs}', "$ct{$port->{name}} = $port->{width} // 1;", "$storage_roles{$port->{name}} = 'transaction_port';"):
    assert literal in lowerer, literal
extra = json.loads(Path('docs/audits/reservation-coverage-generated-module-fields-20261003/source-contracts.json').read_text())['sources']
assert "%$assignment, lhs => 'done', source_kind => 'activation_completion_pulse'" in extra['perl/FSM/Scheduler/ISF/ChildCompletionOutputs.pm']['body']
assert '$port->{name} = $formal->{physical_name};' in contracts['sources']['perl/FSM/Scheduler/ISF/FormalClauseResolver.pm']['body']
assert "identity => ['transaction_port', $actor->{actor_name}, $owner, $name]" in contracts['sources']['perl/FSM/Scheduler/ISF/FormalIdentityPlan.pm']['body']
assert "declaration => _copy($declaration->{declaration})" in contracts['sources']['perl/FSM/Scheduler/ISF/FormalIdentityPlan.pm']['body']
source_actor = expressions(re.search(r"my \$source = <<'ISF';\n(.*?)\nISF", source, re.S)[1])[0]
source_main = next(r for r in source_actor if isinstance(r, list) and r[:2] == ['transaction', 'main'])
assert named(source_main, 'ports') == ['ports', ['input', 'payload', ['width', '4']], ['input', 'value_reg', ['width', '4']]]
assert named(source_actor, 'interface') == ['interface', ['input', 'start'], ['input', 'data', ['width', '4']], ['output', 'result', ['width', '4']], ['output', 'done'], ['output', 'notice']]
source_worker = next(r for r in source_actor if isinstance(r, list) and r[:2] == ['transaction', 'worker'])
assert source_worker == ['transaction', 'worker', ['wait', '1'], ['complete', 'notice']]
atl_names = ['atl_resolved_child_pipeline', 'atl_two_child_vector_data_pipeline', 'atl_two_child_trigger_batch_pipeline']
atl_sources = {name: expressions(bodies['isf/' + name + '.isf']) for name in atl_names}
ordinary = json.loads((CAPTURE / 'ordinary.json').read_text())
pure = json.loads((CAPTURE / 'pure.json').read_text())
module = json.loads((MODULE / 'ordinary.json').read_text())
plan = plain(ordinary['coverage'][0]['before'])[1]
private_names = {'payload': 'isf_port_main_payload_formal', 'value_reg': 'isf_port_main_value_reg'}
for authored, physical in private_names.items():
    r = plan['formals']['main'][authored]
    assert r['identity'] == ['transaction_port', 'coverage', 'main', authored]
    assert r['physical_name'] == physical and r['placement'] == 'direct_private'
    assert r['declaration'] == {'name': authored, 'width': 4}


def formal_widths(m, prefix):
    paths = set()
    for physical in private_names.values():
        assert m['actor_name'] == 'coverage' and m['storage_roles'][physical] == 'transaction_port'
        assert physical in m['explicit_internal_signals'] and all(p['name'] != physical for p in m['ports'])
        for field in ('counters', 'signal_widths'):
            assert same(m[field][physical], 4), ('private formal width kind/value', field, physical)
            paths.add(prefix + '/' + field + '/1/' + physical)
    return paths


def child_assignments(child, prefix, specs, carrier):
    paths = set()
    for state_name, target, op, kind in specs:
        si = next(i for i, s in enumerate(child['states']) if s['name'] == state_name)
        state = child['states'][si]
        transaction = state_name.rsplit('_', 2)[0]
        expected_guard = {'port': transaction + '_start'} if kind == 'scheduler_can_accept' else None
        expected_state_kind = 'entry' if kind == 'scheduler_can_accept' else 'terminal'
        assert same(state.get('guard'), expected_guard) and state['kind'] == expected_state_kind
        assert state['transaction'] == transaction
        matches = [(i, a) for i, a in enumerate(state['assignments']) if a['lhs'] == target]
        assert len(matches) == 1, ('child assignment membership', state_name, target)
        ai, assignment = matches[0]
        expected = {'lhs': target, 'op': op, 'rhs': 1}
        if kind != 'scheduler_can_accept': expected['source_kind'] = kind
        assert same(assignment, expected), ('child numeric assignment', state_name, target)
        records = [(i, r) for i, r in enumerate(child['assignment_provenance']) if r['activation']['container_kind'] == 'state' and r['activation']['container_name'] == state_name and r['target'] == target]
        assert len(records) == 1
        ri, record = records[0]
        assert same(record['rhs'], 1) and record['operator'] == op and record['source_kind'] == kind
        assert record['assignment_index'] == ai and record['activation']['assignment_guard'] is None
        assert same(record['activation']['state_guard'], expected_guard)
        assert record['activation']['state_kind'] == expected_state_kind
        assert record['owner_kind'] == 'transaction' and record['owner'] == state_name.rsplit('_', 2)[0]
        assert record['domain'] == ('helper' if kind == 'scheduler_can_accept' else 'pulse')
        lhs = target + ('>' if any(p['name'] == target and p['direction'] == 'output' for p in child['ports']) else '')
        assert [op, [lhs, '1']] in named(carrier, state_name), ('carrier pulse', state_name, target)
        paths.update((f'{prefix}/states/1/{si}/1/assignments/1/{ai}/1/rhs', f'{prefix}/assignment_provenance/1/{ri}/1/rhs'))
    return paths


def qualify(ordinal, row):
    site, graph = row['site'], row['before']
    if site == 'module_mutation_seed':
        return formal_widths(plain(graph)['coverage'], '/1/coverage/1')
    if site in ('unexpected_module_seed', 'allocation_mutation_seed'):
        return set()
    assert site in ('success_snapshot', 'refusal_snapshot')
    p, _, modules = plain(graph)
    name = p['actor']['actor_name']
    paths = set()
    if name == 'coverage':
        worker = p['generated_child_products']['worker']
        assert worker['actor_name'] == 'worker'
        source_index = 1 if ordinal == 5 else 2 if ordinal == 9 else 0
        carriers = plain(module['lowerings'][source_index]['result'])['files']
        child_carrier = expressions(carriers['worker.fsm'])[0]
        prefix = '/1/0/1/generated_child_products/1/worker/1'
        paths |= child_assignments(worker, prefix, [('worker_done_1', 'notice', '<1', 'complete_pulse'), ('worker_done_1', 'done', '<1', 'activation_completion_pulse')], child_carrier)
        for signal in ('data', 'result'):
            assert same(worker['signal_widths'][signal], 4)
            assert all(port['name'] != signal for port in worker['ports'])
            paths.add(prefix + '/signal_widths/1/' + signal)
        if ordinal == 34:
            paths |= formal_widths(modules['coverage'], '/1/2/1/coverage/1')
    elif name in atl_names:
        mi = atl_names.index(name) + 5
        files = plain(module['lowerings'][mi]['result'])['files']
        children = p['reusable_child_products']['children']
        specs = [('worker', 'process', 1)] if mi == 5 else [('reader', 'capture', 2 if mi == 6 else 1), ('writer', 'emit', 1)]
        for instance, tx, done_index in specs:
            child_name = name + '__' + instance
            child = children[child_name]
            assert child['actor_name'] == child_name
            source_child = next(a for a in atl_sources[name][1] if isinstance(a, list) and a[:2] == ['actor', 'packet_' + instance])
            authored = next(a for a in source_child if isinstance(a, list) and a[:2] == ['transaction', tx])
            assert named(authored, 'complete') == ['complete', 'done']
            prefix = '/1/0/1/reusable_child_products/1/children/1/' + child_name + '/1'
            paths |= child_assignments(child, prefix, [(tx + '_idle_0', 'can_accept', '=', 'scheduler_can_accept'), (tx + '_done_' + str(done_index), 'done', '<1', 'complete_pulse')], expressions(files[child_name + '.fsm'])[0])
            if mi == 6:
                direction = 'output' if instance == 'reader' else 'input'
                assert [direction, 'payload', ['width', '8']] in named(source_child, 'interface')
                pi = next(i for i, port in enumerate(child['ports']) if port['name'] == 'payload')
                assert same(child['ports'][pi], {'name': 'payload', 'direction': direction, 'width': 8})
                assert same(child['signal_widths']['payload'], 8)
                assert named(named(expressions(files[child_name + '.fsm'])[0], '+size'), 'payload') == ['payload', '8']
                paths.update((f'{prefix}/ports/1/{pi}/1/width', prefix + '/signal_widths/1/payload'))
        if mi == 6:
            top = p['reusable_child_products']['atl_top_instances']
            assert len(top) == 1 and top[0]['parent_module'] == name
            assert [c['instance'] for c in top[0]['children']] == ['reader', 'writer']
            for ci, instance in enumerate(('reader', 'writer')):
                side = 'source' if instance == 'reader' else 'sink'
                expected = {'child_' + side + '_port': 'payload', 'drive': 'forward_payload', 'kind': 'scalar_resolved_child_to_parent_handoff' if instance == 'reader' else 'scalar_parent_to_resolved_child_handoff', 'parent_' + side + '_port': instance + '_payload', 'width': 8}
                assert same(top[0]['children'][ci]['data_links'], [expected]), ('prepared vector endpoint', instance)
                paths.add(f'/1/0/1/reusable_child_products/1/atl_top_instances/1/0/1/children/1/{ci}/1/data_links/1/0/1/width')
    else:
        assert name in ('fifo_library_use', 'storage_fields', 'rule_coverage', 'monitor_coverage')
    return paths


selected = {'success_snapshot', 'refusal_snapshot', 'module_mutation_seed', 'unexpected_module_seed', 'allocation_mutation_seed'}
expected = []
for i, (a, b) in enumerate(zip(ordinary['copies'], pure['copies'])):
    if a['site'] not in selected or i == 35: continue
    actual = copy.deepcopy(a)
    if options.trust_storable or (options.trust_seed and a['site'] == 'module_mutation_seed'):
        actual['before'] = a['copy']
    paths = qualify(i, actual)
    assert paths == differences(a['before'], a['copy']), ('complete normal field meanings', i)
    pure_row = copy.deepcopy(b); pure_row['before'] = b['copy']
    assert qualify(i, pure_row) == paths
    if paths and not options.trust_storable and not options.trust_seed:
        bad_copy = copy.deepcopy(a); bad_copy['before'] = a['copy']
        try: qualify(i, bad_copy)
        except AssertionError: pass
        else: raise AssertionError(('actual lossy copy accepted', i))
    expected.append({'ordinal': i, 'site': a['site'], 'paths': sorted(paths)})
assert same(expected, json.loads((BASE / 'qualified-fields.json').read_text()))
assert len(expected) == 35 and sum(len(r['paths']) for r in expected) == 164
assert sum(bool(r['paths']) for r in expected) == 29
for ordinal, description, mutation in (
    (2, 'pulse target', lambda g: g[1][0][1]['generated_child_products'][1]['worker'][1]['states'][1][2][1]['assignments'][1][0][1].update(lhs='wrong')),
    (2, 'pulse guard', lambda g: g[1][0][1]['generated_child_products'][1]['worker'][1]['states'][1][2][1].update(guard=['hash', {'port': 'wrong'}])),
    (10, 'private width', lambda g: g[1]['coverage'][1]['counters'][1].update(isf_port_main_payload_formal=8)),
    (51, 'vector endpoint', lambda g: g[1][0][1]['reusable_child_products'][1]['atl_top_instances'][1][0][1]['children'][1][0][1]['data_links'][1][0][1].update(child_source_port='done'))):
    bad = copy.deepcopy(ordinary['copies'][ordinal]); mutation(bad['before'])
    try: qualify(ordinal, bad)
    except (AssertionError, StopIteration): pass
    else: raise AssertionError(('corruption accepted', description))
print('PASS complete normal snapshot/seed RHS/provenance, source-owned child/vector widths and private formal identity/width contracts, with separate derived roster.')
print('PASS source/producer/carrier literals and pure kinds; real Storable snapshot/seed authorities and pulse/width/endpoint corruptions reject.')
print('OPEN: producer-removal fields, full field join and actual value-only/native-marker controls precede P2 repair; wider controllers/constructors/moved-root stay cold.')

if not options.trust_storable and not options.trust_seed:
    for name, last in (
        ('trust-storable', "AssertionError: ('child numeric assignment', 'worker_done_1', 'notice')"),
        ('trust-seed', "AssertionError: ('private formal width kind/value', 'counters', 'isf_port_main_payload_formal')"),
    ):
        assert (BASE / (name + '.status')).read_text().strip() == '1'
        assert (BASE / (name + '.txt')).read_text().splitlines()[-1] == last

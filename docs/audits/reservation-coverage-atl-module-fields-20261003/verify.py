import argparse
import copy
import hashlib
import json
import re
import subprocess
from pathlib import Path

BASE = Path('docs/audits/reservation-coverage-atl-module-fields-20261003')
MODULE = Path('docs/audits/reservation-coverage-module-capture-20261003')
SOURCE = Path('docs/audits/reservation-coverage-source-copies-20261003')
parser = argparse.ArgumentParser()
parser.add_argument('--trust-storable', action='store_true')
parser.add_argument('--trust-inherited', action='store_true')
options = parser.parse_args()


def same(a, b):
    if type(a) is not type(b):
        return False
    if isinstance(a, dict):
        return a.keys() == b.keys() and all(same(a[k], b[k]) for k in a)
    if isinstance(a, list):
        return len(a) == len(b) and all(same(x, y) for x, y in zip(a, b))
    return a == b


def plain(value):
    if isinstance(value, list) and len(value) == 2:
        if value[0] == 'hash':
            return {k: plain(v) for k, v in value[1].items()}
        if value[0] == 'array':
            return [plain(v) for v in value[1]]
    return value


def expressions(text):
    roots, stack = [], []
    for token in re.findall(r'\(|\)|[^\s()]+', re.sub(r';[^\n]*', '', text)):
        if token == '(':
            node = []
            (stack[-1] if stack else roots).append(node)
            stack.append(node)
        elif token == ')':
            assert stack
            stack.pop()
        else:
            assert stack
            stack[-1].append(token)
    assert not stack
    return roots


def named(rows, name):
    found = [row for row in rows if isinstance(row, list) and row and row[0] == name]
    assert len(found) == 1, name
    return found[0]


def differences(a, b):
    stack, paths = [('', a, b)], set()
    while stack:
        path, x, y = stack.pop()
        if type(x) is not type(y):
            assert type(x) is int and type(y) is str and str(x) == y, path
            paths.add(path)
        elif isinstance(x, dict):
            assert x.keys() == y.keys(), path
            stack.extend((path + '/' + k, x[k], y[k]) for k in x)
        elif isinstance(x, list):
            assert len(x) == len(y), path
            stack.extend((path + '/' + str(i), p, q) for i, (p, q) in enumerate(zip(x, y)))
        else:
            assert x == y, path
    return paths


for reader in (SOURCE / 'verify.py', MODULE / 'verify.py'):
    subprocess.run(['python3', '-B', str(reader)], check=True)
if (BASE / 'manifest.json').exists():
    manifest = json.loads((BASE / 'manifest.json').read_text())
    assert {p.name for p in BASE.iterdir()} == set(manifest) | {'manifest.json'}
    for name, record in manifest.items():
        raw = (BASE / name).read_bytes()
        assert len(raw) == record['bytes'] and hashlib.sha256(raw).hexdigest() == record['sha256'], name
binding = json.loads((MODULE / 'bindings.json').read_text())
bodies = binding['sources']
ordinary = json.loads((MODULE / 'ordinary.json').read_text())
pure = json.loads((MODULE / 'pure.json').read_text())
source_ordinary = json.loads((SOURCE / 'ordinary.json').read_text())
source_pure = json.loads((SOURCE / 'pure.json').read_text())
roster = json.loads((MODULE / 'field-roster.json').read_text())
names = ['atl_resolved_child_pipeline', 'atl_two_child_vector_data_pipeline', 'atl_two_child_trigger_batch_pipeline']
sources = {i: expressions(bodies['isf/' + name + '.isf']) for i, name in zip((5, 6, 7), names)}
for i, roots in sources.items():
    assert roots[0][:2] == ['actor', names[i - 5]] and roots[1][:2] == ['library', 'common.packet']
assert named(sources[5][0], 'transaction')[2:] == [
    ['on', 'start'], ['trigger', 'worker.process'], ['await', 'worker.done'], ['complete', 'done']]
assert named(sources[6][0], 'transaction')[2:] == [
    ['on', 'start'], ['trigger', 'reader.capture'], ['await', 'reader.done'],
    ['drive', 'forward_payload'], ['trigger', 'writer.emit'], ['await', 'writer.done'], ['complete', 'done']]
assert named(sources[7][0], 'transaction')[2:] == [
    ['on', 'start'], ['trigger', 'reader.capture'], ['trigger', 'writer.emit'],
    ['await', 'reader.done'], ['await', 'writer.done'], ['complete', 'done']]
assert named(sources[6][0], 'drive') == ['drive', 'forward_payload', ['writer.payload', 'reader.payload']]
lowerer = bodies['perl/FSM/Scheduler/ISF/LoweringIR.pm']
for literal in ("source_kind => 'atl_actor_transaction_trigger'",
                "source_kind => 'atl_actor_transaction_trigger_batch'",
                "rhs=>1,op=>'<1',source_kind=>'timeout_pulse'",
                "rhs=>1,op=>'<-',source_kind=>'timeout_status'",
                "push @groups, _domain_fanin_groups($records, 'pulse');"):
    assert literal in lowerer, literal


def specs(i):
    done = {5: 'run_done_3', 6: 'run_done_6', 7: 'run_done_4'}[i]
    rows = [(None, 'run_idle_0', 'can_accept', '=', None),
            (None, done, 'done', '<1', 'complete_pulse'),
            (None, 'run_timeout', 'done', '<1', 'timeout_pulse'),
            (None, 'run_timeout', 'last_error', '<-', 'timeout_status')]
    if i == 5:
        rows += [(None, 'run_atl_trigger_1', 'worker_process_start', '<1', 'atl_actor_transaction_trigger'),
                 ('worker', 'process_idle_0', 'can_accept', '=', None),
                 ('worker', 'process_done_1', 'done', '<1', 'complete_pulse')]
    else:
        trigger = 'atl_actor_transaction_trigger_batch' if i == 7 else 'atl_actor_transaction_trigger'
        rows += [(None, 'run_atl_trigger_batch_1' if i == 7 else 'run_atl_trigger_1', 'reader_capture_start', '<1', trigger),
                 (None, 'run_atl_trigger_batch_1' if i == 7 else 'run_atl_trigger_4', 'writer_emit_start', '<1', trigger),
                 ('reader', 'capture_idle_0', 'can_accept', '=', None),
                 ('reader', 'capture_done_1' if i == 7 else 'capture_done_2', 'done', '<1', 'complete_pulse'),
                 ('writer', 'emit_idle_0', 'can_accept', '=', None),
                 ('writer', 'emit_done_1', 'done', '<1', 'complete_pulse')]
        if i == 6:
            rows.append((None, 'run_drive_3', 'forward_payload_start', '=', 'drive_call_start'))
    return rows


def vector_route():
    return {'context': 'transaction_body', 'drive': 'forward_payload', 'kind': 'vector_actor_handoff',
            'route_lifetime': 'drive_call_cycle', 'sink': 'external_handoff', 'sink_endpoint': 'payload',
            'sink_instance': 'writer', 'sink_signal': 'writer_payload', 'source': 'external_handoff',
            'source_endpoint': 'payload', 'source_instance': 'reader', 'source_signal': 'reader_payload',
            'storage': 'none', 'transaction': 'run', 'width': 8, 'width_source': 'resolved_child_endpoint_exact_width'}


def module_fields(i, graph, files):
    m = plain(graph)
    name = names[i - 5]
    assert m['actor_name'] == name
    instances = ['worker'] if i == 5 else ['reader', 'writer']
    assert set(m['children']) == {name + '__' + instance for instance in instances}
    paths = set()
    carriers = {file: expressions(body)[0] for file, body in files.items()}
    for instance, state_name, lhs, op, category in specs(i):
        scope = m if instance is None else m['children'][name + '__' + instance]
        prefix = '/1' if instance is None else '/1/children/1/' + name + '__' + instance + '/1'
        si = next(j for j, s in enumerate(scope['states']) if s['name'] == state_name)
        state = scope['states'][si]
        matches = [(j, a) for j, a in enumerate(state['assignments']) if a['lhs'] == lhs]
        assert len(matches) == 1
        ai, actual = matches[0]
        expected = {'lhs': lhs, 'op': op, 'rhs': 1}
        if category is not None:
            expected['source_kind'] = category
        assert same(actual, expected), ('ATL numeric assignment', i, instance, state_name, lhs)
        paths.add(f'{prefix}/states/1/{si}/1/assignments/1/{ai}/1/rhs')
        pi = next(j for j, p in enumerate(scope['assignment_provenance'])
                  if p['activation']['container_name'] == state_name and p['assignment_index'] == ai)
        provenance = scope['assignment_provenance'][pi]
        assert same(provenance['rhs'], 1) and provenance['target'] == lhs and provenance['operator'] == op
        assert provenance['source_kind'] == (category or 'scheduler_can_accept')
        assert provenance['activation']['container_kind'] == 'state' and provenance['activation']['assignment_guard'] is None
        paths.add(f'{prefix}/assignment_provenance/1/{pi}/1/rhs')
        file = name + ('' if instance is None else '__' + instance) + '.fsm'
        assert carriers[file][0] == '?fsm:' + scope['actor_name']
        emitted_lhs = lhs + ('>' if any(p['name'] == lhs and p['direction'] == 'output' for p in scope['ports']) else '')
        assert [op, [emitted_lhs, '1']] in named(carriers[file], state_name)
    # Both compatibility summaries copy the same two concrete one-cycle done
    # producers. The canonical group RHS is textual; each source RHS is numeric.
    done = {5: 'run_done_3', 6: 'run_done_6', 7: 'run_done_4'}[i]
    groups = m['compatible_fanin_groups']
    assert len(groups) == 2
    for gi, kind in enumerate(('same_target_value', 'pulse')):
        group = groups[gi]
        assert group['kind'] == kind and group['domain'] == 'pulse'
        assert group['target'] == 'done' and group['operator'] == '<1' and same(group['rhs'], '1')
        assert len(group['sources']) == 2
        for ri, (state_name, category) in enumerate(((done, 'complete_pulse'), ('run_timeout', 'timeout_pulse'))):
            record = group['sources'][ri]
            assert same(record['rhs'], 1), ('numeric fan-in source', i, gi, ri)
            assert record['target'] == 'done' and record['operator'] == '<1' and record['domain'] == 'pulse'
            assert record['owner'] == 'run' and record['owner_kind'] == 'transaction' and record['source_kind'] == category
            assert record['assignment_index'] == 0 and record['activation']['container_name'] == state_name
            assert record['activation']['container_kind'] == 'state' and record['activation']['state_kind'] == 'terminal'
            assert record['activation']['assignment_guard'] is None and record['activation']['state_guard'] is None
            paths.add(f'/1/compatible_fanin_groups/1/{gi}/1/sources/1/{ri}/1/rhs')
    if i == 6:
        top = m['atl_top_instances']
        assert len(top) == 1 and top[0]['parent_module'] == name
        assert [c['instance'] for c in top[0]['children']] == ['reader', 'writer']
        for ci, (instance, direction) in enumerate((('reader', 'output'), ('writer', 'input'))):
            source_actor = next(a for a in sources[6][1] if isinstance(a, list) and a[:2] == ['actor', 'packet_' + instance])
            assert [direction, 'payload', ['width', '8']] in named(source_actor, 'interface')
            child_name = name + '__' + instance
            child = m['children'][child_name]
            pi = next(j for j, p in enumerate(child['ports']) if p['name'] == 'payload')
            assert same(child['ports'][pi], {'direction': direction, 'name': 'payload', 'width': 8})
            assert same(child['signal_widths']['payload'], 8)
            prefix = '/1/children/1/' + child_name + '/1'
            paths.update((f'{prefix}/ports/1/{pi}/1/width', prefix + '/signal_widths/1/payload'))
            assert named(named(carriers[child_name + '.fsm'], '+size'), 'payload') == ['payload', '8']
            side = 'source' if instance == 'reader' else 'sink'
            expected = {'child_' + side + '_port': 'payload', 'drive': 'forward_payload',
                        'kind': 'scalar_resolved_child_to_parent_handoff' if instance == 'reader' else 'scalar_parent_to_resolved_child_handoff',
                        'parent_' + side + '_port': instance + '_payload', 'width': 8}
            assert same(top[0]['children'][ci]['data_links'], [expected]), ('vector link', instance)
            paths.add(f'/1/atl_top_instances/1/0/1/children/1/{ci}/1/data_links/1/0/1/width')
        top_carrier = carriers[name + '_top.fsm']
        assert top_carrier[0] == '?top:' + name + '_top'
        wiring = named(top_carrier, '?wiring:isf_wiring')
        assert ['reader.payload', name + '.reader_payload'] in wiring
        assert [name + '.writer_payload', 'writer.payload'] in wiring
        assert named(named(carriers[name + '.fsm'], '+size'), 'reader_payload') == ['reader_payload', '8']
        assert named(named(carriers[name + '.fsm'], '+size'), 'writer_payload') == ['writer_payload', '8']
        assert ['<-', ['writer_payload>', 'reader_payload'], '<forward_payload_start'] in named(carriers[name + '.fsm'], '-forward_payload')
    assert paths == {row[0] for row in roster[i]['differences']}, ('whole ATL field cohort', i)
    return paths


def preparation_fields(graph):
    p = plain(graph)
    assert p['actor']['actor_name'] == names[1]
    assert same(p['actor']['actor_network']['data_movements'], [vector_route()]), 'numeric source route'
    paths = {'/1/actor/1/actor_network/1/data_movements/1/0/1/width'}
    for family in ('parent_activation_products', 'parent_wiring_products'):
        ports = p[family]['ports']
        for name, direction in (('reader_payload', 'input'), ('writer_payload', 'output')):
            pi = next(i for i, port in enumerate(ports) if port['name'] == name)
            assert same(ports[pi], {'direction': direction, 'name': name, 'width': 8}), ('numeric prepared vector port', family, name)
            paths.add(f'/1/{family}/1/ports/1/{pi}/1/width')
    return paths


qualified = {'modules': []}
for i in (5, 6, 7):
    files = plain(pure['lowerings'][i]['result'])['files']
    graph = ordinary['copies'][i]['copy'] if options.trust_storable else ordinary['copies'][i]['before']
    fields = module_fields(i, graph, files)
    module_fields(i, pure['copies'][i]['copy'], files)
    qualified['modules'].append({'ordinal': i, 'paths': sorted(fields)})
    try:
        module_fields(i, ordinary['copies'][i]['copy'], files)
    except AssertionError:
        pass
    else:
        raise AssertionError(('actual lossy ATL capture accepted', i))
graph = source_ordinary['preparations'][7]['result'] if options.trust_inherited else source_pure['preparations'][7]['result']
fields = preparation_fields(graph)
assert fields == differences(source_pure['preparations'][7]['result'], source_ordinary['preparations'][7]['result'])
qualified['preparation'] = {'ordinal': 7, 'paths': sorted(fields)}
for i in (6, 8):
    assert same(source_pure['preparations'][i]['result'], source_ordinary['preparations'][i]['result'])
assert json.loads((BASE / 'qualified-fields.json').read_text()) == qualified
try:
    preparation_fields(source_ordinary['preparations'][7]['result'])
except AssertionError:
    pass
else:
    raise AssertionError('actual inherited vector kind loss accepted')
good = pure['copies'][6]['copy']
files = plain(pure['lowerings'][6]['result'])['files']
for label, mutate in (
        ('fan-in identity', lambda g: g[1]['compatible_fanin_groups'][1][0][1]['sources'][1][0][1].update(target='wrong')),
        ('vector endpoint', lambda g: g[1]['atl_top_instances'][1][0][1]['children'][1][0][1]['data_links'][1][0][1].update(child_source_port='wrong')),
        ('vector width', lambda g: g[1]['children'][1][names[1]+'__reader'][1]['signal_widths'][1].update(payload=4))):
    bad = copy.deepcopy(good)
    mutate(bad)
    try:
        module_fields(6, bad, files)
    except AssertionError:
        pass
    else:
        raise AssertionError(('semantic corruption accepted', label))
bad_files = dict(files)
top_file = names[1] + '_top.fsm'
bad_files[top_file] = files[top_file].replace('(reader.payload ' + names[1] + '.reader_payload)', '(reader.done ' + names[1] + '.reader_payload)', 1)
assert bad_files != files
try:
    module_fields(6, good, bad_files)
except AssertionError:
    pass
else:
    raise AssertionError('carrier endpoint corruption accepted')
for mode, last_line in (
        ('trust-storable', "AssertionError: ('ATL numeric assignment', 5, None, 'run_idle_0', 'can_accept')"),
        ('trust-inherited', 'AssertionError: numeric source route')):
    assert (BASE / (mode + '.status')).read_text().strip() == '1'
    assert (BASE / (mode + '.txt')).read_text().splitlines()[-1] == last_line
print('PASS complete resolved/vector/trigger-batch module field sets, numeric assignments/provenance/fan-in and source-owned child/link width contracts.')
print('PASS structured carrier constants/sizes/endpoint wiring and complete inherited vector activation/wiring width field set; real Storable authorities and semantic/endpoint/carrier corruptions reject.')
print('OPEN: full module reconciliation and snapshots retain their owners; complete controllers/constructors/native/moved-root stay cold.')

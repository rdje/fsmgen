import argparse
import copy
import hashlib
import json
import re
import subprocess
from pathlib import Path

BASE = Path('docs/audits/reservation-coverage-producer-removal-fields-20261003')
CAPTURE = Path('docs/audits/reservation-coverage-snapshot-capture-20261003')
MODULE = Path('docs/audits/reservation-coverage-module-capture-20261003')
parser = argparse.ArgumentParser()
parser.add_argument('--trust-storable', action='store_true')
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
subprocess.run(['python3', '-B', 'docs/audits/reservation-coverage-snapshot-normal-fields-20261003/verify.py'], check=True)
contracts = json.loads((BASE / 'source-contracts.json').read_text())
for path, r in contracts['sources'].items():
    raw = subprocess.check_output(['git', 'show', contracts['revision'] + ':' + path])
    assert raw.decode() == r['body'] and len(raw) == r['bytes'] and hashlib.sha256(raw).hexdigest() == r['sha256']
bodies = json.loads((MODULE / 'bindings.json').read_text())['sources']
lowerer = bodies['perl/FSM/Scheduler/ISF/LoweringIR.pm']
source = json.loads((CAPTURE / 'bindings.json').read_text())['sources']['t/1960-isf-formal-reservation-coverage.t']['body']
for literal in ('my $counter = "${state_name}_cnt";', 'wait_entry           => 1,', 'dynamic_wait_entry   => 1,', 'wait_counter_width   => $wait_spec->{width},', 'assignment_index => $assignment_index,', 'rhs              => $assignment->{rhs}', 'my %names = map { $_ => 1 } grep { defined $_ } (', 'isf_handoff => 1'):
    assert literal in lowerer, literal
completion = contracts['sources']['perl/FSM/Scheduler/ISF/ChildCompletion.pm']['body']
for literal in ('my $products = {input_names => {%reserved}, instances => {}};', '$ir->{counters}{$_} = $ir->{signal_widths}{$_} = 1 for ($seen, $ready);', '$ir->{reset_values}{$seen} = 0;', "rhs => '0'", "rhs => '1'"):
    assert literal in completion, literal
metadata = contracts['sources']['perl/FSM/Support/ISFInterfacePortMetadata.pm']['body']
assert 'width => 0 + $port->{width}' in metadata
assert '$widths{$port->{name}} = $port->{width} // 1;' in lowerer
assert 'my $enter_condition = _combine_condition_exprs($base_condition, "(!= $source 0)");' in lowerer
for literal in ('return {map {my $key = $_; $key =~ s/\\b\\Q$name\\E\\b/missing_reservation_placeholder/g;', 'return [map {substitute_token($_, $name)} @$value]', '$copy =~ s/\\b\\Q$name\\E\\b/missing_reservation_placeholder/g if defined($copy);'):
    assert literal in source, literal
ordinary = json.loads((CAPTURE / 'ordinary.json').read_text())
pure = json.loads((CAPTURE / 'pure.json').read_text())
source_actor = expressions(re.search(r"my \$source = <<'ISF';\n(.*?)\nISF", source, re.S)[1])[0]
assert named(source_actor, 'storage') == ['storage', ['var', 'value_reg', ['width', '8']]]
main = next(r for r in source_actor if isinstance(r, list) and r[:2] == ['transaction', 'main'])
assert main[2:] == [['ports', ['input', 'payload', ['width', '4']], ['input', 'value_reg', ['width', '4']]], ['on', 'start'], ['set', 'payload', 'data'], ['set', 'value_reg', 'payload'], ['drive', 'isf_port_main', 'payload'], ['wait', 'value_reg'], ['spawn', 'worker', 'as', 'job'], ['await_all', 'done'], ['complete', 'done']]
assert next(r for r in source_actor if isinstance(r, list) and r[:2] == ['transaction', 'worker']) == ['transaction', 'worker', ['wait', '1'], ['complete', 'notice']]


def expand_graph(value, seen=None, path=''):
    seen = {} if seen is None else seen
    if not isinstance(value, list):
        return value
    assert len(value) == 2 and value[0] in ('hash', 'array', 'reference')
    if value[0] == 'reference':
        assert value[1] in seen, ('unbound reference', value[1])
        return seen[value[1]]
    result = {} if value[0] == 'hash' else []
    seen[path] = result
    if value[0] == 'hash':
        for k, child in value[1].items():
            escaped = k.replace('~', '~0').replace('/', '~1')
            result[k] = expand_graph(child, seen, path + '/' + escaped)
    else:
        result.extend(expand_graph(child, seen, path + '/' + str(i)) for i, child in enumerate(value[1]))
    return result


def retoken(value):
    if isinstance(value, dict):
        return {re.sub(r'\bmain_wait_4_cnt\b', 'missing_reservation_placeholder', k): retoken(v) for k, v in value.items()}
    if isinstance(value, list):
        return [retoken(v) for v in value]
    return re.sub(r'\bmain_wait_4_cnt\b', 'missing_reservation_placeholder', value) if isinstance(value, str) else value


initial = expand_graph(ordinary['coverage'][0]['before'])[0]
last_before = expand_graph(ordinary['copies'][35]['before'])
assert ordinary['copies'][35]['site'] == 'refusal_snapshot'
assert same(retoken(initial), last_before[0]), 'complete actual substitute_token transformation'
assert same(last_before[1], expand_graph(ordinary['coverage'][0]['before'])[1]), 'complete allocation conservation'
assert same(last_before[2], expand_graph(ordinary['coverage'][0]['before'])[2]), 'complete original module conservation'
# The transform intentionally rebuilds every plain container. Its observed
# graph is a tree; a shared-reference coordinate cannot hide a removed token.
def reference_count(value):
    if not isinstance(value, list):
        return sum(reference_count(v) for v in value.values()) if isinstance(value, dict) else 0
    return int(len(value) == 2 and value[0] == 'reference') + sum(reference_count(v) for v in value)
assert reference_count(ordinary['copies'][35]['before'][1][0]) == 0


def qualify(graph):
    p, plan, modules = plain(graph)
    paths = set()

    def number(path, expected, meaning):
        node = graph
        for part in path.split('/')[1:]:
            node = node[int(part)] if isinstance(node, list) else node[part]
        assert same(node, expected), (meaning, path, expected)
        paths.add(path)

    def numeric_map(node, prefix, expected, meaning):
        assert same(node, expected), (meaning, prefix)
        for key, value in expected.items():
            if type(value) is int:
                number(prefix + '/' + key, value, meaning)

    actor = p['actor']
    assert actor['actor_name'] == 'coverage'
    expected_interface = {'inputs': [{'name': 'start', 'width': 1}, {'name': 'data', 'width': '4'}], 'outputs': [{'name': 'result', 'width': '4'}, {'name': 'done', 'width': 1}, {'name': 'notice', 'width': 1}]}
    assert same(actor['interface'], expected_interface), 'authored interface numeric/string kinds'
    for plural, indices in (('inputs', [0]), ('outputs', [1, 2])):
        for i in indices:
            number(f'/1/0/1/actor/1/interface/1/{plural}/1/{i}/1/width', 1, 'authored scalar port width')
    declared_ports = [('start', 'input', 1), ('data', 'input', 4), ('result', 'output', 4), ('done', 'output', 1), ('notice', 'output', 1)]
    assert same(actor['interface_port_metadata'], [{'name': n, 'direction': d, 'width': w} for n, d, w in declared_ports])
    for i, (_, _, width) in enumerate(declared_ports):
        number(f'/1/0/1/actor/1/interface_port_metadata/1/{i}/1/width', width, 'declared metadata width')
    assert actor['storage'] == [{'kind': 'var', 'name': 'value_reg', 'width': 8, 'signals': [{'name': 'value_reg', 'width': 8}]}]
    number('/1/0/1/actor/1/storage/1/0/1/width', 8, 'authored storage width')
    number('/1/0/1/actor/1/storage/1/0/1/signals/1/0/1/width', 8, 'storage signal width')
    assert [t['name'] for t in actor['transactions']] == ['main', 'worker']
    assert same(actor['transactions'][0]['ports'], {'inputs': [{'name': 'payload', 'width': 4}, {'name': 'value_reg', 'width': 4}], 'outputs': []})
    for i in (0, 1):
        number(f'/1/0/1/actor/1/transactions/1/0/1/ports/1/inputs/1/{i}/1/width', 4, 'authored private formal width')
    numeric_map(p['generated_children'], '/1/0/1/generated_children/1', {'worker': 1}, 'spawn target membership')
    for prefix, node in [('/1/0/1/actor_context/1/named_drives/1', p['actor_context']['named_drives']), *[(f'/1/0/1/transactions/1/{tx}/1/named_drives/1', p['transactions'][tx]['named_drives']) for tx in ('main', 'worker')]]:
        numeric_map(node, prefix, {'isf_port_main': 1}, 'named drive membership')

    def main_states(states, prefix):
        names = ['main_idle_0', 'main_set_1', 'main_set_2', 'main_drive_3', 'main_wait_4', 'main_spawn_5', 'main_await_all_6', 'main_done_7']
        assert [s['name'] for s in states] == names
        for si, target, op, kind in [(0, 'can_accept', '=', None), (3, 'isf_port_main_start', '=', 'drive_call_start'), (5, 'job_start', '=', 'spawn_start'), (7, 'done', '<1', 'complete_pulse')]:
            expected = {'lhs': target, 'rhs': 1, 'op': op}
            if kind: expected['source_kind'] = kind
            assignments = [expected]
            if si == 3:
                assignments += [
                    {'lhs': 'isf_port_main_payload', 'op': '=', 'rhs': 'payload', 'source_kind': 'drive_call_param'},
                    {'lhs': 'missing_reservation_placeholder', 'op': '<-', 'rhs': 'value_reg', 'source_kind': 'dynamic_wait_counter_load', 'guard': {'expr': '(!= value_reg 0)'}},
                ]
            assert same(states[si]['assignments'], assignments), ('parent numeric producer', names[si])
            number(f'{prefix}/{si}/1/assignments/1/0/1/rhs', 1, 'parent numeric producer RHS')
        wait = states[4]
        assert wait['kind'] == 'wait' and wait['wait_counter'] == 'missing_reservation_placeholder'
        assert wait['wait_count_kind'] == 'runtime_scalar' and wait['wait_count_source'] == 'value_reg'
        assert wait['assignments'] == [{'lhs': 'missing_reservation_placeholder', 'op': '--', 'rhs': None, 'source_kind': 'dynamic_wait_counter_decrement'}]
        for field, value in (('wait_entry', 1), ('dynamic_wait_entry', 1), ('wait_counter_width', 4)):
            number(f'{prefix}/4/1/{field}', value, 'source-owned dynamic wait metadata')
        assert len(wait['transitions']) == 2
        for ti, (op, target) in enumerate((('=', 'main_spawn_5'), ('>', 'main_wait_4'))):
            assert same(wait['transitions'][ti], {'condition': {'op': op, 'signal': 'missing_reservation_placeholder', 'value': 1}, 'target': target})
            number(f'{prefix}/4/1/transitions/1/{ti}/1/condition/1/value', 1, 'dynamic wait terminal/loop threshold')

    for tx, widths, counters in (
        ('main', {'data': '4', 'result': '4', 'start': 1, 'done': 1, 'notice': 1, 'payload': 4, 'value_reg': 4}, {'can_accept': 1, 'payload': 4, 'value_reg': 4, 'missing_reservation_placeholder': 4}),
        ('worker', {'data': '4', 'result': '4', 'start': 1, 'done': 1, 'notice': 1, 'value_reg': 8}, {'can_accept': 1}),
    ):
        product = p['transaction_products'][tx]
        prefix = '/1/0/1/transaction_products/1/' + tx + '/1'
        numeric_map(product['signal_widths'], prefix + '/signal_widths/1', widths, 'transaction source width lookup')
        numeric_map(product['counters'], prefix + '/counters/1', counters, 'transaction declared/helper widths')
        if tx == 'main':
            main_states(product['states'], prefix + '/states/1')
        else:
            assert [s['name'] for s in product['states']] == ['worker_wait_0', 'worker_done_1']
            wait = product['states'][0]
            assert wait['kind'] == 'wait' and wait['wait_count_kind'] == 'static' and wait['wait_count_source'] == '1'
            for field in ('wait_entry', 'wait_cycles'):
                number(prefix + '/states/1/0/1/' + field, 1, 'authored static wait metadata')
            assert same(product['states'][1]['assignments'], [{'lhs': 'notice', 'op': '<1', 'rhs': 1, 'source_kind': 'complete_pulse'}])
            number(prefix + '/states/1/1/1/assignments/1/0/1/rhs', 1, 'authored worker completion pulse')

    child = p['generated_child_products']['worker']
    prefix = '/1/0/1/generated_child_products/1/worker/1'
    assert child['actor_name'] == 'worker'
    numeric_map(child['counters'], prefix + '/counters/1', {'can_accept': 1, 'isf_child_start_seen': 1}, 'child readiness/history widths')
    numeric_map(child['signal_widths'], prefix + '/signal_widths/1', {'data': 4, 'result': 4, 'start': 1, 'done': 1, 'notice': 1, 'isf_child_start_seen': 1}, 'child source/handshake widths')
    numeric_map(child['reset_values'], prefix + '/reset_values/1', {'isf_child_start_seen': 0}, 'child history reset')
    child_ports = [{'name': 'start', 'direction': 'input', 'width': 1}, {'name': 'notice', 'direction': 'output', 'width': 1}, {'name': 'done', 'direction': 'output', 'width': 1}]
    for field in ('ports', 'explicit_interface_ports'):
        assert same(child[field], child_ports)
        for pi in range(3): number(f'{prefix}/{field}/1/{pi}/1/width', 1, 'child source/completion handshake width')
    assert same(child['actor_completion_outputs'], [{'name': 'notice', 'width': 1}])
    number(prefix + '/actor_completion_outputs/1/0/1/width', 1, 'authored child completion output width')
    assert [s['name'] for s in child['states']] == ['worker_idle_0', 'worker_wait_0', 'worker_done_1']
    for field in ('wait_entry', 'wait_cycles'):
        number(prefix + '/states/1/1/1/' + field, 1, 'generated child static wait metadata')
    for ai, (target, kind) in enumerate((('notice', 'complete_pulse'), ('done', 'activation_completion_pulse'))):
        assert same(child['states'][2]['assignments'][ai], {'lhs': target, 'op': '<1', 'rhs': 1, 'source_kind': kind})
        number(f'{prefix}/states/1/2/1/assignments/1/{ai}/1/rhs', 1, 'child authored/activation pulse')
    for ri, (container, target, operator, rhs, index, kind, domain) in enumerate((
        ('worker_done_1', 'notice', '<1', 1, 0, 'complete_pulse', 'pulse'),
        ('worker_done_1', 'done', '<1', 1, 1, 'activation_completion_pulse', 'pulse'),
        ('isf_child_start_seen', 'isf_child_start_seen', '<-', 'start', 0, 'child_start_history', 'data'),
    )):
        record = child['assignment_provenance'][ri]
        assert record['activation']['container_name'] == container and record['target'] == target
        assert record['operator'] == operator and record['source_kind'] == kind and record['domain'] == domain
        assert same(record['rhs'], rhs)
        number(f'{prefix}/assignment_provenance/1/{ri}/1/assignment_index', index, 'matched producer assignment ordinal')
        if type(rhs) is int: number(f'{prefix}/assignment_provenance/1/{ri}/1/rhs', rhs, 'matched producer RHS')

    ports = [{'name': n, 'direction': d, 'width': ('4' if w == 4 else w)} for n, d, w in declared_ports] + [{'name': 'job_start', 'direction': 'output', 'width': 1, 'isf_handoff': 1}, {'name': 'job_done', 'direction': 'input', 'width': 1, 'isf_handoff': 1}]
    activation = p['parent_activation_products']
    numeric_map(activation['counters'], '/1/0/1/parent_activation_products/1/counters/1', {'isf_port_main_payload': '4', 'isf_port_main_start': 1, 'job_start': 1, 'job_done': 1}, 'source drive/spawn handshake widths')
    for field in ('parent_activation_products', 'parent_wiring_products'):
        assert same(p[field]['ports'], ports)
        for pi in (0, 3, 4, 5, 6): number(f'/1/0/1/{field}/1/ports/1/{pi}/1/width', 1, 'source/spawn handshake port width')
        for pi in (5, 6): number(f'/1/0/1/{field}/1/ports/1/{pi}/1/isf_handoff', 1, 'generated handoff marker')
    for field in ('parent_wiring_products', 'parent_point_products', 'parent_completion_products'):
        main_states(p[field]['states'], f'/1/0/1/{field}/1/states/1')
    completion = p['parent_completion_products']
    for field in ('counters', 'signal_widths'):
        numeric_map(completion[field], f'/1/0/1/parent_completion_products/1/{field}/1', {'isf_completion_job_seen': 1, 'isf_completion_job_ready': 1}, 'completion memory bit widths')
    numeric_map(completion['reset_values'], '/1/0/1/parent_completion_products/1/reset_values/1', {'isf_completion_job_seen': 0}, 'completion memory reset')
    assert completion['instances']['job'] == {'identity': ['generated_child_instance', 'coverage', 'job'], 'start_signal': 'job_start', 'done_signal': 'job_done', 'seen_signal': 'isf_completion_job_seen', 'ready_signal': 'isf_completion_job_ready'}
    memory = completion['dt_blocks'][0]['assignments']
    assert same(memory[0], {'lhs': 'isf_completion_job_seen', 'rhs': '0', 'op': '<-', 'guard': {'port': 'job_start'}, 'source_kind': 'child_completion_rearm'})
    assert memory[1]['source_kind'] == 'child_completion_capture' and same(memory[1]['rhs'], '1')
    assert memory[2]['source_kind'] == 'child_completion_view' and same(memory[2]['rhs'], '(| job_done isf_completion_job_seen)')
    # Membership comes from declarations at the preallocation stage, never
    # their widths. Source signals/states/drive/spawn explain the complete set.
    names = {n for n, _, _ in declared_ports} | {'clk', 'rst_n', 'value_reg', 'payload', 'can_accept', 'isf_port_main', 'isf_port_main_payload', 'isf_port_main_start', 'job_start', 'job_done', 'missing_reservation_placeholder'} | {s['name'] for s in p['transaction_products']['main']['states']}
    for field in ('parent_completion_products', 'parent_storage_read_products', 'parent_storage_write_products', 'parent_named_completion_products'):
        expected_names = names if field == 'parent_completion_products' else names | {'isf_completion_job_ready', 'isf_completion_job_seen'}
        numeric_map(p[field]['input_names'], f'/1/0/1/{field}/1/input_names/1', {n: 1 for n in expected_names}, 'complete declaration allocation membership')
    named_completion = p['parent_named_completion_products']
    for field in ('counters', 'signal_widths'):
        numeric_map(named_completion[field], f'/1/0/1/parent_named_completion_products/1/{field}/1', {'isf_child_completion_job_notice': 1}, 'authored child completion handoff width')
    assert same(named_completion['ports'], [{'name': 'isf_child_completion_job_notice', 'direction': 'input', 'width': 1, 'isf_handoff': 1}])
    for field in ('width', 'isf_handoff'): number('/1/0/1/parent_named_completion_products/1/ports/1/0/1/' + field, 1, 'child completion handoff port/marker')
    for authored, physical in (('payload', 'isf_port_main_payload_formal'), ('value_reg', 'isf_port_main_value_reg')):
        record = plan['formals']['main'][authored]
        assert record['identity'] == ['transaction_port', 'coverage', 'main', authored] and record['physical_name'] == physical
        assert record['declaration']['name'] == authored and record['placement'] == 'direct_private'
        number('/1/1/1/formals/1/main/1/' + authored + '/1/declaration/1/width', 4, 'source-owned canonical plan formal width')
        for field in ('counters', 'signal_widths'):
            assert modules['coverage']['storage_roles'][physical] == 'transaction_port'
            assert physical in modules['coverage']['explicit_internal_signals']
            number('/1/2/1/coverage/1/' + field + '/1/' + physical, 4, 'private module formal width')
    return paths


before = ordinary['copies'][35]['copy'] if options.trust_storable else ordinary['copies'][35]['before']
paths = qualify(before)
assert paths == differences(ordinary['copies'][35]['before'], ordinary['copies'][35]['copy']), 'complete producer-removal field meanings'
assert qualify(pure['copies'][35]['copy']) == paths
expected = [{'ordinal': 35, 'site': 'refusal_snapshot', 'paths': sorted(paths)}]
assert same(expected, json.loads((BASE / 'qualified-fields.json').read_text()))
assert len(paths) == 228
for meaning, mutation in (
    ('metadata width', lambda g: g[1][0][1]['actor'][1]['interface_port_metadata'][1][1][1].update(width=8)),
    ('membership value', lambda g: g[1][0][1]['parent_completion_products'][1]['input_names'][1].update(data=4)),
    ('provenance index', lambda g: g[1][0][1]['generated_child_products'][1]['worker'][1]['assignment_provenance'][1][1][1].update(assignment_index=0)),
    ('wait threshold', lambda g: g[1][0][1]['parent_point_products'][1]['states'][1][4][1]['transitions'][1][0][1]['condition'][1].update(value=0)),
    ('numeric-looking string', lambda g: g[1][0][1]['parent_completion_products'][1]['dt_blocks'][1][0][1]['assignments'][1][0][1].update(rhs=0)),
):
    bad = copy.deepcopy(ordinary['copies'][35]['before']); mutation(bad)
    try: qualify(bad)
    except AssertionError: pass
    else: raise AssertionError(('corruption accepted', meaning))
print('PASS complete actual token-removal transformation and independent authored/metadata/storage/formal, producer/provenance, membership and handshake/wait field contracts.')
print('PASS every retained field reconciles with a separate recursive roster; pure kinds and typed string constants preserve, actual lossy authority and semantic corruptions reject.')
print('OPEN: full snapshot field join and real value-only/native-marker controls precede P2 repair; complete constructors/controllers/moved-root and visual QA remain cold.')

if not options.trust_storable:
    assert (BASE / 'trust-storable.status').read_text().strip() == '1'
    assert (BASE / 'trust-storable.txt').read_text().splitlines()[-1] == 'AssertionError: authored interface numeric/string kinds'

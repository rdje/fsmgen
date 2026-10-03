import argparse
import copy
import hashlib
import json
import re
import subprocess
from pathlib import Path

BASE = Path('docs/audits/reservation-coverage-reusable-module-fields-20261003')
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


def differences(left, right):
    stack, paths = [('', left, right)], set()
    while stack:
        path, a, b = stack.pop()
        if type(a) is not type(b):
            assert type(a) is int and type(b) is str and str(a) == b, ('unexpected difference', path)
            paths.add(path)
        elif isinstance(a, dict):
            assert a.keys() == b.keys(), path
            stack.extend((path + '/' + key, a[key], b[key]) for key in a)
        elif isinstance(a, list):
            assert len(a) == len(b), path
            stack.extend((path + '/' + str(i), x, y) for i, (x, y) in enumerate(zip(a, b)))
        else:
            assert a == b, path
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
storage_source = expressions(bodies['isf/storage_fields.isf'])[0]
library = expressions(bodies['isf/common/fifo.isf'])[0]
fifo_source = named(library, 'actor')
use_source = expressions(bodies['isf/fifo_library_use.isf'])[0]
assert storage_source[:2] == ['actor', 'storage_fields']
assert named(storage_source, 'transaction')[2:] == [
    ['on', 'start'], ['set', 'control', 'wdata'], ['update', 'control_out', 'control'], ['complete', 'done']]
assert named(named(fifo_source, 'storage'), 'bank') == ['bank', 'data', ['width', '8'], ['depth', '4']]
use = named(use_source, 'use')
assert use[:4] == ['use', 'fifo_lib.fifo', 'as', 'u_fifo']
assert ['input', 'data_in', 'data_in'] in named(use, 'bind')
assert ['output', 'data_out', 'data_out'] in named(use, 'bind')
rules = {row[1]: row for row in fifo_source if isinstance(row, list) and row[0] == 'rule'}
assert rules['accepted_push'][3:] == [['store', 'data', 'wr_ptr', 'data_in']]
assert rules['accepted_pop'][3:] == [['load', 'data', 'rd_ptr', 'as', 'data_out']]
lowerer = bodies['perl/FSM/Scheduler/ISF/LoweringIR.pm']
for literal in ('my $entry_index = $signal->{index};', 'bank_index  => $entry_index,',
                "expr_ast => ['==', $index, $entry_index]", 'return { "eq:$signal" => $term_value };'):
    assert literal in lowerer, literal
ordinary = json.loads((MODULE / 'ordinary.json').read_text())
pure = json.loads((MODULE / 'pure.json').read_text())
source_ordinary = json.loads((SOURCE / 'ordinary.json').read_text())
source_pure = json.loads((SOURCE / 'pure.json').read_text())
roster = json.loads((MODULE / 'field-roster.json').read_text())


def storage_fields(graph, files):
    m = plain(graph)
    assert m['actor_name'] == 'storage_fields' and not m['children']
    carrier = expressions(files['storage_fields.fsm'])[0]
    assert carrier[0] == '?fsm:storage_fields'
    paths = set()
    for state_name, lhs, op, category in (
            ('main_idle_0', 'can_accept', '=', None),
            ('main_done_3', 'done', '<1', 'complete_pulse')):
        si = next(i for i, s in enumerate(m['states']) if s['name'] == state_name)
        state = m['states'][si]
        expected = {'lhs': lhs, 'op': op, 'rhs': 1}
        if category is not None:
            expected['source_kind'] = category
        assert same(state['assignments'], [expected]), ('storage numeric assignment', state_name)
        paths.add(f'/1/states/1/{si}/1/assignments/1/0/1/rhs')
        pi = next(i for i, p in enumerate(m['assignment_provenance']) if p['activation']['container_name'] == state_name)
        p = m['assignment_provenance'][pi]
        assert same(p['rhs'], 1) and p['target'] == lhs and p['operator'] == op
        assert p['source_kind'] == (category or 'scheduler_can_accept')
        assert p['assignment_index'] == 0 and p['activation']['container_kind'] == 'state'
        paths.add(f'/1/assignment_provenance/1/{pi}/1/rhs')
        emitted_lhs = lhs + ('>' if lhs == 'done' else '')
        assert [op, [emitted_lhs, '1']] in named(carrier, state_name)
    sizes = named(carrier, '+size')
    interface = named(storage_source, 'interface')
    for name, direction in (('wdata', 'input'), ('control_out', 'output')):
        assert [direction, name, ['width', '8']] in interface
        assert same(m['signal_widths'][name], 8), ('storage declared width', name)
        assert named(sizes, name) == [name, '8']
        paths.add('/1/signal_widths/1/' + name)
    assert paths == {row[0] for row in roster[4]['differences']}
    return paths


def fifo_preparation(graph, files):
    p = plain(graph)
    actor = p['actor']
    assert actor['actor_name'] == 'fifo_library_use'
    assert len(actor['library_uses']) == 1
    authored_use = actor['library_uses'][0]
    products = p['reusable_child_products']
    assert set(products['children']) == {'fifo_library_use__u_fifo'}
    child = products['children']['fifo_library_use__u_fifo']
    assert child['actor_name'] == 'fifo_library_use__u_fifo'
    paths = set()
    child_prefix = '/1/reusable_child_products/1/children/1/fifo_library_use__u_fifo/1'
    bank = {'kind': 'bank', 'name': 'data', 'depth': 4, 'width': 8,
            'signals': [{'name': 'data_' + str(i), 'index': i, 'width': 8} for i in range(4)]}
    for entries, prefix in (
            (authored_use['actor']['storage'], '/1/actor/1/library_uses/1/0/1/actor/1/storage'),
            (child['declared_storage'], child_prefix + '/declared_storage')):
        bi = next(i for i, entry in enumerate(entries) if entry.get('name') == 'data')
        assert same(entries[bi], bank), ('numeric inherited bank', prefix)
        paths.update(f'{prefix}/1/{bi}/1/signals/1/{i}/1/index' for i in range(4))
    for retained_use, prefix in ((authored_use, '/1/actor/1/library_uses/1/0'),
                                (products['library_uses'][0], '/1/reusable_child_products/1/library_uses/1/0')):
        assert retained_use['module'] == 'fifo_library_use__u_fifo' and retained_use['instance'] == 'u_fifo'
        for name, role in (('data_in', 'input'), ('data_out', 'output')):
            bi = next(i for i, b in enumerate(retained_use['bindings']) if b.get('library_name') == name)
            assert same(retained_use['bindings'][bi], {'library_name': name, 'parent_name': name, 'role': role, 'width': 8})
            paths.add(f'{prefix}/1/bindings/1/{bi}/1/width')
    carrier = expressions(files['fifo_library_use__u_fifo.fsm'])[0]
    assert carrier[0] == '?fsm:fifo_library_use__u_fifo'
    for name in ['data_in', 'data_out'] + ['data_' + str(i) for i in range(4)]:
        assert named(named(carrier, '+size'), name) == [name, '8']
    for rule_name, pointer, category, request in (
            ('accepted_push', 'wr_ptr', 'bank_store', 'write_req'),
            ('accepted_pop', 'rd_ptr', 'bank_load', 'read_req')):
        di = next(i for i, dt in enumerate(child['dt_blocks']) if dt['name'] == rule_name)
        dt = child['dt_blocks'][di]
        assert dt['kind'] == 'rule' and len(dt['assignments']) == 4
        outer_guard = '(& write_req (| (! (== occupancy 4)) read_req))' if category == 'bank_store' else '(& read_req (! (== occupancy 0)))'
        assert dt['dte_guard'] == {'expr': outer_guard}
        block = named(carrier, '-' + rule_name)
        assert block[1:3] == ['<', expressions(outer_guard)[0]]
        for i, a in enumerate(dt['assignments']):
            lhs = 'data_' + str(i) if category == 'bank_store' else 'data_out'
            rhs = 'data_in' if category == 'bank_store' else 'data_' + str(i)
            guard = {'expr': f'(== {pointer} {i})', 'expr_ast': ['==', pointer, i]}
            expected = {'bank': 'data', 'bank_index': i, 'index': pointer, 'lhs': lhs,
                        'op': '<-', 'rhs': rhs, 'source_kind': category, 'guard': guard}
            assert same(a, expected), ('numeric bank selection', rule_name, i)
            path = f'{child_prefix}/dt_blocks/1/{di}/1/assignments/1/{i}/1'
            paths.update((path + '/bank_index', path + '/guard/1/expr_ast/1/2'))
            pi = next(j for j, row in enumerate(child['assignment_provenance'])
                      if row['activation']['container_name'] == rule_name and row['assignment_index'] == i)
            provenance = child['assignment_provenance'][pi]
            assert provenance['target'] == lhs and provenance['rhs'] == rhs and provenance['operator'] == '<-'
            assert provenance['source_kind'] == category and provenance['owner'] == rule_name and provenance['owner_kind'] == 'rule'
            assert same(provenance['activation']['assignment_guard'], guard)
            assert same(provenance['condition_terms'], {'eq:' + pointer: i, request: 1})
            prefix = f'{child_prefix}/assignment_provenance/1/{pi}/1'
            paths.update((prefix + '/activation/1/assignment_guard/1/expr_ast/1/2', prefix + '/condition_terms/1/eq:' + pointer))
            emitted_lhs = lhs + ('>' if lhs == 'data_out' else '')
            assert ['<-', [emitted_lhs, rhs], '<', ['==', pointer, str(i)]] in block
    return paths


storage_files = plain(pure['lowerings'][4]['result'])['files']
module_fields = storage_fields(ordinary['copies'][4]['copy'] if options.trust_storable else ordinary['copies'][4]['before'], storage_files)
storage_fields(pure['copies'][4]['copy'], storage_files)
assert not roster[3]['differences']
assert same(ordinary['copies'][3]['before'], ordinary['copies'][3]['copy'])
assert same(source_pure['preparations'][5]['result'], source_ordinary['preparations'][5]['result'])
fifo_files = plain(source_pure['lowerings'][3]['result'])['files']
fifo_graph = source_ordinary['preparations'][4]['result'] if options.trust_inherited else source_pure['preparations'][4]['result']
fields = fifo_preparation(fifo_graph, fifo_files)
assert fields == differences(source_pure['preparations'][4]['result'], source_ordinary['preparations'][4]['result'])
assert json.loads((BASE / 'qualified-fields.json').read_text()) == {
    'module': {'ordinal': 4, 'paths': sorted(module_fields)},
    'preparation': {'ordinal': 4, 'paths': sorted(fields)}}

for label, graph, model, files in (
        ('actual captured Storable', ordinary['copies'][4]['copy'], storage_fields, storage_files),
        ('actual inherited Storable', source_ordinary['preparations'][4]['result'], fifo_preparation, fifo_files)):
    try:
        model(graph, files)
    except AssertionError:
        pass
    else:
        raise AssertionError(('real lossy authority accepted', label))
good = source_pure['preparations'][4]['result']
for label, mutate in (
        ('bank target', lambda g: g[1]['reusable_child_products'][1]['children'][1]['fifo_library_use__u_fifo'][1]['dt_blocks'][1][28][1]['assignments'][1][0][1].update(lhs='wrong')),
        ('guard index', lambda g: g[1]['reusable_child_products'][1]['children'][1]['fifo_library_use__u_fifo'][1]['dt_blocks'][1][28][1]['assignments'][1][0][1]['guard'][1]['expr_ast'][1].__setitem__(2, 1)),
        ('binding endpoint', lambda g: g[1]['reusable_child_products'][1]['library_uses'][1][0][1]['bindings'][1][3][1].update(parent_name='wrong'))):
    bad = copy.deepcopy(good)
    mutate(bad)
    try:
        fifo_preparation(bad, fifo_files)
    except AssertionError:
        pass
    else:
        raise AssertionError(('semantic corruption accepted', label))
bad_files = dict(fifo_files)
bad_files['fifo_library_use__u_fifo.fsm'] = fifo_files['fifo_library_use__u_fifo.fsm'].replace('(<- (data_0 data_in)', '(<- (data_0 data_out)', 1)
assert bad_files != fifo_files
try:
    fifo_preparation(good, bad_files)
except AssertionError:
    pass
else:
    raise AssertionError('carrier corruption accepted')
for mode, last_line in (
        ('trust-storable', "AssertionError: ('storage numeric assignment', 'main_idle_0')"),
        ('trust-inherited', "AssertionError: ('numeric inherited bank', '/1/actor/1/library_uses/1/0/1/actor/1/storage')")):
    assert (BASE / (mode + '.status')).read_text().strip() == '1'
    assert (BASE / (mode + '.txt')).read_text().splitlines()[-1] == last_line
print('PASS complete storage-module and inherited FIFO preparation field sets against independent source, bank/binding/guard/provenance and structured-carrier contracts.')
print('PASS original/pure preservation; actual captured and inherited Storable authorities plus endpoint/index/target/carrier corruptions reject.')
print('OPEN: ATL fields, full module join and snapshots retain their owners; complete controllers/constructors/native/moved-root stay cold.')

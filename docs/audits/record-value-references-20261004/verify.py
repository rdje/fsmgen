"""Independent complete source/layout/stage/kind reference product reader."""
import argparse
import copy
import hashlib
import importlib.util
import json
import marshal
import struct
import subprocess
import sys
from pathlib import Path
from source_calls import calls, scope_sources

sys.path.insert(0, 'docs/audits/record-value-scopes-20261004')
from model import source_projection, thaw
from source_recipes import graph

BASE = Path(__file__).parent
parser = argparse.ArgumentParser()
for option in ('omit-product', 'omit-root-copy', 'swap-role', 'swap-range', 'numeric-preparation', 'trust-private-product'):
    parser.add_argument('--' + option, action='store_true')
args = parser.parse_args()

def identity(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}

def exact(a, b):
    if type(a) is not type(b):
        return False
    if isinstance(a, dict):
        return set(a) == set(b) and all(exact(a[key], b[key]) for key in a)
    if isinstance(a, list):
        return len(a) == len(b) and all(exact(x, y) for x, y in zip(a, b))
    return a == b

if (BASE / 'manifest.json').exists():
    manifest = json.loads((BASE / 'manifest.json').read_text())
    assert {p.name for p in BASE.iterdir()} == set(manifest) | {'manifest.json'}
    for name, row in manifest.items():
        assert identity((BASE / name).read_bytes()) == row, name
binding = json.loads((BASE / 'binding.json').read_text())
assert binding['revision'] == '06b4cfe05e28a1b1e4fae82d316562ece45b0d3f' and len(binding['sources']) == 21
mutable = {'docs/knowledge/isf-aggregate-port-request-baseline.md', 'docs/book/src/13k-isf-feature-support-matrix.md'}
for path, row in binding['sources'].items():
    raw = subprocess.check_output(['git', 'show', binding['revision'] + ':' + path])
    assert identity(raw) == {'bytes': row['bytes'], 'sha256': row['sha256']} and raw.decode() == row['body']
    if path not in mutable:
        assert raw == Path(path).read_bytes(), 'current selected source drift: ' + path
if (BASE / 'doc-updates.json').exists():
    updates = json.loads((BASE / 'doc-updates.json').read_text())
    assert {row['path'] for row in updates} == mutable
    for row in updates:
        assert row['before'] == binding['sources'][row['path']]['body']
        text = row['before']
        for old, new in row['replacements']:
            assert text.count(old) == 1
            text = text.replace(old, new)
        assert text == row['after'] == Path(row['path']).read_text(), 'exact current reference doc transform'
else:
    assert all(binding['sources'][path]['body'] == Path(path).read_text() for path in mutable)
for archive in ('record-value-runtime-20261004', 'record-value-fields-20261004', 'record-value-copy-fields-20261004',
        'record-value-field-join-20261004', 'record-value-actors-20261004', 'record-value-replay-portability-20261004', 'record-value-scopes-20261004'):
    directory = Path('docs/audits') / archive
    manifest = json.loads((directory / 'manifest.json').read_text())
    assert {p.name for p in directory.iterdir()} == set(manifest) | {'manifest.json'}
    for name, row in manifest.items():
        assert identity((directory / name).read_bytes()) == row, archive + '/' + name
    capture = json.loads((directory / ('join.json' if archive == 'record-value-field-join-20261004' else 'binding.json')).read_text())
    for path, row in capture['sources'].items():
        if path not in mutable:
            assert row['body'] == binding['sources'][path]['body']
owner = json.loads((BASE / 'scope-owner.json').read_text())
task_path = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
for task in (subprocess.check_output(['git', 'show', binding['revision'] + ':' + task_path]).decode(), Path(task_path).read_text()):
    start = task.index('- ID: `' + owner['owner'] + '`')
    end = task.index('\n- ID:', start + 1)
    assert task[start:end] == owner['node'] and 'Status: `done`' in owner['node']
source = binding['sources']['t/1986-isf-record-port-value-gates.t']['body']
for text in ("$scope->{old}", "$scope->{lanes}", "'packet.body.count'", "'packet.body.lanes[0]'", "'packet[5:3]'", "'packet[0]'", "'mode.BUSY'", "'shared.CONSTANT'", 'allow_whole => 2'):
    assert text in source, 'exact original source call/addition: ' + text
assert exact(calls(), json.loads((BASE / 'source-calls.json').read_text()))
data = json.loads((BASE / 'reference-products.json').read_text())
assert exact(scope_sources(), data['source_scopes'])
raw = Path('docs/audits/record-value-runtime-20261004/ordinary.json').read_bytes()
assert identity(raw) == data['native_input']
native = json.loads(raw)
selected = [(i, row) for i, row in enumerate(native['api']) if row['kind'] == 'reference']
rows = copy.deepcopy(data['rows'])
if args.omit_product:
    rows.pop()
if args.omit_root_copy:
    rows[-1]['private_root_copies'].pop()
assert len(rows) == len(selected) == len(calls()) == 68, 'complete original reference product/outcome/caller membership'
assert sum(len(row['private_root_copies']) for row in rows) == 65, 'every own original reference root-copy stage; no empty-site classification'
private_control = json.loads((BASE / 'private-control.json').read_text())
recovery = json.loads((BASE / 'generated-bytecode-recovery.json').read_text())
assert len(recovery) == 2
for receipt in recovery:
    raw = bytes.fromhex(receipt['raw_hex'])
    assert identity(raw) == {'bytes': receipt['bytes'], 'sha256': receipt['sha256']}
    assert raw[:4] == importlib.util.MAGIC_NUMBER
    flags, timestamp, size = struct.unpack('<III', raw[4:16])
    assert receipt['header'] == {'flags': flags, 'source_mtime': timestamp, 'source_bytes': size} and flags == 0
    source_path = Path(receipt['source'])
    source_bytes = source_path.read_bytes()
    assert identity(source_bytes) == receipt['source_manifest'] and size == len(source_bytes)
    code = marshal.loads(raw[16:])
    assert receipt['compiled_source_equal'] and code == compile(source_bytes, code.co_filename, 'exec')
    assert code.co_filename.endswith('/' + receipt['source'])
    assert not Path(receipt['path']).exists(), 'exact generated cache residue must remain absent'

def leaves(spec, path='', low=0):
    if spec['kind'] in ('bit', 'bits'):
        return [(path, low, low + spec['width'] - 1, spec)]
    children = [(path + '.' + name, spec['members'][name]) for name in spec['member_order']] if spec['kind'] == 'record' else [(path + '[' + str(i) + ']', child) for i, child in enumerate(spec['items'])]
    cursor = low
    result = []
    for child_path, child in reversed(children):
        result += leaves(child, child_path, cursor)
        cursor += child['width']
    assert cursor - low == spec['width']
    return result

rejected_helpers = {1, 2, *range(12, 23), 39}
for position, ((index, original), row, call) in enumerate(zip(selected, rows, calls())):
    assert row['index'] == index and row['position'] == position and exact(row['original'], original) and exact(row['source_call'], call)
    assert exact(original['before'], original['after']) and original['warnings'] == [], 'whole caller first-touch/reference/type kinds preserve'
    assert original['caller'] == call['caller'] and original['helper'] == call['helper']
    values = thaw(original['before']); arguments = dict(zip(values[::2], values[1::2]))
    assert set(arguments) in ({'scope', 'token', 'access', 'context'}, {'scope', 'token', 'access', 'context', 'allow_whole'})
    assert all(exact(arguments.get(key, 0), call[key]) for key in ('token', 'access', 'allow_whole', 'context'))
    projected = source_projection(arguments)
    matches = [source['label'] for source in data['source_scopes'] if exact(thaw(source['scope']), projected['scope'])]
    assert matches == row['source_scope_matches'] and matches, 'whole source/nearest-mask scope identities'
    root = call['token'].split('.', 1)[0].split('[', 1)[0]
    private = [dict(value, index=i) for i, value in enumerate(native['copies']) if value['api'] == index and value['kind'] == 'value-private'
        and value['caller'] == ['FSM::Support::ISFRecordPortValues', 'perl/FSM/Support/ISFRecordPortValues.pm', 60]]
    assert exact(private, row['private_root_copies'])
    assert len(private) == int(call['allow_whole'] in (0, 1) and root in arguments['scope'])
    if private:
        assert exact(private[0]['before'], graph(arguments['scope'][root]))
        assert exact(source_projection(thaw(private[0]['copy'])), projected['scope'][root])
    end = next((i for i in range(index + 1, len(native['api'])) if native['api'][i]['kind'] in ('scope', 'reference', 'copy')), len(native['api']))
    assert exact(row['operation_span'], [{'index': i, 'record': native['api'][i]} for i in range(index + 1, end)])
    accepted = int(call['helper'] not in rejected_helpers)
    assert original['accepted'] == row['meaning']['accepted'] == accepted
    expected = thaw(row['expected_product'])
    if accepted and root in projected['scope'] and projected['scope'][root]['type_spec'] is not None:
        declaration = projected['scope'][root]
        assert expected is not None and set(expected) in ({'root', 'role', 'path_text', 'type_spec', 'width'}, {'root', 'role', 'path_text', 'type_spec', 'width', 'low', 'high'})
        assert expected['root'] == root and expected['role'] == declaration['role']
        suffix = call['token'][len(root):]
        assert expected['path_text'] == suffix and type(expected['width']) is int
        if not suffix:
            assert expected['width'] == declaration['type_spec']['width']
            assert exact(source_projection(expected['type_spec']), declaration['type_spec'])
        else:
            scalar = declaration['type_spec']['kind'] in ('bit', 'bits')
            if scalar:
                low, high, width, kind = (3, 5, 3, 'bits') if suffix == '[5:3]' else (0, 0, 1, 'bit')
                assert suffix in ('[5:3]', '[0]')
                spec = {'kind': kind, 'signed': 0, 'width': width}
            else:
                matching = [leaf for leaf in leaves(declaration['type_spec']) if leaf[0] == suffix]
                assert len(matching) == 1
                _, low, high, spec = matching[0]
                width = spec['width']
            assert exact([expected['width'], expected['low'], expected['high']], [width, low, high])
            assert all(type(expected[key]) is int for key in ('width', 'low', 'high'))
            assert exact(source_projection(expected['type_spec']), spec), 'independent least-significant-first leaf inventory/range/property oracle'
        stage = row['type_stage']
        assert exact(stage['record'], native['api'][stage['index']]) and stage['index'] in range(index + 1, end)
        stage_arguments = thaw(stage['record']['before'])
        assert stage_arguments[0] == 'FSM::Package::AggregatePathSupport'
        assert exact(graph(expected['type_spec']), graph(stage_arguments[1])), 'exact complete own type clone input spellings/kinds'
    else:
        assert expected is None and row['type_stage'] is None
    actual = copy.deepcopy(original['result'])
    if index == 4659:
        assert private_control['reference_index'] == index
        assert exact(private_control['source_input_stage'], row['type_stage'])
        assert exact(private_control['expected'], row['expected_product'])
        check_candidate = thaw(row['expected_product'])
        check_candidate['width'] = thaw(row['type_stage']['record']['before'])[1]['width']
        assert exact(graph(check_candidate), private_control['candidate'])
        candidate = thaw(actual)
        if args.swap_role:
            candidate['role'] = 'output'
        if args.swap_range:
            candidate['low'], candidate['high'] = 0, 2
        if args.numeric_preparation:
            candidate['type_spec']['signed'] = 1
        if args.trust_private_product:
            raw_type = thaw(row['type_stage']['record']['before'])[1]
            assert type(raw_type['width']) is str and int(raw_type['width']) == candidate['width']
            candidate['width'] = raw_type['width']
        actual = graph(candidate)
    assert exact(actual, row['expected_product']), 'whole source/layout reference product and exact preparation versus final numeric kinds'
assert sum(row['meaning']['accepted'] for row in rows) == 54 and sum(row['expected_product'] is not None for row in rows) == 51
run = subprocess.run(['python3', '-B', str(BASE / 'replay_scope.py'), '--check'], text=True, capture_output=True)
assert run.returncode == 0, run.stdout + run.stderr
print('PASS all sixty-eight whole source/caller/private-root/path reference outcomes: fifty-one products, three delegated/unresolved nulls, fourteen refusals and every65 own root-copy stage. Independent packed leaf inventory/scalar slice/index witnesses, nearest roles/masks, exact type input spellings and NUM widths/ranges match. Completed scope ordinary/five RED controls and nested prior semantic proofs conserve. Native cause/copy/core assurance remains owned.')

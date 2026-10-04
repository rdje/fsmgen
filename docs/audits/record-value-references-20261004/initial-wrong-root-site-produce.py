"""Build full source/layout reference models without native result authority."""
import copy
import hashlib
import json
import sys
from pathlib import Path
from path_model import resolve
from source_calls import calls

sys.path.insert(0, 'docs/audits/record-value-scopes-20261004')
from model import prepared_type, source_projection, thaw
from source_recipes import graph, recipes

BASE = Path(__file__).parent
raw = Path('docs/audits/record-value-runtime-20261004/ordinary.json').read_bytes()
native = json.loads(raw)
source_scopes = []
for recipe in recipes():
    if recipe['accepted']:
        items = thaw(recipe['arguments'])
        args = dict(zip(items[::2], items[1::2]))
        source_scopes.append((recipe['label'], {**args['outer'], **args['local']}))
roots = json.loads(Path('docs/audits/record-value-copy-fields-20261004/source-models.json').read_text())['roots']
storage_only = copy.deepcopy(next(scope for label, scope in source_scopes if label == 'storage-only'))
storage_only['old'] = {'role': 'storage', 'type_spec': copy.deepcopy(roots['authored:frame'])}
source_scopes.append(('storage-only+old', copy.deepcopy(storage_only)))
storage_only['lanes'] = {'role': 'storage', 'type_spec': copy.deepcopy(roots['authored:lanes'])}
source_scopes.append(('storage-only+old+lanes', storage_only))
selected = [(i, row) for i, row in enumerate(native['api']) if row['kind'] == 'reference']
assert len(selected) == len(calls()) == 68
assert calls() == json.loads((BASE / 'source-calls.json').read_text())
rows = []
for position, ((index, actual), call) in enumerate(zip(selected, calls())):
    items = thaw(actual['before'])
    arguments = dict(zip(items[::2], items[1::2]))
    assert {key: arguments.get(key, 0) for key in ('token', 'access', 'allow_whole', 'context')} == {key: call[key] for key in ('token', 'access', 'allow_whole', 'context')}
    assert actual['helper'] == call['helper'] and actual['caller'] == call['caller']
    projected = source_projection(arguments)
    matches = [label for label, scope in source_scopes if scope == projected['scope']]
    assert matches, 'every full original reference scope must have independently authored source authority'
    meaning = resolve(projected)
    expected = copy.deepcopy(meaning.get('product'))
    end = next((i for i in range(index + 1, len(native['api'])) if native['api'][i]['kind'] in ('scope', 'reference', 'copy')), len(native['api']))
    operation_span = [{'index': i, 'record': row} for i, row in enumerate(native['api'][index + 1:end], index + 1)]
    private = [dict(row, index=i) for i, row in enumerate(native['copies']) if row['api'] == index
        and row['kind'] == 'value-private' and row['caller'] == ['FSM::Support::ISFRecordPortValues', 'perl/FSM/Support/ISFRecordPortValues.pm', 58]]
    type_stage = None
    if expected is not None:
        stages = [row for row in operation_span if row['record']['kind'] == 'structured-clone'
            and (row['record']['caller'] == ['FSM::Support::ISFRecordPortValues', 'perl/FSM/Support/ISFRecordPortValues.pm', 71]
                or row['record']['caller'] == ['FSM::Package::AggregatePathSupport', 'perl/FSM/Package/AggregatePathSupport.pm', 295])]
        assert stages
        type_stage = stages[-1]
        stage_arguments = thaw(type_stage['record']['before'])
        assert stage_arguments[0] == 'FSM::Package::AggregatePathSupport'
        assert graph(source_projection(stage_arguments[1])) == graph(expected['type_spec'])
        expected['type_spec'] = prepared_type(expected['type_spec'], stage_arguments[1])
    rows.append({'index': index, 'position': position, 'source_call': call, 'source_scope_matches': matches,
        'original': actual, 'private_root_copies': private, 'operation_span': operation_span,
        'meaning': meaning, 'type_stage': type_stage, 'expected_product': graph(expected)})
assert sum(row['meaning']['accepted'] for row in rows) == 54
assert sum(row['expected_product'] is not None for row in rows) == 51
(BASE / 'reference-products.json').write_text(json.dumps({'native_input': {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()},
    'source_scopes': [{'label': label, 'scope': graph(scope)} for label, scope in source_scopes], 'rows': rows}, sort_keys=True, indent=2) + '\n')
print('PASS complete original sixty-eight source/caller/root/path reference models: fifty-four accepted, including three delegated/unresolved nulls, and fourteen refusals. Fifty-one whole products rebuild from source identity/layout and exact own type clone input; no actual reference/range result is model authority.')

"""Source-only copy meaning joined to complete original call/private facts."""
import hashlib
import json
from pathlib import Path
from model import helpers, outcome, source_reference
from source_calls import graph_source, recipes

BASE = Path(__file__).parent
raw = Path('docs/audits/record-value-runtime-20261004/ordinary.json').read_bytes()
native = json.loads(raw)
assert recipes() == json.loads((BASE / 'source-recipes.json').read_text())
selected = [(i, row) for i, row in enumerate(native['api']) if row['kind'] == 'copy']
assert len(selected) == len(recipes()) == 22
rows = []
for position, ((index, actual), recipe) in enumerate(zip(selected, recipes())):
    values = helpers.thaw(actual['before'])
    arguments = dict(zip(values[::2], values[1::2]))
    assert set(arguments) == {'source', 'target', 'context'}
    projected = ['source', source_reference(arguments['source']), 'target', source_reference(arguments['target']), 'context', arguments['context']]
    assert graph_source(projected) == recipe['arguments'], 'whole independently authored source reference/role/type/width/copy recipe'
    assert actual['caller'] == recipe['caller'] and actual['helper'] == recipe['helper']
    semantic = outcome(projected[1], projected[3])
    stages = []
    for name, line in (('source', 101), ('target', 102)):
        private = [dict(value, index=i) for i, value in enumerate(native['copies']) if value['api'] == index and value['kind'] == 'value-private'
            and value['caller'] == ['FSM::Support::ISFRecordPortValues', 'perl/FSM/Support/ISFRecordPortValues.pm', line]]
        assert len(private) == int(arguments[name] is not None), 'exact conditional source/target private clone population'
        if private:
            assert private[0]['before'] == graph_source(arguments[name])
            stages.append({'name': name, 'copy': private[0]})
    end = next((i for i in range(index + 1, len(native['api'])) if native['api'][i]['kind'] in ('scope', 'reference', 'copy')), len(native['api']))
    span = [{'index': i, 'record': native['api'][i]} for i in range(index + 1, end)]
    rows.append({'index': index, 'position': position, 'recipe': recipe, 'original': actual,
        'meaning': semantic, 'private_stages': stages, 'operation_span': span})
assert sum(len(row['private_stages']) for row in rows) == 41
assert sum(row['meaning']['accepted'] for row in rows) == 8
assert sum(row['meaning']['product'] == 1 for row in rows) == 5
assert sum(row['meaning']['product'] == 0 for row in rows) == 3
(BASE / 'copy-products.json').write_text(json.dumps({'native_input': {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}, 'rows': rows}, sort_keys=True, indent=2) + '\n')
print('PASS independent whole source/type/role/reference copy models for every22 original call and41 own clone stages: five strict record copies, three existing-contract zeros, fourteen refusals. No actual copy result is model authority.')

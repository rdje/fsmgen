"""Bind real narrower payload truth for a strict signed-type copy refusal."""
import json
from pathlib import Path
from model import helpers
from source_calls import graph_source

BASE = Path(__file__).parent
native = json.loads(Path('docs/audits/record-value-runtime-20261004/ordinary.json').read_text())
ledger = json.loads((BASE / 'copy-products.json').read_text())
wanted = next(row for row in ledger['rows'] if row['recipe']['label'] == 'identity:signed_data')
values = helpers.thaw(wanted['recipe']['arguments'])
arguments = dict(zip(values[::2], values[1::2]))
for index, row in enumerate(native['api']):
    if row['kind'] != 'payload':
        continue
    original = helpers.thaw(row['before'])
    if helpers.source_projection(original[1]) == arguments['source']['type_spec'] and helpers.source_projection(original[2]) == arguments['target']['type_spec']:
        assert row['accepted'] == 1 and type(row['result']) is int and row['result'] == 1
        assert wanted['meaning'] == {'accepted': 0, 'product': None, 'reason': 'resolved-recursive-identity'}
        (BASE / 'payload-control.json').write_text(json.dumps({'copy_index': wanted['index'], 'payload_index': index,
            'whole_original_payload': row, 'source_type': graph_source(arguments['source']['type_spec']),
            'target_type': graph_source(arguments['target']['type_spec']), 'candidate': {'accepted': 1, 'product': row['result']},
            'required_copy': wanted['meaning']}, sort_keys=True, indent=2) + '\n')
        print('PASS original real payload', index, 'accepts signed-property difference while independent whole-copy', wanted['index'], 'requires strict resolved identity and refuses; narrower actual truth cannot be copy authority.')
        break
else:
    raise AssertionError('genuine original matching payload/copy contrast absent')

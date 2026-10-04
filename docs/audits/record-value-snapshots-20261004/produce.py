"""Whole snapshot models from qualified source-capture models, never results."""
import copy
import hashlib
import importlib.util
import json
from pathlib import Path

BASE = Path(__file__).parent
spec = importlib.util.spec_from_file_location('bound_capture_graph', 'docs/audits/record-value-captures-20261004/model.py')
helpers = importlib.util.module_from_spec(spec)
spec.loader.exec_module(helpers)
graph, thaw = helpers.graph, helpers.thaw
native = json.loads(Path('docs/audits/record-value-runtime-20261004/ordinary.json').read_text())
captures = json.loads(Path('docs/audits/record-value-captures-20261004/capture-products.json').read_text())
fields = json.loads(Path('docs/audits/record-value-copy-fields-20261004/fields.json').read_text())
by_index = {row['index']: row for row in captures['rows']}

def identity(value):
    raw = json.dumps(value, sort_keys=True, separators=(',', ':')).encode()
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}

rows, last_capture = [], None
for index, original in enumerate(native['api']):
    if original['kind'] == 'capture':
        last_capture = index
    if original['kind'] != 'snapshot':
        continue
    source = by_index[last_capture]
    assert source['expected_refusal'] is None
    expected = thaw(source['expected_product'])
    handoff = copy.deepcopy(expected)
    private_interface = thaw(source['private']['copy'])
    raw_ports = private_interface['inputs'] + private_interface['outputs']
    assert len(raw_ports) == len(handoff)
    for port, raw in zip(handoff, raw_ports):
        # Capture passes its detached raw port width to snapshot; all packed
        # field numerics were freshly constructed from source layout.
        assert int(raw['width']) == port['width']
        port['width'] = raw['width']
    stages = [dict(row, index=i) for i, row in enumerate(native['copies']) if row['api'] == index]
    assert len(stages) == 1
    stage = stages[0]
    assert stage['kind'] == 'metadata-private'
    rows.append({'index': index, 'original': original, 'capture_index': last_capture,
        'whole_capture_model': identity(source), 'expected_handoff': graph(handoff),
        'expected_product': graph(expected), 'private': stage,
        'whole_field_record': fields['rows'][stage['index']]})
assert len(rows) == len({row['capture_index'] for row in rows}) == 220
(BASE / 'snapshot-products.json').write_text(json.dumps({'rows': rows}, sort_keys=True, indent=2) + '\n')
print('PASS all original220 snapshot source-capture/handoff/private-stage/full-field models retained. Separate closed schema/layout/kind/native reader remains required.')

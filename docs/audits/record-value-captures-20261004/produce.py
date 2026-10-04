"""Bind each complete capture to authored input and detached field authority."""
import hashlib
import json
from pathlib import Path
from model import capture, graph, hydrate, Refusal, thaw, type_meaning

BASE = Path(__file__).parent
native = json.loads(Path('docs/audits/record-value-runtime-20261004/ordinary.json').read_text())
sources = json.loads(Path('docs/audits/record-value-copy-fields-20261004/source-models.json').read_text())
fields = json.loads(Path('docs/audits/record-value-copy-fields-20261004/fields.json').read_text())
actors = json.loads(Path('docs/audits/record-value-actors-20261004/actor-models.json').read_text())
registry = {}
for group in ('roots', 'nodes'):
    for name, value in sources[group].items():
        source = hydrate(value)
        signature = json.dumps(graph(source), sort_keys=True)
        registry.setdefault(signature, []).append((group + ':' + name, source))

def identity(value):
    raw = json.dumps(value, sort_keys=True, separators=(',', ':')).encode()
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}

rows = []
for index, original in enumerate(native['api']):
    if original['kind'] != 'capture':
        continue
    stages = [dict(row, index=i) for i, row in enumerate(native['copies']) if row['api'] == index]
    assert len(stages) == 1 and stages[0]['kind'] == 'metadata-private'
    arguments = thaw(original['before'])
    assert len(arguments) in (1, 2)
    interface = arguments[0]
    default = arguments[1] if len(arguments) == 2 else None
    private = thaw(stages[0]['copy'])
    assert graph(interface) == stages[0]['before'] and stages[0]['before'] == stages[0]['after']
    origins = []
    if original['caller'][0] == 'FSM::Adapter::ISF::Parser':
        actor = 'local' if original['parse'] == 0 else 'imported'
        expected_interface = actors['actors'][actor]['interface']
        assert graph(expected_interface) == graph(interface)
        source_interface = expected_interface
        origins.append({'actor': actor, 'whole_authored_interface': identity(source_interface)})
    else:
        assert original['caller'] == ['FSM::Support::ISFRecordPortValues', 'perl/FSM/Support/ISFRecordPortValues.pm', 147]
        assert set(interface) == {'inputs', 'outputs'} and interface['outputs'] == [] and len(interface['inputs']) == 1
        port = interface['inputs'][0]
        assert set(port) == {'name', 'type', 'type_spec', 'width'} and port['name'] == 'value' and port['type'] == 'resolved_value'
        projected = graph(type_meaning(port['type_spec']))
        candidates = registry[json.dumps(projected, sort_keys=True)]
        source = candidates[0][1]
        assert int(port['width']) == source['width']
        source_interface = {'inputs': [{'name': 'value', 'type': 'resolved_value', 'width': source['width'], 'type_spec': source}], 'outputs': []}
        origins.append({'path': '/inputs/0/type_spec', 'source_nodes': [name for name, _ in candidates], 'whole_source_type': projected})
    assert default is None
    # Every raw private field remains in the original stage. Only physical
    # type/source meaning is compared here; final numeric metadata is rebuilt.
    for group in ('inputs', 'outputs'):
        assert len(private[group]) == len(source_interface[group])
        for raw, source in zip(private[group], source_interface[group]):
            assert set(raw) == set(source)
            for key in source:
                if key == 'type_spec':
                    assert graph(type_meaning(raw[key])) == graph(source[key])
                elif key == 'width':
                    assert int(raw[key]) == source[key]
                else:
                    assert raw[key] == source[key]
    try:
        expected, reason = graph(capture(source_interface, default)), None
    except Refusal as error:
        expected, reason = None, str(error)
    rows.append({'index': index, 'original': original, 'source_interface': graph(source_interface),
        'source_origins': origins, 'private': stages[0], 'whole_field_record': fields['rows'][stages[0]['index']],
        'expected_product': expected, 'expected_refusal': reason})
assert len(rows) == 227
(BASE / 'capture-products.json').write_text(json.dumps({'rows': rows}, sort_keys=True, indent=2) + '\n')
print('PASS complete source-directed capture models; every original call, whole private stage and source/field relation retained. Native output comparison remains the separate reader obligation.')

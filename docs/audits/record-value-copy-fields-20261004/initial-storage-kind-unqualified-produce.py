"""Enumerate complete copied width/type facts without erasing primitive kinds."""
import hashlib
import json
from pathlib import Path

BASE = Path(__file__).parent
native_path = Path('docs/audits/record-value-runtime-20261004/ordinary.json')
native = json.loads(native_path.read_text())
sources = json.loads((BASE / 'source-models.json').read_text())

def stage_shape(value, key=None):
    # This limited view identifies physical source meaning only. The complete
    # original and copied typed graphs remain independent authorities below.
    if isinstance(value, dict):
        return {name: stage_shape(child, name) for name, child in value.items()}
    if isinstance(value, list):
        return [stage_shape(child) for child in value]
    if key in ('width', 'signed') and isinstance(value, str) and value.isascii() and value.isdecimal():
        return int(value)
    return value

registry = {}
for name, spec in sources['nodes'].items():
    signature = json.dumps(stage_shape(spec), sort_keys=True, separators=(',', ':'))
    registry.setdefault(signature, []).append(name)

def shape(graph, root_path, path=None):
    path = root_path if path is None else path
    if not isinstance(graph, list):
        return graph
    kind, body = graph
    if kind == 'reference':
        target = '.' if body == root_path else body
        return {'$reference': target}
    if kind == 'array':
        return [shape(child, root_path, path + '/' + str(index)) for index, child in enumerate(body)]
    assert kind == 'hash'
    return {name: shape(child, root_path, path + '/' + name.replace('~', '~0').replace('/', '~1'))
        for name, child in body.items()}

def facts(graph, path='', ancestor=None):
    if not isinstance(graph, list):
        return []
    kind, body = graph
    if kind == 'reference':
        return []
    result = []
    if kind == 'hash':
        if 'width' in body and not isinstance(body['width'], list):
            actual_shape = shape(graph, path)
            origins = []
            if 'kind' in body:
                signature = json.dumps(stage_shape(actual_shape), sort_keys=True, separators=(',', ':'))
                origins = sorted(registry.get(signature, []))
                ancestor = {'path': path, 'source_nodes': origins}
            result.append({'path': path + '/width', 'value': body['width'],
                'primitive_kind': type(body['width']).__name__,
                'type_shape': actual_shape if 'kind' in body else None,
                'source_nodes': origins, 'type_ancestor': ancestor,
                'type_kind': body.get('kind'), 'metadata_type_kind': body.get('type_kind')})
        pairs = sorted(body.items())
    else:
        assert kind == 'array'
        pairs = enumerate(body)
    for key, child in pairs:
        escaped = str(key).replace('~', '~0').replace('/', '~1')
        result.extend(facts(child, path + '/' + escaped, ancestor))
    return result

rows = []
for index, row in enumerate(native['copies']):
    api = native['api'][row['api']] if row['api'] is not None else None
    helper = native['helpers'][row['helper']] if row['helper'] is not None else None
    rows.append({'index': index, 'copy_kind': row['kind'], 'caller': row['caller'],
        'api_index': row['api'], 'api_kind': api['kind'] if api else None,
        'helper_index': row['helper'], 'helper_label': helper['label'] if helper else None,
        'parse_index': row['parse'], 'before': facts(row['before']), 'after': facts(row['copy'])})
(BASE / 'fields.json').write_text(json.dumps({'rows': rows,
    'native_input': {'bytes': native_path.stat().st_size, 'sha256': hashlib.sha256(native_path.read_bytes()).hexdigest()},
    'meaning': 'Raw copied width facts and complete type/source candidates. Limited width/signed '
        'stage signatures identify physical meaning only; they are never caller-kind or final product authority.'},
    sort_keys=True, indent=2) + '\n')
unknown = [(r['index'], f['path'], f['type_shape']) for r in rows for f in r['before']
    if f['type_kind'] is not None and not f['source_nodes']]
(BASE / 'unqualified-source-node-gaps.json').write_text(json.dumps(unknown, indent=2) + '\n')
print('Complete actual copy width/source candidates enumerated; unmapped before-type nodes:', len(unknown))

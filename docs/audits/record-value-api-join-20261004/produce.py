"""Whole source/owner/value API/clone/field/model join; no new semantics inferred."""
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path(__file__).parent
binding = json.loads((BASE / 'binding.json').read_text())
task = subprocess.check_output(['git', 'show', binding['revision'] + ':docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md']).decode()
parent = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.2.2.2'

def identity(value):
    raw = json.dumps(value, sort_keys=True, separators=(',', ':')).encode()
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}

def file_identity(path):
    raw = path.read_bytes()
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}

children, apis, copies = [], [], []
for suffix, archive, filename in [('1', 'record-value-scopes-20261004', 'scope-products.json'),
        ('2', 'record-value-references-20261004', 'reference-products.json'), ('3', 'record-value-copies-20261004', 'copy-products.json')]:
    owner = parent + '.' + suffix
    start = task.index('- ID: `' + owner + '`')
    end = task.index('\n- ID:', start + 1)
    node = task[start:end]
    assert 'Status: `done`' in node
    directory = Path('docs/audits') / archive
    data = json.loads((directory / filename).read_text())
    children.append({'owner': owner, 'archive': archive, 'product_file': filename, 'node': node,
        'manifest': file_identity(directory / 'manifest.json'), 'whole_product_ledger': file_identity(directory / filename)})
    for row in data['rows']:
        apis.append({'index': row['index'], 'archive': archive, 'original': identity(row['original']),
            'whole_source_stage_model': identity(row)})
        private = row['private'] if suffix == '1' else row['private_root_copies'] if suffix == '2' else [stage['copy'] for stage in row['private_stages']]
        for clone in private:
            copies.append({'index': clone['index'], 'archive': archive, 'api': row['index'],
                'whole_model_copy': identity(clone)})
native_path = Path('docs/audits/record-value-runtime-20261004/ordinary.json')
native = json.loads(native_path.read_text())
fields_path = Path('docs/audits/record-value-copy-fields-20261004/fields.json')
fields = json.loads(fields_path.read_text())
apis.sort(key=lambda row: row['index'])
copies.sort(key=lambda row: row['index'])
assert len(apis) == len({row['index'] for row in apis}) == 130
assert [row['index'] for row in apis] == [i for i, row in enumerate(native['api']) if row['kind'] in ('scope', 'reference', 'copy')]
assert len(copies) == len({row['index'] for row in copies}) == 233
assert [row['index'] for row in copies] == [i for i, row in enumerate(native['copies']) if row['kind'] == 'value-private']
for row in copies:
    original = native['copies'][row['index']]
    row['whole_original_copy'] = identity(original)
    row['whole_source_field_record'] = identity(fields['rows'][row['index']])
    row['before_graph'] = identity(original['before'])
    row['copy_graph'] = identity(original['copy'])
    row['kind'] = original['kind']
    row['caller'] = original['caller']
    row['helper'] = original['helper']
    row['parse'] = original['parse']
support = {name: file_identity(Path('docs/audits') / directory / file) for name, directory, file in [
    ('native', 'record-value-runtime-20261004', 'ordinary.json'),
    ('source_models', 'record-value-copy-fields-20261004', 'source-models.json'),
    ('all_original_fields', 'record-value-copy-fields-20261004', 'fields.json'),
    ('authored_types_layouts', 'record-value-fields-20261004', 'authored-models.json'),
    ('whole_actors', 'record-value-actors-20261004', 'actor-models.json'),
    ('portable_field_actor_join', 'record-value-replay-portability-20261004', 'join.json')]}
(BASE / 'join.json').write_text(json.dumps({'revision': binding['revision'], 'children': children,
    'apis': apis, 'copies': copies, 'support': support}, sort_keys=True, indent=2) + '\n')
print('PASS exact complete three-owner/current21 source/original130 value API/source-stage-product and233 native clone/full-field join. Counts accompany whole model/native/property/graph identities; core APIs and native assurance remain open.')

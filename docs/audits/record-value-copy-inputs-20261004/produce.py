"""Bind the entire original test-copy population and exact existing recipes."""
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-copy-inputs-20261004')
REVISION = 'b63195f3ae231555850de96b5d2412c74b6e4272'
PRIOR = Path('docs/audits/record-value-original-replay-20261004')
SEMANTIC = Path('docs/audits/record-value-semantic-join-20261004')
RECIPE = 't/1960-isf-formal-reservation-coverage.t'


def capture(path):
    raw = subprocess.check_output(['git', 'show', REVISION + ':' + path])
    return {'body': raw.decode(), 'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


pin = json.loads((PRIOR / 'binding.json').read_text())
sources = {path: capture(path) for path in [*pin['sources'], RECIPE]}
task = capture(pin['task_path'])['body']
owners = [row['owner'] for row in pin['owners']]
owners.append('SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.1')
nodes = []
for owner in owners:
    start = task.index('- ID: `' + owner + '`')
    end = task.index('\n- ID:', start + 1)
    node = task[start:end]
    assert 'Status: `done`' in node
    nodes.append({'owner': owner, 'node': node})
(BASE / 'binding.json').write_text(json.dumps({'revision': REVISION, 'sources': sources,
    'task_path': pin['task_path'], 'owners': nodes}, sort_keys=True, indent=2) + '\n')
native = json.loads(Path('docs/audits/record-value-runtime-20261004/ordinary.json').read_text())
semantic = json.loads((SEMANTIC / 'semantics.json').read_text())
indices = [index for index, row in enumerate(native['copies']) if row['kind'] == 'test']
rows = [{'index': index, 'native': native['copies'][index], 'semantic': semantic['copies'][index]} for index in indices]
(BASE / 'inputs.json').write_text(json.dumps({'rows': rows, 'source_models': semantic['source_models']}, sort_keys=True, indent=2) + '\n')
source = sources[RECIPE]['body']
boundaries = [('source_value_copy', 'sub snapshot_graph'), ('snapshot_graph', 'sub input_snapshot'),
    ('input_snapshot', 'sub source_references'), ('source_references', 'sub source_copy'),
    ('source_copy', 'my $scheduler =')]
recipes = []
for name, end_marker in boundaries:
    start = source.index('sub ' + name)
    end = source.index(end_marker, start + 1)
    body = source[start:end]
    recipes.append({'name': name, 'source_path': RECIPE, 'start_line': source[:start].count('\n') + 1,
        'end_line': source[:end].count('\n'), 'body': body,
        'bytes': len(body.encode()), 'sha256': hashlib.sha256(body.encode()).hexdigest()})
(BASE / 'recipes.json').write_text(json.dumps(recipes, sort_keys=True, indent=2) + '\n')
print('Bound every original17 whole test-copy/native/source/field record, complete source models and five exact existing recipe bodies. Candidate/native/hot repairs remain unqualified successors.')

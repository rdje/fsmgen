"""Project complete diagnostic repair populations without classifying evidence."""
import json
from pathlib import Path
BASE = Path(__file__).parent
result = {}
for role, name in [('metadata', 'interface-metadata-cause-repair-20261004'),
                   ('writer', 'interface-metadata-writer-cause-repair-20261004')]:
    parent = Path('docs/audits') / name
    result[role] = {kind: json.loads((parent / (kind + '.json')).read_text())
                    for kind in ('ordinary', 'bypass', 'context-native', 'sources-after')}
    result[role]['manifest'] = json.loads((parent / 'manifest.json').read_text())
result['writer']['source-models'] = json.loads(Path('docs/audits/interface-metadata-writer-cause-repair-20261004/source-models.json').read_text())
result['expected-causes'] = json.loads(Path('docs/audits/interface-metadata-runtime-20261004/expected-causes.json').read_text())
(BASE / 'join.json').write_text(json.dumps(result, sort_keys=True, separators=(',', ':')) + '\n')

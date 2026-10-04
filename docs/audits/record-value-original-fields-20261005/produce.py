"""Observe current fields using the complete qualified predecessor producer.

Only paths/output names change. This producer never supplies expected graphs.
"""
import hashlib
import json
from pathlib import Path

BASE = Path('docs/audits/record-value-original-fields-20261005')
FIELDS = Path('docs/audits/record-value-copy-fields-20261004')
CAPTURE = Path('docs/audits/record-value-original-candidate-20261004')


def apply(source, replacements):
    for old, new in replacements:
        assert source.count(old) == 1, 'unique full observation transform'
        source = source.replace(old, new)
    return source


transforms = []
for mode in ('ordinary', 'storable', 'controls'):
    replacements = [
        ('BASE = Path(__file__).parent', 'BASE = Path(' + repr(str(BASE)) + ')'),
        ("Path('docs/audits/record-value-runtime-20261004/ordinary.json')",
         'Path(' + repr(str(CAPTURE / (mode + '.json'))) + ')'),
        ("(BASE / 'source-models.json')", 'Path(' + repr(str(FIELDS / 'source-models.json')) + ')'),
        ("(BASE / 'fields.json')", "(BASE / '" + mode + "-fields.json')"),
        ("(BASE / 'unqualified-source-node-gaps.json')", "(BASE / '" + mode + "-source-node-gaps.json')"),
    ]
    source = (FIELDS / 'produce.py').read_text()
    transformed = apply(source, replacements)
    transforms.append({'mode': mode, 'source_path': str(FIELDS / 'produce.py'),
                       'replacements': replacements, 'complete_program': transformed})
    for suffix in ('-fields.json', '-source-node-gaps.json'):
        assert not (BASE / (mode + suffix)).exists(), 'never replace captured current fields'
    exec(compile(transformed, mode + '-complete-field-observer', 'exec'), {'__name__': 'field_observation'})
destination = BASE / 'observer-transforms.json'
assert not destination.exists()
destination.write_text(json.dumps(transforms, sort_keys=True, indent=2) + '\n')
print('Captured all three complete current field observations and exact whole producer transformations.')

"""Display finite original product schemas without interpreting native identities."""
import gzip
import json
from pathlib import Path

ROOT = Path('docs/audits')
native = json.loads((ROOT / 'record-value-original-candidate-20261004/ordinary.json').read_bytes())
for key, value in native.items():
    if isinstance(value, list):
        print(key, 'population', len(value), 'first keys', sorted(value[0]) if value and isinstance(value[0], dict) else None)
    else:
        print(key, 'type', type(value).__name__, 'keys', sorted(value) if isinstance(value, dict) else None)
print('helper zero', native['helpers'][0])
print('test run', native['test_run'])
primary = json.loads((ROOT / 'record-value-original-primary-20261005/proofs.json').read_bytes())
context = json.loads((ROOT / 'record-value-original-contexts-20261005/proofs.json').read_bytes())
print('primary zero helper', primary['proofs'][0]['helpers'][0])
print('context keys', sorted(context['proofs'][0]))
print('context parse', context['proofs'][0]['parsers'][0])
semantic = json.loads(gzip.decompress((ROOT / 'raw-semantic-links-20261011/candidate.json.gz').read_bytes()))
print('semantic fields', sorted(semantic))
print('semantic links fields', sorted(semantic['semantic_links']))
print('first cause', semantic['semantic_links']['records'][0]['first_cause'])
print('first context', semantic['semantic_links']['records'][0]['context'])
for mode in semantic['modes']:
    print('mode domain allocation', mode['mode'], {key: dict(population=value['population'], empty=len(value['empty_string_members']), nonempty=len(value['records'])) for key, value in mode['domains'].items()})

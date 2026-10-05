"""Test coordinated corruption against the first retained native qualifier."""
import copy
import hashlib
import importlib.util
import json
from pathlib import Path

BASE = Path('docs/audits/book-reference-publication-20261005')
spec = importlib.util.spec_from_file_location('first_click_qualifier', BASE / 'verify.py')
reader = importlib.util.module_from_spec(spec)
spec.loader.exec_module(reader)
record = json.loads((BASE / 'native.json').read_text())
rows = json.loads(reader.SELECTION.read_text())['routes']
old = json.loads(reader.CLASSIFICATION.read_text())
reader.qualify(record, rows, old)
candidate = copy.deepcopy(record)
source = rows[0]['source']
path = '/' + rows[0]['asset']
body = candidate['source_boundary'][source] + 'coordinated wrong canonical source\n'
candidate['source_boundary'][source] = candidate['built_assets'][source] = body
candidate['responses'][path].update(body=body, bytes=len(body.encode()), sha256=hashlib.sha256(body.encode()).hexdigest())
target = BASE / 'initial-shared-source-candidate.json'
assert not target.exists()
target.write_text(json.dumps(candidate, sort_keys=True, indent=2) + '\n')
reader.qualify(candidate, rows, old)
(BASE / 'initial-shared-source-result.json').write_text(json.dumps({
    'status': 0, 'source': source, 'path': path,
    'outcome': 'First qualifier falsely accepts coordinated canonical/built/served corruption.'}, sort_keys=True, indent=2) + '\n')
print('REPRODUCED first qualifier false green for coordinated source/built/served corruption.')

"""Authenticate finite native observations without claiming graph qualification."""
import hashlib
import json
from pathlib import Path

BASE = Path('docs/audits/record-value-copy-probes-20261004')


def identity(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


if (BASE / 'manifest.json').exists():
    manifest = json.loads((BASE / 'manifest.json').read_text())
    assert {p.name for p in BASE.iterdir()} == set(manifest) | {'manifest.json'}
    for name, row in manifest.items():
        assert identity((BASE / name).read_bytes()) == row, name
source = Path('docs/audits/record-value-copy-inputs-20261004')
prior_manifest = json.loads((source / 'manifest.json').read_text())
assert {p.name for p in source.iterdir()} == set(prior_manifest) | {'manifest.json'}
for name, row in prior_manifest.items():
    assert identity((source / name).read_bytes()) == row
transform = json.loads((BASE / 'recipe-transform.json').read_text())
recipes = json.loads((source / 'recipes.json').read_text())
assert transform['names'] == [row['name'] for row in recipes]
assert transform['before'] == ''.join(row['body'] for row in recipes)
body = transform['before']
for before, after in transform['replacements']:
    assert body.count(before) == 1
    body = body.replace(before, after)
assert body == transform['after']
assert (BASE / 'candidate.pl').read_text() == transform['prefix'] + body + transform['suffix']
expected_failures = {
    'ordinary': [],
    'storable': ['tree copy preserves kinds and sharing'],
    'alias': ['shared copy is isolated from source'],
    'split-sharing': ['shared copy preserves kinds and sharing', 'shared copy preserves reference population'],
    'cycle-alias': ['hash-cycle copy preserves kinds and sharing', 'hash-cycle copy preserves reference population', 'hash-cycle copy is isolated from source'],
    'mutate-input': ['tree copy preserves original kinds and sharing'],
    'numeric-result': ['tree copy preserves kinds and sharing'],
}
receipts = json.loads((BASE / 'native-receipts.json').read_text())
assert [row['command'][2] for row in receipts] == list(expected_failures)
host = None
for receipt in receipts:
    mode = receipt['command'][2]
    assert receipt['command'] == ['perl', str(BASE / 'probe.pl'), mode, str(BASE / (mode + '.json'))]
    assert receipt['working_directory'] == '.'
    assert receipt['programs'] == {name: identity((BASE / name).read_bytes()) for name in ('probe.pl', 'candidate.pl')}
    record = json.loads((BASE / (mode + '.json')).read_text())
    assert record['mode'] == mode
    assert [row['name'] for row in record['cases']] == ['null', 'number', 'string', 'empty-array', 'tree', 'shared', 'hash-cycle', 'array-cycle']
    assert len(record['assertions']) == 32 and len(record['native']) == 4
    failed = [row['label'] for row in record['assertions'] if not row['passed']]
    assert failed == expected_failures[mode] and receipt['status'] == len(failed)
    assert receipt['output'].count('not ok ') == len(failed) and '\n1..36\n' in receipt['output']
    host = record['host'] if host is None else host
    assert record['host'] == host
    for row in record['native']:
        assert row['accepted'] == 0 and row['before'] == row['after']
        assert row['before']['class'] in ('CoverageCauseSentinel', 'CopyProbeNativeSentinel')
        assert row['before']['reftype'] == 'HASH' and row['before']['keys'] == []
        expected = 'unexpected source reference' if row['operation'] == 'copy' else 'unexpected native snapshot reference'
        assert row['error'].startswith(expected)
print('PASS exact finite native capture/recipe/TAP/status/program membership; ordinary36 and six intended bad-provider failures retained. Independent whole joint-graph/source/kind/topology/detachment validation and fresh durability reexecution are explicitly pending.')

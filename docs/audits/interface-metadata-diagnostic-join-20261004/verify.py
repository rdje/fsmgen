"""Independent complete committed-source/semantic diagnostic repair join."""
import argparse
import hashlib
import json
import subprocess
from pathlib import Path
BASE = Path(__file__).parent
parser = argparse.ArgumentParser()
parser.add_argument('--omit-cause', action='store_true')
parser.add_argument('--omit-context', action='store_true')
parser.add_argument('--trust-control', action='store_true')
parser.add_argument('--coerce-product-kind', action='store_true')
args = parser.parse_args()
def equal(a, b):
    if type(a) is not type(b):
        return False
    if isinstance(a, dict):
        return a.keys() == b.keys() and all(equal(a[k], b[k]) for k in a)
    if isinstance(a, list):
        return len(a) == len(b) and all(equal(x, y) for x, y in zip(a, b))
    return a == b
for path in ('interface-metadata-cause-repair-20261004', 'interface-metadata-writer-cause-repair-20261004'):
    subprocess.run(['python3', '-B', 'docs/audits/' + path + '/verify.py'], check=True)
if (BASE / 'manifest.json').exists():
    manifest = json.loads((BASE / 'manifest.json').read_text())
    assert {p.name for p in BASE.iterdir()} == set(manifest) | {'manifest.json'}
    for name, row in manifest.items():
        raw = (BASE / name).read_bytes()
        assert len(raw) == row['bytes'] and hashlib.sha256(raw).hexdigest() == row['sha256']
binding = json.loads((BASE / 'binding.json').read_text())
task = subprocess.check_output(['git', 'show', binding['revision'] + ':docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md']).decode()
for owner, body in binding['owners'].items():
    start = task.index('- ID: `' + owner + '`')
    assert task[start:task.index('\n- ID:', start)] == body and 'Status: `done`' in body
assert len(binding['owners']) == 2 and len(binding['sources']) == 16
for name, row in binding['sources'].items():
    raw = subprocess.check_output(['git', 'show', binding['revision'] + ':' + name])
    assert raw.decode() == row['body'] and len(raw) == row['bytes'] and hashlib.sha256(raw).hexdigest() == row['sha256']
    # Current selected source authority, without requiring HEAD itself to stay
    # fixed after this documentation-only join commits.
    assert Path(name).read_bytes() == raw
joined = json.loads((BASE / 'join.json').read_text())
if args.coerce_product_kind:
    port = joined['writer']['ordinary']['api'][0]['result'][1][0][1]
    assert type(port['width']) is int
    port['width'] = str(port['width'])
for role, name in [('metadata', 'interface-metadata-cause-repair-20261004'),
                   ('writer', 'interface-metadata-writer-cause-repair-20261004')]:
    parent = Path('docs/audits') / name
    for kind in ('ordinary', 'bypass', 'context-native', 'sources-after', 'manifest'):
        assert equal(joined[role][kind], json.loads((parent / (kind + '.json')).read_text())), 'complete typed native population identity'
assert joined['writer']['sources-after'] == {name: row['body'] for name, row in binding['sources'].items()}
assert equal(joined['writer']['source-models'], json.loads(Path('docs/audits/interface-metadata-writer-cause-repair-20261004/source-models.json').read_text()))
assert joined['expected-causes'] == json.loads(Path('docs/audits/interface-metadata-runtime-20261004/expected-causes.json').read_text())
metadata, writer = joined['metadata'], joined['writer']
assert all(r['passed'] for role in (metadata, writer) for r in role['ordinary']['consumers'])
for role, count in ((metadata, 46), (writer, 47)):
    rows = role['ordinary']['cause_consumers'][:-1] if args.omit_cause else role['ordinary']['cause_consumers']
    assert len(rows) == count, 'complete helper/first-read/writer intended cause membership'
    helpers = [r for r in rows if r['helper'] is not None]
    assert [r['helper'] for r in helpers] == list(range(44))
    for r, reason in zip(helpers, joined['expected-causes']['snapshot'] + joined['expected-causes']['capture']):
        assert r['expected'] == 'Invalid ISF interface port metadata: ' + reason
        assert r['error'].splitlines()[0] == r['expected'] and r['matched'] == 1
    assert len(role['ordinary']['api']) == 105 and len(role['ordinary']['copies']) == 144 and len(role['ordinary']['consumers']) == 336
    cycle = role['ordinary']['cycles'][0]
    assert len(role['ordinary']['cycles']) == 1 and equal(cycle['before'], cycle['after']) and equal(cycle['before'], cycle['copy'])
    assert cycle['original_reference_count'] == cycle['copy_reference_count'] == 7 and cycle['shared_with_original'] == 0
contexts = metadata['context-native']['runs'][:-1] if args.omit_context else metadata['context-native']['runs']
assert len(contexts) == 2, 'complete ordinary/wanted-provider native context membership'
assert [r['mode'] for r in contexts] == ['ordinary', 'location_echo']
assert len(writer['context-native']['rows']) == 4
for role, changed, failure_labels in ((metadata, 2, ['malformed snapshot 5 fails closed', 'contextual bounded diagnostic', 'malformed snapshot 27 fails closed', 'contextual bounded diagnostic']),
                                    (writer, 1, ['record output field writer remains deferred', 'existing authored-field refusal remains precise'])):
    assert role['bypass']['changed'] == changed
    failures = [r for r in role['bypass']['consumers'] if not r['passed']]
    assert [r['label'] for r in failures] == failure_labels
    accepted = bool(failures)
    if args.trust_control:
        accepted = all(r['passed'] for r in role['bypass']['consumers'])
    assert accepted, 'actual producer bypass cannot qualify passing cause/refusal assurance'
# Child readers independently require every complete ordinary source/copy/API/
# product/parser/consumer/caller/kind and actual control/private field role;
# their exact semantic proofs, not their PASS text, are part of the join above.
print('PASS complete committed16-source/two-owner diagnostic join: all31/13 helper, two first-read and complete writer causes; exact native location/caller/argument/four parser contexts and genuine bypass controls join full source/copy/field/product/kind/caller/cycle/consumer authority. Both contextual defects close; final T1983 outcome and wider cold/native/HDL remain separately owned.')

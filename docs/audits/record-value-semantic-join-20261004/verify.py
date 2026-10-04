"""Independent whole clone-root source/context/raw-preparation reader."""
import argparse
import copy
import hashlib
import json
import re
import subprocess
from collections import Counter
from pathlib import Path
from source_roots import graph, thaw, exact, digest, read, scope_model

BASE = Path('docs/audits/record-value-semantic-join-20261004')
parser = argparse.ArgumentParser()
for flag in ('omit-field', 'omit-product', 'wrong-source', 'wrong-field', 'wrong-helper', 'omit-consumer', 'wrong-consumer-owner', 'alias-authority', 'wrong-ledger'):
    parser.add_argument('--' + flag, action='store_true')
args = parser.parse_args()


def identity(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def sealed(directory):
    manifest = json.loads((directory / 'manifest.json').read_text())
    assert {path.name for path in directory.iterdir()} == set(manifest) | {'manifest.json'}
    for name, row in manifest.items():
        assert identity((directory / name).read_bytes()) == row, str(directory / name)


if (BASE / 'manifest.json').exists():
    sealed(BASE)
binding = json.loads((BASE / 'binding.json').read_text())
assert binding['revision'] == 'cf3e7830204a42ff7370f86dd8fa54d01287c7c4' and len(binding['sources']) == 21
mutable = {'docs/knowledge/isf-aggregate-port-request-baseline.md', 'docs/book/src/13k-isf-feature-support-matrix.md'}
for path, row in binding['sources'].items():
    raw = subprocess.check_output(['git', 'show', binding['revision'] + ':' + path])
    assert identity(raw) == {'bytes': row['bytes'], 'sha256': row['sha256']} and raw.decode() == row['body']
    if path not in mutable:
        assert raw == Path(path).read_bytes(), 'current selected source drift: ' + path
if (BASE / 'doc-updates.json').exists():
    updates = json.loads((BASE / 'doc-updates.json').read_text())
    assert {row['path'] for row in updates} == mutable
    for row in updates:
        assert row['before'] == binding['sources'][row['path']]['body']
        text = row['before']
        for before, after in row['replacements']:
            assert text.count(before) == 1
            text = text.replace(before, after)
        assert text == row['after'] == Path(row['path']).read_text()
else:
    assert all(Path(path).read_text() == binding['sources'][path]['body'] for path in mutable)
for name in ('runtime', 'fields', 'copy-fields', 'field-join', 'actors', 'replay-portability', 'scopes', 'references', 'copies', 'api-join', 'captures', 'snapshots', 'ranges', 'structured-clones', 'clones', 'clone-roots', 'clone-paths', 'clone-root', 'clone-tree', 'clone-join', 'identities', 'core-join', 'products'):
    directory = Path('docs/audits/record-value-' + name + '-20261004')
    sealed(directory)
    prior = json.loads((directory / ('join.json' if name == 'field-join' else 'binding.json')).read_text())
    for path, row in prior['sources'].items():
        if path not in mutable:
            assert row['body'] == binding['sources'][path]['body']
task_path = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
owners = json.loads((BASE / 'owners.json').read_text())
assert len(owners) == 27
for owner in owners:
    for task in (subprocess.check_output(['git', 'show', binding['revision'] + ':' + task_path]).decode(), Path(task_path).read_text()):
        start = task.index('- ID: `' + owner['owner'] + '`'); end = task.index('\n- ID:', start + 1)
        assert task[start:end] == owner['node'] and 'Status: `done`' in owner['node']

sealed(Path('docs/audits/record-value-semantics-20261004'))
transforms = json.loads((BASE / 'source-transform.json').read_text())
for name, row in transforms.items():
    assert Path(row['source']).read_text() == row['before']
    assert (BASE / name).read_text() == row['after'], 'exact full superseding source/native ledger transform'
for name in ('binding.json', 'owners.json', 'semantics.json', 'semantic-replays.json'):
    assert (BASE / name).read_bytes() == Path('docs/audits/record-value-semantics-20261004', name).read_bytes()

previous = Path('docs/audits/record-value-products-20261004')
prefix = json.loads((BASE / 'reader-prefix.json').read_text())
assert prefix['before'] == (previous / 'verify.py').read_text().split('\nprevious = Path(', 1)[0]
expected_prefix = prefix['before'].replace('record-value-products-20261004', 'record-value-semantic-join-20261004').replace("('omit-actor', 'omit-call', 'same-model', 'wrong-family', 'omit-private', 'numeric-product', 'trust-private-actor', 'wrong-parse')", "('omit-field', 'omit-product', 'wrong-source', 'wrong-field', 'wrong-helper', 'omit-consumer', 'wrong-consumer-owner', 'alias-authority', 'wrong-ledger')").replace('bddc62876343529bc5a02de4265381070ed42081', binding['revision']).replace("'identities', 'core-join')", "'identities', 'core-join', 'products')").replace('len(owners) == 19', 'len(owners) == 27')
assert prefix['after'] == expected_prefix and (BASE / 'verify.py').read_text().startswith(prefix['after'])
assert (BASE / 'source_roots.py').read_bytes() == (previous / 'source_roots.py').read_bytes()
assert (BASE / 'native.py').read_bytes() == Path('docs/audits/record-value-clones-20261004/native.py').read_bytes()
from native import check_joint, conserved

native = read('runtime', 'ordinary.json')
data = copy.deepcopy(json.loads((BASE / 'semantics.json').read_text()))
source = binding['sources']['t/1986-isf-record-port-value-gates.t']['body'].splitlines()
fields = read('copy-fields', 'fields.json')['rows']
field_join = read('field-join', 'join.json')['copies']
products = read('products', 'products.json')
source_models = data['source_models']
if args.wrong_source:
    assert source_models['source']['roots']['authored:frame']['members']['data']['signed'] == 0
    source_models['source']['roots']['authored:frame']['members']['data']['signed'] = 1
assert exact(source_models['authored'], read('fields', 'authored-models.json'))
assert exact(source_models['source'], read('copy-fields', 'source-models.json')), 'whole independently qualified source root/node/property/kind domain retains'
for name, spec in source_models['authored']['types'].items():
    assert exact(spec, source_models['source']['roots']['authored:' + name])
assert exact(source_models['authored']['imported']['shared.frame'], source_models['source']['roots']['imported:shared.frame'])
assert exact(source_models['authored']['scalar'], source_models['source']['roots']['source:scalar'])
if args.omit_product:
    data['products']['apis'].pop()
assert exact(data['products'], products), 'complete whole source-modeled actor/API/private/context product join retains'
assert len(products['actors']) == 4 and len(products['apis']) == 9283 and len(products['private']) == 680

helpers = data['helpers']
assert [row['index'] for row in helpers] == list(range(len(native['helpers'])))
if args.wrong_helper:
    assert helpers[0]['spans']['api'] != helpers[1]['spans']['api']
    helpers[0]['spans']['api'], helpers[1]['spans']['api'] = helpers[1]['spans']['api'], helpers[0]['spans']['api']
for index, row in enumerate(helpers):
    actual = native['helpers'][index]
    assert exact(row['whole_native'], actual)
    assert actual['caller'][:2] == ['main', './t/1986-isf-record-port-value-gates.t']
    assert row['source_line'] == source[actual['caller'][2] - 1]
    spans = {}
    for section, key in (('api', 'api'), ('consumers', 'consumer'), ('parses', 'parse')):
        start, end = actual[key + '_start'], actual[key + '_end']
        assert 0 <= start <= end <= len(native[section])
        spans[section] = list(range(start, end))
        assert all(native[section][i]['helper'] == index for i in spans[section])
        assert spans[section] == [i for i, item in enumerate(native[section]) if item['helper'] == index]
    assert exact(row['spans'], spans), 'exact source helper callback/consumer/parse span allocation'
    assert row['copies'] == [i for i, item in enumerate(native['copies']) if item['helper'] == index]
    assert set(row) == {'index', 'whole_native', 'source_line', 'spans', 'copies'}

consumers = data['consumers']
if args.omit_consumer:
    consumers.pop()
assert [row['index'] for row in consumers] == list(range(len(native['consumers']))), 'complete original consumer observation/source membership'
if args.wrong_consumer_owner:
    row = next(row for row in consumers if row['whole_native']['helper'] == 0)
    row['helper_model'] = digest(helpers[1])
for index, row in enumerate(consumers):
    actual = native['consumers'][index]
    assert exact(row['whole_native'], actual)
    assert actual['caller'][:2] == ['main', './t/1986-isf-record-port-value-gates.t']
    assert row['source_line'] == source[actual['caller'][2] - 1] and actual['passed'] == 1
    helper = actual['helper']
    if helper is None:
        assert row['helper_model'] is None
    else:
        assert index in helpers[helper]['spans']['consumers']
        assert row['helper_model'] == digest(helpers[helper]), 'exact source helper owner for complete consumer observation'
    assert set(row) == {'index', 'whole_native', 'source_line', 'helper_model'}
assert Counter(row['whole_native']['kind'] for row in consumers) == {'is': 24, 'is_deeply': 4, 'ok': 52, 'like': 44, 'unlike': 1}

copies = data['copies']
if args.omit_field:
    copies.pop()
assert [row['index'] for row in copies] == list(range(len(native['copies']))) == list(range(len(fields))), 'complete original copied graph/field/source membership'
if args.wrong_field:
    copies[0]['whole_field'], copies[1]['whole_field'] = copies[1]['whole_field'], copies[0]['whole_field']
private = {row['index']: row for row in products['private']}
for index, row in enumerate(copies):
    actual = native['copies'][index]
    assert exact(row['whole_native'], actual)
    assert exact(row['whole_field'], fields[index]) and exact(row['completed_field_join'], field_join[index]), 'each original source field/model is allocated to its own whole native copy'
    assert exact(row['private_product'], private.get(index))
    assert (index in private) == (actual['kind'] in ('value-private', 'metadata-private'))
    helper, parse, api = actual['helper'], actual['parse'], actual['api']
    if helper is None:
        assert row['helper_model'] is None
    else:
        assert index in helpers[helper]['copies'] and row['helper_model'] == digest(helpers[helper])
    if parse is None:
        assert row['parse_product'] is None
    else:
        assert row['parse_product'] == digest(products['actors'][parse])
    if api is not None:
        assert products['apis'][api]['index'] == api
        assert index in products['apis'][api]['private_indices']
    assert set(row) == {'index', 'whole_native', 'whole_field', 'completed_field_join', 'private_product', 'helper_model', 'parse_product'}
assert len(copies) == 697 and len(helpers) == 43 and len(consumers) == 125
for boundary in ('before', 'after'):
    assert sum(len(row['whole_field'][boundary]) for row in copies) == 2540
assert data['native_host'] == native['host'] and data['native_warnings'] == native['warnings'] == []

ordinary = read('clones', 'ordinary-reexecuted.json')
referents = read('clones', 'referents.json')
assert data['qualified_joint_native'] == digest(ordinary) and exact(data['qualified_referents'], referents)
qualified = ordinary
if args.alias_authority:
    qualified = read('clones', 'alias-result-reexecuted.json')
    assert len(qualified['consumers']) == 125 and all(row['passed'] == 1 for row in qualified['consumers'])
    assert all(exact({key: value for key, value in row.items() if key not in {'joint_input_result', 'input_reference_count', 'result_reference_count', 'shared_with_input'}}, {key: value for key, value in other.items() if key not in {'joint_input_result', 'input_reference_count', 'result_reference_count', 'shared_with_input'}}) for row, other in zip(qualified['api'], ordinary['api']) if row['kind'] == 'structured-clone')
clones = [(i, row) for i, row in enumerate(qualified['api']) if row['kind'] == 'structured-clone']
assert len(clones) == 8251
joints = []
for index, row in clones:
    rebuilt = check_joint(row)
    joints.append({'index': index, **rebuilt})
assert sum(row['container'] for row in joints) == 2628
assert exact(joints, referents['ordinary'])
reexecuted_ledger = read('clones', 'legacy-conservation.json') if args.wrong_ledger else json.loads((BASE / 'reexecuted-conservation.json').read_text())
assert exact(conserved(native, ordinary, True), reexecuted_ledger), 'whole reexecuted native capture retains its own full raw difference ledger'
assert exact(conserved(native, read('structured-clones', 'ordinary.json'), True), read('clones', 'legacy-conservation.json')), 'whole original joint capture retains its own full raw difference ledger'
if (BASE / 'controls.json').exists() and not any(vars(args).values()):
    controls = json.loads((BASE / 'controls.json').read_text())
    assert [row['command'][-1] for row in controls] == ['--' + flag for flag in ('omit-field', 'omit-product', 'wrong-source', 'wrong-field', 'wrong-helper', 'omit-consumer', 'wrong-consumer-owner', 'alias-authority', 'wrong-ledger')]
    for row in controls:
        assert row['command'][:3] == ['python3', '-B', str(BASE / 'verify.py')] and row['working_directory'] == '.' and row['status'] == 1
        assert row['output'].rstrip().endswith('AssertionError: ' + row['expected_failure'])
run = subprocess.run(['python3', '-B', str(BASE / 'replay_semantics.py'), '--check'], text=True, capture_output=True)
assert run.returncode == 0, run.stdout + run.stderr
print('PASS complete original source/field/product/native relationship semantics: 697 copies/9283 APIs/four parses/43 helpers/125 raw consumer observations and all8251 joint clone records retain own source, role, kind, caller, model and allocation. Complete dated field/source/product/native proofs and genuine controls reexecute. Only semantic parent closes; legacy consumer flags/helper regexes do not qualify permanent baseline, detachment-test or host-native intended-cause assurance.')

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

BASE = Path('docs/audits/record-value-products-20261004')
parser = argparse.ArgumentParser()
for flag in ('omit-actor', 'omit-call', 'same-model', 'wrong-family', 'omit-private', 'numeric-product', 'trust-private-actor', 'wrong-parse'):
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
assert binding['revision'] == 'bddc62876343529bc5a02de4265381070ed42081' and len(binding['sources']) == 21
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
for name in ('runtime', 'fields', 'copy-fields', 'field-join', 'actors', 'replay-portability', 'scopes', 'references', 'copies', 'api-join', 'captures', 'snapshots', 'ranges', 'structured-clones', 'clones', 'clone-roots', 'clone-paths', 'clone-root', 'clone-tree', 'clone-join', 'identities', 'core-join'):
    directory = Path('docs/audits/record-value-' + name + '-20261004')
    sealed(directory)
    prior = json.loads((directory / ('join.json' if name == 'field-join' else 'binding.json')).read_text())
    for path, row in prior['sources'].items():
        if path not in mutable:
            assert row['body'] == binding['sources'][path]['body']
task_path = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
owners = json.loads((BASE / 'owners.json').read_text())
assert len(owners) == 19
for owner in owners:
    for task in (subprocess.check_output(['git', 'show', binding['revision'] + ':' + task_path]).decode(), Path(task_path).read_text()):
        start = task.index('- ID: `' + owner['owner'] + '`'); end = task.index('\n- ID:', start + 1)
        assert task[start:end] == owner['node'] and 'Status: `done`' in owner['node']

previous = Path('docs/audits/record-value-core-join-20261004')
prefix = json.loads((BASE / 'reader-prefix.json').read_text())
assert prefix['before'] == (previous / 'verify.py').read_text().split('\nprevious = Path(', 1)[0]
expected_prefix = prefix['before'].replace('record-value-core-join-20261004', 'record-value-products-20261004').replace("('omit-call', 'same-model', 'wrong-family', 'numeric-product', 'omit-private')", "('omit-actor', 'omit-call', 'same-model', 'wrong-family', 'omit-private', 'numeric-product', 'trust-private-actor', 'wrong-parse')").replace('3b00150fd1d4899144b18aac1daf930616a2b744', binding['revision']).replace("'clone-join', 'identities')", "'clone-join', 'identities', 'core-join')").replace('len(owners) == 14', 'len(owners) == 19')
assert prefix['after'] == expected_prefix and (BASE / 'verify.py').read_text().startswith(prefix['after'])
for name in ('source_roots.py', 'core_models.py'):
    assert (BASE / name).read_bytes() == (previous / name).read_bytes()
native = read('runtime', 'ordinary.json')
data = copy.deepcopy(json.loads((BASE / 'products.json').read_text()))
actors, rows, private = data['actors'], data['apis'], data['private']
source_actors = read('actors', 'actor-models.json')
raw_parses = read('actors', 'parses.json')['rows']
if args.omit_actor:
    actors.pop()
assert [row['index'] for row in actors] == list(range(len(native['parses']))) == [0, 1, 2, 3], 'complete original actor/parse product membership'
if args.trust_private_actor:
    candidate = native['copies'][80]
    assert candidate['kind'] == 'test' and candidate['caller'][2] == 122
    actors[0]['expected_product'] = candidate['copy']
for index, row in enumerate(actors):
    actual = native['parses'][index]
    assert exact(actual, raw_parses[index]) and exact(row['whole_native'], actual)
    name = ('local', 'imported')[index] if index < 2 else None
    expected_source = source_actors['sources'][name] if name else source_actors['refused_sources'][index - 2]
    expected_actor = source_actors['actors'][name] if name else None
    expected_product = graph(expected_actor)
    assert row['source'] == expected_source == actual['before'][1][0]
    assert exact(row['source_actor'], expected_actor)
    assert exact(row['expected_product'], expected_product) and exact(expected_product, actual['result']), 'whole source actor product with original primitive kinds, not private-copy authority'
    assert actual['accepted'] == int(index < 2) and exact(actual['before'], actual['after'])
    assert set(row) == {'index', 'source', 'source_actor', 'expected_product', 'whole_native'}

specifications = {
    'scope': ('scopes', 'scope-products.json'),
    'reference': ('references', 'reference-products.json'),
    'copy': ('copies', 'copy-products.json'),
    'capture': ('captures', 'capture-products.json'),
    'snapshot': ('snapshots', 'snapshot-products.json'),
    'range': ('ranges', 'range-products.json'),
    'structured-clone': ('clone-join', 'join-products.json'),
    'identity': ('identities', 'identity-products.json'),
    'payload': ('identities', 'identity-products.json'),
}
models = {}
for family, filename in set(specifications.values()):
    children = read(family, filename)['rows']
    models[family] = {row['index']: row for row in children}
    assert len(models[family]) == len(children)
assert sorted(index for family in models.values() for index in family) == list(range(len(native['api'])))
if args.omit_call:
    rows.pop()
assert [row['index'] for row in rows] == list(range(len(native['api']))), 'complete original actor/value/core API product membership'
if args.same_model:
    seen = {}
    for row in rows:
        key = (row['family'], json.dumps(row['whole_native'], sort_keys=True, separators=(',', ':')))
        if key in seen:
            first = seen[key]
            for field in ('source_index', 'whole_source_model', 'whole_completed_join'):
                first[field], row[field] = row[field], first[field]
            break
        seen[key] = row
    else:
        raise AssertionError('actual identical whole native records required')
    assert sorted(row['source_index'] for row in rows) == list(range(len(native['api'])))
if args.wrong_family:
    rows[0]['family'] = 'scopes'
if args.omit_private:
    private.pop()
if args.numeric_product:
    first = rows[0]['expected_product'][1][0][1]
    assert type(first['width']) is int
    first['width'] = str(first['width'])
if args.wrong_parse:
    first = next(row for row in rows if row['parse_link'] is not None)
    assert first['parse_link']['index'] != 3 and native['parses'][3]['api_start'] == native['parses'][3]['api_end']
    first['parse_link'] = {'index': 3, 'whole_source_parse': digest(actors[3]), 'bounds': [native['parses'][3]['api_start'], native['parses'][3]['api_end']]}

value_join = {row['index']: row for row in read('api-join', 'join.json')['apis']}
core_join = {row['index']: row for row in read('core-join', 'core-products.json')['rows']}
assert sorted(value_join) == [i for i, row in enumerate(native['api']) if row['kind'] in ('scope', 'reference', 'copy')]
assert sorted(core_join) == [i for i, row in enumerate(native['api']) if row['kind'] not in ('scope', 'reference', 'copy')]
expected_private, parse_links = {}, []
for row in rows:
    index = row['index']; actual = native['api'][index]; kind = actual['kind']; family, _ = specifications[kind]
    assert row['kind'] == kind and row['family'] == family, 'exact original API source family and operation role'
    model = models[family][index]
    completed = value_join[index] if index in value_join else core_join[index]
    assert row['source_index'] == index and row['whole_source_model'] == digest(model) and row['whole_completed_join'] == digest(completed), 'exact own source/completed join allocation despite identical native values'
    assert exact(row['whole_native'], actual), 'complete native caller/context/input/output/error observation retains'
    if kind in ('scope', 'reference', 'copy', 'capture', 'snapshot', 'range'):
        assert exact(model['original'], actual)
        expected = model['meaning']['product'] if kind == 'copy' else model['expected_product']
    elif kind == 'structured-clone':
        expected = model['source_product']['result']
        assert exact(model['source_product'], actual)
    else:
        expected = model['expected_result']
        assert exact(model['expected_arguments'], actual['before']) and exact(model['expected_arguments'], actual['after'])
    assert exact(row['expected_product'], expected) and exact(expected, actual['result']), 'complete original source-modeled API product primitive kinds'
    if kind in ('scope', 'copy'):
        expected_links = {'recipe': model['recipe']}
        stages = model['private'] if kind == 'scope' else [stage['copy'] for stage in model['private_stages']]
    elif kind == 'reference':
        expected_links = {key: model[key] for key in ('source_call', 'source_scope_matches', 'type_stage', 'operation_span')}
        stages = model['private_root_copies']
    else:
        expected_links = core_join[index]['links']
        stages = [model['private']] if kind in ('capture', 'snapshot') else []
    assert exact(row['source_links'], expected_links), 'whole source/private/handoff/stage links retain'
    assert row['private_indices'] == [stage['index'] for stage in stages]
    for stage in stages:
        assert stage['api'] == index and stage['index'] not in expected_private
        expected_private[stage['index']] = (index, family, stage)
    parse_index = actual['parse']
    if parse_index is None:
        assert row['parse_link'] is None
    else:
        parse = native['parses'][parse_index]
        expected_link = {'index': parse_index, 'whole_source_parse': digest(actors[parse_index]), 'bounds': [parse['api_start'], parse['api_end']]}
        assert parse['api_start'] <= index < parse['api_end']
        assert exact(row['parse_link'], expected_link), 'exact source parse/outcome/bounds allocation for every nested API'
        parse_links.append(index)
    assert set(row) == {'index', 'kind', 'family', 'source_index', 'whole_source_model', 'whole_completed_join', 'whole_native', 'expected_product', 'source_links', 'private_indices', 'parse_link'}

indices = [i for i, row in enumerate(native['copies']) if row['kind'] in ('value-private', 'metadata-private')]
assert [row['index'] for row in private] == sorted(expected_private) == indices, 'complete original own private clone/field product membership'
fields = read('copy-fields', 'fields.json')['rows']
for row in private:
    index = row['index']; api, family, stage = expected_private[index]; actual = native['copies'][index]
    assert row['api'] == api and row['family'] == family and exact(row['whole_model'], stage)
    assert exact({key: value for key, value in stage.items() if key != 'index'}, actual)
    assert exact(row['whole_native'], actual) and exact(row['whole_field'], fields[index])
    assert fields[index]['index'] == index and fields[index]['api_index'] == api and actual['api'] == api and actual['shared_with_original'] == 0
    assert set(row) == {'index', 'api', 'family', 'whole_model', 'whole_native', 'whole_field'}
assert Counter(row['kind'] for row in rows) == {'scope': 40, 'reference': 68, 'copy': 22, 'capture': 227, 'snapshot': 220, 'range': 437, 'structured-clone': 8251, 'identity': 14, 'payload': 4}
assert len(rows) == 9283 and len(value_join) == 130 and len(core_join) == 9153 and len(private) == 680
assert Counter(row['whole_native']['kind'] for row in private) == {'value-private': 233, 'metadata-private': 447}
assert sorted(parse_links) == sorted(i for parse in native['parses'] for i in range(parse['api_start'], parse['api_end']))
if (BASE / 'controls.json').exists() and not any(vars(args).values()):
    controls = json.loads((BASE / 'controls.json').read_text())
    assert [row['command'][-1] for row in controls] == ['--' + flag for flag in ('omit-actor', 'omit-call', 'same-model', 'wrong-family', 'omit-private', 'numeric-product', 'trust-private-actor', 'wrong-parse')]
    for row in controls:
        assert row['command'][:3] == ['python3', '-B', str(BASE / 'verify.py')] and row['status'] == 1 and row['working_directory'] == '.'
        assert row['output'].rstrip().endswith('AssertionError: ' + row['expected_failure'])
run = subprocess.run(['python3', '-B', str(BASE / 'replay_products.py'), '--check'], text=True, capture_output=True)
assert run.returncode == 0, run.stdout + run.stderr
print('PASS all four original actor outcomes/9283 API products and 680 own private clone/full-field source/native/model/context joins. Every completed actor/value/core owner, exact source assignment, primitive product kind and nested parse boundary retain; reached omission/identical-native allocation/role/private/kind/private-actor/parse controls reject. Complete dated actor/value/core ordinary/RED/native proofs reexecute. Only product parent closes before semantic/helper/permanent consumer/full native cause assurance.')

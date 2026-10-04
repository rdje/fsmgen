"""Independent full original/pure/control stream and source-model reader."""
import argparse
import hashlib
import json
import re
import subprocess
from pathlib import Path

BASE = Path(__file__).parent
parser = argparse.ArgumentParser()
parser.add_argument('--trust-kind', action='store_true')
parser.add_argument('--trust-alias', action='store_true')
parser.add_argument('--trust-projection', action='store_true')
parser.add_argument('--omit-copy', action='store_true')
args = parser.parse_args()
subprocess.run(['python3', '-B', 'docs/audits/interface-metadata-fields-20261004/verify.py'], check=True)
binding = json.loads((BASE / 'binding.json').read_text())
for name, row in binding['sources'].items():
    raw = subprocess.check_output(['git', 'show', binding['revision'] + ':' + name])
    assert raw.decode() == row['body'] and len(raw) == row['bytes'] and hashlib.sha256(raw).hexdigest() == row['sha256']
fields = json.loads(Path('docs/audits/interface-metadata-fields-20261004/fields.json').read_text())
assert set(binding['sources']) == set(fields['sources']) | {'t/1959-isf-prepared-formal-reservations.t'}
assert all(binding['sources'][k] == v for k, v in fields['sources'].items())
recipe = binding['sources']['t/1959-isf-prepared-formal-reservations.t']['body']
recipe = recipe[recipe.index('sub source_value_copy {'):recipe.index('sub snapshot_graph {')].replace('source_value_copy', 'pure_copy')
assert recipe == (BASE / 'pure-body.pl').read_text()
observer = (BASE / 'observe.pl').read_text()
assert recipe in observer
if (BASE / 'manifest.json').exists():
    manifest = json.loads((BASE / 'manifest.json').read_text())
    assert {p.name for p in BASE.iterdir()} == set(manifest) | {'manifest.json'}
    for name, row in manifest.items():
        raw = (BASE / name).read_bytes()
        assert len(raw) == row['bytes'] and hashlib.sha256(raw).hexdigest() == row['sha256'], name

def equal(a, b):
    if type(a) is not type(b): return False
    if isinstance(a, dict): return a.keys() == b.keys() and all(equal(a[k], b[k]) for k in a)
    if isinstance(a, list): return len(a) == len(b) and all(equal(x, y) for x, y in zip(a, b))
    return a == b

def delta(a, b, path=''):
    if type(a) is not type(b): return [(path, type(a).__name__, a, type(b).__name__, b)]
    if isinstance(a, dict):
        assert a.keys() == b.keys(), ('shape drift', path)
        return [r for k in a for r in delta(a[k], b[k], path + '/' + k)]
    if isinstance(a, list):
        assert len(a) == len(b), ('array drift', path)
        return [r for i, (x, y) in enumerate(zip(a, b)) for r in delta(x, y, path + '/' + str(i))]
    return [] if a == b else [(path, type(a).__name__, a, type(b).__name__, b)]

def documents(row): return {Path(k).name: v for k, v in row.items()}

prior = json.loads(Path('docs/audits/interface-metadata-fields-20261004/ordinary.json').read_text())
data = {name: json.loads((BASE / (name + '.json')).read_text())
    for name in ('ordinary', 'pure', 'kind', 'pure-kind', 'alias', 'projection')}
ordinary = data['ordinary']; pure = data['pure']
for name, row in data.items():
    assert row['mode'] == name and len(row['api']) == 105 and len(row['copies']) == 145
    assert len(row['helpers']) == 44 and len(row['parses']) == 3 and len(row['consumers']) == 166
    assert row['changed'] == int(name in ('kind', 'pure-kind', 'alias'))
    assert all(c['passed'] for c in row['consumers']) and int((BASE / (name + '.status')).read_text()) == 0
    assert len(re.findall(r'^    ok \d+ ', (BASE / (name + '.txt')).read_text(), re.M)) == 166
    for index, api in enumerate(row['api']):
        reference = ordinary['api'][index]
        assert api['kind'] == reference['kind'] and api['caller'] == reference['caller']
        assert api['accepted'] == reference['accepted'] and api['warnings'] == reference['warnings'] == []
        assert api['error'].splitlines()[:1] == reference['error'].splitlines()[:1]
    for actual, reference in zip(row['parses'], ordinary['parses']):
        assert actual['accepted'] == reference['accepted']
        assert documents(actual['documents_before']) == documents(reference['documents_before'])
        assert actual['documents_before'] == actual['documents_after']
        assert actual['error'].splitlines()[:1] == reference['error'].splitlines()[:1]
        assert actual['kind'] == reference['kind'] and actual['caller'] == reference['caller']
        assert actual['before'] == actual['after']
        for key in ('before', 'after'):
            changes = delta(reference[key], actual[key])
            if actual['kind'] == 'file':
                assert len(changes) in (0, 1)
                for path, ak, av, bk, bv in changes:
                    assert path == '/1/0' and ak == bk == 'str'
                    assert re.fullmatch(r'\$\{REPO_ROOT\}/\.artifacts/tmp/tests/[A-Za-z0-9_]+/imported\.isf', av)
                    assert re.fullmatch(r'\$\{REPO_ROOT\}/\.artifacts/tmp/tests/[A-Za-z0-9_]+/imported\.isf', bv)
            else: assert not changes
        differences = delta(reference['result'], actual['result'])
        if name == 'projection':
            assert all(d[1] == 'int' and d[3] == 'str' and str(d[2]) == d[4]
                and d[0].startswith('/1/interface_port_metadata/') and d[0].endswith('/width') for d in differences)
            assert len(differences) == {'source': 4, 'file': 2}[actual['kind']] if actual['accepted'] else not differences
        else: assert not differences, ('whole parser product', name)
    for actual, reference in zip(row['consumers'], ordinary['consumers']):
        for key in ('kind', 'caller', 'helper', 'label', 'passed'):
            assert actual[key] == reference[key], ('complete consumer identity', name, key)
    cycle = row['cycles'][0]
    assert len(row['cycles']) == 1 and cycle['before'] == cycle['after'] == cycle['copy']
    assert cycle['original_reference_count'] == cycle['copy_reference_count'] == 7 and cycle['shared_with_original'] == 0
    # The graph records a real back-edge to the existing type_spec, not a new
    # serialized duplicate tree or an unsupported native referent.
    encoded = json.dumps(cycle['copy'])
    assert '"reference", "/inputs/0/type_spec"' in encoded

for actual, reference in zip(ordinary['api'], prior['api']):
    for key in ('kind', 'caller', 'helper', 'before', 'after', 'result', 'warnings', 'accepted'):
        assert equal(actual[key], reference[key]), ('exact original API replay', key)
    assert actual['error'].splitlines()[:1] == reference['error'].splitlines()[:1]
assert ordinary['copies'] == prior['copies']
assert sum(r['kind'] == 'test' and r['before'] != r['copy'] for r in ordinary['copies']) == 14
assert sum(len(delta(r['before'], r['copy'])) for r in ordinary['copies'] if r['kind'] == 'test') == 64
copies = pure['copies'][:-1] if args.omit_copy else pure['copies']
assert len(copies) == 145 and sum(r['kind'] == 'test' for r in copies) == 43, 'complete original/pure copy membership'
for index, copied in enumerate(copies):
    previous = ordinary['copies'][index]
    assert copied['kind'] == previous['kind'] and copied['caller'] == previous['caller'] and copied['api'] == previous['api']
    assert copied['before'] == copied['after']
    assert copied['original_reference_count'] == copied['copy_reference_count'] and copied['shared_with_original'] == 0
    if copied['kind'] == 'test': assert copied['before'] == copied['copy']
    else:
        # Private copies may change spellings; that remains intentional.
        assert all(d[1:2] == ('int',) and d[3] == 'str' and str(d[2]) == d[4]
            for d in delta(copied['before'], copied['copy']))
for actual, reference in zip(pure['api'], ordinary['api']):
    assert actual['before'] == actual['after'] and equal(actual['result'], reference['result'])
    changes = delta(reference['before'], actual['before'])
    assert all(d[1] == 'str' and d[3] == 'int' and d[2] == str(d[4]) and d[0].endswith('/width') for d in changes)
assert sum(len(delta(a['before'], b['before'])) for a, b in zip(ordinary['api'], pure['api'])) == 32

def numeric_string_changes(changes):
    return all(d[1] == 'int' and d[3] == 'str' and str(d[2]) == d[4] and d[0].endswith('/width') for d in changes)

for name, reference in (('kind', ordinary), ('pure-kind', pure), ('alias', ordinary), ('projection', ordinary)):
    controlled = data[name]
    for key, expected in (('before', {4, 5}), ('after', {2, 4, 5})):
        changed_indices = set()
        for index, (actual, original) in enumerate(zip(controlled['api'], reference['api'])):
            differences = delta(original[key], actual[key])
            if differences:
                changed_indices.add(index)
                assert name in ('kind', 'pure-kind') and len(differences) == 1 and numeric_string_changes(differences)
                assert differences[0][2:] == (8, 'str', '8')
        assert changed_indices == (expected if name in ('kind', 'pure-kind') else set())
    for key, expected in (('before', {5, 6, 7}), ('after', {5, 6, 7}), ('copy', {5, 6})):
        changed_indices = set()
        for index, (actual, original) in enumerate(zip(controlled['copies'], reference['copies'])):
            for identity in ('kind', 'caller', 'api', 'original_reference_count', 'copy_reference_count'):
                assert actual[identity] == original[identity]
            assert actual['shared_with_original'] == (8 if name == 'alias' and index == 5 else 0)
            differences = delta(original[key], actual[key])
            if differences:
                changed_indices.add(index)
                assert numeric_string_changes(differences)
                if name in ('kind', 'pure-kind'):
                    assert len(differences) == 1 and differences[0][2:] == (8, 'str', '8')
                else:
                    assert name == 'projection' and len(differences) == 4
                    assert all(d[0].startswith('/1/interface_port_metadata/') for d in differences)
        assert changed_indices == (expected if name in ('kind', 'pure-kind') else {2} if name == 'projection' else set())

for name, reference in (('kind', ordinary), ('pure-kind', pure)):
    row = data[name]
    assert [i for i, r in enumerate(row['api']) if r['mutation']] == [2]
    changed = row['api'][2]
    assert delta(changed['before'], changed['after']) == [('/1/0/1/inputs/1/1/1/width', 'int', 8, 'str', '8')]
    assert all(equal(a['result'], b['result']) for a, b in zip(row['api'], reference['api']))
    consumer = next(r for r in row['consumers'] if r['label'] == 'projection does not share parser objects')
    assert consumer['passed'] == 1 and consumer['kind'] == 'is_deeply'
    safe = changed['before'] == changed['after']
    if args.trust_kind: safe = bool(consumer['passed'])
    assert not safe, 'value-only consumer cannot establish unchanged caller kinds'

aliased = data['alias']
assert [(i, r['shared_with_original']) for i, r in enumerate(aliased['copies']) if r['shared_with_original']] == [(5, 8)]
alias_copy = aliased['copies'][5]
assert alias_copy['caller'][2] == 47 and alias_copy['before'] == alias_copy['copy']
assert all(equal(a['result'], b['result']) for a, b in zip(aliased['api'], ordinary['api']))
isolated = alias_copy['shared_with_original'] == 0
if args.trust_alias: isolated = all(c['passed'] for c in aliased['consumers'])
assert not isolated, 'successful original test cannot establish copied-source isolation'

provider = binding['sources']['perl/FSM/Support/ISFInterfacePortMetadata.pm']['body']
start = provider.index('sub snapshot_interface_port_metadata {'); end = provider.index('sub _closed_keys {', start)
before = provider[start:end]; after = before.replace('width => 0 + $port->{width}', 'width => $port->{width}').replace('$_ => 0 + $field->{$_}', '$_ => $field->{$_}')
assert before == (BASE / 'projection-before.pl').read_text() and after == (BASE / 'projection-after.pl').read_text()
assert before.count('width => 0 + $port->{width}') == before.count('$_ => 0 + $field->{$_}') == 1
projection = data['projection']; product_differences = []
for index, (actual, reference) in enumerate(zip(projection['api'], ordinary['api'])):
    if reference['accepted']:
        for change in delta(reference['result'], actual['result']):
            assert change[1] == 'int' and change[3] == 'str' and str(change[2]) == change[4]
            assert change[0].endswith(('/width', '/signed'))
            product_differences.append((index, *change))
assert len(product_differences) == 79 and len({r[0] for r in product_differences}) == 53
conforming = not product_differences
if args.trust_projection: conforming = all(c['passed'] for c in projection['consumers'])
assert not conforming, 'value-only consumers cannot establish numeric final metadata products'
print('PASS complete original/pure/kind/alias/projection streams and actual seven-reference cycle qualification; scalar-preserving test copies conserve whole ordinary products/primary causes while genuine caller-kind/alias/numeric-projection controls expose owned test-assurance false GREENS. Private numeric rebuilding stays intentional; live test repair is successor-owned.')

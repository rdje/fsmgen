"""Independent exact source transformation and full repaired/control graph reader."""
import argparse
import hashlib
import json
import re
import subprocess
from pathlib import Path

BASE = Path(__file__).parent
parser = argparse.ArgumentParser()
parser.add_argument('--omit-copy', action='store_true')
parser.add_argument('--promote-green', choices=['kind', 'alias', 'lossy', 'projection'])
args = parser.parse_args()
subprocess.run(['python3', '-B', 'docs/audits/interface-metadata-copy-controls-20261004/verify.py'], check=True)
if (BASE / 'manifest.json').exists():
    manifest = json.loads((BASE / 'manifest.json').read_text())
    assert {p.name for p in BASE.iterdir()} == set(manifest) | {'manifest.json'}
    for name, row in manifest.items():
        raw = (BASE / name).read_bytes()
        assert len(raw) == row['bytes'] and hashlib.sha256(raw).hexdigest() == row['sha256'], name
binding = json.loads((BASE / 'binding-before.json').read_text())
after = json.loads((BASE / 'sources-after.json').read_text())
for name, row in binding['sources'].items():
    raw = subprocess.check_output(['git', 'show', binding['revision'] + ':' + name])
    assert raw.decode() == row['body'] and len(raw) == row['bytes'] and hashlib.sha256(raw).hexdigest() == row['sha256']
assert after.keys() == binding['sources'].keys()
assert [k for k in after if after[k] != binding['sources'][k]['body']] == ['t/1983-isf-interface-port-metadata.t']
source = after['t/1983-isf-interface-port-metadata.t']
assert source == (BASE / 'test-after.t').read_text()
helpers = (BASE / 'helpers-after.pl').read_text()
assert source.count(helpers) == 1
plain = binding['sources']['t/1959-isf-prepared-formal-reservations.t']['body']
plain = plain[plain.index('sub source_value_copy {'):plain.index('sub snapshot_graph {')]
assert helpers.startswith(plain)
strong = binding['sources']['t/1960-isf-formal-reservation-coverage.t']['body']
strong = strong[strong.index('sub source_references {'):strong.index('my $scheduler =')]
assert strong in helpers
original = binding['sources']['t/1983-isf-interface-port-metadata.t']['body']
expected = original.replace('use Storable qw(dclone);', 'use Scalar::Util qw(refaddr blessed);').replace('my $parser = FSM::Adapter::ISF->new;', helpers + 'my $parser = FSM::Adapter::ISF->new;')
replacements = {
    'my $before = dclone($actor);': 'my $before = input_snapshot($actor);',
    "is_deeply($actor, $before, 'projection does not share parser objects');": "is(input_snapshot($actor), $before, 'projection does not share parser objects');",
    "my $domain_interface = dclone($actor->{interface});": "my $domain_interface = source_copy($actor->{interface}, 'domain interface');",
    'my $value=dclone($template);': 'my $value=source_copy($template, "$name numeric seed");',
    '$value=dclone($template);': '$value=source_copy($template, "$name refused numeric seed");',
    'my $before = dclone($record_interface);': 'my $before = input_snapshot($record_interface);',
    "is_deeply($record_interface, $before, 'nested type objects remain detached');": "is(input_snapshot($record_interface), $before, 'nested type objects remain detached');",
    'push @{$_[0]}, dclone($_[0][0])': "push @{$_[0]}, source_copy($_[0][0], 'duplicate metadata entry')",
    'my $value = dclone($record);': "my $value = source_copy($record, 'malformed snapshot seed');",
    'my $value = dclone($record_interface);': "my $value = source_copy($record_interface, 'invalid producer seed');",
    'is_deeply($actual, $expected,': 'is_metadata($actual, $expected,',
    'is_deeply($json->decode($json->encode($actual)), $expected,': 'is_metadata($json->decode($json->encode($actual)), $expected,',
    'is_deeply(capture_interface_port_metadata({inputs => [{name =>': 'is_metadata(capture_interface_port_metadata({inputs => [{name =>',
    'is_deeply($actual,$record,': 'is_metadata($actual,$record,',
    'is_deeply($actual, $record,': 'is_metadata($actual, $record,',
    'is_deeply($ports->[0],': 'is_metadata($ports->[0],',
    'is_deeply($prepared->[0]{fields},': 'is_metadata($prepared->[0]{fields},',
}
for old, new in replacements.items():
    assert old in expected
    expected = expected.replace(old, new)
assert source == expected, 'complete bounded hot change'
assert 'dclone' not in source and 'blessed($value)' in helpers
for name in ('projection-before.pl', 'projection-after.pl'):
    assert (BASE / name).read_bytes() == Path('docs/audits/interface-metadata-copy-controls-20261004', name).read_bytes()

def equal(a, b):
    if type(a) is not type(b): return False
    if isinstance(a, dict): return a.keys() == b.keys() and all(equal(a[k], b[k]) for k in a)
    if isinstance(a, list): return len(a) == len(b) and all(equal(x, y) for x, y in zip(a, b))
    return a == b

def delta(a, b, path=''):
    if type(a) is not type(b): return [(path, type(a).__name__, a, type(b).__name__, b)]
    if isinstance(a, dict):
        assert a.keys() == b.keys(), ('shape', path)
        return [r for k in a for r in delta(a[k], b[k], path + '/' + k)]
    if isinstance(a, list):
        assert len(a) == len(b), ('array shape', path)
        return [r for i, (x, y) in enumerate(zip(a, b)) for r in delta(x, y, path + '/' + str(i))]
    return [] if a == b else [(path, type(a).__name__, a, type(b).__name__, b)]

def caller(actual, previous):
    expected = list(previous)
    if previous[1] == './t/1983-isf-interface-port-metadata.t': expected[2] += 77
    assert actual[:3] == expected[:3], ('source-bound coordinate', actual, expected)
    if len(actual) != len(expected):
        assert len(expected) == 3 and len(actual) == 11
        assert actual[3:6] == ['main::source_copy', 1, 1 if expected[2] == 261 else ''], 'exact push-list/other scalar copy-helper context'
    else: assert actual == expected

def primary(error): return error.splitlines()[:1]
def is_copy_assertion(row):
    return any(row['label'].endswith(suffix) for suffix in ('copy preserves original kinds and sharing',
        'copy preserves kinds and sharing', 'copy preserves reference population', 'copy is isolated from source'))

old = json.loads(Path('docs/audits/interface-metadata-copy-controls-20261004/pure.json').read_text())
data = {name: json.loads((BASE / (name + '.json')).read_text()) for name in ('ordinary', 'kind', 'alias', 'lossy', 'projection')}
ordinary = data['ordinary']
for name, row in data.items():
    assert row['sources_before'] == row['sources_after'] == after
    assert row['mode'] == name and row['changed'] == {'ordinary': 0, 'kind': 1, 'alias': 1, 'lossy': 41, 'projection': 0}[name]
    assert len(row['api']) == 105 and len(row['copies']) == 144 and len(row['helpers']) == 44 and len(row['parses']) == 3
    assert len(row['consumers']) == 334 and len(re.findall(r'^    (?:not )?ok [0-9]+ ', (BASE / (name + '.txt')).read_text(), re.M)) == 334
    assert int((BASE / (name + '.status')).read_text()) == {'ordinary': 0, 'kind': 1, 'alias': 1, 'lossy': 2, 'projection': 4}[name]
    for actual, reference in zip(row['api'], ordinary['api']):
        for key in ('kind', 'caller', 'helper', 'accepted', 'warnings'): assert actual[key] == reference[key]
        assert actual['warnings'] == [] and primary(actual['error']) == primary(reference['error'])
    for actual, reference in zip(row['parses'], ordinary['parses']):
        assert actual['kind'] == reference['kind'] and actual['caller'] == reference['caller']
        assert actual['accepted'] == reference['accepted'] and primary(actual['error']) == primary(reference['error'])
        assert {Path(k).name: v for k, v in actual['documents_before'].items()} == {Path(k).name: v for k, v in reference['documents_before'].items()}
        assert actual['documents_before'] == actual['documents_after'] and actual['before'] == actual['after']
        changes = delta(reference['before'], actual['before'])
        assert not changes or (actual['kind'] == 'file' and len(changes) == 1 and changes[0][0:2] == ('/1/0', 'str') and changes[0][3] == 'str')
        for change in changes:
            assert all(re.fullmatch(r'\$\{REPO_ROOT\}/\.artifacts/tmp/tests/[A-Za-z0-9_]+/imported\.isf', change[k]) for k in (2, 4))
        changes = delta(reference['result'], actual['result'])
        assert not changes or (name == 'projection' and all(c[1] == 'int' and c[3] == 'str' and str(c[2]) == c[4] and c[0].startswith('/1/interface_port_metadata/') and c[0].endswith('/width') for c in changes))
    cycle = row['cycles'][0]
    assert len(row['cycles']) == 1 and cycle['before'] == cycle['after'] == cycle['copy']
    assert cycle['original_reference_count'] == cycle['copy_reference_count'] == 7 and cycle['shared_with_original'] == 0
    assert '"reference", "/inputs/0/type_spec"' in json.dumps(cycle['copy'])
    copy_assertions = [r for r in row['consumers'] if is_copy_assertion(r)]
    assert len(copy_assertions) == 168
    cycle_assertions = [r for r in copy_assertions if r['label'].startswith('actual cyclic input ')]
    assert len(cycle_assertions) == 4 and all(r['passed'] for r in cycle_assertions)
    actual_copies = [r for r in row['copies'] if r['kind'] in ('test', 'cycle')]
    assert len(actual_copies) == 42
    suffixes = ('copy preserves original kinds and sharing', 'copy preserves kinds and sharing',
        'copy preserves reference population', 'copy is isolated from source')
    for index, copied in enumerate(actual_copies):
        checks = copy_assertions[index * 4:index * 4 + 4]
        assert all(r['kind'] == 'is' and r['label'].endswith(suffix) for r, suffix in zip(checks, suffixes))
        assert equal(json.loads(checks[0]['actual']), copied['after']) and equal(json.loads(checks[0]['expected']), copied['before'])
        assert equal(json.loads(checks[1]['actual']), copied['copy']) and equal(json.loads(checks[1]['expected']), copied['before'])
        assert checks[2]['actual'] == copied['copy_reference_count'] and checks[2]['expected'] == copied['original_reference_count']
        assert checks[3]['actual'] == copied['shared_with_original'] and checks[3]['expected'] == 0

for actual, previous in zip(ordinary['api'], old['api']):
    caller(actual['caller'], previous['caller'])
    for key in ('kind', 'helper', 'before', 'after', 'result', 'accepted', 'warnings'): assert equal(actual[key], previous[key]), ('whole ordinary API', key)
    assert actual['before'] == actual['after'] and primary(actual['error']) == primary(previous['error'])
for actual, previous in zip(ordinary['parses'], old['parses']):
    caller(actual['caller'], previous['caller'])
    assert equal(actual['result'], previous['result']) and primary(actual['error']) == primary(previous['error'])
    assert {Path(k).name: v for k, v in actual['documents_before'].items()} == {Path(k).name: v for k, v in previous['documents_before'].items()}
    differences = delta(previous['before'], actual['before'])
    if actual['kind'] == 'source': assert not differences
    else:
        assert len(differences) == 1 and differences[0][0] == '/1/0'
        assert all(re.fullmatch(r'\$\{REPO_ROOT\}/\.artifacts/tmp/tests/[A-Za-z0-9_]+/imported\.isf', differences[0][k]) for k in (2, 4))
original_copies = [r for r in old['copies'] if not (r['kind'] == 'test' and r['caller'][2] in (41, 116))]
current_copies = [r for r in ordinary['copies'] if r['kind'] != 'cycle']
if args.omit_copy: current_copies = current_copies[:-1]
assert len(original_copies) == len(current_copies) == 143, 'complete actual copy membership'
assert sum(r['kind'] == 'test' for r in current_copies) == 41
for actual, previous in zip(current_copies, original_copies):
    caller(actual['caller'], previous['caller'])
    for key in ('kind', 'api', 'before', 'after', 'copy', 'original_reference_count', 'copy_reference_count', 'shared_with_original'):
        assert equal(actual[key], previous[key]), ('complete qualified ordinary copy', key)
    assert actual['before'] == actual['after'] and actual['shared_with_original'] == 0
    if actual['kind'] == 'test': assert actual['before'] == actual['copy']
original_consumers = old['consumers']
current_consumers = [r for r in ordinary['consumers'] if not is_copy_assertion(r)]
assert len(original_consumers) == len(current_consumers) == 166
for actual, previous in zip(current_consumers, original_consumers):
    assert actual['label'] == previous['label'] and actual['passed'] == previous['passed'] == 1
    if actual['kind'] != previous['kind']:
        assert actual['kind'] == 'is' and previous['kind'] == 'is_deeply'
        assert equal(json.loads(actual['actual']), previous['actual']) and equal(json.loads(actual['expected']), previous['expected'])
    elif actual['kind'] == 'like':
        assert actual['expected'] == previous['expected'] and primary(actual['actual']) == primary(previous['actual'])
    else:
        assert equal(actual['actual'], previous['actual']) and ('expected' not in actual or equal(actual['expected'], previous['expected']))
assert all(r['passed'] for r in ordinary['consumers'])

for name in ('kind', 'alias', 'lossy', 'projection'):
    row = data[name]
    prior_mode = {'kind': 'pure-kind', 'alias': 'pure', 'lossy': 'ordinary', 'projection': 'projection'}[name]
    prior_control = json.loads(Path('docs/audits/interface-metadata-copy-controls-20261004', prior_mode + '.json').read_text())
    for actual, prior, reference in zip(row['api'], prior_control['api'], ordinary['api']):
        for key in ('before', 'after', 'result'):
            expected_value = reference[key] if name == 'projection' and key != 'result' else prior[key]
            assert equal(actual[key], expected_value), ('complete controlled API graph', name, key)
    old_copies = [r for r in prior_control['copies'] if not (r['kind'] == 'test' and r['caller'][2] in (41, 116))]
    new_copies = [r for r in row['copies'] if r['kind'] != 'cycle']
    assert len(old_copies) == len(new_copies) == 143
    for index, (actual, prior, reference) in enumerate(zip(new_copies, old_copies, current_copies)):
        for key in ('before', 'after', 'copy'):
            expected_value = reference[key] if name in ('alias', 'projection') else prior[key]
            assert equal(actual[key], expected_value), ('complete controlled copy graph', name, index, key)
        for key in ('kind', 'api', 'original_reference_count', 'copy_reference_count'):
            assert actual[key] == reference[key]
        assert actual['shared_with_original'] == (8 if name == 'alias' and index == 4 else 0)
        if name == 'projection' and reference['caller'] == ['FSM::Support::ISFInterfacePortMetadata', 'perl/FSM/Support/ISFInterfacePortMetadata.pm', 142]:
            assert actual['caller'] == ['FSM::Support::ISFInterfacePortMetadata', '(eval 47)', 5]
        else: assert actual['caller'] == reference['caller']
    failures = [r for r in row['consumers'] if not r['passed']]
    assert len(failures) == {'kind': 1, 'alias': 1, 'lossy': 12, 'projection': 7}[name]
    if name == 'kind':
        assert failures[0]['label'] == 'projection does not share parser objects'
        assert delta(row['api'][2]['before'], row['api'][2]['after']) == [('/1/0/1/inputs/1/1/1/width', 'int', 8, 'str', '8')]
        assert not equal(json.loads(failures[0]['actual']), json.loads(failures[0]['expected']))
    elif name == 'alias':
        assert failures[0]['label'] == 'domain interface copy is isolated from source'
        assert failures[0]['actual'] == 8 and failures[0]['expected'] == 0
        assert [(i, r['shared_with_original']) for i, r in enumerate(row['copies']) if r['shared_with_original']] == [(4, 8)]
    elif name == 'lossy':
        assert all(r['label'].endswith('copy preserves kinds and sharing') for r in failures)
        changed = [r for r in row['copies'] if r['kind'] == 'test' and r['before'] != r['copy']]
        assert len(changed) == 12 and sum(len(delta(r['before'], r['copy'])) for r in changed) == 48
        assert all(c[1] == 'int' and c[3] == 'str' and str(c[2]) == c[4] and c[0].endswith('/width') for r in changed for c in delta(r['before'], r['copy']))
    else:
        differences = [c for a, b in zip(ordinary['api'], row['api']) for c in delta(a['result'], b['result'])]
        assert len(differences) == 79 and all(c[1] == 'int' and c[3] == 'str' and str(c[2]) == c[4] and c[0].endswith(('/width', '/signed')) for c in differences)
        assert all(r['kind'] == 'is' and not equal(json.loads(r['actual']), json.loads(r['expected'])) for r in failures)
    failed = bool(failures)
    if args.promote_green == name: failed = all(r['passed'] for r in row['consumers'])
    assert failed, 'genuine fault cannot be promoted to passing repaired assurance: ' + name
print('PASS complete bounded current-source/ordinary copy/API/parser/166 original plus168 strong-copy consumer join; actual kind/alias/lossy/projection faults now fail intended readonly/isolation/kind/numeric product assertions, real cycle preserves7 references and isolation. Exact prior source models/products/causes conserve; private numeric rebuilding and public admission unchanged; diagnostic repair remains separately owned.')

import ast
import copy
import difflib
import hashlib
import json
import subprocess
import sys
from pathlib import Path

B = Path('docs/audits/reservation-coverage-cause-repair-20261003')
C = Path('docs/audits/reservation-coverage-cause-repair-checks-20261003')
P = Path('docs/audits/reservation-coverage-helper-causes-20261003')
D = Path('docs/audits/reservation-coverage-cause-diagnosis-20261003')

def load(path):
    return json.loads(path.read_text())

def equal(left, right):
    if type(left) is not type(right):
        return False
    if isinstance(left, dict):
        return left.keys() == right.keys() and all(equal(left[key], right[key]) for key in left)
    if isinstance(left, list):
        return len(left) == len(right) and all(equal(x, y) for x, y in zip(left, right))
    return left == right

def seal(base):
    manifest = load(base / 'manifest.json')
    assert {path.name for path in base.iterdir()} == set(manifest) | {'manifest.json'}
    for name, record in manifest.items():
        raw = (base / name).read_bytes()
        assert len(raw) == record['bytes'] and hashlib.sha256(raw).hexdigest() == record['sha256'], name

def current_rows(rows, original):
    assert len(rows) == len(original) == 39
    for current, prior in zip(rows, original):
        for key in ('label', 'band', 'expected_cause'):
            assert current[key] == prior[key]
        assert equal(current['before'], prior['before']) and equal(current['after'], prior['before'])
        assert current['accepted'] == 0 and current['result'] is None
        assert current['error'] == current['incoming_error']
        assert current['error'].split('\n')[0] == prior['error'].split('\n')[0]
        intended = current['band'] == 'current_fixture'
        assert current['assertions'] == [1, int(intended), 1]
        assert (current['error'].split('\n')[0] == current['expected_cause']) == intended

for base in (P, D, B):
    seal(base)
bindings = load(B / 'bindings.json')
revision = bindings['baseline']
assert revision == 'edb671c716b987414f81cb367605b9aa54841f10'
changed = 't/1960-isf-formal-reservation-coverage.t'
added = 't/2063-isf-coverage-diagnostic-causes.t'
members = {}
for entry in subprocess.check_output(['git', 'ls-tree', '-r', '-z', revision, '--',
                                     'bin', 'perl', 't', 'scripts', 'isf']).split(b'\0'):
    if entry:
        header, name = entry.split(b'\t', 1)
        members[name.decode()] = header.decode().split()[2]
assert set(bindings['metadata']) == set(members) | {added} and added not in members
for name, record in bindings['metadata'].items():
    raw = Path(name).read_bytes()
    actual = hashlib.sha1(b'blob ' + str(len(raw)).encode() + b'\0' + raw).hexdigest()
    assert len(raw) == record['bytes'] and hashlib.sha256(raw).hexdigest() == record['sha256'], name
    assert actual == record['current_blob'] and record['baseline_blob'] == members.get(name), name
    if name not in (changed, added):
        assert actual == members[name], name
untracked = subprocess.check_output(['git', 'ls-files', '--others', '--exclude-standard', '--',
                                    'bin', 'perl', 't', 'scripts', 'isf'], text=True).splitlines()
assert set(untracked) <= {added}
for name, source in bindings['sources'].items():
    before = subprocess.check_output(['git', 'show', revision + ':' + name], text=True) if name in members else None
    assert before == source['before'] and source['after'] == Path(name).read_text(), name
for name, record in bindings['instruments'].items():
    raw = Path(name).read_bytes()
    assert len(raw) == record['bytes'] and hashlib.sha256(raw).hexdigest() == record['sha256']
    assert record['body'] == raw.decode()
old = bindings['sources'][changed]['before']
new = bindings['sources'][changed]['after']
start = old.index('sub reject {'); end = old.index("subtest 'missing declarations", start)
old_helper = old[start:end]
expected_helper = old_helper.replace('$pattern', '$expected').replace(
    '    ok(!$ok, "$label refused"); like($@, $expected, "$label diagnosed");',
    '    my $error = $@;\n    ok(!$ok, "$label refused");\n'
    '    ok(diagnostic_cause_matches($error, $expected), "$label diagnosed") or diag($error);')
assert new[new.index('sub reject {'):new.index("subtest 'missing declarations")] == expected_helper
assert new[:new.index('sub reject {')] == old[:start].replace(
    'use FSM::Scheduler::ISF::FormalReservationCoverage;\n',
    'use FSM::Scheduler::ISF::FormalReservationCoverage;\nuse FSM::Test::DiagnosticCause qw(diagnostic_cause_matches);\n')
assert (C / 'prior-source.t').read_text() == old
driver = (D / 'desired.pl').read_text().replace(str(D), str(B)).replace(
    "open my $file, '<:raw', 't/1960-isf-formal-reservation-coverage.t'",
    "open my $file, '<:raw', '" + str(C / 'prior-source.t') + "'").replace(
    '"$base/observations-unqualified.json"', '"$base/prior.json"')
assert (C / 'prior-desired.pl').read_text() == driver
delta = subprocess.check_output(['git', 'diff', revision, '--', changed], text=True)
delta += ''.join(difflib.unified_diff([], bindings['sources'][added]['after'].splitlines(keepends=True),
                                    fromfile='absent', tofile=added))
assert (B / 'source-delta.patch').read_text() == delta
provider = bindings['sources']['perl/FSM/Scheduler/ISF/FormalReservationCoverage.pm']['after']
scope = provider[provider.index('sub _verify_scope {'):provider.index('sub _declarations {')]
assert scope.count('if @missing;') == 1
assert (B / 'bypass-body.pl').read_text() == scope.replace('if @missing;', 'if 0;')
declarations = ast.parse((P / 'contracts.py').read_text())
expected = ast.literal_eval(next(node.value for node in declarations.body if isinstance(node, ast.Assign)))
ordinary = load(B / 'ordinary.json')
baseline = load(P / 'initial-observations-unqualified.json')
assert len(ordinary['api']) == len(baseline['api']) == 23
assert len(ordinary['clones']) == len(baseline['clones']) == 62
assert len(ordinary['consumers']) == 13
for now, prior in zip(ordinary['api'], baseline['api']):
    for key in ('before', 'after', 'accepted', 'result'):
        assert equal(now[key], prior[key]), key
    assert now['error'].split('\n')[0] == prior['error'].split('\n')[0]
for now, prior in zip(ordinary['clones'], baseline['clones']):
    for key in ('before', 'after', 'clone'):
        assert equal(now[key], prior[key]), key
    assert equal(now['before'], now['after'])
    assert 'dclone' in new.splitlines()[now['line'] - 1]
assert sum(not equal(row['before'], row['clone']) for row in ordinary['clones']) == 41
for consumer in ordinary['consumers']:
    label = consumer['label'].removesuffix(' diagnosed')
    assert consumer['expected_cause'] == expected[label] and consumer['matched'] == 1
    assert consumer['error'] == ordinary['api'][consumer['api_index']]['error']
original = load(D / 'observations-unqualified.json')['rows']
current = load(B / 'current.json')['rows']
current_rows(current, original)
prior = load(B / 'prior.json')['rows']
assert len(prior) == 39
for now, before in zip(prior, original):
    for key in ('label', 'band', 'expected_cause', 'pattern', 'original', 'before', 'after', 'matched', 'accepted', 'result'):
        assert equal(now[key], before[key]), key
    assert now['error'] == now['incoming_error'] and now['error'].split('\n')[0] == before['error'].split('\n')[0]
    assert now['marker_before'] == now['marker_after']
bypass = load(B / 'bypass.json')
assert len(bypass['api']) == 23 and len(bypass['consumers']) == 13
accepted = {3, 4, 10, 15}
for index, (now, before) in enumerate(zip(bypass['api'], ordinary['api'])):
    assert equal(now['before'], before['before']) and equal(now['after'], before['after'])
    if index in accepted:
        assert before['accepted'] == 0 and now['accepted'] == 1 and now['error'] == ''
        assert equal(now['result'], ordinary['api'][0]['result'])
    else:
        assert now['accepted'] == before['accepted'] and equal(now['result'], before['result'])
        assert now['error'].split('\n')[0] == before['error'].split('\n')[0]
for consumer in bypass['consumers']:
    assert consumer['matched'] == (0 if consumer['api_index'] in accepted else 1)
for name, status, token in (
    ('current', '0', 'Files=2, Tests=239,'), ('ordinary', '0', 'All tests successful'),
    ('prior', '1', 'Tests: 195 Failed: 26'), ('bypass', '1', 'Tests: 5 Failed: 2'),
):
    assert (B / (name + '.status')).read_text().strip() == status
    assert token in (B / (name + '.txt')).read_text()
for key, value in (('expected_cause', 'forged cause'), ('assertions', [1, 1, 1]),
                   ('incoming_error', 'forged native error')):
    corrupted = copy.deepcopy(current)
    corrupted[1][key] = value
    try:
        current_rows(corrupted, original)
    except AssertionError:
        pass
    else:
        raise AssertionError(key + ' corruption escaped')
if '--trust-prior' in sys.argv:
    assert all(row['matched'] == 0 for row in prior if row['band'] != 'current_fixture'), 'real prior accepts wrong native causes'
if '--trust-bypass' in sys.argv:
    assert all(bypass['api'][index]['accepted'] == 0 for index in accepted), 'real bypass admits omitted/unreserved declarations'
print('PASS complete-cause correction/source/graph closure, conserved whole ordinary products and original clone drift; genuine prior and declaration-only bypass fail, typed corruptions reject.')
print('Complete source/copy-field/module/carrier meanings remain .4.3/cold .1.3; original Storable/value-only assurance is not promoted. Moved-root/native/visual QA stays explicit.')

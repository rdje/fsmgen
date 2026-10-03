import argparse
import ast
import copy
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/reservation-coverage-cause-diagnosis-20261003')
PROFILE = Path('docs/audits/reservation-coverage-helper-causes-20261003')

def load(path):
    return json.loads(path.read_text())

def same(a, b):
    if type(a) is not type(b):
        return False
    if isinstance(a, dict):
        return a.keys() == b.keys() and all(same(a[key], b[key]) for key in a)
    if isinstance(a, list):
        return len(a) == len(b) and all(same(x, y) for x, y in zip(a, b))
    return a == b

def escaped(key):
    return key.replace('~', '~0').replace('/', '~1')

def verify_rows(data, profile, expected, direct):
    consumers = profile['consumers']
    assert len(consumers) == 13 and len(data['rows']) == len(direct) == 39
    for index, row in enumerate(data['rows']):
        consumer = consumers[index // 3]
        band = ('current_fixture', 'earlier_reference', 'primary_path_echo')[index % 3]
        label = consumer['label'].removesuffix(' diagnosed')
        assert row['label'] == label and row['band'] == band
        assert row['api_index'] == consumer['api_index'] and row['pattern'] == consumer['pattern']
        reason = expected[label]
        assert row['expected_cause'] == reason
        original = profile['api'][consumer['api_index']]['before']
        assert same(row['original'], original)
        before = copy.deepcopy(original)
        if band != 'current_fixture':
            marker = ['blessed', 'CoverageCauseSentinel']
            if band == 'primary_path_echo':
                for key in reversed(reason.split('/')):
                    marker = ['hash', {key: marker}]
            assert '_early_reference' not in before[1][0][1]
            before[1][0][1]['_early_reference'] = marker
            path = '/_early_reference'
            if band == 'primary_path_echo':
                path += '/' + '/'.join(escaped(key) for key in reason.split('/'))
            primary = "Formal reservation inventory has unsupported reference at '" + path + "'"
            assert type(row['marker_before']) is int and row['marker_before'] > 0
            assert row['marker_before'] == row['marker_after']
        else:
            primary = reason
            assert row['marker_before'] is None and row['marker_after'] is None
        assert same(row['before'], before) and same(row['after'], before)
        assert row['accepted'] == 0 and row['result'] is None
        assert row['error'] == row['incoming_error'] and row['error'].split('\n')[0] == primary
        assert row['matched'] == 1
        replay = direct[index]
        assert replay['label'] == label and replay['band'] == band
        assert same(replay['before'], before) and same(replay['after'], before)
        assert replay['accepted'] == 0 and replay['result'] is None
        assert replay['error'].split('\n')[0] == primary and replay['saved_match'] == 1
        assert replay['direct_match'] == (0 if band == 'earlier_reference' else 1)

parser = argparse.ArgumentParser()
parser.add_argument('--trust-current-consumer', action='store_true')
args = parser.parse_args()
manifest = load(BASE / 'manifest.json')
assert {path.name for path in BASE.iterdir()} == set(manifest) | {'manifest.json'}
for name, record in manifest.items():
    raw = (BASE / name).read_bytes()
    assert len(raw) == record['bytes'] and hashlib.sha256(raw).hexdigest() == record['sha256'], name
bindings = load(BASE / 'bindings.json')
assert bindings['baseline'] == 'd404427cb03f420ff03aa3d49f921cb42020b0ed'
members = {}
for entry in subprocess.check_output(['git', 'ls-tree', '-r', '-z', bindings['baseline'], '--',
                                     'bin', 'perl', 't', 'scripts', 'isf']).split(b'\0'):
    if entry:
        header, name = entry.split(b'\t', 1)
        members[name.decode()] = header.decode().split()[2]
assert set(members) == set(bindings['metadata'])
for name, record in bindings['metadata'].items():
    raw = Path(name).read_bytes()
    assert len(raw) == record['bytes'] and hashlib.sha256(raw).hexdigest() == record['sha256'], name
    assert hashlib.sha1(b'blob ' + str(len(raw)).encode() + b'\0' + raw).hexdigest() == members[name] == record['blob'], name
for name, body in bindings['sources'].items():
    assert body == Path(name).read_text(), name
assert not subprocess.check_output(['git', 'ls-files', '--others', '--exclude-standard', '--',
                                    'bin', 'perl', 't', 'scripts', 'isf'])
manifest = load(PROFILE / 'manifest.json')
for name, record in manifest.items():
    raw = (PROFILE / name).read_bytes()
    assert len(raw) == record['bytes'] and hashlib.sha256(raw).hexdigest() == record['sha256']
profile = load(PROFILE / 'initial-observations-unqualified.json')
tree = ast.parse((PROFILE / 'contracts.py').read_text())
expected = ast.literal_eval(next(node.value for node in tree.body if isinstance(node, ast.Assign)))
assert expected == load(PROFILE / 'declared-causes.json')
data = load(BASE / 'observations-unqualified.json')
direct = load(BASE / 'direct-replay-unqualified.json')
source = bindings['sources']['t/1960-isf-formal-reservation-coverage.t']
assert data['helper'] == source[source.index('sub reject {'):source.index("subtest 'missing declarations")]
assert data['qr_program'].startswith('package RealCoverageConsumer;' + data['helper'])
start = source.index('for my $case (') + len('for my $case (')
end = source.index('    ) {\n', start)
assert source[start:end] in data['qr_program']
verify_rows(data, profile, expected, direct)
assert (BASE / 'desired-unqualified.status').read_text().strip() == '1'
tap = (BASE / 'desired-unqualified.txt').read_text()
assert 'Tests: 195 Failed: 26' in tap and 'Non-zero exit status: 26' in tap
assert (BASE / 'direct-replay-unqualified.status').read_text().strip() == '0'
assert 'All tests successful' in (BASE / 'direct-replay-unqualified.txt').read_text()
for name, mutation in (
    ('cause', lambda rows: rows['rows'][0].update(expected_cause='forged cause')),
    ('match', lambda rows: rows['rows'][1].update(matched=0)),
    ('QR flags', lambda rows: rows['rows'][1].update(pattern='(?i:forged pattern)')),
    ('kind', lambda rows: rows['rows'][0]['before'][1][0][1]['actor'][1].update(actor_name=99)),
    ('native identity', lambda rows: rows['rows'][1].update(marker_after=0)),
):
    corrupt = copy.deepcopy(data)
    mutation(corrupt)
    try:
        verify_rows(corrupt, profile, expected, direct)
    except AssertionError:
        pass
    else:
        raise AssertionError(name + ' corruption escaped')
if args.trust_current_consumer:
    assert all(row['matched'] == 0 for row in data['rows'] if row['band'] != 'current_fixture'), \
        'actual current consumer falsely accepts unrelated native failures'
print('PASS complete source/native input/kind/cause/QR closure: thirteen genuine and twenty-six real wrong-cause matches; direct native replay isolates stack/path echoes and typed corruptions reject.')
print('Whole copy-field/module/carrier meanings remain .4.3/cold .1.3; current-root spelling does not qualify moved-root behavior. Immediate P2 .2.3.14 owns cause repair.')

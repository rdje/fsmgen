"""Cold, typed full-graph verification of the actual coverage helper repair."""
import argparse
import hashlib
import json
import re
import subprocess
from collections import Counter
from pathlib import Path

BASE = Path('docs/audits/reservation-coverage-copy-repair-20261003')
parser = argparse.ArgumentParser()
parser.add_argument('--trust-prior', action='store_true')
parser.add_argument('--trust-alias', action='store_true')
parser.add_argument('--omit-copy', action='store_true')
options = parser.parse_args()


def load(path): return json.loads(Path(path).read_text())


def same(a, b):
    if type(a) is not type(b): return False
    if isinstance(a, dict): return a.keys() == b.keys() and all(same(a[k], b[k]) for k in a)
    if isinstance(a, list): return len(a) == len(b) and all(same(x, y) for x, y in zip(a, b))
    return a == b


def differences(a, b):
    result, pending = [], [('', a, b)]
    while pending:
        path, x, y = pending.pop()
        if type(x) is not type(y):
            result.append((path, type(x).__name__, type(y).__name__, x, y))
        elif isinstance(x, dict):
            assert x.keys() == y.keys(), ('key drift', path)
            pending.extend((path + '/' + k.replace('~', '~0').replace('/', '~1'), x[k], y[k]) for k in x)
        elif isinstance(x, list):
            assert len(x) == len(y), ('length drift', path)
            pending.extend((path + '/' + str(i), xx, yy) for i, (xx, yy) in enumerate(zip(x, y)))
        elif x != y:
            result.append((path, type(x).__name__, type(y).__name__, x, y))
    return sorted(result)


if (BASE / 'manifest.json').exists():
    manifest = load(BASE / 'manifest.json')
    assert {str(p.relative_to(BASE)) for p in BASE.rglob('*') if p.is_file()} == set(manifest) | {'manifest.json'}
    for name, row in manifest.items():
        raw = (BASE / name).read_bytes()
        assert len(raw) == row['bytes'] and hashlib.sha256(raw).hexdigest() == row['sha256'], name

binding = load(BASE / 'bindings.json')
entries = subprocess.check_output(['git', 'ls-tree', '-r', '-z', binding['revision']])
members = {}
for entry in entries.split(b'\0'):
    if not entry: continue
    header, name = entry.split(b'\t', 1)
    mode, kind, blob = header.decode().split(); name = name.decode()
    if name.split('/')[0] not in ('bin', 'perl', 't', 'scripts', 'isf'): continue
    assert kind == 'blob' and mode in ('100644', '100755')
    members[name] = (mode, blob)
assert members.keys() == binding['public_sources'].keys()
changed = []
with subprocess.Popen(['git', 'cat-file', '--batch'], stdin=subprocess.PIPE, stdout=subprocess.PIPE) as objects:
    for name, row in binding['public_sources'].items():
        assert members[name] == (row['mode'], row['blob'])
        objects.stdin.write((row['blob'] + '\n').encode()); objects.stdin.flush()
        header = objects.stdout.readline().decode().split()
        assert header[:2] == [row['blob'], 'blob']
        before = objects.stdout.read(int(header[2])); assert objects.stdout.read(1) == b'\n'
        path = Path(name); assert not path.is_symlink()
        assert path.stat().st_dev == Path.cwd().stat().st_dev
        after = path.read_bytes()
        assert len(before) == row['bytes'] and hashlib.sha256(before).hexdigest() == row['sha256'], name
        assert len(after) == row['after_bytes'] and hashlib.sha256(after).hexdigest() == row['after_sha256'], name
        if after != before: changed.append(name)
    objects.stdin.close(); assert objects.wait() == 0
assert changed == binding['changed_public_sources'] == ['t/1960-isf-formal-reservation-coverage.t', 't/2063-isf-coverage-diagnostic-causes.t']
subprocess.run(['python3', '-B', 'docs/audits/reservation-coverage-historical-context-20261003/verify.py'], check=True)
for name, row in binding['sources'].items():
    before = subprocess.check_output(['git', 'show', binding['revision'] + ':' + name])
    assert before.decode() == row['before'] and len(before) == row['bytes']
    assert hashlib.sha256(before).hexdigest() == row['sha256']
    after = Path(name).read_bytes()
    assert after.decode() == row['after'] and len(after) == row['after_bytes']
    assert hashlib.sha256(after).hexdigest() == row['after_sha256'], name
    if name not in ('t/1960-isf-formal-reservation-coverage.t', 't/2063-isf-coverage-diagnostic-causes.t'):
        assert after == before, ('provider/previous helper changed', name)
assert (BASE / 'prior-T1960.t').read_text() == binding['sources']['t/1960-isf-formal-reservation-coverage.t']['before']
source = binding['sources']['t/1960-isf-formal-reservation-coverage.t']['after']
assert 'Storable' not in source and 'dclone' not in source
recipe = Path('docs/audits/reservation-coverage-plain-native-boundary-20261003/helper-body.pl').read_text()
assert source[source.index('sub source_value_copy {'):source.index('sub source_references {')] == recipe + '\n'
assert len(re.findall(r'\bsource_copy\(', source)) == 6
assert len(re.findall(r'my \$before = input_snapshot\(\[', source)) == 2
assert 'copy preserves kinds and sharing' in source and 'copy is isolated from source' in source
subject = binding['sources']['t/2063-isf-coverage-diagnostic-causes.t']['after']
assert "eval 'package CurrentCoverageCauseSubject;' . $graph_helpers . $helper" in subject
assert 'Test::More::is($_[0], $_[1], $_[2])' in subject
assert 'empty native marker identity retained' in subject

coordinates = load(BASE / 'coordinates.json')
versions = {}
for name in ('prior-ordinary', 'prior-pure', 'prior-success', 'prior-refusal',
             'current-ordinary', 'current-success', 'current-refusal', 'current-storable', 'current-alias'):
    versions[name] = row = load(BASE / (name + '.json'))
    expected_status = 0 if name.startswith('prior-') or name == 'current-ordinary' else 1
    assert int((BASE / (name + '.status')).read_text()) == expected_status, name
    text = (BASE / (name + '.txt')).read_text()
    assert re.search(r'^1\.\.5$', text, re.M), name
    assert len(row['copies']) == (62 if name.startswith('prior-') else 39), name
    assert len(row['preparations']) == 12 and len(row['lowerings']) == 10, name
    assert len(row['coverage']) == len(row['consumers']) == 23, name
    assert len(row['proofs']) == (0 if name.startswith('prior-') else 156), name
    assert row['changed'] == (0 if name.endswith(('ordinary', 'pure')) else 1), name
    found, pending = [], [('', row)]
    while pending:
        path, node = pending.pop()
        if isinstance(node, dict): pending.extend((path + '/' + k, v) for k, v in node.items())
        elif isinstance(node, list): pending.extend((path + '/' + str(i), v) for i, v in enumerate(node))
        elif isinstance(node, str) and '${REPO_ROOT}' in node:
            assert path.endswith('/library_source') and node == '${REPO_ROOT}/isf/common/fifo.isf'
            found.append(path)
    assert sorted(found) == sorted(coordinates[name]), ('portability coordinates', name)

old = versions['prior-ordinary']; pure = versions['prior-pure']; now = versions['current-ordinary']
expected_counts = {'authored_actor': 6, 'physical_actor': 10, 'captured_module': 10,
    'unexpected_module_seed': 1, 'module_mutation_seed': 11, 'allocation_mutation_seed': 1}
copies = now['copies'][:-1] if options.omit_copy else now['copies']
assert Counter(r['site'] for r in copies) == expected_counts, 'complete live copy population'
snapshot_sites = {'success_snapshot', 'refusal_snapshot'}
pure_copies = [r for r in pure['copies'] if r['site'] not in snapshot_sites]
for ordinal, (actual, prospective) in enumerate(zip(copies, pure_copies)):
    assert actual['site'] == prospective['site']
    for key in ('before', 'after', 'copy', 'original_reference_count', 'copy_reference_count', 'shared_with_original'):
        assert same(actual[key], prospective[key]), ('qualified prospective/live mismatch', ordinal, key)
    assert same(actual['before'], actual['after']) and same(actual['before'], actual['copy'])
    assert actual['original_reference_count'] == actual['copy_reference_count'] and actual['shared_with_original'] == 0
    proofs = now['proofs'][ordinal * 4:(ordinal + 1) * 4]
    assert len(proofs) == 4 and all(p['passed'] for p in proofs)
    for index in (0, 1):
        assert same(proofs[index]['actual'], actual['after' if index == 0 else 'copy'])
        assert same(proofs[index]['expected'], actual['before'])
    assert proofs[2]['actual'] == actual['copy_reference_count']
    assert proofs[2]['expected'] == actual['original_reference_count']
    assert proofs[3]['actual'] == proofs[3]['expected'] == 0

historical = load('docs/audits/reservation-coverage-snapshot-capture-20261003/ordinary.json')
for old_row, captured in zip(old['copies'], historical['copies']):
    for key in ('site', 'before', 'after', 'copy', 'original_reference_count', 'copy_reference_count', 'shared_with_original'):
        assert same(old_row[key], captured[key]), ('exact prior copy replay', key)
diffs = [differences(r['before'], r['copy']) for r in old['copies']]
assert sum(bool(d) for d in diffs) == 41 and sum(map(len, diffs)) == 548
assert all(x[1:3] == ('int', 'str') and str(x[3]) == x[4] for d in diffs for x in d)
for key in ('preparations', 'lowerings'):
    assert same(now[key], pure[key]), ('complete source/products/carriers', key)
for actual, expected in zip(now['coverage'], pure['coverage']):
    for key in ('before', 'after', 'accepted', 'result', 'mutation'): assert same(actual[key], expected[key]), key
    assert actual['error'].split('\n')[0] == expected['error'].split('\n')[0]
    assert same(actual['before'], actual['after'])
for ordinal, consumer in enumerate(now['consumers']):
    assert consumer['call_ordinal'] == ordinal and consumer['passed'] == 1
    assert same(consumer['actual'], now['coverage'][ordinal]['after'])
    assert same(consumer['expected'], now['coverage'][ordinal]['before'])

kind_path = '/1/0/1/generated_child_products/1/worker/1/assignment_provenance/1/0/1/rhs'
for mode, target in (('success', 0), ('refusal', 3)):
    for version in ('prior', 'current'):
        controlled = versions[version + '-' + mode]; ordinary = versions[version + '-ordinary']
        failed = [r['call_ordinal'] for r in controlled['consumers'] if not r['passed']]
        assert failed == ([] if version == 'prior' else [target]), ('real kind assurance', version, mode)
        assert same(controlled['lowerings'], ordinary['lowerings'])
        assert same(controlled['preparations'], ordinary['preparations'])
        for ordinal, (call, baseline) in enumerate(zip(controlled['coverage'], ordinary['coverage'])):
            assert call['accepted'] == baseline['accepted'] and same(call['result'], baseline['result'])
            assert call['error'].split('\n')[0] == baseline['error'].split('\n')[0]
            assert bool(call['mutation']) == (ordinal == target)
            for timing in ('before', 'after'):
                affected = ((ordinal == target and timing == 'after') or 3 <= ordinal <= 15)
                if mode == 'refusal' and ordinal == 3 and timing == 'before': affected = False
                delta = differences(baseline[timing], call[timing])
                assert delta == ([(kind_path, 'int', 'str', 1, '1')] if affected else []), (version, mode, ordinal, timing, delta)
    if options.trust_prior:
        assert versions['prior-' + mode]['consumers'][target]['passed'] == 0, 'prior value-only kind authority is unsafe'

for mode, failed_proof in (('storable', 5), ('alias', 7)):
    controlled = versions['current-' + mode]
    assert [i for i, p in enumerate(controlled['proofs']) if not p['passed']] == [failed_proof], mode
    assert all(r['passed'] for r in controlled['consumers'])
    assert same(controlled['preparations'], now['preparations'])
    assert same(controlled['lowerings'], now['lowerings'])
    for call, baseline in zip(controlled['coverage'], now['coverage']):
        assert call['accepted'] == baseline['accepted'] and same(call['result'], baseline['result'])
        assert call['error'].split('\n')[0] == baseline['error'].split('\n')[0]
    if mode == 'alias':
        assert controlled['copies'][1]['shared_with_original'] > 0
        assert same(controlled['copies'][1]['before'], controlled['copies'][1]['copy'])
        if options.trust_alias:
            assert controlled['copies'][1]['shared_with_original'] == 0, 'value-equal aliased copy is unsafe'

prior_native = load('docs/audits/reservation-coverage-snapshot-native-join-20261003/ordinary-test.json')['rows']
for mode in ('ordinary', 'replacement'):
    subject = load(BASE / ('native-' + mode + '-test.json'))['rows']
    observed = load(BASE / ('native-' + mode + '-observer.json'))
    assert len(subject) == len(observed['calls']) == len(prior_native) == 39
    assert observed['changed'] == (0 if mode == 'ordinary' else 1)
    assert int((BASE / ('native-' + mode + '.status')).read_text()) == (0 if mode == 'ordinary' else 3)
    text = (BASE / ('native-' + mode + '.txt')).read_text()
    assert re.search(r'^1\.\.234$', text, re.M)
    failures = re.findall(r'^not ok (\d+) - (.*)$', text, re.M)
    assert [int(n) for n, _ in failures] == ([] if mode == 'ordinary' else [7, 8, 12]), failures
    for ordinal, (row, before, call) in enumerate(zip(subject, prior_native, observed['calls'])):
        for key in ('label', 'band', 'expected_cause', 'before', 'after', 'accepted', 'result'):
            assert same(row[key], before[key]), ('complete native conservation', mode, ordinal, key)
        assert row['error'] == row['incoming_error'] == call['error']
        assert row['error'].split('\n')[0] == before['error'].split('\n')[0]
        expected_bits = [1, 1 if row['band'] == 'current_fixture' else 0, 1]
        if mode == 'replacement' and ordinal == 1: expected_bits[-1] = 0
        assert row['assertions'] == expected_bits
        delta = differences(call['before'], call['after'])
        if mode == 'replacement' and ordinal == 1:
            mutation = call['mutation']
            assert mutation['path'] == '/0/_early_reference'
            assert mutation['before_identity'] != mutation['after_identity']
            assert delta == [('/1/0/1/_early_reference/2', 'int', 'int', mutation['before_identity'], mutation['after_identity'])]
        else: assert not delta and call['mutation'] is None

assert int((BASE / 'focused.status').read_text()) == 0
assert 'All tests successful.' in (BASE / 'focused.txt').read_text()
assert 'Files=3, Tests=243' in (BASE / 'focused.txt').read_text()
assert int((BASE / 'historical-replay.status').read_text()) == 0
context = load(BASE / 'historical/ordinary-context.json')
assert context['reader_status'] == 0 and not context['mismatches'] and context['same_volume']
assert context['primary_git_before'] == context['primary_git_after']
assert context['primary_revision_before'] == context['primary_revision_after'] == binding['revision']
assert context['revision'] == '93ff524834b748004510e10befad4df4cd8cc5fe'
for name, cause in (
    ('unsafe-prior', 'prior value-only kind authority is unsafe'),
    ('alias-authority', 'value-equal aliased copy is unsafe'),
    ('copy-omission', 'complete live copy population'),
):
    assert int((BASE / (name + '.status')).read_text()) == 1
    lines = (BASE / (name + '.txt')).read_text().splitlines()
    assert lines[-1] == 'AssertionError: ' + cause, name
print('PASS live 39-copy/23-snapshot repair, 12 preparations/10 complete lowerings/carriers, 39 native cause cases, exact prior and genuine kind/copy/native failures; historical qualification stays pinned.')

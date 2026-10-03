import argparse
import copy
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/reservation-coverage-value-only-controls-20261003')
CAPTURE = Path('docs/audits/reservation-coverage-snapshot-capture-20261003')
parser = argparse.ArgumentParser()
parser.add_argument('--trust-success', action='store_true')
parser.add_argument('--trust-refusal', action='store_true')
options = parser.parse_args()
TARGET = '/1/0/1/generated_child_products/1/worker/1/assignment_provenance/1/0/1/rhs'


def same(a, b):
    if type(a) is not type(b): return False
    if isinstance(a, dict): return a.keys() == b.keys() and all(same(a[k], b[k]) for k in a)
    if isinstance(a, list): return len(a) == len(b) and all(same(x, y) for x, y in zip(a, b))
    return a == b


def kind_delta(a, b):
    changes, pending = [], [('', a, b)]
    while pending:
        path, x, y = pending.pop()
        if type(x) is not type(y):
            assert type(x) is int and type(y) is str and str(x) == y, ('unexpected kind/value', path)
            changes.append(path)
        elif isinstance(x, dict):
            assert x.keys() == y.keys(), ('changed keys', path)
            pending.extend((path + '/' + k, x[k], y[k]) for k in x)
        elif isinstance(x, list):
            assert len(x) == len(y), ('changed length', path)
            pending.extend((path + '/' + str(i), xx, yy) for i, (xx, yy) in enumerate(zip(x, y)))
        else:
            assert x == y, ('changed value', path)
    return sorted(changes)


def coordinates(value, path='', key=None):
    if isinstance(value, dict): return [p for k, v in value.items() for p in coordinates(v, path + '/' + k, k)]
    if isinstance(value, list): return [p for i, v in enumerate(value) for p in coordinates(v, path + '/' + str(i))]
    if isinstance(value, str) and '${REPO_ROOT}' in value:
        assert key == 'library_source' and value == '${REPO_ROOT}/isf/common/fifo.isf'
        return [path]
    return []


if (BASE / 'manifest.json').exists():
    manifest = json.loads((BASE / 'manifest.json').read_text())
    assert {p.name for p in BASE.iterdir()} == set(manifest) | {'manifest.json'}
    for name, r in manifest.items():
        raw = (BASE / name).read_bytes()
        assert len(raw) == r['bytes'] and hashlib.sha256(raw).hexdigest() == r['sha256'], name
subprocess.run(['python3', '-B', 'docs/audits/reservation-coverage-snapshot-field-join-20261003/verify.py'], check=True)
binding = json.loads((BASE / 'bindings.json').read_text())
for path, r in binding['sources'].items():
    raw = subprocess.check_output(['git', 'show', binding['revision'] + ':' + path])
    assert len(raw) == r['bytes'] and hashlib.sha256(raw).hexdigest() == r['sha256'] and raw.decode() == r['body']
old_binding = json.loads((CAPTURE / 'bindings.json').read_text())
for path, r in binding['sources'].items():
    assert same(r, old_binding['sources'][path]), ('changed native source', path)
source = binding['sources']['t/1960-isf-formal-reservation-coverage.t']['body']
for literal in ('is_deeply([$p, $plan, \\%modules], $before, "$label verification is read-only");', 'is_deeply([$p, $allocation, $actual], $before, "$label refusal preserves inputs");', 'my $error = $@;'):
    assert literal in source, literal
modes = {m: json.loads((BASE / (m + '.json')).read_text()) for m in ('ordinary', 'success', 'refusal')}
original = json.loads((CAPTURE / 'ordinary.json').read_text())
ordinary = modes['ordinary']
ledger = json.loads((BASE / 'coordinates.json').read_text())
acceptance = [1, 1, 1] + [0] * 13 + [1] * 7
for mode, data in modes.items():
    assert set(data) == {'mode', 'calls', 'consumers', 'lowerings', 'changed'} and data['mode'] == mode
    assert len(data['calls']) == len(data['consumers']) == 23 and len(data['lowerings']) == 10
    assert data['changed'] == int(mode != 'ordinary')
    assert [row['accepted'] for row in data['calls']] == acceptance
    assert [row['call_ordinal'] for row in data['consumers']] == list(range(23))
    assert all(row['passed'] == 1 for row in data['consumers'])
    assert sorted(coordinates(data)) == sorted(ledger[mode])
    assert (BASE / (mode + '.status')).read_text().strip() == '0'
    receipt = (BASE / (mode + '.txt')).read_text()
    assert 'All tests successful.' in receipt and 'Files=1, Tests=5,' in receipt
    assert same(data['lowerings'], original['lowerings']), ('whole lowering/carrier drift', mode)
    for i, (row, consumer, baseline, prior) in enumerate(zip(data['calls'], data['consumers'], ordinary['calls'], original['coverage'])):
        assert same(baseline['before'], prior['before']) and same(baseline['after'], prior['after'])
        assert same(row['result'], baseline['result']) and same(row['result'], prior['result'])
        if not row['accepted']:
            assert row['error'].splitlines()[0] == baseline['error'].splitlines()[0] == prior['error'].splitlines()[0]
        else:
            assert row['error'] == baseline['error'] == prior['error'] == ''
        assert consumer['label'] == ordinary['consumers'][i]['label']
        assert same(consumer['actual'], row['after']), ('unassociated actual consumer', mode, i)
        if mode == 'ordinary':
            assert row['mutation'] is None and same(row['before'], row['after'])
        else:
            chosen = 0 if mode == 'success' else 3
            assert bool(row['mutation']) == (i == chosen)
            assert row['mutation'] in (None, TARGET)
            assert kind_delta(row['before'], row['after']) == ([TARGET] if i == chosen else [])
            before_changed = 3 <= i <= 15 if mode == 'success' else 4 <= i <= 15
            after_changed = before_changed or i == chosen
            assert kind_delta(baseline['before'], row['before']) == ([TARGET] if before_changed else [])
            assert kind_delta(baseline['after'], row['after']) == ([TARGET] if after_changed else [])
            # A genuine consumer is explicitly chosen as the competing safety
            # authority. Its real PASS cannot override changed caller kinds.
            if (mode == 'success' and options.trust_success or mode == 'refusal' and options.trust_refusal) and i == chosen:
                assert consumer['passed'] == 1
                assert same(row['before'], row['after']), ('actual value-only authority accepts caller-kind mutation', mode, i)
for mode, ordinal in (('success', 0), ('refusal', 3)):
    row = modes[mode]['calls'][ordinal]
    before = row['before'][1][0][1]['generated_child_products'][1]['worker'][1]['assignment_provenance'][1][0][1]
    after = row['after'][1][0][1]['generated_child_products'][1]['worker'][1]['assignment_provenance'][1][0][1]
    assert before['target'] == after['target'] == 'notice' and before['source_kind'] == after['source_kind'] == 'complete_pulse'
    assert same(before['rhs'], 1) and same(after['rhs'], '1')
    # The old copied expected graph already lost this kind; the test still
    # uses its actual value-only comparator instead of a first-touch oracle.
    expected = modes[mode]['consumers'][ordinal]['expected'][1][0][1]['generated_child_products'][1]['worker'][1]['assignment_provenance'][1][0][1]['rhs']
    assert same(expected, '1')
    bad = copy.deepcopy(row['after'])
    bad[1][0][1]['generated_child_products'][1]['worker'][1]['assignment_provenance'][1][0][1]['rhs'] = '2'
    try: kind_delta(row['before'], bad)
    except AssertionError: pass
    else: raise AssertionError('changed value accepted as kind-only mutation')
assert not same(ordinary['consumers'], ordinary['consumers'][:-1]), 'consumer omission accepted'
print('PASS every exact native call/consumer/current source, original caller graph and whole ordinary lowering/carrier/scope/cause outcome authenticated.')
print('PASS genuine success/refusal numeric1-to-string1 caller mutations each violate one first-touch field while actual current Test::More assertions and full test remain green; all subsequent propagation is exact.')
print('PASS isolated source-owned pulse target, complete kind-only delta and value/consumer omission controls; actual competing consumer authorities are genuine unsafe models.')
print('OPEN: finite plain/native controls and snapshot/final joins precede P2 repair; current unmodified provider mutation is not alleged, and wider constructor/controller/native/moved-root meanings stay cold.')

if not options.trust_success and not options.trust_refusal:
    for name, last in (
        ('trust-success', "AssertionError: ('actual value-only authority accepts caller-kind mutation', 'success', 0)"),
        ('trust-refusal', "AssertionError: ('actual value-only authority accepts caller-kind mutation', 'refusal', 3)"),
    ):
        assert (BASE / (name + '.status')).read_text().strip() == '1'
        assert (BASE / (name + '.txt')).read_text().splitlines()[-1] == last

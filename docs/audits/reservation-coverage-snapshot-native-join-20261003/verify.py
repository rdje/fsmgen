"""Independent actual native identity/cause replay and complete snapshot join."""
import argparse
import copy
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/reservation-coverage-snapshot-native-join-20261003')
PRIOR = Path('docs/audits/reservation-coverage-cause-repair-20261003')
parser = argparse.ArgumentParser()
parser.add_argument('--trust-value-only', action='store_true')
options = parser.parse_args()


def same(a, b):
    if type(a) is not type(b): return False
    if isinstance(a, dict): return a.keys() == b.keys() and all(same(a[k], b[k]) for k in a)
    if isinstance(a, list): return len(a) == len(b) and all(same(x, y) for x, y in zip(a, b))
    return a == b


def plain_view(node):
    # T2063 records native class/empty shape in its value graph and separately
    # asserts original identity. The candidate graph retains that actual ID.
    if isinstance(node, dict): return {k: plain_view(v) for k, v in node.items()}
    if isinstance(node, list):
        if len(node) == 3 and node[0] == 'empty_native_hash':
            assert node[1] == 'CoverageCauseSentinel' and type(node[2]) is int and node[2] > 0
            return ['blessed', node[1]]
        return [plain_view(v) for v in node]
    return node


def native_members(node, path=''):
    if isinstance(node, dict):
        return [(p, n) for k, v in node.items() for p, n in native_members(v, path + '/' + k)]
    if isinstance(node, list):
        if len(node) == 3 and node[0] == 'empty_native_hash': return [(path, node)]
        return [(p, n) for i, v in enumerate(node) for p, n in native_members(v, path + '/' + str(i))]
    return []


if (BASE / 'manifest.json').exists():
    manifest = json.loads((BASE / 'manifest.json').read_text())
    assert {p.name for p in BASE.iterdir()} == set(manifest) | {'manifest.json'}
    for name, row in manifest.items():
        raw = (BASE / name).read_bytes()
        assert len(raw) == row['bytes'] and hashlib.sha256(raw).hexdigest() == row['sha256'], name
subprocess.run(['python3', '-B', 'docs/audits/reservation-coverage-plain-native-boundary-20261003/verify.py'], check=True)
binding = json.loads((BASE / 'bindings.json').read_text())
for path, row in binding['sources'].items():
    raw = subprocess.check_output(['git', 'show', binding['revision'] + ':' + path])
    assert raw.decode() == row['body'] and len(raw) == row['bytes'] and hashlib.sha256(raw).hexdigest() == row['sha256'], path
raw = subprocess.check_output(['git', 'show', binding['revision'] + ':' + binding['task_path']])
assert len(raw) == binding['task_bytes'] and hashlib.sha256(raw).hexdigest() == binding['task_sha256']
task = raw.decode()
expected_suffixes = {'.4.1', '.4.2', '.4.2.3', '.4.3.1', '.4.3.2.1'}
prefix = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.2.4.3'
assert set(binding['owners']) == {prefix + suffix for suffix in expected_suffixes}
for identity, body in binding['owners'].items():
    start = task.index('- ID: `' + identity + '`'); end = task.index('\n- ID:', start + 1)
    assert task[start:end] == body and 'Status: `done`' in body
    assert 'Verification: `pending`' not in body and 'Commit: `pending`' not in body
source = binding['sources']['t/2063-isf-coverage-diagnostic-causes.t']['body']
for literal in (
    'my $identity = marker_identity($input, $row);',
    'is(marker_identity($input, $row), $identity,',
    "&& reftype($marker) eq 'HASH' && !keys %$marker;",
    'my $before = snapshot($input);',
    '$api_error = $@; $api_accepted = $ok ? 1 : 0;',
    'my $helper = substr($source, $start, $end - $start);',
):
    assert literal in source, ('missing actual native/source contract', literal)
prior = json.loads((PRIOR / 'current.json').read_text())['rows']
assert len(prior) == 39
modes = {}
for mode in ('ordinary', 'replacement'):
    test = json.loads((BASE / (mode + '-test.json')).read_text())['rows']
    observer = json.loads((BASE / (mode + '-observer.json')).read_text())
    assert set(observer) == {'mode', 'changed', 'calls'} and observer['mode'] == mode
    assert same(observer['changed'], int(mode == 'replacement'))
    assert len(test) == len(observer['calls']) == len(prior) == 39
    for i, (row, call, old) in enumerate(zip(test, observer['calls'], prior)):
        assert set(row) == set(old) and set(call) == {'ordinal', 'before', 'after', 'accepted', 'result', 'error', 'mutation'}
        assert call['ordinal'] == i and same(call['accepted'], 0) and call['result'] is None
        for key in ('label', 'band', 'expected_cause', 'accepted', 'result', 'assertions', 'before', 'after'):
            assert same(row[key], old[key]), ('complete native result/input drift', mode, i, key)
        assert row['error'] == row['incoming_error'] == call['error']
        assert row['error'].splitlines()[0] == old['error'].splitlines()[0]
        assert same(plain_view(call['before']), row['before']) and same(plain_view(call['after']), row['after'])
        native = native_members(call['before'])
        assert len(native) == int(row['band'] != 'current_fixture')
        if mode == 'replacement' and i == 1:
            assert row['band'] == 'earlier_reference'
            before_marker = call['before'][1][0][1]['_early_reference']
            after_marker = call['after'][1][0][1]['_early_reference']
            assert before_marker[:2] == after_marker[:2] == ['empty_native_hash', 'CoverageCauseSentinel']
            assert before_marker[2] != after_marker[2]
            assert call['mutation'] == {'path': '/0/_early_reference', 'before_identity': before_marker[2], 'after_identity': after_marker[2]}
            expected = copy.deepcopy(call['before']); expected[1][0][1]['_early_reference'][2] = after_marker[2]
            assert same(call['after'], expected), 'replacement changed another field/kind/backedge'
            assert row['assertions'] == [1, 0, 1], 'existing value-only helper assertion did not remain genuinely green'
            if options.trust_value_only:
                assert same(row['before'], row['after'])
                assert same(call['before'], call['after']), 'actual value-only native graph loses original marker identity'
        else:
            assert call['mutation'] is None and same(call['before'], call['after']), ('ordinary identity/kind/sharing drift', mode, i)
    modes[mode] = test
    receipt = (BASE / (mode + '.txt')).read_text()
    assert (BASE / (mode + '.status')).read_text().strip() == ('0' if mode == 'ordinary' else '1')
    if mode == 'ordinary':
        assert 'All tests successful.' in receipt and 'Files=1, Tests=234,' in receipt
    else:
        assert 'Failed 1/234 subtests' in receipt and 'Tests: 234 Failed: 1)' in receipt
        assert 'Failed test \'late register / earlier_reference: empty native marker identity retained\'' in receipt
        assert 'Failed test:  12' in receipt and 'Result: FAIL' in receipt
for left, right in zip(modes['ordinary'], modes['replacement']):
    for key in ('label', 'band', 'expected_cause', 'accepted', 'result', 'assertions', 'before', 'after'):
        assert same(left[key], right[key]), ('ordinary/replacement conservation drift', key)
    assert left['error'].splitlines()[0] == right['error'].splitlines()[0]
print('PASS full Git-bound current T2063 helper/source and completed snapshot capture/fields/real-consumer/candidate owners; whole39 native cases conserve complete causes/results/plain graphs and ordinary original marker identities/classes/empty shapes.')
print('PASS actual one-marker replacement after real refusal preserves every intended cause/value-only graph/helper bit; existing original-identity assertion alone fails RED1/234. Whole first-touch graph detects only the actual ID change.')
print('PASS complete snapshot assurance joins authenticated capture/fields/value-only/plain topology/isolation and finite actual native identity; final coverage join precedes P2 repair. General native/constructor/controller/moved-root meanings stay cold.')
if not options.trust_value_only:
    assert (BASE / 'trust-value-only.status').read_text().strip() == '1'
    assert (BASE / 'trust-value-only.txt').read_text().splitlines()[-1] == 'AssertionError: actual value-only native graph loses original marker identity'

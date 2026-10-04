"""Independently authenticate the pinned original context and actual replays."""
import argparse
import copy
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-original-replay-20261004')
PRIOR = Path('docs/audits/record-value-semantic-join-20261004')
parser = argparse.ArgumentParser()
for flag in ('omit-input', 'trust-decoy', 'wrong-owner'):
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
sealed(PRIOR)
sealed(Path('docs/audits/record-value-semantics-20261004'))
sealed(Path('docs/audits/record-value-clone-paths-20261004'))
binding = json.loads((BASE / 'binding.json').read_text())
assert binding['revision'] == '0da4675ac61460451f030001adad075157a6efb4'
prior = json.loads((PRIOR / 'binding.json').read_text())
assert set(binding['sources']) == set(prior['sources']) and len(binding['sources']) == 21
for path, row in {**binding['sources'], binding['task_path']: binding['task_context']}.items():
    raw = subprocess.check_output(['git', 'show', binding['revision'] + ':' + path])
    assert row == {'body': raw.decode(), **identity(raw)}, 'full original Git source/task identity: ' + path
updates = json.loads((BASE / 'doc-updates.json').read_text())
assert {row['path'] for row in updates} == {'docs/book/src/13k-isf-feature-support-matrix.md', 'docs/knowledge/isf-aggregate-port-request-baseline.md'}
for row in updates:
    assert row['before'] == binding['sources'][row['path']]['body']
    text = row['before']
    for before, after in row['replacements']:
        assert text.count(before) == 1
        text = text.replace(before, after)
    assert text == row['after'], 'exact archived documentation transformation; current docs are separately maintained'
for path, row in binding['runtime'].items():
    assert identity(Path(path).read_bytes()) == row, 'complete unchanged own provider/runtime: ' + path
original_runtime = json.loads(Path('docs/audits/record-value-clone-paths-20261004/runtime-support.json').read_text())
assert binding['runtime'] == original_runtime
assert len(binding['owners']) == 29 and len({row['owner'] for row in binding['owners']}) == 29
current_task = Path(binding['task_path']).read_text()
for row in binding['owners']:
    for text in (binding['task_context']['body'], current_task):
        start = text.index('- ID: `' + row['owner'] + '`')
        end = text.index('\n- ID:', start + 1)
        assert text[start:end] == row['node'] and 'Status: `done`' in row['node'], 'exact completed original semantic owner'
label = 'source-decoy' if args.trust_decoy else 'owner-decoy' if args.wrong_owner else 'ordinary'
packet = copy.deepcopy(json.loads((BASE / (label + '.json')).read_text()))
if args.omit_input:
    packet['inputs'].pop('t/1986-isf-record-port-value-gates.t')
expected = {path: row['body'] for path, row in binding['sources'].items()}
expected[binding['task_path']] = binding['task_context']['body']
assert set(packet['inputs']) == set(expected), 'complete pinned original source/task input membership'
assert set(packet['sources']) == set(expected), 'complete full source/task body membership'
assert {path: packet['sources'][path] for path in binding['sources']} == {path: row['body'] for path, row in binding['sources'].items()}, 'whole original source bodies cannot borrow actual decoy authority'
assert packet['sources'][binding['task_path']] == binding['task_context']['body'], 'whole pinned task bodies retain exact completed owner authority'
assert packet['inputs'] == {path: identity(body.encode()) for path, body in expected.items()}, 'complete pinned source/task byte identities'
assert packet['runtime'] == binding['runtime'] and packet['revision'] == binding['revision']
controls = json.loads((PRIOR / 'controls.json').read_text())
main, helper = str(PRIOR / 'verify.py'), str(PRIOR / 'native.py')
expected_commands = [['python3', '-B', main]] + [row['command'] for row in controls]
assert [row['command'] for row in packet['receipts']] == expected_commands, 'original ordinary and every nine reached RED commands'
assert [row['status'] for row in packet['receipts']] == [0] + [1] * 9
for row in packet['receipts']:
    assert row['programs'] == {path: identity(Path(path).read_bytes()) for path in (main, helper)}
    assert row['working_directory'] == '.artifacts/record-value-original-replay-20261004/ordinary'
for decoy, cause in (('source-decoy', 'AssertionError: current selected source drift: t/1986-isf-record-port-value-gates.t'), ('owner-decoy', 'AssertionError')):
    bad = json.loads((BASE / (decoy + '.json')).read_text())
    assert bad['label'] == decoy and len(bad['receipts']) == 1
    expected_bad = dict(expected)
    if decoy == 'source-decoy':
        target = 't/1986-isf-record-port-value-gates.t'
        assert expected_bad[target].count('my $target = dclone($source);') == 1
        expected_bad[target] = expected_bad[target].replace('my $target = dclone($source);', 'my $target = $source;')
    else:
        node = binding['owners'][0]['node']
        assert expected_bad[binding['task_path']].count(node) == 1
        expected_bad[binding['task_path']] = expected_bad[binding['task_path']].replace(node, node.replace('Status: `done`', 'Status: `pending`'))
    assert bad['sources'] == expected_bad, 'complete genuine decoy source/task transformation and non-target bodies'
    assert bad['inputs'] == {path: identity(body.encode()) for path, body in expected_bad.items()}
    assert bad['runtime'] == binding['runtime'] and bad['revision'] == binding['revision']
    receipt = bad['receipts'][0]
    assert receipt['command'] == expected_commands[0] and receipt['status'] == 1
    assert receipt['working_directory'] == '.artifacts/record-value-original-replay-20261004/' + decoy
    assert receipt['programs'] == {path: identity(Path(path).read_bytes()) for path in (main, helper)}
    assert receipt['output'].rstrip().endswith(cause)
if (BASE / 'controls.json').exists():
    own_controls = json.loads((BASE / 'controls.json').read_text())
    assert [row['command'] for row in own_controls] == [['python3', '-B', str(BASE / 'verify.py'), '--' + flag] for flag in ('omit-input', 'trust-decoy', 'wrong-owner')]
    for row in own_controls:
        assert row['working_directory'] == '.' and row['status'] == 1
        assert row['output'].rstrip().endswith('AssertionError: ' + row['expected_failure'])
for flags in ([], ['--source-decoy'], ['--owner-decoy']):
    run = subprocess.run(['python3', '-B', str(BASE / 'replay.py')] + flags, text=True, capture_output=True)
    assert run.returncode == 0, run.stdout + run.stderr
print('PASS complete pinned original semantic authority:21 full source bodies/full committed task/29 done owners/complete own runtime; original ordinary/all nine RED and inherited source/native proofs reexecute. Actual source/owner decoys reject. Cold authority does not qualify changed current tests or full native causes.')

"""Reexecute the immutable original proof in its complete pinned context."""
import argparse
import ast
import hashlib
import json
import os
import re
import subprocess
import sys
from pathlib import Path

BASE = Path('docs/audits/record-value-original-replay-20261004')
PRIOR = Path('docs/audits/record-value-semantic-join-20261004')
parser = argparse.ArgumentParser()
parser.add_argument('--record', action='store_true')
parser.add_argument('--source-decoy', action='store_true')
parser.add_argument('--owner-decoy', action='store_true')
args = parser.parse_args()
assert not (args.source_decoy and args.owner_decoy)
binding = json.loads((BASE / 'binding.json').read_text())
label = 'source-decoy' if args.source_decoy else 'owner-decoy' if args.owner_decoy else 'ordinary'
fixture = Path('.artifacts/record-value-original-replay-20261004') / label
root = Path.cwd()
metadata = subprocess.check_output(['git', 'rev-parse', '--absolute-git-dir']).decode().strip()


def identity(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


sources = {path: row['body'] for path, row in binding['sources'].items()}
target = 't/1986-isf-record-port-value-gates.t'
if args.source_decoy:
    before = 'my $target = dclone($source);'
    assert sources[target].count(before) == 1
    sources[target] = sources[target].replace(before, 'my $target = $source;')
task = binding['task_context']['body']
if args.owner_decoy:
    node = binding['owners'][0]['node']
    assert task.count(node) == 1 and node.count('Status: `done`') == 1
    task = task.replace(node, node.replace('Status: `done`', 'Status: `pending`'))
sources[binding['task_path']] = task
links = {}
for path in ('docs/audits', 'scripts', 'perl', 't/lib'):
    link = fixture / path
    link.parent.mkdir(parents=True, exist_ok=True)
    relative = os.path.relpath(root / path, root / link.parent)
    if link.is_symlink():
        assert os.readlink(link) == relative
    else:
        assert not link.exists()
        link.symlink_to(relative, target_is_directory=True)
    links[path] = relative
for path, body in sources.items():
    if path.startswith(('perl/', 't/lib/')):
        assert Path(path).read_text() == body, 'unchanged own provider/runtime source: ' + path
        continue
    destination = fixture / path
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(body)
inputs = {path: identity((fixture / path).read_bytes()) for path in sources}
assert all((fixture / path).read_text() == body for path, body in sources.items())
main, helper = str(PRIOR / 'verify.py'), str(PRIOR / 'native.py')
tree = ast.parse(Path('docs/audits/record-value-clone-paths-20261004/portability.py').read_text())
functions = [node for node in tree.body if isinstance(node, ast.FunctionDef) and node.name in ('qualify', 'historic')]
assert {node.name for node in functions} == {'qualify', 'historic'}
helpers = {'Path': Path, 'frame': re.compile(r'(  File ")(.*)(", line [1-9][0-9]*, in [^\r\n]+)(\r?\n)?'), 'main': main, 'helper': helper}
exec(compile(ast.Module(body=functions, type_ignores=[]), 'authenticated exact original main/native module file-coordinate helpers', 'exec'), helpers)
controls = json.loads((PRIOR / 'controls.json').read_text())
flags = (None,) if args.source_decoy or args.owner_decoy else (None,) + tuple(row['command'][-1] for row in controls)
environment = dict(os.environ)
environment['GIT_DIR'] = metadata
environment['GIT_WORK_TREE'] = str(root / fixture)
index_before = subprocess.check_output(['git', 'ls-files', '--stage', '-z'])
runtime_before = {path: identity(Path(path).read_bytes()) for path in binding['runtime']}
assert runtime_before == binding['runtime']
receipts = []
for flag in flags:
    command = ['python3', '-B', main] + ([flag] if flag else [])
    run = subprocess.run(command, cwd=fixture, env=environment, text=True, capture_output=True)
    raw = run.stdout + run.stderr
    filenames = {str(root / fixture / path): path for path in (main, helper)}
    filenames[str((root / fixture / helper).resolve())] = helper
    output = helpers['qualify'](raw, filenames)
    if args.source_decoy:
        assert run.returncode == 1 and output.rstrip().endswith('AssertionError: current selected source drift: ' + target), raw
    elif args.owner_decoy:
        assert run.returncode == 1 and output.rstrip().endswith('AssertionError'), raw
    elif flag:
        prior = next(row for row in controls if row['command'][-1] == flag)
        assert prior['command'] == command and prior['working_directory'] == '.' and prior['status'] == run.returncode == 1
        assert output == helpers['historic'](prior['output']), 'whole original RED output beyond exact invoked process filenames'
    else:
        prior = json.loads(Path('docs/audits/record-value-semantic-join-checks-20261004/ordinary-status.json').read_text())
        expected = Path('docs/audits/record-value-semantic-join-checks-20261004/ordinary.txt').read_text()
        assert expected.startswith('ram-guard: PID ')
        expected = '\n'.join(expected.splitlines()[1:]) + '\n'
        assert prior['command'] == command and prior['working_directory'] == '.' and prior['status'] == run.returncode == 0
        assert output == expected, 'whole original ordinary semantic/native output'
    receipts.append({'command': command, 'working_directory': str(fixture), 'status': run.returncode,
        'output': output, 'programs': {path: identity(Path(path).read_bytes()) for path in (main, helper)}})
assert subprocess.check_output(['git', 'ls-files', '--stage', '-z']) == index_before, 'primary Git index remains unchanged'
assert {path: identity(Path(path).read_bytes()) for path in binding['runtime']} == runtime_before
assert all((fixture / path).read_text() == body for path, body in sources.items()), 'complete pinned source/task afterimages conserve'
packet = {'python': sys.version, 'revision': binding['revision'], 'label': label, 'sources': sources,
    'inputs': inputs, 'links': links, 'runtime': runtime_before, 'receipts': receipts,
    'git_context': {'metadata': 'current repository metadata derived read-only by git rev-parse --absolute-git-dir',
        'work_tree': str(fixture), 'index_conserved': True, 'operations': 'read-only queries; no separate Git repository'}}
destination = BASE / (label + '.json')
if args.record:
    destination.write_text(json.dumps(packet, sort_keys=True, indent=2) + '\n')
else:
    assert packet == json.loads(destination.read_text()), 'whole exact pinned original source/task/runtime/status/output replay identity'
print('PASS pinned ' + label + ' replay with complete original source/task/runtime membership and exact full output/status; only invoked main/native module File-frame coordinates qualify.')

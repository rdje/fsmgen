"""Reexecute the completed relative-command native proof in its dated context."""
import argparse
import ast
import hashlib
import json
import os
import re
import subprocess
import sys
from pathlib import Path

BASE = Path('docs/audits/record-value-identities-20261004')
parser = argparse.ArgumentParser()
parser.add_argument('--check', action='store_true')
args = parser.parse_args()
old = Path('docs/audits/record-value-clone-join-20261004')
binding = json.loads((old / 'binding.json').read_text())
current = json.loads((BASE / 'binding.json').read_text())
fixture = Path('.artifacts/record-value-identities-clone-replay-20261004')
documents = {row['path']: row['after'] for row in json.loads((old / 'doc-updates.json').read_text())}
for path, row in binding['sources'].items():
    if path not in documents:
        assert row['body'] == current['sources'][path]['body']
    if path.startswith(('perl/', 't/lib/')):
        assert Path(path).read_text() == row['body']
        continue
    destination = fixture / path
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(documents.get(path, row['body']))
task_path = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
(fixture / task_path).parent.mkdir(parents=True, exist_ok=True)
(fixture / task_path).write_bytes(Path(task_path).read_bytes())
for path in ('docs/audits', 'scripts', 'perl', 't/lib'):
    link = fixture / path
    target = os.path.relpath(Path.cwd() / path, Path.cwd() / link.parent)
    if link.is_symlink():
        assert os.readlink(link) == target
    else:
        assert not link.exists()
        link.symlink_to(target, target_is_directory=True)
inputs = {path: {'bytes': len((fixture / path).read_bytes()), 'sha256': hashlib.sha256((fixture / path).read_bytes()).hexdigest()} for path in binding['sources']}
relative = str(old / 'verify.py')
module = 'docs/audits/record-value-clones-20261004/native.py'
tree = ast.parse(Path('docs/audits/record-value-clone-paths-20261004/portability.py').read_text())
functions = [node for node in tree.body if isinstance(node, ast.FunctionDef) and node.name in ('qualify', 'historic')]
assert {node.name for node in functions} == {'qualify', 'historic'}
helpers = {'Path': Path, 'frame': re.compile(r'(  File ")(.*)(", line [1-9][0-9]*, in [^\r\n]+)(\r?\n)?'), 'main': relative, 'helper': module}
exec(compile(ast.Module(body=functions, type_ignores=[]), 'bound exact main/native module file-coordinate helpers', 'exec'), helpers)
controls = {row['command'][-1]: row for row in json.loads((old / 'controls.json').read_text())}
receipts = []
for flag in (None, '--omit-call', '--same-native', '--wrong-root', '--numeric-kind', '--alias-result'):
    command = ['python3', '-B', relative] + ([flag] if flag else [])
    environment = dict(os.environ)
    environment['GIT_DIR'] = subprocess.check_output(['git', 'rev-parse', '--absolute-git-dir']).decode().strip()
    environment['GIT_WORK_TREE'] = str(Path.cwd() / fixture)
    # The same project metadata is read only; no synthetic Git repository or
    # index mutation is created. Pathspecs must address the fixture root rather
    # than its ancestor-repository subdirectory prefix.
    run = subprocess.run(command, cwd=fixture, env=environment, text=True, capture_output=True)
    assert run.returncode == (1 if flag else 0), run.stdout + run.stderr
    names = {str(Path.cwd() / fixture / relative): relative, str(Path.cwd() / fixture / module): module}
    output = helpers['qualify'](run.stdout + run.stderr, names)
    if flag:
        prior = controls[flag]
        assert prior['command'] == command and prior['status'] == run.returncode
        assert output == helpers['historic'](prior['output']), 'whole actual structured clone join semantic/control output beyond bound exact process filenames'
    else:
        prior = subprocess.check_output(['git', 'show', current['revision'] + ':docs/audits/record-value-clone-join-checks-20261004/ordinary.txt']).decode()
        assert prior.splitlines()[0].startswith('ram-guard: PID ')
        assert output == '\n'.join(prior.splitlines()[1:]) + '\n'
    receipts.append({'command': command, 'working_directory': str(fixture), 'inputs': inputs, 'status': run.returncode, 'output': output, 'git_context': {'metadata': 'current repository metadata derived by git rev-parse --absolute-git-dir', 'work_tree': str(fixture), 'operations': 'read-only child queries'}})
destination = fixture / 'payload-control-native.json'
command = ['perl', '-Iperl', str(BASE / 'payload_controls.pl'), str(BASE / 'payload-control-inputs.json'), str(destination)]
run = subprocess.run(command, text=True, capture_output=True)
assert run.returncode == 0 and run.stdout == run.stderr == '', run.stdout + run.stderr
assert destination.read_bytes() == (BASE / 'payload-control-native.json').read_bytes(), 'whole genuine current public payload argument/kind/order/product/caller conservation'
payload = {'command': command, 'working_directory': '.', 'status': run.returncode, 'output': run.stdout + run.stderr,
    'input': {'bytes': len((BASE / 'payload-control-inputs.json').read_bytes()), 'sha256': hashlib.sha256((BASE / 'payload-control-inputs.json').read_bytes()).hexdigest()},
    'result': destination.read_text(), 'perl': subprocess.check_output(['perl', '-e', 'print "$^V\n$^O\n";']).decode()}
packet = {'python': sys.version, 'source_revision': binding['revision'], 'receipts': receipts, 'payload': payload}
if args.check:
    assert packet == json.loads((BASE / 'clone-replays.json').read_text()), 'whole dated source/doc/runtime/Python/status/native/control output replay identity'
else:
    (BASE / 'clone-replays.json').write_text(json.dumps(packet, sort_keys=True, indent=2) + '\n')
print('PASS complete structured clone join ordinary/all five source/allocation/kind/native alias RED controls reexecute exact dated source/doc/owner/runtime contexts with all native/source-root/tree proof families. Supplementary public payload controls reexecute exactly from whole source inputs; only exact invoked main/native graph module Python File-frame filenames qualify.')

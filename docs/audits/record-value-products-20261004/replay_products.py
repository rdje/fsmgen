"""Reexecute completed actor/value/core product proofs in exact dated contexts."""
import argparse
import ast
import hashlib
import json
import os
import re
import subprocess
import sys
from pathlib import Path

BASE = Path('docs/audits/record-value-products-20261004')
parser = argparse.ArgumentParser()
parser.add_argument('--check', action='store_true')
args = parser.parse_args()
current = json.loads((BASE / 'binding.json').read_text())
families = {
    'actors': ('omit-product', 'swap-source-role', 'trust-private-product', 'numeric-source-tokens', 'omit-default-family'),
    'api-join': ('omit-api', 'omit-copy', 'incomplete-owner', 'swap-field'),
    'core-join': ('omit-call', 'same-model', 'wrong-family', 'numeric-product', 'omit-private'),
}
tree = ast.parse(Path('docs/audits/record-value-clone-paths-20261004/portability.py').read_text())
functions = [node for node in tree.body if isinstance(node, ast.FunctionDef) and node.name in ('qualify', 'historic')]
assert {node.name for node in functions} == {'qualify', 'historic'}
module = 'docs/audits/record-value-clones-20261004/native.py'
metadata = subprocess.check_output(['git', 'rev-parse', '--absolute-git-dir']).decode().strip()


def identity(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def historical(path):
    return subprocess.check_output(['git', 'show', current['revision'] + ':' + path]).decode()


packets = []
for family, flags in families.items():
    old = Path('docs/audits/record-value-' + family + '-20261004')
    checks = 'docs/audits/record-value-' + family + '-checks-20261004/'
    binding = json.loads((old / 'binding.json').read_text())
    fixture = Path('.artifacts/record-value-products-replay-20261004') / family
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
    inputs = {path: identity((fixture / path).read_bytes()) for path in binding['sources']}
    relative = str(old / 'verify.py')
    helpers = {'Path': Path, 'frame': re.compile(r'(  File ")(.*)(", line [1-9][0-9]*, in [^\r\n]+)(\r?\n)?'), 'main': relative, 'helper': module}
    exec(compile(ast.Module(body=functions, type_ignores=[]), 'bound exact main/native module file-coordinate helpers', 'exec'), helpers)
    controls = {row['command'][-1]: row for row in json.loads((old / 'controls.json').read_text())} if (old / 'controls.json').exists() else {}
    receipts = []
    for flag in (None,) + tuple('--' + flag for flag in flags):
        command = ['python3', '-B', relative] + ([flag] if flag else [])
        environment = dict(os.environ)
        environment['GIT_DIR'] = metadata
        environment['GIT_WORK_TREE'] = str(Path.cwd() / fixture)
        run = subprocess.run(command, cwd=fixture, env=environment, text=True, capture_output=True)
        raw = run.stdout + run.stderr
        assert run.returncode == (1 if flag else 0), raw
        names = {str(Path.cwd() / fixture / relative): relative, str(Path.cwd() / fixture / module): module}
        output = helpers['qualify'](raw, names)
        if flag and controls:
            prior = controls[flag]
            assert prior['command'] == command and prior['status'] == run.returncode and prior['working_directory'] == '.'
            expected = helpers['historic'](prior['output'])
        else:
            label = flag[2:] if flag else 'ordinary'
            prior = json.loads(historical(checks + label + '-status.json'))
            if family == 'actors':
                assert set(prior) == {'command', 'status', 'process_filename_policy'}
                assert prior['command'] == command and prior['status'] == run.returncode
                assert prior['process_filename_policy'] == 'only exact runtime repository prefix becomes ${REPO_ROOT}; native product/error/kind values untouched'
            else:
                assert prior['command'] == command and prior['status'] == run.returncode and prior['working_directory'] == '.'
            expected = historical(checks + label + '.txt')
            if expected.startswith('ram-guard: PID '):
                assert not flag
                expected = '\n'.join(expected.splitlines()[1:]) + '\n'
            if flag and family == 'actors':
                # Old checked receipts already qualify exactly this main File coordinate.
                # Retain every original semantic byte; do not apply their broader prose policy.
                for line in expected.splitlines(keepends=True):
                    match = helpers['frame'].fullmatch(line)
                    if match:
                        assert match[2] == '${REPO_ROOT}/' + relative
            elif flag:
                expected = helpers['historic'](expected)
        assert output == expected, 'whole ' + family + ' ordinary/control output beyond exact process filenames'
        receipts.append({'command': command, 'working_directory': str(fixture), 'inputs': inputs,
            'programs': {path: identity(Path(path).read_bytes()) for path in (relative, module)},
            'status': run.returncode, 'output': output,
            'git_context': {'metadata': 'current repository metadata derived by git rev-parse --absolute-git-dir', 'work_tree': str(fixture), 'operations': 'read-only child queries'}})
    packets.append({'family': family, 'source_revision': binding['revision'], 'receipts': receipts})
packet = {'python': sys.version, 'binding_revision': current['revision'], 'families': packets}
if args.check:
    assert packet == json.loads((BASE / 'product-replays.json').read_text()), 'whole dated actor/value/core source/doc/runtime/Python/status/native/control output replay identity'
else:
    (BASE / 'product-replays.json').write_text(json.dumps(packet, sort_keys=True, indent=2) + '\n')
print('PASS all three completed actor/value/core ordinary readers and all14 direct RED controls reexecute exact dated source/doc/owner/runtime contexts with every inherited native/source/model proof. Only exact invoked main/native graph module Python File-frame filenames qualify; complete semantic output retains.')

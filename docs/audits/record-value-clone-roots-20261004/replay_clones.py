"""Replay full completed native clone proof in its exact dated document context."""
import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
from pathlib import Path

BASE = Path(__file__).parent
parser = argparse.ArgumentParser()
parser.add_argument('--check', action='store_true')
args = parser.parse_args()
old = Path('docs/audits/record-value-clones-20261004')
binding = json.loads((old / 'binding.json').read_text())
current = json.loads((BASE / 'binding.json').read_text())
fixture = Path('.artifacts/record-value-clone-roots-native-replay-20261004')
docs = {row['path']: row['after'] for row in json.loads((old / 'doc-updates.json').read_text())}
for path, source in binding['sources'].items():
    if path not in docs:
        assert source['body'] == current['sources'][path]['body']
    target = fixture / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(docs.get(path, source['body']))
task_path = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
(fixture / task_path).parent.mkdir(parents=True, exist_ok=True)
(fixture / task_path).write_bytes(Path(task_path).read_bytes())
for relative in ('docs/audits', 'scripts'):
    link = fixture / relative
    target = os.path.relpath(Path.cwd() / relative, Path.cwd() / link.parent)
    if link.is_symlink():
        assert os.readlink(link) == target
    else:
        assert not link.exists()
        link.symlink_to(target, target_is_directory=True)
inputs = {path: {'bytes': len((fixture / path).read_bytes()), 'sha256': hashlib.sha256((fixture / path).read_bytes()).hexdigest()} for path in binding['sources']}
main = str(old / 'verify.py'); helper = str(old / 'native.py')
frame = re.compile(r'(  File ")(.*)(", line [1-9][0-9]*, in [^\r\n]+)(\r?\n)?')


def qualify(output, names):
    """Only exact declared main/imported module File-frame filenames change.

    Every line/message/source/argument/native coordinate byte stays exact.
    Imported native.py resolves through the authenticated archive symlink.
    """
    lines = []
    for line in output.splitlines(keepends=True):
        match = frame.fullmatch(line)
        if match:
            assert match[2] in names, 'exact bound main/native module process filename'
            line = match[1] + '${REPO_ROOT}/' + names[match[2]] + match[3] + (match[4] or '')
        lines.append(line)
    return ''.join(lines)


def historical(output):
    names = {}
    for line in output.splitlines(keepends=True):
        match = frame.fullmatch(line)
        if not match:
            continue
        assert Path(match[2]).is_absolute()
        logical = next((relative for relative in (main, helper) if match[2].endswith('/' + relative)), None)
        assert logical is not None
        names[match[2]] = logical
    return qualify(output, names)


controls = {row['command'][-1]: row for row in json.loads((old / 'controls.json').read_text())}
receipts = []
for flag in (None, '--omit-call', '--alias-result', '--false-zero', '--joint-swap', '--wrong-kind'):
    command = ['python3', '-B', main] + ([flag] if flag else [])
    run = subprocess.run(command, cwd=fixture, text=True, capture_output=True)
    assert run.returncode == (1 if flag else 0), run.stdout + run.stderr
    names = {str(Path.cwd() / fixture / main): main, str((Path.cwd() / fixture / helper).resolve()): helper}
    output = qualify(run.stdout + run.stderr, names)
    if flag:
        previous = controls[flag]
        assert previous['command'] == command and previous['status'] == run.returncode
        assert output == historical(previous['output']), 'complete rejecting native output beyond exact two bound program filenames'
    else:
        previous = subprocess.check_output(['git', 'show', current['revision'] + ':docs/audits/record-value-structured-clones-checks-20261004/ordinary.txt']).decode()
        # Original outer monitor line is instrument status, not Python output.
        assert previous.splitlines()[0].startswith('ram-guard: PID ')
        assert output == '\n'.join(previous.splitlines()[1:]) + '\n'
    receipts.append({'command': command, 'working_directory': str(fixture), 'inputs': inputs, 'status': run.returncode, 'output': output, 'bound_programs': {relative: {'bytes': len(Path(relative).read_bytes()), 'sha256': hashlib.sha256(Path(relative).read_bytes()).hexdigest()} for relative in (main, helper)}})
packet = {'python': sys.version, 'source_revision': binding['revision'], 'receipts': receipts}
if args.check:
    assert packet == json.loads((BASE / 'native-replays.json').read_text()), 'whole original native proof/program/source/doc/input/status/output/control replay identity'
else:
    (BASE / 'native-replays.json').write_text(json.dumps(packet, sort_keys=True, indent=2) + '\n')
print('PASS completed native clone ordinary/all five RED proofs reexecute exact21 dated inputs/documents/owners and both full public native profiles. Only exact declared main/native File-frame filenames qualify; full other semantic bytes retain.')

"""Exact relative-command native proof replay at two real working roots."""
import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
from pathlib import Path

BASE = Path('docs/audits/record-value-clone-paths-20261004')
parser = argparse.ArgumentParser()
parser.add_argument('--record', action='store_true')
for flag in ('absolute-command', 'wrong-file', 'wrong-cause', 'root-echo'):
    parser.add_argument('--' + flag, action='store_true')
args = parser.parse_args()
binding = json.loads((BASE / 'binding.json').read_text())
transforms = json.loads((BASE / 'source-transform.json').read_text())
for name, row in transforms.items():
    text = Path(row['source']).read_text()
    for before, after in row['replacements']:
        assert text.count(before) == 1
        text = text.replace(before, after)
    assert text == (BASE / name).read_text(), 'exact full superseding reader/producer transform'
assert (BASE / 'native.py').read_bytes() == Path('docs/audits/record-value-clones-20261004/native.py').read_bytes()
controls = json.loads((BASE / 'controls.json').read_text())
if args.absolute_command:
    # Genuine original producer command, not an invented path defect.
    controls[0]['command'] = json.loads(Path('docs/audits/record-value-clones-20261004/controls.json').read_text())[0]['command']
for row in controls:
    assert not Path(row['command'][2]).is_absolute() and row['command'][2] == str(BASE / 'verify.py'), 'every stored control command is repository-relative and names the exact current reader'
    assert row['command'][:2] == ['python3', '-B'] and row['status'] == 1
frame = re.compile(r'(  File ")(.*)(", line [1-9][0-9]*, in [^\r\n]+)(\r?\n)?')
main, helper = str(BASE / 'verify.py'), str(BASE / 'native.py')


def identity(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def qualify(output, names):
    result = []
    for line in output.splitlines(keepends=True):
        match = frame.fullmatch(line)
        if match:
            assert match[2] in names, 'exact bound main/imported native module filename coordinate'
            line = match[1] + '${REPO_ROOT}/' + names[match[2]] + match[3] + (match[4] or '')
        result.append(line)
    return ''.join(result)


def historic(output):
    names = {}
    for line in output.splitlines(keepends=True):
        match = frame.fullmatch(line)
        if match:
            assert Path(match[2]).is_absolute()
            relative = next((name for name in (main, helper) if match[2].endswith('/' + name)), None)
            assert relative is not None
            names[match[2]] = relative
    return qualify(output, names)


documents = {row['path']: row['after'] for row in json.loads((BASE / 'doc-updates.json').read_text())} if (BASE / 'doc-updates.json').exists() else {}
packets, reached = [], False
for label in ('first', 'second'):
    fixture = Path('.artifacts/record-value-clone-paths-replay-20261004') / label
    for path, row in binding['sources'].items():
        destination = fixture / path
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_text(documents.get(path, row['body']))
    task_path = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
    (fixture / task_path).parent.mkdir(parents=True, exist_ok=True)
    (fixture / task_path).write_bytes(Path(task_path).read_bytes())
    for path in ('docs/audits', 'scripts'):
        link = fixture / path
        target = os.path.relpath(Path.cwd() / path, Path.cwd() / link.parent)
        if link.is_symlink():
            assert os.readlink(link) == target
        else:
            assert not link.exists()
            link.symlink_to(target, target_is_directory=True)
    inputs = {path: identity((fixture / path).read_bytes()) for path in binding['sources']}
    filenames = {str(Path.cwd() / fixture / main): main, str((Path.cwd() / fixture / helper).resolve()): helper}
    receipts = []
    for flag in (None, '--omit-call', '--alias-result', '--false-zero', '--joint-swap', '--wrong-kind'):
        command = ['python3', '-B', main] + ([flag] if flag else [])
        run = subprocess.run(command, cwd=fixture, text=True, capture_output=True)
        raw = run.stdout + run.stderr
        assert run.returncode == (1 if flag else 0), raw
        if flag and not reached:
            if args.wrong_file:
                raw = raw.replace(str(Path.cwd() / fixture / main), str(Path.cwd() / fixture / main) + '.other-program', 1)
            if args.wrong_cause:
                raw = raw.replace('AssertionError:', 'AssertionError: wrong semantic cause ', 1)
            if args.root_echo:
                raw += 'AssertionError: quoted argument retains ' + str(Path.cwd()) + '/native-wanted-cause\n'
            reached = any((args.wrong_file, args.wrong_cause, args.root_echo))
        output = qualify(raw, filenames)
        if flag:
            prior = next(row for row in controls if row['command'] == command)
            assert output == historic(prior['output']), 'complete actual semantic/control output beyond only exact program filenames'
        receipts.append({'command': command, 'working_directory': str(fixture), 'inputs': inputs, 'status': run.returncode, 'output': output, 'programs': {path: identity(Path(path).read_bytes()) for path in (main, helper)}})
    packets.append({'working_root': str(fixture), 'receipts': receipts})
assert not any((args.wrong_file, args.wrong_cause, args.root_echo)) or reached
packet = {'python': sys.version, 'source_revision': binding['revision'], 'roots': packets}
if args.record:
    assert not any((args.absolute_command, args.wrong_file, args.wrong_cause, args.root_echo))
    (BASE / 'portability-replays.json').write_text(json.dumps(packet, sort_keys=True, indent=2) + '\n')
else:
    assert packet == json.loads((BASE / 'portability-replays.json').read_text()), 'whole two-root source/doc/input/program/profile/native semantic/control receipt identity'
print('PASS exact relative commands and complete native clone proof at two actual working roots: two ordinary/all ten RED readers, full native reexecutions and21 exact inputs. Main/imported module File-frame coordinates alone qualify; every other semantic/root-bearing byte retains. Root/tree models and permanent consumer/native cause assurance remain open.')

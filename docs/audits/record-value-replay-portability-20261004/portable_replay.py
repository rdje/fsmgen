"""Exact semantic replay; qualify only each bound Python process filename."""
import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
from pathlib import Path

BASE = Path(__file__).parent
ROOT = Path.cwd()
parser = argparse.ArgumentParser()
parser.add_argument('--check', action='store_true')
parser.add_argument('--corrupt-message', action='store_true')
parser.add_argument('--swap-file-coordinate', action='store_true')
parser.add_argument('--root-echo', action='store_true')
args = parser.parse_args()
binding = json.loads((BASE / 'binding.json').read_text())
legacy = json.loads(Path('docs/audits/record-value-field-join-20261004/child-replays.json').read_text())
legacy_join = json.loads(Path('docs/audits/record-value-field-join-20261004/join.json').read_text())
assert set(legacy_join['sources']) == set(binding['sources'])
for path, row in legacy_join['sources'].items():
    if path not in ('docs/knowledge/isf-aggregate-port-request-baseline.md', 'docs/book/src/13k-isf-feature-support-matrix.md'):
        assert row['body'] == binding['sources'][path]['body'], 'unchanged complete old/current implementation input'

def frames(output):
    return [match for line in output.splitlines(keepends=True)
        if (match := re.fullmatch(r'(  File ")(.*)(", line [1-9][0-9]*, in [^\r\n]+)(\r?\n)?', line))]

def qualified(output, filename, relative):
    # A filename is a process coordinate, never a substring found in a cause,
    # quoted argument, source line or native error. All other bytes remain exact.
    result = []
    for line in output.splitlines(keepends=True):
        match = re.fullmatch(r'(  File ")(.*)(", line [1-9][0-9]*, in [^\r\n]+)(\r?\n)?', line)
        if match:
            assert match[2] == filename, 'exact bound reader process filename coordinate'
            line = match[1] + '${REPO_ROOT}/' + relative + match[3] + (match[4] or '')
        result.append(line)
    return ''.join(result)

def historical(output, relative):
    known = frames(output)
    if not known:
        return output
    suffix = '/' + relative
    filenames = {match[2] for match in known}
    assert len(filenames) == 1
    filename = next(iter(filenames))
    assert filename.endswith(suffix) and Path(filename).is_absolute()
    return qualified(output, filename, relative)

specifications = [
    ('record-value-fields-20261004', ['--omit-type', '--swap-order', '--trust-private-product']),
    ('record-value-copy-fields-20261004', ['--omit-field', '--swap-source-role', '--trust-private-product', '--swap-malformed-model']),
    ('record-value-actors-20261004', ['--omit-product', '--swap-source-role', '--trust-private-product', '--numeric-source-tokens', '--omit-default-family']),
]
results = []
changed = False
for archive, flags in specifications:
    directory = Path('docs/audits') / archive
    fixture = Path('.artifacts/record-value-field-join-replay-20261004') / archive
    fixture.mkdir(parents=True, exist_ok=True)
    source_boundary = binding if archive == 'record-value-actors-20261004' else legacy_join
    for path, row in source_boundary['sources'].items():
        target = fixture / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(row['body'])
    historical_docs = {}
    if (directory / 'card-after.txt').exists():
        historical_docs['docs/knowledge/isf-aggregate-port-request-baseline.md'] = (directory / 'card-after.txt').read_text()
    if (directory / 'doc-updates.json').exists():
        historical_docs.update({row['path']: row['after'] for row in json.loads((directory / 'doc-updates.json').read_text())})
    for path, body in historical_docs.items():
        (fixture / path).write_text(body)
    link = fixture / 'docs/audits'
    expected_link = os.path.relpath(ROOT / 'docs/audits', ROOT / fixture / 'docs')
    if link.is_symlink():
        assert os.readlink(link) == expected_link
    else:
        assert not link.exists()
        link.symlink_to(expected_link, target_is_directory=True)
    inputs = {}
    for path, row in source_boundary['sources'].items():
        raw = (fixture / path).read_bytes()
        assert raw == historical_docs.get(path, row['body']).encode()
        inputs[path] = {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest(),
            'boundary': 'sealed document after-image' if path in historical_docs else 'current committed source'}
    for flag in [None] + flags:
        command = ['python3', '-B', str(directory / 'verify.py')] + ([flag] if flag else [])
        run = subprocess.run(command, cwd=fixture, text=True, capture_output=True)
        assert run.returncode == (1 if flag else 0), run.stdout + run.stderr
        relative = str(fixture / directory / 'verify.py')
        filename = str(ROOT / relative)
        raw_output = run.stdout + run.stderr
        if flag and not changed:
            if args.corrupt_message:
                raw_output = raw_output.replace('AssertionError:', 'AssertionError: wrong semantic cause ', 1)
            if args.swap_file_coordinate:
                raw_output = raw_output.replace(filename, filename + '.different-script', 1)
            if args.root_echo:
                raw_output += 'AssertionError: quoted argument contains ' + str(ROOT) + '/native-wanted-cause\n'
            changed = True
        output = qualified(raw_output, filename, relative)
        if archive != 'record-value-actors-20261004':
            previous = next(row for row in legacy if row['archive'] == archive and row['command'] == command)
            assert previous['status'] == run.returncode and previous['working_directory'] == str(fixture)
            assert previous['inputs'] == inputs
            assert output == historical(previous['output'], relative), 'full immutable semantic output beyond exact process coordinate'
        receipt = {'archive': archive, 'command': command, 'working_directory': str(fixture),
            'inputs': inputs, 'status': run.returncode, 'output': output,
            'source_capture_revision': source_boundary['revision'],
            'process_filename': '${REPO_ROOT}/' + relative}
        results.append(receipt)
        print(archive, flag or 'ordinary', run.returncode)
profile = {'python': sys.version,
    'child_python': subprocess.check_output(['python3', '-c', 'import sys; print(sys.version)']).decode()}
packet = {'profile': profile, 'receipts': results}
if args.check:
    assert packet == json.loads((BASE / 'portable-replays.json').read_text()), 'complete portable source/program/profile/input/output/semantic receipt identity'
else:
    assert not (args.corrupt_message or args.swap_file_coordinate or args.root_echo)
    (BASE / 'portable-replays.json').write_text(json.dumps(packet, sort_keys=True, indent=2) + '\n')
print('PASS three full semantic readers and all twelve RED controls; exact complete legacy outputs conserve beyond bound process filename coordinates. Current source/input/kind/error semantics remain unchanged.')

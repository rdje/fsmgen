"""Authenticate original candidate observations; no independent semantics signoff."""
import base64
import copy
import hashlib
import json
import re
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-original-candidate-20261004')
INPUTS = Path('docs/audits/record-value-copy-inputs-20261004')
PROBES = Path('docs/audits/record-value-copy-probes-20261004')
PREFIX = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.'
MODES = ('ordinary', 'storable', 'alias', 'controls')


def require(condition, message):
    if not condition:
        raise ValueError(message)


def identity(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def load(path):
    return json.loads(path.read_text())


def native_bytes(row):
    return row['body'].encode() if 'body' in row else base64.b64decode(row['body_b64'], validate=True)


def equal(left, right):
    return json.dumps(left, sort_keys=True, separators=(',', ':')) == json.dumps(right, sort_keys=True, separators=(',', ':'))


def sealed(path):
    manifest = load(path / 'manifest.json')
    require({p.name for p in path.iterdir()} == set(manifest) | {'manifest.json'}, 'whole archive membership')
    for name, expected in manifest.items():
        require(identity((path / name).read_bytes()) == expected, 'whole sealed identity: ' + str(path / name))
    return manifest


def authenticate():
    binding = load(BASE / 'binding.json')
    for path, expected in binding['archives'].items():
        require(equal(sealed(Path(path)), expected), 'prerequisite archive identity')
    original = load(INPUTS / 'binding.json')
    require(equal(binding['sources'], original['sources']) and binding['original_revision'] == original['revision'], 'whole original source authority')
    pin = load(Path('docs/audits/record-value-original-replay-20261004/binding.json'))
    require(set(binding['runtime']) == set(pin['runtime']), 'complete own runtime population')
    for group in ('sources', 'runtime', 'support'):
        revision = binding['original_revision'] if group == 'sources' else binding['revision']
        for path, row in binding[group].items():
            raw = native_bytes(row)
            require(identity(raw) == {k: row[k] for k in ('bytes', 'sha256')}, 'whole source body identity')
            require(raw == subprocess.check_output(['git', 'show', revision + ':' + path]), 'full Git source authority: ' + path)
            if group == 'runtime' or (group == 'sources' and path.startswith(('perl/', 't/'))):
                require(Path(path).read_bytes() == raw, 'unchanged current test/runtime: ' + path)
            if group == 'runtime':
                require(identity(raw) == pin['runtime'][path], 'original whole runtime authority')
    support_paths = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', binding['revision'], '--', 'bin', 'specs', 'plugin'], text=True).splitlines()
    require(set(binding['support']) == {'README.md', *support_paths}, 'complete published capsule resources')
    task = subprocess.check_output(['git', 'show', binding['revision'] + ':' + binding['task_path']], text=True)
    require(task == binding['task_body'], 'complete dated task authority')
    require([r['id'] for r in binding['owners']] == [PREFIX + '2.1', PREFIX + '2.2', PREFIX + '2.3.1'], 'complete done owner membership')
    for row in binding['owners']:
        start = task.index('- ID: `' + row['id'] + '`')
        end = task.index('\n- ID:', start + 1)
        require(task[start:end] == row['body'] and '\n  Status: `done`\n' in row['body'], 'whole completed owner authority')
    transform = load(BASE / 'observer-transform.json')
    original_observer = subprocess.check_output(['git', 'show', binding['revision'] + ':' + transform['source_path']], text=True)
    require(transform['before'] == original_observer, 'exact native observer authority')
    body = original_observer
    for before, after in transform['replacements']:
        require(body.count(before) == 1, 'exact observer transform member')
        body = body.replace(before, after)
    require(body == transform['after'] == (BASE / 'observe.pl').read_text(), 'complete observer transformation')
    require((BASE / 'candidate.pl').read_bytes() == (PROBES / 'candidate.pl').read_bytes(), 'exact qualified candidate source')
    book = load(BASE / 'book-transform.json')
    before = subprocess.check_output(['git', 'show', book['revision'] + ':' + book['path']], text=True)
    require(before == book['before'], 'whole original book source')
    for old, new in book['replacements']:
        require(before.count(old) == 1, 'exact book replacement')
        before = before.replace(old, new)
    require(before == book['after'], 'complete book transformation')
    card = load(BASE / 'card-transform.json')
    require(subprocess.check_output(['git', 'show', card['revision'] + ':' + card['path']], text=True) == card['before'], 'whole original card source')
    require(card['after'] != card['before'], 'card update recorded')
    if (BASE / 'manifest.json').exists():
        sealed(BASE)
    return binding


def check_products(execution, records, binding):
    require([r['mode'] for r in execution['modes']] == list(MODES), 'whole native mode population')
    require(execution['programs'] == {name: {'body': (BASE / name).read_text(), **identity((BASE / name).read_bytes())} for name in ('observe.pl', 'candidate.pl')}, 'whole executed program identity')
    require(execution['producer'] == {'body': (BASE / 'capture.py').read_text(), **identity((BASE / 'capture.py').read_bytes())}, 'whole executed capture producer')
    original = load(INPUTS / 'inputs.json')['rows']
    original_indices = [r['index'] for r in original]
    expected = {'ordinary': (0, 9283, 697, 43, 125, 4, 68, 0),
                'storable': (4, 9283, 697, 43, 125, 4, 68, 15),
                'alias': (25, 7683, 557, 39, 117, 2, 68, 17),
                'controls': (5, 9283, 697, 43, 125, 4, 204, 32)}
    summaries = []
    for receipt in execution['modes']:
        mode = receipt['mode']
        data = records[mode]
        raw = (BASE / (mode + '.json')).read_bytes()
        require(receipt['record_identity'] == identity(raw), 'whole native record identity')
        require(receipt['command'] == ['perl', str(BASE / 'observe.pl'), mode, str(BASE / (mode + '.json'))], 'actual native command')
        require(receipt['same_volume'] is True and receipt['captured'] is True, 'captured same-volume mode')
        require(re.fullmatch(r'\.artifacts/record-value-original-candidate-20261004/' + mode + '-[a-z0-9_]+', receipt['fixture']) is not None, 'relative native fixture')
        sources = {**binding['runtime'], **binding['sources'], **binding['support'], **{str(BASE / n): r for n, r in execution['programs'].items()}}
        require(receipt['sources_before'] == receipt['sources_after'] == {p: identity(native_bytes(r)) for p, r in sources.items()}, 'whole fixture before/after source identity')
        status, *counts, failed = expected[mode]
        require(type(receipt['status']) is int and receipt['status'] == status, 'actual mode native status')
        require(data['mode'] == mode and len(data['warnings']) == 0, 'mode/warning capture')
        require(equal(data['host'], load(Path('docs/audits/record-value-runtime-20261004/ordinary.json'))['host']), 'whole observed native host profile')
        require([len(data[k]) for k in ('api', 'copies', 'helpers', 'consumers', 'parses', 'copy_assertions')] == counts, 'complete captured native population')
        require(sum(r['passed'] == 0 for r in data['copy_assertions']) == failed, 'actual copy assertion failures')
        test_copies = [(i, r) for i, r in enumerate(data['copies']) if r['kind'] == 'test']
        require(len(test_copies) == len(original) == 17, 'whole original copy site membership')
        for ordinal, ((index, row), old) in enumerate(zip(test_copies, original)):
            require(row['caller'] == old['native']['caller'] and row['accepted'] == 1, 'actual original copy caller')
            if mode != 'alias':
                require(index == old['index'] and equal(row['before'], old['native']['before']), 'unchanged complete original input')
            require(equal(row['before'], row['after']), 'copy input afterimage observation')
            require(row['assertion_end'] - row['assertion_start'] == (12 if mode == 'controls' else 4), 'actual assertion bounds')
            assertions = data['copy_assertions'][row['assertion_start']:row['assertion_end']]
            require(all(r['copy'] == index for r in assertions), 'copy assertion allocation')
            require(row['candidate_calls'] > 0 and type(row['candidate_calls']) is int, 'actual complete candidate recursion count')
            require(row['joint_input_result'] is not None, 'whole actual input/result joint graph captured')
        if mode == 'alias':
            differences = [ordinal for ordinal, ((_, row), old) in enumerate(zip(test_copies, original)) if not equal(row['before'], old['native']['before'])]
            require(differences == [6, 7, 8, 9, 10, 11, 12, 13, 15, 16], 'whole alias downstream input differences retained')
            require(data['test_run']['completed'] == 0 and data['test_run']['error'].startswith("Invalid ISF record value: root 'held' has invalid resolved type:"), 'actual alias abort boundary')
            require(data['test_run']['error'] in receipt['stderr'] and 'done_testing() was not seen' in receipt['stderr'], 'whole raw abort stream')
        else:
            require(data['test_run']['completed'] == 1 and data['test_run']['error'] == '', 'complete original test execution')
            require(all(r['passed'] == 1 for r in data['consumers']), 'original consumer observations retain green')
            require('\n1..10\n' in receipt['stdout'], 'complete original top-level TAP plan')
        if mode == 'controls':
            require(len(data['trials']) == 34, 'each original input receives both actual providers')
            for ordinal, old in enumerate(original):
                for trial, provider in zip(data['trials'][2 * ordinal:2 * ordinal + 2], ('storable', 'alias')):
                    require(trial['provider'] == provider and trial['copy'] == old['index'] and trial['caller'] == old['native']['caller'], 'whole original bad-provider trial identity')
                    require(equal(trial['before'], old['native']['before']) and equal(trial['after'], old['native']['before']), 'genuine unchanged original trial input')
                    require(trial['assertion_end'] - trial['assertion_start'] == 4 and trial['candidate_calls'] > 0 and trial['joint'] is not None, 'full native trial products captured')
        else:
            require(data['trials'] == [], 'whole trial population')
        summaries.append({'mode': mode, 'status': status, 'counts': dict(zip(('api', 'copies', 'helpers', 'consumers', 'parses', 'copy_assertions'), counts)), 'failed_copy_assertions': failed, 'test_completed': data['test_run']['completed'], 'original_input_indices': [i for i, _ in test_copies]})
    return summaries


def main():
    binding = authenticate()
    execution = load(BASE / 'execution.json')
    records = {m: load(BASE / (m + '.json')) for m in MODES}
    summaries = check_products(execution, records, binding)
    print('PASS full original-source capture membership/program/source/fixture/host/TAP/status and genuine provider observations. Alias downstream mutation/abort is retained; independent graph/source/product qualification and replay remain pending.')
    return summaries


if __name__ == '__main__':
    main()

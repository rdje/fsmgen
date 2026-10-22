#!/usr/bin/env python3
"""Capture fixed source-only parser/native products, or verify both saved epochs.

Run from the repository root, under scripts/run_with_ram_guard.sh.
Before/after inputs are emitted by the unchanged T2097 regression; no HDL runs.
"""
import argparse
import copy
import gzip
import hashlib
import json
from pathlib import Path
import subprocess

BASE = Path('.artifacts/nested-normalization-20261022/qualified')
OUTPUT = Path('docs/audits')
ADAPTER = 'perl/FSM/Adapter/ISF/LispishAdapter.pm'
RECIPE = 'docs/audits/nested-normalization-qualification-20261022.py'
TESTS = ('t/1092-isf-lispish-adapter.t', 't/2097-isf-nested-aggregate-normalization.t')
CASES = ('literal', 'named', 'scalar_control', 'list_control')


def require(condition, message):
    if not condition:
        raise ValueError(message)


def identity(path):
    data = Path(path).read_bytes()
    return {'sha256': hashlib.sha256(data).hexdigest(), 'text': data.decode()}


def capture(epoch):
    record = {'owner': 'ISF-REDUCTION-DELIVERY.2.3.2.1.2.2', 'epoch': epoch,
              'baseline_revision': subprocess.check_output(['git', 'rev-parse', 'HEAD']).decode().strip(),
              'inputs': {p: identity(p) for p in (ADAPTER, *TESTS, RECIPE)},
              'scope': 'Fixed source-only parser/lowering/report/native products; no HDL or new private source records.',
              'cases': {}, 'log': identity(BASE / ('red-qualified.log' if epoch == 'before' else 'green.log'))}
    work = BASE / 'native'
    work.mkdir(exist_ok=True)
    package = '(?pkg:shared (+constants (LIMIT 16)))'
    (work / 'shared.fsm').write_text(package)
    root = str(Path.cwd().resolve())
    for name in CASES:
        row = json.loads((BASE / epoch / (name + '.json')).read_text())
        path = work / (name + '.isf')
        if path.exists():
            require(path.read_text() == row['source'], 'fixed source changed: ' + name)
        else:
            path.write_text(row['source'])
        row['native'] = {}
        for mode, flags in (('check', ['--check', '--json']), ('semantic', ['--emit-semantic-json']),
                            ('schedule', ['--emit-schedule-json'])):
            command = ['./bin/fsmgen', '--quiet', '--strict', *flags, str(path)]
            result = subprocess.run(command, capture_output=True, timeout=60)
            row['native'][mode] = {'command': command, 'exit': result.returncode,
                **{key: {'raw_sha256': hashlib.sha256(value).hexdigest(),
                          'text': value.decode().replace(root, '<repo>')}
                   for key, value in (('stdout', result.stdout), ('stderr', result.stderr))}}
            require(result.returncode == 0, f'{name}/{mode}: native refusal')
            json.loads(row['native'][mode]['stdout']['text'])
        record['cases'][name] = row
    target = OUTPUT / f'nested-normalization-{epoch}-20261022.json.gz'
    with target.open('xb') as stream:
        with gzip.GzipFile(fileobj=stream, mode='wb', mtime=0) as packed:
            packed.write((json.dumps(record, sort_keys=True, indent=2) + '\n').encode())
    print('captured', epoch, 'source-only epoch')


def validate(before, after):
    require(before['epoch'] == 'before' and after['epoch'] == 'after', 'epoch identity')
    require(before['baseline_revision'] == after['baseline_revision'], 'baseline revision changed')
    require('Result: FAIL' in before['log']['text'] and 'Result: PASS' in after['log']['text'], 'RED/GREEN outcomes')
    for path in (*TESTS, RECIPE):
        require(before['inputs'][path] == after['inputs'][path], 'regression/recipe changed between epochs')
    for record in (before, after):
        require(set(record['cases']) == set(CASES), 'case membership')
        for value in record['inputs'].values():
            require(hashlib.sha256(value['text'].encode()).hexdigest() == value['sha256'], 'input identity')
        for row in record['cases'].values():
            require(row['caller_unchanged'] == 1, 'caller kinds changed')
            for native in row['native'].values():
                require(native['exit'] == 0, 'native result')
                json.loads(native['stdout']['text'])
    original = subprocess.check_output(['git', 'show', before['baseline_revision'] + ':' + ADAPTER]).decode()
    require(original == before['inputs'][ADAPTER]['text'], 'original adapter is not baseline Git')
    for name in ('scalar_control', 'list_control'):
        require(before['cases'][name] == after['cases'][name], 'complete scalar/list control changed: ' + name)
    for name, default, override in (
        ('literal', [['16', '17'], ['18', '19']], [['20', '21'], ['22', '23']]),
        ('named', [['16', '16'], ['16', '16']], [['16', '16'], [16, '16']]),
    ):
        old, new = before['cases'][name], after['cases'][name]
        require(old['source'] == new['source'], 'nested source changed')
        for child in new['actor']['library_uses']:
            require(child['actor']['params'][2]['value'] == default, 'literal default shape')
        for key in ('uses', 'library_uses'):
            value = new['actor'][key][0]['parameter_overrides'][0]['value']
            require(json.dumps(value) == json.dumps(override), 'override shape or primitive kind')
            old_value = old['actor'][key][0]['parameter_overrides'][0]['value']
            require(old_value != value and old_value[0][1] == [value[0][1]], 'original first-head defect absent')


parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('action', choices=('before', 'after', 'verify'))
args = parser.parse_args()
if args.action != 'verify':
    capture(args.action)
else:
    epochs = [json.loads(gzip.decompress((OUTPUT / f'nested-normalization-{e}-20261022.json.gz').read_bytes()))
              for e in ('before', 'after')]
    validate(*epochs)
    for mutation in ('shape', 'kind', 'caller', 'membership', 'test', 'control'):
        bad = copy.deepcopy(epochs)
        new = bad[1]
        if mutation == 'shape':
            new['cases']['literal']['actor']['library_uses'][1]['actor']['params'][2]['value'] = []
        elif mutation == 'kind':
            new['cases']['named']['actor']['uses'][0]['parameter_overrides'][0]['value'][1][0] = '16'
        elif mutation == 'caller':
            new['cases']['literal']['caller_unchanged'] = 0
        elif mutation == 'membership':
            del new['cases']['named']
        elif mutation == 'test':
            new['inputs'][TESTS[0]]['text'] += '\n'
        else:
            new['cases']['scalar_control']['native']['check']['exit'] = 1
        try:
            validate(*bad)
        except (ValueError, KeyError):
            continue
        raise ValueError('hostile saved control accepted: ' + mutation)
    print('nested normalization qualification: PASS; saved shape/kind/caller/membership/test/control mutations rejected')

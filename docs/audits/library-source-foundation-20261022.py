#!/usr/bin/env python3
"""Seal/reverify the private source prerequisite without replaying workloads."""
import ast
import copy
import gzip
import hashlib
import json
import os
from pathlib import Path
import runpy
import sys

ROOT = Path(__file__).resolve().parents[2]
os.chdir(ROOT)
RECIPE = 'docs/audits/library-source-foundation-20261022.py'
CAPTURE = 'docs/audits/library-source-retention-20261022.py'
PARSER = 'perl/FSM/Adapter/ISF/Parser.pm'
OUTPUT = Path('docs/audits/library-source-foundation-20261022.json.gz')
WORK = Path('.artifacts/library-source-retention-qualified-20261022')
INPUTS = (RECIPE, CAPTURE, PARSER, 't/2098-isf-authored-library-override-sources.t',
          'docs/audits/library-source-qualification-20261022.py',
          'docs/audits/library-source-public-20261022.pl',
          'docs/audits/library-source-interruption-20261022.py',
          'docs/audits/library-source-timeout-control-20261022.py')
LOGS = ('.artifacts/library-sources-red-initial.log', '.artifacts/library-sources-red-initial-admitted.log',
        '.artifacts/library-source-retention-before.log', '.artifacts/library-source-size-preflight.log',
        '.artifacts/library-source-size-current.log', '.artifacts/library-source-book-build.log',
        '.artifacts/library-source-retention-after.log', '.artifacts/library-source-interruption-20261022.log',
        '.artifacts/library-source-timeout-control-20261022.log', '.artifacts/library-source-public-syntax.log')


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def unpack(path):
    return json.loads(gzip.decompress(Path(path).read_bytes()))


def require(ok, message):
    if not ok:
        raise ValueError(message)


def run_ast(text):
    return ast.dump(next(node for node in ast.parse(text).body if isinstance(node, ast.FunctionDef) and node.name == 'run'))


def validate(record):
    require(record['owner'] == 'ISF-REDUCTION-DELIVERY.2.3.2.1.2.3.1', 'owner')
    for path, value in record['inputs'].items():
        require(sha(value['text'].encode()) == value['sha256'], 'stored input digest: ' + path)
    capture = runpy.run_path(CAPTURE)
    before, after = capture['qualification_pair']()
    capture['validate'](before, after)
    require(record['qualification_join'] == after['_qualification_join'], 'interrupted boundary')
    focus = record['focus_capture']
    require(focus['inputs'][PARSER]['sha256'] == after['inputs'][PARSER]['sha256'], 'focus/parser identity')
    require(record['inputs'][PARSER]['sha256'] == after['inputs'][PARSER]['sha256'], 'sealed/parser identity')
    require(set(focus['results']) == {'focused', 'book_tasks', 'syntax'}, 'focus membership')
    for name, row in focus['results'].items():
        require(row['exit'] == 0, 'focus result: ' + name)
        if name != 'syntax':
            require('All tests successful.' in row['stdout']['text'], 'missing successful TAP')
    for path, value in focus['inputs'].items():
        require(sha(value['text'].encode()) == value['sha256'], 'focus input digest')
        # The old focus instrument is retained in full. Later orchestration
        # edits do not change the held product/test inputs or observed argv.
        if path in record['inputs'] and path != 'docs/audits/library-source-qualification-20261022.py':
            require(value == record['inputs'][path], 'focus product/test changed')
    commands = runpy.run_path('docs/audits/library-source-qualification-20261022.py')['FOCUS_COMMANDS']
    require(all(focus['results'][name]['argv'] == argv for name, argv in commands.items()), 'focus invocation changed')
    initial = unpack('docs/audits/library-source-retention-initial-20261022.json.gz')
    require(set(record['initial_private']) == set(before['cases']), 'first private completeness')
    for name, row in initial['cases'].items():
        require(record['initial_private'][name] == row['private'], 'first private join')
    control = unpack('docs/audits/library-source-timeout-control-20261022.json.gz')
    require(control.get('qualified') is True and 'error' not in control, 'timeout unit control')
    require(run_ast(control['after']['text']) == run_ast(record['inputs'][CAPTURE]['text']), 'tested capture function changed')
    require(sha(record['public_package']['text'].encode()) == record['public_package']['sha256'], 'package input identity')


def seal():
    _, after = runpy.run_path(CAPTURE)['qualification_pair']()
    package = (WORK / 'shared.fsm').read_bytes()
    record = {'schema_version': 1, 'owner': 'ISF-REDUCTION-DELIVERY.2.3.2.1.2.3.1',
              'inputs': {p: {'text': Path(p).read_text(), 'sha256': sha(Path(p).read_bytes())} for p in INPUTS},
              'focus_capture': json.loads(Path('.artifacts/library-source-focused-20261022.json').read_bytes()),
              'qualification_join': after['_qualification_join'],
              'initial_private': {p.stem: json.loads(p.read_bytes()) for p in
                                  Path('.artifacts/library-source-retention-20261022/before').glob('*.json')},
              'initial_attempts': {p: Path(p).read_text().replace(str(ROOT), '<repo>') for p in LOGS},
              'initial_sealer': {'text': Path('.artifacts/library-source-foundation-initial-sealer.py').read_text(),
                                 'failure': Path('.artifacts/library-source-foundation-seal.log').read_text().replace(str(ROOT), '<repo>')},
              'public_package': {'text': package.decode(), 'sha256': sha(package)},
              'limits': 'Historical private source qualification with an explicit interrupted/native-stage join. Focused tests retain their original instrument and inputs. All first private snapshots and available failures remain; exact failed-draft documentation bytes, original timeout partial streams, complete transitive footprints and raw-root stream reconstruction are absent. Queued shell observations lack process-bound timings; they do not establish causality. API/newline and generic HDL closure are separate. No source/HDL workload is replayed by this sealer/verifier.'}
    validate(record)
    with OUTPUT.open('xb') as stream:
        with gzip.GzipFile(fileobj=stream, mode='wb', mtime=0) as compressed:
            compressed.write((json.dumps(record, sort_keys=True, indent=2) + '\n').encode())
    print('private source foundation sealed')


def verify():
    record = unpack(OUTPUT)
    validate(record)
    for mutation in ('focus', 'membership', 'input'):
        bad = copy.deepcopy(record)
        if mutation == 'focus':
            bad['focus_capture']['results']['focused']['exit'] = 1
        elif mutation == 'membership':
            bad['initial_private'].pop('defaults')
        else:
            bad['inputs'][PARSER]['sha256'] = '0' * 64
        try:
            validate(bad)
        except (ValueError, KeyError):
            continue
        raise ValueError('hostile foundation control accepted: ' + mutation)
    print('private source foundation: PASS; hostile saved controls rejected')


if __name__ == '__main__':
    if sys.argv[1:] == ['seal']:
        seal()
    elif sys.argv[1:] == ['verify']:
        verify()
    else:
        raise SystemExit('usage: library-source-foundation-20261022.py seal|verify')

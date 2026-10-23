#!/usr/bin/env python3
"""Frozen generated-width constructor products; replay reads saved evidence only."""
import copy
import gzip
import json
import os
from pathlib import Path
import runpy
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
os.chdir(ROOT)
BASE = 'docs/audits/width-ir-qualification-20261023.py'
base = runpy.run_path(BASE)
capture, sha, typed, require, normalized = [base[k] for k in ('capture', 'sha', 'typed', 'require', 'normalized')]
PREFIX = 'docs/audits/generated-width-ir-'
SELF = PREFIX + '20261023.py'
PUBLIC = PREFIX + 'public-20261023.pl'
TEST = 't/2101-isf-generated-width-ir.t'
CASES = ('generated', 'plain')
INPUTS = ['t/data/isf-generated-width-ir/' + name + '.isf' for name in CASES]
SOURCES = [SELF, BASE, PUBLIC, TEST, 't/lib/FSM/Test/GeneratedWidthIR.pm',
           'perl/FSM/Support/ISFWidthDeclarations.pm', 'perl/FSM/Scheduler/ISF/LoweringIR.pm']
KEYS = ('_width_declarations', '_width_scopes', '_width_static_uses')


def path(epoch):
    require(epoch in ('before', 'after'), 'unknown epoch')
    return Path(PREFIX + epoch + '-20261023.json.gz')


def save(target, value):
    with target.open('xb') as stream:
        stream.write(gzip.compress((json.dumps(value, sort_keys=True, indent=2) + '\n').encode(), mtime=0))


def read(epoch):
    return json.loads(gzip.decompress(path(epoch).read_bytes()))


def checked(row):
    require(type(row['exit']) is int and row['exit'] == 0, 'command failed')
    require(row['stderr']['text'] == '', 'unexpected diagnostic')
    return row['stdout']['text']


def epoch(name):
    packet = {'owner': 'ISF-REDUCTION-DELIVERY.2.3.2.4.1', 'epoch': name,
              'revision': subprocess.check_output(['git', 'rev-parse', 'HEAD']).decode().strip(),
              'sources': {p: {'text': Path(p).read_text(), 'sha256': sha(Path(p).read_bytes())}
                          for p in INPUTS + SOURCES}, 'native': {}, 'qualified': False,
              'limits': 'Complete selected constructor/source/carrier/native/public observations only. '
                        'Transitive loaded-source census, raw-root reconstruction, generic HDL/runtime, '
                        'library/domain closure and historical interruption attribution remain missing.'}
    try:
        packet['private'] = capture(['perl', '-Iperl', '-It/lib', '-MJSON::PP',
            '-MFSM::Test::GeneratedWidthIR=generated_width_products', '-e',
            'print JSON::PP->new->canonical->encode(generated_width_products()),"\n"'])
        checked(packet['private'])
        if name == 'before':
            packet['first_red'] = Path('.artifacts/generated-width-first-20261023.log').read_text()
        for case in CASES:
            packet['native'][case] = {}
            for kind, flags in [('check', ['--check', '--json']), ('semantic', ['--emit-semantic-json']),
                                ('schedule', ['--emit-schedule-json'])]:
                row = capture(['perl', 'bin/fsmgen', '--quiet', '--strict', *flags,
                               't/data/isf-generated-width-ir/' + case + '.isf'], timeout=60)
                packet['native'][case][kind] = row
                checked(row)
        if name == 'after':
            native = {case: {kind: normalized(json.loads(checked(row))) for kind, row in values.items()}
                      for case, values in packet['native'].items()}
            packet['public'] = capture(['perl', '-Iperl', PUBLIC], json.dumps(native).encode())
            checked(packet['public'])
        packet['qualified'] = True
    except Exception as error:
        packet['error'] = str(error)
    finally:
        packet['sources_after'] = {p: sha(Path(p).read_bytes()) for p in INPUTS + SOURCES}
        save(path(name), packet)
    require(packet['qualified'], packet.get('error', 'epoch failed'))
    print(name + ': complete selected products retained')


def formal(tx, name, direction, token, kind, owner):
    return {'scope': {'kind': 'transaction', 'actor': 'generated_width_ir', 'owner': tx},
            'source': {'token': token, 'kind': kind, 'owner': owner},
            'declaration': {'kind': 'transaction_port', 'name': name, 'direction': direction,
                            'identity': ['transaction_port', 'generated_width_ir', tx, name]}}


def oracle(products):
    owner = 'generated_width_ir'
    child = products['generated']['ir']['children']['worker']
    expected = {}
    for name, token, kind, lexical in [
        ('payload', 'ACTOR_ALIAS', 'actor_parameter', owner), ('data', 'W', 'transaction_parameter', 'worker'),
        ('unused_formal', 'ALIAS', 'transaction_parameter', 'worker'),
        ('saved', 'OTHER', 'transaction_parameter', 'worker'), ('fixed', 'FIXED', 'actor_constant', owner),
        ('response', 'ALIAS', 'transaction_parameter', 'worker'),
        ('inherited', 'ACTOR_ALIAS', 'actor_parameter', owner),
        ('from_storage', 'ACTOR_ALIAS', 'actor_parameter', owner)]:
        expected[name] = formal('worker', name, 'output' if name in ('response', 'inherited', 'from_storage') else 'input', token, kind, lexical)
    for name in ('pin',):
        expected[name] = {'scope': {'kind': 'actor', 'owner': owner},
            'source': {'token': 'W', 'kind': 'actor_parameter', 'owner': owner},
            'declaration': {'kind': 'interface', 'name': name, 'direction': 'input' if name == 'pin' else 'output'}}
    expected['stored'] = {'scope': {'kind': 'actor', 'owner': owner},
        'source': {'token': 'ACTOR_ALIAS', 'kind': 'actor_parameter', 'owner': owner},
        'declaration': {'kind': 'storage', 'storage_kind': 'var', 'name': 'stored'}}
    require(typed(child['_width_declarations']) == typed(expected), 'whole worker source association')
    require(typed(child['_width_scopes']['actor']['params']) == typed([
        {'name': 'W', 'value': '8'}, {'name': 'ACTOR_ALIAS', 'value': 'W', 'resolved_value': '8'},
        {'name': 'OTHER', 'value': '8'}]), 'actor lexical environment')
    require(typed(child['_width_scopes']['transactions']) == typed({'worker': {
        'actor': owner, 'owner': 'worker', 'params': [{'name': 'W', 'value': '4'},
        {'name': 'ALIAS', 'value': 'W', 'resolved_value': '4'}, {'name': 'OTHER', 'value': '4'}]}}),
        'selected transaction environment')
    sibling = products['generated']['ir']['children']['sibling']
    require(typed(sibling['_width_declarations']) == typed({
        'data': formal('sibling', 'data', 'input', 'ALIAS', 'transaction_parameter', 'sibling'),
        'response': formal('sibling', 'response', 'output', 'W', 'transaction_parameter', 'sibling')}),
        'whole sibling source association')
    require(set(sibling['_width_scopes']['transactions']) == {'sibling'}, 'sibling scope membership')
    require(sibling['_width_scopes']['transactions']['sibling']['params'][0]['value'] == '6', 'sibling default')
    require(products['plain']['ir']['children']['worker']['_width_declarations'] == {}, 'literal/type association')


def verify():
    before, after = read('before'), read('after')
    initial = json.loads(gzip.decompress(Path(PREFIX + 'initial-refusal-20261023.json.gz').read_bytes()))
    require(initial['qualified'] is False and initial['error'] == 'command failed', 'original refusal identity')
    original = json.loads(initial['native']['generated']['check']['stdout']['text'])
    require(original['success'] is False and any('first.from_storage' in d['message']
            and 'unconnected' in d['message'] for d in original['diagnostics']), 'original explicit-binding boundary')
    draft = json.loads(gzip.decompress(Path(PREFIX + 'first-draft-20261023.json.gz').read_bytes()))
    require('keys %{$args{signal_widths}}' in draft['sources']['perl/FSM/Support/ISFWidthDeclarations.pm']
            and 'Failed 2/3 subtests' in draft['log'], 'original auxiliary-width membership draft')
    for packet in (before, after):
        require(packet['qualified'] is True, 'incomplete packet')
        require(set(packet['sources']) == set(INPUTS + SOURCES), 'input membership')
        for p, row in packet['sources'].items():
            require(sha(row['text'].encode()) == row['sha256'] == packet['sources_after'][p], 'input changed')
    require(before['sources'][TEST] == after['sources'][TEST], 'fixed regression changed')
    for p in ('perl/FSM/Support/ISFWidthDeclarations.pm', 'perl/FSM/Scheduler/ISF/LoweringIR.pm'):
        require(sha(subprocess.check_output(['git', '--no-replace-objects', 'show', before['revision'] + ':' + p]))
                == before['sources'][p]['sha256'], 'predecessor production Git source')
    require('Failed 3/3 subtests' in before['first_red'] and 'physical' in before['first_red'], 'actual original RED')
    old, new = [json.loads(checked(packet['private'])) for packet in (before, after)]
    require(set(old) == set(new) == set(CASES), 'case membership')
    stripped = copy.deepcopy(new)
    for case in CASES:
        require(new[case]['caller_unchanged'] is True, 'caller changed')
        require(set(old[case]['ir']['children']) == set(new[case]['ir']['children']), 'child membership')
        for child in stripped[case]['ir']['children'].values():
            for key in KEYS:
                require(key in child, 'missing metadata')
                del child[key]
        for kind in ('check', 'semantic', 'schedule'):
            require(checked(before['native'][case][kind]) == checked(after['native'][case][kind]), 'native bytes changed')
    require(typed(old) == typed(stripped), 'old complete private/source/carrier/report products changed')
    oracle(new)
    for label in ('source_owner', 'source_token', 'physical_member', 'scope_kind', 'actor_default', 'local_default'):
        bad = copy.deepcopy(new)
        child = bad['generated']['ir']['children']['worker']
        if label.startswith('source_'):
            child['_width_declarations']['data']['source'][label[7:]] = 'WRONG'
        elif label == 'physical_member':
            child['_width_declarations']['unused'] = child['_width_declarations'].pop('unused_formal')
        elif label == 'scope_kind':
            child['_width_declarations']['data']['scope']['kind'] = 'actor'
        elif label == 'actor_default':
            child['_width_scopes']['actor']['params'][0]['value'] = '4'
        else:
            child['_width_scopes']['transactions']['worker']['params'][0]['value'] = 4
        try:
            oracle(bad)
        except (ValueError, KeyError):
            continue
        raise ValueError('hostile metadata admitted: ' + label)
    rows = [json.loads(line) for line in checked(after['public']).splitlines()]
    require([(r['case'], r['kind']) for r in rows] == [(c, k) for c in CASES for k in ('check', 'semantic', 'schedule')],
            'complete public transport membership')
    for row in rows:
        response = row['api']
        require(not response.get('error') and not response['result'].get('isError'), 'API refused')
        require(typed(response['result']['structuredContent']['report']) == typed(normalized(json.loads(
            checked(after['native'][row['case']][row['kind']])))), 'native/API product')
        require(typed(json.loads(response['result']['content'][0]['text'])) == typed(response['result']['structuredContent']),
                'API text/structured product')
        wire = row['wire']
        require(type(wire['exit_code']) is int and wire['exit_code'] == 0 and wire['signal'] == 0 and wire['stderr'] == '', 'wire failed')
        require(wire['stdout'].count('\n') == 1 and typed(json.loads(wire['stdout'])) == typed(response), 'actual newline product')
    print('generated-width: complete old products, literal/scoped associations, public parity and hostile controls verify')


def doc_checks(final=False):
    terminal_path = PREFIX + 'focused-terminal-20261023.json'
    terminal = json.loads(Path(terminal_path).read_text())
    focused_log = Path('.artifacts/generated-width-focused-20261023.log').read_bytes()
    require(type(terminal['result']['exit_code']) is int and terminal['result']['exit_code'] == 0,
            'guarded focused cohort did not finish successfully')
    require(terminal['log_sha256'] == sha(focused_log), 'focused terminal/log identity')
    paths = INPUTS + SOURCES + ['MEMORY.md', 'docs/TASK_TREE.md', 'docs/tasks/ISF-REDUCTION-DELIVERY.md',
        'docs/book/src/13b-transactions.md', 'docs/isf-spec/11-downstream-actor-transactions.md',
        'docs/decisions/current/language-api/0119-scalar-width-declarations-retain-authored-provenance.md',
        'docs/decisions/current/catalog.json', 'doctrine/live_document_size/surfaces.jsonl', terminal_path]
    packet = {'owner': 'ISF-REDUCTION-DELIVERY.2.3.2.4.1', 'qualified': False,
              'inputs': {p: sha(Path(p).read_bytes()) for p in paths}, 'results': {},
              'focused_log': focused_log.decode(), 'focused_terminal': terminal,
              'book_task_log': Path('.artifacts/generated-width-doc-tests-20261023.log').read_text()}
    commands = {
        'book_build': ['mdbook', 'build', 'docs/book'],
        'book_sources': ['python3', '-B', 'scripts/book_source_references.py', '--check', '--verify-build', 'docs/book/book'],
        'book_index': ['python3', '-B', 'scripts/check_book_source_index.py'],
        'task_tree': ['scripts/check_task_tree_integrity.pl'],
        'decisions': ['python3', '-B', 'scripts/decision_records.py', 'check'],
        'saved_products': ['python3', '-B', SELF, 'verify'],
        'syntax_metadata': ['perl', '-Iperl', '-c', 'perl/FSM/Support/ISFWidthDeclarations.pm'],
        'syntax_lowering': ['perl', '-Iperl', '-c', 'perl/FSM/Scheduler/ISF/LoweringIR.pm'],
    }
    try:
        require(all('All tests successful.' in packet[k] and 'Result: PASS' in packet[k]
                    for k in ('focused_log', 'book_task_log')), 'incomplete focused checks')
        for label, argv in commands.items():
            packet['results'][label] = capture(argv, timeout=600)
            require(type(packet['results'][label]['exit']) is int and packet['results'][label]['exit'] == 0,
                    'failed document check: ' + label)
        require(all(sha(Path(p).read_bytes()) == digest for p, digest in packet['inputs'].items()), 'inputs changed during checks')
        packet['qualified'] = True
    finally:
        save(Path(PREFIX + ('final-doc-checks' if final else 'doc-checks') + '-20261023.json.gz'), packet)
    print('generated-width: complete document/build/syntax and saved-product checks retained')


if __name__ == '__main__':
    if sys.argv[1:] in (['before'], ['after']):
        epoch(sys.argv[1])
    elif sys.argv[1:] == ['verify']:
        verify()
    elif sys.argv[1:] == ['doc-checks']:
        doc_checks()
    elif sys.argv[1:] == ['final-doc-checks']:
        doc_checks(final=True)
    else:
        raise SystemExit('usage: generated-width-ir-20261023.py before|after|verify|doc-checks|final-doc-checks')

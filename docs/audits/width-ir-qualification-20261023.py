#!/usr/bin/env python3
"""Bounded actor-width IR captures and saved, type-sensitive conservation checks."""
import copy
import datetime
import gzip
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[2]
os.chdir(ROOT)
PREFIX = 'docs/audits/width-ir-'
RECIPE = PREFIX + 'qualification-20261023.py'
PUBLIC = PREFIX + 'public-20261023.pl'
TEST = 't/2099-isf-actor-width-ir-provenance.t'
INPUTS = ['t/data/isf-width-ir/actor.isf', 't/data/isf-width-ir/plain.isf', 't/data/isf-width-ir/shared.fsm']
SOURCES = ['perl/FSM/Adapter/ISF/Parser.pm', 'perl/FSM/Scheduler/ISF/LoweringIR.pm',
           'perl/FSM/Support/ISFWidthDeclarations.pm', 't/lib/FSM/Test/WidthIR.pm', TEST, PUBLIC, RECIPE]
PRIVATE = ['perl', '-Iperl', '-It/lib', '-MJSON::PP', '-MFSM::Test::WidthIR=width_ir_products',
           '-e', 'print JSON::PP->new->canonical->encode(width_ir_products()),"\n"']
TESTS = [
    't/1092-isf-lispish-adapter.t', 't/1281-isf-enum-member-library-use-params.t',
    't/1352-isf-library-use-package-constants.t', 't/1357-isf-transaction-port-package-constant-widths.t',
    't/2094-isf-authored-width-declarations.t', 't/2096-isf-authored-static-references.t',
    't/2097-isf-nested-aggregate-normalization.t', 't/2098-isf-authored-library-override-sources.t', TEST,
    't/1112-isf-public-interface-contract.t', 't/1117-isf-public-lower-result-files-audit.t',
    't/1118-isf-public-parse-source-facade-audit.t', 't/2044-isf-conditional-origin-source-authority.t',
    't/2045-isf-same-source-library-origins.t', 't/2043-isf-conditional-origin-parser.t',
    't/2052-isf-local-formal-origin-authority.t', 't/2055-isf-local-formal-helper-diagnostic-causes.t',
]


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def typed(value):
    return json.dumps(value, sort_keys=True, separators=(',', ':'))


def require(condition, message):
    if not condition:
        raise ValueError(message)


def capture(argv, stdin=None, timeout=300):
    start = datetime.datetime.now(datetime.timezone.utc).isoformat()
    t0 = time.monotonic_ns()
    try:
        result = subprocess.run(argv, input=stdin, capture_output=True, timeout=timeout)
        status, out, err = result.returncode, result.stdout, result.stderr
    except subprocess.TimeoutExpired as error:
        status, out, err = 'timeout', error.stdout or b'', error.stderr or b''
    return {'argv': argv, 'exit': status, 'controller_pid': os.getpid(), 'started_utc': start,
            'ended_utc': datetime.datetime.now(datetime.timezone.utc).isoformat(),
            'elapsed_ns': time.monotonic_ns() - t0, 'timeout_seconds': timeout,
            **{key: {'text': raw.decode().replace(str(ROOT), '<repo>'), 'raw_bytes': len(raw), 'raw_sha256': sha(raw)}
               for key, raw in [('stdout', out), ('stderr', err)]}}


def path(epoch):
    require(epoch in ('before', 'after'), 'unknown epoch')
    return Path(PREFIX + epoch + '-20261023.json.gz')


def save(target, packet):
    # Failed or partial epochs are immutable observations too.
    require(not target.exists(), 'refusing to overwrite ' + str(target))
    target.write_bytes(gzip.compress((json.dumps(packet, sort_keys=True, indent=2) + '\n').encode(), mtime=0))


def read(epoch):
    return json.loads(gzip.decompress(path(epoch).read_bytes()))


def checked(row):
    require(type(row['exit']) is int and row['exit'] == 0, 'programme did not succeed')
    require(row['stderr']['text'] == '', 'unexpected programme diagnostic')
    return row['stdout']['text']


def native_reports(packet):
    return {case: {kind: normalized(json.loads(checked(row))) for kind, row in rows.items()}
            for case, rows in packet['native'].items()}


def normalized(value):
    # Native observations retain the exact checkout prefix as <repo>. The
    # public adapter sanitizes that same prefix to a repository-relative path.
    if type(value) is dict:
        return {k: normalized(v) for k, v in value.items()}
    if type(value) is list:
        return [normalized(v) for v in value]
    if type(value) is str:
        return '.' if value == '<repo>' else value.replace('<repo>/', '')
    return value


def public_corrected():
    after = read('after')
    require(after['qualified'] is False and after['error'] == 'programme did not succeed', 'not the original oracle refusal')
    require(after['public']['exit'] == 255 and after['public']['stderr']['text'] == 'native/API mismatch actor check\n',
            'unexpected original public failure')
    rows = [json.loads(line) for line in after['public']['stdout']['text'].splitlines()]
    require(len(rows) == 1, 'original public refusal membership')
    original = json.loads(after['native']['actor']['check']['stdout']['text'])
    expected = copy.deepcopy(original)
    require(expected['source']['resolved_path'] == '<repo>/t/data/isf-width-ir/actor.isf', 'original native path')
    expected['source']['resolved_path'] = 't/data/isf-width-ir/actor.isf'
    require(typed(expected) == typed(rows[0]['api']['result']['structuredContent']['report']), 'failure was not solely path normalization')
    for p, source in after['sources'].items():
        if p != RECIPE:
            require(sha(Path(p).read_bytes()) == source['sha256'], 'public product/instrument input changed: ' + p)
    require(all(sha(Path(p).read_bytes()) == row['sha256'] for p, row in after['inputs'].items()), 'public input changed')
    packet = {'owner': after['owner'], 'qualification': 'Correct established root normalization; no native/private epoch replay.',
              'original_after_sha256': sha(path('after').read_bytes()),
              'sources': {p: {'text': Path(p).read_text(), 'sha256': sha(Path(p).read_bytes())} for p in (RECIPE, PUBLIC)},
              'inputs': after['inputs']}
    packet['public'] = capture(['perl', '-Iperl', PUBLIC], json.dumps(native_reports(after)).encode(), timeout=300)
    packet['inputs_after'] = {p: sha(Path(p).read_bytes()) for p in INPUTS}
    save(Path(PREFIX + 'public-corrected-20261023.json.gz'), packet)
    checked(packet['public'])
    print('corrected public programme retained')


def qualified_after():
    original = read('after')
    corrected = json.loads(gzip.decompress(Path(PREFIX + 'public-corrected-20261023.json.gz').read_bytes()))
    require(corrected['original_after_sha256'] == sha(path('after').read_bytes()), 'public/original packet join')
    require(typed(corrected['inputs']) == typed(original['inputs']), 'public input join')
    require(all(row['sha256'] == corrected['inputs_after'][p] for p, row in corrected['inputs'].items()), 'public input digest')
    result = copy.deepcopy(original)
    result['public'] = corrected['public']
    result['qualified'] = True
    result['_qualification_join'] = {'original_error': original['error'], 'public_packet': PREFIX + 'public-corrected-20261023.json.gz'}
    return result


def run_epoch(epoch):
    packet = {'owner': 'ISF-REDUCTION-DELIVERY.2.3.2.2', 'epoch': epoch,
              'revision': subprocess.check_output(['git', 'rev-parse', 'HEAD']).decode().strip(),
              'inputs': {p: {'text': Path(p).read_text(), 'sha256': sha(Path(p).read_bytes())} for p in INPUTS},
              'sources': {p: {'text': Path(p).read_text(), 'sha256': sha(Path(p).read_bytes())}
                          for p in SOURCES if Path(p).exists()},
              'native': {}, 'qualified': False,
              'limits': 'Selected complete private and native/public source products; no transitive loaded-source census, raw root reconstruction, HDL execution, generic width or historical timeout attribution.'}
    try:
        packet['private'] = capture(PRIVATE)
        checked(packet['private'])
        for case in ('actor', 'plain'):
            packet['native'][case] = {}
            for kind, flags in [('check', ['--check', '--json']), ('semantic', ['--emit-semantic-json']),
                                ('schedule', ['--emit-schedule-json'])]:
                row = capture(['perl', 'bin/fsmgen', '--quiet', '--strict', *flags,
                               't/data/isf-width-ir/' + case + '.isf'], timeout=60)
                packet['native'][case][kind] = row
                checked(row)
        if epoch == 'after':
            packet['public'] = capture(['perl', '-Iperl', PUBLIC],
                                       json.dumps(native_reports(packet)).encode(), timeout=300)
            checked(packet['public'])
        packet['qualified'] = True
    except Exception as error:
        packet['error'] = str(error)
    finally:
        packet['inputs_after'] = {p: sha(Path(p).read_bytes()) for p in INPUTS}
        save(path(epoch), packet)
    require(packet['qualified'], packet.get('error', 'capture failed'))
    print(epoch + ': complete epoch retained')


def projection(products):
    result = copy.deepcopy(products)
    for row in result.values():
        row['actor'].pop('_width_source_actor_name', None)
        row['prepared']['actor'].pop('_width_source_actor_name', None)
        for key in ('_width_declarations', '_width_scopes', '_width_static_uses'):
            row['ir'].pop(key, None)
    return result


def expected_metadata(case):
    owner = 'width_ir' if case == 'actor' else 'plain_width_ir'
    scope = {'kind': 'actor', 'owner': owner}
    declarations = {}
    params = []
    constants = []
    tx_params = []
    imports, packages, enums = [], {}, {'local': {}, 'packages': {}}
    statics = {'scope': scope, 'storage_depths': {}, 'library_overrides': {}}

    def source(token, kind='actor_parameter', lexical_owner=owner):
        return {'token': token, 'kind': kind, 'owner': lexical_owner}

    if case == 'actor':
        for name, token, kind, lexical_owner in [
            ('data', 'W', 'actor_parameter', owner), ('alias_data', 'ALIAS', 'actor_parameter', owner),
            ('other_data', 'OTHER', 'actor_parameter', owner), ('result', 'W', 'actor_parameter', owner),
            ('fixed_data', 'FIXED', 'actor_constant', owner),
            ('package_data', 'shared.WIDTH', 'package_constant', 'shared'),
            ('collision_data', 'word_t', 'actor_parameter', owner),
        ]:
            declarations[name] = {'scope': scope, 'source': source(token, kind, lexical_owner),
                                  'declaration': {'kind': 'interface', 'name': name,
                                                  'direction': 'output' if name == 'result' else 'input'}}
        for name, token, kind, lexical_owner in [
            ('saved', 'ALIAS', 'actor_parameter', owner), ('fixed_saved', 'FIXED', 'actor_constant', owner),
            ('package_saved', 'shared.WIDTH', 'package_constant', 'shared'),
        ]:
            declarations[name] = {'scope': scope, 'source': source(token, kind, lexical_owner),
                                  'declaration': {'kind': 'storage', 'name': name, 'storage_kind': 'var'}}
        for index in (0, 1):
            declarations['mem_' + str(index)] = {'scope': scope, 'source': source('OTHER'),
                'declaration': {'kind': 'storage', 'name': 'mem', 'storage_kind': 'bank', 'index': index}}
        params = [{'name': 'W', 'value': '8'}, {'name': 'ALIAS', 'value': 'W', 'resolved_value': '8'},
                  {'name': 'OTHER', 'value': '8'}, {'name': 'D', 'value': '2'},
                  {'name': 'WD', 'value': '3'}, {'name': 'word_t', 'value': '16'}]
        constants = [{'name': 'FIXED', 'value': '8', 'resolved_value': '8'}]
        tx_params = [{'name': 'W', 'value': '4'}, {'name': 'ALIAS', 'value': 'W', 'resolved_value': '4'}]
        imports, packages = ['shared'], {'shared': {'WIDTH': {'kind': 'scalar', 'payload': 8}}}
        enums = {'local': {}, 'packages': {'shared': {}}}
        statics.update(watchdog=source('WD'), storage_depths={'mem': source('D')})
    return {'_width_declarations': declarations, '_width_static_uses': statics,
            '_width_scopes': {'actor': {'owner': owner, 'params': params, 'constants': constants,
                                      'package_imports': imports, 'package_constants': packages, 'enum_symbols': enums},
                              'transactions': {'main': {'actor': owner, 'owner': 'main', 'params': tx_params}}}}


def verify(before, after):
    require(before['qualified'] is True and after['qualified'] is True, 'unqualified epoch')
    require(typed(before['inputs']) == typed(after['inputs']), 'source inputs differ')
    for packet in (before, after):
        require(packet['private']['argv'] == PRIVATE, 'private command identity')
        require(set(packet['inputs']) == set(INPUTS), 'input manifest membership')
        for entry in packet['sources'].values():
            require(sha(entry['text'].encode()) == entry['sha256'], 'source snapshot digest')
        require(set(packet['native']) == {'actor', 'plain'}, 'native membership')
        for p, entry in packet['inputs'].items():
            require(sha(entry['text'].encode()) == entry['sha256'] == packet['inputs_after'][p], 'source digest')
        require(all(set(rows) == {'check', 'semantic', 'schedule'} for rows in packet['native'].values()), 'mode membership')
    old = json.loads(checked(before['private']))
    new = json.loads(checked(after['private']))
    require(set(old) == set(new) == {'actor', 'plain'}, 'private membership')
    require(all(row['caller_unchanged'] is True for row in new.values()), 'caller changed')
    for case, row in new.items():
        owner = 'width_ir' if case == 'actor' else 'plain_width_ir'
        require(row['actor']['_width_source_actor_name'] == row['prepared']['actor']['_width_source_actor_name'] == owner,
                'original actor identity')
        expected = expected_metadata(case)
        require(typed({k: row['ir'].get(k) for k in expected}) == typed(expected), 'metadata association/environment')
    require(typed(projection(old)) == typed(projection(new)), 'old private projection changed')
    require(typed(native_reports(before)) == typed(native_reports(after)), 'native report changed')
    for case in ('actor', 'plain'):
        for kind in ('check', 'semantic', 'schedule'):
            require(typed(before['native'][case][kind]['stdout']) == typed(after['native'][case][kind]['stdout']),
                    'native bytes/hash changed')
    rows = [json.loads(line) for line in checked(after['public']).splitlines()]
    require(len(rows) == 6 and {(r['case'], r['kind']) for r in rows}
            == {(c, k) for c in ('actor', 'plain') for k in ('check', 'semantic', 'schedule')}, 'public membership')
    for row in rows:
        tool = {'check': 'fsmgen_check', 'semantic': 'fsmgen_semantic_introspect', 'schedule': 'fsmgen_schedule_preview'}[row['kind']]
        expected_request = {'jsonrpc': '2.0', 'id': 1, 'method': 'tools/call', 'params': {
            'name': tool, 'arguments': {'source_id': 't/data/isf-width-ir/' + row['case'] + '.isf'}}}
        require(typed(row['request']) == typed(expected_request), 'public request identity')
        require(row['api']['jsonrpc'] == '2.0' and type(row['api']['id']) is int and row['api']['id'] == 1, 'API response identity')
        result = row['api']['result']
        require(row['api'].get('error') is None and result.get('isError') is not True, 'API failure')
        require(typed(result['structuredContent']['report'])
                == typed(native_reports(after)[row['case']][row['kind']]), 'native/API mismatch')
        require(typed(json.loads(result['content'][0]['text'])) == typed(result['structuredContent']), 'API text mismatch')
        wire = row['wire']
        require(type(wire['exit_code']) is int and wire['exit_code'] == 0 and wire['stderr'] == ''
                and type(wire['signal']) is int and wire['signal'] == 0, 'wire failure')
        require(wire['stdout'].endswith('\n') and len(wire['stdout'].splitlines()) == 1, 'wire framing')
        require(typed(json.loads(wire['stdout'])) == typed(row['api']), 'wire/API mismatch')
        observation = row['observation']
        require(type(observation['programme_pid']) is int and observation['programme_pid'] > 0
                and observation['started_utc_epoch'] > 0
                and observation['api_started_monotonic'] <= observation['api_finished_monotonic']
                <= observation['newline_finished_monotonic'], 'observation order')
    return {'cases': len(new), 'public_rows': len(rows), 'whole_old_projections_equal': True}


def controls():
    before, after = read('before'), qualified_after()
    baseline = verify(before, after)
    results = {}
    mutations = {
        'wrong_source_token': lambda p: p['actor']['ir']['_width_declarations']['data']['source'].update(token='OTHER'),
        'wrong_source_kind': lambda p: p['actor']['ir']['_width_declarations']['data']['source'].update(kind='actor_constant'),
        'wrong_lexical_owner': lambda p: p['actor']['ir']['_width_declarations']['package_data']['source'].update(owner='width_ir'),
        'wrong_scope': lambda p: p['actor']['ir']['_width_declarations']['data']['scope'].update(owner='renamed'),
        'missing_declaration': lambda p: p['actor']['ir']['_width_declarations'].pop('alias_data'),
        'invented_literal_source': lambda p: p['plain']['ir']['_width_declarations'].update(data={}),
        'wrong_bank_index': lambda p: p['actor']['ir']['_width_declarations']['mem_1']['declaration'].update(index=0),
        'string_bank_index': lambda p: p['actor']['ir']['_width_declarations']['mem_0']['declaration'].update(index='0'),
        'borrow_actor_default': lambda p: p['actor']['ir']['_width_scopes']['transactions']['main']['params'][0].update(value='8'),
        'erase_alias_source': lambda p: p['actor']['ir']['_width_scopes']['actor']['params'][1].update(value='8'),
        'change_parameter_kind': lambda p: p['actor']['ir']['_width_scopes']['actor']['params'][0].update(value=8),
        'change_package_kind': lambda p: p['actor']['ir']['_width_scopes']['actor']['package_constants']['shared']['WIDTH'].update(payload='8'),
        'wrong_depth': lambda p: p['actor']['ir']['_width_static_uses']['storage_depths']['mem'].update(token='W'),
        'wrong_watchdog': lambda p: p['actor']['ir']['_width_static_uses']['watchdog'].update(token='D'),
        'lost_original_actor': lambda p: p['actor']['actor'].update(_width_source_actor_name='renamed'),
        'changed_old_ir': lambda p: p['actor']['ir']['signal_widths'].update(data=9),
        'caller_boolean_kind': lambda p: p['actor'].update(caller_unchanged=1),
    }
    for name, mutate in mutations.items():
        altered = copy.deepcopy(after)
        products = json.loads(altered['private']['stdout']['text'])
        mutate(products)
        altered['private']['stdout']['text'] = json.dumps(products)
        try:
            verify(before, altered)
        except ValueError as error:
            results[name] = str(error)
        else:
            raise ValueError('hostile control accepted: ' + name)
    save(Path(PREFIX + 'controls-20261023.json.gz'), {'owner': after['owner'], 'baseline': baseline,
        'controls': results, 'method': 'Saved-packet mutations only; no source/native/public programme replay.',
        'verifier': {'text': Path(RECIPE).read_text(), 'sha256': sha(Path(RECIPE).read_bytes())}})
    print(json.dumps({'controls_rejected': len(results), **baseline}, sort_keys=True))


def focused():
    paths = set(INPUTS + SOURCES + TESTS + [
        't/lib/FSM/Test/ConditionalOriginAuthority.pm', 't/lib/FSM/Test/ConditionalOriginParser.pm',
        't/lib/FSM/Test/LocalFormalOriginAuthority.pm'])
    packet = {'owner': 'ISF-REDUCTION-DELIVERY.2.3.2.2',
              'sources': {p: {'text': Path(p).read_text(), 'sha256': sha(Path(p).read_bytes())} for p in sorted(paths)},
              'results': {}, 'qualified': False}
    commands = {'focused': ['prove', '-Iperl', '-It/lib', *TESTS],
                **{'syntax_' + str(i): ['perl', '-Iperl', '-c', p] for i, p in enumerate(SOURCES[:3])}}
    try:
        for name, argv in commands.items():
            packet['results'][name] = capture(argv, timeout=600)
            require(packet['results'][name]['exit'] == 0, 'failed ' + name)
        packet['qualified'] = True
    finally:
        save(Path(PREFIX + 'focused-20261023.json.gz'), packet)
    print('focused checks retained')


def public_controls():
    before, after = read('before'), qualified_after()
    baseline = verify(before, after)
    mutations = {
        'wrong_request': lambda r: r[0]['request']['params']['arguments'].update(source_id='t/data/isf-width-ir/plain.isf'),
        'boolean_response_id': lambda r: r[0]['api'].update(id=True),
        'wire_signal': lambda r: r[0]['wire'].update(signal=15),
        'boolean_exit': lambda r: r[0]['wire'].update(exit_code=False),
        'extra_newline': lambda r: r[0]['wire'].update(stdout=r[0]['wire']['stdout'] + '\n'),
        'report_kind': lambda r: r[0]['api']['result']['structuredContent']['report']['source']['interface_ports'][1].update(width='8'),
        'text_payload': lambda r: r[0]['api']['result']['content'][0].update(text='{}'),
        'missing_row': lambda r: r.pop(),
    }
    results = {}
    for name, mutate in mutations.items():
        altered = copy.deepcopy(after)
        rows = [json.loads(line) for line in altered['public']['stdout']['text'].splitlines()]
        mutate(rows)
        altered['public']['stdout']['text'] = ''.join(json.dumps(row) + '\n' for row in rows)
        try:
            verify(before, altered)
        except ValueError as error:
            results[name] = str(error)
        else:
            raise ValueError('hostile public control accepted: ' + name)
    save(Path(PREFIX + 'public-controls-20261023.json.gz'), {'owner': after['owner'], 'baseline': baseline,
        'controls': results, 'method': 'Saved-packet mutations only; no source programme replay.',
        'verifier': {'text': Path(RECIPE).read_text(), 'sha256': sha(Path(RECIPE).read_bytes())}})
    print(json.dumps({'public_controls_rejected': len(results), **baseline}, sort_keys=True))


def foundation():
    focus = json.loads(gzip.decompress(Path(PREFIX + 'focused-20261023.json.gz').read_bytes()))
    require(focus['qualified'] is True, 'focused checks are not qualified')
    require('All tests successful' in focus['results']['focused']['stdout']['text'], 'focused success signature')
    before = read('before')
    require(focus['sources'][TEST]['sha256'] == before['sources'][TEST]['sha256'], 'fixed actor regression changed')
    logs = {}
    for name in ('red', 'library-red', 'green', 'focused', 'authority', 'authority-final',
                 'before', 'after', 'public-corrected'):
        p = Path('.artifacts/width-ir-' + name + '-20261023.log')
        raw = p.read_bytes()
        logs[str(p)] = {'text': raw.decode().replace(str(ROOT), '<repo>'), 'raw_sha256': sha(raw), 'raw_bytes': len(raw)}
    revision = before['revision']
    old_tests = {p: subprocess.check_output(['git', 'show', revision + ':' + p]).decode()
                 for p in ('t/2044-isf-conditional-origin-source-authority.t', 't/2055-isf-local-formal-helper-diagnostic-causes.t')}
    save(Path(PREFIX + 'foundation-20261023.json.gz'), {'owner': focus['owner'], 'baseline_revision': revision,
        'old_origin_tests': old_tests, 'logs': logs, 'source_versions': focus['sources'],
        'initial_private_observation': json.loads(Path('.artifacts/width-ir-before-20261023.json').read_text().replace(str(ROOT), '<repo>')),
        'qualification': verify(before, qualified_after()),
        'receipt_sha256': {str(p): sha(p.read_bytes()) for p in sorted(Path('docs/audits').glob('width-ir-*-20261023.json.gz'))},
        'limits': 'Original logs and selected code/test/input snapshots. No full transitive footprint, raw-root reconstruction, generic HDL or historical source-query causal closure.'})
    print('original failures, corrected checks and selected sources retained')


def doc_checks():
    paths = ['MEMORY.md', 'docs/TASK_TREE.md', 'docs/tasks/ISF-REDUCTION-DELIVERY.md',
             'docs/book/src/13a-actor-interface.md', 'docs/book/src/13e-data-manipulation.md',
             'docs/isf-spec/11-downstream-actor-transactions.md', 'docs/BIN_FSMGEN_IMPORT_TREE.md',
             'docs/decisions/current/language-api/0119-scalar-width-declarations-retain-authored-provenance.md',
             'docs/decisions/current/catalog.json', 'doctrine/live_document_size/surfaces.jsonl']
    packet = {'owner': 'ISF-REDUCTION-DELIVERY.2.3.2.2', 'qualified': False, 'results': {},
              'inputs': {p: sha(Path(p).read_bytes()) for p in paths}}
    commands = {
        'book_tasks': ['prove', '-Iperl', 't/1376-isf-book-example-lowering-audit.t', 't/1549-task-tree-integrity-doctrine.t'],
        'book_build': ['mdbook', 'build', 'docs/book'],
        'book_sources': ['python3', '-B', 'scripts/book_source_references.py', '--check', '--verify-build', 'docs/book/book'],
        'book_index': ['python3', '-B', 'scripts/check_book_source_index.py'],
        'task_tree': ['scripts/check_task_tree_integrity.pl'],
        'decisions': ['python3', '-B', 'scripts/decision_records.py', 'check'],
        'saved_products': ['python3', '-B', RECIPE, 'verify'],
    }
    try:
        for name, argv in commands.items():
            packet['results'][name] = capture(argv, timeout=600)
            require(packet['results'][name]['exit'] == 0, 'failed ' + name)
        require(all(sha(Path(p).read_bytes()) == digest for p, digest in packet['inputs'].items()), 'documentation changed during checks')
        packet['qualified'] = True
    finally:
        save(Path(PREFIX + 'doc-checks-20261023.json.gz'), packet)
    print('final document checks retained')


def verify_foundation():
    saved = json.loads(gzip.decompress(Path(PREFIX + 'foundation-20261023.json.gz').read_bytes()))
    for p, digest in saved['receipt_sha256'].items():
        require(sha(Path(p).read_bytes()) == digest, 'foundation receipt digest: ' + p)
    for p, text in saved['old_origin_tests'].items():
        require(subprocess.check_output(['git', 'show', saved['baseline_revision'] + ':' + p]).decode() == text,
                'original origin test Git binding: ' + p)
    for entry in saved['source_versions'].values():
        require(sha(entry['text'].encode()) == entry['sha256'], 'foundation source digest')
    require(typed(saved['initial_private_observation']) == typed(json.loads(checked(read('before')['private']))),
            'initial private observation differs')
    focused = json.loads(gzip.decompress(Path(PREFIX + 'focused-20261023.json.gz').read_bytes()))
    require(focused['qualified'] is True and all(type(row['exit']) is int and row['exit'] == 0
                                               for row in focused['results'].values()), 'focused check status')
    require(focused['results']['focused']['argv'] == ['prove', '-Iperl', '-It/lib', *TESTS], 'focused membership')
    require('All tests successful' in focused['results']['focused']['stdout']['text'], 'focused signature')
    require(saved['source_versions'][TEST]['sha256'] == read('before')['sources'][TEST]['sha256'], 'fixed RED/GREEN oracle identity')
    for p in SOURCES[:3]:
        require(saved['source_versions'][p]['sha256'] == read('after')['sources'][p]['sha256'], 'qualified product source identity')
    return {'foundation_and_selected_Git_sources': True, 'focused_files': len(TESTS)}


if __name__ == '__main__':
    if len(sys.argv) == 2 and sys.argv[1] in ('before', 'after'):
        run_epoch(sys.argv[1])
    elif sys.argv[1:] == ['verify']:
        print(json.dumps({**verify(read('before'), qualified_after()), **verify_foundation()}, sort_keys=True))
    elif sys.argv[1:] == ['public-corrected']:
        public_corrected()
    elif sys.argv[1:] == ['controls']:
        controls()
    elif sys.argv[1:] == ['focused']:
        focused()
    elif sys.argv[1:] == ['public-controls']:
        public_controls()
    elif sys.argv[1:] == ['foundation']:
        foundation()
    elif sys.argv[1:] == ['doc-checks']:
        doc_checks()
    else:
        raise SystemExit('usage: width-ir-qualification-20261023.py before|after|public-corrected|verify|controls|public-controls|focused|foundation|doc-checks')

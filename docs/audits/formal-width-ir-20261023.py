#!/usr/bin/env python3
"""Frozen direct-formal width-source observations and type-sensitive joins."""
import copy
import gzip
import json
import os
from pathlib import Path
import re
import runpy
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
os.chdir(ROOT)
BASE = 'docs/audits/width-ir-qualification-20261023.py'
# Import only the committed capture/normalization utilities. Its CLI and source
# programmes do not execute under run_path; sealed actor epochs are never replayed.
base = runpy.run_path(BASE)
capture, sha, typed, require, normalized = [base[k] for k in ('capture', 'sha', 'typed', 'require', 'normalized')]
RECIPE = 'docs/audits/formal-width-ir-20261023.py'
PUBLIC = 'docs/audits/formal-width-ir-public-20261023.pl'
PREFIX = 'docs/audits/formal-width-ir-'
CASES = ('scopes', 'literals', 'mixed')
INPUTS = ['t/data/isf-formal-width-ir/' + n for n in ('scopes.isf', 'literals.isf', 'mixed.isf', 'shared.fsm')]
TEST = 't/2100-isf-direct-formal-width-ir.t'
SOURCES = [RECIPE, BASE, PUBLIC, TEST, 't/lib/FSM/Test/FormalWidthIR.pm',
           't/2048-isf-file-document-origin-authority.t', 'perl/FSM/Support/ISFWidthDeclarations.pm',
           'perl/FSM/Scheduler/ISF/LoweringIR.pm', 'perl/FSM/Scheduler/ISF/FormalLowering.pm',
           'perl/FSM/Scheduler/ISF/FormalIdentityPlan.pm', 'perl/FSM/Scheduler/ISF/FormalClauseResolver.pm']
PRIVATE = ['perl', '-Iperl', '-It/lib', '-MJSON::PP', '-MFSM::Test::FormalWidthIR=formal_width_products',
           '-e', 'print JSON::PP->new->canonical->encode(formal_width_products()),"\n"']
TESTS = [TEST, 't/2099-isf-actor-width-ir-provenance.t', 't/2094-isf-authored-width-declarations.t',
         't/2096-isf-authored-static-references.t', 't/2098-isf-authored-library-override-sources.t',
         't/1925-isf-formal-identity-plan.t', 't/1936-isf-formal-source-context.t',
         't/1939-isf-formal-helper-identity.t', 't/1955-isf-formal-domain-source-products.t',
         't/1961-isf-formal-source-binding-reports.t', 't/2044-isf-conditional-origin-source-authority.t',
         't/2046-isf-library-document-origin-authority.t', 't/2047-isf-atl-document-origin-authority.t',
         't/2048-isf-file-document-origin-authority.t', 't/2052-isf-local-formal-origin-authority.t',
         't/2055-isf-local-formal-helper-diagnostic-causes.t', 't/1336-isf-transaction-port-actor-param-widths.t',
         't/1342-isf-transaction-port-actor-constant-widths.t', 't/1357-isf-transaction-port-package-constant-widths.t',
         't/1368-isf-transaction-port-transaction-param-widths.t', 't/1371-isf-transaction-port-activation-override-width-gate.t',
         't/1240-isf-transaction-port-declarations.t', 't/1241-isf-transaction-port-bindings.t']


def save(path, packet):
    path = Path(path)
    require(not path.exists(), 'refusing to overwrite an observed packet: ' + str(path))
    path.write_bytes(gzip.compress((json.dumps(packet, sort_keys=True, indent=2) + '\n').encode(), mtime=0))


def path(epoch):
    require(epoch in ('before', 'after'), 'unknown epoch')
    return Path(PREFIX + epoch + '-20261023.json.gz')


def read(epoch):
    return json.loads(gzip.decompress(path(epoch).read_bytes()))


def checked(row):
    require(type(row['exit']) is int and row['exit'] == 0, 'programme refused or timed out')
    require(row['stderr']['text'] == '', 'unexpected programme diagnostics')
    return row['stdout']['text']


def reports(packet):
    return {case: {kind: normalized(json.loads(checked(row))) for kind, row in rows.items()}
            for case, rows in packet['native'].items()}


def epoch(name):
    packet = {'owner': 'ISF-REDUCTION-DELIVERY.2.3.2.3', 'epoch': name,
              'revision': subprocess.check_output(['git', 'rev-parse', 'HEAD']).decode().strip(),
              'inputs': {p: {'text': Path(p).read_text(), 'sha256': sha(Path(p).read_bytes())} for p in INPUTS},
              'sources': {p: {'text': Path(p).read_text(), 'sha256': sha(Path(p).read_bytes())} for p in SOURCES},
              'native': {}, 'qualified': False,
              'limits': 'Selected private source/preparation/physical/module/carrier and public reports. No complete transitive loaded footprint, raw-root reconstruction, generic HDL, generated/domain provenance closure or historical source-query attribution.'}
    try:
        packet['private'] = capture(PRIVATE)
        checked(packet['private'])
        for case in CASES:
            packet['native'][case] = {}
            for kind, flags in [('check', ['--check', '--json']), ('semantic', ['--emit-semantic-json']),
                                ('schedule', ['--emit-schedule-json'])]:
                row = capture(['perl', 'bin/fsmgen', '--quiet', '--strict', *flags,
                               't/data/isf-formal-width-ir/' + case + '.isf'], timeout=60)
                packet['native'][case][kind] = row
                checked(row)
        if name == 'after':
            packet['public'] = capture(['perl', '-Iperl', PUBLIC], json.dumps(reports(packet)).encode(), timeout=300)
            checked(packet['public'])
        packet['qualified'] = True
    except Exception as error:
        packet['error'] = str(error)
    finally:
        packet['inputs_after'] = {p: sha(Path(p).read_bytes()) for p in INPUTS}
        save(path(name), packet)
    require(packet['qualified'], packet.get('error', 'epoch not qualified'))
    print(name + ': complete direct-formal epoch retained')


def formal_expectations(case):
    if case == 'literals':
        return {}
    rows = [
        ('left', 'data', 'isf_port_left_data_formal', 'input', 'ALIAS', 'transaction_parameter', 'left'),
        ('left', 'saved', 'isf_port_left_saved', 'input', 'W', 'transaction_parameter', 'left'),
        ('left', 'equal_data', 'isf_port_left_equal_data', 'input', 'OTHER', 'transaction_parameter', 'left'),
        ('left', 'inherited_data', 'isf_port_left_inherited_data', 'input', 'ACTOR_ALIAS', 'actor_parameter', 'formal_width_ir'),
        ('left', 'fixed_data', 'isf_port_left_fixed_data', 'input', 'FIXED', 'actor_constant', 'formal_width_ir'),
        ('left', 'package_data', 'isf_port_left_package_data', 'input', 'shared.WIDTH', 'package_constant', 'shared'),
        ('left', 'collision_data', 'isf_port_left_collision_data', 'input', 'word_t', 'transaction_parameter', 'left'),
        ('left', 'N', 'isf_port_left_N', 'input', 'W', 'transaction_parameter', 'left'),
        ('left', 'result', 'isf_port_left_result', 'output', 'W', 'transaction_parameter', 'left'),
        ('right', 'data', 'isf_port_right_data', 'input', 'ALIAS', 'transaction_parameter', 'right'),
        ('right', 'result', 'isf_port_right_result', 'output', 'W', 'transaction_parameter', 'right'),
    ] if case == 'scopes' else [
        ('parent', 'data', 'isf_port_parent_data', 'input', 'ALIAS', 'actor_parameter', 'mixed_formal_width_ir')]
    actor = 'formal_width_ir' if case == 'scopes' else 'mixed_formal_width_ir'
    return {physical: {'scope': {'kind': 'transaction', 'actor': actor, 'owner': tx},
                       'source': {'token': token, 'kind': kind, 'owner': owner},
                       'declaration': {'kind': 'transaction_port', 'name': name, 'direction': direction,
                                       'identity': ['transaction_port', actor, tx, name]}}
            for tx, name, physical, direction, token, kind, owner in rows}


def verify(before, after):
    require(before['qualified'] is True and after['qualified'] is True, 'unqualified observed epoch')
    require(typed(before['inputs']) == typed(after['inputs']), 'different source inputs')
    for packet in (before, after):
        require(packet['private']['argv'] == PRIVATE, 'private programme identity')
        require(set(packet['native']) == set(CASES), 'native case membership')
        require(all(set(r) == {'check', 'semantic', 'schedule'} for r in packet['native'].values()), 'native mode membership')
        for p, entry in packet['inputs'].items():
            require(sha(entry['text'].encode()) == entry['sha256'] == packet['inputs_after'][p], 'source input digest')
        for entry in packet['sources'].values():
            require(sha(entry['text'].encode()) == entry['sha256'], 'source instrument snapshot digest')
    require(before['sources'][TEST]['sha256'] == after['sources'][TEST]['sha256'], 'fixed regression changed')
    old = json.loads(checked(before['private']))
    new = json.loads(checked(after['private']))
    require(set(old) == set(new) == set(CASES), 'private case membership')
    stripped = copy.deepcopy(new)
    for case, row in new.items():
        require(row['caller_unchanged'] is True and row['physical_unchanged'] is True, 'source/physical input changed')
        expected = formal_expectations(case)
        for physical, declaration in expected.items():
            require(physical not in old[case]['ir']['_width_declarations'], 'predecessor already owns new formal association')
            require(typed(row['ir']['_width_declarations'].get(physical)) == typed(declaration), 'formal association mismatch')
            identity = declaration['declaration']['identity']
            plan = row['context']['plan']['formals'][identity[2]][identity[3]]
            require(typed(plan['identity']) == typed(identity) and plan['physical_name'] == physical, 'actual identity-plan allocation')
            stripped[case]['ir']['_width_declarations'].pop(physical)
        if case == 'mixed':
            require('_width_declarations' not in row['ir']['children']['worker'], 'generated successor widened')
    require(typed(old) == typed(stripped), 'complete old private projection changed')
    for case in CASES:
        for kind in ('check', 'semantic', 'schedule'):
            require(typed(before['native'][case][kind]['stdout']) == typed(after['native'][case][kind]['stdout']),
                    'complete native bytes/hash changed')
    native = reports(after)
    rows = [json.loads(line) for line in checked(after['public']).splitlines()]
    require(len(rows) == 9 and {(r['case'], r['kind']) for r in rows}
            == {(c, k) for c in CASES for k in ('check', 'semantic', 'schedule')}, 'public row membership')
    tools = {'check': 'fsmgen_check', 'semantic': 'fsmgen_semantic_introspect', 'schedule': 'fsmgen_schedule_preview'}
    for row in rows:
        request = {'jsonrpc': '2.0', 'id': 1, 'method': 'tools/call', 'params': {'name': tools[row['kind']],
                   'arguments': {'source_id': 't/data/isf-formal-width-ir/' + row['case'] + '.isf'}}}
        require(typed(row['request']) == typed(request), 'request identity')
        result = row['api']['result']
        require(row['api'].get('error') is None and result.get('isError') is not True, 'API refused')
        require(row['api']['jsonrpc'] == '2.0' and type(row['api']['id']) is int and row['api']['id'] == 1, 'API response identity')
        require(typed(result['structuredContent']['report']) == typed(native[row['case']][row['kind']]), 'native/API mismatch')
        require(typed(json.loads(result['content'][0]['text'])) == typed(result['structuredContent']), 'text/structured mismatch')
        wire = row['wire']
        require(type(wire['exit_code']) is int and wire['exit_code'] == 0 and type(wire['signal']) is int
                and wire['signal'] == 0 and wire['stderr'] == '', 'newline failure')
        require(wire['stdout'].endswith('\n') and len(wire['stdout'].splitlines()) == 1, 'newline framing')
        require(typed(json.loads(wire['stdout'])) == typed(row['api']), 'API/newline mismatch')
        obs = row['observation']
        require(type(obs['programme_pid']) is int and obs['programme_pid'] > 0 and obs['started_utc_epoch'] > 0
                and obs['api_started_monotonic'] <= obs['api_finished_monotonic'] <= obs['newline_finished_monotonic'], 'observation order')
    return {'cases': len(new), 'formal_associations': sum(len(formal_expectations(c)) for c in CASES),
            'public_rows': len(rows), 'whole_old_private_and_native_products_equal': True}


def focused():
    paths = sorted(set(SOURCES + INPUTS + TESTS))
    packet = {'owner': 'ISF-REDUCTION-DELIVERY.2.3.2.3', 'qualified': False, 'results': {},
              'sources': {p: {'text': Path(p).read_text(), 'sha256': sha(Path(p).read_bytes())} for p in paths}}
    try:
        commands = {'focused': ['prove', '-Iperl', '-It/lib', *TESTS],
                    'lowering_syntax': ['perl', '-Iperl', '-c', 'perl/FSM/Scheduler/ISF/LoweringIR.pm'],
                    'metadata_syntax': ['perl', '-Iperl', '-c', 'perl/FSM/Support/ISFWidthDeclarations.pm']}
        for name, argv in commands.items():
            packet['results'][name] = capture(argv, timeout=900)
            require(packet['results'][name]['exit'] == 0, 'failed check: ' + name)
        packet['qualified'] = True
    finally:
        save(PREFIX + 'focused-20261023.json.gz', packet)
    print('focused direct-formal checks retained')


def controls():
    before, after = read('before'), read('after')
    baseline = verify(before, after)
    results = {}
    mutations = {
        'wrong_token': lambda p: p['scopes']['ir']['_width_declarations']['isf_port_left_data_formal']['source'].update(token='W'),
        'wrong_kind': lambda p: p['scopes']['ir']['_width_declarations']['isf_port_left_saved']['source'].update(kind='actor_parameter'),
        'wrong_package_owner': lambda p: p['scopes']['ir']['_width_declarations']['isf_port_left_package_data']['source'].update(owner='formal_width_ir'),
        'sibling_scope_borrow': lambda p: p['scopes']['ir']['_width_declarations']['isf_port_left_saved']['scope'].update(owner='right'),
        'physical_actor_scope': lambda p: p['scopes']['ir']['_width_declarations']['isf_port_left_saved']['scope'].update(actor='renamed_module'),
        'wrong_original_identity': lambda p: p['scopes']['ir']['_width_declarations']['isf_port_left_saved']['declaration']['identity'].__setitem__(3, 'data'),
        'wrong_original_name': lambda p: p['scopes']['ir']['_width_declarations']['isf_port_left_saved']['declaration'].update(name='other'),
        'wrong_direction': lambda p: p['scopes']['ir']['_width_declarations']['isf_port_left_result']['declaration'].update(direction='input'),
        'missing_formal': lambda p: p['scopes']['ir']['_width_declarations'].pop('isf_port_right_result'),
        'unallocated_prefix_guess': lambda p: p['scopes']['ir']['_width_declarations'].update(isf_port_left_data=p['scopes']['ir']['_width_declarations'].pop('isf_port_left_data_formal')),
        'invented_literal_dependency': lambda p: p['literals']['ir']['_width_declarations'].update(isf_port_main_data={}),
        'generated_in_parent': lambda p: p['mixed']['ir']['_width_declarations'].update(child_data={}),
        'generated_successor_widened': lambda p: p['mixed']['ir']['children']['worker'].update(_width_declarations={}),
        'actor_alias_borrow_local_default': lambda p: p['scopes']['ir']['_width_scopes']['actor']['params'][1].update(resolved_value='4'),
        'local_default_numeric_kind': lambda p: p['scopes']['ir']['_width_scopes']['transactions']['left']['params'][0].update(value=4),
        'changed_old_width': lambda p: p['scopes']['ir']['signal_widths'].update(isf_port_left_N=2),
        'count_value_conflation': lambda p: p['scopes']['context']['actor']['transactions'][0]['clauses'][3].__setitem__(1, 'isf_port_left_N'),
        'wrong_plan_allocation': lambda p: p['scopes']['context']['plan']['formals']['left']['data'].update(physical_name='isf_port_left_data'),
        'caller_boolean_kind': lambda p: p['scopes'].update(caller_unchanged=1),
        'physical_boolean_kind': lambda p: p['scopes'].update(physical_unchanged=1),
    }
    for name, mutate in mutations.items():
        changed = copy.deepcopy(after)
        products = json.loads(changed['private']['stdout']['text'])
        mutate(products)
        changed['private']['stdout']['text'] = json.dumps(products)
        try:
            verify(before, changed)
        except ValueError as error:
            results[name] = str(error)
        else:
            raise ValueError('accepted hostile private control: ' + name)
    wire_mutations = {
        'wrong_request': lambda r: r[0]['request']['params']['arguments'].update(source_id='different.isf'),
        'response_id_kind': lambda r: r[0]['api'].update(id=True),
        'newline_signal': lambda r: r[0]['wire'].update(signal=15),
        'exit_kind': lambda r: r[0]['wire'].update(exit_code=False),
        'extra_newline': lambda r: r[0]['wire'].update(stdout=r[0]['wire']['stdout']+'\n'),
        'text_payload': lambda r: r[0]['api']['result']['content'][0].update(text='{}'),
        'missing_public_row': lambda r: r.pop(),
    }
    for name, mutate in wire_mutations.items():
        changed = copy.deepcopy(after)
        rows = [json.loads(line) for line in changed['public']['stdout']['text'].splitlines()]
        mutate(rows)
        changed['public']['stdout']['text'] = ''.join(json.dumps(r)+'\n' for r in rows)
        try:
            verify(before, changed)
        except ValueError as error:
            results[name] = str(error)
        else:
            raise ValueError('accepted hostile public control: ' + name)
    save(PREFIX+'controls-20261023.json.gz', {'owner': after['owner'], 'baseline': baseline,
        'controls': results, 'method': 'Saved-packet falsifiers only; no source/native/public replay.',
        'verifier': {'text': Path(RECIPE).read_text(), 'sha256': sha(Path(RECIPE).read_bytes())}})
    print(json.dumps({'controls_rejected': len(results), **baseline}, sort_keys=True))


def foundation():
    focus = json.loads(gzip.decompress(Path(PREFIX+'focused-20261023.json.gz').read_bytes()))
    require(focus['qualified'] is True, 'focused cohort is not qualified')
    before, after = read('before'), read('after')
    require(focus['sources'][TEST]['sha256'] == before['sources'][TEST]['sha256'] == after['sources'][TEST]['sha256'],
            'fixed RED/GREEN formal regression changed')
    for p in ('perl/FSM/Support/ISFWidthDeclarations.pm', 'perl/FSM/Scheduler/ISF/LoweringIR.pm'):
        require(focus['sources'][p]['sha256'] == after['sources'][p]['sha256'], 'qualified product source changed')
    logs = {}
    for label in ('formal-width-ir-initial', 'formal-width-ir-baseline', 'formal-width-ir-red',
                  'formal-width-ir-green', 'formal-width-file-authority-red', 'formal-width-file-authority-green',
                  'formal-width-ir-before', 'formal-width-ir-after', 'formal-width-ir-focused'):
        p = Path('.artifacts/'+label+'-20261023.log'); raw = p.read_bytes()
        logs[str(p)] = {'text': raw.decode().replace(str(ROOT), '<repo>'), 'raw_sha256': sha(raw), 'raw_bytes': len(raw)}
    revision = before['revision']
    save(PREFIX+'foundation-20261023.json.gz', {'owner': before['owner'], 'baseline_revision': revision,
        'old_file_authority_test': subprocess.check_output(['git', 'show', revision+':t/2048-isf-file-document-origin-authority.t']).decode(),
        'initial_sources': json.loads(Path('.artifacts/formal-width-ir-initial-sources-20261023.json').read_text()),
        'initial_private': json.loads(Path('.artifacts/formal-width-ir-initial-20261023.json').read_text().replace(str(ROOT), '<repo>')),
        'initial_limits': 'Private-only two-case draft. Actor static N intentionally shields the same-named value formal; corrected fixture removes only that confounder. No native admission was observed for this draft.',
        'corrected_private_baseline': json.loads(Path('.artifacts/formal-width-ir-baseline-20261023.json').read_text().replace(str(ROOT), '<repo>')),
        'logs': logs, 'sources': focus['sources'], 'qualification': verify(before, after),
        'receipt_sha256': {str(p): sha(p.read_bytes()) for p in sorted(Path('docs/audits').glob('formal-width-ir-*-20261023.json.gz'))},
        'limits': after['limits']})
    print('original drafts/refusals, exact source versions and final checks retained')


def verify_foundation():
    f = json.loads(gzip.decompress(Path(PREFIX+'foundation-20261023.json.gz').read_bytes()))
    for p, digest in f['receipt_sha256'].items():
        require(sha(Path(p).read_bytes()) == digest, 'foundation receipt binding')
    require(subprocess.check_output(['git', 'show', f['baseline_revision']+':t/2048-isf-file-document-origin-authority.t']).decode()
            == f['old_file_authority_test'], 'original file-authority Git source')
    for entry in [*f['sources'].values(), *f['initial_sources'].values()]:
        require(sha(entry['text'].encode()) == entry['sha256'], 'foundation source snapshot digest')
    focus = json.loads(gzip.decompress(Path(PREFIX+'focused-20261023.json.gz').read_bytes()))
    require(focus['qualified'] is True and all(type(r['exit']) is int and r['exit'] == 0 for r in focus['results'].values()),
            'focused result status')
    require(focus['results']['focused']['argv'] == ['prove', '-Iperl', '-It/lib', *TESTS], 'focused membership')
    require('All tests successful' in focus['results']['focused']['stdout']['text'], 'focused success signature')
    require(f['sources'][TEST]['sha256'] == read('before')['sources'][TEST]['sha256'] == read('after')['sources'][TEST]['sha256'],
            'fixed regression source binding')
    for p in ('perl/FSM/Support/ISFWidthDeclarations.pm', 'perl/FSM/Scheduler/ISF/LoweringIR.pm'):
        require(f['sources'][p]['sha256'] == read('after')['sources'][p]['sha256'], 'qualified production source binding')
    return {'foundation_and_selected_Git_sources': True, 'focused_files': len(TESTS)}


def doc_checks():
    paths = ['MEMORY.md', 'docs/TASK_TREE.md', 'docs/tasks/ISF-REDUCTION-DELIVERY.md',
             'docs/book/src/13b-transactions.md', 'docs/book/src/13e-data-manipulation.md',
             'docs/isf-spec/11-downstream-actor-transactions.md',
             'docs/decisions/current/language-api/0119-scalar-width-declarations-retain-authored-provenance.md',
             'docs/decisions/current/catalog.json', 'doctrine/live_document_size/surfaces.jsonl', RECIPE]
    blocks = re.findall(r'```lisp\n(\(actor width_scopes\b.*?\n)```', Path('docs/book/src/13b-transactions.md').read_text(), re.S)
    require(len(blocks) == 1, 'exact complete book alias example')
    raw = blocks[0].encode()
    example = Path('.artifacts/formal-width-book-'+sha(raw)[:16]+'.isf')
    require(not any(p.is_symlink() for p in (example, *example.parents)), 'book example symlink')
    require(example.parent.stat().st_dev == ROOT.stat().st_dev and not (example.parent/'.git').exists(), 'book example locality')
    if example.exists():
        require(example.is_file() and example.read_bytes() == raw, 'conflicting book example')
    else:
        with example.open('xb') as stream:
            stream.write(raw)
    paths.append(str(example))
    packet = {'owner': 'ISF-REDUCTION-DELIVERY.2.3.2.3', 'qualified': False, 'results': {},
              'inputs': {p: sha(Path(p).read_bytes()) for p in paths}}
    commands = {
        'book_example_native': ['perl', 'bin/fsmgen', '--quiet', '--strict', '--check', '--json', str(example)],
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
            require(packet['results'][name]['exit'] == 0, 'failed document check: ' + name)
        require(all(sha(Path(p).read_bytes()) == digest for p, digest in packet['inputs'].items()), 'documentation changed during checks')
        packet['qualified'] = True
    finally:
        save(PREFIX+'doc-checks-20261023.json.gz', packet)
    print('final direct-formal document checks retained')


if __name__ == '__main__':
    if len(sys.argv) == 2 and sys.argv[1] in ('before', 'after'):
        epoch(sys.argv[1])
    elif sys.argv[1:] == ['verify']:
        print(json.dumps({**verify(read('before'), read('after')), **verify_foundation()}, sort_keys=True))
    elif sys.argv[1:] == ['focused']:
        focused()
    elif sys.argv[1:] == ['controls']:
        controls()
    elif sys.argv[1:] == ['foundation']:
        foundation()
    elif sys.argv[1:] == ['doc-checks']:
        doc_checks()
    else:
        raise SystemExit('usage: formal-width-ir-20261023.py before|after|verify|focused|controls|foundation|doc-checks')

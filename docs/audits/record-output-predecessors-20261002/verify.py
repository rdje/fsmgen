"""Compare finite captured predecessor/current products without executing HDL."""
import copy
import hashlib
import json
import re
import subprocess
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
BASE = '0d4bb1801006235d816ebf519eb437752c303849'
NAMES = ['local_nested', 'forward_alias', 'imported_nested', 'imported_alias', 'formal_shadow',
         'drive_shadow', 'unused_record', 'record_input', 'record_input_children',
         'storage_fields', 'storage_word_access', 'isf_record_input_generated_domains_runtime',
         'isf_record_input_generated_blocking_runtime']
FIELDS = [dict(path='kind', width=2, msb=9, lsb=8, signed=0),
          dict(path='payload.data', width=5, msb=7, lsb=3, signed=1, state_model='four_state'),
          dict(path='payload.flags[0]', width=1, msb=2, lsb=2, signed=0),
          dict(path='payload.flags[1]', width=2, msb=1, lsb=0, signed=0, state_model='two_state')]
CLASSES = {'FSM::Composition::' + name for name in ('Instance', 'Link', 'Port', 'PortsBlock',
           'Spec', 'Top', 'TopSymbols', 'WiringBlock')} | {'FSM::Package::Symbols'}


def canonical(value):
    return json.dumps(value, sort_keys=True, ensure_ascii=False, separators=(',', ':'))


def dates(value):
    if isinstance(value, dict):
        return {key: dates(item) for key, item in value.items()}
    if isinstance(value, list):
        return [dates(item) for item in value]
    if isinstance(value, str):
        return re.sub(r'^// Date:[^\n]*$', '// Date: omitted', value, flags=re.M)
    return value


def public_paths(value):
    if isinstance(value, dict):
        return {key: public_paths(item) for key, item in value.items()}
    if isinstance(value, list):
        return [public_paths(item) for item in value]
    if isinstance(value, str):
        return '.' if value == '<repo>' else value.replace('<repo>/', '')
    return value


def native_ok(value):
    assert value['exit_code'] == 0 and value['signal'] == 0 and value['stderr'] == ''


def typed_data(value, classes):
    if isinstance(value, dict):
        if set(value) == {'capture_class', 'capture_kind', 'capture_data'}:
            name = value['capture_class']
            assert name in CLASSES and value['capture_kind'] == 'HASH'
            assert isinstance(value['capture_data'], dict)
            classes.add(name)
            if name == 'FSM::Composition::Spec':
                assert set(value['capture_data']) == {'embedded_dt_sources', 'embedded_fsm_sources',
                       'embedded_package_sources', 'raw_ast', 'top'}
            if name == 'FSM::Composition::Top':
                assert set(value['capture_data']) == {'instances', 'name', 'package_imports', 'ports_blocks',
                       'raw_ast', 'top_symbols', 'wiring_blocks'}
        for item in value.values():
            typed_data(item, classes)
    elif isinstance(value, list):
        for item in value:
            typed_data(item, classes)


def products(value):
    result = public_paths(copy.deepcopy(value))
    for row in result:
        text = row['generation']['stdout']
        paths = re.findall(r'^Wrote: (\.artifacts/tmp/ial1-lowering/fsmgen-[A-Za-z0-9_]+/[A-Za-z0-9_.-]+\.fsm)$', text, flags=re.M)
        if paths:
            parents = {path.rsplit('/', 1)[0] for path in paths}
            assert len(parents) == 1
            assert sorted(path.rsplit('/', 1)[1] for path in paths) == sorted(row['lower']['files'])
            prefix = next(iter(parents))
            row['generation']['stdout'] = text.replace(prefix + '/', '<native-lowering>/')
    return dates(result)


def literal(row, index):
    ports = row['actor']['interface_port_metadata']
    if index < 7:
        type_name = ['frame', 'alias', 'shared.frame', 'alias', 'frame', 'frame', 'frame'][index]
        expected = [dict(name='start', direction='input', width=1),
                    dict(name='packet', direction='input', width=10, type=type_name, type_kind='record', fields=FIELDS),
                    dict(name='scalar', direction='input', width=5), dict(name='mode', direction='input', width=1),
                    dict(name='done', direction='output', width=1), dict(name='seen', direction='output', width=5),
                    dict(name='sliced', direction='output', width=3), dict(name='tag', direction='output', width=2)]
        assert canonical(ports) == canonical(expected)
        packet = next(port for port in row['actor']['interface']['inputs'] if port['name'] == 'packet')
        assert packet['type_spec']['member_order'] == ['kind', 'payload']
        data = packet['type_spec']['members']['payload']['members']['data']
        assert canonical(data) == canonical(dict(kind='bits', width=5, signed=1, state_model='four_state'))
    elif index in (7, 8):
        expected_fields = [dict(path='flag', width=1, msb=5, lsb=5, signed=0),
                           dict(path='data', width=5, msb=4, lsb=0, signed=1, state_model='four_state')]
        for port in ports:
            if port['name'] in ('packet', 'unused'):
                expected = dict(name=port['name'], direction='input', width=6, type='frame', type_kind='record', fields=expected_fields)
                if index == 8:
                    expected['domain'] = 'idle' if port['name'] == 'unused' else 'io'
                assert canonical(port) == canonical(expected)
    elif index in (9, 10):
        names = [('start', 'input', 1), ('wdata', 'input', 8), ('done', 'output', 1)]
        if index == 10:
            names.append(('status_out', 'output', 8))
        names.append(('control_out', 'output', 8))
        assert canonical(ports) == canonical([dict(name=n, direction=d, width=w) for n, d, w in names])
    else:
        fields = copy.deepcopy(FIELDS)
        fields[0]['path'] = 'tag'
        fields[2]['state_model'] = 'two_state'
        for port in ports:
            if port['name'] in ('packet', 'unused'):
                expected = dict(name=port['name'], direction='input', width=10, type='frame', type_kind='record', fields=fields)
                if index == 11:
                    expected['domain'] = 'idle' if port['name'] == 'unused' else 'io'
                assert canonical(port) == canonical(expected)
    for kind, query in row['queries'].items():
        report = query['native_report']
        if kind != 'schedule':
            assert report['success'] is True
        actual = report['interface_ports'] if kind == 'schedule' else report['source']['interface_ports']
        assert canonical(actual) == canonical(ports)


def validate(old, current):
    for phase, capture in [('baseline', old), ('current', current)]:
        classes = set()
        typed_data(capture['products'], classes)
        assert classes == CLASSES
        assert [row['name'] for row in capture['products']] == NAMES
        selection = capture['selection']
        expected = phase == 'current'
        for report in (selection['native_report'], selection['api']['result']['structuredContent']['report'],
                       selection['wire_response']['result']['structuredContent']['report']):
            assert report['success'] is expected
        for index, row in enumerate(capture['products']):
            assert row['caller_before'] == row['caller_after']
            assert hashlib.sha256(row['source'].encode()).hexdigest() == row['source_before'] == row['source_after']
            assert row['lower']['files'] and set(row['lower']['files']) == set(row['carriers'])
            literal(row, index)
            for kind, query in row['queries'].items():
                native_ok(query['native']); native_ok(query['wire'])
                assert query['source_before'] == query['source_after'] == row['source_before']
                assert canonical(json.loads(query['native']['stdout'])) == canonical(query['native_report'])
                assert canonical(json.loads(query['wire']['stdout'])) == canonical(query['wire_response'])
                assert canonical(query['api']) == canonical(query['wire_response'])
                result = query['api']['result']
                assert result['isError'] is False
                assert canonical(json.loads(result['content'][0]['text'])) == canonical(result['structuredContent'])
                assert canonical(result['structuredContent']['report']) == canonical(public_paths(query['native_report']))
            for carrier in row['carriers'].values():
                native_ok(carrier)
                assert json.loads(carrier['stdout'])['success'] is True
            native_ok(row['generation'])
            assert row['hdl'] and row['facade']['hdl_code']
            assert row['facade']['source_info']['kind'] == 'isf'
    assert canonical(products(current['products'])) == canonical(products(old['products']))
    assert canonical(current['packages']) == canonical(old['packages'])


def downstream(value):
    fields = [dict(path='flag', width=1, msb=5, lsb=5, signed=0),
              dict(path='data', width=5, msb=4, lsb=0, signed=1, state_model='four_state')]
    ports = [dict(name='start', direction='input', width=1),
             dict(name='packet', direction='input', width=6, type='frame', type_kind='record', fields=fields),
             dict(name='result', direction='output', width=6, type='frame', type_kind='record', fields=fields),
             dict(name='seen', direction='output', width=5), dict(name='done', direction='output', width=1)]
    assert value['caller_before'] == value['caller_after']
    assert hashlib.sha256(value['source'].encode()).hexdigest() == value['source_sha256']
    assert canonical(value['actor']['interface_port_metadata']) == canonical(ports)
    assert set(value['queries']) == {'check', 'semantic', 'schedule'}
    assert value['lower']['files'] and set(value['lower']['files']) == set(value['carriers'])
    for kind, query in value['queries'].items():
        native_ok(query['native']); native_ok(query['stdio'])
        report = query['native']['report']
        assert canonical(json.loads(query['native']['stdout'])) == canonical(report)
        if kind != 'schedule': assert report['success'] is True
        actual = report['interface_ports'] if kind == 'schedule' else report['source']['interface_ports']
        assert canonical(actual) == canonical(ports)
        result = query['adapter_result']
        assert result['isError'] is False
        assert canonical(query['stdio']['response']) == canonical(json.loads(query['stdio']['stdout']))
        assert canonical(result) == canonical(query['stdio']['response']['result'])
        assert canonical(json.loads(result['content'][0]['text'])) == canonical(result['structuredContent'])
        assert canonical(public_paths(report)) == canonical(result['structuredContent']['report'])
        assert query['source_sha256_before'] == query['source_sha256_after'] == value['source_sha256']
        assert query['producer_sha256_before'] == query['producer_sha256_after']
    for carrier in value['carriers'].values():
        native_ok(carrier); assert json.loads(carrier['stdout'])['success'] is True
    native_ok(value['generation']); assert value['hdl']


def main():
    manifest = json.loads((HERE / 'manifest.json').read_bytes())
    assert set(manifest['sha256']) == {p.name for p in HERE.iterdir() if p.is_file() and p.name != 'manifest.json'}
    for name, digest in manifest['sha256'].items():
        assert hashlib.sha256((HERE / name).read_bytes()).hexdigest() == digest
    for revision, sources in manifest['producer_objects'].items():
        for path, identity in sources.items():
            blob = subprocess.check_output(['git', 'rev-parse', revision + ':' + path], cwd=ROOT).decode().strip()
            assert blob == identity['git_blob']
            assert hashlib.sha256(subprocess.check_output(['git', 'cat-file', 'blob', blob], cwd=ROOT)).hexdigest() == identity['sha256']
    for dirname, members in manifest['parent_members'].items():
        parent = ROOT / 'docs/audits' / dirname
        assert set(members) == {p.name for p in parent.iterdir() if p.is_file()}
        for name, digest in members.items():
            assert hashlib.sha256((parent / name).read_bytes()).hexdigest() == digest
    def phase(name):
        row = manifest['phase_fragments'][name]
        parts = [(HERE / filename).read_bytes() for filename in row['members']]
        assert all(len(part) <= 16 * 1024 * 1024 for part in parts)
        raw = b''.join(parts)
        assert len(raw) == row['normalized_bytes']
        assert hashlib.sha256(raw).hexdigest() == row['normalized_sha256']
        assert len(raw) == row['raw_bytes'] - row['replacement_count'] * (row['root_prefix_bytes'] - len(b'<repo>'))
        return json.loads(raw)
    example = json.loads((HERE / 'downstream-products.json').read_bytes())
    downstream(example)
    assert example['source'] == (HERE / 'downstream-record-ports.isf').read_text()
    for mutate in (lambda v: v['actor']['interface_port_metadata'][2]['fields'][1].update(signed=0),
                   lambda v: v['actor']['interface_port_metadata'][2].update(width='6'),
                   lambda v: v['lower'].update(files={}),
                   lambda v: v['queries']['check']['native']['report'].update(success=False)):
        bad = copy.deepcopy(example); mutate(bad)
        try: downstream(bad)
        except (AssertionError, KeyError, TypeError): pass
        else: raise AssertionError('hostile downstream shared/lost/kind substitution accepted')
    metadata = json.loads((HERE / 'downstream-manifest.json').read_bytes())
    fs = metadata['language_surface']['file_surfaces']
    assert fs['shipped_suffixes'] == ['.fsm', '.isf', '.ppif', '.axi', '.apb', '.ahb', '.vial']
    assert fs['direct_ial2_to_ial0_allowed'] is False
    for suffix in ('.axi', '.apb', '.ahb'):
        row, = [row for row in fs['entries'] if row['suffix'] == suffix]
        assert row['intent_layer'] == 'IAL2' and row['lowers_to'] == ['.isf', '.fsm']
        assert row['status'] == 'shipped_bounded_profile_alias'
        assert metadata['semantic_introspection']['source_query_kinds'][suffix[1:]] == ['check','semantic','schedule']
    shape = metadata['embedding']['isf_public_interface']['schedule_report_interface_ports']
    assert shape['entry_keys'] == ['name','direction','width']
    assert shape['optional_entry_keys'] == ['type','type_kind','domain','fields']
    assert shape['field_keys'] == ['path','width','lsb','msb','signed']
    assert shape['optional_field_keys'] == ['state_model']
    assert shape['type_kind_values'] == ['bit','bits','record']
    render = json.loads((HERE / 'downstream-render.json').read_bytes())
    assert render['example_matches_rendered_code'] is True and render['record_heading_present'] is True and render['old_refusal_absent'] is True
    assert hashlib.sha256((HERE / 'downstream-render.html').read_bytes()).hexdigest() == render['render_sha256']
    assert example['source'].rstrip() in render['parts']['11-downstream-actor-transactions.md']['text']
    for row in render['parts'].values():
        assert hashlib.sha256(row['text'].encode()).hexdigest() == row['sha256']
        assert 'Record source admission remains refused.' not in row['text']
    assert 'source query requires a safe relative source identity' in (HERE / 'downstream-probe-draft.txt').read_text()
    assert 'Complete documented record input/output example passes' in (HERE / 'downstream-probe.txt').read_text()
    assert 'HTML book written to' in (HERE / 'downstream-book.txt').read_text()
    old = phase('baseline')
    current = phase('current')
    validate(old, current)
    assert manifest['terminal_exit_codes'] == dict(draft_focused=1, getter_draft_focused=1,
        preload_draft_focused=1, focused=0, lower_only_diagnostic=255, getter_diagnostic=255,
        typed_data_trace=0, expired_preload_check=1, fresh_preload_check=0, syntax=0, docs=0, book=0, independent_verifier_draft=1, independent_verifier=0, staged_doctrines_draft=1, staged_doctrines_claim_draft=1,
        decision_growth_red=1, decision_growth=0, decision_regression=0, decision_syntax=0,
        downstream_probe_draft=255, downstream_probe=0, downstream_manifest=0,
        downstream_docs=0, downstream_book=0, downstream_render=0, downstream_verifier_draft=1)
    for name, files, tests, outcome in [('focused.txt', 1, 38, 'PASS'),
            ('docs.txt', 3, 310, 'PASS'), ('draft-focused.txt', 1, 10, 'FAIL'),
            ('getter-draft-focused.txt', 1, 10, 'FAIL'), ('preload-draft-focused.txt', 1, 38, 'FAIL'),
            ('decision-growth-red.txt', 1, 2, 'FAIL'), ('decision-growth.txt', 1, 2, 'PASS'),
            ('decision-regression.txt', 4, 8, 'PASS'), ('downstream-docs.txt', 6, 622, 'PASS')]:
        receipt = (HERE / name).read_text()
        assert re.search(rf'Files={files}, Tests={tests},', receipt)
        assert 'Result: ' + outcome in receipt
        assert ('All tests successful.' in receipt) is (outcome == 'PASS')
    assert 'HTML book written to' in (HERE / 'book.txt').read_text()
    assert (HERE / 'syntax.txt').read_text().count('syntax OK') == 2
    assert 'AssertionError' in (HERE / 'verify-draft.txt').read_text()
    assert 'Finite complete predecessor/current products authenticate' in (HERE / 'saved-verify.txt').read_text()
    census = json.loads((HERE / 'decision-growth-census.json').read_bytes())
    assert census['head_revision'] == manifest['current_revision']
    assert census['head']['entries'] == 19921
    assert census['index_before_reader_repair_staging']['entries'] == 20003
    assert census['index_before_reader_repair_staging']['independent_path_membership_agrees'] is True
    assert census['retired_count_bound'] == 20000
    assert census['unchanged_metadata_byte_bound'] == 4194304 and census['minimum_index_record_bytes'] == 52
    assert census['index_before_reader_repair_staging']['metadata_bytes'] < 4194304
    prior_source = subprocess.check_output(['git', 'show', manifest['current_revision'] + ':scripts/decision_store_git.py'], cwd=ROOT)
    assert prior_source == (HERE / 'decision-git-baseline.py.source').read_bytes()
    replacement = """# Every SHA-1 index record needs mode, object ID, stage, tab, a nonempty
# path and NUL; tree records are longer. The byte cap bounds all entries,
# including unrelated tracked evidence, without a separate growth cliff.
MIN_INVENTORY_RECORD_BYTES = len(b'100644 ' + b'0' * 40 + b' 0\\ta\\0')
MAX_TRACKED_PATHS = MAX_INVENTORY_BYTES // MIN_INVENTORY_RECORD_BYTES"""
    assert prior_source.decode().replace('MAX_TRACKED_PATHS = 20_000', replacement) == (HERE / 'decision_store_git.py.source').read_text()
    assert '1a9bd5ece33094a7f53782b35de4dc2f69eaab35' in (HERE / 'decision-growth-history.txt').read_text()
    assert 'Git path inventory exceeds bound or is incomplete' in (HERE / 'staged-doctrines-draft.txt').read_text()
    assert 'Python syntax valid' in (HERE / 'decision-syntax.txt').read_text()
    fresh = json.loads((HERE / 'preload-fresh.json').read_bytes())
    assert [row['flags'] for row in fresh['records']] == [['-Iperl', '-It/lib'], []]
    assert [row['matches_exact_git'] for row in fresh['records']] == [False, True]
    for module, digest in fresh['expected'].items():
        assert digest == manifest['producer_objects'][BASE]['perl/' + module]['sha256']
        assert fresh['records'][1]['loaded'][module]['sha256'] == digest
        assert fresh['records'][0]['loaded'][module]['sha256'] == manifest['producer_objects'][manifest['current_revision']]['perl/' + module]['sha256']
    # These complete drafts authenticate the instrument failure, never the result.
    for name in ('preload-draft-baseline', 'preload-draft-current'):
        invalid = phase(name)
        for module, loaded in invalid['loaded'].items():
            assert loaded['sha256'] == manifest['producer_objects'][manifest['current_revision']]['perl/' + module]['sha256']
        expected = name.endswith('current')
        for report in (invalid['selection']['native_report'], invalid['selection']['api']['result']['structuredContent']['report'],
                invalid['selection']['wire_response']['result']['structuredContent']['report']):
            assert report['success'] is expected
    for phase, capture, revision in [('baseline', old, BASE), ('current', current, manifest['current_revision'])]:
        for module, loaded in capture['loaded'].items():
            assert loaded['sha256'] == manifest['producer_objects'][revision]['perl/' + module]['sha256']
    for mutate in (
        lambda v: v['products'].pop(),
        lambda v: v['products'][0]['actor']['interface_port_metadata'][1].update(width='10'),
        lambda v: v['products'][0]['actor']['interface_port_metadata'][1]['fields'][1].update(signed=0),
        lambda v: v['products'][0]['lower'].update(files={}),
        lambda v: v['products'][0]['queries']['check']['native'].update(exit_code=1),
        lambda v: v['selection']['native_report'].update(success=False),
        lambda v: v['products'][8]['facade']['source_info']['composition_spec'].update(capture_class='counterfeit'),
    ):
        bad = copy.deepcopy(current); mutate(bad)
        try:
            validate(old, bad)
        except (AssertionError, KeyError, TypeError):
            continue
        raise AssertionError('hostile product mutation accepted')
    # Shared corrupt old/new parity must still fail the literal declaration oracle.
    a, b = copy.deepcopy(old), copy.deepcopy(current)
    for value in (a, b):
        value['products'][0]['actor']['interface_port_metadata'][1]['fields'][1]['lsb'] = 4
    try:
        validate(a, b)
    except AssertionError:
        pass
    else:
        raise AssertionError('shared wrong layout accepted')
    print('Finite complete predecessor/current products authenticate exact kinds, all carriers, real transports and source/HDL text with qualified date normalization. Old/current child-selection sentinels and hostile shared layout/loss/kind controls pass; no HDL execution or complete consumer claim.')


if __name__ == '__main__':
    main()

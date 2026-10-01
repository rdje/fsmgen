"""Verify captured authored-output profile and atomic publication boundaries."""
import copy
import hashlib
import json
import re
import subprocess
from pathlib import Path

HERE = Path(__file__).resolve().parent
BASE = '4b4f988a5ceafb446383ed48de2913f8be5d7a62'
NAMES = ['local', 'imported', 'alias', 'mixed', 'unused']
TYPES = {'local': 'frame', 'imported': 'shared.frame', 'alias': 'alias', 'mixed': 'frame', 'unused': 'frame'}
FIELDS = [dict(path='tag', width=2, msb=5, lsb=4, signed=0),
          dict(path='body.data', width=3, msb=3, lsb=1, signed=1, state_model='four_state'),
          dict(path='body.flag', width=1, msb=0, lsb=0, signed=0)]
SENTINEL = 'EXISTING DESTINATION\nkeep every byte\n'


def canonical(value):
    return json.dumps(value, sort_keys=True, ensure_ascii=False, separators=(',', ':'))


def reason(name, target):
    language = 'verilog' if target == 'v' else target
    role = 'input' if name == 'mixed' and language == 'verilog' else 'output'
    port, type_name = ('incoming', 'frame') if role == 'input' else ('packet', TYPES[name])
    detail = 'Verilog-2005 record lowering is not implemented.' if language == 'verilog' else 'VHDL record-output lowering is not implemented.'
    return f"ISF actor 'target_output_{name}' record {role} '{port}' (type '{type_name}') cannot generate target '{language}': packed record {role}s require SystemVerilog; use --language systemverilog. {detail}"


def refused(value, expected):
    first = value['stderr'].splitlines()[0] if value['stderr'] else ''
    return value['exit_code'] == 1 and value['signal'] == 0 and value['stdout'] == '' and re.match(r'^(?:Error generating HDL: )?' + re.escape(expected) + r'(?: at |$)', first) is not None


def normalize_date(text):
    return re.sub(r'^// Date:[^\n]*$', '// Date: omitted', text, flags=re.M)


def validate(value, name):
    assert value['type'] == TYPES[name] and value['sentinel'] == SENTINEL
    assert [row['target'] for row in value['refused']] == ['verilog', 'v', 'vhdl']
    for row in value['refused']:
        expected = reason(name, row['target'])
        assert row['reason'] == expected
        assert refused(row['existing'], expected) and refused(row['absent'], expected)
        assert row['destination_sha256'] == hashlib.sha256(SENTINEL.encode()).hexdigest()
        assert row['absent_destination_exists'] is False and row['facade_product'] is None
        assert row['facade_error'].splitlines()[0] == expected
        assert set(row['machine']) == {'check', 'semantic'}
        for mode, machine in row['machine'].items():
            native, report = machine['native'], machine['report']
            assert native['exit_code'] == 1 and native['signal'] == 0 and native['stderr'] == ''
            assert report['success'] is False and report['diagnostics'][0]['message'] == expected
            assert 'code' in report['diagnostics'][0] and 'interface_ports' not in report['source']
            assert report.get('semantic') is None
            assert canonical(json.loads(native['stdout'])) == canonical(report)
        schedule = row['schedule']
        assert schedule['exit_code'] == 0 and schedule['signal'] == 0 and schedule['stderr'] == ''
        report = json.loads(schedule['stdout'])
        ports = [dict(name='start', direction='input', width=1)]
        if name == 'mixed':
            ports.append(dict(name='incoming', direction='input', width=6, type='frame', type_kind='record', fields=FIELDS))
        ports.extend([dict(name='packet', direction='output', width=6, type=TYPES[name], type_kind='record', fields=FIELDS),
                      dict(name='done', direction='output', width=1)])
        assert canonical(report['interface_ports']) == canonical(ports)
    assert set(value['supported']) == {'systemverilog', 'sv'}
    for target, supported in value['supported'].items():
        native, facade = supported['native'], supported['facade']
        assert native['exit_code'] == 0 and native['signal'] == 0 and native['stderr'] == ''
        for text in (supported['hdl'], facade['hdl_code']):
            assert re.search(r'\bmodule target_output_' + name + r'\b', text)
            assert 'typedef struct packed' in text and 'logic signed [2:0] data;' in text
            assert re.search(r'\boutput\b[^\n]*\bpacket\b', text)
        assert facade['source_info']['kind'] == 'isf'
        assert facade['source_info']['public_source_path'].endswith('/' + name + '.isf')
        assert facade['source_info']['generated_hdl_entry_artifact'] == 'target_output_' + name + '.fsm'
        assert 'hdl_code' in facade['result_keys'] and 'source_info' in facade['result_keys']
    assert normalize_date(value['supported']['sv']['hdl']) == normalize_date(value['supported']['systemverilog']['hdl'])


def rejects(value, name):
    try:
        validate(value, name)
    except (AssertionError, KeyError, TypeError, ValueError):
        return True
    return False


def main():
    manifest = json.loads((HERE / 'manifest.json').read_bytes())
    assert manifest['baseline_revision'] == BASE
    assert manifest['owner'] == 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.4.4.2'
    assert set(manifest['sha256']) == {p.name for p in HERE.iterdir() if p.is_file() and p.name != 'manifest.json'}
    for name, digest in manifest['sha256'].items():
        assert hashlib.sha256((HERE / name).read_bytes()).hexdigest() == digest
    root = HERE.parents[2]
    for path, item in manifest['source_objects'].items():
        blob = subprocess.check_output(['git', 'rev-parse', BASE + ':' + path], cwd=root).decode().strip()
        assert blob == item['git_blob']
        assert hashlib.sha256(subprocess.check_output(['git', 'cat-file', 'blob', blob], cwd=root)).hexdigest() == item['sha256']
    for dirname, members in manifest['parent_members'].items():
        parent = root / 'docs/audits' / dirname
        assert set(members) == {p.name for p in parent.iterdir() if p.is_file()}
        for name, digest in members.items():
            assert hashlib.sha256((parent / name).read_bytes()).hexdigest() == digest
    assert manifest['terminal_exit_codes'] == dict(draft_focused=1, focused=0, syntax=0, preservation=0, docs=0, book=0)
    for name, item in manifest['receipt_projections'].items():
        assert len((HERE / name).read_bytes()) == item['raw_bytes'] - item['replacement_count'] * (item['root_prefix_bytes'] - len(b'<repo>'))
    values = {name: json.loads((HERE / (name + '.json')).read_bytes()) for name in NAMES}
    for name, value in values.items():
        validate(value, name)
    for filename, count in [('focused.txt', 'Files=1, Tests=7'), ('preservation.txt', 'Files=4, Tests=121'), ('docs.txt', 'Files=3, Tests=310')]:
        receipt = (HERE / filename).read_text()
        assert count in receipt and 'All tests successful' in receipt and 'Result: PASS' in receipt
    assert 'HTML book written to' in (HERE / 'book.txt').read_text()
    assert 'syntax OK' in (HERE / 'syntax.txt').read_text()
    draft = (HERE / 'draft-focused.txt').read_text()
    assert "encountered object 'FSM::CoreAST::FSMModule" in draft and 'No plan found' in draft and 'Result: FAIL' in draft
    old = json.loads((root / 'docs/audits/record-output-hdl-profiles-20261001/manifest.json').read_bytes())
    restored = json.loads((HERE / 'restored-prior-scratch.json').read_bytes())
    for row in restored.values():
        name = Path(row['archived_source']).name
        assert row['sha256'] == old['receipt_projections'][name]['raw_sha256']
        assert row['bytes'] == old['receipt_projections'][name]['raw_bytes']
    for mutate in (
        lambda v: v['refused'][0]['existing'].update(exit_code=0),
        lambda v: v['refused'][0]['existing'].update(signal=9),
        lambda v: v['refused'][0]['existing'].update(stderr='Error generating HDL: unrelated\n' + v['refused'][0]['reason']),
        lambda v: v['refused'][0].update(destination_sha256='0' * 64),
        lambda v: v['refused'][0].update(absent_destination_exists=True),
        lambda v: v['refused'][0]['machine']['semantic']['report'].update(success=True),
        lambda v: v['refused'][0]['machine']['check']['report']['source'].update(interface_ports=[]),
        lambda v: v['supported']['sv'].update(hdl=v['supported']['sv']['hdl'].replace('logic signed [2:0] data;', 'logic [2:0] data;')),
    ):
        bad = copy.deepcopy(values['local']); mutate(bad)
        assert rejects(bad, 'local')
    mixed = copy.deepcopy(values['mixed']); mixed['refused'][0]['reason'] = reason('local', 'verilog')
    assert rejects(mixed, 'mixed')
    print('Actual authored record-output target profiles authenticate precise normal native/facade failures, atomic destinations, complete machine and neutral schedule products, supported SystemVerilog/sv text and exact prior scratch restoration. Hostile publication/cause/layout/priority mutations refuse. Typed facade ASTs are not serialized; no HDL execution or complete consumer claim.')


if __name__ == '__main__':
    main()

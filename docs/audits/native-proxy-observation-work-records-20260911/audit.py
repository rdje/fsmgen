"""Independent Python oracle for closed work records and original qualification."""
from __future__ import annotations

import copy
import hashlib
import importlib.util
import itertools
import json
from pathlib import Path
import re
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs/native-proxy-observation-work-records-20260911'
ARCHIVE = 'docs/audits/native-proxy-observation-archive-records-20260911'
REVISION = 'da75e940ec226936828984e77774e9c044cdd8ed'
SPEC = importlib.util.spec_from_file_location('work_original_archive', ROOT / ARCHIVE / 'audit.py')
ORIGINAL = importlib.util.module_from_spec(SPEC); SPEC.loader.exec_module(ORIGINAL)
SELECTION = 'fsmgen.inactive_observation_work_selection.v1'
SETTLEMENT = 'fsmgen.inactive_observation_work_settlement.v1'
ENVELOPE = dict(schema=SETTLEMENT, runtime_authorized=0, executable=None, selection=None, selection_sealed=1, receipts=[])


def canonical(value): return json.dumps(value, ensure_ascii=True, sort_keys=True, separators=(',', ':'))


def closed(value, fields): assert type(value) is dict and set(value) == set(fields.split())


def same(first, second): assert canonical(first) == canonical(second)


def inactive(value, schema):
    assert value['schema'] == schema and type(value['runtime_authorized']) is int and value['runtime_authorized'] == 0
    assert value['executable'] is None


def work(value):
    assert type(value['work_id']) is str and re.fullmatch(r'[A-Za-z0-9_.:-]{1,64}', value['work_id'])
    assert type(value['ownership_token']) is str and re.fullmatch(r'[0-9a-f]{64}', value['ownership_token'])
    assert value['role'] in ('capture', 'helper', 'query') and type(value['role']) is str


def selection(value, observed):
    assert re.fullmatch(r'\.artifacts/tmp/native-proxy-image-custody/cases/fsmgen-[A-Za-z0-9_]+', value['case'])
    spec = ORIGINAL.specification(value)
    record = value['acquired']['observation_reference']['record']
    expected_key = hashlib.sha256(b'fsmgen.rust_proxy_reference.observation.v1\0' + canonical(
        [record['evidence_directory'], record['observer_birth'], record['target_birth']]).encode()).hexdigest()
    assert record['reference_key'] == expected_key
    closed(observed, 'schema runtime_authorized executable evidence_directory_identity observation_reference_key entries')
    inactive(observed, SELECTION)
    same(observed['evidence_directory_identity'], spec['evidence_directory_identity'])
    assert observed['observation_reference_key'] == spec['observation_reference_key']
    entries = observed['entries']; assert type(entries) is list and 1 <= len(entries) <= 17
    ids = []
    for entry in entries:
        closed(entry, 'work_id ownership_token role'); work(entry); ids.append(entry['work_id'])
    assert len(ids) == len(set(ids))
    assert len(canonical(observed).encode('ascii')) <= 4096
    return observed


def create_selection(value):
    expected = dict(schema=SELECTION, runtime_authorized=0, executable=None,
                    evidence_directory_identity=copy.deepcopy(value['request']['evidence_directory_identity']),
                    observation_reference_key=value['acquired']['observation_reference']['record']['reference_key'],
                    entries=copy.deepcopy(value['entries']))
    return selection(value, expected)


def flag(value):
    assert type(value) in (str, int) and value in (0, 1, '0', '1')
    return value == 1 or value == '1'


def settlement(value, observed):
    original = selection(value, value['selection'])
    closed(observed, 'schema runtime_authorized executable selection selection_sealed receipts')
    inactive(observed, SETTLEMENT); same(observed['selection'], original)
    assert type(observed['selection_sealed']) is int and observed['selection_sealed'] == 1
    receipts = observed['receipts']; assert type(receipts) is list and len(receipts) == len(original['entries'])
    for entry, receipt in zip(original['entries'], receipts, strict=True):
        closed(receipt, 'work_id ownership_token role outcome cleanup'); work(receipt)
        same({key: receipt[key] for key in entry}, entry)
        assert type(receipt['outcome']) is str and receipt['outcome'] in ('completed', 'failed', 'cancelled')
        cleanup = receipt['cleanup']; closed(cleanup, 'leader_started leader_reaped group_gone')
        started, reaped, gone = [flag(cleanup[key]) for key in ('leader_started', 'leader_reaped', 'group_gone')]
        assert gone and (not started or reaped)
        assert len(canonical(receipt).encode('ascii')) <= 4096
    limit = len(canonical(ENVELOPE).encode()) + 4096 + 17 * (4096 + 1)
    assert len(canonical(observed).encode('ascii')) <= limit
    return observed


def create_settlement(value):
    observed = dict(ENVELOPE, selection=copy.deepcopy(value['selection']), receipts=copy.deepcopy(value['receipts']),
                    selection_sealed=value['sealed'])
    return settlement(value, observed)


def value_for(plan, vector, context=None):
    vector = copy.deepcopy(plan['vectors'][vector])
    return dict(copy.deepcopy(plan['contexts'][vector['context'] if context is None else context]), **vector)


def changed(plan, control):
    value = value_for(plan, control['vector'], control.get('context'))
    for step in control['steps']:
        parent = value
        for component in step['path'][:-1]: parent = parent[int(component)] if type(parent) is list else parent[component]
        key = int(step['path'][-1]) if type(parent) is list else step['path'][-1]
        action = step['action']
        if action == 'set': parent[key] = copy.deepcopy(step['value'])
        elif action == 'delete': del parent[key]
        elif action == 'pop': parent[key].pop()
        elif action == 'duplicate': parent[key].append(copy.deepcopy(parent[key][0]))
        elif action == 'reverse': parent[key].reverse()
        else: raise AssertionError(action)
    return value


def invoke(operation, value):
    if operation == 'selection': return create_selection(value)
    if operation == 'settlement': return create_settlement(value)
    if operation == 'encode_selection': return canonical(selection(value, value['selection']))
    if operation in ('validate', 'encode_settlement'): return canonical(settlement(value, value['settlement']))
    field, limit = ('selection_raw', 4096) if operation == 'decode_selection' else ('settlement_raw', len(canonical(ENVELOPE)) + 4096 + 17 * 4097)
    assert operation in ('decode_selection', 'decode_settlement')
    raw = value[field]; assert type(raw) is str and raw.isascii() and len(raw.encode()) <= limit
    decoded = json.loads(raw); assert canonical(decoded) == raw
    return selection(value, decoded) if operation == 'decode_selection' else settlement(value, decoded)


def rejects(action):
    try: action()
    except (AssertionError, KeyError, ValueError, TypeError, IndexError, UnicodeError): return True
    return False


def domain(plan):
    assert plan['source_revision'] == REVISION
    assert plan['bounds'] == dict(work_entries=17, work_id_bytes=64, selection_bytes=4096, receipt_bytes=4096)
    assert [row['name'] for row in plan['vectors']] == ['historical acquisition', 'historical reuse', 'constructed binary snapshots',
        'one reserved never-started cancelled helper', 'distinct work IDs can reserve the same owner token',
        'work count and ID width ceilings', 'exact encoded selection ceiling']
    prior = json.loads((ROOT / ARCHIVE / 'plan.json').read_bytes())
    for context, source in zip(plan['contexts'][:3], prior['vectors'][:3], strict=True):
        assert context == {key: source[key] for key in ('case', 'request', 'acquired', 'historical_origin') if key in source}
    for context in plan['contexts'][:2]:
        origin = context['historical_origin']; saved = json.loads((ROOT / origin['path']).read_bytes())
        case = next(row for row in saved['cases'] if row['name'] == origin['case_name'])
        assert case['returned'] == 1 and case['error'] == ''
        assert case['request'] == context['request'] and case['context']['store']['path'] == context['case']
        def restore(value):
            if type(value) is list: return [restore(row) for row in value]
            if type(value) is dict: return {('bytes' if key == 'bytes_hex' else key):
                (bytes.fromhex(item).decode('latin1') if key == 'bytes_hex' else restore(item)) for key, item in value.items()}
            return value
        same(case['result'], restore(context['acquired']))
    expected = []
    for outcome in ('completed', 'failed', 'cancelled'):
        for started, reaped, gone in itertools.product([0, 1, '0', '1'], repeat=3):
            expected.append(dict(name='cleanup:' + str(len(expected)), role='capture', outcome=outcome,
                                 flags=[started, reaped, gone], accepted=flag(gone) and (not flag(started) or flag(reaped))))
    same(plan['cleanup_cases'], expected)
    names = [row['name'] for row in plan['controls']]; assert len(names) == len(set(names))
    required = {'encoded selection excess', 'work count excess', 'duplicate selected ID', 'missing receipt', 'duplicate receipt',
                'reordered receipts', 'swapped receipt owner token', 'unsealed selection', 'unreaped started owner',
                'surviving owner group', 'foreign store', 'changed requested evidence', 'acquisition grants runtime authority', 'changed retained octets'}
    for group, fields in [('selection', plan['vectors'][0]['selection']), ('settlement', ENVELOPE),
                          ('entry', ['work_id', 'ownership_token', 'role']), ('receipt', ['work_id', 'ownership_token', 'role', 'outcome', 'cleanup']),
                          ('cleanup', ['leader_started', 'leader_reaped', 'group_gone'])]:
        required.update(group + ' missing ' + field for field in fields)
        required.add(group + ' extra field')
    assert required <= set(names)
    assert [(row['helper'], row['control']) for row in plan['mutants']] == [('_sealed', 'unsealed selection'),
        ('_work_match', 'swapped receipt owner token'), ('_cleanup_settled', 'surviving owner group')]


def verify(plan, report):
    assert report['schema'] == 'fsmgen.inactive_observation_work_record_qualification.v1'
    assert report['success'] is True and report['filesystem_lookup_attempts'] == report['forbidden_process_attempts'] == 0
    assert report['prospective_pins'] == json.loads((BASE / 'preflight-pins.json').read_bytes())
    assert [row['name'] for row in report['vectors']] == [row['name'] for row in plan['vectors']]
    for index, row in enumerate(report['vectors']):
        value = value_for(plan, index); expected_selection = create_selection(value); expected_settlement = create_settlement(value)
        for key in ('selection', 'selection_decoded'): same(row[key], expected_selection)
        for key in ('settlement', 'settlement_decoded'): same(row[key], expected_settlement)
        assert row['selection_raw'] == value['selection_raw'] == canonical(expected_selection)
        assert row['settlement_raw'] == value['settlement_raw'] == canonical(expected_settlement)
        assert row['inputs_unchanged'] == 1
    assert [row['name'] for row in report['cleanup_cases']] == [row['name'] for row in plan['cleanup_cases']]
    for case, row in zip(plan['cleanup_cases'], report['cleanup_cases'], strict=True):
        value = value_for(plan, 0); value['entries'] = value['entries'][:1]; value['selection'] = create_selection(value)
        value['receipts'] = [dict(value['entries'][0], outcome=case['outcome'], cleanup=dict(zip(
            ['leader_started', 'leader_reaped', 'group_gone'], case['flags'], strict=True)))]
        accepted = not rejects(lambda: create_settlement(value))
        assert accepted is case['accepted'] and row['accepted'] == int(accepted) and row['inputs_unchanged'] == 1
        if accepted:
            assert row['error'] == ''; same(row['output'], create_settlement(value))
        else:
            assert row['error'] and row['output'] is None
    assert [row['name'] for row in report['controls']] == [row['name'] for row in plan['controls']]
    for control, row in zip(plan['controls'], report['controls'], strict=True):
        assert row['rejected'] == row['inputs_unchanged'] == 1 and type(row['error']) is str and row['error']
        if 'argument_change' not in control and 'upgrade' not in control:
            assert rejects(lambda: invoke(control['operation'], changed(plan, control))), control['name']
    assert [row['name'] for row in report['mutants']] == [row['name'] for row in plan['mutants']]
    for mutant, row in zip(plan['mutants'], report['mutants'], strict=True):
        control = next(row for row in plan['controls'] if row['name'] == mutant['control'])
        assert row['accepted'] == 1 and row['error'] == ''
        value = changed(plan, control)
        assert rejects(lambda: settlement(value, row['output'])), mutant['name']
    return dict(vectors=len(report['vectors']), cleanup_cases=len(report['cleanup_cases']),
                accepted_cleanup_cases=sum(row['accepted'] for row in report['cleanup_cases']),
                rejected_controls=len(report['controls']), helper_mutants=len(report['mutants']),
                selection_ceiling_bytes=len(report['vectors'][-1]['selection_raw'].encode()),
                maximum_work_entries=len(report['vectors'][-2]['selection']['entries']), historical_acquisitions=2)


def authenticate(plan):
    pins = json.loads((BASE / 'preflight-pins.json').read_bytes())
    assert [row['path'] for row in pins] == [str((BASE / name).relative_to(ROOT)) for name in ['plan.json', 'prepare.py', 'WorkRecord.pm', 'qualify.t', 'audit.py']]
    for row in plan['inputs'] + pins:
        path = ROOT / row['path']; raw = path.read_bytes()
        assert len(raw) == row['size_bytes'] and hashlib.sha256(raw).hexdigest() == row['sha256']
        assert path.stat().st_dev == ROOT.stat().st_dev
        for ancestor in [path, *path.parents]:
            if ancestor == ROOT: break
            assert not ancestor.is_symlink()
        if row in plan['inputs']:
            assert raw == subprocess.check_output(['git', 'show', REVISION + ':' + row['path']], cwd=ROOT)
    return pins


def main():
    plan = json.loads((BASE / 'plan.json').read_bytes()); pins = authenticate(plan); domain(plan)
    report = json.loads((LOG / 'qualification.json').read_bytes()); counts = verify(plan, report)
    raw = (LOG / 'qualify.tap').read_text(); assertions = 8 * counts['vectors'] + counts['cleanup_cases'] + counts['rejected_controls'] + counts['helper_mutants'] + 2
    assert re.findall(r'^ok ([0-9]+) - ', raw, re.M) == [str(i) for i in range(1, assertions + 1)]
    assert re.findall(r'^1\.\.([0-9]+)$', raw, re.M) == [str(assertions)]
    assert not re.search(r'^(not ok|Bail out!)|#\s*(skip|todo)\b', raw, re.M | re.I)
    assert (LOG / 'qualify.exit').read_bytes() == b'0\n'
    changes = [
        ('wrong selection bytes', lambda r: r['vectors'][0].update(selection_raw='{}')),
        ('wrong settlement bytes', lambda r: r['vectors'][0].update(settlement_raw='{}')),
        ('lost evidence identity', lambda r: r['vectors'][0]['selection']['evidence_directory_identity'].update(inode=7)),
        ('lost original role', lambda r: r['vectors'][0]['settlement']['receipts'][0].update(role='helper')),
        ('failed outcome becomes completed', lambda r: r['vectors'][0]['settlement']['receipts'][1].update(outcome='completed')),
        ('changed cleanup scalar type', lambda r: r['vectors'][0]['settlement']['receipts'][0]['cleanup'].update(group_gone='1')),
        ('missing positive', lambda r: r['vectors'].pop()),
        ('missing cleanup case', lambda r: r['cleanup_cases'].pop()),
        ('changed cleanup decision', lambda r: r['cleanup_cases'][0].update(accepted=1)),
        ('missing malformed control', lambda r: r['controls'].pop()),
        ('invalid record admitted', lambda r: r['controls'][0].update(rejected=0)),
        ('input mutation', lambda r: r['vectors'][0].update(inputs_unchanged=0)),
        ('hidden lookup', lambda r: r.update(filesystem_lookup_attempts=1)),
        ('hidden process', lambda r: r.update(forbidden_process_attempts=1)),
        ('missing mutant', lambda r: r['mutants'].pop()),
        ('ineffective mutant', lambda r: r['mutants'][0].update(accepted=0)),
        ('valid mutant result', lambda r: r['mutants'][0].update(output=copy.deepcopy(plan['vectors'][0]['settlement']))),
    ]
    for name, change in changes:
        altered = copy.deepcopy(report); change(altered); assert rejects(lambda: verify(plan, altered)), name
    altered_domain = copy.deepcopy(plan); altered_domain['cleanup_cases'].pop()
    assert rejects(lambda: domain(altered_domain))
    authenticate(plan)
    output = dict(schema='fsmgen.inactive_observation_work_record_audit.v1', success=True, **counts,
                  tap_assertions=assertions, predecessor_inputs_unchanged=len(plan['inputs']), prospective_inputs_unchanged=len(pins),
                  report_falsifiers=[row[0] for row in changes], domain_falsifiers=['missing scalar cleanup combination'], scope=plan['scope'])
    with (LOG / 'audit.json').open('x') as stream: stream.write(json.dumps(output, indent=2, sort_keys=True) + '\n')
    print(json.dumps(output, sort_keys=True))


if __name__ == '__main__':
    main()

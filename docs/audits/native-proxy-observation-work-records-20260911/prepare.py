"""Prospective deterministic work-record vectors and malformed controls."""
from __future__ import annotations

import copy
import hashlib
import itertools
import json
from pathlib import Path
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
REVISION = 'da75e940ec226936828984e77774e9c044cdd8ed'
OWNER = 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.7.3.12.4.1.3.4.3.1'
ARCHIVE = 'docs/audits/native-proxy-observation-archive-records-20260911'
CONTRACT = 'docs/audits/native-proxy-observation-release-contract-20260911'
SELECTION = 'fsmgen.inactive_observation_work_selection.v1'
SETTLEMENT = 'fsmgen.inactive_observation_work_settlement.v1'
ROLES = ['capture', 'helper', 'query']
OUTCOMES = ['completed', 'failed', 'cancelled']
FLAGS = [0, 1, '0', '1']


def canonical(value):
    return json.dumps(value, ensure_ascii=True, sort_keys=True, separators=(',', ':'))


def token(name): return hashlib.sha256(name.encode()).hexdigest()


def entry(index, role=None, width=None):
    name = 'work:' + str(index)
    if width is not None: name += 'x' * (width - len(name))
    return dict(work_id=name, ownership_token=token('owner:' + str(index)), role=role or ROLES[index % len(ROLES)])


def receipt(selected, outcome='completed', flags=(1, 1, 1)):
    return dict(selected, outcome=outcome, cleanup=dict(zip(['leader_started', 'leader_reaped', 'group_gone'], flags, strict=True)))


def selected(context, entries):
    return dict(schema=SELECTION, runtime_authorized=0, executable=None,
                evidence_directory_identity=copy.deepcopy(context['request']['evidence_directory_identity']),
                observation_reference_key=context['acquired']['observation_reference']['record']['reference_key'], entries=copy.deepcopy(entries))


def settled(selection, receipts, sealed=1):
    return dict(schema=SETTLEMENT, runtime_authorized=0, executable=None, selection=copy.deepcopy(selection),
                selection_sealed=sealed, receipts=copy.deepcopy(receipts))


def rebind_evidence(context, name):
    """Construct a new consistent historical-data vector; never touch its paths."""
    value = copy.deepcopy(context); value.pop('historical_origin', None)
    evidence = value['request']['evidence_directory_identity']; evidence['path'] = name
    hold = value['acquired']['observation_reference']; record = hold['record']
    record['evidence_directory'] = name; record['evidence_directory_identity'] = copy.deepcopy(evidence)
    record['reference_key'] = hashlib.sha256(b'fsmgen.rust_proxy_reference.observation.v1\0' + canonical(
        [name, record['observer_birth'], record['target_birth']]).encode()).hexdigest()
    raw = canonical(record).encode(); assert len(raw) <= 4096
    hold['source']['bytes_hex'] = raw.hex()
    hold['source']['identity'].update(path=value['case'] + '/references/' + record['reference_key'] + '.json',
                                     size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())
    return value


def build():
    old = json.loads((ROOT / ARCHIVE / 'plan.json').read_bytes())
    contexts = [{key: copy.deepcopy(row[key]) for key in ['case', 'request', 'acquired', 'historical_origin'] if key in row}
                for row in old['vectors'][:3]]
    vectors = []
    def add(name, context, entries, receipts=None):
        receipts = receipts if receipts is not None else [receipt(row, OUTCOMES[i % 3]) for i, row in enumerate(entries)]
        selection = selected(contexts[context], entries); settlement = settled(selection, receipts)
        vectors.append(dict(name=name, context=context, entries=copy.deepcopy(entries), receipts=copy.deepcopy(receipts),
                            sealed=1, selection=selection, settlement=settlement,
                            selection_raw=canonical(selection), settlement_raw=canonical(settlement)))
    for index, label in enumerate(['historical acquisition', 'historical reuse', 'constructed binary snapshots']):
        add(label, index, [entry(i) for i in range(3)])
    add('one reserved never-started cancelled helper', 0, [entry(0, 'helper')], [receipt(entry(0, 'helper'), 'cancelled', ('0', '0', '1'))])
    same_owner = [entry(0), dict(entry(1), ownership_token=entry(0)['ownership_token'])]
    add('distinct work IDs can reserve the same owner token', 0, same_owner)
    entries = [entry(i, width=64) for i in range(17)]
    add('work count and ID width ceilings', 0, entries)
    prefix = '.artifacts/logs/native-proxy-observation-acquisition-20260910/cases/fsmgen-'
    base = rebind_evidence(contexts[0], prefix + 'a')
    needed = 4096 - len(canonical(selected(base, entries)).encode())
    assert needed > 0
    contexts.append(rebind_evidence(base, prefix + 'a' * (needed + 1)))
    add('exact encoded selection ceiling', len(contexts) - 1, entries)
    assert len(vectors[-1]['selection_raw'].encode()) == 4096
    contexts.append(rebind_evidence(base, prefix + 'a' * (needed + 2)))
    excess_context = len(contexts) - 1
    assert len(canonical(selected(contexts[excess_context], entries)).encode()) == 4097

    cleanup = []
    for outcome, values in itertools.product(OUTCOMES, itertools.product(FLAGS, repeat=3)):
        started, reaped, gone = [value in (1, '1') for value in values]
        cleanup.append(dict(name='cleanup:' + str(len(cleanup)), role='capture', outcome=outcome, flags=list(values),
                            accepted=gone and (not started or reaped)))
    controls = []
    def control(name, operation, path=None, action='set', value=None, **extra):
        steps = [] if path is None else [dict(path=path.split('.'), action=action, **({'value': value} if action == 'set' else {}))]
        controls.append(dict(name=name, operation=operation, vector=0, steps=steps, **extra))
    # Closed-field and type controls are independently enumerated in the oracle.
    for field in vectors[0]['selection']:
        control('selection missing ' + field, 'encode_selection', 'selection.' + field, 'delete')
    control('selection extra field', 'encode_selection', 'selection.extra', value=0)
    for field, values in {'schema': ['foreign', None], 'runtime_authorized': [1, '0', True], 'executable': ['run'],
                          'observation_reference_key': ['0' * 64], 'evidence_directory_identity': [None, {}],
                          'entries': [None, {}, []]}.items():
        for i, value in enumerate(values): control('selection invalid ' + field + ':' + str(i), 'encode_selection', 'selection.' + field, value=value)
    for field in ['path', 'device', 'inode']:
        control('selection changed evidence ' + field, 'encode_selection', 'selection.evidence_directory_identity.' + field,
                value='foreign' if field == 'path' else 7)
    for field in ['work_id', 'ownership_token', 'role']:
        control('entry missing ' + field, 'selection', 'entries.0.' + field, 'delete')
    control('entry extra field', 'selection', 'entries.0.extra', value=0)
    for field, values in {'work_id': ['', 'x' * 65, 'space value', 'caf\u00e9', 1, None, {}],
                          'ownership_token': ['0' * 63, 'A' * 64, 1, None], 'role': ['compiler', '', 1, None]}.items():
        for i, value in enumerate(values): control('entry invalid ' + field + ':' + str(i), 'selection', 'entries.0.' + field, value=value)
    control('duplicate selected ID', 'selection', 'entries', 'duplicate')
    control('work count excess', 'selection', 'entries', value=[entry(i) for i in range(18)])
    control('encoded selection excess', 'selection', 'entries', value=entries, context=excess_context)
    for field in vectors[0]['settlement']:
        control('settlement missing ' + field, 'validate', 'settlement.' + field, 'delete')
    control('settlement extra field', 'validate', 'settlement.extra', value=0)
    for field, values in {'schema': ['foreign', None], 'runtime_authorized': [1, '0', True], 'executable': ['run'],
                          'selection': [None, {}], 'selection_sealed': [0, '1', True, None, {}]}.items():
        for i, value in enumerate(values): control('settlement invalid ' + field + ':' + str(i), 'validate', 'settlement.' + field, value=value)
    for field in ['work_id', 'ownership_token', 'role', 'outcome', 'cleanup']:
        control('receipt missing ' + field, 'settlement', 'receipts.0.' + field, 'delete')
    control('receipt extra field', 'settlement', 'receipts.0.extra', value=0)
    for label, action in [('missing receipt', 'pop'), ('duplicate receipt', 'duplicate'), ('reordered receipts', 'reverse')]:
        control(label, 'settlement', 'receipts', action)
    for i, value in enumerate([None, {}, [], [None, None, None]]):
        control('invalid receipt list:' + str(i), 'settlement', 'receipts', value=value)
    for field, values in {'work_id': ['other'], 'ownership_token': ['0' * 64], 'role': ['helper'],
                          'outcome': ['success', '', 0, None], 'cleanup': [None, {}, []]}.items():
        for i, value in enumerate(values): control('receipt invalid ' + field + ':' + str(i), 'settlement', 'receipts.0.' + field, value=value)
    for field in ['leader_started', 'leader_reaped', 'group_gone']:
        control('cleanup missing ' + field, 'settlement', 'receipts.0.cleanup.' + field, 'delete')
        for i, value in enumerate([True, False, None, 2, -1, '01', '', [], {}]):
            control('cleanup invalid ' + field + ':' + str(i), 'settlement', 'receipts.0.cleanup.' + field, value=value)
    control('cleanup extra field', 'settlement', 'receipts.0.cleanup.extra', value=0)
    control('unreaped started owner', 'settlement', 'receipts.0.cleanup.leader_reaped', value=0)
    control('surviving owner group', 'settlement', 'receipts.0.cleanup.group_gone', value=0)
    control('unsealed selection', 'settlement', 'sealed', value=0)
    for field in ['selection_raw', 'settlement_raw']:
        operation = 'decode_selection' if field == 'selection_raw' else 'decode_settlement'
        raw = vectors[0][field]
        for label, value in [('whitespace', raw + '\n'), ('malformed', '{'), ('scalar', 'null'),
                             ('duplicate key', raw[:-1] + ',"schema":"foreign"}'), ('nonASCII', '\u00ff'),
                             ('overlong', ' ' * (4097 if field == 'selection_raw' else 75000))]:
            control(field + ':' + label, operation, field, value=value)
        control(field + ':character-flag', operation, upgrade=field)
    for operation in ['selection', 'encode_selection', 'decode_selection', 'settlement', 'validate', 'encode_settlement', 'decode_settlement']:
        for change in ['drop', 'append']: control(operation + ':arity:' + change, operation, argument_change=change)
    for name, path, value in [
        ('foreign store', 'case', 'foreign'),
        ('changed requested evidence', 'request.evidence_directory_identity.inode', 7),
        ('acquisition grants runtime authority', 'acquired.runtime_authorized', 1),
        ('changed retained octets', 'acquired.target_sources.0.bytes_hex', '00')]:
        control(name, 'selection', path, value=value)
    # Tokens bind by selected work identity; one receipt cannot replace another.
    control('swapped receipt owner token', 'settlement', 'receipts.0.ownership_token', value=vectors[0]['receipts'][1]['ownership_token'])
    mutants = [dict(name=name, helper=helper, control=control_name) for name, helper, control_name in [
        ('seal omitted', '_sealed', 'unsealed selection'), ('owner binding omitted', '_work_match', 'swapped receipt owner token'),
        ('cleanup omitted', '_cleanup_settled', 'surviving owner group')]]
    paths = {row['path'] for row in old['inputs']}
    paths.update([ARCHIVE + '/' + name for name in ['plan.json', 'ArchiveRecord.pm', 'audit.py']])
    paths.update([CONTRACT + '/' + name for name in ['contract.json', 'model.py', 'audit.py', 'result/audit.json']])
    paths.update(['docs/audits/native-proxy-cleanup-receipts-20260910/CleanupReceipts.pm',
                  'docs/audits/native-proxy-observation-archive-final-join-20260911/result/audit.json'])
    pins = []
    for path in sorted(paths):
        raw = (ROOT / path).read_bytes(); assert raw == subprocess.check_output(['git', 'show', REVISION + ':' + path], cwd=ROOT)
        pins.append(dict(path=path, size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest()))
    return dict(schema='fsmgen.inactive_observation_work_record_plan.v1', owner=OWNER, source_revision=REVISION,
                contexts=contexts, vectors=vectors, cleanup_cases=cleanup, controls=controls, mutants=mutants, inputs=pins,
                bounds=dict(work_entries=17, work_id_bytes=64, selection_bytes=4096, receipt_bytes=4096),
                scope='Pure inactive record consistency. Two historical acquisition bindings plus constructed byte/profile/limit data; no current target or archive lookup, process launch, actual late-launch prevention, native receipt authenticity, hold release or product activation. Cleanup accepts the existing scalar numeric/string zero/one spellings, independently of completed/failed/cancelled outcome. Work IDs are unique; the contract does not require distinct tokens for distinct work entries. Aggregate wire size derives conservatively from the bounded selection, receipt roster and fixed envelope.')


if __name__ == '__main__':
    plan = build()
    with (BASE / 'plan.json').open('x') as stream:
        stream.write(json.dumps(plan, indent=2, sort_keys=True) + '\n')
    print(json.dumps(dict(vectors=len(plan['vectors']), cleanup_cases=len(plan['cleanup_cases']), controls=len(plan['controls']),
                         mutants=len(plan['mutants']), inputs=len(plan['inputs'])), sort_keys=True))

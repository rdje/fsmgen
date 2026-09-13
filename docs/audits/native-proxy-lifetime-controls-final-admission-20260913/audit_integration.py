"""Verify retained setup observations and complete synthetic reader carriers."""
import argparse
from copy import deepcopy as clone
from support_final import BASE, H, M, C, pin, read, reader, record, write
from resources import opened_identities, resources


def verify():
    for row in read(BASE / 'integration-pins.json'):
        from support_final import ROOT
        assert pin(ROOT / row['path']) == row
    carrier = read(BASE / 'integration-carrier.json')
    assert carrier['actual_fixture_operations'] == 0
    assert carrier['synthetic_control_and_cleanup'] is carrier['synthetic_timing'] is True
    selected = read(M / 'selection.json')
    payloads = {name.removesuffix('_hex'): bytes.fromhex(body) for name, body in read(H / 'prepared.json')['payloads'].items()}
    records = carrier['records']; selection = carrier['selection']
    assert len(selection['cases']) == 2
    for case in selection['cases']:
        original = clone(next(row for row in selected['cases'] if row['name'] == case['name']))
        original['roots'] = record(73)['value']['paths']
        assert case == original and case['prefix'] == []
        stages = [row['value'] for row in records if row['kind'] == 'stage' and row['value']['case'] == case['name']]
        for index, stage in enumerate(stages[:6]):
            original = record(67 + index)['value']; original['case'] = case['name']
            assert stage == original
        context = next(row['value'] for row in records if row['kind'] == 'case-initial' and row['value']['name'] == case['name'])
        original = record(73)['value']; original['name'] = case['name']; assert context == original
    # Exercise all creation/open joins on actual retained setup observations.
    flags = records[0]['value']['admission']['native_open_flags']
    uid = records[0]['value']['normal_uid']
    context = record(73)['value']; device = context['directories']['store']['device']
    roots = context['roots']; setup = [record(index)['value'] for index in range(67, 73)]
    created_opens = []
    for index, stage in enumerate(setup):
        operation = stage['operation']
        resources(operation, roots, selection['trace_limits'], native_flags=flags)
        opened_identities(operation, stage['before']['result']['nodes'], stage['after']['result']['nodes'], uid, device, flags)
        for handle in operation['handles']:
            call = operation['calls'][handle['opening_call']]
            if call['operation'] == 'sysopen' and call['flags'] & flags['O_CREAT'] and call['flags'] & flags['O_EXCL']:
                created_opens.append(dict(record=67+index, ordinal=handle['ordinal'], path=handle['path']))
    assert created_opens
    result = reader.verify(records, selection, payloads)
    rejected = []

    def reject(label, change):
        altered = clone(records); change(altered)
        try: reader.verify(altered, selection, payloads)
        except (AssertionError, KeyError, IndexError, ValueError, TypeError): rejected.append(label)
        else: raise AssertionError('reader accepted countermodel: ' + label)

    def stage(rows, name):
        return next(row['value'] for row in rows if row['kind'] == 'stage' and row['value']['name'] == name)

    reject('missing_setup_record', lambda rows: rows.pop(2))
    reject('wrong_sequence', lambda rows: rows[2].update(sequence=700))
    reject('wrong_initial_setup_receipt', lambda rows: stage(rows, 'create_owned_roots')['operation']['result'].clear())
    reject('promoted_release_success', lambda rows: stage(rows, 'selected_control')['operation']['result'].update(success=1))
    reject('lost_release_error', lambda rows: stage(rows, 'selected_control')['operation']['result'].update(error=''))
    reject('caller_input_changed', lambda rows: stage(rows, 'selected_control').update(input_after={}))
    reject('cleanup_ownership_lost', lambda rows: next(row['value'] for row in rows if row['kind']=='cleanup-admission')['created_identities'].clear())
    reject('cleanup_removal_omitted', lambda rows: stage(rows, 'owned_cleanup')['operation']['calls'].pop())
    reject('cleanup_snapshot_changed', lambda rows: stage(rows, 'owned_cleanup')['input_before']['expected']['nodes'].clear())
    opening = created_opens[0]
    def alter_open(rows, field, value):
        target = stage(rows, setup[opening['record']-67]['name'])
        target['operation']['handles'][opening['ordinal']]['native_at_open'][field] = value
    for label, field, value in [('created_wrong_uid', 4, uid+1), ('created_wrong_device', 0, device+1),
                                ('created_wrong_mode', 2, 0o100400), ('created_wrong_links', 3, 2),
                                ('created_nonempty_at_open', 7, 1), ('created_wrong_inode', 1, -1)]:
        reject(label, lambda rows, field=field, value=value: alter_open(rows, field, value))
    return dict(schema='fsmgen.lifetime_control_reader_integration.v1', actual_fixture_operations=0,
        retained_setup_stages=len(setup), retained_exclusive_opens=created_opens,
        synthetic_complete_reader=result, synthetic_control_and_cleanup=True, rejected_countermodels=rejected,
        actual_interruption_execution_pending=True)


def main():
    parser=argparse.ArgumentParser(); group=parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--retain', action='store_true'); group.add_argument('--verify-saved', action='store_true')
    args=parser.parse_args(); result=verify()
    if args.retain: write(BASE/'integration-review.json', result)
    else: assert read(BASE/'integration-review.json') == result
    print('Reader integration: OK; retained setup and synthetic complete journals; no fixture execution.')


if __name__ == '__main__':
    main()

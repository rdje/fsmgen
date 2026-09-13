"""Author explicitly counterfactual reader carriers without touching fixture paths.

Only setup observations are retained actual records. Rejections, the cleanup
operation and journal timing are invented test data, never execution evidence.
The reader is exercised separately against this saved carrier.
"""
from copy import deepcopy as clone
from support_final import BASE, H, M, C, read, record, write


def empty_trace(result=None, error=''):
    return dict(calls=[], handles=[], metadata_observers=[], recovery=[],
                ownership_registration_error_hex='', returned=int(not error),
                error_hex=error.encode().hex(), result=result)


def main():
    selection = read(M / 'selection.json')
    selected = [clone(case) for case in selection['cases']
                if case['name'] in ('release_before_archive', 'unreaped_runtime')]
    payloads = {name.removesuffix('_hex'): bytes.fromhex(body) for name, body in read(H / 'prepared.json')['payloads'].items()}
    original_context = record(73)['value']
    selected_records = []
    final_cases = []

    def append(kind, value):
        selected_records.append(dict(schema='fsmgen.inactive_lifetime_controls_event.v1',
            sequence=len(selected_records), kind=kind,
            monotonic_ns=len(selected_records) * 1_000_000, value=clone(value)))

    append('run-started', record(0)['value'])
    for case in selected:
        case['roots'] = clone(original_context['paths'])
        roots = [case['roots'][key] for key in ('store', 'target', 'other', 'evidence')]
        context = clone(original_context); context['name'] = case['name']
        append('case-intent', dict(case=case, synthetic_ownership_only=1, roots_absent_before_creation=roots))
        setup = [record(index)['value'] for index in range(67, 73)]
        for row in setup:
            row['case'] = case['name']; append('stage', row)
        append('case-initial', context)
        seed = C.initial(context, payloads, bytes.fromhex(selection['payload_source']['different_image_suffix_hex']))
        probe = clone(setup[-1]['after'])

        def stage(name, inputs, trace, after, control=None):
            value = dict(case=case['name'], name=name, before=probe, operation=trace, after=after,
                         input_before=inputs, input_after=inputs, started_monotonic_ns=0, ended_monotonic_ns=1)
            if control is not None: value['control'] = control
            append('stage', value)

        if case['name'] == 'release_before_archive':
            observer = seed['observers']['a']
            inputs = dict(store=context['paths']['store'], request=observer['request'], acquired=observer['acquired'],
                          archive=None, selection=observer['selection'], settlement=observer['settlement'])
            failure = dict(schema='fsmgen.inactive_observation_release_attempt.v1', runtime_authorized=0,
                executable=None, success=0, error='expected closed record fields\n', release=None,
                unlink_attempted=0, unlink_completed=0, reference_absence_verified=0, last_reference_check=None)
            trace = empty_trace(failure)
        else:
            inputs = C.event_input('retire_target', context, seed)
            inputs['cleanup']['stages'][0]['cleanup']['leader_reaped'] = 0
            trace = empty_trace(error='complete compiler, outer and inner cleanup is unproved\n')
        stage('selected_control', inputs, trace, probe, dict(event=case['event'], selector=None, hits=[]))
        maintenance = dict(store=context['paths']['store'], image_key=seed['target_image'])
        stage('followup_maintenance', maintenance,
              empty_trace(error='selected image is retained by an unresolved reference\n'), probe,
              dict(event='maintain_target', selector=None, hits=[]))
        append('case-primary', dict(case=case['name'], returned=1, error_hex=''))
        # The independently observed initial nodes define this synthetic ledger.
        owned = {path: dict(path=path, device=node['identity']['device'], inode=node['identity']['inode'], kind=node['kind'])
                 for path, node in context['initial']['nodes'].items()}
        append('cleanup-admission', dict(case=case['name'], created_identities=owned, observed=probe))
        removed = sorted(owned, key=lambda path: (-path.count('/'), path))
        result = dict(absent_roots=roots, removed=removed)
        trace = empty_trace(result)
        for path in removed:
            trace['calls'].append(dict(operation='rmdir', path=path, returned=1) if owned[path]['kind'] == 'directory'
                                  else dict(operation='unlink', paths=[path], returned=1))
        stage('owned_cleanup', dict(roots=roots, expected=probe['result']), trace, record(92)['value']['after'])
        final = dict(case=case['name'], primary_returned=1, error_hex='', cleanup_returned=1,
                     cleanup_error_hex='', cleanup=result)
        append('case-final', final); final_cases.append(final)
    selection['cases'] = selected
    append('run-final', dict(success=1, forbidden_process_attempts=0, runtime_qualification=0,
                            elapsed_ns=len(selected_records)*1_000_000, cases=final_cases))
    write(BASE / 'integration-carrier.json', dict(schema='fsmgen.synthetic_lifetime_control_reader_carrier.v1',
        actual_fixture_operations=0, synthetic_control_and_cleanup=True, synthetic_timing=True,
        retained_setup_records=list(range(67, 74)), selection=selection, records=selected_records))
    print('Prepared synthetic full-reader carriers; no fixture operation executed.')


if __name__ == '__main__':
    main()

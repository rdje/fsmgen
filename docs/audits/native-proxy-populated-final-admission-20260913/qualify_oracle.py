"""Challenge the independent journal join using full synthetic driver records."""
import copy
import json

from contract import ROOT, WORKER_CONTRACT, bounds, canonical, cases
import oracle
from qualify_driver import run_case, qualify as qualify_driver
import records


def evidence(case, prior, toolchains):
    machine, result = run_case(case, prior, toolchains)
    if not result['success']:
        raise AssertionError('oracle input model failed before review: ' + str(result['first_error']))
    return dict(case=case, activation=canonical(machine.documents[case['activation_path']]),
        handoff=canonical(machine.documents[case['handoff_path']]) if case['handoff_path'] else None,
        rows=machine.journal, streams={role: {name: bytes(body) for name, body in worker.buffers.items()}
            for role, worker in machine.workers.items()}, outcome=result, interpreter=toolchains['perl'])


def check(value):
    rows = [dict(row, sequence=index, elapsed_ns=index * 1000) for index, row in enumerate(value['rows'])]
    encoded = b''.join(canonical(row) + b'\n' for row in rows)
    parsed = oracle.journal_rows(encoded)
    result = oracle.check_case(value['case'], value['activation'], parsed, value['streams'], value['outcome'], value['interpreter'], value['handoff'])
    return dict(result, journal_rows=len(parsed), journal_bytes=len(encoded),
                worker_bytes=sum(len(body) for streams in value['streams'].values() for body in streams.values()))


def change_event(value, role, name, mutate):
    row = next(row for row in value['rows'] if row['event'] == 'controller_worker_event'
        and row['role'] == role and row['value']['event'] == name)
    mutate(row['value'])
    body = b''.join(canonical(row['value']) + b'\n' for row in value['rows']
        if row['event'] == 'controller_worker_event' and row['role'] == role)
    value['streams'][role]['stdout'] = body
    value['outcome']['outcomes'][role]['retained_prefixes']['stdout'] = records.file_pin(body)
    terminal = next(row for row in value['rows'] if row['event'] == 'worker_outcome' and row['role'] == role)
    terminal['outcome'] = copy.deepcopy(value['outcome']['outcomes'][role])


def qualify():
    driver = qualify_driver()
    prior = json.loads((ROOT / WORKER_CONTRACT).with_name('qualification.json').read_bytes())
    toolchains = json.loads((ROOT / 'docs/audits/native-proxy-populated-final-admission-20260913/installed-first.json').read_bytes())['result']['toolchains']
    inputs = [evidence(case, previous, toolchains) for case, previous in zip(cases(), prior['cases'])]
    joined = [check(value) for value in inputs]
    rejected = []

    def reject(name, original, mutate):
        value = copy.deepcopy(original)
        mutate(value)
        try:
            check(value)
        except (ValueError, KeyError, TypeError, StopIteration) as error:
            rejected.append(dict(name=name, error=str(error)))
        else:
            raise AssertionError('altered independent evidence accepted: ' + name)

    first, observation, cancelled = inputs[0], inputs[2], inputs[5]
    reject('missing original worker stream line', first, lambda value: value['streams']['publisher_a'].update(stdout=value['streams']['publisher_a']['stdout'].split(b'\n', 1)[1]))
    reject('unaccounted worker stderr', first, lambda value: value['streams']['publisher_b'].update(stderr=b'failure\n'))
    reject('changed admitted native executable', first, lambda value: next(row for row in value['rows'] if row['event'] == 'controller_native_admitted')['image'].update(sha256='0' * 64))
    reject('changed original worker birth', first, lambda value: next(row for row in value['rows'] if row['event'] == 'controller_native_owned')['identity'].update(start_usec=0))
    reject('boolean lock closure with matching raw stream hashes', first,
        lambda value: change_event(value, 'publisher_a', 'result', lambda event: event['lock'].update(descriptor_closed=True)))
    reject('different lock inode with matching raw stream hashes', first,
        lambda value: change_event(value, 'publisher_a', 'opened', lambda event: event.update(inode=1)))
    reject('wrong busy errno with matching raw stream hashes', first,
        lambda value: change_event(value, 'publisher_b', 'busy', lambda event: event.update(errno=errno_value())))
    reject('missing original operation acceptance', first,
        lambda value: value['rows'].remove(next(row for row in value['rows'] if row['event'] == 'operation_accepted')))
    reject('missing settled fixture snapshot', first,
        lambda value: value['rows'].remove(next(row for row in value['rows'] if row['event'] == 'case_snapshot' and row['phase'] == 'workers_settled')))
    reject('missing original cleanup node', first,
        lambda value: value['rows'].remove(next(row for row in value['rows'] if row['event'] == 'removed')))
    reject('invented extra removal', first, lambda value: value['outcome']['cleanup']['removed'].append('undeclared'))
    reject('changed retained file mode in snapshot', first,
        lambda value: next(node for row in value['rows'] if row['event'] == 'case_snapshot' for node in row['snapshot']['nodes'].values()
            if node['identity']['path'].endswith('/rustup'))['identity'].update(mode=0o400))
    reject('changed retained inode in snapshot', first,
        lambda value: next(node for row in value['rows'] if row['event'] == 'case_snapshot' for node in row['snapshot']['nodes'].values()
            if node['identity']['path'].endswith('/rustup'))['identity'].update(inode=1))
    reject('observation archive omitted from terminal closure', observation,
        lambda value: next(row for row in value['rows'] if row['event'] == 'case_snapshot' and row['phase'] == 'workers_settled')['snapshot']['nodes'].pop(
            next(path for path in value['outcome']['cleanup']['removed'] if path.endswith('.source'))))
    reject('handoff reconstructed from changed bytes', cancelled,
        lambda value: value.update(handoff=value['handoff'] + b'\n'))
    reject('cancelled worker promoted to ordinary completion', cancelled,
        lambda value: value['outcome']['outcomes']['observer'].update(healthy=True, separate_recovery=False))
    reject('requested signal without matching terminal signal exit', cancelled,
        lambda value: value['outcome']['outcomes']['observer'].update(exit_code=0))
    reject('unsettled cancelled process group', cancelled,
        lambda value: value['outcome']['outcomes']['observer'].update(group_gone=False))
    require_counts = dict(cases=len(joined), workers=sum(row['workers'] for row in joined),
        completed_operations=sum(row['completed_operations'] for row in joined),
        commands=sum(row['commands'] for row in joined), cleanup_nodes=sum(row['cleanup_nodes'] for row in joined),
        cancelled_workers=sum(row['cancelled_workers'] for row in joined), archives=sum(row['retained_archives'] for row in joined))
    if require_counts != dict(cases=6, workers=15, completed_operations=45, commands=120, cleanup_nodes=42, cancelled_workers=2, archives=3):
        raise AssertionError('independently reconstructed fixed counts differ')
    return dict(schema='fsmgen.inactive_populated_oracle_qualification.v1', counts=require_counts, cases=joined,
        rejecting_controls=rejected, driver_checks=len(driver['checks']), driver_rejecting_cases=len(driver['rejecting_cases']),
        driver_qualification=driver,
        prospective_bounds=bounds(), actual_worker_execution=False, actual_fixture_allocation=False,
        synthetic_native_records=True, scope='Independent journal, byte and identity join over synthetic records.')


def errno_value():
    # Deliberately not EWOULDBLOCK on the selected Darwin platform.
    return 2


if __name__ == '__main__':
    print(json.dumps(qualify(), sort_keys=True, indent=2))

"""Revalidate original finite domains and compose their authenticated results."""
from __future__ import annotations

from collections import Counter
import copy
import json
import re

import evidence as E
import replay

BOUNDARY = 'docs/audits/native-proxy-observation-archive-boundaries-20260911'
TRACED = ['boundaries', 'ordinary-fresh', 'ordinary-existing', 'equal-fresh', 'equal-existing',
          'partial-writes', 'close-reports', 'omitted-closes', 'namespace', 'replacements']
PRIMARY = ['records', 'files', *TRACED, 'guards', 'observer', 'reader-failures']


def tap(raw):
    assert not re.search(r'^(?:not ok|Bail out!)|#\s*(?:SKIP|TODO)\b', raw, re.M | re.I)
    plans = re.findall(r'^1\.\.([0-9]+)$', raw, re.M); assert len(plans) == 1
    count = int(plans[0])
    assert re.findall(r'^ok ([0-9]+) - ', raw, re.M) == [str(n) for n in range(1, count + 1)]
    return count


def archive_summary(counts):
    """Compose child-oracle counts; the final auditor walks original operations."""
    result = Counter()
    for name in TRACED:
        count = counts[name]
        result['traced_operations'] += count.get('operations', count.get('cases', 0))
        result['traced_events'] += count.get('events', count.get('preparation_events', 0) + count.get('interruption_events', 0))
        for kind in ['source', 'writer', 'directory']:
            field = kind + '_handles'
            result[field] += count.get(field, count.get('preparation_' + field, 0) + count.get('interruption_' + field, 0))
    result['traced_handles'] = sum(result[kind + '_handles'] for kind in ['source', 'writer', 'directory'])
    result['archive_operations'] = result['traced_operations'] + counts['files']['operations']
    result['legacy_source_observations'] = counts['files']['observed_source_descriptors']
    result['omitted_closes'] = counts['omitted-closes']['omitted_and_recovered']
    result['implementation_closes'] = result['traced_handles'] - result['omitted_closes']
    result['counterimplementation_returns'] = counts['omitted-closes']['counterimplementation_returns']
    result['closure_rejections'] = counts['omitted-closes']['closure_rejections']
    result['modeled_close_errors'] = counts['close-reports']['modeled_errors']
    result['actual_partial_write_calls'] = counts['partial-writes']['actual_syscalls']
    result['actual_partial_written_bytes'] = counts['partial-writes']['actual_written_bytes']
    return dict(result)


def record_origins(plan):
    def restore(value):
        if isinstance(value, list): return [restore(item) for item in value]
        if isinstance(value, dict):
            return {('bytes' if key == 'bytes_hex' else key):
                    (bytes.fromhex(item).decode('latin1') if key == 'bytes_hex' else restore(item))
                    for key, item in value.items()}
        return value
    for vector in plan['vectors'][:2]:
        origin = vector['historical_origin']; old = E.document(origin['path'])
        row = next(row for row in old['cases'] if row['name'] == origin['case_name'])
        assert row['returned'] == 1 and not row['error']
        assert row['request'] == vector['request'] and row['context']['store']['path'] == vector['case']
        assert restore(vector['acquired']) == row['result']


def primary_domains(plan, declared):
    original = E.document(BOUNDARY + '/plan.json'); baseline = E.document(BOUNDARY + '/result/qualification.json')
    children, reports, oracles, arguments, counts, assertions = {}, {}, {}, {}, {}, {}
    domains = {row['name']: row for row in declared['domains']}
    assert set(plan['domain_order']) == set(PRIMARY) and len(plan['domain_order']) == len(PRIMARY)
    for name in plan['domain_order']:
        base = domains[name]['source']; oracle = E.load_oracle(base, 'final_' + name.replace('-', '_'))
        child = E.document(base + '/plan.json'); report = E.document(base + '/result/qualification.json')
        if domains[name]['kind'] == 'calls':
            value = oracle.domain(child, baseline)
            args = value if child['route'] == 'existing' else (value,)
        elif name == 'partial-writes':
            oracle.domain(child, baseline); args = (original, baseline)
        elif domains[name]['kind'] in ('closes', 'hostile'):
            oracle.domain(child, original, baseline); args = (original, baseline)
        else:
            if name in ('guards', 'observer', 'reader-failures'): oracle.domain(child)
            args = ()
        result = oracle.verify(child, report, *args)
        saved = E.document(base + '/result/audit.json'); assert saved['success'] is True
        if name == 'records':
            record_origins(child)
            result = dict(positive_vectors=len(report['vectors']), rejected_controls=len(report['controls']),
                          helper_mutants=len(report['mutants']), historical_inputs=2,
                          unique_files_by_vector={row['name']: len(oracle.specification(row)['files']) for row in child['vectors']})
        assert all(saved[key] == value for key, value in result.items())
        if name == 'boundaries':
            for kind in ['source', 'writer', 'directory']:
                result[kind + '_handles'] = sum(handle['kind'] == kind for row in report['cases'] for handle in row['operation']['handles'])
        count = tap(E.read(base + '/result/qualify.tap')[0].decode()); assert count == saved['tap_assertions']
        assert E.read(base + '/result/qualify.exit')[0] == b'0\n'
        if 'allocated' in report:
            journal = [json.loads(line) for line in E.read(base + '/result/admission.jsonl')[0].splitlines()]
            assert journal == report['allocated'] and saved['all_allocations_absent'] is True
        children[name], reports[name], oracles[name], arguments[name] = child, report, oracle, args
        counts[name], assertions[name] = result, count
    reachability = oracles['guards'].source_relationship()
    assert reachability == E.document(domains['guards']['source'] + '/result/audit.json')['reachability']
    oracles['namespace'].source_proof(*[E.read(path)[0].decode() for path in [
        'docs/audits/native-proxy-observation-archive-20260911/ObservationArchive.pm',
        'docs/audits/native-proxy-image-coordination-20260910/Coordination.pm',
        't/lib/FSM/Test/RustProxyFixture.pm', 'perl/FSM/Support/ProcessSupervisor.pm']])
    oracles['replacements'].source_proof(*[E.read(path)[0].decode() for path in [
        'docs/audits/native-proxy-observation-archive-20260911/ObservationArchive.pm',
        'docs/audits/native-proxy-image-custody-20260910/ImageCustody.pm']])
    reader = E.read('t/lib/FSM/Test/RustProxyFixture.pm')[0].decode()
    observer = E.read(domains['observer']['source'] + '/LowerReaderTrace.pm')[0].decode()
    oracles['observer'].source_proof(reader, observer)
    oracles['reader-failures'].source_proof(reader, observer, E.read(domains['reader-failures']['source'] + '/LowerReadControls.pm')[0].decode())
    return dict(children=children, reports=reports, oracles=oracles, arguments=arguments, counts=counts,
                assertions=assertions, original=original, baseline=baseline, reachability=reachability)


def handoff(declared):
    domain = next(row for row in declared['domains'] if row['name'] == 'strict-handoff')
    base = domain['source']; oracle = E.load_oracle(base, 'final_strict_handoff')
    child = E.document(base + '/plan.json')
    assert E.digest(E.read(base + '/plan.json')[0])['sha256'] == oracle.PLAN_SHA
    oracle.LOG = E.ROOT / base / 'result'
    reports = {}; counts = {}; roots = []
    for phase in ['baseline', 'qualification']:
        report = E.document(base + '/result/' + phase + '.json'); oracle.validate(report, child, phase)
        assertions = tap(E.read(base + '/result/' + phase + '.tap')[0].decode())
        assert assertions == 2 * (len(report['cases']) + len(report['mutants'])) + 1
        reports[phase] = report; roots.extend(report['allocated'])
        counts[phase] = dict(cases=len(report['cases']), mutants=len(report['mutants']), assertions=assertions)
    strict = [row for row in reports['qualification']['cases'] if row['operation'] == 'source' and not row['returned']]
    assert all(row['handles'][0]['closed_before_recovery'] == 1 and row['handles'][0]['recovery_close_ok'] is None for row in strict)
    return dict(counts=counts, strict_failed_source_closures=len(strict), roots=roots)


def prior_joins(declared, inventory, data, strict):
    domains = {row['name']: row for row in declared['domains']}
    close = E.load_oracle(domains['close-join']['source'], 'final_close_join')
    children = dict(reports=data['children']['close-reports'], omissions=data['children']['omitted-closes'])
    reports = dict(reports=data['reports']['close-reports'], omissions=data['reports']['omitted-closes'])
    coverage = close.coverage(children, data['original']); counts, roots = close.derive_counts(reports)
    counts['tap_assertions'] = data['assertions']['close-reports'] + data['assertions']['omitted-closes']
    old_close = E.document(domains['close-join']['source'] + '/result/audit.json')
    assert old_close['success'] is True and old_close['counts'] == counts and old_close['coverage'] == coverage
    lower = E.load_oracle(domains['reader-join']['source'], 'final_lower_reader_join')
    texts = [E.read(path)[0].decode() for path in [lower.READER, lower.CUSTODY, lower.PUBLICATION, lower.ARCHIVE,
             BOUNDARY + '/ArchiveTrace.pm', domains['files']['source'] + '/qualify.t']]
    lower.source_contract(texts)
    selections = {}; counts = Counter(); selected_roots = []
    for name in ['ordinary-fresh', 'ordinary-existing', 'equal-fresh', 'equal-existing']:
        selected, tally, allocations = lower.select_archive(data['children'][name], data['reports'][name], data['arguments'][name][0])
        selections[name] = selected; counts.update(tally); selected_roots.extend(allocations)
    old_lower = E.document(domains['reader-join']['source'] + '/result/audit.json')
    assert old_lower['success'] is old_lower['source_observation_gap_closed'] is True
    assert old_lower['selections'] == selections and old_lower['selected_archive_counts'] == dict(counts)
    assert old_lower['selected_archive_roots'] == len(selected_roots)
    assert old_lower['strict_failed_source_closures'] == strict['strict_failed_source_closures']
    assert old_lower['handoff_counts'] == strict['counts']
    assert old_lower['exact_handoff_function_bodies'] == inventory['handoff_functions']
    rejections = []
    for selection, row in zip(data['children']['files']['cases'], data['reports']['files']['cases'], strict=True):
        if selection['change'] in ('changed_mode', 'hardlink'):
            assert row['operation']['returned'] == 0 and row['operation']['descriptors'] == []
            rejections.append(dict(name=row['name'], observed_failed_source_descriptors=0))
    assert rejections == old_lower['original_strict_rejections']
    lower.absent(selected_roots)
    return dict(close_counts=old_close['counts'], close_coverage=coverage, source_entry_counts=dict(counts),
                source_entry_selections=selections, strict_rejection_observation=rejections)


def absent(roots):
    paths = [row['path'] for row in roots]
    assert len(paths) == len(set(paths)), 'overlapping original case allocations'
    for name in paths:
        assert name.startswith('.artifacts/') and all(part not in ('', '.', '..') for part in name.split('/'))
        path = E.ROOT / name; assert not path.exists() and not path.is_symlink()
        while path != E.ROOT:
            assert not path.is_symlink()
            if path.exists(): assert path.stat().st_dev == E.ROOT.stat().st_dev
            path = path.parent


def main():
    pins = E.own_pins(); plan = E.document(str((E.BASE / 'plan.json').relative_to(E.ROOT)))
    declared, inventory, sources = E.authenticate(plan)
    with E.saved_only():
        data = primary_domains(plan, declared)
        strict = handoff(declared)
        joins = prior_joins(declared, inventory, data, strict)
        replay_base = replay.BASE
        replay_oracle = E.load_oracle(replay_base, 'final_original_replay')
        replay_plan = E.document(replay_base + '/plan.json'); replay_oracle.authenticate(replay_plan)
        replay_counts = replay.verify(replay_plan, E.document(replay_base + '/result/qualification.json'), inventory,
                                      E.document(str((E.BASE / 'replay-preservation-scope.json').relative_to(E.ROOT))))
    roots = [dict(domain=name, **root) for name in plan['domain_order'] for root in data['reports'][name].get('allocated', [])]
    strict_roots = [dict(domain='strict-handoff', **root) for root in strict['roots']]
    absent(roots + strict_roots)
    summary = archive_summary(data['counts'])
    source_unchanged = E.authenticate(plan)[2]; assert source_unchanged == sources
    E.own_pins()
    output = dict(schema='fsmgen.inactive_archive_final_join.v1', success=True, source_revision=E.REVISION,
                  source_files=len(sources), source_bytes=sum(row['size_bytes'] for row in sources),
                  source_inputs=sources, original_inventory_files=len(inventory['inputs']),
                  source_epoch_comparisons=len(inventory['source_epochs']), current_prospective_pins=len(pins),
                  domains=data['counts'], primary_tap_assertions=data['assertions'], archive_summary=summary,
                  reachability=data['reachability'], strict_handoff=dict(counts=strict['counts'], failed_source_closures=strict['strict_failed_source_closures']),
                  prior_joins=joins, replay=replay_counts, primary_allocations=roots, strict_support_allocations=strict_roots,
                  all_original_case_roots_absent=True, semantic_archive_join_complete=True, limits=plan['limits'])
    with (E.LOG / 'join.json').open('x') as stream:
        stream.write(json.dumps(output, indent=2, sort_keys=True) + '\n')
    print(json.dumps(dict(source_files=len(sources), source_bytes=output['source_bytes'], archive_summary=summary,
                         primary_tap_assertions=sum(data['assertions'].values()), primary_roots=len(roots),
                         strict_support_roots=len(strict_roots), replay=replay_counts), sort_keys=True))


if __name__ == '__main__':
    main()

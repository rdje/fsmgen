"""Independently verify real omitted handles, closure rejection and exact recovery."""
from __future__ import annotations

import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import re
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs/native-proxy-observation-archive-omitted-closes-20260911'
BOUNDARY = BASE.parent / 'native-proxy-observation-archive-boundaries-20260911'
specification = importlib.util.spec_from_file_location('archive_close_unwind_oracle',
    BASE.parent / 'native-proxy-observation-archive-close-reports-20260911/audit.py')
CLOSE = importlib.util.module_from_spec(specification)
specification.loader.exec_module(CLOSE)
PARTIAL, FRESH, TRACE, PHYSICAL = CLOSE.PARTIAL, CLOSE.FRESH, CLOSE.TRACE, CLOSE.PHYSICAL


def domain(plan, original, baseline):
    TRACE.verify(original, baseline)
    profiles = [dict(name='ordinary', wrapper='ordinary', files=4),
                dict(name='equal_reference', wrapper='equal_reference', files=3)]
    assert plan['profiles'] == profiles
    cases = []
    for profile in profiles:
        for route in ['fresh', 'existing']:
            name = profile['name'] + ':' + route
            labels = [row['event'][6:-6] for row in original['flows'][name]['events']
                      if re.fullmatch(r'close:.+:after', row['event'])]
            ordinal = 1 if route == 'fresh' else 0
            retained = [f'source:{index}:{ordinal}' for index in range(profile['files'])]
            def add(kind, suffix, omissions, primary=None):
                cases.append(dict(name=name + ':' + kind + (':' + suffix if suffix else ''),
                    profile=profile['name'], route=route, kind=kind, omissions=list(reversed(omissions)), primary=primary))
            add('healthy', '', [])
            for label in labels:
                add('single', label, [label])
            add('all-group', '', labels)
            add('primary-retained', '', retained, 'receipt:before')
            if route == 'fresh':
                for index in range(profile['files']):
                    add('primary-payload', str(index), ['directory_handle:0', f'source:{index}:0', f'writer:{index}'] + retained[:index],
                        f'recheck:source:{index}:0:0:before')
            for index in range(profile['files']):
                label = f'source:{index}:{ordinal + 1}'
                add('primary-reread', str(index), ['directory_handle:0', label] + retained, f'recheck:{label}:0:before')
            add('primary-directory', '', ['directory_handle:0'], 'names:0:after')
    assert plan['cases'] == cases and len({case['name'] for case in cases}) == len(cases)


def handles(selection, operation, prefix, events, paths):
    rows = operation['handles']
    assert [row['label'] for row in rows] == [event[7:] for event in prefix if event.startswith('opened:')]
    selected = set(selection['omissions'])
    assert len(selected) == len(selection['omissions'])
    labels = [event[6:-6] for event in events if re.fullmatch(r'close:.+:after', event)]
    assert set(labels) == {row['label'] for row in rows} and len(labels) == len(rows)
    hits = [label for label in labels if label in selected]
    assert len(hits) == len(selected) and operation['omission_hits'] == hits
    assert operation['all_observed_handles_closed'] == int(not selected)
    counts = dict(source=0, writer=0, directory=0)
    by_label = {}
    for row in rows:
        label, kind = row['label'], row['kind']; omitted = label in selected
        assert row['actual_close_ok'] == row['closed_after_call'] == row['closed_at_return'] == int(not omitted)
        assert row['actual_errno'] == 0
        for key in ('descriptor', 'device', 'inode', 'actual_close_ok', 'actual_errno', 'closed_after_call', 'closed_at_return'):
            assert type(row[key]) is int
        assert row['descriptor'] >= 0
        if omitted:
            assert row['actual_close_performed'] == row['reported_errno'] == 0 and row['reported_return'] == 1
        else:
            assert not {'actual_close_performed', 'reported_return', 'reported_errno'} & row.keys()
        if label.startswith('directory_handle:'):
            assert kind == 'directory' and row['observer_closed'] == 1
            assert row['observer_descriptor'] != row['descriptor'] and row['cloexec_before_close'] is None
            path = paths[0].rsplit('/', 1)[0]
        else:
            index = int(label.split(':')[1]); path = paths[index]
            assert row['file_index'] == index and kind == label.split(':')[0]
            assert row['cloexec_before_close'] == 1
        assert row['path'] == path
        native = operation['after']['evidence']['retained-sources' + path.split('/retained-sources', 1)[1]]
        assert (row['device'], row['inode']) == (native['device'], native['inode'])
        counts[kind] += 1; by_label[label] = row
    # The unchanged closure gate consumes the ORIGINAL pre-recovery verdict.
    # No healed copy or synthetic closure flag is supplied to this countercheck.
    rejected = TRACE.reject(lambda: FRESH.handles(operation, prefix, paths))
    assert rejected == bool(selected)
    witnesses, recovery = operation['open_witnesses'], operation['observer_recovery']
    assert [row['label'] for row in witnesses] == [row['label'] for row in recovery] == hits
    descriptors = {by_label[label]['descriptor'] for label in hits}
    assert len(descriptors) == len(hits)
    for witness, recovered in zip(witnesses, recovery, strict=True):
        assert set(witness) == {'label', 'kind', 'path', 'descriptor', 'device', 'inode',
                                'open_at_return', 'cloexec', 'observer_descriptor', 'observer_closed'}
        handle = by_label[witness['label']]
        for key in ('kind', 'path', 'descriptor', 'device', 'inode'):
            assert witness[key] == handle[key]
        assert type(witness['open_at_return']) is int and witness['open_at_return'] == 1
        if handle['kind'] == 'directory':
            assert witness['cloexec'] is None and witness['observer_closed'] == 1
            assert type(witness['observer_descriptor']) is int and witness['observer_descriptor'] >= 0
            assert witness['observer_descriptor'] not in descriptors
        else:
            assert witness['cloexec'] == 1
            assert witness['observer_descriptor'] is witness['observer_closed'] is None
        assert set(recovered) == {'label', 'descriptor_before', 'performed', 'actual_return', 'actual_errno', 'closed_after'}
        assert recovered['descriptor_before'] == handle['descriptor']
        for key in ('descriptor_before', 'performed', 'actual_return', 'actual_errno', 'closed_after'):
            assert type(recovered[key]) is int
        assert recovered['performed'] == recovered['actual_return'] == recovered['closed_after'] == 1
        assert recovered['actual_errno'] == 0
    assert operation['observer_errors'] == [] and operation['recovery_complete'] == 1
    return counts, len(hits), rejected


def verify(plan, report, original, baseline):
    assert report['schema'] == 'fsmgen.inactive_archive_omitted_closes_qualification.v1'
    assert report['success'] is True and report['forbidden_process_attempts'] == 0
    assert [row['name'] for row in report['cases']] == [case['name'] for case in plan['cases']]
    counts = dict(cases=0, operations=0, preparations=0, healthy_controls=0, closure_rejections=0,
                  omitted_and_recovered=0, primary_failures=0, counterimplementation_returns=0,
                  events=0, source_handles=0, writer_handles=0, directory_handles=0)
    roots = []
    flows = {row['name']: row['operation']['events'] for row in baseline['cases']}
    for selection, row in zip(plan['cases'], report['cases'], strict=True):
        assert row['selection'] == selection and row['inputs_unchanged'] == 1
        context, prior, retired = row['context'], row['prior_retirement'], row['retired']
        for kind in ('store', 'workspace', 'other_workspace', 'evidence'):
            identity = context[kind]; roots.append(dict(kind=kind, **identity))
            node = prior[kind]['']
            assert node['kind'] == 'directory' and node['mode'] == 0o700
            assert (node['device'], node['inode']) == (identity['device'], identity['inode'])
        PHYSICAL.target_inputs(context, prior)
        assert retired['workspace'] == {}
        global_path = context['runtime']['reference']['global']['identity']['path']
        store = copy.deepcopy(prior['store']); del store[global_path[len(context['store']['path']) + 1:]]
        assert retired['store'] == store
        for kind in ('evidence', 'other_workspace'):
            assert retired[kind] == prior[kind]
        retirement = row['retirement']
        assert retirement['schema'] == 'fsmgen.inactive_runtime_retirement.v1'
        assert retirement['runtime_authorized'] == 0 and retirement['executable'] is None
        assert retirement['retired_workspace'] == context['workspace']['path'] and retirement['released_reference'] == global_path
        spec = PARTIAL.retained_spec(context, selection['profile']); paths = [file['path'] for file in spec['files']]
        operation = row['operation']
        if selection['route'] == 'existing':
            preparation = row['preparation']
            assert preparation['before'] == retired
            assert operation['before'] == preparation['after'] == operation['after']
            PHYSICAL.operation_checks(context, preparation, True, '')
            preparation_flow = selection['profile'] + ':fresh'
            assert preparation['events'] == flows[preparation_flow]
            TRACE.lifetimes(original['flows'][preparation_flow], preparation)
            CLOSE.projection(preparation)
            kinds = FRESH.handles(preparation, flows[preparation_flow], paths)
            for kind, number in kinds.items(): counts[kind + '_handles'] += number
            counts['preparations'] += 1; counts['operations'] += 1; counts['events'] += len(preparation['events'])
        else:
            assert 'preparation' not in row and operation['before'] == retired
        flow = flows[selection['profile'] + ':' + selection['route']]
        cut = dict(kind='primary' if selection['primary'] else 'healthy', primary=selection['primary'], route=selection['route'], reports=[])
        prefix, events = CLOSE.unwind(cut, flow)
        assert operation['events'] == events and len(events) == len(set(events))
        assert operation['primary_hits'] == int(selection['primary'] is not None)
        if selection['primary']:
            assert operation['returned'] == 0 and operation.get('result') is None
            assert operation['error'] == 'primary archive omission-control: ' + selection['name'] + '\n'
            counts['primary_failures'] += 1
        else:
            assert operation['returned'] == 1 and operation['error'] == ''
            PHYSICAL.physical_receipt(context, operation)
            counts['counterimplementation_returns'] += bool(selection['omissions'])
        CLOSE.projection(operation)
        if selection['route'] == 'fresh':
            complete = {index: bytes.fromhex(file['bytes_hex']) for index, file in enumerate(spec['files'])
                        if 'opened:writer:' + str(index) in prefix}
            PARTIAL.physical(context, operation, spec, complete)
        kinds, omitted, rejected = handles(selection, operation, prefix, events, paths)
        counts['omitted_and_recovered'] += omitted; counts['closure_rejections'] += rejected
        counts['healthy_controls'] += not bool(selection['omissions'])
        assert operation['reads'] == [paths[int(event.split(':')[2])] for event in prefix if event.startswith('opened:source:')]
        assert operation['writes'] == [paths[int(event.split(':')[1])] for event in prefix if re.fullmatch(r'write:[0-9]+:before', event)]
        assert operation['directories'] == [context['evidence']['path'] + ('/retained-sources' if event.split(':')[1] == 'archive' else '')
            for event in prefix if re.fullmatch(r'directory:(?:evidence|archive):[0-9]+:before', event)]
        for kind, number in kinds.items(): counts[kind + '_handles'] += number
        counts['cases'] += 1; counts['operations'] += 1; counts['events'] += len(events)
    assert roots == report['allocated'] and len({row['path'] for row in roots}) == len(roots)
    return dict(counts, roots=len(roots))


def main():
    plan = json.loads((BASE / 'plan.json').read_bytes())
    assert plan['source_revision'] == '2ad652d308348e8ce82bb8e4e11a968c731a8ebe'
    original = json.loads((BOUNDARY / 'plan.json').read_bytes())
    dependencies = {pin['path'] for pin in original['inputs']}
    dependencies.update(str((BOUNDARY / name).relative_to(ROOT)) for name in
        ('plan.json', 'ArchiveTrace.pm', 'ArchiveFixture.pm', 'extraction.json',
         'audit.py', 'result/qualification.json', 'result/recovery-copies.json'))
    dependencies.update('docs/audits/' + component + '/audit.py' for component in
        ('native-proxy-observation-archive-fresh-calls-20260911', 'native-proxy-observation-archive-partial-writes-20260911',
         'native-proxy-observation-archive-close-reports-20260911'))
    assert [pin['path'] for pin in plan['inputs']] == sorted(dependencies)
    for pin in plan['inputs']:
        raw = (ROOT / pin['path']).read_bytes()
        assert len(raw) == pin['size_bytes'] and hashlib.sha256(raw).hexdigest() == pin['sha256']
        assert raw == subprocess.check_output(['git', 'show', plan['source_revision'] + ':' + pin['path']], cwd=ROOT)
    pins = json.loads((BASE / 'preflight-pins.json').read_bytes())
    for pin in pins:
        raw = (ROOT / pin['path']).read_bytes()
        assert len(raw) == pin['size_bytes'] and hashlib.sha256(raw).hexdigest() == pin['sha256']
    baseline = json.loads((BOUNDARY / 'result/qualification.json').read_bytes())
    domain(plan, original, baseline)
    report = json.loads((LOG / 'qualification.json').read_bytes())
    counts = verify(plan, report, original, baseline)
    admission = [json.loads(line) for line in (LOG / 'admission.jsonl').read_text().splitlines()]
    assert admission == report['allocated']
    assert all(not (ROOT / row['path']).exists() and not (ROOT / row['path']).is_symlink() for row in admission)
    assertions = len(plan['cases']) * 6 + sum(case['route'] == 'existing' for case in plan['cases']) * 2 + 1
    tap = (LOG / 'qualify.tap').read_text()
    assert re.findall(r'^1\.\.([0-9]+)$', tap, re.M) == [str(assertions)]
    assert [int(value) for value in re.findall(r'^ok ([0-9]+) - ', tap, re.M)] == list(range(1, assertions + 1))
    assert not re.search(r'^(?:not ok|Bail out!)', tap, re.M) and (LOG / 'qualify.exit').read_text().strip() == '0'
    def rich(value): return next(row['operation'] for row in value['cases'] if row['selection']['kind'] == 'all-group')
    def omitted(value, kind='source'): return next(row for row in rich(value)['handles'] if row['kind'] == kind)
    def witness(value): return rich(value)['open_witnesses'][0]
    def recovery(value): return rich(value)['observer_recovery'][0]
    def primary(value): return next(row['operation'] for row in value['cases'] if row['selection']['primary'])
    def preparation(value): return next(row['preparation'] for row in value['cases'] if row['selection']['route'] == 'existing')
    def file(value): return next(node for node in rich(value)['after']['evidence'].values() if node['kind'] == 'file')
    def other_hold(value):
        row = value['cases'][0]; path = row['context']['other_observation']['observation_reference']['source']['identity']['path']
        del row['operation']['after']['store'][path[len(row['context']['store']['path']) + 1:]]
    changes = [
        ('missing case', lambda value: value['cases'].pop()),
        ('duplicate case', lambda value: value['cases'].append(copy.deepcopy(value['cases'][0]))),
        ('changed selection', lambda value: value['cases'][1]['selection']['omissions'].append('writer:99')),
        ('hidden closure rejection', lambda value: rich(value).update(all_observed_handles_closed=1)),
        ('unclosed unselected handle', lambda value: value['cases'][0]['operation']['handles'][0].update(closed_at_return=0)),
        ('wrong actual errno', lambda value: omitted(value).update(actual_errno=5)),
        ('lost source inheritance seal', lambda value: omitted(value).update(cloexec_before_close=0)),
        ('missing omission', lambda value: rich(value)['omission_hits'].pop()),
        ('reordered omissions', lambda value: rich(value)['omission_hits'].reverse()),
        ('performed omitted close', lambda value: omitted(value).update(actual_close_performed=1)),
        ('forged actual close success', lambda value: omitted(value).update(actual_close_ok=1)),
        ('forged closed after call', lambda value: omitted(value).update(closed_after_call=1)),
        ('forged source closed at return', lambda value: omitted(value).update(closed_at_return=1)),
        ('forged writer closed at return', lambda value: omitted(value, 'writer').update(closed_at_return=1)),
        ('forged directory closed at return', lambda value: omitted(value, 'directory').update(closed_at_return=1)),
        ('changed modeled return', lambda value: omitted(value).update(reported_return=0)),
        ('changed modeled errno', lambda value: omitted(value).update(reported_errno=5)),
        ('unclosed original directory observer', lambda value: omitted(value, 'directory').update(observer_closed=0)),
        ('missing open witness', lambda value: rich(value)['open_witnesses'].pop()),
        ('changed witness order', lambda value: rich(value)['open_witnesses'].reverse()),
        ('closed open witness', lambda value: witness(value).update(open_at_return=0)),
        ('foreign witness descriptor', lambda value: witness(value).update(descriptor=987654)),
        ('foreign witness inode', lambda value: witness(value).update(inode=7)),
        ('unclosed witness duplicate', lambda value: witness(value).update(observer_closed=0)),
        ('aliased witness duplicate', lambda value: witness(value).update(observer_descriptor=witness(value)['descriptor'])),
        ('missing recovery', lambda value: rich(value)['observer_recovery'].pop()),
        ('changed recovery order', lambda value: rich(value)['observer_recovery'].reverse()),
        ('foreign recovery descriptor', lambda value: recovery(value).update(descriptor_before=987654)),
        ('omitted recovery call', lambda value: recovery(value).update(performed=0)),
        ('failed recovery call', lambda value: recovery(value).update(actual_return=0)),
        ('changed recovery errno', lambda value: recovery(value).update(actual_errno=5)),
        ('still open after recovery', lambda value: recovery(value).update(closed_after=0)),
        ('lost recovery completion', lambda value: rich(value).update(recovery_complete=0)),
        ('hidden observer error', lambda value: rich(value)['observer_errors'].append('failed')),
        ('changed primary error', lambda value: primary(value).update(error='cleanup error\n')),
        ('unhit primary error', lambda value: primary(value).update(primary_hits=0)),
        ('hidden primary failure', lambda value: primary(value).update(returned=1)),
        ('failed preparation', lambda value: preparation(value).update(returned=0)),
        ('lost preparation boundary', lambda value: preparation(value)['events'].pop()),
        ('unclosed preparation handle', lambda value: preparation(value)['handles'][0].update(closed_at_return=0)),
        ('missing cleanup event', lambda value: rich(value)['events'].pop()),
        ('changed archive bytes', lambda value: file(value).update(bytes_hex='00')),
        ('changed archive permissions', lambda value: file(value).update(mode=0o600)),
        ('reopened original target', lambda value: rich(value)['reads'].append('original-target')),
        ('removed other observation hold', other_hold),
        ('changed retained input', lambda value: value['cases'][0].update(inputs_unchanged=0)),
        ('lost allocation', lambda value: value['allocated'].pop()),
        ('process attempt', lambda value: value.update(forbidden_process_attempts=1)),
    ]
    for name, change in changes:
        altered = copy.deepcopy(report); change(altered)
        assert TRACE.reject(lambda: verify(plan, altered, original, baseline)), name
    domains = []
    for name in ['duplicate case', 'omitted close', 'wrong primary', 'aliased omission', 'changed selection order']:
        altered = copy.deepcopy(plan)
        if name == 'duplicate case': altered['cases'].append(copy.deepcopy(altered['cases'][0]))
        elif name == 'omitted close': altered['cases'].pop(1)
        elif name == 'wrong primary': altered['cases'][1]['primary'] = 'operation:begin'
        elif name == 'aliased omission': altered['cases'][1]['omissions'].append(altered['cases'][1]['omissions'][0])
        else: next(case for case in altered['cases'] if case['kind'] == 'all-group')['omissions'].reverse()
        assert TRACE.reject(lambda: domain(altered, original, baseline)), name
        domains.append(name)
    output = dict(schema='fsmgen.inactive_archive_omitted_closes_audit.v1', success=True, **counts,
        tap_assertions=assertions, report_falsifiers=[name for name, _ in changes], domain_falsifiers=domains,
        predecessor_inputs_unchanged=len(plan['inputs']), prospective_inputs_unchanged=len(pins),
        all_allocations_absent=True, limits=plan['limits'])
    (LOG / 'audit.json').write_text(json.dumps(output, indent=2, sort_keys=True) + '\n')
    print(json.dumps(output, sort_keys=True))


if __name__ == '__main__':
    main()

"""Derive close-report unwind, actual cleanup and first/primary error precedence."""
from __future__ import annotations

import copy
import errno
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs/native-proxy-observation-archive-close-reports-20260911'
BOUNDARY = BASE.parent / 'native-proxy-observation-archive-boundaries-20260911'
specification = importlib.util.spec_from_file_location('archive_close_physical_oracle',
    BASE.parent / 'native-proxy-observation-archive-partial-writes-20260911/audit.py')
PARTIAL = importlib.util.module_from_spec(specification)
specification.loader.exec_module(PARTIAL)
FRESH, TRACE, PHYSICAL = PARTIAL.FRESH, PARTIAL.TRACE, PARTIAL.PHYSICAL
ERRORS = dict(EIO=errno.EIO, ENOSPC=errno.ENOSPC)


def domain(plan, original, baseline):
    TRACE.verify(original, baseline)
    profiles = [dict(name='ordinary', wrapper='ordinary', files=4),
                dict(name='equal_reference', wrapper='equal_reference', files=3)]
    assert plan['profiles'] == profiles
    cases = []
    for profile in profiles:
        for route in ['fresh', 'existing']:
            flow = profile['name'] + ':' + route
            labels = [row['event'][6:-6] for row in original['flows'][flow]['events']
                      if re.fullmatch(r'close:.+:after', row['event'])]
            retained = [dict(label='source:' + str(index) + ':' + ('1' if route == 'fresh' else '0'),
                             errno='ENOSPC' if index % 2 == 0 else 'EIO') for index in range(profile['files'])]
            def add(kind, suffix, reports, primary=None):
                cases.append(dict(name=flow + ':' + kind + (':' + suffix if suffix else ''),
                    profile=profile['name'], route=route, kind=kind, reports=reports[::-1], primary=primary))
            add('healthy', '', [])
            for label in labels:
                add('single', label, [dict(label=label, errno='EIO')])
            if route == 'fresh':
                for index in range(profile['files']):
                    pair = [dict(label=f'source:{index}:0', errno='EIO'), dict(label=f'writer:{index}', errno='ENOSPC')]
                    add('payload-pair', str(index), pair)
                    add('primary-payload', str(index), pair + retained[:index], f'recheck:source:{index}:0:0:before')
            add('retained-group', '', retained)
            add('primary-retained', '', retained, 'receipt:before')
            for index in range(profile['files']):
                label = f"source:{index}:{2 if route == 'fresh' else 1}"
                add('primary-reread', str(index), [dict(label=label, errno='EIO')] + retained, f'recheck:{label}:0:before')
    assert plan['cases'] == cases and len({case['name'] for case in cases}) == len(cases)


def unwind(selection, healthy):
    if selection['kind'] == 'healthy':
        return healthy, healthy
    selected = {row['label'] for row in selection['reports']}
    if selection['primary'] is not None:
        cut = selection['primary']
    else:
        cut = next(event for event in healthy if event.startswith('close:') and event.endswith(':after')
                   and event[6:-6] in selected)
    prefix = healthy[:healthy.index(cut) + 1]
    owned = []
    for event in prefix:
        if event.startswith('opened:'):
            owned.append(event[7:])
        elif event.startswith('close:') and event.endswith(':after'):
            owned.remove(event[6:-6])
    ordinal = 1 if selection['route'] == 'fresh' else 0
    retained = [label for label in owned if re.fullmatch(f'source:[0-9]+:{ordinal}', label)]
    temporary = [label for label in owned if label not in retained]
    readers = [label for label in temporary if label.startswith('source:')]
    writers = [label for label in temporary if label.startswith('writer:')]
    assert len(readers) <= 1 and len(writers) <= 1 and set(temporary) == set(readers + writers)
    suffix = []
    def close(label):
        suffix.extend(['close:' + label + ':before', 'close:' + label + ':after'])
    for label in readers + writers:
        close(label)
    # Final retained cleanup may already be underway when its report fails.
    if 'close_sources:before' not in prefix:
        suffix.append('close_sources:before')
    for label in retained:
        close(label)
    suffix.append('close_sources:after')
    return prefix, prefix + suffix


def reports(selection, operation, events):
    labels = [event[6:-6] for event in events if event.startswith('close:') and event.endswith(':after')]
    rows = operation['close_reports']
    assert [row['label'] for row in rows] == labels and len(labels) == len(set(labels))
    owned = {handle['label']: handle for handle in operation['handles']}
    selected = {row['label']: row['errno'] for row in selection['reports']}
    assert len(selected) == len(selection['reports']) and selected.keys() <= set(labels)
    hits = []
    for row in rows:
        assert set(row) == {'label', 'kind', 'path', 'descriptor', 'device', 'inode', 'actual_return',
                           'actual_errno', 'closed_after_call', 'report_applied', 'reported_return',
                           'reported_errno', 'selected_errno'}
        handle = owned[row['label']]
        for key in ('kind', 'path', 'descriptor', 'device', 'inode'):
            assert row[key] == handle[key]
        for key in ('descriptor', 'device', 'inode', 'actual_return', 'actual_errno', 'closed_after_call',
                    'report_applied', 'reported_return', 'reported_errno'):
            assert type(row[key]) is int
        assert row['actual_return'] == row['closed_after_call'] == 1 and row['actual_errno'] == 0
        assert handle['actual_close_ok'] == handle['closed_after_call'] == handle['closed_at_return'] == 1
        assert handle['actual_errno'] == 0
        name = selected.get(row['label'])
        assert row['selected_errno'] == name and row['report_applied'] == int(name is not None)
        assert row['reported_return'] == (0 if name is not None else 1)
        assert row['reported_errno'] == (ERRORS[name] if name is not None else 0)
        if name is not None:
            hits.append(row['label'])
    assert operation['reported_error_hits'] == hits
    assert operation['primary_hits'] == int(selection['primary'] is not None)
    if selection['primary'] is not None:
        expected = 'primary archive close-control: ' + selection['name'] + '\n'
    elif selection['kind'] == 'healthy':
        expected = ''
    else:
        first = hits[0]
        if first.startswith('directory_handle:'):
            stage = 'bounded namespace'
        elif first.startswith('writer:'):
            stage = 'canonical writer'
        else:
            ordinal = int(first.split(':')[2])
            if selection['route'] == 'fresh' and ordinal == 0:
                stage = 'canonical reader'
            elif ordinal == (1 if selection['route'] == 'fresh' else 0):
                stage = 'retained archive descriptor'
            else:
                assert ordinal == (2 if selection['route'] == 'fresh' else 1)
                stage = 'archive reread descriptor'
        expected = 'cannot close ' + stage + ': ' + os.strerror(ERRORS[selected[first]]) + '\n'
    assert operation['error'] == expected
    return len(rows), len(hits)


def projection(operation):
    assert operation['descriptors'] == [dict(path=handle['path'], descriptor=handle['descriptor'],
        closed=handle['closed_at_return'], cloexec=handle['cloexec_before_close'])
        for handle in operation['handles'] if handle['kind'] == 'source']


def verify(plan, report, original, baseline):
    assert report['schema'] == 'fsmgen.inactive_archive_close_reports_qualification.v1'
    assert report['success'] is True and report['forbidden_process_attempts'] == 0
    assert [row['name'] for row in report['cases']] == [case['name'] for case in plan['cases']]
    counts = dict(cases=0, operations=0, preparations=0, healthy_returns=0, close_reports=0,
                  modeled_errors=0, primary_failures=0, events=0, source_handles=0, writer_handles=0, directory_handles=0)
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
        spec = PARTIAL.retained_spec(context, selection['profile'])
        paths = [file['path'] for file in spec['files']]
        operation = row['operation']
        if selection['route'] == 'existing':
            preparation = row['preparation']
            assert preparation['before'] == retired
            assert operation['before'] == preparation['after'] == operation['after']
            PHYSICAL.operation_checks(context, preparation, True, '')
            preparation_flow = selection['profile'] + ':fresh'
            assert preparation['events'] == flows[preparation_flow]
            TRACE.lifetimes(original['flows'][preparation_flow], preparation)
            projection(preparation)
            kinds = FRESH.handles(preparation, flows[preparation_flow], paths)
            for kind, number in kinds.items():
                counts[kind + '_handles'] += number
            counts['preparations'] += 1; counts['operations'] += 1; counts['events'] += len(preparation['events'])
        else:
            assert 'preparation' not in row and operation['before'] == retired
        flow_name = selection['profile'] + ':' + selection['route']
        prefix, events = unwind(selection, flows[flow_name])
        assert operation['events'] == events and len(events) == len(set(events))
        if selection['kind'] == 'healthy':
            assert operation['returned'] == 1
            PHYSICAL.operation_checks(context, operation, True, '')
            TRACE.lifetimes(original['flows'][flow_name], operation)
            counts['healthy_returns'] += 1
        else:
            assert operation['returned'] == 0 and operation.get('result') is None
        projection(operation)
        number, errors = reports(selection, operation, events)
        counts['close_reports'] += number; counts['modeled_errors'] += errors
        counts['primary_failures'] += int(selection['primary'] is not None)
        if selection['route'] == 'fresh':
            complete = {index: bytes.fromhex(file['bytes_hex']) for index, file in enumerate(spec['files'])
                        if 'opened:writer:' + str(index) in prefix}
            PARTIAL.physical(context, operation, spec, complete)
        kinds = FRESH.handles(operation, prefix, paths)
        assert all(handle['cloexec_before_close'] == 1 for handle in operation['handles'] if handle['kind'] != 'directory')
        assert operation['reads'] == [paths[int(event.split(':')[2])] for event in prefix if event.startswith('opened:source:')]
        assert operation['writes'] == [paths[int(event.split(':')[1])] for event in prefix if re.fullmatch(r'write:[0-9]+:before', event)]
        assert operation['directories'] == [context['evidence']['path'] + ('/retained-sources' if event.split(':')[1] == 'archive' else '')
            for event in prefix if re.fullmatch(r'directory:(?:evidence|archive):[0-9]+:before', event)]
        for kind, number in kinds.items():
            counts[kind + '_handles'] += number
        counts['cases'] += 1; counts['operations'] += 1; counts['events'] += len(events)
    assert roots == report['allocated'] and len({row['path'] for row in roots}) == len(roots)
    return dict(counts, roots=len(roots))


def main():
    plan = json.loads((BASE / 'plan.json').read_bytes())
    assert plan['source_revision'] == '7e1f2daa01c9ef5760954089c36ec6c778c25f17'
    original = json.loads((BOUNDARY / 'plan.json').read_bytes())
    dependencies = {pin['path'] for pin in original['inputs']}
    dependencies.update(str((BOUNDARY / name).relative_to(ROOT)) for name in
        ('plan.json', 'ArchiveTrace.pm', 'ArchiveFixture.pm', 'extraction.json',
         'audit.py', 'result/qualification.json', 'result/recovery-copies.json'))
    dependencies.update('docs/audits/' + component + '/audit.py' for component in
        ('native-proxy-observation-archive-fresh-calls-20260911', 'native-proxy-observation-archive-partial-writes-20260911'))
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
    assertions = len(plan['cases']) * 5 + sum(case['route'] == 'existing' for case in plan['cases']) * 2 + 1
    tap = (LOG / 'qualify.tap').read_text()
    assert re.findall(r'^1\.\.([0-9]+)$', tap, re.M) == [str(assertions)]
    assert [int(value) for value in re.findall(r'^ok ([0-9]+) - ', tap, re.M)] == list(range(1, assertions + 1))
    assert not re.search(r'^(?:not ok|Bail out!)', tap, re.M) and (LOG / 'qualify.exit').read_text().strip() == '0'
    def rich(value):
        return next(row['operation'] for row in value['cases'] if row['selection']['kind'] == 'retained-group')
    def modeled(value):
        return next(row for row in rich(value)['close_reports'] if row['report_applied'])
    def primary(value):
        return next(row['operation'] for row in value['cases'] if row['selection']['primary'] is not None)
    def handle(value, kind):
        return next(row for row in rich(value)['handles'] if row['kind'] == kind)
    def preparation(value):
        return next(row['preparation'] for row in value['cases'] if row['selection']['route'] == 'existing')
    def file(value):
        return next(node for node in rich(value)['after']['evidence'].values() if node['kind'] == 'file')
    def other_hold(value):
        row = value['cases'][0]
        path = row['context']['other_observation']['observation_reference']['source']['identity']['path']
        del row['operation']['after']['store'][path[len(row['context']['store']['path']) + 1:]]
    changes = [
        ('missing case', lambda value: value['cases'].pop()),
        ('duplicate case', lambda value: value['cases'].append(copy.deepcopy(value['cases'][0]))),
        ('changed selection', lambda value: value['cases'][1]['selection']['reports'][0].update(errno='ENOSPC')),
        ('missing report', lambda value: rich(value)['close_reports'].pop()),
        ('reordered reports', lambda value: rich(value)['close_reports'].reverse()),
        ('hidden actual close failure', lambda value: modeled(value).update(actual_return=0)),
        ('wrong actual errno', lambda value: modeled(value).update(actual_errno=errno.EIO)),
        ('open actual descriptor', lambda value: modeled(value).update(closed_after_call=0)),
        ('unapplied modeled report', lambda value: modeled(value).update(report_applied=0)),
        ('hidden successful report', lambda value: modeled(value).update(reported_return=1)),
        ('wrong reported errno', lambda value: modeled(value).update(reported_errno=errno.EIO)),
        ('wrong selected errno', lambda value: modeled(value).update(selected_errno='EIO')),
        ('foreign reported descriptor', lambda value: modeled(value).update(descriptor=987654)),
        ('foreign reported inode', lambda value: modeled(value).update(inode=7)),
        ('lost report hit', lambda value: rich(value)['reported_error_hits'].pop()),
        ('wrong first error', lambda value: rich(value).update(error='cannot close retained archive descriptor: ' + os.strerror(errno.EIO) + '\n')),
        ('replaced primary error', lambda value: primary(value).update(error='cleanup error\n')),
        ('unhit primary error', lambda value: primary(value).update(primary_hits=0)),
        ('hidden success', lambda value: rich(value).update(returned=1)),
        ('failed preparation', lambda value: preparation(value).update(returned=0)),
        ('lost preparation boundary', lambda value: preparation(value)['events'].pop()),
        ('unclosed preparation handle', lambda value: preparation(value)['handles'][0].update(closed_at_return=0)),
        ('missing cleanup event', lambda value: rich(value)['events'].pop()),
        ('unclosed source', lambda value: handle(value, 'source').update(closed_at_return=0)),
        ('unclosed writer', lambda value: handle(value, 'writer').update(closed_after_call=0)),
        ('unclosed directory', lambda value: handle(value, 'directory').update(actual_close_ok=0)),
        ('unclosed observer duplicate', lambda value: handle(value, 'directory').update(observer_closed=0)),
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
    for name in ['duplicate case', 'omitted close', 'wrong primary', 'aliased report', 'changed report order']:
        altered = copy.deepcopy(plan)
        if name == 'duplicate case': altered['cases'].append(copy.deepcopy(altered['cases'][0]))
        elif name == 'omitted close': altered['cases'].pop(1)
        elif name == 'wrong primary': altered['cases'][1]['primary'] = 'operation:begin'
        elif name == 'aliased report': altered['cases'][1]['reports'].append(copy.deepcopy(altered['cases'][1]['reports'][0]))
        else: next(case for case in altered['cases'] if case['kind'] == 'retained-group')['reports'].reverse()
        assert TRACE.reject(lambda: domain(altered, original, baseline)), name
        domains.append(name)
    output = dict(schema='fsmgen.inactive_archive_close_reports_audit.v1', success=True, **counts,
        tap_assertions=assertions, report_falsifiers=[name for name, _ in changes], domain_falsifiers=domains,
        predecessor_inputs_unchanged=len(plan['inputs']), prospective_inputs_unchanged=len(pins),
        all_allocations_absent=True, limits=plan['limits'])
    (LOG / 'audit.json').write_text(json.dumps(output, indent=2, sort_keys=True) + '\n')
    print(json.dumps(output, sort_keys=True))


if __name__ == '__main__':
    main()

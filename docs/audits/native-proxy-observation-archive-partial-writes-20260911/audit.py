"""Independently derive archive write progress, prefix files and owned cleanup."""
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
LOG = ROOT / '.artifacts/logs/native-proxy-observation-archive-partial-writes-20260911'
BOUNDARY = BASE.parent / 'native-proxy-observation-archive-boundaries-20260911'
specification = importlib.util.spec_from_file_location('archive_partial_unwind',
    BASE.parent / 'native-proxy-observation-archive-fresh-calls-20260911/audit.py')
FRESH = importlib.util.module_from_spec(specification)
specification.loader.exec_module(FRESH)
TRACE, PHYSICAL = FRESH.TRACE, FRESH.PHYSICAL


def domain(plan, baseline):
    original = json.loads((BOUNDARY / 'plan.json').read_bytes())
    TRACE.verify(original, baseline)
    profiles = [dict(name=name, wrapper=name, files=files, targets=targets, chunk=chunk)
        for name, files, targets, chunk in [('ordinary', 4, [0, 1, 2, 3], 7),
            ('equal_reference', 3, [0, 1, 2], 7), ('binary', 4, [0], 7),
            ('empty', 4, [0], 7), ('maximum', 4, [0], 4096)]]
    assert plan['profiles'] == profiles and plan['syscall_calls_per_operation'] == 4096
    cases = []
    for profile in profiles:
        for index in profile['targets']:
            selections = [('empty', None)] if profile['name'] == 'empty' else [('short', None)] + [
                (kind, offset) for kind in ['zero', 'error'] for offset in ['start', 'one', 'middle', 'last']]
            for mode, offset in selections:
                name = profile['name'] + ':file:' + str(index) + ':' + mode + (':' + offset if offset else '')
                cases.append(dict(name=name, profile=profile['name'], file_index=index,
                                  mode=mode, offset=offset, chunk=profile['chunk']))
    assert plan['cases'] == cases and len({case['name'] for case in cases}) == len(cases)
    return original


def retained_spec(context, profile):
    value = dict(case=context['store']['path'], request=context['request'], acquired=PHYSICAL.wire(context['acquired']))
    spec = PHYSICAL.RECORD.specification(value)
    assert len(spec['sources']) == 5 and len(spec['files']) == (3 if profile == 'equal_reference' else 4)
    wrapper = bytes.fromhex(spec['sources'][0]['snapshot']['bytes_hex'])
    if profile == 'equal_reference':
        shared = spec['sources'][:3]
        assert [source['role'] for source in shared] == ['wrapper', 'private_reference', 'global_reference']
        assert len({source['snapshot']['bytes_hex'] for source in shared}) == 1
        assert len({source['destination'] for source in shared}) == 1
        identities = [source['snapshot']['identity'] for source in shared]
        assert len({identity['path'] for identity in identities}) == 3
        assert len({(identity['device'], identity['inode']) for identity in identities}) == 3
    else:
        expected = dict(ordinary=b'#!/usr/bin/perl\n# inert observation wrapper; never executed\n',
                        binary=bytes(range(256)), empty=b'', maximum=b'W' * 65536)
        assert wrapper == expected[profile]
    return spec


def write_progress(selection, operation, spec, limit):
    target = selection['file_index']
    failure = selection['mode'] in ('zero', 'error')
    files = spec['files']
    target_bytes = bytes.fromhex(files[target]['bytes_hex'])
    if failure:
        assert len(target_bytes) >= 4
        offsets = dict(start=0, one=1, middle=len(target_bytes) // 2, last=len(target_bytes) - 1)
        stop = offsets[selection['offset']]
    else:
        stop = None
    calls = operation['syswrites']
    assert len(calls) <= limit
    cursor = 0
    actual_calls = actual_bytes = 0
    preserved = {}
    for index, file in enumerate(files[:target + 1] if failure else files):
        raw = bytes.fromhex(file['bytes_hex'])
        writer = next(handle for handle in operation['handles'] if handle['label'] == f'writer:{index}')
        progress = ordinal = 0
        while progress < len(raw):
            assert cursor < len(calls)
            row = calls[cursor]
            assert set(row) == {'file_index', 'call_index', 'path', 'descriptor', 'device', 'inode',
                'cloexec', 'before_size', 'buffer_bytes', 'buffer_sha256', 'requested', 'offset',
                'syscall_performed', 'actual_requested', 'actual_return', 'actual_errno', 'accepted_hex',
                'after_device', 'after_inode', 'after_size', 'reported_return', 'reported_errno'}
            for field in ('file_index', 'call_index', 'descriptor', 'device', 'inode', 'cloexec',
                          'before_size', 'buffer_bytes', 'requested', 'offset', 'syscall_performed',
                          'actual_requested', 'actual_errno', 'after_device', 'after_inode',
                          'after_size', 'reported_errno'):
                assert type(row[field]) is int
            assert row['file_index'] == index and row['call_index'] == ordinal and row['path'] == file['path']
            assert (row['descriptor'], row['device'], row['inode']) == (writer['descriptor'], writer['device'], writer['inode'])
            assert (row['after_device'], row['after_inode']) == (writer['device'], writer['inode'])
            assert row['cloexec'] == 1 and row['before_size'] == row['offset'] == progress
            assert row['buffer_bytes'] == len(raw) and row['buffer_sha256'] == hashlib.sha256(raw).hexdigest()
            assert row['requested'] == len(raw) - progress
            cursor += 1; ordinal += 1
            if index == target and failure and progress == stop:
                assert row['syscall_performed'] == 0 and row['actual_requested'] == 0
                assert row['actual_return'] is None and row['actual_errno'] == 0
                assert row['accepted_hex'] == '' and row['after_size'] == progress
                if selection['mode'] == 'zero':
                    assert type(row['reported_return']) is int and row['reported_return'] == 0
                else:
                    assert row['reported_return'] is None
                assert row['reported_errno'] == errno.EIO
                assert cursor == len(calls)
                break
            requested = len(raw) - progress
            if index == target:
                requested = min(requested, selection['chunk'])
                if failure:
                    requested = min(requested, stop - progress)
            assert requested > 0 and row['syscall_performed'] == 1 and row['actual_requested'] == requested
            written = row['actual_return']
            assert type(written) is int and 0 < written <= requested
            assert type(row['reported_return']) is int and row['reported_return'] == written
            assert row['actual_errno'] == row['reported_errno'] == 0
            assert row['accepted_hex'] == raw[progress:progress + written].hex()
            progress += written
            assert row['after_size'] == progress
            actual_calls += 1; actual_bytes += written
        assert progress == (stop if index == target and failure else len(raw))
        if index == target and selection['mode'] == 'short':
            assert ordinal >= 2 and len(raw) > selection['chunk']
        if index == target and selection['mode'] == 'empty':
            assert raw == b'' and ordinal == 0
        preserved[index] = raw[:progress]
    assert cursor == len(calls) and operation['write_fault_hits'] == int(failure)
    return preserved, dict(syswrite_records=len(calls), actual_syscalls=actual_calls, actual_written_bytes=actual_bytes)


def physical(context, operation, spec, expected_bytes):
    before, after = operation['before'], operation['after']
    for kind in ('store', 'workspace', 'other_workspace'):
        assert before[kind] == after[kind]
    assert set(before['evidence']) == {''} and before['evidence'][''] == after['evidence']['']
    directory = after['evidence']['retained-sources']
    assert directory['kind'] == 'directory' and directory['mode'] == 0o700
    assert directory['device'] == context['evidence']['device'] and directory['uid'] == before['evidence']['']['uid']
    names = {'', 'retained-sources'}
    for index, raw in expected_bytes.items():
        file = spec['files'][index]
        name = 'retained-sources/' + file['sha256'] + '.source'
        names.add(name)
        node = after['evidence'][name]
        identity = PHYSICAL.file_identity(file['path'], node)
        assert node['bytes_hex'] == raw.hex() and node['size_bytes'] == identity['size_bytes'] == len(raw)
        assert node['sha256'] == hashlib.sha256(raw).hexdigest()
        assert node['links'] == 1 and node['mode'] == 0o400
        assert node['device'] == directory['device'] and node['uid'] == directory['uid']
    assert set(after['evidence']) == names
    assert len({(node['device'], node['inode']) for node in after['evidence'].values()}) == len(names)


def verify(plan, report, original, baseline):
    assert report['schema'] == 'fsmgen.inactive_archive_partial_writes_qualification.v1'
    assert report['success'] is True and report['forbidden_process_attempts'] == 0
    assert [row['name'] for row in report['cases']] == [case['name'] for case in plan['cases']]
    roots = []
    counts = dict(cases=0, successful_returns=0, zero_returns=0, error_returns=0, syswrite_records=0,
                  actual_syscalls=0, actual_written_bytes=0, events=0, source_handles=0, writer_handles=0, directory_handles=0)
    for selection, row in zip(plan['cases'], report['cases'], strict=True):
        assert row['selection'] == selection and row['inputs_unchanged'] == 1
        context, prior, operation = row['context'], row['prior_retirement'], row['operation']
        for kind in ('store', 'workspace', 'other_workspace', 'evidence'):
            identity = context[kind]; roots.append(dict(kind=kind, **identity))
            node = prior[kind]['']
            assert node['kind'] == 'directory' and node['mode'] == 0o700
            assert (node['device'], node['inode']) == (identity['device'], identity['inode'])
        PHYSICAL.target_inputs(context, prior)
        before = operation['before']; retirement = row['retirement']
        assert before['workspace'] == {}
        global_path = context['runtime']['reference']['global']['identity']['path']
        expected = copy.deepcopy(prior['store']); del expected[global_path[len(context['store']['path']) + 1:]]
        assert before['store'] == expected
        for kind in ('other_workspace', 'evidence'):
            assert before[kind] == prior[kind]
        assert retirement['schema'] == 'fsmgen.inactive_runtime_retirement.v1'
        assert retirement['runtime_authorized'] == 0 and retirement['executable'] is None
        assert retirement['retired_workspace'] == context['workspace']['path'] and retirement['released_reference'] == global_path
        spec = retained_spec(context, selection['profile'])
        flow_name = ('equal_reference' if selection['profile'] == 'equal_reference' else 'ordinary') + ':fresh'
        baseline_index = 2 if selection['profile'] == 'equal_reference' else 0
        healthy = baseline['cases'][baseline_index]['operation']['events']
        failure = selection['mode'] in ('zero', 'error')
        if failure:
            assert operation['returned'] == 0 and operation.get('result') is None
            assert operation['error'] == 'cannot write complete canonical bytes: ' + os.strerror(errno.EIO) + '\n'
            prefix, events = FRESH.unwind(healthy, f"writer:{selection['file_index']}:binmode")
            counts[selection['mode'] + '_returns'] += 1
        else:
            assert operation['returned'] == 1 and operation['error'] == ''
            PHYSICAL.operation_checks(context, operation, True, '')
            TRACE.lifetimes(original['flows'][flow_name], operation)
            prefix = events = healthy
            counts['successful_returns'] += 1
        assert operation['events'] == events
        assert operation['descriptors'] == [dict(path=handle['path'], descriptor=handle['descriptor'],
            closed=handle['closed_at_return'], cloexec=handle['cloexec_before_close'])
            for handle in operation['handles'] if handle['kind'] == 'source']
        retained, writes = write_progress(selection, operation, spec, plan['syscall_calls_per_operation'])
        physical(context, operation, spec, retained)
        paths = [file['path'] for file in spec['files']]
        assert operation['reads'] == [paths[int(event.split(':')[2])] for event in prefix if event.startswith('opened:source:')]
        assert operation['writes'] == [paths[int(event.split(':')[1])] for event in prefix if re.fullmatch(r'write:[0-9]+:before', event)]
        assert operation['directories'] == [context['evidence']['path'] + ('/retained-sources' if event.split(':')[1] == 'archive' else '')
            for event in prefix if re.fullmatch(r'directory:(?:evidence|archive):[0-9]+:before', event)]
        kinds = FRESH.handles(operation, prefix, paths)
        assert all(handle['cloexec_before_close'] == 1 for handle in operation['handles'] if handle['kind'] != 'directory')
        for key, value in writes.items():
            counts[key] += value
        for kind, value in kinds.items():
            counts[kind + '_handles'] += value
        counts['cases'] += 1; counts['events'] += len(events)
    assert roots == report['allocated'] and len({row['path'] for row in roots}) == len(roots)
    return dict(counts, roots=len(roots))


def main():
    plan = json.loads((BASE / 'plan.json').read_bytes())
    assert plan['source_revision'] == '2a3af00cd390b0801396c52af7e1fa8d6ef57c12'
    boundary_plan = json.loads((BOUNDARY / 'plan.json').read_bytes())
    dependencies = {pin['path'] for pin in boundary_plan['inputs']}
    dependencies.update(str((BOUNDARY / name).relative_to(ROOT)) for name in
        ('plan.json', 'ArchiveTrace.pm', 'ArchiveFixture.pm', 'extraction.json',
         'audit.py', 'result/qualification.json', 'result/recovery-copies.json'))
    dependencies.update(str((BASE.parent / 'native-proxy-observation-archive-fresh-calls-20260911' / name).relative_to(ROOT))
                        for name in ('plan.json', 'audit.py'))
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
    original = domain(plan, baseline)
    report = json.loads((LOG / 'qualification.json').read_bytes())
    counts = verify(plan, report, original, baseline)
    admission = [json.loads(line) for line in (LOG / 'admission.jsonl').read_text().splitlines()]
    assert admission == report['allocated']
    assert all(not (ROOT / row['path']).exists() and not (ROOT / row['path']).is_symlink() for row in admission)
    assertions = len(plan['cases']) * 5 + 1
    tap = (LOG / 'qualify.tap').read_text()
    assert re.findall(r'^1\.\.([0-9]+)$', tap, re.M) == [str(assertions)]
    assert [int(value) for value in re.findall(r'^ok ([0-9]+) - ', tap, re.M)] == list(range(1, assertions + 1))
    assert not re.search(r'^(?:not ok|Bail out!)', tap, re.M) and (LOG / 'qualify.exit').read_text().strip() == '0'
    def operation(value):
        return value['cases'][0]['operation']
    def call(value):
        return operation(value)['syswrites'][0]
    def failure(value):
        return next(row['operation'] for row in value['cases'] if row['selection']['mode'] == 'error')
    def file(value):
        return next(node for node in operation(value)['after']['evidence'].values() if node['kind'] == 'file')
    def handle(value, kind):
        return next(row for row in operation(value)['handles'] if row['kind'] == kind)
    def other_hold(value):
        row = value['cases'][0]
        path = row['context']['other_observation']['observation_reference']['source']['identity']['path']
        del row['operation']['after']['store'][path[len(row['context']['store']['path']) + 1:]]
    def partial_file(value):
        row = next(row for row in value['cases'] if row['selection']['mode'] == 'error'
                   and row['selection']['offset'] == 'one')
        return next(node for node in row['operation']['after']['evidence'].values() if node['kind'] == 'file')
    def empty_write(value):
        operation = next(row['operation'] for row in value['cases'] if row['selection']['mode'] == 'empty')
        operation['syswrites'].insert(0, copy.deepcopy(call(value)))
    changes = [
        ('missing case', lambda value: value['cases'].pop()),
        ('duplicate case', lambda value: value['cases'].append(copy.deepcopy(value['cases'][0]))),
        ('wrong selected offset', lambda value: value['cases'][1]['selection'].update(offset='last')),
        ('missing syscall', lambda value: operation(value)['syswrites'].pop()),
        ('duplicate syscall', lambda value: operation(value)['syswrites'].append(copy.deepcopy(call(value)))),
        ('wrong syscall offset', lambda value: call(value).update(offset=1)),
        ('wrong remaining count', lambda value: call(value).update(requested=1)),
        ('wrong short request', lambda value: call(value).update(actual_requested=1)),
        ('wrong actual progress', lambda value: call(value).update(actual_return=1)),
        ('wrong reported progress', lambda value: call(value).update(reported_return=1)),
        ('wrong accepted bytes', lambda value: call(value).update(accepted_hex='00')),
        ('wrong buffer digest', lambda value: call(value).update(buffer_sha256='0' * 64)),
        ('wrong file size progression', lambda value: call(value).update(after_size=1)),
        ('foreign syscall writer', lambda value: call(value).update(inode=7)),
        ('unsealed syscall writer', lambda value: call(value).update(cloexec=0)),
        ('modeled result called syscall', lambda value: failure(value)['syswrites'][-1].update(syscall_performed=1)),
        ('hidden successful failure', lambda value: failure(value).update(returned=1)),
        ('replaced write error', lambda value: failure(value).update(error='cleanup error\n')),
        ('unhit write failure', lambda value: failure(value).update(write_fault_hits=0)),
        ('changed archive bytes', lambda value: file(value).update(bytes_hex='00')),
        ('changed partial prefix', lambda value: partial_file(value).update(bytes_hex='00')),
        ('empty payload syscall', empty_write),
        ('changed archive permissions', lambda value: file(value).update(mode=0o600)),
        ('missing cleanup event', lambda value: operation(value)['events'].pop()),
        ('unclosed source', lambda value: handle(value, 'source').update(closed_at_return=0)),
        ('unclosed writer', lambda value: handle(value, 'writer').update(closed_after_call=0)),
        ('unclosed directory', lambda value: handle(value, 'directory').update(actual_close_ok=0)),
        ('unclosed observer duplicate', lambda value: handle(value, 'directory').update(observer_closed=0)),
        ('reopened original target', lambda value: operation(value)['reads'].append('original-target')),
        ('removed other observation hold', other_hold),
        ('changed retained input', lambda value: value['cases'][0].update(inputs_unchanged=0)),
        ('lost allocation', lambda value: value['allocated'].pop()),
        ('process attempt', lambda value: value.update(forbidden_process_attempts=1)),
    ]
    for name, change in changes:
        altered = copy.deepcopy(report); change(altered)
        assert TRACE.reject(lambda: verify(plan, altered, original, baseline)), name
    domains = []
    for name in ['duplicate selection', 'missing offset', 'wrong chunk', 'missing profile']:
        altered = copy.deepcopy(plan)
        if name == 'duplicate selection': altered['cases'].append(copy.deepcopy(altered['cases'][0]))
        elif name == 'missing offset': altered['cases'].pop(1)
        elif name == 'wrong chunk': altered['profiles'][0]['chunk'] = 0
        else: altered['profiles'].pop()
        assert TRACE.reject(lambda: domain(altered, baseline)), name
        domains.append(name)
    output = dict(schema='fsmgen.inactive_archive_partial_writes_audit.v1', success=True, **counts,
        tap_assertions=assertions, report_falsifiers=[name for name, _ in changes], domain_falsifiers=domains,
        all_allocations_absent=True, predecessor_inputs_unchanged=len(plan['inputs']),
        prospective_inputs_unchanged=len(pins), limits=plan['limits'])
    (LOG / 'audit.json').write_text(json.dumps(output, indent=2, sort_keys=True) + '\n')
    print(json.dumps(output, sort_keys=True))


if __name__ == '__main__':
    main()

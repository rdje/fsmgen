"""Independently verify post-admission identity replacement, preserved objects and actual cleanup."""
from __future__ import annotations

import copy
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs/native-proxy-observation-archive-replacements-20260911'
BOUNDARY = BASE.parent / 'native-proxy-observation-archive-boundaries-20260911'
CLOSE_BASE = BASE.parent / 'native-proxy-observation-archive-close-reports-20260911'
specification = importlib.util.spec_from_file_location('archive_replacement_custody_oracle', CLOSE_BASE / 'audit.py')
CLOSE = importlib.util.module_from_spec(specification)
specification.loader.exec_module(CLOSE)
PARTIAL, FRESH, TRACE, PHYSICAL = CLOSE.PARTIAL, CLOSE.FRESH, CLOSE.TRACE, CLOSE.PHYSICAL
REVISION = 'cb070ba4b28151f6089aae2555846f6a154296e5'


def domain(plan, original, baseline):
    TRACE.verify(original, baseline)
    profiles = [dict(name='ordinary', wrapper='ordinary', files=4),
                dict(name='equal_reference', wrapper='equal_reference', files=3)]
    assert plan['profiles'] == profiles
    cases = []
    for profile, size in [('ordinary', 4), ('equal_reference', 3)]:
        for kind, index in [('healthy', None), ('file', 0), ('file', size - 1), ('directory', None)]:
            selector = f'recheck:source:{index}:0:0:before' if kind == 'file' else f'directory_closure:{size + 1}:before' if kind == 'directory' else None
            cases.append(dict(name=profile + ':' + kind + (f':{index}' if index is not None else ''),
                              profile=profile, kind=kind, index=index, selector=selector))
    assert plan['cases'] == cases and len({row['name'] for row in cases}) == len(cases)
    for case in cases:
        if case['selector']:
            assert any(row['event'] == case['selector'] and row['call_fault_eligible']
                       for row in original['flows'][case['profile'] + ':existing']['events'])


def source_proof(archive, custody):
    implementation = archive.split('sub archive_retained_sources {', 1)[1]
    assert implementation.index('push @{$state->{sources}}, NativeProxyImageCustody::_source(') < implementation.index('NativeProxyImageCustody::_recheck_source($source);')
    assert implementation.index('_source_closure($state);') > implementation.index(r'_members($state, \@names);')
    closure = archive.split('sub _directory_closure {', 1)[1].split('\nsub ', 1)[0]
    assert '::_directory("$ROOT/$directory->{path}")' in closure
    assert '_same_metadata($directory->{metadata}, $current, 0,1,2,4)' in closure
    check = custody.split('sub _recheck_source {', 1)[1].split('\nsub ', 1)[0]
    assert 'stat($source->{handle})' in check and 'lstat($source->{path})' in check
    assert r'_same_metadata($source->{metadata}, \@descriptor, 0,1,2,3,4,7,9,10)' in check
    assert r'_same_metadata($source->{metadata}, \@named, 0,1,2,3,4,7,9,10)' in check


def events(selection, healthy):
    if selection['kind'] == 'healthy':
        return healthy, healthy
    cut = selection['selector']
    if selection['kind'] == 'directory':
        # Replacement occurs before closure. The unchanged body observes both
        # directory identities before rejecting the replaced archive identity.
        tail = healthy[healthy.index(cut) + 1:]
        cut = next(event for event in tail if re.fullmatch(r'directory:archive:[0-9]+:after', event))
    return CLOSE.unwind(dict(kind='primary', reports=[], primary=cut, route='existing'), healthy)


def metadata(actual, physical):
    assert type(actual) is list and len(actual) == 13 and all(type(value) is int for value in actual)
    assert actual[0] == physical['device'] and actual[1] == physical['inode']
    assert actual[2] == (0o100000 | physical['mode'])
    assert actual[3] == physical['links'] and actual[4] == physical['uid'] and actual[7] == physical['size_bytes']


def mutation(selection, row, spec):
    operation = row['operation']; before, after = operation['before'], operation['after']
    assert operation['before'] == row['preparation']['after']
    if selection['kind'] == 'healthy':
        assert operation['replacement_hits'] == 0 and operation['replacement'] is None and before == after
        return 0, 0
    assert operation['replacement_hits'] == 1
    record = operation['replacement']; kind = selection['kind']
    assert set(record) == {'selector', 'kind', 'complete', 'original_retained', 'before', 'after',
                          'descriptors_before', 'descriptors_after', 'path', 'retained', 'error'}
    assert record['selector'] == selection['selector'] and record['kind'] == kind
    assert record['complete'] == record['original_retained'] == 1 and record['error'] == ''
    assert record['before'] == before and record['after'] == after
    for area in ('store', 'workspace', 'other_workspace'):
        assert before[area] == after[area]
    evidence = row['context']['evidence']['path']; paths = [file['path'] for file in spec['files']]
    source = paths[selection['index']] if kind == 'file' else spec['archive_directory']
    retained = evidence + '/displaced-' + (f"source-{selection['index']}" if kind == 'file' else 'archive')
    assert record['path'] == source and record['retained'] == retained
    source_key, retained_key = source.removeprefix(evidence + '/'), retained.removeprefix(evidence + '/')
    expected = copy.deepcopy(before['evidence'])
    keys = [key for key in expected if key == source_key or key.startswith(source_key + '/')]
    assert len(keys) == (1 if kind == 'file' else len(paths) + 1)
    all_native = {(node['device'], node['inode']) for node in expected.values()}
    for key in keys:
        saved_key = retained_key + key[len(source_key):]
        assert saved_key not in expected
        original = expected[key]
        expected[saved_key] = original
        replacement = after['evidence'][key]
        assert set(replacement) == set(original)
        assert type(replacement['inode']) is int and replacement['inode'] > 0
        assert (replacement['device'], replacement['inode']) not in all_native
        all_native.add((replacement['device'], replacement['inode']))
        assert {k: v for k, v in replacement.items() if k != 'inode'} == {k: v for k, v in original.items() if k != 'inode'}
        expected[key] = replacement
    assert after['evidence'] == expected
    admitted = selection['index'] + 1 if kind == 'file' else len(paths)
    handles = {handle['label']: handle for handle in operation['handles']}
    for phase in ('before', 'after'):
        witnesses = record['descriptors_' + phase]
        assert [w['label'] for w in witnesses] == [f'source:{index}:0' for index in range(admitted)]
        assert len({w['descriptor'] for w in witnesses}) == admitted
        for index, witness in enumerate(witnesses):
            assert set(witness) == {'label', 'path', 'descriptor', 'metadata', 'named', 'cloexec'}
            handle = handles[witness['label']]
            assert witness['path'] == paths[index] and witness['descriptor'] == handle['descriptor']
            assert witness['cloexec'] == 1
            key = paths[index].removeprefix(evidence + '/')
            metadata(witness['metadata'], before['evidence'][key])
            metadata(witness['named'], (before if phase == 'before' else after)['evidence'][key])
            assert (handle['device'], handle['inode']) == (witness['metadata'][0], witness['metadata'][1])
    # The recorded native identity remains the admitted original even where the
    # canonical name now resolves to the byte-identical replacement.
    for index in range(admitted):
        initial, final = record['descriptors_before'][index], record['descriptors_after'][index]
        assert initial['descriptor'] == final['descriptor']
        assert initial['metadata'][:2] == final['metadata'][:2]
        changed = kind == 'directory' or index == selection['index']
        assert (final['metadata'][:2] != final['named'][:2]) is changed
    return admitted, len(keys)


def admitted_handles(operation, prefix, paths):
    # Every opening in these selected failure prefixes precedes the mutation.
    # Supply that authenticated admission census to the unchanged native handle
    # oracle; keep every actual close flag, event and original operation intact.
    admission_view = dict(operation, after=operation['before'])
    return FRESH.handles(admission_view, prefix, paths)


def verify(plan, report, original, baseline):
    assert report['schema'] == 'fsmgen.inactive_archive_replacements_qualification.v1'
    assert report['success'] is True and report['forbidden_process_attempts'] == 0
    assert [row['name'] for row in report['cases']] == [case['name'] for case in plan['cases']]
    flows = {row['name']: row['operation']['events'] for row in baseline['cases']}
    roots = []
    counts = dict(cases=0, operations=0, preparations=0, healthy_returns=0, replacement_rejections=0,
                  events=0, source_handles=0, writer_handles=0, directory_handles=0,
                  witnessed_live_sources=0, retained_replaced_objects=0)
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
        preparation, operation = row['preparation'], row['operation']
        assert preparation['before'] == retired
        PHYSICAL.operation_checks(context, preparation, True, '')
        fresh = selection['profile'] + ':fresh'
        assert preparation['events'] == flows[fresh]
        TRACE.lifetimes(original['flows'][fresh], preparation)
        CLOSE.projection(preparation)
        kinds = FRESH.handles(preparation, flows[fresh], paths)
        for kind, number in kinds.items(): counts[kind + '_handles'] += number
        counts['preparations'] += 1; counts['operations'] += 1; counts['events'] += len(preparation['events'])
        witnessed, retained_objects = mutation(selection, row, spec)
        counts['witnessed_live_sources'] += witnessed; counts['retained_replaced_objects'] += retained_objects
        flow = selection['profile'] + ':existing'; prefix, complete = events(selection, flows[flow])
        assert operation['events'] == complete and len(complete) == len(set(complete))
        kind = selection['kind']
        if kind == 'healthy':
            PHYSICAL.operation_checks(context, operation, True, '')
            TRACE.lifetimes(original['flows'][flow], operation)
            counts['healthy_returns'] += 1
        else:
            assert operation['returned'] == 0 and operation.get('result') is None
            assert operation['error'] == ('source descriptor or named identity changed\n' if kind == 'file' else 'archive or evidence directory changed\n')
            counts['replacement_rejections'] += 1
            cut = prefix.index(selection['selector'])
            assert not any(event.startswith('opened:') for event in prefix[cut + 1:])
        CLOSE.projection(operation)
        kinds = admitted_handles(operation, prefix, paths)
        assert kinds['writer'] == 0 and operation['writes'] == []
        assert operation['reads'] == [paths[int(event.split(':')[2])] for event in prefix if event.startswith('opened:source:')]
        assert operation['directories'] == [context['evidence']['path'] + ('/retained-sources' if event.split(':')[1] == 'archive' else '')
            for event in prefix if re.fullmatch(r'directory:(?:evidence|archive):[0-9]+:before', event)]
        for kind, number in kinds.items(): counts[kind + '_handles'] += number
        counts['cases'] += 1; counts['operations'] += 1; counts['events'] += len(complete)
    assert roots == report['allocated'] and len({row['path'] for row in roots}) == len(roots)
    return dict(counts, roots=len(roots))


def main():
    plan = json.loads((BASE / 'plan.json').read_bytes()); assert plan['source_revision'] == REVISION
    predecessor = json.loads((CLOSE_BASE / 'plan.json').read_bytes())
    dependencies = {pin['path'] for pin in predecessor['inputs']}
    dependencies.update(str((CLOSE_BASE / name).relative_to(ROOT)) for name in ('plan.json', 'audit.py'))
    assert [pin['path'] for pin in plan['inputs']] == sorted(dependencies)
    pins = json.loads((BASE / 'preflight-pins.json').read_bytes())
    assert [pin['path'] for pin in pins] == [str((BASE / name).relative_to(ROOT)) for name in ('plan.py', 'plan.json', 'ArchiveReplacement.pm', 'qualify.t', 'audit.py')]
    def authenticate():
        for pin in plan['inputs'] + pins:
            raw = (ROOT / pin['path']).read_bytes()
            assert len(raw) == pin['size_bytes'] and hashlib.sha256(raw).hexdigest() == pin['sha256']
            if pin in plan['inputs']:
                assert raw == subprocess.check_output(['git', 'show', REVISION + ':' + pin['path']], cwd=ROOT)
    authenticate()
    sources = [(BASE.parent / component / filename).read_text() for component, filename in
               [('native-proxy-observation-archive-20260911', 'ObservationArchive.pm'),
                ('native-proxy-image-custody-20260910', 'ImageCustody.pm')]]
    source_proof(*sources)
    original = json.loads((BOUNDARY / 'plan.json').read_bytes())
    baseline = json.loads((BOUNDARY / 'result/qualification.json').read_bytes())
    domain(plan, original, baseline)
    report = json.loads((LOG / 'qualification.json').read_bytes()); counts = verify(plan, report, original, baseline)
    admission = [json.loads(line) for line in (LOG / 'admission.jsonl').read_text().splitlines()]
    assert admission == report['allocated']
    device = ROOT.stat().st_dev
    for row in admission:
        path = ROOT / row['path']
        assert not path.exists() and not path.is_symlink() and row['device'] == device
        parent = path.parent
        while parent != ROOT:
            assert not parent.is_symlink() and parent.is_dir() and parent.stat().st_dev == device
            parent = parent.parent
    assertions = len(plan['cases']) * 7 + 1
    tap = (LOG / 'qualify.tap').read_text()
    assert re.findall(r'^1\.\.([0-9]+)$', tap, re.M) == [str(assertions)]
    assert [int(value) for value in re.findall(r'^ok ([0-9]+) - ', tap, re.M)] == list(range(1, assertions + 1))
    assert not re.search(r'^(?:not ok|Bail out!)|#\s*(?:SKIP|TODO)', tap, re.M)
    assert (LOG / 'qualify.exit').read_text().strip() == '0'
    def rich(value): return next(row for row in value['cases'] if row['selection']['kind'] == 'directory')
    def op(value): return rich(value)['operation']
    def mutation_record(value): return op(value)['replacement']
    def witness(value): return mutation_record(value)['descriptors_after'][0]
    def handle(value, kind): return next(row for row in op(value)['handles'] if row['kind'] == kind)
    def saved(value): return next(node for key, node in op(value)['after']['evidence'].items() if key.startswith('displaced-archive/'))
    def changed(value): return next(node for key, node in op(value)['after']['evidence'].items() if key.startswith('retained-sources/'))
    def other_hold(value):
        row = rich(value); path = row['context']['other_observation']['observation_reference']['source']['identity']['path']
        del op(value)['after']['store'][path[len(row['context']['store']['path']) + 1:]]
    changes = [
        ('missing case', lambda r: r['cases'].pop()),
        ('duplicate case', lambda r: r['cases'].append(copy.deepcopy(r['cases'][0]))),
        ('changed selection', lambda r: rich(r)['selection'].update(selector='receipt:before')),
        ('lost preparation', lambda r: rich(r).pop('preparation')),
        ('failed preparation', lambda r: rich(r)['preparation'].update(returned=0)),
        ('unclosed preparation handle', lambda r: rich(r)['preparation']['handles'][0].update(closed_at_return=0)),
        ('missing preparation binding', lambda r: rich(r)['preparation']['result']['source_bindings'].pop()),
        ('unhit replacement', lambda r: op(r).update(replacement_hits=0)),
        ('incomplete replacement', lambda r: mutation_record(r).update(complete=0)),
        ('lost live witness', lambda r: mutation_record(r)['descriptors_after'].pop()),
        ('unretained original', lambda r: mutation_record(r).update(original_retained=0)),
        ('foreign live descriptor', lambda r: witness(r).update(descriptor=987654)),
        ('wrong live inode', lambda r: witness(r)['metadata'].__setitem__(1, 7)),
        ('hidden named replacement', lambda r: witness(r).update(named=witness(r)['metadata'][:])),
        ('lost live CLOEXEC', lambda r: witness(r).update(cloexec=0)),
        ('wrong first error', lambda r: op(r).update(error='wrong error\n')),
        ('hidden successful verification', lambda r: op(r).update(returned=1)),
        ('missing cleanup event', lambda r: op(r)['events'].pop()),
        ('unclosed admitted source', lambda r: handle(r, 'source').update(closed_at_return=0)),
        ('unclosed directory', lambda r: handle(r, 'directory').update(actual_close_ok=0)),
        ('unclosed observer duplicate', lambda r: handle(r, 'directory').update(observer_closed=0)),
        ('wrong admission identity', lambda r: handle(r, 'source').update(inode=7)),
        ('lost original bytes', lambda r: saved(r).update(bytes_hex='00')),
        ('changed replacement bytes', lambda r: changed(r).update(bytes_hex='00')),
        ('aliased replacement inode', lambda r: changed(r).update(inode=saved(r)['inode'])),
        ('changed replacement permissions', lambda r: changed(r).update(mode=0o600)),
        ('original target read', lambda r: op(r)['reads'].append('original-target')),
        ('unexpected write', lambda r: op(r)['writes'].append('unexpected')),
        ('removed other hold', other_hold),
        ('changed retained input', lambda r: rich(r).update(inputs_unchanged=0)),
        ('lost allocation', lambda r: r['allocated'].pop()),
        ('process attempt', lambda r: r.update(forbidden_process_attempts=1)),
    ]
    for name, change in changes:
        altered = copy.deepcopy(report); change(altered)
        assert TRACE.reject(lambda: verify(plan, altered, original, baseline)), name
    domain_changes = [
        ('omitted directory replacement', lambda p: p['cases'].pop(3)),
        ('aliased late source', lambda p: p['cases'][2].update(index=0)),
        ('unsafe admission selector', lambda p: p['cases'][1].update(selector='opened:source:0:0')),
        ('missing healthy control', lambda p: p['cases'].pop(0)),
        ('changed equal profile', lambda p: p['profiles'][1].update(files=4)),
    ]
    for name, change in domain_changes:
        altered = copy.deepcopy(plan); change(altered)
        assert TRACE.reject(lambda: domain(altered, original, baseline)), name
    source_changes = [
        ('lost directory inode comparison', 0, '$directory->{metadata}, $current, 0,1,2,4', '$directory->{metadata}, $current, 0,2,4'),
        ('lost named identity observation', 1, 'lstat($source->{path})', 'stat($source->{handle})'),
        ('lost descriptor identity observation', 1, 'stat($source->{handle})', 'lstat($source->{path})'),
    ]
    for name, index, old, new in source_changes:
        altered = sources.copy(); assert old in altered[index]; altered[index] = altered[index].replace(old, new)
        assert TRACE.reject(lambda: source_proof(*altered)), name
    authenticate()
    output = dict(schema='fsmgen.inactive_archive_replacements_audit.v1', success=True, **counts,
        tap_assertions=assertions, report_falsifiers=[name for name, _ in changes],
        domain_falsifiers=[name for name, _ in domain_changes], source_falsifiers=[row[0] for row in source_changes],
        predecessor_inputs_unchanged=len(plan['inputs']), prospective_inputs_unchanged=len(pins),
        all_allocations_absent=True, limits=plan['limits'])
    (LOG / 'audit.json').write_text(json.dumps(output, indent=2, sort_keys=True) + '\n')
    print(json.dumps(output, sort_keys=True))


if __name__ == '__main__':
    main()

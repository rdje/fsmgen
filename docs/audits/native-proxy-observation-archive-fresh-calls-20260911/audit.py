"""Derive fault unwind, conservative files and preserved owners independently."""
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
LOG = ROOT / '.artifacts/logs/native-proxy-observation-archive-fresh-calls-20260911'
BOUNDARY = BASE.parent / 'native-proxy-observation-archive-boundaries-20260911'
_spec = importlib.util.spec_from_file_location('fresh_cut_boundaries', BOUNDARY / 'audit.py')
TRACE = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(TRACE)
PHYSICAL = TRACE.PHYSICAL


def domain(plan, baseline):
    original = json.loads((BOUNDARY / 'plan.json').read_bytes())
    TRACE.verify(original, baseline)
    assert plan['profile'] == dict(name='ordinary', wrapper='ordinary', files=4)
    assert plan['route'] == 'fresh'
    healthy = baseline['cases'][0]['operation']['events']
    assert baseline['cases'][0]['name'] == 'ordinary:fresh'
    selectors = [e for e in healthy if TRACE.eligible(e)]
    assert plan['cases'] == [dict(name='ordinary:fresh:' + e, selector=e) for e in selectors]
    assert len(selectors) == len(set(selectors))
    return healthy


def unwind(healthy, selector):
    """Interpret actual successful prefix, then the source-owned cleanup scopes.

    The selected exception terminates ordinary nested helper returns. Payload
    readers precede their writer; a closure reread precedes retained sources.
    The archive cleanup scope exists only after initial directory acquisition.
    """
    assert healthy.count(selector) == 1
    prefix = healthy[:healthy.index(selector) + 1]
    owned = []
    for event in prefix:
        if event.startswith('opened:'):
            label = event[len('opened:'):]
            assert label not in owned
            owned.append(label)
        elif event.startswith('close:') and event.endswith(':after'):
            owned.remove(event[len('close:'):-len(':after')])
    retained = [h for h in owned if re.fullmatch(r'source:[0-9]+:1', h)]
    transient = [h for h in owned if h not in retained]
    assert not any(h.startswith('directory_handle:') for h in transient)
    readers = [h for h in transient if h.startswith('source:')]
    writers = [h for h in transient if h.startswith('writer:')]
    assert len(readers) <= 1 and len(writers) <= 1
    suffix = []
    def close(label):
        suffix.extend(['close:' + label + ':before', 'close:' + label + ':after'])
    for label in readers + writers:
        close(label)
    if 'directory_closure:0:before' in prefix:
        suffix.append('close_sources:before')
        for label in retained:
            close(label)
        suffix.append('close_sources:after')
    else:
        assert not owned
    return prefix, prefix + suffix


def physical(context, operation, prefix):
    value = dict(case=context['store']['path'], request=context['request'],
                 acquired=PHYSICAL.wire(context['acquired']))
    spec = PHYSICAL.RECORD.specification(value)
    assert len(spec['files']) == 4 and len(spec['sources']) == 5
    before = operation['before']; after = operation['after']
    for kind in ('store', 'workspace', 'other_workspace'):
        assert before[kind] == after[kind]
    assert set(before['evidence']) == {''}
    assert before['evidence'][''] == after['evidence']['']
    expected = {''}
    created = 'mkdir:after' in prefix
    if created:
        expected.add('retained-sources')
        directory = after['evidence']['retained-sources']
        assert directory['kind'] == 'directory' and directory['mode'] == 0o700
        assert directory['device'] == context['evidence']['device']
        assert directory['uid'] == before['evidence']['']['uid']
    files = spec['files']
    for index, file in enumerate(files):
        if f'opened:writer:{index}' not in prefix:
            continue
        assert created
        key = 'retained-sources/' + file['sha256'] + '.source'
        expected.add(key)
        node = after['evidence'][key]
        raw = bytes.fromhex(file['bytes_hex']) if f'source:{index}:0:before' in prefix else b''
        identity = PHYSICAL.file_identity(file['path'], node)
        assert node['bytes_hex'] == raw.hex() and identity['size_bytes'] == len(raw)
        assert node['mode'] == 0o400 and node['uid'] == directory['uid']
        assert node['device'] == directory['device']
    assert set(after['evidence']) == expected
    identities = [(n['device'], n['inode']) for n in after['evidence'].values()]
    assert len(identities) == len(set(identities))
    paths = [f['path'] for f in files]
    assert operation['reads'] == [paths[int(e.split(':')[2])] for e in prefix if e.startswith('opened:source:')]
    assert operation['writes'] == [paths[int(e.split(':')[1])] for e in prefix if re.fullmatch(r'write:[0-9]+:before', e)]
    assert operation['directories'] == [context['evidence']['path'] + ('/retained-sources' if e.split(':')[1] == 'archive' else '')
        for e in prefix if re.fullmatch(r'directory:(?:evidence|archive):[0-9]+:before', e)]
    return paths


def handles(operation, prefix, paths):
    observed = operation['handles']
    assert operation['all_observed_handles_closed'] == 1
    assert [h['label'] for h in observed] == [e[len('opened:'):] for e in prefix if e.startswith('opened:')]
    kinds = dict(source=0, writer=0, directory=0)
    for handle in observed:
        label = handle['label']; kind = handle['kind']
        assert handle['actual_close_ok'] == handle['closed_after_call'] == handle['closed_at_return'] == 1
        assert handle['actual_errno'] == 0
        assert type(handle['descriptor']) is int and handle['descriptor'] >= 0
        if label.startswith('directory_handle:'):
            assert kind == 'directory' and handle['observer_closed'] == 1
            assert handle['observer_descriptor'] != handle['descriptor']
            assert handle['cloexec_before_close'] is None
            path = paths[0].rsplit('/', 1)[0]
        else:
            index = int(label.split(':')[1]); path = paths[index]
            assert handle['file_index'] == index
            assert kind == label.split(':')[0]
            # The binmode cut precedes the writer's explicit CLOEXEC setup.
            # Record that actual flag without claiming the later seal exists.
            if kind == 'writer' and f'source:{index}:0:before' not in prefix:
                assert handle['cloexec_before_close'] in (0, 1)
            else:
                assert handle['cloexec_before_close'] == 1
        assert handle['path'] == path
        key = 'retained-sources' + path.split('/retained-sources', 1)[1]
        native = operation['after']['evidence'][key]
        assert (handle['device'], handle['inode']) == (native['device'], native['inode'])
        kinds[kind] += 1
    return kinds


def verify(plan, report, healthy):
    assert report['schema'] == 'fsmgen.inactive_archive_fresh_calls_qualification.v1'
    assert report['success'] is True and report['forbidden_process_attempts'] == 0
    assert [r['name'] for r in report['cases']] == [c['name'] for c in plan['cases']]
    roots = []; counts = dict(cases=0, events=0, source_handles=0, writer_handles=0, directory_handles=0)
    for selection, row in zip(plan['cases'], report['cases'], strict=True):
        selector = selection['selector']
        assert row['selector'] == selector and row['injected_hits'] == row['inputs_unchanged'] == 1
        context = row['context']; prior = row['prior_retirement']; operation = row['operation']
        for kind in ('store', 'workspace', 'other_workspace', 'evidence'):
            identity = context[kind]; roots.append(dict(kind=kind, **identity))
            node = prior[kind]['']
            assert node['kind'] == 'directory' and node['mode'] == 0o700
            assert (node['device'], node['inode']) == (identity['device'], identity['inode'])
        PHYSICAL.target_inputs(context, prior)
        before = operation['before']; retirement = row['retirement']
        assert before['workspace'] == {}
        global_path = context['runtime']['reference']['global']['identity']['path']
        expected = copy.deepcopy(prior['store'])
        del expected[global_path[len(context['store']['path']) + 1:]]
        assert before['store'] == expected
        for kind in ('other_workspace', 'evidence'):
            assert before[kind] == prior[kind]
        assert retirement['schema'] == 'fsmgen.inactive_runtime_retirement.v1'
        assert retirement['runtime_authorized'] == 0 and retirement['executable'] is None
        assert retirement['retired_workspace'] == context['workspace']['path']
        assert retirement['released_reference'] == global_path
        assert operation['returned'] == 0 and operation.get('result') is None
        assert operation['error'] == 'injected archive call: ' + selector + '\n'
        prefix, events = unwind(healthy, selector)
        assert operation['events'] == events and len(events) == len(set(events))
        paths = physical(context, operation, prefix)
        kinds = handles(operation, prefix, paths)
        for kind, count in kinds.items():
            counts[kind + '_handles'] += count
        counts['cases'] += 1; counts['events'] += len(events)
    assert roots == report['allocated'] and len({r['path'] for r in roots}) == len(roots)
    return dict(counts, roots=len(roots))


def main():
    plan = json.loads((BASE / 'plan.json').read_bytes())
    for pin in plan['inputs']:
        raw = (ROOT / pin['path']).read_bytes()
        assert raw == subprocess.check_output(['git', 'show', plan['source_revision'] + ':' + pin['path']], cwd=ROOT)
        assert len(raw) == pin['size_bytes'] and hashlib.sha256(raw).hexdigest() == pin['sha256']
    pins = json.loads((LOG / 'preflight-pins.json').read_bytes())
    for pin in pins:
        raw = (ROOT / pin['path']).read_bytes()
        assert len(raw) == pin['size_bytes'] and hashlib.sha256(raw).hexdigest() == pin['sha256']
    baseline = json.loads((BOUNDARY / 'result/qualification.json').read_bytes())
    healthy = domain(plan, baseline)
    report = json.loads((LOG / 'qualification.json').read_bytes())
    counts = verify(plan, report, healthy)
    admission = [json.loads(line) for line in (LOG / 'admission.jsonl').read_text().splitlines()]
    assert admission == report['allocated']
    for row in admission:
        path = ROOT / row['path']
        assert not path.exists() and not path.is_symlink()
    assertions = len(plan['cases']) * 5 + 1
    tap = (LOG / 'qualify.tap').read_text()
    assert re.findall(r'^1\.\.([0-9]+)$', tap, re.M) == [str(assertions)]
    assert [int(x) for x in re.findall(r'^ok ([0-9]+) - ', tap, re.M)] == list(range(1, assertions + 1))
    assert not re.search(r'^(?:not ok|Bail out!)', tap, re.M)
    assert (LOG / 'qualify.exit').read_text().strip() == '0'
    def rich(r):
        return r['cases'][-1]['operation']
    def first_handle(r, kind):
        return next(h for h in rich(r)['handles'] if h['kind'] == kind)
    def archive_file(r):
        return next(n for n in rich(r)['after']['evidence'].values() if n['kind'] == 'file')
    def other_hold(r):
        row = r['cases'][-1]
        path = row['context']['other_observation']['observation_reference']['source']['identity']['path']
        del row['operation']['after']['store'][path[len(row['context']['store']['path']) + 1:]]
    changes = [
        ('missing case', lambda r: r['cases'].pop()),
        ('duplicate case', lambda r: r['cases'].append(copy.deepcopy(r['cases'][0]))),
        ('wrong selected occurrence', lambda r: r['cases'][0].update(selector='limits:after')),
        ('unhit fault', lambda r: r['cases'][0].update(injected_hits=0)),
        ('hidden successful return', lambda r: rich(r).update(returned=1)),
        ('replaced primary error', lambda r: rich(r).update(error='cleanup error\n')),
        ('missing cleanup event', lambda r: rich(r)['events'].pop()),
        ('duplicate cleanup event', lambda r: rich(r)['events'].append(rich(r)['events'][-1])),
        ('unclosed source', lambda r: first_handle(r, 'source').update(closed_at_return=0)),
        ('unclosed writer', lambda r: first_handle(r, 'writer').update(closed_after_call=0)),
        ('unclosed directory', lambda r: first_handle(r, 'directory').update(actual_close_ok=0)),
        ('unclosed observer duplicate', lambda r: first_handle(r, 'directory').update(observer_closed=0)),
        ('wrong descriptor identity', lambda r: first_handle(r, 'source').update(inode=7)),
        ('lost source CLOEXEC', lambda r: first_handle(r, 'source').update(cloexec_before_close=0)),
        ('changed archive bytes', lambda r: archive_file(r).update(bytes_hex='00')),
        ('changed archive permissions', lambda r: archive_file(r).update(mode=0o600)),
        ('missing archive object', lambda r: rich(r)['after']['evidence'].pop('retained-sources')),
        ('reopened original target', lambda r: rich(r)['reads'].append('original-target')),
        ('removed other observation hold', other_hold),
        ('changed retained input', lambda r: r['cases'][0].update(inputs_unchanged=0)),
        ('lost root', lambda r: r['allocated'].pop()),
        ('process attempt', lambda r: r.update(forbidden_process_attempts=1)),
    ]
    for name, change in changes:
        altered = copy.deepcopy(report); change(altered)
        assert TRACE.reject(lambda: verify(plan, altered, healthy)), name
    domains = []
    for name in ('duplicate selector', 'unsafe ownership fault', 'omitted selector'):
        altered = copy.deepcopy(plan)
        if name == 'duplicate selector': altered['cases'].append(copy.deepcopy(altered['cases'][0]))
        elif name == 'unsafe ownership fault': altered['cases'][0]['selector'] = 'opened:source:0:0'
        else: altered['cases'].pop()
        assert TRACE.reject(lambda: domain(altered, baseline)), name
        domains.append(name)
    output = dict(schema='fsmgen.inactive_archive_fresh_calls_audit.v1', success=True, **counts,
        tap_assertions=assertions, report_falsifiers=[name for name, _ in changes],
        domain_falsifiers=domains, all_allocations_absent=True,
        predecessor_inputs_unchanged=len(plan['inputs']), prospective_inputs_unchanged=len(pins), limits=plan['limits'])
    (LOG / 'audit.json').write_text(json.dumps(output, indent=2, sort_keys=True) + '\n')
    print(json.dumps(output, sort_keys=True))


if __name__ == '__main__':
    main()

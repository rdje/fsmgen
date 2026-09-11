"""Verify observed preparation, existing-archive unwind and exact preservation."""
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
LOG = ROOT / '.artifacts/logs/native-proxy-observation-archive-equal-existing-calls-20260911'
BOUNDARY = BASE.parent / 'native-proxy-observation-archive-boundaries-20260911'
_spec = importlib.util.spec_from_file_location('existing_archive_handle_oracle',
    BASE.parent / 'native-proxy-observation-archive-fresh-calls-20260911/audit.py')
FRESH = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(FRESH)
TRACE = FRESH.TRACE
PHYSICAL = FRESH.PHYSICAL


def domain(plan, baseline):
    original = json.loads((BOUNDARY / 'plan.json').read_bytes())
    TRACE.verify(original, baseline)
    assert plan['profile'] == dict(name='equal_reference', wrapper='equal_reference', files=3)
    assert plan['route'] == 'existing'
    fresh, existing = baseline['cases'][2:4]
    assert [fresh['name'], existing['name']] == ['equal_reference:fresh', 'equal_reference:existing']
    assert plan['preparation_events'] == fresh['operation']['events']
    healthy = existing['operation']['events']
    selectors = [event for event in healthy if TRACE.eligible(event)]
    assert len(selectors) == len(set(selectors))
    assert plan['cases'] == [dict(name='equal_reference:existing:' + event, selector=event) for event in selectors]
    return healthy, original['flows']['equal_reference:fresh']


def unwind(healthy, selector):
    """Only reread and retained-source cleanup can follow an existing-route cut."""
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
    retained = [h for h in owned if re.fullmatch(r'source:[0-9]+:0', h)]
    reread = [h for h in owned if re.fullmatch(r'source:[0-9]+:1', h)]
    assert len(reread) <= 1 and set(owned) == set(retained + reread)
    suffix = []
    def close(label):
        suffix.extend(['close:' + label + ':before', 'close:' + label + ':after'])
    for label in reread:
        close(label)
    if 'directory_closure:0:before' in prefix:
        suffix.append('close_sources:before')
        for label in retained:
            close(label)
        suffix.append('close_sources:after')
    else:
        assert not owned
    return prefix, prefix + suffix


def retirement_checks(row):
    context = row['context']; prior = row['prior_retirement']
    retired = row['preparation']['before']; retirement = row['retirement']
    PHYSICAL.target_inputs(context, prior)
    assert retired['workspace'] == {}
    global_path = context['runtime']['reference']['global']['identity']['path']
    expected = copy.deepcopy(prior['store'])
    del expected[global_path[len(context['store']['path']) + 1:]]
    assert retired['store'] == expected
    for kind in ('other_workspace', 'evidence'):
        assert retired[kind] == prior[kind]
    assert retirement['schema'] == 'fsmgen.inactive_runtime_retirement.v1'
    assert retirement['runtime_authorized'] == 0 and retirement['executable'] is None
    assert retirement['retired_workspace'] == context['workspace']['path']
    assert retirement['released_reference'] == global_path


def verify(plan, report, healthy, fresh_flow):
    assert report['schema'] == 'fsmgen.inactive_archive_equal_existing_calls_qualification.v1'
    assert report['success'] is True and report['forbidden_process_attempts'] == 0
    assert [row['name'] for row in report['cases']] == [case['name'] for case in plan['cases']]
    roots = []
    counts = dict(cases=0, operations=0, preparation_events=0, interruption_events=0,
        preparation_source_handles=0, preparation_writer_handles=0, preparation_directory_handles=0,
        interruption_source_handles=0, interruption_writer_handles=0, interruption_directory_handles=0)
    for selection, row in zip(plan['cases'], report['cases'], strict=True):
        context = row['context']; prior = row['prior_retirement']
        selector = selection['selector']; operation = row['operation']; preparation = row['preparation']
        assert row['selector'] == selector and row['injected_hits'] == row['inputs_unchanged'] == 1
        for kind in ('store', 'workspace', 'other_workspace', 'evidence'):
            identity = context[kind]; roots.append(dict(kind=kind, **identity))
            node = prior[kind]['']
            assert node['kind'] == 'directory' and node['mode'] == 0o700
            assert (node['device'], node['inode']) == (identity['device'], identity['inode'])
        retirement_checks(row)
        PHYSICAL.operation_checks(context, preparation, True, '')
        TRACE.lifetimes(fresh_flow, preparation)
        assert preparation['events'] == plan['preparation_events']
        assert preparation['descriptors'] == [dict(path=h['path'], descriptor=h['descriptor'],
            closed=h['closed_at_return'], cloexec=h['cloexec_before_close'])
            for h in preparation['handles'] if h['kind'] == 'source']
        spec, receipt = PHYSICAL.physical_receipt(context, preparation)
        assert len(spec['files']) == 3 and len(receipt['source_bindings']) == 5
        shared = spec['sources'][:3]
        assert [source['role'] for source in shared] == ['wrapper', 'private_reference', 'global_reference']
        assert len({source['snapshot']['bytes_hex'] for source in shared}) == 1
        assert len({source['destination'] for source in shared}) == 1
        identities = [source['snapshot']['identity'] for source in shared]
        assert len({identity['path'] for identity in identities}) == 3
        assert len({(identity['device'], identity['inode']) for identity in identities}) == 3
        assert operation['before'] == preparation['after'] == operation['after']
        assert operation['returned'] == 0 and operation.get('result') is None
        assert operation['error'] == 'injected archive call: ' + selector + '\n'
        prefix, events = unwind(healthy, selector)
        assert operation['events'] == events and len(events) == len(set(events))
        paths = [file['path'] for file in spec['files']]
        assert operation['writes'] == []
        assert operation['reads'] == [paths[int(e.split(':')[2])] for e in prefix if e.startswith('opened:source:')]
        assert operation['directories'] == [context['evidence']['path'] + ('/retained-sources' if e.split(':')[1] == 'archive' else '')
            for e in prefix if re.fullmatch(r'directory:(?:evidence|archive):[0-9]+:before', e)]
        kinds = FRESH.handles(operation, prefix, paths)
        assert kinds['writer'] == 0
        for kind, count in kinds.items():
            counts['interruption_' + kind + '_handles'] += count
            counts['preparation_' + kind + '_handles'] += sum(h['kind'] == kind for h in preparation['handles'])
        counts['cases'] += 1; counts['operations'] += 2
        counts['preparation_events'] += len(preparation['events'])
        counts['interruption_events'] += len(operation['events'])
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
    healthy, fresh_flow = domain(plan, baseline)
    report = json.loads((LOG / 'qualification.json').read_bytes())
    counts = verify(plan, report, healthy, fresh_flow)
    admission = [json.loads(line) for line in (LOG / 'admission.jsonl').read_text().splitlines()]
    assert admission == report['allocated']
    for row in admission:
        path = ROOT / row['path']
        assert not path.exists() and not path.is_symlink()
    assertions = len(plan['cases']) * 7 + 1
    tap = (LOG / 'qualify.tap').read_text()
    assert re.findall(r'^1\.\.([0-9]+)$', tap, re.M) == [str(assertions)]
    assert [int(x) for x in re.findall(r'^ok ([0-9]+) - ', tap, re.M)] == list(range(1, assertions + 1))
    assert not re.search(r'^(?:not ok|Bail out!)', tap, re.M)
    assert (LOG / 'qualify.exit').read_text().strip() == '0'
    def operation(r):
        return r['cases'][-1]['operation']
    def preparation(r):
        return r['cases'][-1]['preparation']
    def first_handle(r, phase, kind):
        return next(h for h in r['cases'][-1][phase]['handles'] if h['kind'] == kind)
    def archive_file(r):
        return next(n for n in operation(r)['after']['evidence'].values() if n['kind'] == 'file')
    def remove_other_hold(r):
        row = r['cases'][-1]
        path = row['context']['other_observation']['observation_reference']['source']['identity']['path']
        del row['operation']['after']['store'][path[len(row['context']['store']['path']) + 1:]]
    changes = [
        ('missing case', lambda r: r['cases'].pop()),
        ('duplicate case', lambda r: r['cases'].append(copy.deepcopy(r['cases'][0]))),
        ('wrong selected occurrence', lambda r: r['cases'][0].update(selector='limits:after')),
        ('unhit fault', lambda r: r['cases'][0].update(injected_hits=0)),
        ('hidden successful verification', lambda r: operation(r).update(returned=1)),
        ('replaced primary error', lambda r: operation(r).update(error='cleanup error\n')),
        ('unobserved preparation', lambda r: r['cases'][-1].pop('preparation')),
        ('failed preparation', lambda r: preparation(r).update(returned=0)),
        ('missing preparation occurrence', lambda r: preparation(r)['events'].pop()),
        ('missing preparation binding', lambda r: preparation(r)['result']['source_bindings'].pop()),
        ('unclosed preparation writer', lambda r: first_handle(r, 'preparation', 'writer').update(closed_at_return=0)),
        ('unclosed preparation directory', lambda r: first_handle(r, 'preparation', 'directory').update(actual_close_ok=0)),
        ('missing verification cleanup', lambda r: operation(r)['events'].pop()),
        ('duplicate verification event', lambda r: operation(r)['events'].append(operation(r)['events'][-1])),
        ('unclosed verification source', lambda r: first_handle(r, 'operation', 'source').update(closed_at_return=0)),
        ('unclosed verification directory', lambda r: first_handle(r, 'operation', 'directory').update(closed_after_call=0)),
        ('unclosed observer duplicate', lambda r: first_handle(r, 'operation', 'directory').update(observer_closed=0)),
        ('wrong descriptor identity', lambda r: first_handle(r, 'operation', 'source').update(inode=7)),
        ('lost source CLOEXEC', lambda r: first_handle(r, 'operation', 'source').update(cloexec_before_close=0)),
        ('changed archive bytes', lambda r: archive_file(r).update(bytes_hex='00')),
        ('changed archive inode', lambda r: archive_file(r).update(inode=7)),
        ('changed archive permissions', lambda r: archive_file(r).update(mode=0o600)),
        ('verification writes', lambda r: operation(r)['writes'].append('unexpected-write')),
        ('original target read', lambda r: operation(r)['reads'].append('original-target')),
        ('removed other observation hold', remove_other_hold),
        ('changed retained input', lambda r: r['cases'][0].update(inputs_unchanged=0)),
        ('changed shared source bytes', lambda r: r['cases'][0]['context']['acquired']['target_sources'][0].update(bytes='changed')),
        ('collapsed original source identity', lambda r: r['cases'][0]['context']['acquired']['target_sources'][0].update(
            identity=copy.deepcopy(r['cases'][0]['context']['acquired']['target_sources'][1]['identity']))),
        ('lost allocation', lambda r: r['allocated'].pop()),
        ('process attempt', lambda r: r.update(forbidden_process_attempts=1)),
    ]
    for name, change in changes:
        altered = copy.deepcopy(report); change(altered)
        assert TRACE.reject(lambda: verify(plan, altered, healthy, fresh_flow)), name
    domains = []
    for name in ('duplicate selector', 'unsafe ownership fault', 'omitted selector', 'omitted preparation boundary'):
        altered = copy.deepcopy(plan)
        if name == 'duplicate selector': altered['cases'].append(copy.deepcopy(altered['cases'][0]))
        elif name == 'unsafe ownership fault': altered['cases'][0]['selector'] = 'opened:source:0:0'
        elif name == 'omitted selector': altered['cases'].pop()
        else: altered['preparation_events'].pop()
        assert TRACE.reject(lambda: domain(altered, baseline)), name
        domains.append(name)
    output = dict(schema='fsmgen.inactive_archive_equal_existing_calls_audit.v1', success=True, **counts,
        tap_assertions=assertions, report_falsifiers=[name for name, _ in changes], domain_falsifiers=domains,
        all_allocations_absent=True, predecessor_inputs_unchanged=len(plan['inputs']),
        prospective_inputs_unchanged=len(pins), limits=plan['limits'])
    (LOG / 'audit.json').write_text(json.dumps(output, indent=2, sort_keys=True) + '\n')
    print(json.dumps(output, sort_keys=True))


if __name__ == '__main__':
    main()

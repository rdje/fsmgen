"""Independent archive trace domains, ownership lifetimes and physical oracle."""
from __future__ import annotations

import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import re
import subprocess

BASE=Path(__file__).resolve().parent
ROOT=BASE.parents[2]
LOG=ROOT/'.artifacts/logs/native-proxy-observation-archive-boundaries-20260911'
_spec=importlib.util.spec_from_file_location('boundary_archive_physical',BASE.parent/'native-proxy-observation-archive-20260911/audit.py')
PHYSICAL=importlib.util.module_from_spec(_spec);_spec.loader.exec_module(PHYSICAL)


def eligible(event):
    if event in ('operation:begin','operation:end') or event.startswith(('opened:','close:','close_sources:')):return False
    if re.fullmatch(r'source:[0-9]+:[0-9]+:before',event):return True
    if re.fullmatch(r'writer:[0-9]+:binmode',event):return True
    assert event.endswith((':before',':after'))
    assert event.split(':')[0] in {'limits','prior','mkdir','directory','directory_closure','members','names','write','seal','source_closure','receipt','recheck'}
    return True


def domain(plan):
    assert plan['profiles']==[dict(name='ordinary',wrapper='ordinary',files=4),dict(name='equal_reference',wrapper='equal_reference',files=3)]
    ids=[p['name']+':'+route for p in plan['profiles'] for route in ('fresh','existing')]
    assert set(plan['flows'])==set(ids)
    for profile in plan['profiles']:
        for route in ('fresh','existing'):
            flow=plan['flows'][profile['name']+':'+route]
            assert flow['route']==route and flow['files']==profile['files']
            names=[e['event'] for e in flow['events']]
            assert len(names)==len(set(names))
            assert [e['call_fault_eligible'] for e in flow['events']]==[eligible(n) for n in names]
            labels=[h['label'] for h in flow['handles']]
            assert len(labels)==len(set(labels))
    return ids


def lifetimes(flow,operation):
    events=operation['events'];handles=operation['handles']
    assert events==[e['event'] for e in flow['events']]
    assert len(events)==len(set(events))
    assert [h['label'] for h in handles]==[h['label'] for h in flow['handles']]
    assert operation['all_observed_handles_closed']==1
    by_label={h['label']:h for h in handles}; stack=[];opened=[];owners=set();rechecks={};source_calls=[]
    for event in events:
        if event=='operation:begin':assert not stack and not owners;continue
        if event=='operation:end':assert not stack and not owners;continue
        match=re.fullmatch(r'source:([0-9]+):([0-9]+):before',event)
        if match:
            source_calls.append(tuple(map(int,match.groups())));continue
        if event.startswith('opened:'):
            label=event[len('opened:'):];assert label not in opened
            assert label in by_label;opened.append(label);owners.add(label)
            row=by_label[label]
            assert row['actual_close_ok']==row['closed_after_call']==row['closed_at_return']==1
            assert row['actual_errno']==0
            if row['kind']=='directory':
                number=int(label.split(':')[-1]);assert stack[-1]==f'names:{number}'
                assert row['observer_closed']==1 and row['observer_descriptor']!=row['descriptor']
                assert row['cloexec_before_close'] is None
            elif row['kind']=='writer':
                assert stack[-1]==f"write:{row['file_index']}" and row['cloexec_before_close']==1
            else:
                assert row['kind']=='source' and row['cloexec_before_close']==1
                index,occurrence=map(int,label.split(':')[1:]);assert source_calls[-1]==(index,occurrence)
                assert row['file_index']==index
            continue
        if event.endswith(':binmode'):
            label=event[:-len(':binmode')];assert label in owners
            assert stack[-1]=='write:'+label.split(':')[1];continue
        stem,side=event.rsplit(':',1)
        if side=='before':
            if stem.startswith('close:'):
                label=stem[len('close:'):];assert label in owners
                row=by_label[label]
                if row['kind']=='directory':assert stack[-1]=='names:'+label.split(':')[-1]
                elif row['kind']=='writer':assert stack[-1]=='write:'+label.split(':')[1]
                else:
                    index,occurrence=map(int,label.split(':')[1:])
                    retained=1 if flow['route']=='fresh' else 0
                    expected_parent='close_sources' if occurrence==retained else 'source_closure'
                    if flow['route']=='fresh' and occurrence==0:expected_parent=f'write:{index}'
                    assert stack[-1]==expected_parent
            elif stem.startswith('recheck:'):
                label=stem[len('recheck:'):].rsplit(':',1)[0];assert label in owners
                rechecks[label]=rechecks.get(label,0)+1
            elif stem=='close_sources':
                retained=1 if flow['route']=='fresh' else 0
                assert owners=={f'source:{i}:{retained}' for i in range(flow['files'])}
            stack.append(stem)
        else:
            assert side=='after' and stack.pop()==stem
            if stem.startswith('close:'):owners.remove(stem[len('close:'):])
    assert opened==[h['label'] for h in handles] and not owners and not stack
    expected={}
    for index in range(flow['files']):
        retained=1 if flow['route']=='fresh' else 0
        expected[f'source:{index}:{retained}']=4
        expected[f'source:{index}:{retained+1}']=1
        if flow['route']=='fresh':expected[f'source:{index}:0']=1
    assert rechecks==expected
    assert len([h for h in handles if h['kind']=='directory'])==(flow['files']+3 if flow['route']=='fresh' else 3)
    assert len([h for h in handles if h['kind']=='writer'])==(flow['files'] if flow['route']=='fresh' else 0)
    assert len([h for h in handles if h['kind']=='source'])==flow['files']*(3 if flow['route']=='fresh' else 2)
    # Actual descriptor identities must match the independent final physical
    # census, not only producer role labels or the plan's handle counts.
    for row in handles:
        root=operation['after']['evidence'];relative=row['path'].split('/retained-sources',1)[1]
        key='retained-sources'+relative
        node=root[key]
        assert (row['device'],row['inode'])==(node['device'],node['inode'])


def verify(plan,report):
    ids=domain(plan)
    assert report['success'] is True and report['forbidden_process_attempts']==0
    assert [r['name'] for r in report['cases']]==ids
    roots=[];totals=dict(operations=0,events=0,handles=0,call_fault_selectors=0)
    for profile_index,profile in enumerate(plan['profiles']):
        pair=report['cases'][profile_index*2:profile_index*2+2]
        fresh,existing=pair
        assert fresh['context']==existing['context']
        context=fresh['context']
        for kind in ('store','workspace','other_workspace','evidence'):
            roots.append(dict(kind=kind,**context[kind]))
        assert fresh['operation']['before']==fresh['after_retirement']
        assert fresh['operation']['after']==existing['operation']['before']
        assert fresh['operation']['result']==existing['operation']['result']
        for row in pair:
            assert row['inputs_unchanged']==1
            prior=row['prior_retirement'];after=row['after_retirement']
            PHYSICAL.target_inputs(context,prior)
            assert after['workspace']=={}
            expected=copy.deepcopy(prior['store'])
            global_path=context['runtime']['reference']['global']['identity']['path']
            del expected[global_path[len(context['store']['path'])+1:]]
            assert after['store']==expected
            assert row['retirement']['retired_workspace']==context['workspace']['path']
            assert row['retirement']['released_reference']==global_path
            for kind in ('other_workspace','evidence'):assert after[kind]==prior[kind]
            operation=row['operation'];flow=plan['flows'][row['name']]
            PHYSICAL.operation_checks(context,operation,True,'')
            lifetimes(flow,operation)
            totals['operations']+=1;totals['events']+=len(operation['events']);totals['handles']+=len(operation['handles'])
            totals['call_fault_selectors']+=sum(e['call_fault_eligible'] for e in flow['events'])
    assert roots==report['allocated'] and len({r['path'] for r in roots})==len(roots)
    return dict(totals,roots=len(roots))


def reject(callback):
    try:callback()
    except (AssertionError,KeyError,ValueError,TypeError,IndexError):return True
    return False


def extraction():
    manifest=json.loads((BASE/'extraction.json').read_bytes())
    source=(ROOT/manifest['source_path']).read_bytes()
    assert source==subprocess.check_output(['git','show',manifest['source_revision']+':'+manifest['source_path']],cwd=ROOT)
    assert len(source)==manifest['source_bytes'] and hashlib.sha256(source).hexdigest()==manifest['source_sha256']
    module=(BASE/'ArchiveFixture.pm').read_bytes()
    names=[]
    for row in manifest['exact_helper_bodies']:
        names.append(row['name']);start=sum(len(line) for line in source.splitlines(keepends=True)[:row['source_start_line']-1])
        raw=source[start:start+row['bytes']]
        assert hashlib.sha256(raw).hexdigest()==row['sha256'] and module.count(raw)==1
        assert raw.startswith(('sub '+row['name']+' {').encode()) and raw.endswith(b'}\n')
    assert set(names)=={'clone','read_bytes','write_bytes','allocate','tree','footprint','cleanup_receipts','context'}
    assert sorted(re.findall(rb'^sub (\w+) ',module,re.M))==sorted(n.encode() for n in names+['initialize','save_result'])
    return len(names)


def main():
    plan=json.loads((BASE/'plan.json').read_bytes())
    for pin in plan['inputs']:
        raw=(ROOT/pin['path']).read_bytes()
        assert raw==subprocess.check_output(['git','show',plan['source_revision']+':'+pin['path']],cwd=ROOT)
        assert len(raw)==pin['size_bytes'] and hashlib.sha256(raw).hexdigest()==pin['sha256']
    pins=json.loads((LOG/'preflight-pins.json').read_bytes())
    for pin in pins:
        raw=(ROOT/pin['path']).read_bytes();assert len(raw)==pin['size_bytes'] and hashlib.sha256(raw).hexdigest()==pin['sha256']
    bodies=extraction()
    report=json.loads((LOG/'qualification.json').read_bytes());counts=verify(plan,report)
    admission=[json.loads(x) for x in (LOG/'admission.jsonl').read_text().splitlines()]
    assert admission==report['allocated']
    for row in admission:
        path=ROOT/row['path'];assert not path.exists() and not path.is_symlink()
    tap=(LOG/'qualify.tap').read_text();assertions=len(report['cases'])*5+len(plan['profiles'])+1
    assert re.findall(r'^1\.\.([0-9]+)$',tap,re.M)==[str(assertions)]
    assert [int(x) for x in re.findall(r'^ok ([0-9]+) - ',tap,re.M)]==list(range(1,assertions+1))
    assert not re.search(r'^(?:not ok|Bail out!)',tap,re.M) and (LOG/'qualify.exit').read_text().strip()=='0'
    def first_handle(r,kind):return next(h for h in r['cases'][0]['operation']['handles'] if h['kind']==kind)
    changes=[
        ('missing operation',lambda r:r['cases'].pop()),
        ('duplicate operation',lambda r:r['cases'].append(copy.deepcopy(r['cases'][0]))),
        ('missing occurrence',lambda r:r['cases'][0]['operation']['events'].pop(1)),
        ('duplicate occurrence',lambda r:r['cases'][0]['operation']['events'].append(r['cases'][0]['operation']['events'][1])),
        ('reordered occurrences',lambda r:r['cases'][0]['operation']['events'].reverse()),
        ('lost source handle',lambda r:r['cases'][0]['operation']['handles'].pop()),
        ('unclosed source',lambda r:first_handle(r,'source').update(closed_at_return=0)),
        ('unclosed writer',lambda r:first_handle(r,'writer').update(actual_close_ok=0)),
        ('unclosed directory',lambda r:first_handle(r,'directory').update(closed_after_call=0)),
        ('unclosed observer duplicate',lambda r:first_handle(r,'directory').update(observer_closed=0)),
        ('foreign handle inode',lambda r:first_handle(r,'source').update(inode=7)),
        ('unsealed writer',lambda r:first_handle(r,'writer').update(cloexec_before_close=0)),
        ('lost retained identity',lambda r:r['cases'][0]['operation']['result']['source_bindings'][0]['source'].update(inode=7)),
        ('hidden target read',lambda r:r['cases'][0]['operation']['reads'].append('original-target')),
        ('changed input',lambda r:r['cases'][0].update(inputs_unchanged=0)),
        ('lost allocation',lambda r:r['allocated'].pop()),
        ('process attempt',lambda r:r.update(forbidden_process_attempts=1)),
    ]
    for name,change in changes:
        altered=copy.deepcopy(report);change(altered);assert reject(lambda:verify(plan,altered)),name
    domains=[]
    for label in ('duplicate event','duplicate handle','unsafe source-return fault','unsafe close fault'):
        altered=copy.deepcopy(plan);flow=altered['flows']['ordinary:fresh']
        if label=='duplicate event':flow['events'].append(copy.deepcopy(flow['events'][0]))
        elif label=='duplicate handle':flow['handles'].append(copy.deepcopy(flow['handles'][0]))
        else:
            prefix='opened:source:' if label=='unsafe source-return fault' else 'close:'
            next(e for e in flow['events'] if e['event'].startswith(prefix))['call_fault_eligible']=True
        assert reject(lambda:domain(altered)),label;domains.append(label)
    output=dict(schema='fsmgen.inactive_archive_boundary_audit.v1',success=True,**counts,
        tap_assertions=assertions,exact_fixture_helper_bodies=bodies,predecessor_inputs_unchanged=len(plan['inputs']),
        prospective_inputs_unchanged=len(pins),report_falsifiers=[name for name,_ in changes],domain_falsifiers=domains,
        all_allocations_absent=True,limits=plan['limits'])
    (LOG/'audit.json').write_text(json.dumps(output,indent=2,sort_keys=True)+'\n');print(json.dumps(output,sort_keys=True))


if __name__=='__main__':main()

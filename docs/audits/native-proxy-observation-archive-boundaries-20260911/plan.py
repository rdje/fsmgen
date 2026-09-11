"""Prospective unique helper/ownership boundaries for inactive archival."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import subprocess

BASE=Path(__file__).resolve().parent
ROOT=BASE.parents[2]
REVISION='ff71d28f1e47c6bf34db96029862f6be5fe96051'


def flow(route,files):
    events=[];counters={};handles=[]
    def event(name,eligible=False):
        assert name not in {e['event'] for e in events},name
        events.append(dict(event=name,call_fault_eligible=eligible))
    def ordinal(name):
        result=counters.get(name,0);counters[name]=result+1;return result
    def pair(name,body=lambda:None,eligible=True):
        event(name+':before',eligible);body();event(name+':after',eligible)
    def directory(role):pair(f'directory:{role}:{ordinal("directory:"+role)}')
    def prior():pair(f'prior:{ordinal("prior")}',lambda:directory('evidence'))
    def directory_closure():
        pair(f'directory_closure:{ordinal("directory_closure")}',lambda:(directory('evidence'),directory('archive')))
    def close(label):pair('close:'+label,eligible=False)
    def members():
        def names():
            label=f'directory_handle:{ordinal("directory_handle")}'
            handles.append(dict(label=label,kind='directory'))
            event('opened:'+label)
            close(label)
        pair(f'members:{ordinal("members")}',lambda:pair(f'names:{ordinal("names")}',names))
    def source(index):
        label=f'source:{index}:{ordinal("source:"+str(index))}'
        # A source-return wrapper owns the returned handle before its caller
        # can push it into cleanup. Observe that transfer without injecting an
        # adapter exception there; the next guarded check belongs to the caller.
        event(label+':before',True)
        handles.append(dict(label=label,kind='source',file_index=index))
        event('opened:'+label)
        return label
    def recheck(label):pair(f'recheck:{label}:{ordinal("recheck:"+label)}')
    def write(index):
        def body():
            label=f'writer:{index}';handles.append(dict(label=label,kind='writer',file_index=index))
            event('opened:'+label)
            event(label+':binmode',True)
            reader=source(index);recheck(reader)
            pair(f'seal:{index}')
            close(reader);close(label)
        pair(f'write:{index}',body)

    event('operation:begin')
    pair('limits');prior()
    if route=='fresh':prior();pair('mkdir')
    else:assert route=='existing'
    directory('archive');directory_closure();members()
    retained=[]
    for index in range(files):
        directory_closure()
        if route=='fresh':members();write(index)
        label=source(index);retained.append(label);recheck(label)
    members();directory_closure()
    def closure():
        for index,label in enumerate(retained):
            recheck(label);fresh=source(index);recheck(fresh);close(fresh)
        for label in retained:recheck(label)
    pair('source_closure',closure);pair('receipt');members();directory_closure()
    for label in retained:recheck(label)
    # Cleanup's aggregate helper returns an error value, not an exception.
    # Its and the actual close observations are reserved for modeled close
    # reports and omitted-close controls in the separately owned close matrix.
    pair('close_sources',lambda:[close(label) for label in retained],eligible=False)
    event('operation:end')
    assert len({h['label'] for h in handles})==len(handles)
    return dict(events=events,handles=handles,files=files,route=route)


def build():
    profiles=[dict(name='ordinary',wrapper='ordinary',files=4),
              dict(name='equal_reference',wrapper='equal_reference',files=3)]
    flows={p['name']+':'+route:flow(route,p['files']) for p in profiles for route in ('fresh','existing')}
    previous=BASE.parent/'native-proxy-observation-archive-20260911/plan.json'
    paths={row['path'] for row in json.loads(previous.read_bytes())['inputs']}
    paths.update([str(previous.relative_to(ROOT)),
        'docs/audits/native-proxy-observation-archive-records-20260911/plan.json',
        'docs/audits/native-proxy-observation-archive-20260911/ObservationArchive.pm',
        'docs/audits/native-proxy-observation-archive-20260911/qualify.t',
        'docs/audits/native-proxy-observation-archive-20260911/audit.py'])
    inputs=[]
    for path in sorted(paths):
        raw=(ROOT/path).read_bytes();assert raw==subprocess.check_output(['git','show',REVISION+':'+path],cwd=ROOT)
        inputs.append(dict(path=path,size_bytes=len(raw),sha256=hashlib.sha256(raw).hexdigest()))
    return dict(schema='fsmgen.inactive_archive_boundary_plan.v1',source_revision=REVISION,
        owner='HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.7.3.12.4.1.3.4.2.3.1',
        profiles=profiles,flows=flows,inputs=inputs,
        execution='Each profile allocates one isolated inert context, retires its runtime/private workspace, and observes fresh archival followed by existing complete verification. Every operation is observed; no preparation archive call is hidden.',
        limits='Prospective selected helper-call and actual returned-handle observations, not every syscall or failure. Source ownership-transfer observations and aggregate/actual close events are not throwing call-fault selectors. Partial writes, modeled close reports, real omitted-close counterimplementations, bounds/layout and applicability closure remain owned children. No original fixture rerun, compiler, native work, observation release or activation.')


if __name__=='__main__':
    plan=build();(BASE/'plan.json').write_text(json.dumps(plan,indent=2,sort_keys=True)+'\n')
    print(json.dumps({name:dict(events=len(value['events']),handles=len(value['handles']),call_fault_selectors=sum(e['call_fault_eligible'] for e in value['events'])) for name,value in plan['flows'].items()},sort_keys=True))

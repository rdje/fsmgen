"""Independent directory contents, errno transitions and retained-handle oracle."""
from __future__ import annotations

import copy
import errno
import hashlib
import json
import os
from pathlib import Path
import re
import sys

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT/'.artifacts/logs/native-proxy-namespace-reader-20260911'
PLAN_SHA = '883d5f4744bc1a8ba5b41d8a7c0ee46748a5b2c1a93334b74143d1f5549fc842'
PAYLOADS = {'a':b'alpha\n','b':b'beta\n'}


def equal(a,b) -> None:
    assert json.dumps(a,sort_keys=True,separators=(',',':'))==json.dumps(b,sort_keys=True,separators=(',',':'))


def integer(value, minimum=0) -> None:
    assert type(value) is int and value >= minimum


def native(value: dict) -> None:
    integer(value['device']);integer(value['inode'],1)
    assert value['device']==ROOT.stat().st_dev


def footprint(row: dict, spec: dict) -> None:
    before=row['before'];equal(before,row['after'])
    expected={''}|(set(PAYLOADS) if spec['members'] else set())
    assert set(before)==expected
    for name,node in before.items():
        native(node)
        integer(node['mode']);integer(node['uid'])
        assert node['uid']==os.getuid()
        if name=='':
            equal(node,dict(kind='directory',mode=0o700,uid=os.getuid(),
                device=row['allocation']['device'],inode=row['allocation']['inode']))
        else:
            raw=PAYLOADS[name]
            equal(node,dict(kind='file',mode=0o400,uid=os.getuid(),device=node['device'],inode=node['inode'],links=1,
                bytes=raw.decode('ascii'),size_bytes=len(raw),sha256=hashlib.sha256(raw).hexdigest()))


def check_row(row: dict, spec: dict, phase: str, mutant: str | None = None, strict=False) -> None:
    name=spec['name']
    assert row['fault']==name
    footprint(row,spec)
    assert type(row['allocation_absent']) is int and row['allocation_absent']==1
    calls=row['calls'];assert calls and calls[0]['kind']=='open'
    opened=name!='missing_directory'
    assert type(calls[0]['returned']) is int and calls[0]['returned']==int(opened)
    integer(calls[0]['errno'])
    if not opened:assert calls[0]['errno']==errno.ENOENT
    read_calls=[c for c in calls if c['kind']=='read']
    close_calls=[c for c in calls if c['kind']=='close']
    assert len(calls)==1+len(read_calls)+len(close_calls)
    assert calls==[calls[0],*read_calls,*close_calls]
    actual=[c['entry'] for c in read_calls if c['entry'] not in (None,'.','..')]
    equal(actual,row['actual_members'])
    assert len(actual)==len(set(actual)) and set(actual)<=set(PAYLOADS)
    for entry in read_calls:
        assert set(entry)=={'kind','entry','incoming_errno','errno','injected'}
        integer(entry['incoming_errno']);integer(entry['errno']);integer(entry['injected'])
        assert entry['injected'] in (0,1)
        assert entry['entry'] is None or entry['entry'] in ('.','..','a','b')
        if phase=='qualification':assert entry['incoming_errno']==0
    real=[c for c in read_calls if not c['injected']]
    assert sum(c['entry']=='.' for c in real)<=1 and sum(c['entry']=='..' for c in real)<=1
    injected=[c for c in read_calls if c['injected']]
    read_count={'read_entry':0,'read_after_one':1,'read_after_all':2,'read_and_close':1}.get(name)
    if read_count is not None:
        assert len(injected)==1 and read_calls[-1]==injected[0]
        assert injected[0]['entry'] is None and injected[0]['errno']==errno.EIO
        assert len(actual)==read_count and all(c['entry'] is not None for c in real)
    else:
        assert injected==[]
        if opened and not name.startswith('capacity'):
            assert read_calls[-1]['entry'] is None and read_calls[-1]['errno']==0
            assert sum(c['entry'] is None for c in read_calls)==1
        elif name.startswith('capacity'):
            assert all(c['entry'] is not None for c in read_calls)
            assert len(actual)==spec['limit']+1==2
        else:assert read_calls==[]
    assert type(row['read_error_injected']) is int and row['read_error_injected']==int(read_count is not None)
    baseline_capacity=phase=='baseline' and name=='capacity'
    expected_closes=int(opened and not baseline_capacity)
    assert len(close_calls)==expected_closes
    for call in close_calls:
        assert set(call)=={'kind','actual_close','returned','errno'}
        for field in ('actual_close','returned','errno'):integer(call[field])
        omit=mutant=='omit_directory_close'
        reported=name in ('close_error','capacity_and_close','read_and_close')
        assert call['actual_close']==int(not omit)
        assert call['returned']==int(omit or not reported)
        if reported:assert call['errno']==errno.EIO
    handles=row['handles'];assert len(handles)==int(opened)
    expected_open=baseline_capacity or mutant=='omit_directory_close'
    for handle in handles:
        integer(handle['descriptor']);integer(handle['observer_descriptor'])
        assert handle['observer_descriptor']!=handle['descriptor']
        assert handle['path']==row['allocation']['path']
        equal(handle['identity'],{key:row['before'][''][key] for key in ('device','inode','mode','uid')})
        for field in ('observer_close_ok','observer_closed','closed_after_recovery'):
            integer(handle[field]);assert handle[field]==1
        integer(handle['closed_before_recovery'])
        assert handle['closed_before_recovery']==int(not expected_open)
        if expected_open:
            assert not strict
            integer(handle['recovery_close_ok']);assert handle['recovery_close_ok']==1
        else:assert handle['recovery_close_ok'] is None
    baseline_read=phase=='baseline' and name in ('read_entry','read_after_one')
    accepts_partial=baseline_read or mutant=='omit_read_error_check'
    returns=spec['returns'] or accepts_partial
    integer(row['returned']);assert row['returned']==int(returns)
    if returns:
        assert row['error']==''
        equal(row['names'],sorted(actual))
        if accepts_partial:
            assert not strict and len(row['names'])<spec['members']
        else:equal(row['names'],sorted(PAYLOADS) if spec['members'] else [])
    else:
        assert 'names' not in row
        diagnostic=spec['diagnostic']
        expected=diagnostic+'\n' if diagnostic=='namespace capacity exceeded' else diagnostic+': '+os.strerror(errno.ENOENT if name=='missing_directory' else errno.EIO)+'\n'
        assert row['error']==expected


def validate(result: dict, plan: dict, phase: str) -> None:
    assert result['schema']=='fsmgen.inactive_namespace_reader_qualification.v1' and result['phase']==phase
    assert result['completed'] is True and 'first_failure' not in result
    assert result['success'] is (phase=='qualification') and result['qualified'] is (phase=='qualification')
    assert result['perl_version']=='v5.34.1' and result['directory_descriptor_support']=='define'
    integer(result['forbidden_process_attempts']);assert result['forbidden_process_attempts']==0
    specs={r['name']:r for r in plan['cases']}
    selected=plan['baseline'] if phase=='baseline' else list(specs)
    assert [r['name'] for r in result['cases']]==selected
    expected_mutants=[] if phase=='baseline' else plan['mutants']
    assert [r['name'] for r in result['mutants']]==[r['name'] for r in expected_mutants]
    ledger=[json.loads(line) for line in (LOG/(phase+'-admission.jsonl')).read_text().splitlines()]
    equal(ledger,result['allocated'])
    assert len(ledger)==len(selected)+len(expected_mutants)
    assert len({r['path'] for r in ledger})==len(ledger)
    for allocation in ledger:
        assert set(allocation)=={'path','device','inode'};native(allocation)
        assert re.fullmatch(r'\.artifacts/tmp/native-proxy-image-custody/cases/fsmgen-[A-Za-z0-9_]+',allocation['path'])
        assert not (ROOT/allocation['path']).exists() and not (ROOT/allocation['path']).is_symlink()
    equal(ledger,[r['allocation'] for r in result['cases']+result['mutants']])
    for row in result['cases']:check_row(row,specs[row['name']],phase)
    for row,mutant in zip(result['mutants'],expected_mutants):
        spec=specs[mutant['case']];check_row(row,spec,phase,mutant['name'])
        try:check_row(row,spec,phase,mutant['name'],strict=True)
        except AssertionError:pass
        else:raise AssertionError('strict oracle accepted omitted namespace guard')


def main() -> None:
    assert len(sys.argv)==2 and sys.argv[1] in ('--baseline','--qualification')
    phase=sys.argv[1][2:]
    raw=(BASE/'plan.json').read_bytes();assert hashlib.sha256(raw).hexdigest()==PLAN_SHA
    plan=json.loads(raw);result=json.loads((LOG/(phase+'.json')).read_bytes());validate(result,plan,phase)
    tap=(LOG/(phase+'.tap')).read_text()
    assert not re.search(r'^(?:not ok|Bail out!)',tap,re.M)
    assertions=2*(len(result['cases'])+len(result['mutants']))+1
    assert re.findall(r'^1\.\.(\d+)$',tap,re.M)==[str(assertions)]
    assert [int(n) for n in re.findall(r'^ok (\d+) - ',tap,re.M)]==list(range(1,assertions+1))
    falsifiers=[]
    for name,change in [
        ('phase relabeled as passing',lambda x:x.update(success=not x['success'])),
        ('lost allocation',lambda x:x['allocated'].pop()),
        ('lost read calls',lambda x:x['cases'][0].update(calls=[x['cases'][0]['calls'][0]])),
        ('invented directory identity',lambda x:x['cases'][0]['handles'][0]['identity'].update(inode=1)),
        ('lost observer close',lambda x:x['cases'][0]['handles'][0].update(observer_closed=0)),
        ('changed file bytes',lambda x:x['cases'][0]['after']['a'].update(bytes='changed')),
        ('forbidden process',lambda x:x.update(forbidden_process_attempts=1)),
    ]:
        changed=copy.deepcopy(result);change(changed)
        try:validate(changed,plan,phase)
        except (AssertionError,KeyError):falsifiers.append(name)
        else:raise AssertionError('namespace oracle missed falsifier: '+name)
    report=dict(schema='fsmgen.inactive_namespace_reader_audit.v1',phase=phase,qualified=phase=='qualification',
        completed=True,assertions=assertions,cases=len(result['cases']),allocations=len(result['allocated']),
        mutants=[r['name'] for r in result['mutants']],falsifiers=falsifiers,limits=plan['limits'])
    (LOG/(phase+'-audit.json')).write_text(json.dumps(report,sort_keys=True,indent=2)+'\n')
    print(json.dumps(report,sort_keys=True))


if __name__=='__main__':main()

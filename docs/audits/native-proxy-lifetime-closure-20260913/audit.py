"""Authenticate and join selected lifetime closure without replaying execution."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import subprocess
from join_evidence import verify as join, falsify

BASE=Path(__file__).resolve().parent
ROOT=BASE.parents[2]


def read(path):return json.loads(path.read_bytes())
def pin(path,body=None):
    if body is None:body=path.read_bytes()
    return dict(path=path.relative_to(ROOT).as_posix(),size_bytes=len(body),sha256=hashlib.sha256(body).hexdigest())
def git(*args):return subprocess.check_output(['git',*args],cwd=ROOT)
def section(text,owner):
    marker='- ID: `'+owner+'`\n';assert text.count(marker)==1
    return text.split(marker)[1].split('- ID: `',1)[0]


def source_graph(plan):
    paths=set();phase_names=set()
    for phase in plan['phases']:
        assert phase['name'] not in phase_names;phase_names.add(phase['name'])
        members=git('ls-tree','-r','--name-only',plan['source_revision'],'--',phase['directory']).decode().splitlines()
        assert members==phase['members'] and phase['report'] in members;paths.update(members)
        for name in ('plan.json','harness-plan.json'):
            relative=phase['directory']+'/'+name
            if relative in members:
                paths.update(row['path'] for row in json.loads(git('show',plan['source_revision']+':'+relative)).get('inputs',[]))
    assert phase_names=={'contracts','model','complete_admission','complete_actual','matrix','harness','final_admission','controls_actual'}
    assert [row['path'] for row in plan['inputs']]==sorted(paths)
    for row in plan['inputs']:
        path=ROOT/row['path'];metadata=path.lstat()
        assert stat.S_ISREG(metadata.st_mode) and metadata.st_dev==ROOT.stat().st_dev
        body=path.read_bytes();assert pin(path,body)==row
        assert git('show',plan['source_revision']+':'+row['path'])==body
    task=git('show',plan['source_revision']+':'+plan['task_source']['path'])
    assert pin(ROOT/plan['task_source']['path'],task)==plan['task_source']
    text=task.decode()
    for suffix in ('.1','.2','.3','.4'):assert 'Status: `done`' in section(text,plan['parent']+suffix)
    for suffix in ('.1','.2','.3','.4','.5'):assert 'Status: `done`' in section(text,plan['custody_parent']+suffix)
    assert 'Status: `proposed`' in section(text,plan['owner'])
    assert 'Status: `proposed`' in section(text,plan['next_owner'])
    assert 'Status: `proposed`' in section(text,plan['native_integration_owner'])
    return paths


def raw_body(row):
    key='bytes_hex' if 'bytes_hex' in row else 'raw_hex'
    body=bytes.fromhex(row[key])
    assert len(body)==row['size_bytes'] and hashlib.sha256(body).hexdigest()==row['sha256']
    return body


def retained_epochs(plan):
    epochs={};exits={}
    def visit(value,artifact,pointer):
        if isinstance(value,list):
            for index,item in enumerate(value):visit(item,artifact,pointer+'/'+str(index))
        elif isinstance(value,dict):
            if {'path','size_bytes','sha256'}<=value.keys() and ('bytes_hex' in value or 'raw_hex' in value):
                body=raw_body(value);key=(value['path'],value['sha256'])
                entry=epochs.setdefault(key,dict(path=value['path'],sha256=value['sha256'],size_bytes=len(body),locations=[]))
                entry['locations'].append(dict(artifact=artifact,pointer=pointer))
                if value['path'].endswith('.exit') and re.fullmatch(rb'-?\d+\s*',body):exits[key]=int(body)
            for key,item in value.items():visit(item,artifact,pointer+'/'+str(key).replace('~','~0').replace('/','~1'))
    for row in plan['inputs']:
        if row['path'].endswith('.json'):visit(read(ROOT/row['path']),row['path'],'')
    ordered=[dict(value,exit_code=exits.get(key)) for key,value in sorted(epochs.items())]
    assert any(code!=0 for code in exits.values()),'first nonzero source/gate outcomes were lost'
    return dict(embedded_raw_epochs=ordered,distinct_stage_exit_epochs=len(exits),
        retained_nonzero_exit_epochs=sum(code!=0 for code in exits.values()))


def absent(relative):
    path=ROOT
    for part in relative.split('/'):
        assert part not in ('','.','..');path/=part
        try:metadata=path.lstat()
        except FileNotFoundError:return True
        assert stat.S_ISDIR(metadata.st_mode) and metadata.st_dev==ROOT.stat().st_dev and metadata.st_uid==os.getuid()
    return False


def verify():
    plan=read(BASE/'plan.json')
    for row in read(BASE/'closure-pins.json'):assert pin(ROOT/row['path'])==row
    assert pin(ROOT/plan['author']['path'])==plan['author']
    paths=source_graph(plan);phases={row['name']:row for row in plan['phases']}
    reports={name:read(ROOT/phase['report']) for name,phase in phases.items()}
    domain=read(ROOT/phases['contracts']['directory']/'corrected-contracts.json')
    prepared=read(ROOT/phases['model']['directory']/'prepared.json')
    value=dict(contract=domain,model=reports['model'],model_schedules=prepared['schedules'],
        complete_selection=read(ROOT/phases['complete_admission']['directory']/'selection.json'),
        control_selection=read(ROOT/phases['matrix']['directory']/'selection.json'),
        complete_report=reports['complete_actual'],control_report=reports['controls_actual'])
    joined=join(value);controls=falsify(value)
    assert all(absent(path) for path in joined['fixture_roots'])
    checks=read(BASE/'checks.json');outputs=read(BASE/'verification-outputs.json')
    raw={row['path'].rsplit('/',1)[1]:raw_body(row) for row in outputs}
    assert len(raw)==len(outputs)==3*(len(checks)+1)
    for name in ['plan']+[check['name'] for check in checks]:assert raw[name+'.exit']==b'0\n'
    for name in ('contracts','model'):assert json.loads(raw[name+'.stdout'])==reports[name]
    assert b'actual_fixture_execution=0' in raw['complete_admission.stdout']
    assert raw['complete_actual.stdout']==b'actual inert lifetimes: OK; cases=8 stages=152 handles=19820 roots_absent=32 native_payload_execution=0\n'
    assert json.loads(raw['matrix.stdout'])['actual_controls_executed']==0
    assert json.loads(raw['controls_actual.stdout'])==dict(success=True,cases=14,records=351,countermodels=11,native_process_authentication=False)
    admissions=read(BASE/'admission-review.json')
    assert admissions['actual_fixture_operations']==admissions['actual_permits_written']==0
    assert admissions['prospective_report_states_preserved_as_original_epochs']
    expected=['Native process authentication','Real compiler and returned-stage receipt transport','Late-launch prevention',
        'Live canonical-store/public integration','Historical startup and parent qualification; full CI/push']
    assert plan['missing_native_legs']==expected
    epochs=retained_epochs(plan)
    return dict(schema='fsmgen.inactive_combined_lifetime_closure.v1',owner=plan['owner'],source_revision=plan['source_revision'],
        source_inputs=len(paths),source_bytes=sum(row['size_bytes'] for row in plan['inputs']),
        phase_reports=[pin(ROOT/phase['report']) for phase in plan['phases']],admission_components=pin(BASE/'admission-review.json'),
        applicability=joined,rejected_join_countermodels=controls,first_epochs=epochs,
        raw_verification_outputs=outputs,closure_criteria_satisfied=True,
        no_original_producer_or_fixture_replayed=True,new_fixture_operations=0,
        next_owner=plan['next_owner'],native_integration_owner=plan['native_integration_owner'],
        remaining_prerequisites=expected,actual_process_coordination_pending=True,
        original_clock_domains_kept_separate=True,native_process_authentication=False,live_store_authorized=False)


def main():
    parser=argparse.ArgumentParser();group=parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--retain',action='store_true');group.add_argument('--verify-saved',action='store_true');args=parser.parse_args()
    result=verify()
    if args.retain:
        with (BASE/'review.json').open('x') as stream:json.dump(result,stream,sort_keys=True,indent=2);stream.write('\n')
    else:assert read(BASE/'review.json')==result
    print(json.dumps(dict(success=True,source_inputs=result['source_inputs'],modeled_orders=result['applicability']['modeled_serial_orders'],
        complete_file_cases=result['applicability']['actual_complete_cases'],control_file_cases=result['applicability']['actual_control_cases'],
        join_countermodels=len(result['rejected_join_countermodels']),new_fixture_operations=0),sort_keys=True))


if __name__=='__main__':main()

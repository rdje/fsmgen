"""Read-only review of prospective controls; never run an earlier producer main."""
from __future__ import annotations
import argparse
import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import re
import subprocess
import sys

sys.dont_write_bytecode = True
BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs' / BASE.name
A = ROOT / 'docs/audits/native-proxy-lifetime-files-admission-20260913'
spec = importlib.util.spec_from_file_location('control_matrix_original_support', A/'support.py')
SUPPORT = importlib.util.module_from_spec(spec); spec.loader.exec_module(SUPPORT)
MODEL = SUPPORT.OLD_MODEL


def raw(path): return (ROOT/path).read_bytes() if isinstance(path,str) else path.read_bytes()
def document(path): return json.loads(raw(path))
def sha(body): return hashlib.sha256(body).hexdigest()
def pin(path):
    path = Path(path)
    if path.is_absolute(): path = path.relative_to(ROOT)
    body = raw(str(path)); return dict(path=path.as_posix(),size_bytes=len(body),sha256=sha(body))
def write(path,value):
    with path.open('xb') as stream:
        stream.write(json.dumps(value,sort_keys=True,indent=2,ensure_ascii=True).encode()+b'\n')


def reject(action):
    try: action()
    except (AssertionError, KeyError, ValueError, TypeError): return
    raise AssertionError('known-bad control was accepted')


def layout():
    original = document(BASE/'task-layout.json')
    body = subprocess.check_output(['git','show',original['source_revision']+':'+original['source_task']],cwd=ROOT)
    assert sha(body)==original['source_sha256']; text=body.decode()
    for descriptor in (original,document(BASE/'admission-layout.json')):
        assert sha(text.encode())==descriptor['source_sha256']
        for edit in sorted(descriptor['source_edits'],key=lambda row:row['start'],reverse=True):
            text=text[:edit['start']]+edit['replacement']+text[edit['end']:]
        assert sha(text.encode())==descriptor['expanded_sha256']
        expanded=text
        for offset in sorted(descriptor['removed_separator_offsets'],reverse=True):
            assert text[offset:offset+8]=='\n\n- ID: '
            text=text[:offset]+text[offset+1:]
        assert sha(text.encode())==descriptor['normalized_sha256']
        assert [line for line in text.splitlines() if line]==[line for line in expanded.splitlines() if line]
        assert text.count('\n')==descriptor['live_lines']==6366
        assert descriptor['nonempty_normalization_loss']==0 and descriptor['ceilings_changed'] is False
    return dict(live_lines=6366,nonempty_normalization_loss=0,ceilings_changed=False)


def source_contracts(rows):
    assert len(rows)==14
    by_name={}
    for row in rows:
        text=raw(row['path']).decode(); lines=text.splitlines(keepends=True)
        start=row['first_line']-1; assert lines[start].startswith('sub '+row['name']+' ')
        end=start+1
        while end<len(lines) and not lines[end].startswith('sub ') and lines[end]!='1;\n': end+=1
        body=''.join(lines[start:end])
        if end<len(lines) and lines[end]=='1;\n': body=body[:-1]
        assert body==row['body'] and sha(body.encode())==row['sha256']
        by_name[(row['role'],row['name'])]=body
    def ordered(role,name,*parts):
        body=by_name[(role,name)]; position=0
        for part in parts:
            position=body.index(part,position)+len(part)
    ordered('release','_prepare','validate_archive_receipt','validate_work_settlement','_source(')
    ordered('release','_unlink_exact','unlink_attempted} = 1','unlink(','unlink_completed} = 1')
    ordered('release','release_observation_reference','my $error = $@','_close_owned','error => $success ?')
    ordered('retirement','_retire_locked','_remove(','_absent(')
    ordered('retirement','_release_locked','_absent(','_unlink_global(','_absent(')
    ordered('coordination','_transaction','_retire_locked(','_release_locked(')
    ordered('coordination','_transaction','my $error = $@','close($handle)','die $error unless $ok')
    assert 'cleanup_receipts_settled' in by_name[('retirement','_request')]
    assert 'selected work is not sealed' in by_name[('work','_sealed')]
    assert 'selected work cleanup is incomplete' in by_name[('work','_cleanup_settled')]
    assert 'image_key} eq $key' in by_name[('maintenance','_referenced')]
    assert 'selected image is retained by an unresolved reference' in by_name[('maintenance','_admit_locked')]
    assert 'observation runtime reference is absent' in by_name[('reuse','_admit_locked')]
    census=raw('docs/audits/native-proxy-runtime-census-20260910/ReferenceCensus.pm').decode()
    assert 'expected explicit reference schema' in census and 'unknown reference schema' in census


def witnesses(rows):
    assert [row['role'] for row in rows]==['private_root','runtime_global','observation_hold']
    result=[]
    for row in rows:
        assert pin(row['record']['path'])==row['record'] and row['actual_interruption_observed'] is False
        record=document(row['record']['path']); assert record['kind']=='stage'
        stage=record['value']; assert (stage['case'],stage['name'])==(row['case'],row['stage'])
        trace=stage['operation']; assert trace['returned']==1 and trace['error_hex']=='' and trace['recovery']==[]
        assert all(h['closed_at_return']==1 for h in trace['handles'])
        calls=trace['calls']; assert calls[row['ordinal']]==row['call']
        call=row['call']; assert call['returned']==1
        selected_path=call['path'] if call['operation']=='rmdir' else call['paths'][0]
        matches=[i for i,c in enumerate(calls) if c['operation']==call['operation'] and
                 (c.get('path')==selected_path or c.get('paths')==[selected_path]) and c['returned']==1]
        assert matches==[row['ordinal']]
        before=stage['before']['result']['nodes']; after=stage['after']['result']['nodes']
        removed=[]
        for c in calls[:row['ordinal']+1]:
            if c['operation']=='unlink':
                assert c['returned']==len(c['paths']); removed.extend(c['paths'])
            if c['operation']=='rmdir':
                assert c['returned']==1; removed.append(c['path'])
        assert removed==row['successful_prefix_removals'] and len(set(removed))==len(removed)
        assert set(removed)<=set(before)-set(after)
        acquired=stage['input_before']['acquired']
        if row['role']=='observation_hold':
            assert selected_path==acquired['observation_reference']['source']['identity']['path']
            assert removed==[selected_path]
        else:
            root=acquired['reference']['record']['workspace']
            private={p for p in before if p==root or p.startswith(root+'/')}
            global_path=acquired['reference']['global']['identity']['path']
            assert set(removed)==private|({global_path} if row['role']=='runtime_global' else set())
            assert selected_path==(root if row['role']=='private_root' else global_path)
        result.append(dict(role=row['role'],successful_prefix_removals=len(removed),ordinal=row['ordinal']))
    return result


def apply_changes(seed,state,changes):
    roots=dict(seed=seed,state=state)
    for change in changes:
        path=change['path']; target=roots
        for key in path[:-1]: target=target[key]
        if change['op']=='set': target[path[-1]]=copy.deepcopy(change['value'])
        elif change['op']=='delete': del target[path[-1]]
        elif change['op']=='increment': target[path[-1]]+=1
        else: raise AssertionError('unknown original mutation')


def project(state,target):
    names=sorted('unknown' if name=='unclassified' else name for name in state['references'])
    return dict(references=names,workspaces=sorted(state['workspaces']),image_present=target in state['images'])


def matrix(selection):
    expected_names={'runtime_pins','observation_a_pins','observation_b_pins','other_runtime_pins',
        'release_before_archive','repeated_release','unreaped_runtime','unsettled_work','unsealed_work',
        'reuse_after_retirement','unknown_reference','after_private_rmdir','after_global_unlink','after_last_observation_unlink'}
    assert {row['name'] for row in selection['cases']}==expected_names and len(selection['cases'])==len(expected_names)
    assert selection['execution_admitted'] is False and selection['runtime_qualification'] is False
    assert selection['bounds']==dict(case_wall_seconds=30,cases=14,cleanup_wall_seconds=10,file_bytes=65536,
        fixture_roots=56,record_bytes=4194304,total_record_bytes=134217728,total_wall_seconds=600,
        tree_bytes=4194304,tree_depth=8,tree_nodes=128)
    assert selection['trace_limits']==dict(calls=32768,handles=2048)
    prepared=document('docs/audits/native-proxy-lifetime-model-20260913/prepared.json')
    old_controls={row['name']:row for row in document('docs/audits/native-proxy-lifetime-model-20260913/plan.json')['controls']}
    summaries=[]; roots=set()
    for case in selection['cases']:
        assert case['profile']=='same_image'
        seed=copy.deepcopy(prepared['seeds']['same_image']); state=MODEL.initial(seed)
        for event in case['prefix']: assert MODEL.transition(seed,state,event)['returned']
        old=old_controls.get(case['prior_model_control'])
        changes=old.get('changes',[]) if case['mutation'] else []
        apply_changes(seed,state,changes)
        assert case['before']==project(state,seed['target_image'])
        if case['fault'] in ('private_root','runtime_global'):
            # The retained successful syscall-prefix witness independently
            # establishes these role removals; no physical interruption ran.
            del state['workspaces']['target']; del state['private']['target']
            if case['fault']=='runtime_global': del state['references']['target']
            returned=False
        elif case['event']=='reuse_a':
            returned=MODEL.live_matches(seed,state,'a',True)
            assert state['archives']['a']==seed['observers']['a']['archive']
        else:
            returned=MODEL.transition(seed,state,case['event'],fault='after_unlink' if case['fault'] else None)['returned']
        assert returned is case['expected_success'] is False
        assert case['expected_call_returned']==case['event'].startswith('release_')
        assert project(state,seed['target_image'])==case['after']
        if case['release_effect'] is not None:
            assert case['release_effect']==dict(unlink_attempted=int(bool(case['fault'])),unlink_completed=0,
                reference_absence_verified=0,last_reference_check=None)
        if case['followup_maintenance'] is not None:
            follow=MODEL.transition(seed,copy.deepcopy(state),'maintain_target')
            assert follow['returned'] is case['followup_maintenance']
        stem='fsmgen-LifetimeControls20260913_'+case['name']
        expected_roots=dict(store='.artifacts/tmp/native-proxy-image-custody/cases/'+stem,
            target='.artifacts/tmp/process-supervisor-tests/'+stem+'_target',
            other='.artifacts/tmp/process-supervisor-tests/'+stem+'_other',
            evidence='.artifacts/logs/native-proxy-observation-acquisition-20260910/cases/'+stem)
        assert case['roots']==expected_roots
        for relative in case['roots'].values():
            assert relative not in roots; roots.add(relative)
            path=ROOT/relative; assert not path.exists() and not path.is_symlink()
        summaries.append(dict(case=case['name'],prefix_events=len(case['prefix']),expected_after=case['after'],
            exact_original_receipt_changes=changes,actual_control_executed=False))
    assert len(roots)==selection['bounds']['fixture_roots']
    return summaries


def verify():
    plan=document(BASE/'plan.json'); selection=document(BASE/'selection.json')
    for row in plan['inputs']+document(BASE/'matrix-pins.json'):
        assert pin(row['path'])==row
    for row in plan['inputs']:
        assert subprocess.check_output(['git','show',plan['source_revision']+':'+row['path']],cwd=ROOT)==raw(row['path'])
    contracts=document(BASE/'source-contracts.json'); source_contracts(contracts)
    calls=document(BASE/'call-witnesses.json'); call_result=witnesses(calls)
    cases=matrix(selection); negative=[]
    for name,action in [
        ('missing_case',lambda s:s['cases'].pop()),
        ('failure_rolls_back',lambda s:s['cases'][-1]['after']['references'].append('b')),
        ('implicit_image_removal',lambda s:s['cases'][-1]['after'].__setitem__('image_present',False)),
        ('stale_runtime_does_not_pin',lambda s:s['cases'][-3].__setitem__('followup_maintenance',True)),
        ('release_failure_is_throw',lambda s:s['cases'][-1].__setitem__('expected_call_returned',False)),
        ('post_unlink_flag_promoted',lambda s:s['cases'][-1]['release_effect'].__setitem__('unlink_completed',1)),
        ('original_root_reuse',lambda s:s['cases'][0]['roots'].__setitem__('target','.artifacts/tmp/process-supervisor-tests/fsmgen-original'))]:
        changed=copy.deepcopy(selection);action(changed);reject(lambda:matrix(changed));negative.append(name)
    for name,action in [
        ('wrong_call_ordinal',lambda rows:rows[0].__setitem__('ordinal',rows[0]['ordinal']+1)),
        ('missing_partial_effect',lambda rows:rows[0]['successful_prefix_removals'].pop()),
        ('claim_actual_interruption',lambda rows:rows[0].__setitem__('actual_interruption_observed',True))]:
        changed=copy.deepcopy(calls);action(changed);reject(lambda:witnesses(changed));negative.append(name)
    failure=document(BASE/'first-selection-failure.json')
    assert raw(BASE/'author_matrix.py')==raw(BASE/'first-selection.source')
    assert sha(raw(BASE/'first-selection.source'))==failure['source_sha256']
    assert not (BASE/'select.py').exists()
    for row in failure['raw_captures']:
        body=bytes.fromhex(row['bytes_hex']);assert len(body)==row['size_bytes'] and sha(body)==row['sha256']
    assert bytes.fromhex(failure['raw_captures'][-1]['bytes_hex'])==b'1\n'
    return dict(schema='fsmgen.inactive_lifetime_control_matrix_review.v1',source_inputs=len(plan['inputs']),
        source_functions=len(contracts),cases=cases,call_witnesses=call_result,rejected_countermodels=negative,
        layout=layout(),actual_controls_executed=0,native_process_authentication=False,runtime_qualification=False,
        missing_legs=plan['missing_legs'])


def captures(prefix):
    result=[]
    for suffix in ('stdout','stderr','exit'):
        path=LOG/(prefix+'.'+suffix);body=raw(path)
        result.append(dict(**pin(path),bytes_hex=body.hex()))
    return result


def main():
    parser=argparse.ArgumentParser();group=parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--retain',action='store_true');group.add_argument('--verify-saved',action='store_true')
    args=parser.parse_args(); value=verify()
    if args.retain:
        value['raw_captures']=captures('corrected-selection')
        assert bytes.fromhex(value['raw_captures'][-1]['bytes_hex'])==b'0\n'
        write(BASE/'review.json',value)
    else:
        saved=document(BASE/'review.json')
        assert {k:v for k,v in saved.items() if k!='raw_captures'}==value
        for row in saved['raw_captures']:
            body=bytes.fromhex(row['bytes_hex']);assert sha(body)==row['sha256'] and len(body)==row['size_bytes']
    print(json.dumps(dict(cases=len(value['cases']),source_functions=value['source_functions'],
        call_witnesses=len(value['call_witnesses']),rejected_countermodels=len(value['rejected_countermodels']),
        actual_controls_executed=0,success=True),sort_keys=True))


if __name__=='__main__': main()

"""Reverify the preserved pre-compilation rejection; never rerun its producer."""
import argparse
import copy
import hashlib
import json
from pathlib import Path
import subprocess

BASE=Path(__file__).resolve().parent
ROOT=BASE.parents[2]
REVISION='143aafbc05ae5e15e41c4a5cccfefb3142f298d7'
ADMISSION='docs/audits/native-proxy-compiler-census-admission-20260913/'


def digest(raw):return hashlib.sha256(raw).hexdigest()


def old(path):
    return subprocess.check_output(['git','show',REVISION+':'+path],cwd=ROOT)


def read(name):return json.loads((BASE/name).read_bytes())


def sources():
    rows=read('source-pins.json')
    result={}
    for row in rows:
        raw=old(row['path'])
        assert len(raw)==row['size_bytes'] and digest(raw)==row['sha256']
        result[row['path']]=raw
    return result


def validate(first, views, diagnosis, source, corrected):
    assert first['compiler_invocations']==first['workspace_allocations']==0
    assert first['permit_consumed'] is False and first['run_start_absent'] and first['journal_absent']
    assert first['runner_exit']==1 and first['stage']=='closed_environment_preflight'
    plan=json.loads(source[ADMISSION+'plan.json'])
    assert first['root_absence']==[c['workspace'] for c in plan['cases']]
    outputs={}
    for row in first['outputs']:
        raw=bytes.fromhex(row['bytes_hex'])
        assert len(raw)==row['size_bytes'] and digest(raw)==row['sha256'] and row['path'] not in outputs
        outputs[row['path']]=raw
    out=plan['output']+'/'
    outer='.artifacts/logs/native-proxy-compiler-census-execution-20260913/'
    assert set(outputs)=={out+n for n in ['epoch-before.json','permit.json','runner.exit','runner.stdout','runner.stderr']} | {
        outer+s+'.'+e for s in ['permit','runner-outer'] for e in ['stdout','stderr','exit']}
    assert outputs[out+'runner.exit']==outputs[outer+'runner-outer.exit']==b'1\n'
    assert outputs[out+'runner.stdout']==outputs[outer+'runner-outer.stdout']==b''
    error=outputs[out+'runner.stderr'].decode()
    assert 'admission.py", line 101, in sources' in error
    assert "row[3:] in allowed or row[3:].startswith(PLAN['execution_evidence'] + '/')" in error
    assert 'AssertionError\ncommitted compiler admission preflight failed\n' in error
    permit=json.loads(outputs[out+'permit.json'])
    assert permit['admission_revision']==REVISION and permit['plan_sha256']==digest(source[ADMISSION+'plan.json'])
    assert permit['implementation_pins_sha256']==digest(source[ADMISSION+'implementation-pins.json'])
    assert permit['cases']==plan['cases'] and permit['compiler']==plan['compiler']
    assert permit['uid']==plan['normal_user']['uid'] and permit['device']==plan['normal_user']['project_device']
    assert not permit['reusable'] and not permit['native_proxy_execution'] and not permit['wrapper_execution']
    issued=json.loads(outputs[outer+'permit.stdout'])
    assert outputs[outer+'permit.exit']==b'0\n' and issued==dict(action='emit',admission_revision=REVISION,compiler_invocations=0,qualified=True)
    for view in views.values():
        assert view['exit']==0 and view['stderr_hex']==''
        assert bytes.fromhex(view['stdout_hex']).decode().split('\0')==view['paths']
    ordinary=set(views['ordinary']['paths']);closed=set(views['closed']['paths'])
    assert ordinary<closed and closed-ordinary=={'?? .claude/'}
    assert ordinary=={' M MEMORY.md',' M docs/TASK_TREE.md',
        ' M docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md','?? docs/audits/native-proxy-compiler-census-20260913/',''}
    commands=diagnosis['results']
    assert commands['ordinary_ignore']['exit']==0 and commands['closed_ignore']['exit']==1
    rule=bytes.fromhex(commands['ordinary_ignore']['stdout_hex']).decode()
    assert rule=='/Users/richarddje/.gitignore_global:6:.claude/settings.local.json\t.claude/settings.local.json\n'
    assert commands['closed_ignore']['stdout_hex']==''
    warning="git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead\n"
    assert bytes.fromhex(commands['closed_ignore']['stderr_hex']).decode()==warning*2
    assert corrected['exit']==1 and corrected['stdout_hex']==corrected['stderr_hex']==''
    assert corrected['closed_environment']==dict(PATH='/usr/bin:/bin',LC_ALL='C',LANG='C',TMPDIR_root_relative='.artifacts/tmp')
    local=commands['repository_ignore_only']
    assert local['exit']==0 and bytes.fromhex(local['stdout_hex']).decode().split('\0')==views['closed']['paths']
    assert local['command']==['git','-c','core.excludesFile=.gitignore','status','--porcelain=v1','-z']
    assert diagnosis['settings_content_read'] is False and diagnosis['settings_changed'] is False
    assert diagnosis['external_configuration_access']['access']=='read_only_by_git'
    assert [r['path'] for r in diagnosis['settings_metadata_only']]==['.claude','.claude/settings.local.json']
    assert all(r['uid']==permit['uid'] and r['device']==permit['device'] for r in diagnosis['settings_metadata_only'])
    runner=source[ADMISSION+'compile_profile.pl'].decode()
    assert runner.index("system($python->{path}, '-B'")<runner.index('exclusive("$OUT/run-start.json"')<runner.index('$prepared = prepare_rust_proxy(')
    assert "or die \"committed compiler admission preflight failed\\n\";" in runner
    gate=source[ADMISSION+'admission.py'].decode()
    assert gate.splitlines()[100].strip().startswith('assert all(row[3:] in allowed')
    assert "{'epoch-before.json', 'permit.json', 'runner.stdout', 'runner.stderr'}" in gate
    shell=source[ADMISSION+'execute_once.sh'].decode()
    assert 'set -uC' in shell and 'env -i PATH=/usr/bin:/bin' in shell
    return dict(first_runner_exit=1,compiler_invocations=0,compiler_workspaces=0,permit_consumed=False,
        cause='ordinary Git uses a personal ignore rule for local Claude settings; closed environment does not',
        hidden_path='.claude/settings.local.json',original_permit_retained=True,
        original_output_blocks_reuse=True,fresh_repository_local_admission_required=True,
        authentic_compiler_profiles=False,native_live_qualification=False)


def verify():
    values=(read('first-run-rejected.json'),read('git-view-first.json'),read('ignore-diagnosis-first.json'),sources(),read('closed-ignore-project-temp.json'))
    result=validate(*values);rejected=[]
    for name,change in [
        ('compiler_invocation_promoted',lambda a,b,c,d,t:a.update(compiler_invocations=1)),
        ('workspace_promoted',lambda a,b,c,d,t:a.update(workspace_allocations=1)),
        ('consumption_promoted',lambda a,b,c,d,t:a.update(permit_consumed=True)),
        ('exit_promoted',lambda a,b,c,d,t:a.update(runner_exit=0)),
        ('root_absence_missing',lambda a,b,c,d,t:a['root_absence'].pop()),
        ('missing_first_output',lambda a,b,c,d,t:a['outputs'].pop()),
        ('changed_view_bytes',lambda a,b,c,d,t:b['closed'].update(stdout_hex='')),
        ('shared_settings_read',lambda a,b,c,d,t:c.update(settings_content_read=True)),
        ('shared_settings_changed',lambda a,b,c,d,t:c.update(settings_changed=True)),
        ('configuration_write_promoted',lambda a,b,c,d,t:c['external_configuration_access'].update(access='write')),
        ('source_boundary_removed',lambda a,b,c,d,t:d.update({ADMISSION+'compile_profile.pl':b'changed'})),
        ('initial_temp_warning_hidden',lambda a,b,c,d,t:c['results']['closed_ignore'].update(stderr_hex='')),
        ('corrected_temp_root_changed',lambda a,b,c,d,t:t['closed_environment'].update(TMPDIR_root_relative='/tmp')),
    ]:
        altered=copy.deepcopy(values);change(*altered)
        try:validate(*altered)
        except (AssertionError,KeyError,ValueError):rejected.append(name)
        else:raise AssertionError('accepted altered first rejection: '+name)
    return dict(result=result,rejected_controls=rejected,source_revision=REVISION,
        claim_legs=dict(rederivation='Exact committed invocation order and preserved terminal outputs, views and ignore-source controls.',
            falsification='Independent repository-only ignore view and altered first-outcome/source/ownership controls.',
            durability='First outputs and metadata, immutable Git source pins, owned repair/fresh-admission leaves and this commit.'))


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    group=parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--retain',action='store_true');group.add_argument('--verify-saved',action='store_true')
    args=parser.parse_args();value=verify()
    if args.retain:
        with (BASE/'review.json').open('x') as stream:json.dump(value,stream,sort_keys=True,indent=2);stream.write('\n')
    else:assert read('review.json')==value
    print(json.dumps(dict(**value['result'],rejected_controls=len(value['rejected_controls'])),sort_keys=True))

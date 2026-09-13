"""Verify the fresh local-policy admission without issuing any runtime permit."""
import argparse
import ast
import json
import os

import admission
import ignore_policy
import qualify_profile
import source_contract

BASE, ROOT, PLAN = admission.BASE, admission.ROOT, admission.PLAN


def pin(path):
    raw=path.read_bytes()
    return dict(path=str(path.relative_to(ROOT)),size_bytes=len(raw),sha256=admission.digest(raw))


def verify():
    implementation=json.loads((BASE/'implementation-pins.json').read_bytes())
    for row in PLAN['inputs']+implementation:assert pin(ROOT/row['path'])==row
    inherited=json.loads((BASE/'inherited-sources.json').read_bytes())
    modified={'admission.py','execute_once.sh','review_profile.py','qualify_profile.py'}
    for row in inherited:
        raw=admission.git('show',row['source_revision']+':'+row['source_path'])
        assert len(raw)==row['size_bytes'] and admission.digest(raw)==row['sha256']
        if row['path'].rsplit('/',1)[-1] not in modified:
            assert (ROOT/row['path']).read_bytes()==raw
    old_plan=json.loads(admission.git('show','143aafbc05ae5e15e41c4a5cccfefb3142f298d7:docs/audits/native-proxy-compiler-census-admission-20260913/plan.json'))
    for key in ['cases','compiler','evidence_limits','workspace_policy','wrapper','cargo_role','selection','normal_user']:
        assert PLAN[key]==old_plan[key],key
    assert PLAN['output']!=old_plan['output'] and PLAN['execution_evidence']!=old_plan['execution_evidence']
    assert PLAN['execution_owner']==PLAN['owner'].rsplit('.',1)[0]+'.3'
    prior=json.loads((ROOT/PLAN['prior_rejection']['evidence']).read_bytes())
    assert prior['result']['compiler_invocations']==prior['result']['compiler_workspaces']==0
    assert prior['result']['permit_consumed'] is False and prior['result']['original_output_blocks_reuse']
    assert len(prior['rejected_controls'])==13
    assert PLAN['git_policy']['executable']=='/usr/bin/git'
    assert PLAN['git_policy']['configuration']=={'core.excludesFile':'.gitignore'}
    assert PLAN['git_policy']['closed_environment']==dict(PATH='/usr/bin:/bin',LC_ALL='C',LANG='C',TMPDIR_root_relative='.artifacts/tmp')
    policy=ignore_policy.verify(json.loads((BASE/'ignore-policy-first.json').read_bytes()))
    assert policy==json.loads((BASE/'ignore-policy-review.json').read_bytes())
    assert len(policy['rejected_controls'])==10 and policy['result']['negative_path_controls']==5
    model=qualify_profile.qualify()
    assert model['compiler_invocations']==model['fixture_allocations']==0
    assert len(model['rejected_controls'])==48 and model['git_request_model_calls']==2
    assert len(model['wrapper_source']['rejected_controls'])==5
    qualification=json.loads((BASE/'qualification.json').read_bytes())
    assert json.loads(qualification['outputs']['profile-model']['stdout'])==model
    for row in qualification['sources']:assert pin(ROOT/row['path'])==row
    assert all(row['exit']=='0\n' for row in qualification['outputs'].values())
    assert qualification['outputs']['compiler-model']['stdout'].endswith('1..29\n')
    assert '\nnot ok ' not in '\n'+qualification['outputs']['compiler-model']['stdout']
    assert 'compile_profile.pl syntax OK' in qualification['outputs']['runner-syntax']['stderr']
    installed=json.loads((BASE/'installed-inputs-first.json').read_bytes())
    assert installed['compiler_invocations']==installed['fixture_allocations']==0
    assert installed['inputs']['git_launcher']==PLAN['git_policy']['pin']
    assert json.loads(qualification['outputs']['installed-inputs-file']['stdout'])==dict(
        installed_inputs_match=True,git_launcher=PLAN['git_policy']['pin']['sha256'],
        compiler_invocations=0,fixture_allocations=0)
    epoch=json.loads((admission.EPOCH/'epoch-first.json').read_bytes())
    assert installed['inputs']==dict(
        files=[r for r in epoch['files'] if '/MacOSX26.5.sdk/' not in r['path']],
        sdk_entries=[r for r in epoch['sdk_entries'] if not r['path'].endswith('/MacOSX26.5.sdk')],
        interpreters=PLAN['interpreters'],git_launcher=PLAN['git_policy']['pin'])
    first=json.loads((BASE/'stdin-source-check-first.json').read_bytes())
    assert first['outputs']['exit']=='0\n' and first['outputs']['stdout']=='' and first['required_artifact_absent']
    assert 'installed-inputs' not in qualification['outputs']
    for path in BASE.glob('*.py'):ast.parse(path.read_bytes(),filename=str(path.relative_to(ROOT)))
    assert source_contract.wrapper((ROOT/'t/1669-task-acceptance-fixture-runtime.t').read_bytes())==bytes.fromhex(PLAN['wrapper']['bytes_hex'])
    assert not os.path.lexists(ROOT/PLAN['output'])
    assert all(not os.path.lexists(ROOT/c['workspace']) for c in PLAN['cases'])
    return dict(source_inputs=len(PLAN['inputs']),implementation_inputs=len(implementation),
        inherited_compiler_model_checks=29,profile_rejected_controls=48,git_policy_rejected_controls=10,
        git_negative_path_controls=5,equal_git_views=3,source_admission_only=True,
        compiler_invocations=0,fixture_allocations=0,previous_permit_reusable=False,
        current_installed_inputs_revalidation_required=True,authentic_profiles_pending=True)


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--verify-saved',required=True,action='store_true');parser.parse_args()
    print(json.dumps(verify(),sort_keys=True))

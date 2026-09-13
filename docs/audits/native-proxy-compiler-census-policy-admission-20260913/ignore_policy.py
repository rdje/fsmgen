"""Read-only Git policy probes; no settings contents or fixture creation."""
import argparse
import copy
import json
import subprocess

from admission import BASE, ROOT, PLAN, digest, save

CASES=['.claude/settings.local.json','.claude/settings.json','.claude/settings.local.json.extra',
       '.claude/nested/settings.local.json','.claude/AGENTS.md','nested/.claude/settings.local.json']
PREFIX=['/usr/bin/git','-c','core.excludesFile=.gitignore']


def environment():
    return dict(PATH='/usr/bin:/bin',LC_ALL='C',LANG='C',TMPDIR=str(ROOT/'.artifacts/tmp'))


def invoke(argv, env):
    value=subprocess.run(argv,cwd=ROOT,env=env,stdout=subprocess.PIPE,stderr=subprocess.PIPE,check=False)
    assert len(value.stdout)<=262144 and len(value.stderr)<=32768
    return dict(argv=argv,environment='ordinary' if env is None else 'closed_repository_temp',
                exit=value.returncode,stdout_hex=value.stdout.hex(),stderr_hex=value.stderr.hex())


def capture():
    views={label:invoke(argv+['status','--porcelain=v1','-z'],env) for label,argv,env in [
        ('ordinary',['/usr/bin/git'],None),('closed',['/usr/bin/git'],environment()),
        ('fixed',PREFIX,environment())]}
    cases={path:invoke(PREFIX+['check-ignore','--no-index','-v','--',path],environment()) for path in CASES}
    return dict(views=views,cases=cases,settings_content_read=False,settings_changed=False,
                compiler_invocations=0,fixture_allocations=0)


def validate(observed, current, baseline):
    marker=b'.vscode/tasks.json\n'
    added=b'# Local harness permissions; keep shared Claude configuration visible.\n/.claude/settings.local.json\n'
    assert baseline.count(marker)==1 and current==baseline.replace(marker,marker+added)
    assert observed['settings_content_read'] is False and observed['settings_changed'] is False
    assert observed['compiler_invocations']==observed['fixture_allocations']==0
    views=observed['views'];assert set(views)=={'ordinary','closed','fixed'}
    assert all(r['exit']==0 and r['stderr_hex']=='' for r in views.values())
    assert len({r['stdout_hex'] for r in views.values()})==1
    assert b'?? .claude/' not in bytes.fromhex(views['fixed']['stdout_hex'])
    assert views['fixed']['argv']==PREFIX+['status','--porcelain=v1','-z']
    assert views['closed']['environment']==views['fixed']['environment']=='closed_repository_temp'
    assert set(observed['cases'])==set(CASES)
    line=current.splitlines().index(b'/.claude/settings.local.json')+1
    for path,row in observed['cases'].items():
        assert row['argv']==PREFIX+['check-ignore','--no-index','-v','--',path]
        assert row['environment']=='closed_repository_temp' and row['stderr_hex']==''
        if path==CASES[0]:
            assert row['exit']==0
            assert bytes.fromhex(row['stdout_hex']).decode()==f'.gitignore:{line}:/.claude/settings.local.json\t{path}\n'
        elif path=='.claude/AGENTS.md':
            # --verbose reports matching negations; ! means not excluded.
            kept=current.splitlines().index(b'!*.md')+1
            assert row['exit']==0
            assert bytes.fromhex(row['stdout_hex']).decode()==f'.gitignore:{kept}:!*.md\t{path}\n'
        else:
            assert row['exit']==1 and row['stdout_hex']==''
    return dict(exact_ignored_path=CASES[0],negative_path_controls=len(CASES)-1,
        equal_git_views=len(views),shared_configuration_visible=True,settings_contents_untouched=True,
        source_only=True,compiler_invocations=0,fixture_allocations=0)


def verify(observed):
    baseline=subprocess.check_output(PREFIX+['show',PLAN['source_revision']+':.gitignore'],cwd=ROOT,env=environment())
    current=(ROOT/'.gitignore').read_bytes()
    result=validate(observed,current,baseline);rejected=[]
    for name,change in [
        ('global_view_mismatch',lambda v:v['views']['closed'].update(stdout_hex='00')),
        ('ambient_fixed_environment',lambda v:v['views']['fixed'].update(environment='ordinary')),
        ('compiler_invocation_promoted',lambda v:v.update(compiler_invocations=1)),
        ('fixture_allocation_promoted',lambda v:v.update(fixture_allocations=1)),
        ('settings_read_promoted',lambda v:v.update(settings_content_read=True)),
        ('settings_edit_promoted',lambda v:v.update(settings_changed=True)),
        ('shared_config_hidden',lambda v:v['cases'][CASES[1]].update(exit=0)),
        ('nested_config_hidden',lambda v:v['cases'][CASES[-1]].update(exit=0)),
        ('markdown_negation_lost',lambda v:v['cases']['.claude/AGENTS.md'].update(stdout_hex='')),
    ]:
        altered=copy.deepcopy(observed);change(altered)
        try:validate(altered,current,baseline)
        except (AssertionError,KeyError):rejected.append(name)
        else:raise AssertionError('accepted altered ignore evidence: '+name)
    try:validate(observed,current+b'/.claude/\n',baseline)
    except AssertionError:rejected.append('broad_directory_ignore')
    else:raise AssertionError('accepted broader ignore policy')
    return dict(result=result,rejected_controls=rejected,source_revision=PLAN['source_revision'],
                baseline_sha256=digest(baseline),current_sha256=digest(current),capture=observed)


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__);flags=parser.add_mutually_exclusive_group(required=True)
    flags.add_argument('--capture',action='store_true');flags.add_argument('--review-first',action='store_true')
    flags.add_argument('--verify-saved',action='store_true');args=parser.parse_args()
    if args.capture:
        observed=capture();save(BASE/'ignore-policy-first.json',observed)
        reviewed=verify(observed);save(BASE/'ignore-policy-review.json',reviewed)
    else:
        observed=json.loads((BASE/'ignore-policy-first.json').read_bytes());reviewed=verify(observed)
        if args.review_first:save(BASE/'ignore-policy-review.json',reviewed)
        else:assert reviewed==json.loads((BASE/'ignore-policy-review.json').read_bytes())
    print(json.dumps(dict(**reviewed['result'],rejected_controls=len(reviewed['rejected_controls'])),sort_keys=True))

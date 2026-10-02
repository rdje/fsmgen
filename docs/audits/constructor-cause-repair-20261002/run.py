import hashlib, json, os, subprocess
from pathlib import Path
base=Path('docs/audits/constructor-cause-repair-20261002')
paths=subprocess.check_output(['git','ls-files','bin','perl','t']).decode().splitlines()
paths += ['t/2053-isf-constructor-diagnostic-causes.t','t/lib/FSM/Test/DiagnosticCause.pm']
paths += [str(base/name) for name in ('bindings.json','old-consumer.pl','run.py','preload/FSM/Test/ConstructorCauseSubstring.pm')]
def digests():return {p:hashlib.sha256(Path(p).read_bytes()).hexdigest() for p in paths}
before=digests();runs=[]
for band in ('current','substring','family','old-consumer'):
    env=os.environ.copy()
    for name in ('FSMGEN_FORMAL_DIAGNOSTIC_FULL_STACK','FSMGEN_LIBRARY_DIAGNOSTIC_FULL_STACK','FSMGEN_FILE_DIAGNOSTIC_FULL_STACK'):
        env.pop(name,None)
    if band in ('current','substring'):
        env['FSMGEN_CONSTRUCTOR_CAUSE_CAPTURE']=str(base/band)
        command=['prove','-Iperl','-It/lib','t/2053-isf-constructor-diagnostic-causes.t']
        if band=='substring':
            env['PERL5LIB']=str(Path.cwd()/base/'preload')+os.pathsep+str(Path.cwd()/'t/lib')+os.pathsep+str(Path.cwd()/'perl')
            env['PERL5OPT']='-MFSM::Test::ConstructorCauseSubstring'
        expected=0 if band=='current' else 1
    elif band=='family':
        env.update(FSMGEN_ORIGIN_AUTHORITY_CAPTURE=str(base/'authority'),FSMGEN_LIBRARY_ORIGIN_CAPTURE=str(base/'same-source'),FSMGEN_ATL_ORIGIN_CAPTURE=str(base/'ATL'),FSMGEN_LOCAL_FORMAL_ORIGIN_CAPTURE=str(base/'formal'))
        command=['prove','-Iperl','-It/lib','t/2044-isf-conditional-origin-source-authority.t','t/2045-isf-same-source-library-origins.t','t/2047-isf-atl-document-origin-authority.t','t/2052-isf-local-formal-origin-authority.t']
        expected=0
    else:
        command=['perl','-Iperl','-It/lib',str(base/'old-consumer.pl')];expected=12
    command=['scripts/run_with_ram_guard.sh','--']+command
    with (base/(band+'.txt')).open('wb') as out:
        result=subprocess.run(command,env=env,stdout=out,stderr=subprocess.STDOUT)
    runs.append({'band':band,'command':command,'status':result.returncode,'expected':expected})
    (base/'runtime.json').write_text(json.dumps({'before':before,'after':digests(),'runs':runs,'baseline':subprocess.check_output(['git','rev-parse','HEAD']).decode().strip()},sort_keys=True,indent=2)+'\n')
    assert result.returncode==expected, runs[-1]
assert before==digests()
print('bound current/family pass; substring and exact old consumer intentionally RED; all sources/instruments unchanged during replay')

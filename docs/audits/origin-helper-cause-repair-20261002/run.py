import hashlib,json,os,subprocess
from pathlib import Path
base=Path('docs/audits/origin-helper-cause-repair-20261002')
paths=subprocess.check_output(['git','ls-files','bin','perl','t']).decode().splitlines()
paths += [str(base/'run.py')]+[str(p) for p in (base/'preload').glob('*.pm')]
def hashes():return {p:hashlib.sha256(Path(p).read_bytes()).hexdigest() for p in paths}
before=hashes();runs=[];baseline=subprocess.check_output(['git','rev-parse','HEAD']).decode().strip()
for kind,test,capture_var,flag,class_var,module in (
 ('library','t/2046-isf-library-document-origin-authority.t','FSMGEN_DOCUMENT_ORIGIN_CAPTURE','FSMGEN_LIBRARY_DIAGNOSTIC_FULL_STACK','FSMGEN_DOCUMENT_ORIGIN_AUTHORITY_CLASS','NoLibrarySourceComparison'),
 ('file','t/2048-isf-file-document-origin-authority.t','FSMGEN_FILE_ORIGIN_CAPTURE','FSMGEN_FILE_DIAGNOSTIC_FULL_STACK','FSMGEN_FILE_ORIGIN_AUTHORITY_CLASS','NoFileSourceComparison')):
    for band in ('current','full-stack','bypass'):
        env=os.environ.copy()
        for name in ('FSMGEN_DOCUMENT_ORIGIN_AUTHORITY_CLASS','FSMGEN_FILE_ORIGIN_AUTHORITY_CLASS','FSMGEN_LIBRARY_DIAGNOSTIC_FULL_STACK','FSMGEN_FILE_DIAGNOSTIC_FULL_STACK'):
            env.pop(name,None)
        settings={capture_var:str(base/kind/band)}
        if band=='full-stack':settings[flag]='1'
        if band=='bypass':
            settings[class_var]=module
            env['PERL5OPT']='-M'+module
            env['PERL5LIB']=os.pathsep.join(str(Path(p).resolve()) for p in ('perl','t/lib',str(base/'preload')))
        env.update(settings)
        command=['scripts/run_with_ram_guard.sh','--','prove','-Iperl','-It/lib',test]
        with (base/(kind+'-'+band+'.txt')).open('wb') as out:
            result=subprocess.run(command,env=env,stdout=out,stderr=subprocess.STDOUT)
        expected=0 if band=='current' else 1
        runs.append({'kind':kind,'band':band,'command':command,'settings':settings,'status':result.returncode,'expected':expected})
        after=hashes()
        (base/'runtime.json').write_text(json.dumps({'baseline':baseline,'before':before,'after':after,'runs':runs},sort_keys=True,indent=2)+'\n')
        assert before==after and result.returncode==expected,runs[-1]
        print(kind,band,'expected terminal status',result.returncode,flush=True)

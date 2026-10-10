"""Fresh complete inherited source/value/regex and publication reader executions."""
import subprocess
from common import BASE,CENSUS,PREDICATE,SCALAR,REGEX,REPAIR,REVISION,SCOPE,canonical,module,need,pin,save
from run import execute


def inputs():
    return [CENSUS/'census.json',CENSUS/'source-models.json',CENSUS/'obligation-plan.json',
        PREDICATE/'predicate-values-qualified.json',PREDICATE/'manifest-final.json',
        SCALAR/'scalars.json',SCALAR/'qualified-proof.json',SCALAR/'manifest-qualified.json',
        REGEX/'regexes.json',REGEX/'plan.json',REGEX/'proof.json',REGEX/'manifest.json',
        REPAIR/'proof.json',REPAIR/'manifest.json']


def readers():
    result=dict(module(PREDICATE/'common.py')['READERS'])
    result['predicate-values']=[str(PREDICATE/'verify.py')]
    result['scalar-values']=[str(SCALAR/'verify.py')]
    result['regex-values']=[str(REGEX/'verify.py')]
    result['regex-publication-repair']=[str(REPAIR/'verify.py')]
    return result


def main():
    fixed={}
    for path in inputs():
        command=['git','--no-replace-objects','show',REVISION+':'+str(path)]
        result=subprocess.run(command,capture_output=True)
        need(result.returncode==0 and not result.stderr and result.stdout==path.read_bytes(),
             'whole fixed/current value boundary prerequisite')
        fixed[str(path)]=dict(command=command,status=result.returncode,identity=pin(result.stdout))
    receipts={name:execute('prerequisite-'+name,['python3','-B',*arguments]) for name,arguments in readers().items()}
    save('prerequisites.json',dict(revision=REVISION,fixed=fixed,
        readers={name:pin(canonical(record)) for name,record in receipts.items()},scope=SCOPE))


if __name__=='__main__':
    main()

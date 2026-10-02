import hashlib,json,subprocess
from pathlib import Path
BASE=Path(__file__).parent
reader=Path('docs/audits/current-diagnostic-lexical-kinds-20261002/verify.py')
paths=subprocess.check_output(['git','ls-files','bin','perl','t']).decode().splitlines()
paths+=[str(reader),str(reader.parent/'manifest.json'),str(BASE/'run_bound.py')]
def fingerprints():return {p:hashlib.sha256(Path(p).read_bytes()).hexdigest() for p in sorted(paths) if Path(p).is_file()}
for label,flags,status in [('current',[],0),('old-comparison',['--old-comparison'],1)]:
    argv=['python3',str(reader),*flags];before=fingerprints()
    with (BASE/(label+'-bound.txt')).open('wb') as output:result=subprocess.run(argv,stdout=output,stderr=subprocess.STDOUT)
    after=fingerprints()
    (BASE/(label+'-binding.json')).write_text(json.dumps({'argv':argv,'expected':status,'status':result.returncode,'before':before,'after':after},sort_keys=True,indent=2)+'\n')
    assert before==after and result.returncode==status
    assert subprocess.run(['git','diff','--quiet','--','bin','perl','t']).returncode==0
    print(label+': PASS exact before/after source/reader/seal binding and expected actual outcome',flush=True)

import json
import subprocess
from pathlib import Path

root=Path('.artifacts/procedure-cond-normalization')
product=json.loads((root/'first-samples-candidate.json').read_text())
work=root/'candidate-carriers'
work.mkdir(exist_ok=True)
checks=[]
for name,source in sorted(product['lowered']['files'].items()):
    path=work/name
    path.write_text(source)
    argv=['perl','bin/fsmgen','--quiet','--strict','--check','--json',str(path)]
    result=subprocess.run(argv,input=b'',stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    checks.append(dict(file=name,argv=argv,exit_code=result.returncode,
        stdout=result.stdout.decode(),stderr=result.stderr.decode()))
    assert result.returncode==0 and json.loads(result.stdout)['success'] is True
(root/'candidate-carriers.json').write_text(json.dumps(checks,indent=2,sort_keys=True)+'\n')
print('PASS every complete saved candidate carrier strictly admits; source intent remains independently wrong')

import hashlib
import json
import os
import subprocess
from pathlib import Path
root=Path('.artifacts/conditional-origin-atl')
paths=sorted((root/'current-bound').glob('*.json'))
paths += [Path(p) for p in ('t/lib/FSM/Test/ATLDocumentOriginAuthority.pm',
    't/lib/FSM/Test/LibraryDocumentOriginAuthority.pm','t/lib/FSM/Test/SameSourceLibraryOriginParser.pm',
    't/lib/FSM/Test/ConditionalOriginParser.pm','.artifacts/conditional-origin-atl/red_missing_producer.t',
    '.artifacts/conditional-origin-atl/run_missing.py')]
paths += [Path(p) for p in subprocess.check_output(['git','ls-files','bin','perl']).decode().splitlines()]
def identities():return {str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(set(paths))}
capture=root/'missing-bound';capture.mkdir(exist_ok=False)
argv=['prove','-v','-Iperl','-It/lib','.artifacts/conditional-origin-atl/red_missing_producer.t']
env={'FSMGEN_ATL_MISSING_CAPTURE':str(capture)}
before=identities()
with (root/'missing-bound.tap').open('wb') as out,(root/'missing-bound-stderr.txt').open('wb') as err:
    result=subprocess.run(argv,env=dict(os.environ,**env),stdout=out,stderr=err)
after=identities()
(root/'missing-bound-recipe.json').write_text(json.dumps({'argv':argv,'cwd':'.','environment':env,
    'exit_status':result.returncode,'expected_status':1,'before':before,'after':after,
    'baseline':'f392e33a491d7798193f72447cfb564f0152da4a'},indent=2,sort_keys=True)+'\n')
assert result.returncode==1 and before==after and len(list(capture.glob('*.json')))==24
print('PASS genuine complete actual missing-producer RED and exact input/instrument/producer binding')

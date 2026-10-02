import hashlib, json, subprocess
from pathlib import Path
base=Path('docs/audits/source-origin-constructor-causes-20261002')
paths=subprocess.check_output(['git','ls-files','bin','perl','t']).decode().splitlines()
paths += [str(base/'probe.pl'),str(base/'bindings.json'),str(base/'run.py')]
def digests():
    return {p:hashlib.sha256(Path(p).read_bytes()).hexdigest() for p in paths}
before=digests()
with (base/'bound-probe.txt').open('wb') as out:
    result=subprocess.run(['scripts/run_with_ram_guard.sh','--','perl','-Iperl','-It/lib',str(base/'probe.pl')],stdout=out,stderr=subprocess.STDOUT)
after=digests()
receipt={'command':['scripts/run_with_ram_guard.sh','--','perl','-Iperl','-It/lib',str(base/'probe.pl')], 'status':result.returncode, 'head':subprocess.check_output(['git','rev-parse','HEAD']).decode().strip(),'before':before,'after':after}
(base/'runtime.json').write_text(json.dumps(receipt,sort_keys=True,indent=2)+'\n')
assert before==after
assert result.returncode==12, result.returncode
print('bound constructor probe: intentional current-consumer TAP RED status12; source/instrument digests unchanged')

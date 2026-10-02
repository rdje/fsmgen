"""Bound execution; called under the project RAM guard."""
import hashlib,json,subprocess
from pathlib import Path
B=Path(__file__).parent
paths=list(json.loads((B/'before.json').read_text()))+[str(B/n) for n in ('probe.pl','late-packages.pl','bindings.json','inputs.json','run.py')]
def fingerprints():return {p:hashlib.sha256(Path(p).read_bytes()).hexdigest() for p in paths}
before=fingerprints();(B/'bound-before.json').write_text(json.dumps(before,sort_keys=True,indent=2)+'\n')
with (B/'probe.txt').open('w') as f:r=subprocess.run(['perl',str(B/'probe.pl')],stdout=f,stderr=subprocess.STDOUT)
after=fingerprints();(B/'bound-after.json').write_text(json.dumps(after,sort_keys=True,indent=2)+'\n');assert before==after
runtime={'status':r.returncode,'command':['perl',str(B/'probe.pl')],'baseline':subprocess.check_output(['git','rev-parse','HEAD']).decode().strip()}
(B/'runtime.json').write_text(json.dumps(runtime,sort_keys=True,indent=2)+'\n');assert r.returncode==58
print('actual diagnostic TAP RED status58; exact producer and instrument fingerprints unchanged')

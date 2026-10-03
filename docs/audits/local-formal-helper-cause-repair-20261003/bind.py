import hashlib,json,subprocess
from pathlib import Path
B=Path(__file__).parent
revision=subprocess.check_output(['git','rev-parse','HEAD']).decode().strip()
assert revision=='1b14d447c14267d63da9faaa43152497934244e0'
names=subprocess.check_output(['git','ls-tree','-r','--name-only',revision,'--','bin','perl','t','scripts']).decode().splitlines()
names+=['t/2055-isf-local-formal-helper-diagnostic-causes.t']
metadata={p:{'bytes':len(Path(p).read_bytes()),'sha256':hashlib.sha256(Path(p).read_bytes()).hexdigest()} for p in names}
selected=['t/2052-isf-local-formal-origin-authority.t','t/2055-isf-local-formal-helper-diagnostic-causes.t','t/lib/FSM/Test/DiagnosticCause.pm','t/lib/FSM/Test/LocalFormalOriginAuthority.pm']
(B/'bindings.json').write_text(json.dumps({'baseline':revision,'metadata':metadata,'sources':{p:Path(p).read_text() for p in selected}},sort_keys=True,indent=2)+'\n')
print('Bound whole current source closure and selected sources.')

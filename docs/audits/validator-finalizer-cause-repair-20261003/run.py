"""Capture final producer/test execution with portable identities and fingerprints."""
import hashlib,json,os,subprocess
from pathlib import Path
B=Path(__file__).resolve().parent.relative_to(Path.cwd().resolve())
names=['t/2043-isf-conditional-origin-parser.t','t/2044-isf-conditional-origin-source-authority.t','t/2045-isf-same-source-library-origins.t','t/2046-isf-library-document-origin-authority.t','t/2047-isf-atl-document-origin-authority.t','t/2054-isf-validator-finalizer-diagnostic-causes.t']
paths=[p for p in subprocess.check_output(['git','ls-files','-z','bin','perl','t']).decode().split('\0') if p and Path(p).is_file()]
paths+=['t/2054-isf-validator-finalizer-diagnostic-causes.t',str(B/'run.py')]
for name in names+['t/lib/FSM/Test/DiagnosticCause.pm']:
 p=B/'instruments'/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(Path(name).read_bytes())
def fingerprints():return {p:hashlib.sha256(Path(p).read_bytes()).hexdigest() for p in paths}
before=fingerprints();(B/'before.json').write_text(json.dumps(before,sort_keys=True,indent=2)+'\n')
statuses={}
env=os.environ.copy();env.pop('FSMGEN_VALIDATOR_CAUSE_PRIOR_CONSUMER',None)
for directory,variable in [('parser','FSMGEN_CONDITIONAL_ORIGIN_CAPTURE'),('authority','FSMGEN_ORIGIN_AUTHORITY_CAPTURE'),('same','FSMGEN_LIBRARY_ORIGIN_CAPTURE'),('library','FSMGEN_DOCUMENT_ORIGIN_CAPTURE'),('ATL','FSMGEN_ATL_ORIGIN_CAPTURE'),('current','FSMGEN_VALIDATOR_CAUSE_CAPTURE')]:
 p=B/directory;p.mkdir(exist_ok=True);env[variable]=str(p)
# Only the existing changed cohort and the original repaired PathSearch boundary.
cmd=['prove','-Iperl','-It/lib',*names,'t/2049-pathsearch-module-origin.t']
with (B/'current.txt').open('w') as f:statuses['current']=subprocess.run(cmd,env=env,stdout=f,stderr=subprocess.STDOUT).returncode
assert statuses['current']==0
prior=os.environ.copy();prior['FSMGEN_VALIDATOR_CAUSE_PRIOR_CONSUMER']='1';p=B/'prior';p.mkdir(exist_ok=True);prior['FSMGEN_VALIDATOR_CAUSE_CAPTURE']=str(p)
with (B/'prior-consumers.txt').open('w') as f:statuses['prior']=subprocess.run(['prove','-Iperl','-It/lib',names[-1]],env=prior,stdout=f,stderr=subprocess.STDOUT).returncode
assert statuses['prior']==1
after=fingerprints();(B/'after.json').write_text(json.dumps(after,sort_keys=True,indent=2)+'\n');assert before==after
(B/'runtime.json').write_text(json.dumps({'statuses':statuses,'current_command':cmd,'prior_command':['prove','-Iperl','-It/lib',names[-1]],'baseline':subprocess.check_output(['git','rev-parse','HEAD']).decode().strip()},sort_keys=True,indent=2)+'\n')
print('current cohort PASS; exact prior-consumer counterfactual RED; all producer and instrument bytes unchanged')

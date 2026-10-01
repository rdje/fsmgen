"""Verify the selected-input evidence join without HDL execution."""
import copy,hashlib,json,subprocess
from pathlib import Path
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
BASE='1fccd22bea883f63ba9782db52b2eff139c7f665'
NATIVE='889d7e1beb7bcec1b214f4209d1cf725cb2f5239'
EXPECTED=['R1-input','R2-input-reads','R2-input-copy','R3-input-layout','R3-input-public','selected-input-profile-behavior']
def sha(raw):return hashlib.sha256(raw).hexdigest()
def validate(rows):
    assert [r['id'] for r in rows]==EXPECTED
    for row in rows:assert row['contract'] and row['evidence'] and row['open']
    assert 'same recursive resolved type' in rows[2]['contract']
    assert 'JSON primitive kinds' in rows[4]['contract']
    assert 'SystemVerilog parsing' in rows[5]['contract']
    assert 'X/Z' in rows[3]['open'] and 'historical EPERM' in rows[5]['open']
def reject(fn):
    try:fn()
    except AssertionError:return
    raise AssertionError('hostile signoff join accepted')
def main():
    m=json.loads((HERE/'manifest.json').read_bytes())
    assert m['baseline_revision']==BASE and m['native_revision']==NATIVE
    assert {p.name for p in HERE.iterdir() if p.is_file() and p.name!='manifest.json'}==set(m['sha256'])
    for p,d in m['sha256'].items():assert sha((HERE/p).read_bytes())==d
    for p,d in m['evidence_members'].items():assert sha((ROOT/p).read_bytes())==d
    for p,d in m['source_objects'].items():
        blob=subprocess.check_output(['git','rev-parse',BASE+':'+p],cwd=ROOT).decode().strip()
        assert blob==d['git_blob']
        assert sha(subprocess.check_output(['git','cat-file','blob',blob],cwd=ROOT))==d['sha256']
    joined=json.loads((HERE/'requirements.json').read_bytes())
    validate(joined['requirements'])
    reject(lambda:validate(joined['requirements'][:-1]))
    bad=copy.deepcopy(joined['requirements']);bad[2]['contract']=bad[2]['contract'].replace('same recursive resolved type','same width');reject(lambda:validate(bad))
    bad=copy.deepcopy(joined['requirements']);bad[5]['contract']=bad[5]['contract'].replace('SystemVerilog parsing','Verilog-2005 parsing');reject(lambda:validate(bad))
    saved=json.loads((HERE/'saved.json').read_bytes());assert len(saved)==8
    for row in saved:assert type(row['exit_code']) is int and row['exit_code']==0 and row['stdout'] and row['stderr']==''
    changed=subprocess.check_output(['git','diff','--name-only',NATIVE,BASE,'--','bin','perl','t/data','isf'],cwd=ROOT).decode().splitlines()
    assert changed==['bin/fsmgen','perl/FSM/Pipeline/HDLGenerator.pm','perl/FSM/Support/ISFHDLProfile.pm']
    assert json.loads((HERE/'source-boundary.json').read_bytes())=={'argv':['git','diff','--name-only',NATIVE,BASE,'--','bin','perl','t/data','isf'],'exit_code':0,'stdout':'\n'.join(changed)+'\n','stderr':''}
    receipt=(HERE/'current-public.txt').read_text();assert 'All tests successful.' in receipt and 'Result: PASS' in receipt
    assert 'Files=3, Tests=42' in receipt
    docs=(HERE/'docs-final.txt').read_text();assert 'All tests successful.' in docs and 'Files=3, Tests=310' in docs and 'Result: PASS' in docs
    before=(HERE/'docs-before.txt').read_text();assert "matrix documents Packed record actor inputs as source admitted; qualification pending" in before and 'Failed test:  28' in before
    prior=subprocess.check_output(['git','show',BASE+':t/1305-isf-book-feature-matrix-audit.t'],cwd=ROOT).decode()
    assert (HERE/'matrix-audit.t.source').read_text()==prior.replace("['Packed record actor inputs', 'source admitted; qualification pending']","['Packed record actor inputs', 'shipped bounded surface']")
    print('All selected R1-R3 input clauses join complete authenticated source/public/profile/native evidence; current public contracts pass and only the qualified profile integration changed since native execution. Missing clauses, width-only identity and parser-scope substitutions reject. Output/full consumer and stated execution limits remain open; no HDL replay.')
if __name__=='__main__':main()

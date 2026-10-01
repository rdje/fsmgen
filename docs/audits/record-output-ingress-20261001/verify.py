"""Authenticate record-output admission selection and the owned import prerequisite."""
import hashlib,json,subprocess
from pathlib import Path
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[2]
BASE='33de1d53162d7614060dca226c3081ebc3959df1'
def sha(b):return hashlib.sha256(b).hexdigest()
def validate(j):
    for n,t in [('local_output','frame'),('imported_output','shared.frame')]:
        r=j[n];assert r['parse_success'] is False
        assert r['parse_error'].splitlines()[0].startswith("Error: actor '"+n+"' interface port 'packet' references aggregate type '"+t+"'")
    a=j['imported_input'];b=j['imported_alias_input']
    assert a['parse_success'] is True and b['parse_success'] is True
    assert a['physical_success'] is False and b['physical_success'] is True
    assert a['physical_error'].splitlines()[0]=="Physical write declaration 'packet' has an invalid width token"
    assert '(packet shared.frame)' in a['carrier'] and '(held shared.frame)' in a['carrier']
    assert '(packet alias)' in b['carrier'] and '(held alias)' in b['carrier']
    assert b['physical_targets']['held']=={'module':'imported_alias_input','root':'held','target':'held','root_width':5,'low':0,'high':4,'width':5,'path_segments':[]}
    for r in [a,b,j['scalar_writer_overlap']]:assert r['source_unchanged'] is True
    w=j['scalar_writer_overlap'];assert w['parse_success'] is True and w['physical_success'] is True
    assert w['conflict_issues']==[]
    assignments=[r for r in w['assignment_provenance'] if r['target']=='value']
    assert {r['rhs'] for r in assignments}=={'1','2'}
    assert {r['source_name'] for r in w['source_owners']}=={'left','right'}
    assert w['physical_targets']['value']['low']==0 and w['physical_targets']['value']['high']==4

def reject(fn):
    try:fn()
    except AssertionError:return
    raise AssertionError('hostile ingress interpretation accepted')
def main():
    m=json.loads((HERE/'manifest.json').read_bytes());assert m['baseline_revision']==BASE
    assert set(m['sha256'])=={p.name for p in HERE.iterdir() if p.is_file() and p.name!='manifest.json'}
    for n,d in m['sha256'].items():assert sha((HERE/n).read_bytes())==d
    for p,d in m['producers'].items():
        blob=subprocess.check_output(['git','rev-parse',BASE+':'+p],cwd=ROOT).decode().strip();assert blob==d['git_blob']
        assert sha(subprocess.check_output(['git','cat-file','blob',blob],cwd=ROOT))==d['sha256']
    j=json.loads((HERE/'probe.json').read_bytes());validate(j)
    import copy
    bad=copy.deepcopy(j);bad['imported_input']['physical_success']=True;reject(lambda:validate(bad))
    bad=copy.deepcopy(j);bad['local_output']['parse_success']=True;reject(lambda:validate(bad))
    bad=copy.deepcopy(j);bad['scalar_writer_overlap']['assignment_provenance']=[r for r in bad['scalar_writer_overlap']['assignment_provenance'] if r['rhs']!='2'];reject(lambda:validate(bad))
    replay=json.loads((HERE/'carrier-replay.json').read_bytes());assert [r['case'] for r in replay]==['imported_input','imported_alias_input']
    for r in replay:
        assert type(r['exit_code']) is int and r['exit_code']==0 and r['stderr']==''
        assert json.loads(r['stdout'])['success'] is True
    h=json.loads((HERE/'history.json').read_bytes());assert h['exit_code']==0 and h['stdout'].startswith('1933c4f1255802f191aa6efd016aa5063e9188d2 ')
    receipt=(HERE/'substrate.txt').read_text();assert 'All tests successful.' in receipt and 'Files=2, Tests=9' in receipt and 'Result: PASS' in receipt
    print('Current output source refusal and imported writer-token defect authenticate against alias-equivalent carrier replay, unchanged callers and exact helper history. Actual scalar overlapping targets are retained without treating empty conflict issues as admission. False import repair/output admission and omitted competing assignments reject. No HDL execution; scoped prerequisite and writer/source/qualification slices remain owned.')
if __name__=='__main__':main()

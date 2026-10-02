"""Saved actual-source safety witnesses. Never replay HDL or integrate a candidate."""
import copy
import hashlib
import json
import subprocess
from functools import lru_cache
from pathlib import Path

BASE=Path(__file__).resolve().parent
BASELINE='518d99d288b6b1cf4fd2f8f38518d684d37740a6'
NAMES=set('basic expression priority no_else else_only nested_cond outer_when outer_while outer_until outer_repeat repeat_control outer_switch nested_call multiple_calls direct_formal generated domain first_actions first_samples authored_entry unused_bad_cond empty_body else_order non_list direct_recursion mutual_recursion'.split())
CONTROLS={'authored_entry','unused_bad_cond'}
PRODUCERS={'bin/fsmgen','bin/fsmgen-mcp','perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm','perl/FSM/VIAL/Tool.pm'}
DELTA=b'''    # The transaction cond pass ran before this body existed at the call site.
    # Normalize the substituted copy, then expose branch calls to the same
    # recursion checks below; leave unused procedure definitions untouched.
    $body = $self->_expand_conds_in_list($body, "$ctx -> proc '$name'");
'''


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def load(path):
    return json.loads((BASE/path).read_text())


def exact(value):
    return json.dumps(value,sort_keys=True,separators=(',',':'))


@lru_cache(maxsize=None)
def baseline_sha(path):
    return sha(subprocess.check_output(['git','show',BASELINE+':'+path]))


def has_cond(node):
    return isinstance(node,list) and ((bool(node) and node[0]=='cond') or any(has_cond(n) for n in node))


def phases(value,refuse):
    assert set(value['queries'])=={'check','semantic','schedule'}
    for kind,q in value['queries'].items():
        native,report,api=q['native'],q['native_report'],q['api']
        assert native['signal']==0 and native['exit_code']==((255 if kind=='schedule' else 1) if refuse else 0)
        assert q['stdio']['exit_code']==0 and q['stdio']['signal']==0
        assert exact(json.loads(q['stdio']['stdout']))==exact(q['stdio_response'])==exact(api)
        assert set(q['producer_before'])==PRODUCERS and q['producer_before']==q['producer_after']
        assert all(fingerprint==baseline_sha(path) for path,fingerprint in q['producer_before'].items())
        if refuse:
            assert "unsupported '(cond ...)' clause" in native['stdout']+native['stderr']
        if refuse and kind=='schedule':
            assert native['stdout']=='' and report is None
            assert api=={'jsonrpc':'2.0','id':1,'error':{'code':-32000,'message':'FSMGen command failed without a matching public failure report'}}
        else:
            assert exact(json.loads(native['stdout']))==exact(report)
            assert api['result']['isError'] is refuse and 'error' not in api
            assert exact(api['result']['structuredContent']['report'])==exact(report)
            if kind!='schedule':
                assert report['success'] is (not refuse)


def safety(candidate,restored):
    source=(BASE/'sources/first_samples.isf').read_text()
    for value in [candidate,restored]:
        assert value['source']==source and value['source_sha256']==sha(source.encode())
        port=next(p for p in value['actor']['interface']['inputs'] if p['name']=='datain')
        assert type(port['width']) is str and port['width']=='3'
    assert candidate['loaded_parser_sha256']==sha((BASE/'Parser-current.pm').read_bytes())
    assert restored['loaded_parser_sha256']==restored['loaded_parser_before_sha256']==baseline_sha('perl/FSM/Adapter/ISF/Parser.pm')
    assert restored['parser_mode']=='restored'
    phases(candidate,False)
    phases(restored,True)
    assert restored['lowered'] is None and restored['private_ir'] is None
    assert "unsupported '(cond ...)' clause" in restored['lower_error']+restored['private_error']
    tx=next(t for t in restored['actor']['transactions'] if t['name']=='main')
    assert tx['clauses']==[['cond',['allow',['sample','datain','as','captured']],['else',['sample','other','as','saved']]],['complete','done']]
    tx=next(t for t in candidate['actor']['transactions'] if t['name']=='main')
    assert tx['clauses']==[['when','allow',['sample','datain','as','captured']],['when',['!','allow'],['sample','other','as','saved']],['complete','done']]
    ir=candidate['private_ir']
    assert [s['kind'] for s in ir['states']]==['entry','branch','sequential','terminal']
    assert ir['states'][0]['guard']=={'port':'allow'}
    assert sum(s['kind']=='branch' for s in ir['states'])==1
    assert next(s for s in ir['states'] if s['kind']=='branch')['condition']==['!','allow']
    captures=[a for s in ir['states'] for a in s.get('assignments',[]) if a.get('source_kind')=='sample_capture']
    assert [(a['lhs'],a['op'],a['rhs']) for a in captures]==[('captured','<=','datain'),('saved','<=','other')]


def verify():
    assert len(NAMES)==26 and {c['name'] for c in load('cases.json')}==NAMES
    assert {p.stem for p in (BASE/'sources').glob('*.isf')}==NAMES
    for cohort in ['baseline-qualified','current-qualified','restored-boundary']:
        assert {p.stem for p in (BASE/cohort).glob('*.json')}==NAMES
        for name in NAMES:
            v=load(cohort+'/'+name+'.json')
            assert v['source']==(BASE/'sources'/ (name+'.isf')).read_text()
    for name in NAMES:
        v=load('restored-boundary/'+name+'.json')
        tx=next(t for t in v['actor']['transactions'] if t['name']=='main')
        assert bool(has_cond(tx['clauses'])) is (name not in CONTROLS|{'repeat_control'})
        if name in CONTROLS:
            assert v['lowered'] and v['private_ir'] and v['lower_error'] is None and v['private_error'] is None
            assert v['private_ir']['states'][0]['kind']=='entry'
        else:
            reason="unsupported '(when ...)' clause in repeat body" if name=='repeat_control' else "unsupported '(cond ...)' clause"
            assert v['lowered'] is None and v['private_ir'] is None
            assert reason in v['lower_error'] and reason in v['private_error']
    cases={c['name']:c for c in load('cases.json')}
    for name in NAMES:
        v=load('current-qualified/'+name+'.json')
        if cases[name].get('parse_reason'):
            assert v['actor'] is None and cases[name]['parse_reason'] in v['parse_error']
        else:
            assert v['parse_error'] is None
            tx=next(t for t in v['actor']['transactions'] if t['name']=='main')
            assert exact(tx['clauses'])==exact(cases[name]['clauses'])
            assert exact(v['actor']['procs']['choose']['body'])==exact(cases[name]['definition'])
    basic=load('current-qualified/basic.json')
    assert next(t for t in basic['actor']['transactions'] if t['name']=='main')['clauses']==[
        ['on','request'],['when','allow',['set','seen','datain']],
        ['when',['!','allow'],['set','seen','other']],['complete','done']]
    namespace={'__file__':str(BASE/'macro_validate.py')}
    exec(compile((BASE/'macro_validate.py').read_text(),str(BASE/'macro_validate.py'),'exec'),namespace)
    assert {p.stem for p in (BASE/'macro-current').glob('*.json')}==namespace['NAMES']
    assert len(namespace['NAMES'])==43
    for name in namespace['NAMES']:
        namespace['validate'](name,load('macro-current/'+name+'.json'))
    for receipt,token,result in [('baseline-qualified.tap','Tests: 27 Failed: 23','FAIL'),
        ('current-qualified.tap','Files=1, Tests=27','PASS'),('macro-current.tap','Files=1, Tests=44','PASS'),
        ('unsafe-entry-red.tap','Tests: 2 Failed: 2','FAIL'),('restored-boundary.tap','Files=1, Tests=27','PASS'),
        ('focused.tap','Files=9, Tests=60','PASS'),('docs.tap','Files=6, Tests=622','PASS')]:
        raw=(BASE/receipt).read_text()
        assert token in raw and 'Result: '+result in raw
    assert 'Result: FAIL' in (BASE/'current-candidate.tap').read_text()
    before=(BASE/'Parser-baseline.pm').read_bytes()
    after=(BASE/'Parser-current.pm').read_bytes()
    assert sha(before)==baseline_sha('perl/FSM/Adapter/ISF/Parser.pm')
    assert after.count(DELTA)==1 and after.replace(DELTA,b'',1)==before
    candidate,restored=load('first-samples-candidate.json'),load('first-samples-restored.json')
    safety(candidate,restored)
    carriers=load('candidate-carriers.json')
    assert sorted(c['file'] for c in carriers)==sorted(candidate['lowered']['files'])
    for c in carriers:
        assert c['exit_code']==0 and json.loads(c['stdout'])['success'] is True
        assert (BASE/'candidate-carriers'/c['file']).read_text()==candidate['lowered']['files'][c['file']]
    controls=[]
    for mode in ['sample_omission','guard_change','fabricated_branch','width_kind','false_restored_admission']:
        c,r=copy.deepcopy(candidate),copy.deepcopy(restored)
        if mode=='sample_omission':
            c['private_ir']['states'][0]['assignments']=[a for a in c['private_ir']['states'][0]['assignments'] if a.get('source_kind')!='sample_capture']
        elif mode=='guard_change':
            c['private_ir']['states'][0]['guard']['port']='request'
        elif mode=='fabricated_branch':
            c['private_ir']['states'][0]['kind']='branch'
        elif mode=='width_kind':
            for v in [c,r]:
                next(p for p in v['actor']['interface']['inputs'] if p['name']=='datain')['width']=3
        else:
            r['queries']=copy.deepcopy(c['queries'])
        try:
            safety(c,r)
        except AssertionError:
            controls.append(mode)
        else:
            raise AssertionError('shared corruption escaped literal/source safety witness: '+mode)
    inventory=load('production-inventory.json')
    assert inventory['baseline']==BASELINE and inventory['changed_existing']==[] and inventory['added']==[]
    raw=subprocess.check_output(['git','ls-tree','-r','-z',BASELINE,'--','bin','perl'])
    assert raw==(BASE/'production-inventory.zlist').read_bytes()
    assert set(inventory['members'])=={e.split(b'\t')[1].decode() for e in raw.split(b'\0') if e}
    for p,d in inventory['members'].items():
        assert sha(subprocess.check_output(['git','cat-file','blob',d['blob']]))==d['sha256']
    parents=load('immutable-parents.json')
    raw=subprocess.check_output(['git','ls-tree','-r','-z',BASELINE,'--']+parents['roots'])
    assert raw==(BASE/'immutable-parents.zlist').read_bytes()
    assert set(parents['members'])=={e.split(b'\t')[1].decode() for e in raw.split(b'\0') if e}
    assert all(sha(Path(p).read_bytes())==d['sha256'] for p,d in parents['members'].items())
    if (BASE/'manifest.json').exists():
        entries=load('manifest.json')['entries']
        assert set(entries)=={str(p.relative_to(BASE)) for p in BASE.rglob('*') if p.is_file() and p.name!='manifest.json'}
        assert all((BASE/p).stat().st_size==d['bytes'] and sha((BASE/p).read_bytes())==d['sha256'] for p,d in entries.items())
    print('PASS complete fixed 26-source qualification, genuine old-parser/desired-branch RED and restored current boundary')
    print('PASS actual complete candidate admission versus restored native/API/newline refusal; every saved candidate carrier strictly admits')
    print('PASS exact four-line candidate, restored production census, immutable predecessors and independent corruptions: '+', '.join(controls))


if __name__=='__main__':
    verify()

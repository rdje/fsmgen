"""Independent immutable source/cause/whole-product guard for this exact cohort."""
import copy, hashlib, json, re, subprocess, sys
from pathlib import Path
B=Path(__file__).parent
enc=lambda x:json.dumps(x,sort_keys=True,separators=(',',':'),ensure_ascii=False)
sha=lambda b:hashlib.sha256(b).hexdigest()
bound=json.loads((B/'bindings.json').read_text()); revision=bound['baseline']
def blob(path):return subprocess.check_output(['git','show',revision+':'+str(path)])
def seal(path):
    m=json.loads((path/'manifest.json').read_text())
    # Historical seals use either a members object or a files list/object.
    members=m.get('members',m.get('files'));assert members is not None
    if isinstance(members,list):members={r['path']:r for r in members}
    for name,row in members.items():
        raw=(path/name).read_bytes();assert sha(raw)==row['sha256'];assert len(raw)==row['bytes']
    assert set(members)=={str(p.relative_to(path)) for p in path.rglob('*') if p.is_file() and p.name!='manifest.json'}
if (B/'manifest.json').exists():seal(B)
for path,source in bound['sources'].items():assert source.encode()==blob(path)
oldpath=Path('docs/audits/source-origin-refusal-review-20261002/inventory.json')
assert oldpath.read_bytes()==blob(oldpath);old=json.loads(oldpath.read_text())
roster={'t/2043-isf-conditional-origin-parser.t':[132,174],'t/2044-isf-conditional-origin-source-authority.t':[50,79,91],'t/2045-isf-same-source-library-origins.t':[161],'t/2046-isf-library-document-origin-authority.t':[79,195],'t/2047-isf-atl-document-origin-authority.t':[77,118]}
assert set(bound['sites'])=={p+':'+str(n) for p,ns in roster.items() for n in ns}
for site,row in bound['sites'].items():
    path,line=site.rsplit(':',1);prior=next(r for r in old['sites'] if r['path']==path and r['line']==int(line));text=old['sources'][path]['source'];statement=text[prior['offset']:text.index(';',prior['offset'])+1]
    assert statement==row['statement'];current=bound['sources'][path];assert current.count(statement)==1
    assert current.index(statement)==row['offset'];assert current[:row['offset']].count('\n')+1==row['line'];assert prior['offset']==row['historical_offset']
inputs=json.loads((B/'inputs.json').read_text())
for name,row in inputs.items():
    raw=blob(row['path']);assert Path(row['path']).read_bytes()==raw
    if name=='scheduler':assert raw.decode()==row['source']
    else:assert sha(raw)==row['sha256'];assert enc(json.loads(raw))==enc(row['product'])
# Complete committed producer fingerprint roster, independently obtained from Git.
before=json.loads((B/'before.json').read_text());names=subprocess.check_output(['git','ls-tree','-r','--name-only',revision,'--','bin','perl','t']).decode().splitlines();assert set(names)==set(before)
requests=''.join(revision+':'+p+'\n' for p in names).encode();raw=subprocess.check_output(['git','cat-file','--batch'],input=requests);offset=0
for name in names:
    end=raw.index(b'\n',offset);head=raw[offset:end].split();assert head[1]==b'blob';size=int(head[2]);data=raw[end+1:end+1+size];assert sha(data)==before[name];offset=end+size+2
assert offset==len(raw)
a=json.loads((B/'bound-before.json').read_text());z=json.loads((B/'bound-after.json').read_text());assert enc(a)==enc(z)
for path,digest in a.items():
    if path in before:assert digest==before[path]
    else:assert sha(Path(path).read_bytes())==digest
assert enc(json.loads((B/'runtime.json').read_text()))==enc({'status':58,'baseline':revision,'command':['perl',str(B/'probe.pl')]})
tap=(B/'probe.txt').read_text();assert '\n1..166\n' in tap and 'failed 58 tests of 166' in tap
assert len(re.findall(r'^not ok ',tap,re.M))==58
# Cause contracts are declared from the producer APIs, independently of emitted rows.
generic={'changed_target':'target identity mismatch','duplicate':'missing, extra or duplicate path','forged_origin':'differs from the actual producer result','omission':'incomplete coverage','schema_kind':'schema mismatch','source_identity':'differs from the actual producer result','unknown_field':'unknown or missing fields','wrong_path':'missing, extra or duplicate path'}
contracts={'scheduler':('scheduler',"Transaction 'main': unsupported '(cond ...)' clause in transaction body",'')}
contracts.update({'generic_'+k:('generic','conditional origin '+v,k) for k,v in generic.items()})
contracts.update({'local_'+v:('local','conditional origin '+v+' differs from authoritative source',v) for v in ('actor','ledger')})
contracts['twins']=('twins','conditional origin ledger differs from authoritative source','');contracts['missing']=('missing','conditional origin independent source authority required','')
contracts.update({k+'_'+v:(k,'library origin '+v+' differs from authoritative document set',v) for k in ('library','ATL') for v in ('actor','proof')})
contracts['same_late']=('same_late','conditional origin target identity mismatch','target')
contracts.update({'library_late_'+v:('library_late','library origin final use '+('coverage' if v=='coverage' else 'target or identity')+' differs',v) for v in ('target','instance','coverage','parameter_kind')})
contracts.update({'ATL_late_'+v:('ATL_late','ATL origin final '+('resolved actor coverage' if v=='coverage' else 'target or instance identity')+' differs',v) for v in ('target','declaration','coverage')})
data=json.loads((B/'products.json').read_text())
def causes(candidate):
    assert set(candidate)=={'contexts','products','original','documents','authorities'}
    assert len(candidate['contexts'])==25 and {r['id'] for r in candidate['contexts']}==set(contracts)
    assert enc(candidate['original'])==enc({'actor':inputs['local']['product']['instrumented'],'ledger':inputs['local']['product']['ledger']})
    seen=set()
    for r in candidate['products']:
        kind,expected,variant=contracts[r['id']];assert (r['kind'],r['expected'],r['variant'])==(kind,expected,variant)
        assert enc(next(c for c in candidate['contexts'] if c['id']==r['id']))==enc({k:r[k] for k in ('id','site','kind','wanted','expected','variant')})
        assert (r['id'],r['band']) not in seen;seen.add((r['id'],r['band']))
        for key in ('accepted','matched','first_line_matched'):assert type(r[key]) is int and r[key] in (0,1)
        assert r['accepted']==0 and r['first_line']==r['error'].split('\n')[0]
        band=r['band']
        if band=='positive':assert r['first_line']==expected
        elif kind.endswith('_late'):
            p=r['payload'];source='; '+r['wanted']+'\n(not_actor)' if band=='wrong_source_echo' else '(not_actor)';label=r['wanted']+'.isf' if band=='wrong_label_echo' else 'wrong.isf'
            assert p['source']==source and p['label']==label;assert r['first_line']=="Error: no (actor ...) root found in '"+label+"'"
        elif kind=='scheduler':assert r['first_line']=='FSM::Scheduler::ISF->lower argument 1 must be a scheduler-consumable actor hash reference'
        elif kind=='generic':
            value=r['wanted'] if band=='wrong_argument_echo' else 'unrelated argument';assert r['payload']['actor']==value
            source=bound['sources']['t/lib/FSM/Test/ConditionalOriginParser.pm'];line=source[:source.index('for my $i (0 .. $#{$actor->{transactions}})')].count('\n')+1
            assert r['first_line']==f'Can\'t use string ("{value}") as a HASH ref while "strict refs" in use at t/lib/FSM/Test/ConditionalOriginParser.pm line {line}.'
        elif kind=='missing':assert r['first_line']=='conditional origin actor differs from authoritative source'
        else:assert r['first_line']==('conditional origin independent source authority required' if kind in ('local','twins') else 'library origin independent document set required')
        expected_match=0 if band.endswith('_plain') else 1;assert r['matched']==expected_match
        assert r['first_line_matched']==(1 if band in ('positive','wrong_label_echo') or (kind=='generic' and band=='wrong_argument_echo') else 0)
        if band!='positive' and not kind.endswith('_late'):assert r['payload']['actor']==(r['wanted'] if band=='wrong_argument_echo' else 'unrelated argument')
    assert seen=={(name,band) for name,(kind,_,__) in contracts.items() for band in (('positive','wrong_source_echo','wrong_source_plain','wrong_label_echo') if kind.endswith('_late') else ('positive','wrong_argument_echo','wrong_argument_plain'))}
causes(data)
actual=json.loads(subprocess.check_output(['perl',str(B/'replay.pl')],input=enc({'sites':bound['sites'],'products':data['products']}).encode()));assert enc(actual)==enc([r['matched'] for r in data['products']])
if '--trust-current' in sys.argv:
    assert all(r['matched']==(1 if r['band']=='positive' else 0) for r in data['products']), 'actual current assertions accept unrelated echoed causes'
for name in ('first_cause','flag_kind','flag_value','missing_context','source','unknown_root'):
    bad=copy.deepcopy(data)
    if name=='first_cause':bad['products'][0]['first_line']='wrong cause'
    elif name=='flag_kind':bad['products'][0]['matched']=True
    elif name=='flag_value':bad['products'][1]['matched']=0
    elif name=='missing_context':bad['products'].pop()
    elif name=='source':bad['products'][-1]['payload']['source']='(actor wrong)'
    else:bad['unknown']=1
    try:causes(bad)
    except AssertionError:print('shared cause corruption rejects:',name)
    else:raise AssertionError('accepted '+name)
# Exact frozen independently-authored source oracles; use only product functions,
# excluding old historical runtime/admission gates. Authenticate all dependencies.
for dirname in ('conditional-origin-library-20261002','conditional-origin-documents-finalization-20261002','conditional-origin-atl-20261002'):
    parent=Path('docs/audits')/dirname;seal(parent);assert (parent/'verify.py').read_bytes()==blob(parent/'verify.py')
    for p in (parent/'current-bound').glob('*.json'):assert p.read_bytes()==blob(p)
scopes={}
for kind,dirname in (('library','conditional-origin-documents-finalization-20261002'),('ATL','conditional-origin-atl-20261002')):
    p=Path('docs/audits')/dirname/'verify.py';scope={};exec(compile(p.read_text().split('\nproducts = ',1)[0],str(p),'exec'),scope);scopes[kind]=scope

def whole(candidate):
    for kind,scope in scopes.items():
        label,docs,roots=candidate['documents'][kind];assert roots==[str(B/'fixtures'/kind)]
        old=inputs[kind]['product'];wanted={str(B/'fixtures'/kind/Path(p).name):s for p,s in old['documents'].items()};assert enc(docs)==enc(wanted)
        expected_actor,expected_proof=scope['expected_product'](inputs['same']['product'],label,docs)
        result=candidate['authorities'][kind];assert set(result)=={'actor','proof','ordinary'}
        assert enc(result['actor'])==enc(expected_actor)==enc(result['ordinary']);assert enc(result['proof'])==enc(expected_proof)
whole(data)
for kind in ('library','ATL'):
    bad=copy.deepcopy(data)
    for f in ('actor','ordinary'):bad['authorities'][kind][f]['interface']['inputs'][0]['width']='1'
    try:whole(bad)
    except AssertionError:print('whole product kind corruption rejects:',kind)
    else:raise AssertionError('accepted whole kind '+kind)
print('complete ten-site/25-context/83-capture causes, independent whole products/kinds, Git/fingerprints and hostile controls pass; broader consumers remain open')

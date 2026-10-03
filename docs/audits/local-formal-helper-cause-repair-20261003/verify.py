"""Finite complete-cause helper repair: real inputs, whole products and exact source delta."""
import copy,hashlib,json,re,subprocess,sys
from pathlib import Path
B=Path(__file__).parent
PRIOR=Path('docs/audits/local-formal-helper-causes-20261003')
REV='1b14d447c14267d63da9faaa43152497934244e0'
enc=lambda x:json.dumps(x,sort_keys=True,separators=(',',':'))
def same(a,b):assert enc(a)==enc(b),'typed whole value mismatch'
def load(p):return json.loads(p.read_text())
def blob(p):return subprocess.check_output(['git','show',REV+':'+str(p)])
def seal(p,committed=False):
    if not (p/'manifest.json').exists():return
    if committed:assert (p/'manifest.json').read_bytes()==blob(p/'manifest.json')
    manifest=load(p/'manifest.json');rows=manifest['files'] if 'files' in manifest else manifest['members']
    assert set(rows)=={str(f.relative_to(p)) for f in p.rglob('*') if f.is_file() and f.name!='manifest.json'}
    for name,row in rows.items():
        raw=(p/name).read_bytes();same(row,{'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()})
seal(PRIOR,True);seal(B)
bind=load(B/'bindings.json');assert set(bind)=={'baseline','metadata','sources'} and bind['baseline']==REV
paths=subprocess.check_output(['git','ls-tree','-r','--name-only',REV,'--','bin','perl','t','scripts']).decode().splitlines()
new='t/2055-isf-local-formal-helper-diagnostic-causes.t';changed='t/2052-isf-local-formal-origin-authority.t'
assert set(bind['metadata'])==set(paths)|{new}
for p,row in bind['metadata'].items():
    raw=Path(p).read_bytes();same(row,{'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()})
unchanged=[p for p in paths if p!=changed]
hashes=subprocess.check_output(['git','hash-object','--stdin-paths'],input=('\n'.join(unchanged)+'\n').encode()).decode().splitlines()
gitrows=subprocess.check_output(['git','ls-tree','-r',REV,'--','bin','perl','t','scripts']).decode().splitlines()
git_hash={r.split('\t',1)[1]:r.split()[2] for r in gitrows}
assert len(hashes)==len(unchanged)
for p,h in zip(unchanged,hashes):assert h==git_hash[p],p
assert set(bind['sources'])=={changed,new,'t/lib/FSM/Test/DiagnosticCause.pm','t/lib/FSM/Test/LocalFormalOriginAuthority.pm'}
for p,source in bind['sources'].items():assert source.encode()==Path(p).read_bytes()
# Exact independently enumerated old-to-new source replacements, not a broad allowlist.
source=blob(changed).decode()
positive_causes={
'equal-body origin transplant':'local formal origin proof differs from authoritative source',
'actual clone callback lost':'local formal origin conditional clone association missing',
'actual Storable callback lost':'local formal origin conditional clone association missing',
'imported producer boundary':'conditional origin imported source authority is not qualified',
'actor network boundary':'local formal origin reusable/network scope is not qualified',
'generated transaction boundary':'local formal origin generated specialization is not qualified',
'domain constructor boundary':'local formal origin domain scope is not qualified',
'no formal preparation boundary':'local formal origin requires an unprojected direct formal'}
old_bound=load(PRIOR/'bindings.json')
for caller in old_bound['callers']:
    before='qr/'+caller['pattern']+'/'
    # Identical clone cause has two callers; replace their exact whole statements independently.
    statement=caller['statement'];assert source.count(statement)==1
    source=source.replace(statement,statement.replace(before,"'"+positive_causes[caller['name']]+"'"),1)
replacements=[
("diagnostic_matches($error,qr/expected_refusal_marker/)","diagnostic_matches($error,'expected_refusal_marker')",2),
('my ($operation,$pattern,$name)=@_;','my ($operation,$expected,$name)=@_;',1),
("ok(diagnostic_matches($error,$pattern),'exact first-line refusal mechanism');","ok(diagnostic_matches($error,$expected),'complete refusal cause');",1),
('    my ($error,$pattern)=@_;\n    my $subject=$ENV{FSMGEN_FORMAL_DIAGNOSTIC_FULL_STACK} ? $error : first_line($error);\n    return $subject =~ $pattern ? 1 : 0;',
'    my ($error,$expected)=@_;\n    return $error =~ /\\Q$expected\\E/ ? 1 : 0\n        if $ENV{FSMGEN_FORMAL_DIAGNOSTIC_FULL_STACK};\n    return diagnostic_cause_matches($error,$expected);',1)]
for before,after,count in replacements:
    assert source.count(before)==count;source=source.replace(before,after)
assert source==bind['sources'][changed]
assert old_bound['packages']==source[source.index('package FSM::Test::LocalFormalOriginAuthority::DropClone;'):]
products={p.stem:load(p) for p in (B/'products').glob('*.json')}
old_products={p.stem:load(p) for p in (PRIOR/'products').glob('*.json')}
assert set(products)==set(old_products)
ordinary=['select','min','max','cond','when-bit','unless-bit','when-field','unless-field','authored','nested','local','calls','first_authored_sample','first_macro_sample']
for name,value in products.items():
    old=old_products[name];assert set(value)==set(old)
    for key in set(value)-{'error','controls','canonical_error','observed_error'}:same(value[key],old[key])
    for key in ('canonical_error','observed_error'):
        if key in value:assert value[key].splitlines()[0]==old[key].splitlines()[0]
    if 'accepted' in value:
        same(value['accepted'],0);assert value['error'].splitlines()[0]==positive_causes[name.replace('_',' ')]
    elif 'error' in value:assert value['error'].splitlines()[0]==old['error'].splitlines()[0]
    if 'controls' in value:
        assert len(value['controls'])==8
        for c,o in zip(value['controls'],old['controls']):
            assert set(c)==set(o)
            for key in set(c)-{'error'}:same(c[key],o[key])
            assert c['error'].splitlines()[0]==o['error'].splitlines()[0]
exec((B/'input_oracle.py').read_text())
# Closed actual API descriptors and literal primary-error grammar; pointers are observations.
cases=load(PRIOR/'causes.json')['rows'];current=load(B/'current-causes.json');prior=load(B/'prior-causes.json')
def verify_rows(data):
    assert set(data)=={'rows'} and len(data['rows'])==32
    assert [(r['id'],r['band']) for r in data['rows']]==[(r['id'],r['band']) for r in cases]
    for r,c in zip(data['rows'],cases):
        assert set(r)=={'id','band','input','error','accepted','current','prior','expected_cause'}
        same(r['input'],expected_inputs[r['id']] if r['band']=='positive' else c['input'])
        same(r['accepted'],0);same(r['current'],int(r['band']=='positive'))
        same(r['prior'],int(r['band'] in ('positive','wrong_label_echo','wrong_input_echo')))
        assert r['expected_cause']==positive_causes[r['id']]
        first=r['error'].splitlines()[0]
        if r['band'] in ('wrong_input_echo','wrong_input_plain'):
            cls=r['input']['mutation']['class']
            grammar="encountered object '"+re.escape(cls)+r"=HASH\(0x[0-9a-f]+\)', but neither allow_blessed, convert_blessed nor allow_tags settings are enabled \(or TO_JSON/FREEZE method missing\) at t/lib/FSM/Test/LocalFormalOriginAuthority[.]pm line 190[.]"
            assert re.fullmatch(grammar,first)
        else:assert first==c['first_line']
verify_rows(current);verify_rows(prior)
replay=json.loads(subprocess.check_output(['perl',str(B/'replay.pl')]))
same(replay,[{k:r[k] for k in ('id','band','current','prior')} for r in current['rows']])
if '--prior-helper' in sys.argv:assert all(r['prior']==int(r['band']=='positive') for r in prior['rows']),'actual prior helper falsely matches wrong causes'
# Whole actual source-comparison bypass outputs conserve all sources/products/submitted kinds.
bypass={p.stem:load(p) for p in (B/'bypass-products').glob('*.json')}
stack={p.stem:load(p) for p in (B/'full-stack-products').glob('*.json')}
assert set(bypass)==set(stack)==set(products)
for name,value in products.items():
    for red in (bypass[name],stack[name]):
        assert set(red)==set(value)
        for key in set(value)-{'controls','error','accepted','matched','canonical_error','observed_error'}:same(red[key],value[key])
        for key in ('canonical_error','observed_error'):
            if key in value:assert red[key].splitlines()[0]==value[key].splitlines()[0]
    if name in ordinary:
        for red,current_control in zip(bypass[name]['controls'],value['controls']):
            expected=copy.deepcopy(current_control);expected.update(accepted=1,error='');same(red,expected)
        for red,current_control in zip(stack[name]['controls'],value['controls']):
            assert set(red)==set(current_control)
            for key in set(red)-{'error'}:same(red[key],current_control[key])
            assert red['error'].splitlines()[0]==current_control['error'].splitlines()[0]
    elif name=='equal-body_origin_transplant':same(bypass[name],{'accepted':1,'error':''})
    elif 'accepted' in value:
        for red in (bypass[name],stack[name]):
            same(red['accepted'],0);assert red['error'].splitlines()[0]==value['error'].splitlines()[0]
same(products['diagnostic_echo']['matched'],0);same(stack['diagnostic_echo']['matched'],1);same(bypass['diagnostic_echo']['matched'],0)
assert products['diagnostic_echo']['error'].splitlines()[0]=='unrelated failure'
if '--source-bypass' in sys.argv:assert all(c['accepted']==0 for n in ordinary for c in bypass[n]['controls']),'actual source authentication bypass admits forgeries'
for label in ('cause','input','current_kind','prior_kind','extra_field','membership'):
    bad=copy.deepcopy(current)
    if label=='cause':bad['rows'][0]['error']='wrong cause\n'
    elif label=='input':bad['rows'][0]['input']['proof']['unknown']=1
    elif label=='current_kind':bad['rows'][0]['current']=True
    elif label=='prior_kind':bad['rows'][0]['prior']=1.0
    elif label=='extra_field':bad['rows'][0]['extra']=1
    else:bad['rows'].pop()
    try:verify_rows(bad)
    except AssertionError:print('shared corruption rejects:',label)
    else:raise AssertionError('accepted '+label)
for label in ('whole_kind','whole_guard','whole_membership'):
    bad=copy.deepcopy(products['select'])
    if label=='whole_kind':bad['proof']['entries'][0]['source_entry']=False
    elif label=='whole_guard':
        bad['context']['actor']['transactions'][0]['clauses'][1][1]='forged'
        bad['proof']['entries'][0]['after'][1]='forged'
    else:bad['unexpected']=1
    try:
        assert set(bad)==set(old_products['select'])
        for key in ('source','context','proof','literal_clauses','literal_operations'):same(bad[key],old_products['select'][key])
    except AssertionError:print('whole product corruption rejects:',label)
    else:raise AssertionError('accepted '+label)
for name,status in [('current',0),('prior-helper-red',1),('full-stack-red',1),('source-bypass-red',1)]:assert (B/(name+'.status')).read_text()==str(status)+'\n'
assert 'All tests successful.' in (B/'current.txt').read_text() and 'Files=2, Tests=83' in (B/'current.txt').read_text()
assert 'Tests: 64 Failed: 8' in (B/'prior-helper-red.txt').read_text()
assert 'Tests: 19 Failed: 1' in (B/'full-stack-red.txt').read_text()
assert 'Tests: 19 Failed: 14' in (B/'source-bypass-red.txt').read_text()
print('PASS exact source delta, whole closed products/inputs/kinds, complete causes, prior helper/trace/source bypass and typed controls. Wider consumers remain open.')

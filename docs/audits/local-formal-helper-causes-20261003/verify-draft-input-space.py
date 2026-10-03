"""Cold exact-source/helper/cause/input qualification for the declared finite cohort."""
import copy,hashlib,json,re,subprocess,sys
from pathlib import Path
B=Path(__file__).parent
REVISION='21f4887c6ee4bf34efd37f35b6a400052008c4f3'
enc=lambda x:json.dumps(x,sort_keys=True,separators=(',',':'))
def blob(path):return subprocess.check_output(['git','show',REVISION+':'+str(path)])
def seal(path,committed=True):
    p=path/'manifest.json'
    if committed:assert p.read_bytes()==blob(p)
    m=json.loads(p.read_text());members=m.get('files',m.get('members'))
    assert set(members)=={str(p.relative_to(path)) for p in path.rglob('*') if p.is_file() and p.name!='manifest.json'}
    for name,row in members.items():
        raw=(path/name).read_bytes();assert enc(row)==enc({'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()})
if (B/'manifest.json').exists():seal(B,False)
prior=Path('docs/audits/local-formal-diagnostic-correction-20261002');seal(prior)
# Whole semantic products have not changed in this diagnostic-only slice.
# Their original source/literal/kind proof remains scoped, not a fresh universal
# formal/native signoff. Error trace coordinates are separately observed.
ordinary=['select','min','max','cond','when-bit','unless-bit','when-field','unless-field','authored','nested','local','calls','first_authored_sample','first_macro_sample']
for name in ordinary:
    value=json.loads((B/'products'/(name+'.json')).read_text());previous=json.loads(blob(prior/'current-bound'/(name+'.json')))
    for key in ('source','context','proof','literal_clauses','literal_operations'):assert enc(value[key])==enc(previous[key]),(name,key)
    assert len(value['controls'])==8
    for control in value['controls']:
        assert enc(control['accepted'])==enc(0)
        assert control['error'].splitlines()[0] in ('local formal origin context differs from authoritative source','local formal origin proof differs from authoritative source')
        counterpart=next(r for r in previous['controls'] if r['kind']==control['kind'])
        for key in ('kind','context','proof','accepted'):assert enc(control[key])==enc(counterpart[key]),(name,key)
for name in ('siblings','decline_cond','decline_first'):
    value=json.loads((B/'products'/(name+'.json')).read_text());previous=json.loads(blob(prior/'current-bound'/(name+'.json')))
    for key in set(value)-{'canonical_error','observed_error'}:assert enc(value[key])==enc(previous[key]),(name,key)
bind=json.loads((B/'bindings.json').read_text());source=blob('t/2052-isf-local-formal-origin-authority.t').decode()
assert set(bind)=={'baseline','helper','packages','callers','all_source_metadata','sources','scope'}
assert bind['baseline']==REVISION
assert set(bind['sources'])=={'t/2052-isf-local-formal-origin-authority.t','t/lib/FSM/Test/LocalFormalOriginAuthority.pm','t/lib/FSM/Test/ConditionalOriginAuthority.pm','t/lib/FSM/Test/ConditionalOriginParser.pm','perl/FSM/Adapter/ISF/Parser.pm','perl/FSM/Scheduler/ISF/FormalLowering.pm','perl/FSM/Scheduler/ISF/FormalClauseResolver.pm','perl/FSM/Scheduler/ISF/LoweringIR.pm'}
names=subprocess.check_output(['git','ls-tree','-r','--name-only',REVISION,'--','bin','perl','t','scripts']).decode().splitlines()
assert set(names)==set(bind['all_source_metadata'])
for path in names:
    raw=Path(path).read_bytes();assert enc(bind['all_source_metadata'][path])==enc({'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()}),path
# Independent Git hash-object comparison binds the full tracked source closure
# without treating an identical copied digest as re-derivation.
for path,raw in bind['sources'].items():assert raw.encode()==blob(path)==Path(path).read_bytes()
raw_hashes=subprocess.check_output(['git','hash-object','--stdin-paths'],input=('\n'.join(names)+'\n').encode()).decode().splitlines()
git_rows=subprocess.check_output(['git','ls-tree','-r',REVISION,'--','bin','perl','t','scripts']).decode().splitlines()
expected_hashes={row.split('\t',1)[1]:row.split()[2] for row in git_rows}
assert len(raw_hashes)==len(names)
for path,digest in zip(names,raw_hashes):assert digest==expected_hashes[path],path
assert bind['helper']==source[source.index('sub first_line {'):source.index('sub unrelated_refusal {')]
assert bind['packages']==source[source.index('package FSM::Test::LocalFormalOriginAuthority::DropClone;'):]
assert len(bind['callers'])==8
for row in bind['callers']:
    assert set(row)=={'path','line','offset','statement','pattern','name'}
    assert source.count(row['statement'])==1 and source[row['offset']:row['offset']+len(row['statement'])]==row['statement']
    assert enc(row['line'])==enc(source[:row['offset']].count('\n')+1)
    assert 'qr/'+row['pattern']+'/' in row['statement'] and row['name'] in row['statement']
positive_causes={'equal-body origin transplant':'local formal origin proof differs from authoritative source','actual clone callback lost':'local formal origin conditional clone association missing','actual Storable callback lost':'local formal origin conditional clone association missing','imported producer boundary':'conditional origin imported source authority is not qualified','actor network boundary':'local formal origin reusable/network scope is not qualified','generated transaction boundary':'local formal origin generated specialization is not qualified','domain constructor boundary':'local formal origin domain scope is not qualified','no formal preparation boundary':'local formal origin requires an unprojected direct formal'}
assert set(positive_causes)=={r['name'] for r in bind['callers']}
products={p.stem:json.loads(p.read_text()) for p in (B/'products').glob('*.json')}
assert set(products)==set(ordinary)|{'siblings','decline_cond','decline_first','diagnostic_echo'}|{re.sub(r'[^a-zA-Z0-9_-]','_',name) for name in positive_causes}
# Reconstruct complete positive API values independently from captured whole
# source products and declared fixture spelling, not the materializer's eval.
selected_source=products['select']['source'];header=selected_source.split('(transaction main ',1)[0]
ports=selected_source[len(header+'(transaction main '):selected_source.index(' (on start)')]
body='(transaction main '+ports+' (on start) (select result allow payload other) (complete done)))'
domain='(actor domains (clock-domains (domain core (clock clk) :default)) (interface (input start) (input allow) (input payload (width 3)) (input other (width 3)) (output result (width 3)) (output done))'+body
expected_inputs={'equal-body origin transplant':{'api':'validate','authority_source':selected_source,'authority_label':'select.isf','context':products['authored']['context'],'proof':products['authored']['proof']}}
for name,cls in (('actual clone callback lost','DropClone'),('actual Storable callback lost','DropStorable')):
    expected_inputs[name]={'api':'from_source','class':'FSM::Test::LocalFormalOriginAuthority::'+cls,'source':selected_source,'label':'select.isf'}
for name,source_value,label in (
    ('imported producer boundary','(library lib (actor worker (transaction run (wait 1))))'+header+'(imports (library lib as imported))'+body,'imports.isf'),
    ('actor network boundary',header+'(instance remote of external_worker)'+body,'network.isf'),
    ('generated transaction boundary',header+'(transaction worker (params (MODE 1)) (wait 1))'+'(transaction main '+ports+' (on start) (do worker (params (MODE 1))) (select result allow payload other) (complete done)))','generated.isf'),
    ('domain constructor boundary',domain,'domain.isf'),
    ('no formal preparation boundary',header+'(transaction main (on start) (select result allow payload other) (complete done)))','plain.isf')):
    expected_inputs[name]={'api':'from_source','class':'FSM::Test::LocalFormalOriginAuthority','source':source_value,'label':label}
positive_inputs=json.loads((B/'positive_inputs.json').read_text());assert enc(positive_inputs)==enc(expected_inputs)
data=json.loads((B/'causes.json').read_text());assert set(data)=={'rows'}
rows=data['rows'];expected_rows=[]
if '--extra-field-at-load' in sys.argv:rows[0]['extra_at_load']=1
assert len(rows)==32
for row in rows:assert set(row)=={'id','site','band','input','error','first_line','accepted','matched','expected','pattern','full_trace_matched'},'unexpected incoming cause field'
for caller in bind['callers']:
    identity=caller['name'];file=re.sub(r'[^a-zA-Z0-9_-]','_',identity);literal=caller['pattern'].replace('\\/','/')
    validator=identity=='equal-body origin transplant'
    bands=('positive','wrong_context','wrong_input_echo','wrong_input_plain') if validator else ('positive','wrong_source_plain','wrong_source_echo','wrong_label_echo')
    cls='FSM::Test::LocalFormalOriginAuthority::DropClone' if identity=='actual clone callback lost' else 'FSM::Test::LocalFormalOriginAuthority::DropStorable' if identity=='actual Storable callback lost' else 'FSM::Test::LocalFormalOriginAuthority'
    for band in bands:
        row=next(r for r in rows if r['id']==identity and r['band']==band)
        if band=='positive':
            expected_input={'capture':'products/'+file+'.json','statement':caller['statement'],'source_phase':'fresh current T2052 real producer capture'}
            assert row['error']==products[file]['error'] and row['first_line']==positive_causes[identity]
        elif validator:
            mutation={'path':['actor','name'],'value':'forged'} if band=='wrong_context' else {'path':['extra'],'perl_kind':'blessed_hash','class':literal if band=='wrong_input_echo' else 'unrelated_object','contents':{}}
            expected_input={'api':'validate','base_context':products['authored']['context'],'proof':products['authored']['proof'],'mutation':mutation}
            if band=='wrong_context':assert row['first_line']=='local formal origin context differs from authoritative source'
            else:
                prefix="encountered object '"+mutation['class']+'=HASH('
                assert row['first_line'].startswith(prefix)
                tail=row['first_line'][len(prefix):]
                assert re.fullmatch(r'0x[0-9a-f]+\)\', but neither allow_blessed, convert_blessed nor allow_tags settings are enabled \(or TO_JSON/FREEZE method missing\) at t/lib/FSM/Test/LocalFormalOriginAuthority[.]pm line 190[.]',tail)
        else:
            expected_input={'api':'from_source','class':cls,'source':'; '+literal+'\n(not_actor)' if band=='wrong_source_echo' else '(not_actor)','label':literal+'.isf' if band=='wrong_label_echo' else 'wrong.isf'}
            assert row['first_line']=="Error: no (actor ...) root found in '"+expected_input['label']+"'"
        expected={**row,'input':expected_input,'accepted':0,'expected':int(band=='positive'),'matched':int(band in ('positive','wrong_input_echo','wrong_label_echo')),'pattern':caller['pattern'],'site':caller['path']+':'+str(caller['line'])}
        assert row['first_line']==row['error'].split('\n',1)[0]
        expected_rows.append(expected)
def verify(candidate):assert enc(candidate)==enc(expected_rows),'closed cause/input/primitive-kind mismatch'
verify(rows)
replayed=json.loads(subprocess.check_output(['perl',str(B/'replay.pl')]))
assert enc(replayed)==enc([{key:r[key] for key in ('id','band','matched','full_trace_matched')} for r in rows])
if '--trust-current' in sys.argv:
    assert all(r['matched']==r['expected'] for r in rows),'actual current helper accepts unrelated primary causes'
for label in ('primary_cause','input_class','matched_kind','accepted_kind','missing_context','extra_field'):
    bad=copy.deepcopy(rows)
    if label=='primary_cause':bad[0]['first_line']='wrong cause'
    elif label=='input_class':next(r for r in bad if r['band']=='wrong_input_echo')['input']['mutation']['class']='unrelated_object'
    elif label=='matched_kind':bad[0]['matched']=True
    elif label=='accepted_kind':bad[0]['accepted']=False
    elif label=='missing_context':bad.pop()
    else:bad[0]['unknown']=1
    try:verify(bad)
    except AssertionError:print('shared cause corruption rejects:',label)
    else:raise AssertionError('accepted '+label)
print('Exact8 helper callers/32 real captured contexts:8 genuine positives and8 unrelated primary matches; complete selected products/kinds and current source/Git scope reconcile. Direct/trace/wider consumers remain open.')

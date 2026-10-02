"""Frozen source/product/cause re-derivation; no production or HDL execution."""
import copy, hashlib, json, re, runpy, subprocess, sys
from pathlib import Path
sys.dont_write_bytecode=True
B=Path(__file__).resolve().parent.relative_to(Path.cwd().resolve())
P=Path('docs/audits/source-origin-validator-causes-20261003')
enc=lambda x:json.dumps(x,sort_keys=True,separators=(',',':'),ensure_ascii=False)
sha=lambda x:hashlib.sha256(x).hexdigest()
changes=json.loads((B/'changes.json').read_text());revision=changes['baseline']
def blob(path):return subprocess.check_output(['git','show',revision+':'+str(path)])
def sealed(path):
    assert (path/'manifest.json').read_bytes()==blob(path/'manifest.json') if path!=B else True
    members=json.loads((path/'manifest.json').read_text())['files']
    assert set(members)=={str(p.relative_to(path)) for p in path.rglob('*') if p.is_file() and p.name!='manifest.json'}
    for name,row in members.items():
        raw=(path/name).read_bytes();assert enc(row)==enc({'bytes':len(raw),'sha256':sha(raw)})
if (B/'manifest.json').exists():sealed(B)
sealed(P);assert (P/'verify.py').read_bytes()==blob(P/'verify.py')
# This complete immutable diagnostic guard authenticates its Git/source/inputs
# and earlier independent source oracles. Its own deliberate hostile controls
# remain proof of that historical cohort, not current broad consumer signoff.
old=runpy.run_path(str(P/'verify.py'),run_name='frozen_validator_diagnosis')
assert enc(changes['old'])==enc({k:v['statement'] for k,v in old['bound']['sites'].items()})
before=json.loads((B/'before.json').read_text());after=json.loads((B/'after.json').read_text());assert enc(before)==enc(after)
changed={site.rsplit(':',1)[0] for site in changes['new']};added='t/2054-isf-validator-finalizer-diagnostic-causes.t'
names=subprocess.check_output(['git','ls-tree','-r','--name-only',revision,'--','bin','perl','t']).decode().splitlines();assert set(before)==set(names)|{added,str(B/'run.py')}
requests=''.join(revision+':'+p+'\n' for p in names).encode();raw=subprocess.check_output(['git','cat-file','--batch'],input=requests);offset=0
for name in names:
    end=raw.index(b'\n',offset);head=raw[offset:end].split();assert head[1]==b'blob';size=int(head[2]);data=raw[end+1:end+size+1];offset=end+size+2
    if name not in changed:assert sha(data)==before[name]
assert offset==len(raw)
for p in (B/'instruments').rglob('*'):
    if p.is_file():
        path=str(p.relative_to(B/'instruments'));assert sha(p.read_bytes())==before[path]
        if path!=added:
            source=p.read_text()
            for site,statement in changes['new'].items():
                if site.rsplit(':',1)[0]==path:assert source.count(statement)==1 and changes['old'][site] not in source
assert sha((B/'run.py').read_bytes())==before[str(B/'run.py')]
runtime=json.loads((B/'runtime.json').read_text())
assert runtime['baseline']==revision and enc(runtime['statuses'])==enc({'current':0,'prior':1})
assert runtime['current_command']==['prove','-Iperl','-It/lib',*[str(p.relative_to(B/'instruments')) for p in sorted((B/'instruments/t').glob('*.t')) if str(p.relative_to(B/'instruments'))!=added],added,'t/2049-pathsearch-module-origin.t']
assert runtime['prior_command']==['prove','-Iperl','-It/lib',added]
assert 'All tests successful.' in (B/'current.txt').read_text() and 'Files=7, Tests=231,' in (B/'current.txt').read_text()
assert 'Tests: 26 Failed: 25' in (B/'prior-consumers.txt').read_text() and 'Files=1, Tests=26,' in (B/'prior-consumers.txt').read_text()

def old_matches(rows,first=False):
    source=(P/'replay.pl').read_text()
    if first:source=source.replace('my $error=$r->{error};','my $error=(split /\\n/,$r->{error})[0];')
    return json.loads(subprocess.check_output(['perl','-e',source],input=enc({'sites':old['bound']['sites'],'products':rows}).encode()))

fields={'id','site','kind','wanted','expected','variant','band','payload','accepted','matched','error','first_line'}
def causes(candidate,prior=False):
    assert set(candidate)=={'contexts','products','original','documents','authorities'}
    assert enc(candidate['contexts'])==enc(old['data']['contexts'])
    rows=candidate['products'];assert len(rows)==83
    prior_results=old_matches(rows);first_results=old_matches(rows,True)
    projected=copy.deepcopy(candidate)
    for i,r in enumerate(rows):
        assert set(r)==fields
        assert type(r['matched']) is int and r['matched'] in (0,1)
        expected=prior_results[i] if prior else (1 if r['band']=='positive' else 0)
        assert r['matched']==expected
        projected['products'][i]['matched']=prior_results[i]
        projected['products'][i]['first_line_matched']=first_results[i]
    # Same exact independently authored causes, whole API input substitutions,
    # site/context membership, kinds and category/input-echo distinctions.
    old['causes'](projected)
    perl=r'''use JSON::PP;use FSM::Test::DiagnosticCause qw(diagnostic_cause_matches);
my$j=JSON::PP->new->canonical;my$r=$j->decode(do{local$/;<STDIN>});
print$j->encode([map{diagnostic_cause_matches($_->{error},$_->{expected})}@$r]);'''
    current=json.loads(subprocess.check_output(['perl','-I'+str(B/'instruments/t/lib'),'-e',perl],input=enc(rows).encode()))
    assert enc(current)==enc([1 if r['band']=='positive' else 0 for r in rows])
    if not prior:assert enc(current)==enc([r['matched'] for r in rows])
    for kind,scope in old['scopes'].items():
        label,docs,roots=candidate['documents'][kind]
        assert len(roots)==1 and re.fullmatch(r'\.artifacts/tmp/tests/[^/]+/'+kind,roots[0])
        wanted={roots[0]+'/'+Path(p).name:s for p,s in old['inputs'][kind]['product']['documents'].items()}
        assert label==roots[0]+'/authority-root.isf' and enc(docs)==enc(wanted)
        actor,proof=scope['expected_product'](old['inputs']['same']['product'],label,docs)
        result=candidate['authorities'][kind];assert set(result)=={'actor','proof','ordinary'}
        assert enc(result['actor'])==enc(actor)==enc(result['ordinary']) and enc(result['proof'])==enc(proof)

current=json.loads((B/'current/products.json').read_text());prior=json.loads((B/'prior/products.json').read_text())
causes(current);causes(prior,True)
if '--prior-consumer' in sys.argv:causes(prior)
for name in ('cause','flag_kind','flag_value','omission','source','site','unknown_row','whole_kind'):
    bad=copy.deepcopy(current)
    if name=='cause':bad['products'][0]['error']='wrong cause\n'+bad['products'][0]['error']
    elif name=='flag_kind':bad['products'][0]['matched']=True
    elif name=='flag_value':bad['products'][1]['matched']=1
    elif name=='omission':bad['products'].pop()
    elif name=='source':bad['products'][0]['payload']['source']+='\n'
    elif name=='site':bad['products'][0]['site']='t/2043-isf-conditional-origin-parser.t:174'
    elif name=='unknown_row':bad['products'][0]['unknown']=1
    else:
        for f in ('actor','ordinary'):bad['authorities']['library'][f]['interface']['inputs'][0]['width']='1'
    try:causes(bad)
    except AssertionError:print('shared current cause/product corruption rejects:',name)
    else:raise AssertionError('accepted '+name)

# Current complete original cohorts, through independently authored immutable
# whole source oracles only; historical live runtime/admission gates are excluded.
for archive,cohort in [('conditional-origin-authority-20261002','authority'),('conditional-origin-library-20261002','same'),('conditional-origin-atl-20261002','ATL')]:
    root=Path('docs/audits')/archive;sealed(root);assert (root/'verify.py').read_bytes()==blob(root/'verify.py')
    scope={};exec(compile((root/'verify.py').read_text().split('\nproducts = ',1)[0],str(root/'verify.py'),'exec'),scope)
    products={p.name:json.loads(p.read_text()) for p in (B/cohort).glob('*.json')};scope['verify_products'](products)
    if cohort in ('authority','ATL'):
        for p in products.values():
            for r in p.get('controls',[]):
                cause='actor' if r['name'] in ('actor_identity','actor_kind') else ('ledger' if cohort=='authority' else 'proof')
                assert r['diagnostic'].split('\n')[0]==('conditional origin '+cause+' differs from authoritative source' if cohort=='authority' else 'library origin '+cause+' differs from authoritative document set')
        if cohort=='ATL':
            for r in products['finalization.json']['controls']:
                assert r['diagnostic'].split('\n')[0]=='ATL origin final '+('resolved actor coverage' if r['name']=='coverage' else 'target or instance identity')+' differs'
    sample=copy.deepcopy(products);p=sample[next(iter(sample))]
    for field in ('actor','reconstructed_actor') if cohort=='authority' else ('ordinary','instrumented'):p[field]['interface']['inputs'][0]['width']='1'
    try:scope['verify_products'](sample)
    except AssertionError:print('complete cohort kind corruption rejects:',cohort)
    else:raise AssertionError('accepted cohort kind '+cohort)
root=Path('docs/audits/conditional-origin-parser-20261002');sealed(root);assert (root/'verify.py').read_bytes()==blob(root/'verify.py')
scope={'__file__':str(root/'verify.py')};exec(compile((root/'verify.py').read_text().split('\ndef main():',1)[0],str(root/'verify.py'),'exec'),scope)
products={p.stem:json.loads(p.read_text()) for p in (B/'parser').glob('*.json')};assert set(products)=={p.stem for p in (root/'current-corrected').glob('*.json')}
for name,p in products.items():scope['product'](name,p)
root=Path('docs/audits/library-origin-diagnostic-correction-20261002');sealed(root);assert (root/'verify.py').read_bytes()==blob(root/'verify.py')
scope={'__file__':str(root/'verify.py')};exec(compile((root/'verify.py').read_text().split('\nbands = {}',1)[0],str(root/'verify.py'),'exec'),scope)
products={p.name:json.loads(p.read_text()) for p in (B/'library').glob('*.json')};assert set(products)==scope['original_names']|{'boundaries.json','diagnostic-echo.json','diagnostic-label-echo.json'}
scope['oracle']({name:products[name] for name in scope['original_names']});scope['boundaries'](products['boundaries.json'])
for name in scope['scope']['names']:
    for r in products[name]['controls']:
        assert r['diagnostic'].split('\n')[0]=='library origin '+('actor' if r['name'] in ('actor_identity','actor_kind') else 'proof')+' differs from authoritative document set'
for r in products['finalization.json']['controls']:
    assert r['diagnostic'].split('\n')[0]=='library origin final use '+('coverage' if r['name']=='coverage' else 'target or identity')+' differs'
print('current complete causes reject actual prior echoes; whole parser/authority/same-source/library/ATL products and kinds re-derive; scoped runtime/source/fingerprints and hostile controls pass')

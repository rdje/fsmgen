"""Independent complete-cause/source delta and finite product models."""
import copy, hashlib, json, re, subprocess, sys
from pathlib import Path
B=Path(__file__).parent
OLD=Path('docs/audits/reusable-product-helper-causes-20261003')
REV='142da0b8cbb3d819dd69d34fe282f27f83f0f9c0'
TEST='t/1947-isf-formal-reusable-products.t'
NEW='t/2060-isf-reusable-diagnostic-causes.t'
def load(name):return json.loads((B/name).read_text())
def same(a,b):
    assert json.dumps(a,sort_keys=True,separators=(',',':'))==json.dumps(b,sort_keys=True,separators=(',',':')),'value/kind/field mismatch'
def source(path):return subprocess.check_output(['git','show',REV+':'+path]).decode()
test=source(TEST)
mixed=re.search(r"my \$mixed = <<'ISF';\n(.*?)\nISF",test,re.S)[1]+'\n'
atl=source('isf/atl_resolved_child_pipeline.isf')
width_source=mixed.replace('(transaction worker','(storage (var payload (width 8))) (transaction worker')
exec(compile((B/'models.py').read_text(),str(B/'models.py'),'exec'))
binding=load('bindings.json')
assert set(binding)=={'baseline','metadata','sources'} and binding['baseline']==REV
paths=subprocess.check_output(['git','ls-tree','-r','--name-only',REV,'--','bin','perl','t','scripts','isf']).decode().splitlines()
assert set(binding['metadata'])==set(paths)|{NEW}
for path,row in binding['metadata'].items():
    raw=Path(path).read_bytes();same(row,{'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()})
unchanged=[p for p in paths if p!=TEST]
hashes=subprocess.check_output(['git','hash-object','--stdin-paths'],input=('\n'.join(unchanged)+'\n').encode()).decode().splitlines()
gitrows=subprocess.check_output(['git','ls-tree','-r',REV,'--','bin','perl','t','scripts','isf']).decode().splitlines()
wanted_hashes={r.split('\t',1)[1]:r.split()[2] for r in gitrows}
for p,h in zip(unchanged,hashes):assert h==wanted_hashes[p]
for p,body in binding['sources'].items():assert body==Path(p).read_text()
expected=test.replace('use FSM::Test::SourceQueryRunner;','use FSM::Test::SourceQueryRunner;\nuse FSM::Test::DiagnosticCause qw(diagnostic_cause_matches);')
expected=expected.replace('my ($actor, $pattern, $label) = @_;','my ($actor, $expected_cause, $label) = @_;')
expected=expected.replace('my $ok = eval {$l->$method(dclone($actor)); 1};','my $ok = eval {$l->$method(dclone($actor)); 1};\n        my $error = $@;')
expected=expected.replace('like($@, $pattern, "$label canonical diagnosis in $method");','ok(diagnostic_cause_matches($error, $expected_cause), "$label canonical diagnosis in $method")\n            or diag($error);')
before_direct="""eval {$l->build_module($a)};
    like($@, qr/(?:width|Width).*payload|payload.*(?:width|Width)/s, 'real parent still refuses raw conflicting declarations');"""
after_direct="""my $width_ok = eval {$l->build_module($a); 1};
    my $width_error = $@;
    ok(!$width_ok, 'real parent still refuses raw conflicting declarations');
    ok(diagnostic_cause_matches($width_error,
        "signal width for 'payload' conflicts across transactions while merging 'main'"),
        'raw parent conflict retains complete width cause') or diag($width_error);"""
assert before_direct in expected;expected=expected.replace(before_direct,after_direct)
replacements=[
("""refused($missing, qr/missing a generated module name/, 'missing library module');""",
 """refused($missing, "Library use 'rx' is missing a generated module name", 'missing library module');"""),
("""refused($collision, qr/conflicts with another generated child/, 'library versus generated module collision');""",
 """refused($collision, "Library use 'rx' generated module 'worker' conflicts with another generated child",
        'library versus generated module collision');"""),
("""refused($broken, qr/does not carry a reusable actor shell/, 'missing library actor');""",
 """refused($broken, "Library use 'rx' does not carry a reusable actor shell", 'missing library actor');"""),
("""refused($missing_atl, qr/missing a generated module name/, 'missing resolved ATL module');""",
 """refused($missing_atl, "ATL static actor instance 'worker' is missing a generated module name",
        'missing resolved ATL module');"""),
("""refused($groups, qr/cannot combine generated child wiring with static group metadata/, 'unsupported ATL group composition');""",
 """refused($groups, "ATL generated top for actor 'atl_resolved_child_pipeline' "
        . "cannot combine generated child wiring with static group metadata in the current subset",
        'unsupported ATL group composition');"""),
]
for before,after in replacements:
    assert before in expected;expected=expected.replace(before,after)
assert expected==binding['sources'][TEST]
prior_script=(OLD/'probe.pl').read_text().replace('reusable-product-helper-causes-20261003','reusable-cause-repair-20261003').replace("open my $fh,'<:raw','t/1947-isf-formal-reusable-products.t' or die $!;","open my $fh,'-|','git','show','142da0b8cbb3d819dd69d34fe282f27f83f0f9c0:t/1947-isf-formal-reusable-products.t' or die $!;").replace('"$base/causes.json"','"$base/prior-causes.json"')
assert prior_script==(B/'prior.pl').read_text()
prior=load('prior-causes.json');verify_rows(prior)
old=json.loads((OLD/'causes.json').read_text())
same([{k:v for k,v in r.items() if k!='error'} for r in prior['rows']],
     [{k:v for k,v in r.items() if k!='error'} for r in old['rows']])
reasons={ident:cause for ident,wanted,kind,cause in ids}
reasons['raw parent width conflict']="signal width for 'payload' conflicts across transactions while merging 'main'"
def verify_current(data):
    assert set(data)=={'rows'} and len(data['rows'])==33
    for row,original in zip(data['rows'],prior['rows']):
        assert set(row)=={'id','band','method','source','actor','expected_cause','error','assertions'}
        same([row[k] for k in ('id','band','method','source')],
             [original[k] for k in ('id','band','method','source')])
        same(row['actor'],original['actor_before'])
        same(row['expected_cause'],reasons[original['id']])
        assert row['error'].splitlines()[0]==original['error'].splitlines()[0]
        assert "\teval '" not in row['error']
        same(row['assertions'],[1,int(original['band']=='current_fixture')])
current=load('current-causes.json');verify_current(current)
replay=json.loads(subprocess.check_output(['perl',str(B/'replay.pl')]))
same(replay,[int(r['band']=='current_fixture') for r in current['rows']])
if '--trust-prior' in sys.argv:
    assert all(r['matched']==int(r['band']=='current_fixture') for r in prior['rows']),'exact prior accepts twenty helper and one direct wrong causes'
products=load('products.json');before_products=load('before-products.json')
verify_products(products);verify_products(before_products);same(products,before_products)
bypass=load('bypass-inputs.json')
assert set(bypass)=={'rows'} and len(bypass['rows'])==2
collision=next(r for r in prior['rows'] if r['id']=='library versus generated module collision' and r['band']=='current_fixture')
for row,method in zip(bypass['rows'],('prepare_formal_source','build_module')):
    assert set(row)=={'method','source','original','actor','accepted','error','result'}
    same([row['method'],row['source'],row['original']],[method,collision['source'],collision['actor_before']])
    same(row['actor'],row['original']);same([row['accepted'],row['error']],[1,''])
    assert set(row['result'])==(prepkeys if method=='prepare_formal_source' else modulekeys|{'child_completion_products'})
if '--trust-bypass' in sys.argv:
    assert all(r['accepted']==0 for r in bypass['rows']),'actual collision guard bypass admits invalid namespace inputs'
for label in ('cause','source','kind','actor','field','member'):
    bad=copy.deepcopy(current)
    if label=='cause':bad['rows'][0]['error']='wrong cause\n'
    elif label=='source':bad['rows'][0]['source']='(not_actor)'
    elif label=='kind':bad['rows'][0]['assertions'][1]=True
    elif label=='actor':bad['rows'][0]['actor']['transactions'][-1]['ports']['inputs'][0]['width']=4.0
    elif label=='field':bad['rows'][0]['unknown']=1
    else:bad['rows'].pop()
    try:verify_current(bad)
    except AssertionError:print('cause corruption rejects:',label)
    else:raise AssertionError('accepted '+label)
for label in ('origin','kind','field'):
    bad=copy.deepcopy(products)
    if label=='origin':bad['rows'][0]['prepared']['reusable_child_products']['children']['fifo_library_use__u_fifo']['library_origin']['instance']='wrong'
    elif label=='kind':bad['rows'][0]['input_equal']=True
    else:bad['rows'][0]['module']['unknown']=1
    try:verify_products(bad)
    except AssertionError:print('whole corruption rejects:',label)
    else:raise AssertionError('accepted '+label)
assert (B/'current.status').read_text()=='0\n' and 'Files=2, Tests=102' in (B/'current.txt').read_text()
assert (B/'prior-red.status').read_text()=='22\n' and 'failed 22 tests of 132' in (B/'prior-red.txt').read_text()
assert (B/'bypass-red.status').read_text()=='1\n' and 'failed 4 tests of 21' in (B/'bypass-red.txt').read_text() and 'failed 1 test of 3' in (B/'bypass-red.txt').read_text()
assert (B/'ordinary.status').read_text()==(B/'before-ordinary.status').read_text()=='0\n'
if (B/'manifest.json').exists():
    members=load('manifest.json')['members']
    assert set(members)=={str(p.relative_to(B)) for p in B.rglob('*') if p.is_file() and p.name!='manifest.json'}
    for name,row in members.items():
        raw=(B/name).read_bytes();same(row,{'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()})
print('PASS complete current causes, exact prior/bypass failures, whole ordinary conservation and finite models; FIFO test-copy kinds and wider internals remain owned.')

"""Independent current/prior/bypass models with explicit wider semantic limits."""
import copy,hashlib,json,re,subprocess,sys
from pathlib import Path
B=Path(__file__).parent
OLD=Path('docs/audits/formal-resource-helper-causes-20261003')
REV='0dd4aea7ae402cf57ac3924e8d443a3d9b6b8749'
def load(p):return json.loads(p.read_text())
exec(compile((B/'models.py').read_text(),str(B/'models.py'),'exec'))
bind=load(B/'bindings.json');assert set(bind)=={'baseline','metadata','sources'} and bind['baseline']==REV
paths=subprocess.check_output(['git','ls-tree','-r','--name-only',REV,'--','bin','perl','t','scripts']).decode().splitlines()
changed='t/1944-isf-formal-resource-products.t';new='t/2058-isf-formal-resource-diagnostic-causes.t'
assert set(bind['metadata'])==set(paths)|{new}
for p,row in bind['metadata'].items():
 raw=Path(p).read_bytes();same(row,{'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()})
for p,body in bind['sources'].items():assert body.encode()==Path(p).read_bytes()
unchanged=[p for p in paths if p!=changed]
actual=subprocess.check_output(['git','hash-object','--stdin-paths'],input=('\n'.join(unchanged)+'\n').encode()).decode().splitlines()
gitrows=subprocess.check_output(['git','ls-tree','-r',REV,'--','bin','perl','t','scripts']).decode().splitlines();expected={r.split('\t',1)[1]:r.split()[2] for r in gitrows};assert len(actual)==len(unchanged)
for p,h in zip(unchanged,actual):assert h==expected[p]
# Complete independent source delta: predicates save actual errors and all
# authored fixture, projection, admission and ordinary checks remain intact.
test=subprocess.check_output(['git','show',REV+':'+changed]).decode()
test=test.replace('use FSM::Test::SourceQueryRunner;','use FSM::Test::SourceQueryRunner;\nuse FSM::Test::DiagnosticCause qw(diagnostic_cause_matches);').replace('my ($actor, $pattern, $label) = @_;','my ($actor, $expected_cause, $label) = @_;').replace('my $ok = eval {$lowerer->build_module($actor); 1};','my $ok = eval {$lowerer->build_module($actor); 1};\n    my $error = $@;').replace('like($@, $pattern, "$label retains canonical diagnostic");','ok(diagnostic_cause_matches($error, $expected_cause), "$label retains canonical diagnostic")\n        or diag($error);')
collision=json.dumps(reasons['raw formal alias'].replace(HELPER,'$helper'))
test=test.replace('qr/isf_resource_round_robin_pointer_collision/',collision).replace('my $pattern;','my $expected_cause;').replace('$pattern =','$expected_cause =').replace('rejected($bad, $pattern, $kind);','rejected($bad, $expected_cause, $kind);')
for ident,code,mutation in cases:
 if ident in ('unknown_user','overlap','unsupported kind'):test=test.replace('qr/'+code+'/',json.dumps(reasons[ident]))
name=json.dumps(reasons['malformed name'])
before='''eval {$lowerer->prepare_formal_source($bad_name)};
    like($@, qr/isf_resource_round_robin_name_shape/, 'shared declaration producer rejects malformed generated name');'''
after='''my $bad_name_ok = eval {$lowerer->prepare_formal_source($bad_name); 1};
    my $bad_name_error = $@;
    ok(!$bad_name_ok, 'shared declaration producer rejects malformed generated name');
    ok(diagnostic_cause_matches($bad_name_error, '''+name+'''),
        'shared declaration producer retains complete malformed-name cause') or diag($bad_name_error);'''
assert before in test;test=test.replace(before,after).replace('qr/isf_resource_round_robin_name_shape/',name)
def wrap(m):
 full=m[1];head,body=full.split(': ',1);code,resource=head.split(' on resource ',1)
 return '"'+code+' "\n                . "on resource '+resource+': "\n                . "'+body+'"'
test=re.sub(r'"(ISF resource arbitration \'[^\']+\' on resource \'[^\']+\': [^"\n]+)"',wrap,test)
assert test==bind['sources'][changed]==Path(changed).read_text(),'whole T1944 delta mismatch'
assert bind['sources'][new]==Path(new).read_text()
# Exact prior instruments differ only in immutable source-read/output adapters.
prior_helper=(OLD/'probe.pl').read_text().replace('formal-resource-helper-causes-20261003','formal-resource-cause-repair-20261003').replace("open my $fh,'<:raw','t/1944-isf-formal-resource-products.t' or die $!;","open my $fh,'-|','git','show','0dd4aea7ae402cf57ac3924e8d443a3d9b6b8749:t/1944-isf-formal-resource-products.t' or die $!;").replace('"$base/causes.json"','"$base/prior-helper-causes.json"')
assert prior_helper==(B/'prior_helper.pl').read_text()
prior_direct=(OLD/'direct.pl').read_text().replace('formal-resource-helper-causes-20261003','formal-resource-cause-repair-20261003').replace('"$base/causes.json"','"$base/prior-helper-causes.json"').replace("open $fh,'<:raw','t/1944-isf-formal-resource-products.t' or die $!;","open $fh,'-|','git','show','0dd4aea7ae402cf57ac3924e8d443a3d9b6b8749:t/1944-isf-formal-resource-products.t' or die $!;").replace('"$base/direct-causes.json"','"$base/prior-direct-causes.json"')
assert prior_direct==(B/'prior_direct.pl').read_text()
ph=load(B/'prior-helper-causes.json');pd=load(B/'prior-direct-causes.json');verify_rows(ph);verify_direct(pd)
for data,old in [(ph,load(OLD/'causes.json')),(pd,load(OLD/'direct-causes.json'))]:
 same([{k:v for k,v in r.items() if k!='error'} for r in data['rows']],[{k:v for k,v in r.items() if k!='error'} for r in old['rows']])
def verify_current(data):
 assert set(data)=={'rows'} and len(data['rows'])==21
 wanted=[('helper',ident,band,code) for ident,code,mutation in cases for band in ('current_fixture','wrong_body','primary_body_echo')]+[('direct','malformed name',band,'isf_resource_round_robin_name_shape') for band in ('current_fixture','wrong_body','primary_body_echo')]
 for r,(consumer,ident,band,code) in zip(data['rows'],wanted):
  assert set(r)=={'consumer','id','band','source','actor','expected_cause','error','assertions'}
  same([r['consumer'],r['id'],r['band'],r['source'],r['expected_cause']],[consumer,ident,band,source('rule_slot',3,HELPER if ident=='raw formal alias' else 'payload'),reasons[ident]]);same(r['actor'],submitted(ident,band,code));assert r['error'].splitlines()[0]==cause(ident,band,code);same(r['assertions'],[1,int(band=='current_fixture')])
  assert "\teval '" not in r['error'],'active consumer-string eval contaminates runtime'
current=load(B/'current-causes.json');verify_current(current)
same(json.loads(subprocess.check_output(['perl',str(B/'replay.pl')])),[r['assertions'][1] for r in current['rows']])
if '--prior-helper' in sys.argv:assert all(r['matched']==int(r['band']=='current_fixture') for r in ph['rows']),'real prior helper accepts twelve wrong causes'
if '--prior-direct' in sys.argv:assert all(r['matched']==int(r['band']=='current_fixture') for r in pd['rows']),'real prior direct assertion accepts a primary code echo'
bypass=load(B/'bypass-input.json');assert set(bypass)=={'source','actor','module','accepted','error','unchanged'}
same(bypass['source'],source('rule_slot',3,HELPER));same(bypass['actor'],submitted('raw formal alias','current_fixture','isf_resource_round_robin_pointer_collision'));same([bypass['accepted'],bypass['error'],bypass['unchanged']],[1,'',1]);assert set(bypass['module'])==modulekeys
# The real bypass reuses the authored four-bit counter: _register_counter_width
# retains max(existing4,potential2), then arbitration overwrites its role.
same(bypass['module']['counters'][HELPER],4);same(bypass['module']['storage_roles'][HELPER],'resource_round_robin_pointer')
if '--resource-bypass' in sys.argv:assert bypass['accepted']==0,'real bypass admits conflicting raw formal/pointer identity'
products=load(B/'products.json');verify_products(products);same(products,load(OLD/'products.json'))
for label in ('cause','source','expectation','kind','field','member'):
 bad=copy.deepcopy(current)
 if label=='cause':bad['rows'][0]['error']='wrong cause\n'
 elif label=='source':bad['rows'][0]['source']='(not_actor)'
 elif label=='expectation':bad['rows'][0]['expected_cause']='wrong expectation'
 elif label=='kind':bad['rows'][0]['assertions'][1]=True
 elif label=='field':bad['rows'][0]['unknown']=1
 else:bad['rows'].pop()
 try:verify_current(bad)
 except AssertionError:print('shared corruption rejects:',label)
 else:raise AssertionError('accepted '+label)
for label in ('whole_kind','whole_pointer','whole_field'):
 bad=copy.deepcopy(products)
 if label=='whole_kind':bad['rows'][0]['prepared']['resource_signal_products'][0]['declaration']['width']=2.0
 elif label=='whole_pointer':bad['rows'][0]['module']['storage_roles'][HELPER]='forged'
 else:bad['rows'][0]['module']['unknown']=1
 try:verify_products(bad)
 except AssertionError:print('whole corruption rejects:',label)
 else:raise AssertionError('accepted '+label)
assert (B/'current.status').read_text()=='0\n' and 'Files=2, Tests=66' in (B/'current.txt').read_text()
assert (B/'prior-helper-red.status').read_text()=='12\n' and 'failed 12 tests of 72' in (B/'prior-helper-red.txt').read_text()
assert (B/'prior-direct-red.status').read_text()=='2\n' and 'failed 2 tests of 9' in (B/'prior-direct-red.txt').read_text()
assert (B/'resource-bypass-red.status').read_text()=='2\n' and 'failed 2 tests of 3' in (B/'resource-bypass-red.txt').read_text()
assert (B/'ordinary.status').read_text()=='0\n'
if (B/'manifest.json').exists():
 m=load(B/'manifest.json')['members'];assert set(m)=={str(p.relative_to(B)) for p in B.rglob('*') if p.is_file() and p.name!='manifest.json'}
 for name,row in m.items():
  raw=(B/name).read_bytes();same(row,{'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()})
print('PASS current21 complete cause rows, exact prior helper/direct false matches, real guard bypass and full ordinary conservation; finite source/pointer/schema/kind proof, wider internals open.')

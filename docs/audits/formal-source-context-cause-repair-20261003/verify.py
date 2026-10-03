"""Finite helper/fixture repair; exact source delta and typed whole conservation."""
import copy,hashlib,json,subprocess,sys
from pathlib import Path
B=Path(__file__).parent
P=Path('docs/audits/formal-source-context-helper-causes-20261003')
REV='4ed8478c149cf632238dd120570756c96c717dcb'
enc=lambda x:json.dumps(x,sort_keys=True,separators=(',',':'))
def same(a,b):assert enc(a)==enc(b),'whole typed mismatch'
def load(p):return json.loads(p.read_text())
def blob(p):return subprocess.check_output(['git','show',REV+':'+str(p)])
def seal(p,committed=False):
 if not (p/'manifest.json').exists():return
 if committed:assert (p/'manifest.json').read_bytes()==blob(p/'manifest.json')
 rows=load(p/'manifest.json')['members'];assert set(rows)=={str(f.relative_to(p)) for f in p.rglob('*') if f.is_file() and f.name!='manifest.json'}
 for name,row in rows.items():
  raw=(p/name).read_bytes();same(row,{'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()})
seal(P,True);seal(B)
bind=load(B/'bindings.json');assert set(bind)=={'baseline','metadata','sources'} and bind['baseline']==REV
changed='t/1936-isf-formal-source-context.t';new='t/2056-isf-formal-source-context-diagnostic-causes.t'
paths=subprocess.check_output(['git','ls-tree','-r','--name-only',REV,'--','bin','perl','t','scripts']).decode().splitlines()
assert set(bind['metadata'])==set(paths)|{new}
for p,row in bind['metadata'].items():
 raw=Path(p).read_bytes();same(row,{'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()})
unchanged=[p for p in paths if p!=changed]
actual=subprocess.check_output(['git','hash-object','--stdin-paths'],input=('\n'.join(unchanged)+'\n').encode()).decode().splitlines()
gitrows=subprocess.check_output(['git','ls-tree','-r',REV,'--','bin','perl','t','scripts']).decode().splitlines();expected_hashes={r.split('\t',1)[1]:r.split()[2] for r in gitrows}
assert len(actual)==len(unchanged)
for p,h in zip(unchanged,actual):assert h==expected_hashes[p]
assert set(bind['sources'])=={changed,new,'t/lib/FSM/Test/DiagnosticCause.pm','perl/FSM/Scheduler/ISF/LoweringIR.pm','perl/FSM/Adapter/ISF.pm','perl/FSM/Adapter/ISF/Parser.pm','perl/FSM/Scheduler/ISF/FormalIdentityPlan.pm','perl/FSM/Scheduler/ISF/FormalClauseResolver.pm'}
for p,source in bind['sources'].items():assert source.encode()==Path(p).read_bytes()
old_rows=load(P/'causes.json')['rows']
inputs={r['id']:r['input'] for r in old_rows if r['band']=='current_fixture'}
causes={
 'static parameter boundary':"Transaction 'main': when-body nested repeat generated do bindings require static '(params ...)' overrides in the current nested generated blocking-do subset",
 'live binding':"Transaction 'main': repeat-body do target 'worker' binds unknown transaction port 'missing' on 'worker'",
 'malformed dead binding':"Transaction 'main': do target 'worker' bind entries must be '(input port expr [(timing snapshot|live)])' or '(output port signal)'",
 'unknown dead target':"Transaction 'main': do target 'absent' is not a declared transaction",
 'local option':"Transaction 'main': unsupported local option 'typo'",
 'wait operator':"Transaction 'main': runtime dynamic wait count expression '(bogus count)' must use a supported expression operator shape in transaction body",
 'nested local':"Transaction 'main': unsupported '(local ...)' clause in repeat body"}
inputs['static parameter boundary']=inputs['live binding']
corrected=inputs['live binding']
for before,after in [
 ('(do worker (bind','(do worker (params (COUNT 1)) (bind'),
 ('(transaction worker (ports (input data (width 4)))','(transaction worker (ports (input data (width 4))) (params (COUNT 1))')]:
 assert corrected.count(before)==1;corrected=corrected.replace(before,after)
inputs['live binding']=corrected;assert corrected==load(P/'corrected-live.json')['source']
# Exact old-to-new source reconstruction, including only declared readability changes.
source=blob(changed).decode()
def edit(before,after):
 global source
 assert source.count(before)==1,before;source=source.replace(before,after)
edit('use FSM::Test::ProjectDataLocality;','use FSM::Test::ProjectDataLocality;\nuse FSM::Test::DiagnosticCause qw(diagnostic_cause_matches);')
edit('my ($text, $pattern, $label) = @_;','my ($text, $expected, $label) = @_;')
edit('my $ok = eval {prepare($text); 1};\n    ok(!$ok,','my $ok = eval {prepare($text); 1};\n    my $error = $@;\n    ok(!$ok,')
edit('like($@, $pattern, "$label source diagnostic");','ok(diagnostic_cause_matches($error, $expected), "$label complete source cause");')
edit("    rejects($live, qr/unknown transaction port 'missing'/, 'same binding made live');",
'''    rejects($live,
        "'''+causes['static parameter boundary']+'''",
        'live bound repeat requires static parameter overrides');
    $live =~ s/\\(do worker \\(bind/(do worker (params (COUNT 1)) (bind/;
    $live =~ s/\\(transaction worker \\(ports \\(input data \\(width 4\\)\\)\\)/(transaction worker (ports (input data (width 4))) (params (COUNT 1))/;
    rejects($live,
        "'''+causes['live binding']+'''",
        'valid live activation checks binding endpoints');''')
for variable,identity,pattern,label in [
 ('malformed','malformed dead binding','bind.*(?:entries|input|requires)','malformed dead binding shape'),
 ('missing','unknown dead target','not a declared transaction','unknown dead target')]:
 edit('    rejects($'+variable+', qr/'+pattern+"/, '"+label+"');",'    rejects($'+variable+',\n        "'+causes[identity]+'",\n        \''+label+"');")
for before,after,identity,pattern in [
 ('(local scratch (width 4) (init 1))','(local scratch (width 4) (typo 1))','local option','unsupported local option'),
 ('(wait count)','(wait (bogus count))','wait operator','supported expression operator shape'),
 ('(repeat count (set value count))','(repeat count (local nested (width 4)))','nested local','unsupported.*local')]:
 edit("        ['"+before+"', '"+after+"', qr/"+pattern+'/],',"        [\n            '"+before+"',\n            '"+after+"',\n            \""+causes[identity]+'",\n        ],')
assert source==bind['sources'][changed]
current=load(B/'current-causes.json')
def verify_rows(data):
 assert set(data)=={'rows'} and len(data['rows'])==21
 desired=[(identity,band) for identity in causes for band in ('positive','wrong_parser','source_echo')]
 assert [(r['id'],r['band']) for r in data['rows']]==desired
 for r in data['rows']:
  assert set(r)=={'id','band','input','expected_cause','error','assertions'}
  identity,band=r['id'],r['band'];cause=causes[identity]
  assert r['expected_cause']==cause
  assert r['input']==(inputs[identity] if band=='positive' else '; '+cause+'\n(not_actor)' if band=='source_echo' else '(not_actor)')
  assert r['error'].splitlines()[0]==(cause if band=='positive' else "Error: no (actor ...) root found in 'source_context.isf'")
  same(r['assertions'],[1,int(band=='positive')])
verify_rows(current)
same(json.loads(subprocess.check_output(['perl',str(B/'replay.pl')])),[{k:r[k] for k in ('id','band')}|{'matched':r['assertions'][1]} for r in current['rows']])
# Whole observations conserve the immutable source-bound diagnosis, preserving kinds.
same(load(B/'products.json'),load(P/'products.json'))
for label in ('whole_kind','whole_guard','whole_field'):
 bad=copy.deepcopy(load(B/'products.json'))
 if label=='whole_kind':bad['direct']['prepared']['transactions']['main']['locals']['scratch']=True
 elif label=='whole_guard':
  bad['direct']['actor']['transactions'][0]['clauses'][5][1]='forged'
  bad['direct']['prepared']['actor']['transactions'][0]['clauses'][5][1]='forged'
 else:bad['direct']['prepared']['extra']=1
 try:same(bad,load(P/'products.json'))
 except AssertionError:print('whole corruption rejects:',label)
 else:raise AssertionError('accepted '+label)
prior=load(B/'prior/causes.json');assert set(prior)=={'rows'} and len(prior['rows'])==24
same([{k:r[k] for k in set(r)-{'error'}} for r in prior['rows']],[{k:r[k] for k in set(r)-{'error'}} for r in old_rows])
for r,o in zip(prior['rows'],old_rows):assert r['error'].splitlines()[0]==o['error'].splitlines()[0]
same(load(B/'prior/products.json'),load(P/'products.json'))
# Exact unchanged prior producer with only immutable-source/output adapters.
prior_source=blob(P/'probe.pl').decode().replace("my $base='docs/audits/formal-source-context-helper-causes-20261003';","my $base='docs/audits/formal-source-context-cause-repair-20261003/prior';")
prior_source=prior_source.replace("open my $fh,'<:raw','t/1936-isf-formal-source-context.t' or die $!;","open my $fh,'-|','git','show','4ed8478c149cf632238dd120570756c96c717dcb:t/1936-isf-formal-source-context.t' or die $!;")
assert prior_source==(B/'prior_probe.pl').read_text()
if '--prior-consumer' in sys.argv:assert all(r['matched']==r['primary_matched'] for r in prior['rows']),'actual prior consumer promotes unrelated primary causes'
bypass=load(B/'bypass-input.json');assert set(bypass)=={'source','actor','error','accepted','unchanged'}
same(bypass['source'],corrected);same(bypass['actor'],load(P/'corrected-live.json')['actor']);same(bypass['accepted'],0);same(bypass['unchanged'],1)
assert bypass['error'].splitlines()[0]=="Transaction 'worker': '(local bad ...)' requires a '(width N)' with a positive integer"
assert 'not ok 8 - valid live activation checks binding endpoints complete source cause' in (B/'binding-bypass-red.txt').read_text()
assert 'failed 1 test of 6' in (B/'binding-bypass-red.txt').read_text()
if '--binding-bypass' in sys.argv:assert bypass['error'].splitlines()[0]==causes['live binding'],'actual bypass reaches a different primary cause'
for label in ('cause','input','assertion_kind','expected','membership','extra_field'):
 bad=copy.deepcopy(current)
 if label=='cause':bad['rows'][0]['error']='wrong cause\n'
 elif label=='input':bad['rows'][0]['input']='(not_actor)'
 elif label=='assertion_kind':bad['rows'][0]['assertions'][0]=True
 elif label=='expected':bad['rows'][0]['expected_cause']='wrong reason'
 elif label=='membership':bad['rows'].pop()
 else:bad['rows'][0]['extra']=1
 try:verify_rows(bad)
 except AssertionError:print('shared corruption rejects:',label)
 else:raise AssertionError('accepted '+label)
for name,status in [('bind',0),('current',0),('ordinary',0),('prior-consumer-red',13),('binding-bypass-red',1)]:assert (B/(name+'.status')).read_text()==str(status)+'\n'
assert 'All tests successful.' in (B/'current.txt').read_text() and 'Files=2, Tests=48' in (B/'current.txt').read_text()
assert 'failed 13 tests of 76' in (B/'prior-consumer-red.txt').read_text()
print('PASS complete-cause current helper/seven contracts/21 real rows, valid live fixture and separate subset boundary, whole ordinary conservation, exact prior consumer and real binding bypass. Internal product semantics beyond prior scope remain open.')

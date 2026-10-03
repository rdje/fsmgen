"""Exact cause repair delta, native graph closure and scope conservation."""
import copy, hashlib, json, subprocess, sys
from pathlib import Path
B=Path(__file__).parent
OLD=Path('docs/audits/prepared-reservation-helper-causes-20261003')
REV='3a4bb6f69920418cb3c059e089d73930793ff856'
TEST='t/1959-isf-prepared-formal-reservations.t'
NEW='t/2062-isf-prepared-reservation-diagnostic-causes.t'
def load(name):return json.loads((B/name).read_text())
def same(a,b):
 assert json.dumps(a,sort_keys=True,separators=(',',':'))==json.dumps(b,sort_keys=True,separators=(',',':')),'value/kind/field mismatch'
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
wanted={r.split('\t',1)[1]:r.split()[2] for r in gitrows}
for p,h in zip(unchanged,hashes):assert h==wanted[p]
for p,body in binding['sources'].items():assert body==Path(p).read_text()
before=subprocess.check_output(['git','show',REV+':'+TEST]).decode()
expected=before.replace("use lib 'perl';","use lib 'perl', 't/lib';\nuse FSM::Test::DiagnosticCause qw(diagnostic_cause_matches);")
expected=expected.replace('my ($prepared, $pattern, $label) = @_;','my ($prepared, $expected_cause, $label) = @_;')
expected=expected.replace('my $ok = eval {collect($prepared); 1};','my $ok = eval {collect($prepared); 1};\n    my $error = $@;')
expected=expected.replace('like($@, $pattern, "$label has a focused diagnostic");','ok(diagnostic_cause_matches($error, $expected_cause), "$label has a focused diagnostic")\n        or diag($error);')
expected=expected.replace(r'qr/incomplete preparation.*missing: \Q$field\E/', '"Prepared formal reservations have incomplete preparation (missing: $field; unexpected: )"')
expected=expected.replace(r"qr/malformed preparation field '\Q$field\E'/", '"Prepared formal reservations have malformed preparation field \'$field\'"')
expected=expected.replace("qr/incomplete preparation/, 'missing nested producer'",'"Prepared formal reservations have incomplete preparation (missing: parent_completion_products; unexpected: )", \'missing nested producer\'')
replacements={pattern:cause for label,cause,pattern,direct in contracts if not direct and not label.startswith(('missing ','malformed '))}
for label,cause,pattern,direct in contracts[-9:]:replacements[pattern]=cause
replacements['incomplete preparation']=prefix+'have incomplete preparation (missing: actor; unexpected: )'
for pattern,cause in replacements.items():
 token='qr/'+pattern+'/'
 if token in expected:expected=expected.replace(token,'"'+cause+'"')
expected=expected.replace('my $ok = eval {collect($bad); 1};','my $ok = eval {collect($bad); 1};\n    my $error = $@;')
expected=expected.replace("like($@, qr/has a cycle/, 'cycle diagnostic retained');","""ok(diagnostic_cause_matches($error,
        "Formal reservation inventory has a cycle at '/actor_context/cycle'"),
        'cycle diagnostic retained') or diag($error);""")
assert expected==binding['sources'][TEST]
prior=json.loads((OLD/'causes.json').read_text())
current=load('current-causes.json')
def verify_current(data):
 assert set(data)=={'rows'} and len(data['rows'])==len(contracts)*3
 for index,(label,cause,pattern,direct) in enumerate(contracts):
  for offset,band in enumerate(('current_fixture','earlier_reference','primary_cause_echo')):
   row=data['rows'][index*3+offset];old=prior['rows'][index*3+offset]
   assert set(row)=={'label','direct','band','expected_cause','before','after','error','assertions'}
   same([row[k] for k in ('label','direct','band','expected_cause')],[label if direct else label+' has a focused diagnostic',int(direct),band,cause])
   same(row['before'],old['before']);same(row['after'],row['before'])
   assert row['error'].splitlines()[0]==old['error'].splitlines()[0] and "\teval '" not in row['error']
   same(row['assertions'],[1,int(band=='current_fixture')])
verify_current(current)
if '--trust-prior' in sys.argv:
 assert all(r['assertions'][1]==int(r['band']=='current_fixture') for r in prior['rows']),'exact prior accepts111 wrong causes'
api=load('current-api.json');old_api=json.loads((OLD/'default-api.json').read_text())
assert set(api)=={'rows'} and len(api['rows'])==64
for row,old in zip(api['rows'],old_api['rows']):
 assert set(row)=={'before','after','accepted','error','result'}
 same({k:v for k,v in row.items() if k!='error'},{k:v for k,v in old.items() if k!='error'})
 assert (row['error'].splitlines() or [''])[0]==(old['error'].splitlines() or [''])[0]
verify_successes([r for r in api['rows'] if r['accepted']])
bypass=load('bypass-inputs.json')
assert set(bypass)=={'rows'} and len(bypass['rows'])==2
for row,kind in zip(bypass['rows'],('missing_optional_category','unknown_producer')):
 assert set(row)=={'kind','original','before','after','accepted','error','result'}
 same(row['kind'],kind);same(row['original'],old_api['rows'][0]['before'])
 expected=copy.deepcopy(row['original'])
 if kind=='missing_optional_category':del expected['domain_partition']
 else:expected['new_producer_products']={}
 same(row['before'],expected);same(row['after'],expected);same([row['accepted'],row['error']],[1,''])
 same(row['result'],old_api['rows'][0]['result'])
if '--trust-bypass' in sys.argv:
 assert all(r['accepted']==0 for r in bypass['rows']),'actual checked membership bypass admits invalid schema'
for label in ('cause','graph-kind','marker','field','member','expected'):
 bad=copy.deepcopy(current)
 if label=='cause':bad['rows'][0]['error']='wrong cause\n'
 elif label=='graph-kind':bad['rows'][0]['before']['actor_context']['watchdog']=True
 elif label=='marker':bad['rows'][1]['before']['_early_reference']['$blessed']='WrongMarker'
 elif label=='field':bad['rows'][0]['unknown']=1
 elif label=='member':bad['rows'].pop()
 else:bad['rows'][0]['expected_cause']='wrong'
 try:verify_current(bad)
 except AssertionError:print('cause corruption rejects:',label)
 else:raise AssertionError('accepted '+label)
for label in ('scope','token','kind'):
 bad=copy.deepcopy([r for r in api['rows'] if r['accepted']])
 if label=='scope':bad[0]['result']['scopes'][0]['identity'][1]='wrong'
 elif label=='token':bad[0]['result']['reserved_names']['unexpected']=1
 else:bad[0]['result']['reserved_names']['start']=True
 try:verify_successes(bad)
 except AssertionError:print('whole corruption rejects:',label)
 else:raise AssertionError('accepted '+label)
assert (B/'current.status').read_text()=='0\n' and 'Files=2, Tests=526' in (B/'current.txt').read_text()
assert (B/'prior-red.status').read_text()=='111\n' and 'failed 111 tests of 519' in (B/'prior-red.txt').read_text()
assert (B/'bypass-red.status').read_text()=='2\n' and all(s in (B/'bypass-red.txt').read_text() for s in ('failed 24 tests of 146','failed 2 tests of 32','failed 2 tests of 4'))
assert (B/'ordinary.status').read_text()=='0\n'
if (B/'manifest.json').exists():
 members=load('manifest.json')['members']
 assert set(members)=={str(p.relative_to(B)) for p in B.rglob('*') if p.is_file() and p.name!='manifest.json'}
 for name,row in members.items():
  raw=(B/name).read_bytes();same(row,{'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()})
print('PASS complete cause repair/graph and ordinary scope conservation with exact prior/bypass failures; snapshots and wider semantics remain owned.')

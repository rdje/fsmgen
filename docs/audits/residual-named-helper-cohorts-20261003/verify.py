"""Independent immutable-Git/line/ownership closure; tokens are not callers."""
import copy,hashlib,json,re,subprocess,sys
from pathlib import Path
B=Path(__file__).parent
REV='e3febc5c29ac10887f0fedb308bebbe3ea7ab30f'
D='SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3'
P=D+'.1.2.3.2.3.3.'
def load(p):return json.loads(p.read_text())
def enc(x):return json.dumps(x,sort_keys=True,separators=(',',':'))
def same(a,b):assert enc(a)==enc(b),'whole typed mismatch'
prior=load(Path('docs/audits/named-helper-membership-20261003/membership.json'))
repair={1933:('.2.3.7','e3febc5c29ac10887f0fedb308bebbe3ea7ab30f'),1936:('.2.3.6','64628a4089349f7a23e333eef70584c30dc08dad'),2046:('.2.3.2','fe8c412afd02507cbdcdd4ca756ce5421af1aed7'),2048:('.2.3.2','fe8c412afd02507cbdcdd4ca756ce5421af1aed7'),2052:('.2.3.5','09c9dcbaea274020207dc0f4d8d6c43623dcae62')}
groups={'2':{1944,1947,1959,1960},'3':{1983,1986,1987,1988,1989,1990,1991,1993,1998,2021,2027,2028,2030,2035},'4':{1880,1883,1885},'5':{1832,1550,1638,1790},'7':{1543,1600,1656,1671,1731,1732,1733,1734,1735,1736,1737,1738,1739,1747,1816}}
scriptpaths={'perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm','perl/FSM/Support/ProcessSupervisor/Connection.pm','perl/FSM/Support/ProcessSupervisor/Service.pm','scripts/check_claim_verification.pl','scripts/check_task_tree_integrity.pl','scripts/run_vial_regression_promotion_budget_qualification.pl','scripts/run_vial_regression_promotion_gate.pl'}
def route(path):
 if path in scriptpaths:return P+'6','pending_actual_role_and_cause_review',None
 m=re.fullmatch(r't/(\d+)-[^/]+\.t',path);assert m;number=int(m[1])
 if number in repair:
  suffix,revision=repair[number];return D+suffix,'finite_repaired_owner_reference',revision
 matches=[key for key,numbers in groups.items() if number in numbers];assert len(matches)==1
 return P+matches[0],'pending_actual_role_and_cause_review',None
names=subprocess.check_output(['git','ls-tree','-r','--name-only',REV,'--','t','perl','scripts','bin']).decode().splitlines()
pipe=subprocess.Popen(['git','cat-file','--batch'],stdin=subprocess.PIPE,stdout=subprocess.PIPE)
raw={}
for path in names:
 pipe.stdin.write((REV+':'+path+'\n').encode());pipe.stdin.flush();header=pipe.stdout.readline().split();assert len(header)==3 and header[1]==b'blob'
 body=pipe.stdout.read(int(header[2]));assert pipe.stdout.read(1)==b'\n'
 if Path(path).suffix in ('.pl','.t','.pm') or (body.startswith(b'#!') and b'perl' in body.split(b'\n',1)[0]):raw[path]=body
pipe.stdin.close();pipe.stdout.close();assert pipe.wait()==0
for path,body in raw.items():assert Path(path).read_bytes()==body
expected=[]
for path,body in sorted(raw.items()):
 offset=0
 for number,line in enumerate(body.splitlines(keepends=True),1):
  m=re.match(rb'[ \t]*sub[ \t]+([A-Za-z_]\w*)\b',line)
  if m and m[1].decode().startswith(('refus','reject','fail','declin')):
   fn=m[1].decode();old=[r for r in prior['current_named_definition_tokens'] if (r['path'],r['function'])==(path,fn)];assert len(old)==1
   owner,qual,proof=route(path)
   if proof:assert body==subprocess.check_output(['git','show',proof+':'+path])
   identifiers=[{'offset':x.start(),'line':body[:x.start()].count(b'\n')+1} for x in re.finditer(rb'\b[A-Za-z_]\w*\b',body) if x[0].decode()==fn]
   expected.append({'path':path,'function':fn,'line':number,'offset':offset,'token':m[0].decode(),'prior_locator':old[0],'source_state':'unchanged' if body.decode()==prior['source_snapshots'][path] else 'changed','review_owner':owner,'qualification':qual,'evidence_revision':proof,'identifier_occurrences':identifiers})
  offset+=len(line)
assert {(r['path'],r['function']) for r in expected}=={(r['path'],r['function']) for r in prior['current_named_definition_tokens']}
sources={p:raw[p].decode() for p in sorted({r['path'] for r in expected})}
metadata={p:{'bytes':len(b),'sha256':hashlib.sha256(b).hexdigest()} for p,b in raw.items()}
contract={'baseline':REV,'prior_baseline':prior['baseline'],'metadata':metadata,'definitions':expected,'sources':sources,'scope':'line-anchored declarations and identifier occurrences only; pending role/caller/runtime/dynamic/framework/cause safety'}
def verify(data):same(data,contract)
data=load(B/'membership.json');verify(data)
owners=load(B/'owners.json');assert set(owners)=={'repaired','cohorts'}
want_repaired={};want_cohorts={k:[] for k in ('2','3','4','5','6','7')}
for path in sources:
 owner,qual,proof=route(path)
 if proof:want_repaired[path]={'suffix':owner[len(D):],'revision':proof}
 else:want_cohorts[owner[len(P):]].append(path)
same(owners['repaired'],want_repaired)
for key,paths in owners['cohorts'].items():assert len(paths)==len(set(paths));same(sorted(paths),sorted(want_cohorts[key]))
assert set(owners['cohorts'])==set(want_cohorts)
task=Path('docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md').read_text()
for r in expected:assert '- ID: `'+r['review_owner']+'`' in task
if '--trust-prior-sources' in sys.argv:assert all(s==prior['source_snapshots'][p] for p,s in sources.items()),'real prior source snapshots are stale for the repaired current helpers'
if '--trust-prior-row-owners' in sys.argv:assert all('review_owner' in r for r in prior['current_named_definition_tokens']),'real prior lexical declarations contain no exact row-specific cohort ownership'
for label in ('line_kind','offset_kind','owner','source','member','identifier','metadata','shape'):
 bad=copy.deepcopy(data)
 if label=='line_kind':bad['definitions'][0]['line']=True
 elif label=='offset_kind':bad['definitions'][0]['offset']=float(bad['definitions'][0]['offset'])
 elif label=='owner':bad['definitions'][0]['review_owner']=P+'2'
 elif label=='source':bad['sources'][next(iter(bad['sources']))]+='\n'
 elif label=='member':bad['definitions'].pop()
 elif label=='identifier':bad['definitions'][0]['identifier_occurrences'][0]['offset']+=1
 elif label=='metadata':bad['metadata'].pop(next(iter(bad['metadata'])))
 else:bad['unknown']=1
 try:verify(bad)
 except AssertionError:print('shared corruption rejects:',label)
 else:raise AssertionError('accepted '+label)
if (B/'manifest.json').exists():
 m=load(B/'manifest.json')['members'];assert set(m)=={str(p.relative_to(B)) for p in B.rglob('*') if p.is_file() and p.name!='manifest.json'}
 for name,row in m.items():
  b=(B/name).read_bytes();same(row,{'bytes':len(b),'sha256':hashlib.sha256(b).hexdigest()})
print('PASS complete current Git/byte/line/identifier/kind/owner closure:',len(expected),'declarations,',len(sources),'source files,',len(raw),'Perl files; no AST/caller/runtime/cause qualification.')

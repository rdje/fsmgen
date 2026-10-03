"""Current byte-defined declaration and explicit review ownership; no AST signoff."""
import hashlib,json,re,subprocess
from pathlib import Path
B=Path(__file__).parent
REV='e3febc5c29ac10887f0fedb308bebbe3ea7ab30f'
D='SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3'
assert subprocess.check_output(['git','rev-parse','HEAD']).decode().strip()==REV
prior=json.loads(Path('docs/audits/named-helper-membership-20261003/membership.json').read_text())
owners=json.loads((B/'owners.json').read_text())
route={}
for path,row in owners['repaired'].items():route[path]=(D+row['suffix'],'finite_repaired_owner_reference',row['revision'])
for number,paths in owners['cohorts'].items():
 for path in paths:
  assert path not in route;route[path]=(D+'.1.2.3.2.3.3.'+number,'pending_actual_role_and_cause_review',None)
paths=subprocess.check_output(['git','ls-tree','-r','--name-only',REV,'--','t','perl','scripts','bin']).decode().splitlines()
selected={}
for path in paths:
 raw=Path(path).read_bytes()
 if Path(path).suffix in ('.t','.pm','.pl') or re.match(rb'#![^\n]*perl',raw):selected[path]=raw
metadata={p:{'bytes':len(v),'sha256':hashlib.sha256(v).hexdigest()} for p,v in selected.items()}
rows=[]
for path,raw in sorted(selected.items()):
 for m in re.finditer(rb'(?m)^[ \t]*sub[ \t]+((?:refus|reject|fail|declin)\w*)\b',raw):
  fn=m[1].decode();old=[r for r in prior['current_named_definition_tokens'] if r['path']==path and r['function']==fn];assert len(old)==1
  owner,qual,proof=route[path]
  if proof:assert raw==subprocess.check_output(['git','show',proof+':'+path])
  rows.append({'path':path,'function':fn,'line':raw[:m.start()].count(b'\n')+1,'offset':m.start(),'token':m[0].decode(),'prior_locator':old[0],'source_state':'unchanged' if raw.decode()==prior['source_snapshots'][path] else 'changed','review_owner':owner,'qualification':qual,'evidence_revision':proof,'identifier_occurrences':[{'offset':x.start(),'line':raw[:x.start()].count(b'\n')+1} for x in re.finditer(rb'\b'+fn.encode()+rb'\b',raw)]})
assert set(route)=={r['path'] for r in rows}
snapshots={p:selected[p].decode() for p in sorted(route)}
(B/'membership.json').write_text(json.dumps({'baseline':REV,'prior_baseline':prior['baseline'],'metadata':metadata,'definitions':rows,'sources':snapshots,'scope':'line-anchored declarations and identifier occurrences only; pending role/caller/runtime/dynamic/framework/cause safety'},sort_keys=True,indent=2)+'\n')
print('Declared',len(rows),'current tokens across',len(snapshots),'whole source files; metadata',len(metadata),'Perl files. No runtime qualification.')

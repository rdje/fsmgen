import hashlib
import json
from pathlib import Path

p=Path('docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md')
s=p.read_text()
s=s.replace('Schedule directly after .5.1 and before .5.2 propagation.',
 'Qualify directly after .5.1; integrate only after .5.2 explicit source intent prevents newly unsafe first-sample admission.')
s=s.replace('Priority P2; repair is explicitly scheduled next after qualification.',
 'Priority P2; .5.4.1 qualifies the unsafe candidate and restores production, while .5.4.2 integration now requires .5.2 explicit source intent.')
p.write_text(s)

path='docs/book/src/13k-isf-feature-support-matrix.md'
line=next(line for line in Path(path).read_text().splitlines() if line.startswith('| Data manipulation |'))
new_id='published-'+hashlib.sha256((path+'\0'+' '.join(line.split())+'\0'+'1').encode()).hexdigest()[:24]
p=Path('doctrine/claim_verification/dispositions.jsonl')
rows=[json.loads(line) for line in p.read_text().splitlines()]
matches=[r for r in rows if r.get('candidate_id')=='published-416acfd411ceffb4341c876b']
assert len(matches)==1
row=matches[0]
assert row['owner_task']=='CLAIM-VERIFICATION-ADOPTION.5.3'
row['candidate_id']=new_id
test='t/2042-isf-procedure-cond-normalization.t'
row['durability']['watcher_paths'].append(test)
row['falsify']['oracle_paths'].append(test)
row['rederive']['evidence']+=' Complete inline procedure safety qualification observes the actual newly unsafe first-sample candidate admission and restored current refusal. Explicit source intent must precede normalization integration; production is unchanged.'
row['falsify']['evidence']+=' Independent actual first_samples branch oracle is genuine RED despite structural/full-transport classification passes. Literal source/kind/guard/capture and shared-corruption checks prevent parity-only admission signoff.'
rows=rows[:1]+sorted(rows[1:],key=lambda r:r['candidate_id'])
p.write_text(''.join(json.dumps(r,sort_keys=True,separators=(',',':'))+'\n' for r in rows))
print('Canonical general_book matrix identity',new_id)

source=Path('.artifacts/conditional-macro-intent/refresh_capacity.py').read_text()
source=source.replace('9bf0bd4c8af8c8aab5ab6865e66f6729d9583b3c','518d99d288b6b1cf4fd2f8f38518d684d37740a6')
source=source.replace('CONDITIONAL-MACRO-INTENT-20261002-','PROCEDURE-COND-SAFETY-20261002-')
source=source.replace('SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.1','SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.4.1')
source=source.replace('Qualify actual existing ISF/IAL1 conditional macro placement and inline procedure cond normalization boundaries with complete actual source/products/phase evidence. Synchronize entry versus branch, source-intent and local-call execution limitations in book/integration/feedback. No production, schema, output routing, immutable evidence, ceiling or store-identity change.',
 'Qualify unsafe new first-sample admission from a standalone inline-cond candidate and restore exact production. Synchronize explicit source-intent prerequisite before safe normalization, current refusal and call-site workaround in book/integration/feedback. No production, schema, routing, immutable evidence, ceiling or store-identity change.')
source=source.replace('.artifacts/conditional-macro-intent/capacity.json','.artifacts/procedure-cond-normalization/capacity.json')
Path('.artifacts/procedure-cond-normalization/refresh_capacity.py').write_text(source)

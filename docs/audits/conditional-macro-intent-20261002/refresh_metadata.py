import hashlib
import json
from pathlib import Path

path = 'docs/book/src/13k-isf-feature-support-matrix.md'
line = next(line for line in Path(path).read_text().splitlines() if line.startswith('| Data manipulation |'))
normalized = ' '.join(line.split())
new_id = 'published-' + hashlib.sha256((path+'\0'+normalized+'\0'+'1').encode()).hexdigest()[:24]
p=Path('doctrine/claim_verification/dispositions.jsonl')
rows=[json.loads(line) for line in p.read_text().splitlines()]
matches=[row for row in rows if row.get('candidate_id')=='published-de2ce8bd6c7f69a23a273a7c']
assert len(matches)==1
row=matches[0]
assert row['owner_task']=='CLAIM-VERIFICATION-ADOPTION.5.3'
row['candidate_id']=new_id
test='t/2041-isf-conditional-macro-intent-qualification.t'
row['durability']['watcher_paths'].append(test)
row['falsify']['oracle_paths'].append(test)
row['rederive']['evidence']+=' Complete current macro qualification preserves actual family/placement public phase contracts, including first sample-only activation misclassification and unexpanded inline cond. These are tracked existing ISF/IAL1 defects, not delivered macro support.'
row['falsify']['evidence']+=' Independent desired-intent producer is genuine RED for seven unsafe sample witnesses; fixed literal/source and shared-corruption controls reject parity-only signoff.'
rows=rows[:1]+sorted(rows[1:],key=lambda row: row['candidate_id'])
p.write_text(''.join(json.dumps(row,sort_keys=True,separators=(',',':'))+'\n' for row in rows))
print('Updated canonical general_book candidate',new_id)

source=Path('.artifacts/first-when-refresh.py').read_text()
source=source.replace('43dcfae199ca7d93a88fe047f886fdcc6522c2ec','9bf0bd4c8af8c8aab5ab6865e66f6729d9583b3c')
source=source.replace('FIRST-WHEN-ACTIVATION-BODY-20261002-','CONDITIONAL-MACRO-INTENT-20261002-')
source=source.replace('SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.3','SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.1')
source=source.replace('Close unsupported first-when activation action admission while preserving complete sample-entry/later-branch products. Synchronize actual phase refusals and first-operation macro/literal prerequisites in downstream/book/feedback. No public schema, output routing, immutable evidence, ceiling or store-identity change.',
 'Qualify actual existing ISF/IAL1 conditional macro placement and inline procedure cond normalization boundaries with complete actual source/products/phase evidence. Synchronize entry versus branch, source-intent and local-call execution limitations in book/integration/feedback. No production, schema, output routing, immutable evidence, ceiling or store-identity change.')
source=source.replace('.artifacts/first-when-capacity.json','.artifacts/conditional-macro-intent/capacity.json')
Path('.artifacts/conditional-macro-intent/refresh_capacity.py').write_text(source)

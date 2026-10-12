"""Development-only complete original source, meaning and contract interfaces."""
from parent_common import *
import interfaces

contracts = interfaces.contracts()
public = interfaces.public()
admitted = public['consumer_fact'].authenticate()
source = interfaces.source_contracts()
meaning = interfaces.meanings()
need(source['qualification']['assertions'] == 125 and meaning['qualification']['phase'] == 'complete independent meaning acceptance',
     'whole complete original source and meaning interfaces')
with interfaces.isolated_source() as (reader, controls):
    source_cases = [(label, status, cause) for label, mutate, status, cause in controls.CASES]
with interfaces.isolated_meaning() as (reader, controls):
    meaning_cases = [(label, status, cause) for label, mutate, status, cause in controls.CASES]
for rows in (source_cases, meaning_cases):
    need(rows[0] == ('positive', 0, None) and all(type(status) is int and status == 1 and type(cause) is str
         for _, status, cause in rows[1:]), 'complete original native control interfaces')
namespace = interfaces.namespace(PLAN['canonical_parent'])
name = PLAN['canonical_parent'] + '/proof.json'
canonical_proof = json.loads(fixed([name])[name])
need(canonical_proof['owner'] == PLAN['parent'] + '.3.3'
     and canonical_proof['qualification']['boundary'] == json.loads(fixed([PLAN['canonical_parent'] + '/plan.json'])[PLAN['canonical_parent'] + '/plan.json'])['condition'],
     'whole completed canonical acceptance proof boundary interface')
save('development-interfaces.json', dict(contracts=contracts, admission=admitted, source=source['qualification'],
    meanings=meaning['qualification'], source_cases=source_cases, meaning_cases=meaning_cases, canonical=pin(canonical(canonical_proof)),
    namespace=namespace, scope='Development-only original consumer interface; no formal parent or higher closure.'))
print('PASS development-only complete original source and meaning readers, canonical custody and unchanged descendant contracts.')

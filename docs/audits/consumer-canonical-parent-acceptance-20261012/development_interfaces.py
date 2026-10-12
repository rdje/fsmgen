"""Development-only source-bound interface probe; production is unchanged."""
from parent_common import *
import interfaces

contracts = interfaces.contracts()
public = interfaces.public()
admitted = public['consumer_fact'].authenticate()
meanings = interfaces.meanings()
need(meanings['qualification']['phase'] == 'complete independent meaning acceptance', 'whole original complete meaning interface')
with interfaces.isolated_meaning() as (reader, controls):
    declarations = [(label, status, cause) for label, mutate, status, cause in controls.CASES]
need(declarations[0] == ('positive', 0, None) and all(type(status) is int and status == 1 and type(cause) is str
     for _, status, cause in declarations[1:]), 'whole native original meaning control interface')
save('development-interfaces.json', dict(contracts=contracts, admission=admitted,
    meanings=meanings['qualification'], declarations=declarations,
    scope='Development interface only; no formal canonical acceptance or original consumer closure.'))
print('PASS development-only complete isolated original meaning, admission and unchanged contract interfaces.')

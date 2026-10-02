import json
from pathlib import Path
for name in ['first_when_bit_sample', 'first_cond_sample', 'later_cond_sample',
             'nested_select', 'initialized_select', 'later_generated_select', 'domain_later_select']:
    v=json.loads(Path('.artifacts/conditional-macro-intent/current/'+name+'.json').read_text())
    ir=v['private_ir']['children']['worker'] if name=='later_generated_select' else v['private_ir']
    print(name, 'keys', sorted(ir))
    for s in ir['states']:
        print(s['kind'], s.get('guard'), s.get('condition'), s.get('assignments'))

import json
from pathlib import Path
p=Path('.artifacts/procedure-cond-normalization/first-samples-candidate.json')
v=json.loads(p.read_text())
print('Loaded parser',v['loaded_parser'],v['loaded_parser_sha256'])
print('State kinds',[s['kind'] for s in v['private_ir']['states']])
print('Branches',sum(s['kind']=='branch' for s in v['private_ir']['states']))
for kind,q in v['queries'].items():
    print(kind,'native',q['native']['exit_code'],'API error',q['api'].get('error'),
          'isError',q['api'].get('result',{}).get('isError'),'wire',q['stdio']['exit_code'])

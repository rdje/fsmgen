import json
from pathlib import Path
BASE=Path(__file__).parent
result={}
for name,path in [('original-contract','interface-metadata-helper-contract-20261003/contracts.json'),('diagnostic-join','interface-metadata-diagnostic-join-20261004/join.json')]:
    result[name]=json.loads((Path('docs/audits')/path).read_text())
(BASE/'outcome.json').write_text(json.dumps(result,sort_keys=True,separators=(',',':'))+'\n')

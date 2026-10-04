"""Source/field/product member projection; independent semantic join required."""
import json
from pathlib import Path
BASE=Path(__file__).parent
join=json.loads(Path('docs/audits/interface-metadata-copy-join-20261004/join.json').read_text())
current=json.loads(Path('docs/audits/interface-metadata-copy-repair-20261004/ordinary.json').read_text())
rows={
 'original_width_fields':join['original_fields'],
 'current_private_source_fields':join['current_private_fields'],
 'copies':join['copies'],
 'cycle_copies':join['cycle_copies'],
 'accepted_products':[{'api':i,'kind':r['kind'],'before':r['before'],'result':r['result']} for i,r in enumerate(current['api']) if r['accepted']],
 'caller_causes':[{'api':i,'kind':r['kind'],'before':r['before'],'after':r['after'],'accepted':r['accepted'],'primary':r['error'].splitlines()[:1],'warnings':r['warnings']} for i,r in enumerate(current['api'])],
 'consumers':join['consumers'],
}
(BASE/'join.json').write_text(json.dumps(rows,indent=2,sort_keys=True)+'\n')

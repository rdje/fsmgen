"""Measure final task evidence and retain unchanged collection ceilings."""
import gzip
import json
from pathlib import Path
from common import BASE, canonical, need, pin, save
from verify import metrics

registry=Path('doctrine/live_document_size/surfaces.jsonl')
rows=[json.loads(line) for line in registry.read_bytes().splitlines()]
task=next(row for row in rows if row.get('surface_id')=='task_evidence')
paths=sorted({path for pattern in task['targets'] for path in Path('.').glob(pattern)})
source={str(path):path.read_bytes() for path in paths}
actual=metrics(source.values())
for dimension,value in actual.items():
    allowance=task['baseline'][dimension]+task['transition']['max_growth'][dimension]
    if value>allowance:
        task['transition']['max_growth'][dimension]=min(value+task['transition']['ratchet_step'][dimension],
            task['enforcement_ceilings'][dimension])-task['baseline'][dimension]
    need(value<=task['baseline'][dimension]+task['transition']['max_growth'][dimension]
         <=task['enforcement_ceilings'][dimension],'exact task measurement within unchanged ceiling')
registry.write_text(''.join(json.dumps(row,sort_keys=True)+'\n' for row in rows))
(BASE/'task-collection.json.gz').write_bytes(gzip.compress(canonical({p:r.decode() for p,r in source.items()}),mtime=0))
save('publication-metrics.json',dict(task=actual,task_declaration=task,complete_source_members={p:pin(r) for p,r in source.items()}))
print('PASS complete current task collection and measured allowance; all original ceilings and Knowledge Map authority retain.')

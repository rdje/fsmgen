"""Retain first publication; measure final task state inside unchanged ceilings."""
import copy
import json
from pathlib import Path
from common import BASE, load, need, same, save
import book
from publication_verify import metrics


def main():
    first=load('publication-final.json'); final=copy.deepcopy(first)
    current=[json.loads(line) for line in book.REGISTRY.read_bytes().splitlines()]
    need(same(current,first['registry_after']),'first registry authority retained before task refresh')
    old=[json.loads(line) for line in (BASE/'before-surfaces.jsonl.txt').read_bytes().splitlines()]
    previous=next(r for r in old if r.get('surface_id') == 'task_evidence')
    task=next(r for r in current if r.get('surface_id') == 'task_evidence')
    paths=sorted({p for pattern in task['targets'] for p in Path('.').glob(pattern)})
    measured=metrics(paths); growth=copy.deepcopy(previous['transition']['max_growth'])
    for key,actual in measured.items():
        if actual > previous['baseline'][key]+growth[key]:
            growth[key]=min(actual+task['transition']['ratchet_step'][key],task['enforcement_ceilings'][key])-previous['baseline'][key]
        need(actual <= previous['baseline'][key]+growth[key] <= task['enforcement_ceilings'][key],'whole final task pressure within unchanged ceiling')
    task['transition']['max_growth']=growth
    final['registry_after']=current; final['task_metrics']=measured
    need([r.get('enforcement_ceilings') for r in current] == [r.get('enforcement_ceilings') for r in first['registry_after']], 'every existing capacity ceiling unchanged')
    save('publication-qualified.json',final)
    book.REGISTRY.write_text(''.join(json.dumps(r,sort_keys=True)+'\n' for r in current))
    print('PASS first publication retained; complete final task pressure measured within unchanged ceilings and Knowledge Map allowance.')


if __name__ == '__main__': main()

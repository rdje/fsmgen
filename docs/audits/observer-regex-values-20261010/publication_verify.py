"""Conserve every prior surface and ceiling around the exact regex publication."""
import json
import sys
from pathlib import Path
from common import BASE, REVISION, load, need, pin, same, save
import book


def declaration(original,task):
    expected=json.loads(json.dumps(original))
    for dimension,actual in task['task'].items():
        need(type(actual) is int and actual>0,'typed complete task measurement')
        allowance=expected['baseline'][dimension]+expected['transition']['max_growth'][dimension]
        if actual>allowance:
            expected['transition']['max_growth'][dimension]=min(actual+expected['transition']['ratchet_step'][dimension],
                expected['enforcement_ceilings'][dimension])-expected['baseline'][dimension]
        need(actual<=expected['baseline'][dimension]+expected['transition']['max_growth'][dimension]
             <=expected['enforcement_ceilings'][dimension],'exact measured task growth inside unchanged ceiling')
    need(same(expected,task['task_declaration']),'entire exact measured task declaration')
    return expected


def main():
    need(sys.argv[1:] in ([],['--current']),'explicit dated versus current publication')
    before=[json.loads(line) for line in book.git('show',REVISION+':'+str(book.REGISTRY)).splitlines()]
    after=json.loads(json.dumps(before))
    report=load('book-publication.json')
    source_before,source_after=book.source()
    need(report['revision']==REVISION and report['addition']==book.ADDITION
         and report['before']=={k:pin(v) for k,v in source_before.items()}
         and report['after']=={k:pin(v) for k,v in source_after.items()},'entire sole owned book source change')
    a,b=book.aggregate(list(source_before.values())),book.aggregate(list(source_after.values()))
    authority=report['authority']
    need(authority['owner']==(BASE/'scope.txt').read_text().splitlines()[0]
         and authority['baseline']==a and authority['delta']=={k:b[k]-a[k] for k in a}
         and authority['authority_id']=='OBSERVER-REGEX-VALUES-20261010','whole exact fresh regex book authority')
    next(r for r in after if r.get('surface_id')=='shipped_behavior')['reference_contract']['aggregate_change']=authority
    task=load('publication-metrics.json')
    original=next(r for r in before if r.get('surface_id')=='task_evidence')
    expected=declaration(original,task)
    for index,row in enumerate(after):
        if row.get('surface_id')=='task_evidence':
            after[index]=expected
    need([r.get('enforcement_ceilings') for r in before]==[r.get('enforcement_ceilings') for r in after],
         'every prior capacity ceiling unchanged')
    first_proof=dict(before=pin(book.git('show',REVISION+':'+str(book.REGISTRY))),after=after,
        scope='No surface, capacity ceiling or Knowledge Map authority changes; sole exact book authority and measured task allowance only.')
    need(same(load('publication-proof.json'),first_proof),'whole immutable first publication proof')
    if (BASE/'publication-metrics-final.json').exists():
        task=load('publication-metrics-final.json')
        expected=declaration(original,task)
        for index,row in enumerate(after):
            if row.get('surface_id')=='task_evidence':
                after[index]=expected
    if sys.argv[1:]:
        need(after==[json.loads(line) for line in book.REGISTRY.read_bytes().splitlines()],
             'complete current registry and sole book/task authority changes')
        paths=sorted({p for pattern in expected['targets'] for p in Path('.').glob(pattern)})
        data=[p.read_bytes() for p in paths]
        measured=dict(files=len(data),lines_total=sum(x.count(b'\n') for x in data),bytes_total=sum(map(len,data)),
            lines_each=max(x.count(b'\n') for x in data),bytes_each=max(map(len,data)),
            line_bytes_each=max(len(line.rstrip(b'\r')) for x in data for line in x.split(b'\n')))
        need(measured==task['task'],'all actual current task dimensions')
        need({str(p):p.read_bytes() for p in Path('docs/book/src').glob('*.md')}==source_after,
             'whole current book source set and bytes')
    proof=dict(before=pin(book.git('show',REVISION+':'+str(book.REGISTRY))),after=after,
        scope='No surface, capacity ceiling or Knowledge Map authority changes; sole exact book authority and measured task allowance only.')
    if (BASE/'publication-proof-final.json').exists():
        need(same(load('publication-proof-final.json'),proof),'whole immutable final regex publication proof')
    else:
        save('publication-proof-final.json',proof)
    print('PASS complete regex publication authority, exact measured task allowance and unchanged prior surfaces/ceilings/Knowledge Map authority.')


if __name__ == '__main__':
    main()

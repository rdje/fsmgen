"""Independently conserve the complete book source set and every prior ceiling."""
import json
import subprocess
import sys
from pathlib import Path
from common import BASE, REVISION, canonical, load, need, pin, same, save
import book


def git(*args):
    actual=subprocess.run(['git','--no-replace-objects',*args],capture_output=True)
    need(actual.returncode==0 and actual.stderr==b'','complete fixed publication source custody')
    return actual.stdout


def aggregate(data):
    return dict(files=len(data),lines_total=sum(x.count(b'\n') for x in data),bytes_total=sum(map(len,data)))


def main():
    need(sys.argv[1:] in ([],['--current']),'explicit dated or current publication role')
    names=git('ls-tree','-r','--name-only',REVISION,'--','docs/book/src').decode().splitlines()
    before={name:git('show',REVISION+':'+name) for name in names
            if Path(name).parent==Path('docs/book/src') and name.endswith('.md')}
    after=dict(before)
    need(before[str(book.CHAPTER)].decode().count(book.ANCHOR)==1,'unique complete book publication seam')
    changed=before[str(book.CHAPTER)].decode()
    for prior,replacement in book.TRANSFORMS.items():
        need(changed.count(prior)==1,'unique whole owned source-status correction')
        changed=changed.replace(prior,replacement,1)
    after[str(book.CHAPTER)]=changed.replace(book.ANCHOR,book.ANCHOR+book.ADDITION,1).encode()
    report=load('book-publication.json')
    need(report['revision']==REVISION and report['addition']==book.ADDITION
         and report['before']=={k:pin(v) for k,v in before.items()}
         and report['after']=={k:pin(v) for k,v in after.items()},'whole sole observer-current guide change')
    original=[json.loads(line) for line in git('show',REVISION+':'+str(book.REGISTRY)).splitlines()]
    expected=json.loads(json.dumps(original))
    authority=report['authority'];a,b=aggregate(list(before.values())),aggregate(list(after.values()))
    need(authority['authority_id']=='OBSERVER-CURRENT-PUBLICATION-20261011'
         and authority['owner']==(BASE/'scope.txt').read_text().splitlines()[0]
         and authority['baseline']==a and authority['delta']=={k:b[k]-a[k] for k in a},'exact fresh book authority')
    next(r for r in expected if r.get('surface_id')=='shipped_behavior')['reference_contract']['aggregate_change']=authority
    metrics=load('publication-metrics.json')
    task=next(r for r in expected if r.get('surface_id')=='task_evidence')
    for dimension,value in metrics['task'].items():
        need(type(value) is int and value>0,'complete typed task measurement')
        allowance=task['baseline'][dimension]+task['transition']['max_growth'][dimension]
        if value>allowance:
            task['transition']['max_growth'][dimension]=min(value+task['transition']['ratchet_step'][dimension],
                task['enforcement_ceilings'][dimension])-task['baseline'][dimension]
        need(value<=task['baseline'][dimension]+task['transition']['max_growth'][dimension]
             <=task['enforcement_ceilings'][dimension],'measured task growth within unchanged ceiling')
    need(same(task,metrics['task_declaration']),'whole independently measured task declaration')
    need([r.get('enforcement_ceilings') for r in original]==[r.get('enforcement_ceilings') for r in expected],
         'every original capacity ceiling conserves')
    if sys.argv[1:]:
        need(expected==[json.loads(line) for line in book.REGISTRY.read_bytes().splitlines()],
             'every prior surface and Knowledge Map authority conserves')
        paths=sorted({p for pattern in task['targets'] for p in Path('.').glob(pattern)})
        data=[p.read_bytes() for p in paths]
        actual=dict(files=len(data),lines_total=sum(x.count(b'\n') for x in data),bytes_total=sum(map(len,data)),
            lines_each=max(x.count(b'\n') for x in data),bytes_each=max(map(len,data)),
            line_bytes_each=max(len(line.rstrip(b'\r')) for x in data for line in x.split(b'\n')))
        need(actual==metrics['task'],'complete actual current task dimensions')
        need({str(p):p.read_bytes() for p in Path('docs/book/src').glob('*.md')}==after,'complete current book source membership and bytes')
    proof=dict(before=pin(git('show',REVISION+':'+str(book.REGISTRY))),after=expected,
        scope='Sole exact book authority and measured task allowance; every prior surface/ceiling/Knowledge Map authority unchanged.')
    if (BASE/'publication-proof.json').exists():
        need(same(load('publication-proof.json'),proof),'whole immutable source-value publication proof')
    else:
        save('publication-proof.json',proof)
    print('PASS complete observer-current book publication, measured task authority and unchanged prior surfaces/ceilings/Knowledge Map authority.')


if __name__=='__main__':
    main()

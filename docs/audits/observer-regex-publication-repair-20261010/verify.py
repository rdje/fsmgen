"""Qualify the same-slice index repair without rewriting sealed regex evidence."""
import copy
import hashlib
import json
import subprocess
from pathlib import Path

BASE=Path('docs/audits/observer-regex-publication-repair-20261010')
CORE=Path('docs/audits/observer-regex-values-20261010')
REVISION='5c560fba3d64d04560b0d8736e35e6ef970b651c'
INDEX=Path('docs/TASK_TREE.md')
TASK=Path('docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md')
REGISTRY=Path('doctrine/live_document_size/surfaces.jsonl')
SCOPE='Exact same-slice index wording and current publication repair only; every original regex/source/native/parent boundary and capacity ceiling remains unchanged.'
OLD='predicates/scalars/regex done; opaque-boundary parent next;'
NEW='source constructors done; profiles next;'
BEFORE='Exact book source/native/copies, focused/current/claim/staged/normal hooks gate commit'
AFTER=('First staged doctrine rejects the expanded active-index row at the focused-document line allowance; '
       'same-slice observer-regex-publication-repair-20261010 retains whole failed index/task/registry/gate '
       'and compacts only equivalent index wording. '+BEFORE)


def need(condition,cause):
    if not condition:
        raise ValueError(cause)


def canonical(value):
    return (json.dumps(value,sort_keys=True,separators=(',',':'),ensure_ascii=True)+'\n').encode()


def pin(raw):
    return dict(bytes=len(raw),sha256=hashlib.sha256(raw).hexdigest())


def read(path):
    return json.loads(path.read_bytes())


def fixed(path):
    result=subprocess.run(['git','--no-replace-objects','show',REVISION+':'+str(path)],capture_output=True)
    need(type(result.returncode) is int and result.returncode==0 and result.stderr==b'','whole fixed publication authority')
    return result.stdout


def custody():
    failed_control=read(BASE/'first-control-failure.json')
    need(type(failed_control['status']) is int and failed_control['status']==1
         and "KeyError: 'enforcement_ceilings'" in failed_control['stderr']
         and failed_control==read(CORE/'checks.json')['publication-repair']
         and failed_control['inputs'][str(BASE/'verify.py')]==pin((BASE/'before-ceiling-control.py.txt').read_bytes()),
         'whole retained first malformed control programme and actual rejection')
    manifest=read(BASE/'first-core-manifest.json')
    need(manifest==read(CORE/'manifest.json'),'whole first regex namespace seal')
    need(manifest=={str(p.relative_to(CORE)):pin(p.read_bytes()) for p in CORE.rglob('*')
         if p.is_file() and p.name not in ('manifest.json','checks.json')},'every original sealed regex byte retained')
    gate=read(BASE/'first-staged-doctrines.json')
    need(type(gate['status']) is int and gate['status']==1 and gate['command']==['scripts/check_doctrines.sh']
         and 'max line bytes is 877 (> baseline 790 + growth 72)' in gate['stdout']+gate['stderr'],
         'complete actual original focused-document gate rejection')
    need(gate==read(CORE/'checks.json')['staged-doctrines'],'whole first failed staged result retained')
    first_registry=[json.loads(line) for line in (BASE/'first-surfaces.jsonl.txt').read_bytes().splitlines()]
    need(first_registry==read(CORE/'publication-proof-final.json')['after'],'whole first qualified registry before index gate')
    original_index=fixed(INDEX).decode()
    need(original_index.count('predicates and scalars done; regex next;')==1,'unique committed predecessor status seam')
    failed_index=original_index.replace('predicates and scalars done; regex next;',OLD,1)
    need(failed_index==(BASE/'first-task-index.md.txt').read_text(),'whole original failing index derived from fixed source')
    return manifest,first_registry


def task_metrics(original):
    paths=sorted({p for pattern in original['targets'] for p in Path('.').glob(pattern)})
    rows=[p.read_bytes() for p in paths]
    dimensions=dict(files=len(rows),lines_total=sum(raw.count(b'\n') for raw in rows),bytes_total=sum(map(len,rows)),
        lines_each=max(raw.count(b'\n') for raw in rows),bytes_each=max(map(len,rows)),
        line_bytes_each=max(len(line.rstrip(b'\r')) for raw in rows for line in raw.split(b'\n')))
    declaration=copy.deepcopy(original)
    for name,value in dimensions.items():
        allowed=declaration['baseline'][name]+declaration['transition']['max_growth'][name]
        if value>allowed:
            declaration['transition']['max_growth'][name]=min(value+declaration['transition']['ratchet_step'][name],
                declaration['enforcement_ceilings'][name])-declaration['baseline'][name]
        need(value<=declaration['baseline'][name]+declaration['transition']['max_growth'][name]
             <=declaration['enforcement_ceilings'][name],'complete task measurement inside unchanged ceiling')
    return dict(task=dimensions,task_declaration=declaration),{str(p):pin(raw) for p,raw in zip(paths,rows,strict=True)}


def expected():
    manifest,first_registry=custody()
    old_index=(BASE/'first-task-index.md.txt').read_text()
    need(old_index.count(OLD)==1,'unique failing index status seam')
    index=old_index.replace(OLD,NEW,1)
    old_task=(BASE/'first-owning-task.md.txt').read_text()
    need(old_task.count(BEFORE)==1,'unique same-slice task diagnosis seam')
    task=old_task.replace(BEFORE,AFTER,1)
    original=[json.loads(line) for line in fixed(REGISTRY).splitlines()]
    original_task=next(r for r in original if r.get('surface_id')=='task_evidence')
    measurements,task_pins=task_metrics(original_task)
    need(read(BASE/'metrics.json')==measurements,'entire independently measured final task declaration')
    registry=copy.deepcopy(first_registry)
    for i,row in enumerate(registry):
        if row.get('surface_id')=='task_evidence':
            registry[i]=measurements['task_declaration']
    need([r.get('enforcement_ceilings') for r in original]==[r.get('enforcement_ceilings') for r in registry],
         'every original ceiling unchanged')
    focused=next(r for r in registry if r.get('surface_id')=='focused_documents')
    need(max(len(line.encode()) for line in index.splitlines())<=focused['baseline']['line_bytes_each']
         +focused['transition']['max_growth']['line_bytes_each'],'whole repaired index within original line allowance')
    return dict(index=index,task=task,registry=registry,task_pins=task_pins,core_manifest=manifest,scope=SCOPE)


def validate(product,wanted):
    need(product['scope']==SCOPE,'unchanged original scope')
    need(product['index']==wanted['index'],'whole equivalent index source and unchanged peers')
    need(product['task']==wanted['task'],'whole owning task and unchanged acceptance')
    need(product['registry']==wanted['registry'],'whole current authority and unchanged ceilings/Knowledge Map')
    need(product['task_pins']==wanted['task_pins'],'complete actual task-byte custody')
    need(product['core_manifest']==wanted['core_manifest'],'entire original regex evidence custody')


def main():
    wanted=expected()
    actual=dict(index=INDEX.read_text(),task=TASK.read_text(),registry=[json.loads(l) for l in REGISTRY.read_bytes().splitlines()],
        task_pins=wanted['task_pins'],core_manifest=read(CORE/'manifest.json'),scope=SCOPE)
    validate(actual,wanted)
    controls=[]
    for name,change,cause in [
        ('borrowed-index',lambda p:p.update(index=p['index']+'borrowed\n'),'whole equivalent index source and unchanged peers'),
        ('narrowed-acceptance',lambda p:p.update(task=p['task'].replace('Acceptance:','Borrowed:',1)),
         'whole owning task and unchanged acceptance'),
        ('changed-ceiling',lambda p:next(r for r in p['registry'] if r.get('surface_id')=='task_evidence')['enforcement_ceilings'].update(lines_each=999),
         'whole current authority and unchanged ceilings/Knowledge Map'),
        ('lost-task-member',lambda p:p['task_pins'].pop(next(iter(p['task_pins']))),'complete actual task-byte custody'),
        ('lost-regex-member',lambda p:p['core_manifest'].pop(next(iter(p['core_manifest']))),'entire original regex evidence custody'),
        ('promoted-scope',lambda p:p.update(scope='Original runtime measured.'),'unchanged original scope')]:
        candidate=copy.deepcopy(actual);change(candidate)
        need(canonical(candidate)!=canonical(actual),'genuine whole publication hostile candidate')
        try:
            validate(candidate,wanted)
        except ValueError as error:
            need(str(error)==cause,'intended publication repair rejection: '+name)
            controls.append(dict(name=name,cause=cause,candidate=candidate,status='rejected'))
        else:
            raise ValueError('accepted publication repair candidate: '+name)
    proof=dict(product=actual,controls=controls,scope=SCOPE)
    path=BASE/'proof.json'
    if path.exists():
        need(read(path)==proof,'whole immutable publication repair proof')
    else:
        path.write_bytes(canonical(proof))
    if (BASE/'manifest.json').exists():
        need(read(BASE/'manifest.json')=={str(p.relative_to(BASE)):pin(p.read_bytes()) for p in BASE.rglob('*')
             if p.is_file() and p.name!='manifest.json'},'whole immutable publication repair namespace')
    print('PASS whole equivalent index repair, unchanged task acceptance and sealed regex evidence, exact current authority/measurements and genuine controls; every prior ceiling and Knowledge Map authority retains.')


if __name__=='__main__':
    main()

"""Dated complete repair proof; --current additionally checks live publication."""
import base64
import copy
import gzip
import hashlib
import json
import sys
import subprocess
from pathlib import Path

BASE=Path('docs/audits/observer-source-value-publication-repair-20261011')
CORE=Path('docs/audits/observer-source-value-acceptance-20261011')
TASK=Path('docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md')
REGISTRY=Path('doctrine/live_document_size/surfaces.jsonl')
SCOPE='Only exact same-owner resume-pointer compaction and final task publication; all original contracts, core bytes, capacities and Knowledge Map authority conserve.'


def need(condition,cause):
    if not condition:
        raise ValueError(cause)


def canonical(value):
    return (json.dumps(value,sort_keys=True,separators=(',',':'),ensure_ascii=True)+'\n').encode()


def pin(raw):
    return dict(bytes=len(raw),sha256=hashlib.sha256(raw).hexdigest())


def read(path):
    return json.loads(path.read_bytes())


def dimensions(data):
    return dict(files=len(data),lines_total=sum(x.count(b'\n') for x in data),bytes_total=sum(map(len,data)),
        lines_each=max(x.count(b'\n') for x in data),bytes_each=max(map(len,data)),
        line_bytes_each=max(len(line.rstrip(b'\r')) for x in data for line in x.split(b'\n')))


def wanted():
    source=read(BASE/'pressure-contract-source.json')
    command=['git','--no-replace-objects','show','dc2eb7df001c4cf968df31e15d2b4f0784f976bb:live-document-size/scripts/check_live_document_size.pl']
    need(source['command']==command and type(source['status']) is int and source['status']==0,
         'exact fixed own checker source command')
    actual=subprocess.run(command,capture_output=True)
    need(actual.returncode==0 and actual.stderr==b''
         and actual.stdout==(BASE/'pressure-contract-source.pl.txt').read_bytes()
         and pin(actual.stdout)==source['identity'],'complete fixed singleton/collection pressure source custody')
    malformed=read(BASE/'first-pressure-control-failure.json')
    need(type(malformed['status']) is int and malformed['status']==1
         and 'resume pressure below unchanged warning threshold' in malformed['stderr']
         and malformed==read(CORE/'checks.json')['publication-repair']
         and malformed['inputs'][str(BASE/'verify.py')]==pin((BASE/'before-pressure-control.py.txt').read_bytes()),
         'complete first malformed singleton-pressure predicate and actual refusal retain')
    failed=read(BASE/'first-staged-doctrines.json')
    need(type(failed['status']) is int and failed['status']==1 and failed['command']==['scripts/check_doctrines.sh']
         and 'surface active_resume is at 84.2% and must declare warning_debt' in failed['stdout']+failed['stderr']
         and failed==read(CORE/'checks.json')['staged-doctrines'],'complete original actual resume-pressure rejection')
    before=[json.loads(line) for line in (BASE/'before-surfaces.txt').read_bytes().splitlines()]
    need(before==read(CORE/'publication-proof.json')['after'],'entire independently qualified first registry')
    transform=read(BASE/'pointer-transform.json');memory=(BASE/'before-memory.txt').read_text()
    need(memory.count(transform['before'])==1,'unique complete resume pointer seam')
    memory=memory.replace(transform['before'],transform['after'],1)
    task=(BASE/'before-task.txt').read_text();owner=(BASE/'scope.txt').read_text().splitlines()[0]
    a=task.index('- ID: `'+owner+'`\n');b=task.find('\n- ID:',a+1);b=b if b>=0 else len(task)
    change=read(BASE/'task-transform.json');node=task[a:b]
    need(node.count(change['before'])==1,'unique same-owner publication diagnosis seam')
    task=task[:a]+node.replace(change['before'],change['after'],1)+task[b:]
    need(memory==(BASE/'after-memory.txt').read_text() and task==(BASE/'after-task.txt').read_text(),
         'whole exact memory/task transformations and all unchanged peers/contracts')
    collection={k:base64.b64decode(v,validate=True) for k,v in json.loads(gzip.decompress((BASE/'task-collection.json.gz').read_bytes())).items()}
    need(collection[str(TASK)]==task.encode(),'complete owning task in full collection snapshot')
    metric=dimensions(list(collection.values()));registry=copy.deepcopy(before)
    declaration=next(r for r in registry if r.get('surface_id')=='task_evidence')
    for name,value in metric.items():
        allowance=declaration['baseline'][name]+declaration['transition']['max_growth'][name]
        if value>allowance:
            declaration['transition']['max_growth'][name]=min(value+declaration['transition']['ratchet_step'][name],
                declaration['enforcement_ceilings'][name])-declaration['baseline'][name]
        need(value<=declaration['baseline'][name]+declaration['transition']['max_growth'][name]
             <=declaration['enforcement_ceilings'][name],'exact task measurement inside unchanged ceiling')
    need(read(BASE/'metrics.json')==dict(task=metric,task_declaration=declaration),'whole independent final task declaration')
    need(registry==[json.loads(line) for line in (BASE/'after-surfaces.txt').read_bytes().splitlines()],
         'entire exact registry transform and unchanged book/Knowledge Map/ceiling authority')
    seal=read(CORE/'manifest.json')
    need(seal=={str(p.relative_to(CORE)):pin(p.read_bytes()) for p in CORE.rglob('*')
         if p.is_file() and p.name not in ('manifest.json','checks.json')},'every whole original sealed parent byte conserves')
    return dict(memory=memory,task=task,registry=registry,collection={k:pin(v) for k,v in collection.items()},
        core_manifest=seal,scope=SCOPE)


def validate(product,expected):
    need(product['scope']==SCOPE,'unchanged publication repair scope')
    resume=next(r for r in expected['registry'] if r.get('surface_id')=='active_resume')
    measure=dimensions([product['memory'].encode()])
    need(all(100*measure[k]<resume['milestones']['warning_pct']*v for k,v in resume['health_targets'].items() if k!='files' or resume['locator']=='collection'),
         'resume pressure below unchanged warning threshold')
    for field in expected:
        need(product[field]==expected[field],'whole publication repair field: '+field)


def main():
    need(sys.argv[1:] in ([],['--current']),'explicit dated versus current repair role')
    expected=wanted();validate(expected,expected)
    controls=[]
    for name,mutate,cause in [
        ('first-resume-pressure',lambda p:p.update(memory=(BASE/'before-memory.txt').read_text()),'resume pressure below unchanged warning threshold'),
        ('lost-pointer-field',lambda p:p.update(memory=p['memory'].replace('- in_flight_background: none.','')),'whole publication repair field: memory'),
        ('narrowed-task-acceptance',lambda p:p.update(task=p['task'].replace('Acceptance:','Borrowed:',1)),'whole publication repair field: task'),
        ('changed-ceiling',lambda p:next(r for r in p['registry'] if r.get('surface_id')=='active_resume')['enforcement_ceilings'].update(line_bytes_each=999),'whole publication repair field: registry'),
        ('lost-collection-member',lambda p:p['collection'].pop(next(iter(p['collection']))),'whole publication repair field: collection'),
        ('lost-original-core-member',lambda p:p['core_manifest'].pop(next(iter(p['core_manifest']))),'whole publication repair field: core_manifest'),
        ('promoted-scope',lambda p:p.update(scope='Full original headers closed.'),'unchanged publication repair scope')]:
        candidate=copy.deepcopy(expected);mutate(candidate)
        need(candidate!=expected,'genuine complete publication candidate')
        try:
            validate(candidate,expected)
        except ValueError as error:
            need(str(error)==cause,'intended publication control rejection: '+name)
            controls.append(dict(name=name,cause=cause,status='rejected',
                candidate_gzip_base64=base64.b64encode(gzip.compress(canonical(candidate),mtime=0)).decode()))
        else:
            raise ValueError('accepted hostile publication candidate: '+name)
    if sys.argv[1:]:
        need(Path('MEMORY.md').read_text()==expected['memory'] and TASK.read_text()==expected['task']
             and [json.loads(line) for line in REGISTRY.read_bytes().splitlines()]==expected['registry'],
             'whole current Memory/task/registry source matches final publication')
        declaration=next(r for r in expected['registry'] if r.get('surface_id')=='task_evidence')
        paths=sorted({p for pattern in declaration['targets'] for p in Path('.').glob(pattern)})
        need({str(p):pin(p.read_bytes()) for p in paths}==expected['collection'],'complete actual current collection membership/bytes')
    proof=dict(product=expected,controls=controls,scope=SCOPE)
    if (BASE/'proof.json').exists():
        need(read(BASE/'proof.json')==proof,'whole immutable dated repair proof')
    else:
        (BASE/'proof.json').write_bytes(canonical(proof))
    if (BASE/'manifest.json').exists():
        need(read(BASE/'manifest.json')=={str(p.relative_to(BASE)):pin(p.read_bytes()) for p in BASE.rglob('*')
             if p.is_file() and p.name!='manifest.json'},'whole immutable repair namespace')
    print('PASS complete resume-pointer compaction, unchanged task acceptance/core/ceilings/Knowledge Map authority, exact collection and genuine controls; dated and current roles remain distinct.')


if __name__=='__main__':
    main()

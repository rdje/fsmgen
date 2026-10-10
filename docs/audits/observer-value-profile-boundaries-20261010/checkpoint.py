"""Fresh dated-publication replay from complete fixed inputs on this volume."""
import subprocess
import sys
from pathlib import Path
from common import BASE,REGEX,REPAIR,REVISION,SCOPE,load,need,pin,same,save

ROOT=Path('.artifacts/observer-value-profile-boundaries-20261010/publication-checkpoint')
PREFIXES=['docs/tasks',str(REGEX),str(REPAIR),'docs/TASK_TREE.md','doctrine/live_document_size/surfaces.jsonl']


def main():
    need(sys.argv[1:] in ([],['--replay']),'explicit initial capture versus fresh fixed-context replay')
    replay=bool(sys.argv[1:])
    listing=['git','--no-replace-objects','ls-tree','-r','--name-only',REVISION,'--',*PREFIXES]
    result=subprocess.run(listing,capture_output=True,text=True)
    need(result.returncode==0 and result.stderr=='','whole fixed dated-publication input membership')
    names=result.stdout.splitlines()
    need(names and len(names)==len(set(names)),'complete distinct fixed checkpoint members')
    need(replay or not ROOT.exists(),'retain complete first checkpoint workspace')
    ROOT.mkdir(parents=True,exist_ok=replay)
    members={}
    for name in names:
        path=Path(name)
        need(not path.is_absolute() and '..' not in path.parts,'repository-relative checkpoint member')
        command=['git','--no-replace-objects','show',REVISION+':'+name]
        source=subprocess.run(command,capture_output=True)
        need(source.returncode==0 and source.stderr==b'','whole fixed checkpoint byte retrieval')
        target=ROOT/path
        target.parent.mkdir(parents=True,exist_ok=True)
        if target.exists():
            need(replay and target.read_bytes()==source.stdout,'whole existing checkpoint member matches fixed source')
        else:
            target.write_bytes(source.stdout)
        members[name]=dict(identity=pin(source.stdout),command=command,status=source.returncode)
    before={str(p.relative_to(ROOT)):pin(p.read_bytes()) for p in ROOT.rglob('*') if p.is_file()}
    need(before=={name:row['identity'] for name,row in members.items()},'whole copied checkpoint matches fixed Git inputs')
    command=['python3','-B',str(REPAIR/'verify.py')]
    actual=subprocess.run(command,cwd=ROOT.resolve(),capture_output=True,text=True)
    after={str(p.relative_to(ROOT)):pin(p.read_bytes()) for p in ROOT.rglob('*') if p.is_file()}
    record=dict(revision=REVISION,cwd=str(ROOT),members=members,listing=dict(command=listing,status=result.returncode,
        stdout=result.stdout,stderr=result.stderr),command=command,status=actual.returncode,stdout=actual.stdout,
        stderr=actual.stderr,before=before,after=after,scope=SCOPE,
        meaning='Actual fresh execution against whole immutable committed inputs; no current mutable task state or borrowed result is admitted as the dated publication epoch.')
    if replay:
        need(same(record,load('checkpoint-publication.json')),'whole actual fresh fixed-context result and input conservation')
    else:
        save('checkpoint-publication.json',record)
    need(type(actual.returncode) is int and actual.returncode==0 and actual.stderr=='' and actual.stdout.startswith('PASS '),
         'actual fresh dated publication checkpoint success')
    need(before==after,'dated reader conserves every complete checkpoint input and creates no artifact')
    print('PASS fresh complete dated-publication checkpoint execution, fixed Git byte custody and before/after input conservation; no original native scope is promoted.')


if __name__=='__main__':
    main()

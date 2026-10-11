"""Qualify genuine whole candidates and the first actual nested false green."""
import copy
import json
import shutil
import subprocess
import tarfile
from pathlib import Path
import guard
import oracle

BASE=Path('docs/audits/observer-publication-namespace-repair-20261011')
WORK=Path('.artifacts/observer-publication-namespace-repair-20261011')


def save(name,value):
    path=BASE/name;guard.require(not path.exists(),'retain complete first namespace repair product')
    path.write_bytes(guard.encoded(value))


def main():
    original=guard.authenticate_original();guard.require(oracle.reconstruct(guard.ORIGINAL,original)==original,'independent complete original namespace reconstruction')
    first=json.loads((BASE/'first-nested-probe.json').read_bytes())
    guard.require(type(first['status']) is int and first['status']==0 and first['stderr']=='' and
                  first['stdout'].startswith('PASS complete dated observer publication'),'actual whole first saved-reader nested false green retained')
    guard.require(guard.identity(first['reader_source'].encode())==original['verify.py'],'complete exact first reader source binding')
    actual=subprocess.run(['python3','-B',str(guard.ORIGINAL/'verify.py')],capture_output=True,text=True)
    guard.require(type(actual.returncode) is int and actual.returncode==0 and actual.stdout==first['stdout'] and actual.stderr=='',
                  'fresh complete unchanged original publication and all semantic obligations')
    save('fresh-original-reader.json',dict(command=['python3','-B',str(guard.ORIGINAL/'verify.py')],status=actual.returncode,stdout=actual.stdout,stderr=actual.stderr))
    WORK.mkdir(parents=True,exist_ok=True)
    root=WORK/'whole-candidate';shutil.copytree(guard.ORIGINAL,root)
    baseline=guard.check_tree(root,original);guard.require(oracle.reconstruct(root,original)==baseline,'whole positive relocated candidate')
    controls=[]
    cases=[('nested-file','declared observer namespace directory graph'),('empty-directory','declared observer namespace directory graph'),
           ('symlink','ordinary same-volume observer namespace member'),('missing-member','complete observer namespace member graph'),
           ('changed-tail','whole observer namespace member bytes')]
    for name,cause in cases:
        changed=[]
        if name in ('nested-file','empty-directory'):
            path=root/'unexpected';path.mkdir();changed=[path]
            if name=='nested-file':(path/'member.txt').write_text('whole unexpected member\n');changed.insert(0,path/'member.txt')
        elif name=='symlink':
            path=root/'unexpected.txt';path.symlink_to('scope.txt');changed=[path]
        elif name=='missing-member':
            path=root/'scope.txt';retained=path.read_bytes();path.unlink()
        else:
            path=root/'scope.txt';retained=path.read_bytes();path.write_bytes(retained[:-1]+b'!')
        candidate=BASE/(name+'-whole.tar.gz')
        with tarfile.open(candidate,'w:gz') as archive:
            for p in sorted(root.iterdir()):archive.add(p,arcname=p.name,recursive=True)
        outcomes=[]
        for reader in (guard.check_tree,oracle.reconstruct):
            try:reader(root,original)
            except ValueError as error:
                guard.require(str(error)==cause,'intended whole namespace refusal: '+name)
                outcomes.append(dict(reader=reader.__module__+'.'+reader.__name__,status='rejected',cause=str(error)))
            else:raise ValueError('accepted hostile whole observer namespace')
        controls.append(dict(name=name,complete_candidate=str(candidate),identity=guard.identity(candidate.read_bytes()),outcomes=outcomes))
        for p in changed:
            p.unlink() if p.is_symlink() or p.is_file() else p.rmdir()
        if name in ('missing-member','changed-tail'):path.write_bytes(retained)
        guard.check_tree(root,original)
    invalid=copy.deepcopy(original);invalid['scope.txt']['bytes']=True
    try:guard.check_tree(root,invalid)
    except ValueError as error:
        guard.require(str(error)=='closed original observer namespace identity','intended Boolean size refusal')
        controls.append(dict(name='boolean-size',whole_declaration=invalid,cause=str(error),status='rejected'))
    else:raise ValueError('accepted Boolean namespace size')
    save('controls.json',controls)
    save('semantic-proof.json',dict(original_manifest=guard.MANIFEST_IDENTITY,whole_original=original,
        actual_false_green=guard.identity((BASE/'first-nested-probe.json').read_bytes()),
        fresh_original=guard.identity((BASE/'fresh-original-reader.json').read_bytes()),
        controls=guard.identity((BASE/'controls.json').read_bytes()),scope=(BASE/'scope.txt').read_text(),
        legs=dict(rederive='Independent recursive graph and complete byte reconstruction plus fresh complete original saved-reader semantic replay.',
                  falsify='Actual original nested-file false green and genuine whole nested/directory/symlink/missing/tail/Boolean controls reject in strict independent readers.',
                  durability='Whole first sealed epoch, exact first programme/proof/manifest, complete candidate archives and actual source-bound results retain unchanged.')))
    print('PASS strict complete original namespace and unchanged semantic replay; genuine whole candidate controls reject; current/native publication remains pending.')


if __name__=='__main__':main()

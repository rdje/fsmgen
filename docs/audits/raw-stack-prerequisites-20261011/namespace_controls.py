"""Observe whole namespace graph and typed declaration refusals on an exact copy."""
import copy
import argparse
import shutil
import tempfile
from pathlib import Path
import verify
from common import BASE, canonical, load, need, pin, save


def qualify(wanted):
    need(canonical(verify.members())==canonical(wanted),'whole strict namespace declaration and bytes')


def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--replay',action='store_true');args=parser.parse_args()
    original=load('namespace-controls.json')['original'] if args.replay else verify.members()
    local=Path('.artifacts/raw-stack-prerequisites-20261011')
    local.mkdir(parents=True,exist_ok=True);results=[]
    with tempfile.TemporaryDirectory(dir=local,prefix='whole-namespace-') as directory:
        root=Path(directory).resolve().relative_to(Path.cwd().resolve())
        for name in original:
            path=BASE/name
            need(path.is_file() and not path.is_symlink(),'complete flat original namespace control input')
            shutil.copy2(path,root/path.name)
        verify.BASE=root;qualify(original)
        results.append(dict(name='complete-positive',status=0,whole_namespace=original))
        for name in ('empty-directory','nested-file','symlink','missing-member','changed-tail','integer-executable-kind'):
            wanted=copy.deepcopy(original);restore=None;extra=None
            if name in ('empty-directory','nested-file'):
                extra=root/'unexpected';extra.mkdir()
                if name=='nested-file':(extra/'payload.txt').write_text('Unexpected complete member.\n')
            elif name=='symlink':extra=root/'borrowed';extra.symlink_to('common.py')
            elif name in ('missing-member','changed-tail'):
                path=root/'common.py';restore=path.read_bytes()
                if name=='missing-member':path.unlink()
                else:path.write_bytes(restore[:-1]+bytes([restore[-1]^1]))
            else:
                wanted['common.py']['executable']=0
                need(wanted==original and canonical(wanted)!=canonical(original),
                     'actual typed-kind intervention defeats untyped dictionary equality')
            candidate={str(path.relative_to(root)):dict(kind='symlink' if path.is_symlink() else 'directory' if path.is_dir() else 'file',
                       identity=pin(path.read_bytes()) if path.is_file() and not path.is_symlink() else None)
                       for path in sorted(root.rglob('*'))}
            try:qualify(wanted)
            except ValueError as error:
                need(str(error) in ('complete flat regular raw prerequisite member graph without hidden directories',
                                   'whole strict namespace declaration and bytes'),'intended whole namespace refusal')
                results.append(dict(name=name,status=1,cause=str(error),candidate=candidate,declaration=wanted))
            else:raise ValueError('false-green whole namespace control: '+name)
            if extra is not None:
                if extra.is_symlink():extra.unlink()
                else:
                    if (extra/'payload.txt').exists():(extra/'payload.txt').unlink()
                    extra.rmdir()
            if restore is not None:(root/'common.py').write_bytes(restore)
            qualify(original)
        verify.BASE=BASE
    product=dict(original=original,actual=results,
         scope='Exact complete immutable-member namespace at this captured epoch, copied on the same volume; real graph/byte/typed-declaration controls preserve original bytes. Explicitly mutable checks and later qualified files are not misrepresented as original probe inputs.')
    if args.replay:need(canonical(load('namespace-controls.json'))==canonical(product),'whole exact namespace control replay epoch')
    else:save('namespace-controls.json',product)
    print('PASS complete actual positive and hidden-directory/nested-file/symlink/missing/changed-tail/typed-kind namespace refusals with independent whole candidate census.')


if __name__=='__main__':main()

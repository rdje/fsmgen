"""Observe old/new checkpoint write boundaries without any foreign repository write."""
import json
import argparse
import sys
import tempfile
from pathlib import Path
from common import BASE, canonical, need, pin, save


def namespace(raw):
    result={'__name__':'checkpoint_locality_control'}
    exec(compile(raw,'retained-checkpoint-programme','exec'),result)
    return result


def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--qualified',action='store_true');args=parser.parse_args()
    before=(BASE/'display-checkpoint-before-locality.py.txt').read_bytes()
    after=(BASE/'display_checkpoint.py').read_bytes()
    root=Path('.artifacts/raw-stack-prerequisites-20261011');root.mkdir(parents=True,exist_ok=True)
    results=[]
    with tempfile.TemporaryDirectory(dir=root,prefix='checkpoint-locality-') as directory:
        local=Path(directory).resolve().relative_to(Path.cwd().resolve())
        for name,raw in (('before',before),('after',after)):
            case=local/name;case.mkdir();outside=case/'separate-owned-directory';outside.mkdir()
            link=case/'alias';link.symlink_to('separate-owned-directory',target_is_directory=True)
            module=namespace(raw);module['ROOT']=link/'checkpoint'
            record=dict(**pin(Path('README.md').read_bytes()),executable=False)
            module['expected']=lambda:({'README.md':record},b'')
            previous=sys.argv;sys.argv=['display_checkpoint.py']
            try:
                module['main']()
            except ValueError as error:cause=str(error)
            finally:sys.argv=previous
            observed={str(path.relative_to(outside)):pin(path.read_bytes()) for path in outside.rglob('*') if path.is_file()}
            if name=='before':
                need(observed=={'checkpoint/README.md':pin(Path('README.md').read_bytes())}
                     and cause=='own same-volume dated display checkpoint graph',
                     'actual predecessor writes through alias before its later graph refusal')
            else:need(observed=={} and cause=='plain own dated checkpoint path before any write',
                      'actual corrected checkpoint refuses alias before creating any member')
            results.append(dict(name=name,programme=raw.decode(),programme_identity=pin(raw),status=1,cause=cause,
                                observed_members=observed,scope='Only an isolated directory created by this control inside the project is used; no other Git repository or volume is written.'))
    save('locality-controls-qualified.json' if args.qualified else 'locality-controls.json',dict(actual=results,
         scope='Genuine pre-write locality mechanism: old callback copies through a symlinked ancestor before refusal; corrected callback refuses before any write. No external repo boundary is crossed.'))
    print('PASS actual old/new checkpoint alias-write control; complete first source retains and corrected pre-write locality refuses before creating any member.')


if __name__=='__main__':main()

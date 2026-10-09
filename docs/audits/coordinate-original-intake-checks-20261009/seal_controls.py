"""Genuine copied-corpus controls conserve the complete original intake."""
import hashlib
import json
import os
import runpy
import shutil
import uuid
from pathlib import Path

BASE = Path('docs/audits/coordinate-original-intake-20261009')
CHECKS = Path('docs/audits/coordinate-original-intake-checks-20261009')


def census(folder):
    return {p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in folder.iterdir()}


def main():
    authenticate = runpy.run_path(str(CHECKS/'verify_intake.py'))['authenticate']
    before = census(BASE)
    root = Path('.artifacts/tmp/coordinate-original-intake-seals')/uuid.uuid4().hex
    root.mkdir(parents=True)
    if root.stat().st_dev != Path('.').stat().st_dev:
        raise ValueError('same-volume own intake controls')
    controls = {}
    try:
        for name in ('valid','missing-seal','missing-member','borrowed-body','extra-member','rewritten-seal','symlink-root'):
            path = root/name
            if name == 'symlink-root':
                path.symlink_to(os.path.relpath(BASE.resolve(),path.parent.resolve()),target_is_directory=True)
                expected = 'fixed intake plain same-volume root'
            else:
                shutil.copytree(BASE,path)
                expected = None
                if name == 'missing-seal':
                    (path/'seal.json').unlink(); expected = 'fixed complete intake seal identity'
                elif name == 'missing-member':
                    (path/'admission.json').unlink(); expected = 'fixed complete intake member domain'
                elif name in ('borrowed-body','rewritten-seal'):
                    (path/'admission.json').write_bytes((path/'scope.txt').read_bytes())
                    expected = 'fixed complete intake member bytes'
                    if name == 'rewritten-seal':
                        seal = json.loads((path/'seal.json').read_bytes());raw=(path/'admission.json').read_bytes()
                        seal['admission.json']={'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()}
                        (path/'seal.json').write_text(json.dumps(seal,sort_keys=True,indent=2)+'\n')
                        expected = 'fixed complete intake seal identity'
                elif name == 'extra-member':
                    (path/'foreign.txt').write_text('foreign\n'); expected = 'fixed complete intake member domain'
            try:
                authenticate(path)
            except ValueError as error:
                if str(error) != expected:
                    raise ValueError('intended actual intake seal predicate: '+name) from error
                controls[name]=str(error)
            else:
                if name != 'valid':
                    raise ValueError('false-green actual intake seal: '+name)
                controls[name]='PASS complete copied original'
    finally:
        shutil.rmtree(root)
    authenticate(BASE)
    if root.exists() or census(BASE) != before:
        raise ValueError('complete original conservation and own fixture disposal')
    print(json.dumps({'result':'PASS genuine copied intake seal controls and whole original conservation',
                      'controls':controls,'original':before},sort_keys=True))


if __name__ == '__main__':
    main()

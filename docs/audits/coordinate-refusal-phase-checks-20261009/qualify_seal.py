"""Actual hostile same-volume copies; preserve the immutable complete corpus."""
import hashlib
import json
import runpy
import shutil
import tempfile
from pathlib import Path

BASE = Path('docs/audits/coordinate-refusal-phases-20261009')
CHECKS = Path('docs/audits/coordinate-refusal-phase-checks-20261009')


def census(folder):
    return {p.name: {'bytes': len(p.read_bytes()), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}
            for p in folder.iterdir()}


def main():
    reader = runpy.run_path(str(CHECKS / 'verify_phases.py'))
    before = census(BASE)
    reader['authenticate'](BASE)
    scratch = Path('.artifacts/tmp')
    scratch.mkdir(parents=True, exist_ok=True)
    controls = {}
    with tempfile.TemporaryDirectory(prefix='coordinate-phase-seal-', dir=scratch) as name:
        root = Path(name)
        trials = ('missing-seal', 'missing-member', 'borrowed-body', 'extra-member', 'resealed-extra-member', 'symlink-root')
        for trial in trials:
            folder = root / trial
            shutil.copytree(BASE, folder)
            selected = folder
            cause = 'fixed complete phase member bytes'
            if trial == 'missing-seal':
                (folder / 'seal.json').unlink()
                cause = 'fixed complete phase seal identity'
            elif trial == 'missing-member':
                (folder / 'scope.txt').unlink()
                cause = 'fixed complete phase member domain'
            elif trial == 'borrowed-body':
                (folder / 'phases.json').write_bytes(b'{}\n')
            elif trial in ('extra-member', 'resealed-extra-member'):
                (folder / 'extra.txt').write_bytes(b'borrowed\n')
                cause = 'fixed complete phase member domain'
                if trial == 'resealed-extra-member':
                    seal = census(folder)
                    del seal['seal.json']
                    (folder / 'seal.json').write_text(json.dumps(seal, sort_keys=True, indent=2) + '\n')
                    cause = 'fixed complete phase seal identity'
            else:
                selected = root / 'linked-root'
                selected.symlink_to(folder.resolve(), target_is_directory=True)
                cause = 'fixed phase plain same-volume root'
            try:
                reader['authenticate'](selected)
            except ValueError as error:
                if str(error) != cause:
                    raise ValueError('intended actual copied-corpus refusal: ' + trial + ': ' + str(error))
                controls[trial] = {'status': 1, 'cause': cause}
            else:
                raise ValueError('false-green actual copied-corpus control: ' + trial)
    if root.exists() or census(BASE) != before:
        raise ValueError('complete original conservation and owned scratch disposal')
    reader['authenticate'](BASE)
    print(json.dumps({'result': 'PASS fixed complete phase seal and actual copied-corpus controls',
                      'controls': controls, 'conserved_original': before, 'scratch_removed': True}, sort_keys=True))


if __name__ == '__main__':
    main()

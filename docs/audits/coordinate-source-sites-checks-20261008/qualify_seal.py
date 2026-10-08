"""Reproduce the original missing-seal false green and qualify its successor."""
import contextlib
import hashlib
import io
import json
import runpy
import shutil
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
BASE = Path('docs/audits/coordinate-source-sites-checks-20261008')
BANK = Path('docs/audits/coordinate-source-sites-20261008')


def need(condition, cause):
    if not condition:
        raise ValueError(cause)


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def members(path):
    need(path.resolve() == path and path.stat().st_dev == ROOT.stat().st_dev
         and all(row.is_file() and not row.is_symlink() for row in path.iterdir()),
         'own plain same-volume complete fixture members')
    return {row.name: pin(row.read_bytes()) for row in sorted(path.iterdir())}


def main():
    need(Path.cwd().resolve() == ROOT, 'invoke seal controls from repository root')
    scratch = ROOT / '.artifacts/coordinate-source-sites-seal-controls-20261008'
    scratch.mkdir(exist_ok=True)
    need(scratch.resolve() == scratch and scratch.stat().st_dev == ROOT.stat().st_dev
         and not (scratch / '.git').exists(), 'own same-volume control workspace')
    before = members(ROOT / BANK)
    namespace = runpy.run_path(str(ROOT / BASE / 'verify_sites.py'), run_name='qualified_seal_reader')
    authenticate = namespace['authenticate']
    authenticate()
    results = []
    controls = (
        ('missing-seal', 'immutable source-site seal is required'),
        ('missing-member', 'whole immutable source-site member population and bytes'),
        ('borrowed-body', 'whole immutable source-site member population and bytes'),
        ('changed-seal', 'exact original immutable source-site seal identity'),
        ('changed-scope', 'whole immutable source-site member population and bytes'),
    )
    original = None
    for name, cause in controls:
        fixture = Path(tempfile.mkdtemp(prefix=name + '-', dir=scratch))
        relative = fixture.relative_to(ROOT)
        try:
            for path in (ROOT / BANK).iterdir():
                shutil.copyfile(path, fixture / path.name)
            need(members(fixture) == before, 'whole before-control bank copy equality')
            authenticate(relative)
            if name == 'missing-seal':
                (fixture / 'seal.json').unlink()
                previous = runpy.run_path(str(ROOT / BANK / 'verify.py'), run_name='first_missing_seal_reader')
                previous['main'].__globals__['BASE'] = relative
                output = io.StringIO()
                saved_argv = sys.argv
                try:
                    sys.argv = [str(BANK / 'verify.py')]
                    with contextlib.redirect_stdout(output):
                        previous['main']()
                finally:
                    sys.argv = saved_argv
                original = {'status': 0, 'stdout': output.getvalue(), 'stderr': '',
                            'programme': pin((ROOT / BANK / 'verify.py').read_bytes()),
                            'candidate_members': members(fixture)}
                need(original['stdout'] == 'PASS complete independent binary source-site allocation and genuine controls; lexical extents do not predict original coordinates.\n',
                     'actual original missing-seal false green reproduced')
            elif name == 'missing-member':
                (fixture / 'controls.json').unlink()
            elif name == 'borrowed-body':
                (fixture / 'sites.json').write_bytes((ROOT / BANK / 'controls.json').read_bytes())
            elif name == 'changed-seal':
                (fixture / 'seal.json').write_bytes((fixture / 'seal.json').read_bytes() + b' ')
            else:
                (fixture / 'scope.txt').write_text('borrowed\n')
            candidate = members(fixture)
            need(candidate != before, 'genuine actual copied source-site control')
            try:
                authenticate(relative)
            except ValueError as error:
                need(str(error) == cause, 'intended immutable-bank refusal: ' + name)
                results.append({'name': name, 'status': 'refused', 'cause': cause, 'candidate_members': candidate})
            else:
                raise ValueError('false-green immutable-bank control: ' + name)
        finally:
            need(fixture.parent == scratch and fixture.resolve() == fixture
                 and not (fixture / '.git').exists(), 'exact owned disposable fixture cleanup')
            shutil.rmtree(fixture)
            need(not fixture.exists(), 'complete owned fixture removal')
    need(members(ROOT / BANK) == before and not list(scratch.iterdir()), 'original sealed-bank conservation and empty fixture residue')
    proof = {'original_missing_seal': original, 'controls': results, 'original_members_before_after': before,
             'programmes': {str(path): pin(path.read_bytes()) for path in (BASE / 'qualify_seal.py', BASE / 'verify_sites.py', BANK / 'verify.py')},
             'role': 'Missing-seal default-reader repair only; original immutable bank, per-refusal composition and original coordinate selection remain unchanged.'}
    (BASE / 'seal-repair.json').write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    print('PASS actual original missing-seal false green, superseding reader refusals and whole original sealed-bank conservation; all fixtures removed.')


if __name__ == '__main__':
    main()

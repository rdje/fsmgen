"""Admit complete own source and dated public inputs before original coordinates."""
import base64
import hashlib
import io
import json
import os
import subprocess
import tarfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
BASE = Path('docs/audits/coordinate-source-admission-20261008')
REVISION = 'cd5021fab917166edc79b9317bb072ace82d952e'
CATALOG = Path('docs/audits/record-value-coordinate-source-catalog-20261007')
PUBLIC = Path('docs/audits/record-value-coordinate-public-reference-20261008')
FINAL = Path('docs/audits/coordinate-public-final-replay-20261008')
ROOTS = (str(CATALOG), str(PUBLIC), str(FINAL))
ROLE = 'Complete qualified own source/catalog/custody and finite-public input admission only; source hypotheses and original coordinate intake remain successor-owned.'


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def same(left, right):
    return json.dumps(left, sort_keys=True) == json.dumps(right, sort_keys=True)


def git(*args):
    result = subprocess.run(['git', '--no-replace-objects', '-C', str(ROOT), *args], capture_output=True)
    if result.returncode or result.stderr:
        raise ValueError('complete native committed input result')
    return result.stdout


def module(path):
    source = git('show', REVISION + ':' + str(path))
    namespace = {'__name__': 'source_only_admission', '__file__': str(path)}
    exec(compile(source, str(path), 'exec'), namespace)
    return namespace


def custody():
    metadata = git('--literal-pathspecs', 'ls-tree', '-r', '--full-tree', '-z', REVISION, '--', *ROOTS)
    rows = {}
    for record in metadata.rstrip(b'\0').split(b'\0'):
        header, name = record.split(b'\t', 1)
        mode, kind, oid = header.decode().split()
        if kind != 'blob' or mode not in ('100644', '100755'):
            raise ValueError('regular own admitted input modes')
        rows[name.decode()] = {'mode': mode, 'oid': oid}
    archive = git('--literal-pathspecs', 'archive', '--format=tar', REVISION, '--', *ROOTS)
    members = {}
    with tarfile.open(fileobj=io.BytesIO(archive)) as source:
        for member in source:
            if member.isdir():
                continue
            if not member.isfile() or member.name not in rows or member.name in members:
                raise ValueError('exact unique regular committed input membership')
            raw = source.extractfile(member).read()
            live = ROOT / member.name
            for parent in live.parents:
                if parent == ROOT:
                    break
                if parent.is_symlink() or not parent.is_dir() or parent.stat().st_dev != ROOT.stat().st_dev or (parent / '.git').exists():
                    raise ValueError('plain same-volume own input parents')
            if live.is_symlink() or not live.is_file() or live.stat().st_dev != ROOT.stat().st_dev or live.read_bytes() != raw:
                raise ValueError('whole unchanged same-volume admitted input bytes')
            members[member.name] = pin(raw)
    if set(members) != set(rows):
        raise ValueError('complete admitted input population')
    return {'revision': REVISION, 'roots': ROOTS, 'metadata': base64.b64encode(metadata).decode(),
            'rows': rows, 'members': members}


def source_input():
    catalog = module(CATALOG / 'verify.py')
    source = catalog['inputs']()
    product = catalog['derive'](source)
    if not same(source, json.loads(git('show', REVISION + ':' + str(CATALOG / 'inputs.json')))) or not same(product, json.loads(git('show', REVISION + ':' + str(CATALOG / 'catalog.json')))):
        raise ValueError('whole source-only original source/catalog reconstruction')
    return {'source': source, 'catalog': product}


def readers():
    result = []
    for path in (CATALOG / 'verify.py', PUBLIC / 'verify.py', FINAL / 'verify.py'):
        command = ['python3', '-B', str(path)]
        actual = subprocess.run(command, cwd=ROOT, capture_output=True, text=True)
        if actual.returncode or actual.stderr:
            raise ValueError('complete unchanged input-reader result: ' + str(path))
        result.append({'command': command, 'status': actual.returncode,
                       'stdout': actual.stdout, 'stderr': actual.stderr})
    return result


def main():
    if Path.cwd().resolve() != ROOT:
        raise ValueError('invoke from the current repository root')
    os.environ['GIT_NO_REPLACE_OBJECTS'] = '1'
    os.environ['GIT_NO_LAZY_FETCH'] = '1'
    before = custody()
    source = source_input()
    public = json.loads(git('show', REVISION + ':' + str(PUBLIC / 'recipes.json')))
    checks = json.loads(git('show', REVISION + ':' + str(FINAL / 'checks.json')))
    current = {name: checks[name] for name in ('current-native-rebuilt', 'copied-source-final', 'focused', 'staged-doctrines')}
    actual = readers()
    if not same(before, custody()):
        raise ValueError('complete committed input conservation during admission')
    proof = {'role': ROLE, 'custody': before, 'inputs': source, 'public': public,
             'prior_current_results': current, 'actual_readers': actual,
             'programmes': {name: (BASE / name).read_text() for name in ('qualify.py', 'verify.py')}}
    (BASE / 'proof.json').write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    print('PASS complete committed source-only/catalog/custody/public admission; hypotheses and original coordinates remain successor-owned.')


if __name__ == '__main__':
    main()

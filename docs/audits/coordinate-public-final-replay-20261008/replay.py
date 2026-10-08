"""Run the unchanged dated route using explicit committed dependencies only."""
import ast
import base64
import hashlib
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

PREPARATION = Path('docs/audits/coordinate-public-final-preparation-20261008')
sys.path.insert(0, str(PREPARATION.resolve()))
import epoch

BASE = Path('docs/audits/coordinate-public-final-replay-20261008')
READER = 'docs/audits/record-value-coordinate-public-route-20261008/verify.py'
ADDITIONAL = ('docs/audits/book-source-plane-20261005/book-authority.json',)
READERS = (READER, 'docs/audits/record-value-coordinate-public-reference-20261008/verify.py',
           'docs/audits/record-value-coordinate-public-qualification-20261008/verify.py')


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def primary():
    directory = Path(epoch.git('rev-parse', '--absolute-git-dir').decode().strip())
    return {'files': {name: pin((directory / name).read_bytes()) if (directory / name).exists() else None
                      for name in ('index', 'config', 'HEAD', 'packed-refs')},
            'refs': epoch.git('for-each-ref', '--format=%(refname) %(objectname)').decode()}


def recovered(root, rows):
    result = {}
    for path, row in rows.items():
        endpoint = root / path
        raw = os.readlink(endpoint).encode() if endpoint.is_symlink() else endpoint.read_bytes()
        result[path] = {'content': pin(raw), 'kind': 'alias' if endpoint.is_symlink() else 'regular',
                        'mode': oct(endpoint.lstat().st_mode & 0o777),
                        'same_volume': endpoint.lstat().st_dev == epoch.ROOT.stat().st_dev}
    return result


def names():
    all_names = set(epoch.git('ls-tree', '-r', '--name-only', epoch.REVISION).decode().splitlines())
    roots = {'scripts', 'knowledge-map/scripts', 'knowledge-map/generated', 'docs/knowledge', 'docs/decisions',
             'docs/book/src/reference-source', 'docs/audits/record-value-class-frame-publication-20261006',
             'docs/audits/record-value-class-frame-retention-20261006',
             'docs/audits/record-value-class-frame-publication-admission-20261006',
             'docs/audits/coordinate-public-route-checks-20261008', str(Path(READER).parent)}
    prior = '75f6a47018a7098d6f192788c5e8aa3bd9d3c622'
    raw = epoch.git('ls-tree', '--name-only', '-z', prior + ':docs/audits')
    roots.update('docs/audits/' + name.decode() for name in raw.split(b'\0') if name.startswith((b'coordinate-', b'record-value-coordinate-')))
    selected = {name for name in all_names if any(name == root or name.startswith(root + '/') for root in roots)}
    selection = json.loads(epoch.git('show', epoch.REVISION + ':docs/audits/book-reference-selection-20261005/selected-routes.json'))
    selected.update(row['source'] for row in selection['routes'])
    selected.update(ADDITIONAL)
    selected.update(name for name in ('.gitignore', '.knowledge_map.conf', 'docs/book/src/13k-isf-feature-support-matrix.md',
                                     'docs/book/src/90-reference-map.md', 'doctrine/live_document_size/surfaces.jsonl',
                                     'docs/audits/book-reference-selection-20261005/selected-routes.json') if name in all_names)
    # Imported audit programmes define their own exact namespaces. Only their
    # programme files are initially needed; sealed/input data stay explicit.
    audit_roots = {root for root in roots if root.startswith('docs/audits/')}
    visited = set()
    while audit_roots - visited:
        root = sorted(audit_roots - visited)[0]
        visited.add(root)
        programmes = sorted(name for name in all_names if name.startswith(root + '/') and name.endswith('.py'))
        selected.update(programmes)
        for name in programmes:
            source = epoch.git('show', epoch.REVISION + ':' + name)
            for part in ast.walk(ast.parse(source)):
                if isinstance(part, ast.Constant) and isinstance(part.value, str):
                    value = part.value
                    if value.startswith('docs/audits/') and '\n' not in value and ' ' not in value:
                        path = Path(value)
                        candidate = str(path.parent) if value in all_names else value.rstrip('/')
                        if len(Path(candidate).parts) >= 3 and any(name.startswith(candidate + '/') for name in all_names):
                            audit_roots.add(candidate)
    return sorted(selected), sorted(roots), sorted(audit_roots)


def main():
    before = primary()
    selected, roots, programme_roots = names()
    raw, rows = epoch.metadata(selected)
    attempt = len(list(BASE.glob('attempt-*.json'))) + 1
    proof = {'revision': epoch.REVISION, 'scope': 'Unchanged dated finite-public route only; current publication and original-coordinate identities remain separate.',
             'selection_roots': roots, 'programme_roots': programme_roots,
             'names': selected, 'metadata': base64.b64encode(raw).decode(), 'rows': rows,
             'source': Path(__file__).read_text(),
             'transport': {name: pin((PREPARATION / name).read_bytes()) for name in ('epoch.py', 'git_readonly.py')}}
    with tempfile.TemporaryDirectory(prefix='coordinate-public-final-', dir=epoch.ROOT / '.artifacts') as directory:
        root = Path(directory)
        proof['fixture'] = {'relative_path': str(root.relative_to(epoch.ROOT)), 'observed_root': str(root)}
        epoch.recover(root, rows, selected)
        proof['recovered_before'] = recovered(root, rows)
        env = epoch.environment(root)
        results = []
        for reader in READERS:
            command = ['python3', '-B', reader]
            actual = subprocess.run(command, cwd=root, env=env, capture_output=True, text=True)
            results.append({'command': command, 'status': actual.returncode,
                            'stdout': actual.stdout, 'stderr': actual.stderr})
            if actual.returncode:
                break
        proof['results'] = results
        proof['recovered_after'] = recovered(root, rows)
        proof['git_calls'] = (root / '.artifacts/readonly-git-calls.jsonl').read_text()
    proof['fixture']['removed'] = not root.exists() and not root.is_symlink()
    proof['primary_before'], proof['primary_after'] = before, primary()
    assert proof['primary_before'] == proof['primary_after']
    assert proof['recovered_before'] == proof['recovered_after']
    (BASE / ('attempt-' + str(attempt) + '.json')).write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    print('dated route attempt', attempt, actual.returncode, actual.stdout[-700:], actual.stderr[-3000:])
    raise SystemExit(actual.returncode)


if __name__ == '__main__':
    main()

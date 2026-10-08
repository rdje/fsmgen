"""Capture dated installed-store integration at an unchanged committed index."""
import base64
import gzip
import hashlib
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path.cwd()
BASE = Path('docs/audits/decision-index-integration-20261008')
BINDINGS = ('doctrine/live_document_size/surfaces.jsonl',
            'doctrine/live_document_size/ceiling_increase_authorities.jsonl')
sys.path.insert(0, str(ROOT / 'scripts'))
import decision_records as records
import decision_store_git as selected


def run(command):
    result = subprocess.run(command, capture_output=True)
    if result.returncode:
        raise ValueError((command, result.returncode, result.stderr.decode()))
    return {'command': command, 'status': result.returncode,
            'stdout': result.stdout.decode(), 'stderr': result.stderr.decode()}


def packed(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest(),
            'gzip_base64': base64.b64encode(gzip.compress(raw, mtime=0)).decode()}


def main():
    revision = run(['git', '--no-replace-objects', 'rev-parse', 'HEAD'])['stdout'].strip()
    sources = {path: Path(path).read_text() for path in
               ['scripts/' + name + '.py' for name in
                ('decision_records', 'decision_store_git', 'decision_store', 'decision_catalog')]
               + [str(BASE / 'qualify.py'), str(BASE / 'verify.py')]}
    rows = []
    blobs = {}
    for selector in ('index', revision):
        command = (['git', '--no-replace-objects', 'ls-files', '--stage', '-z']
                   if selector == 'index' else
                   ['git', '--no-replace-objects', 'ls-tree', '-r', '--full-tree', '-z', revision])
        native = subprocess.run(command, capture_output=True)
        assert native.returncode == 0 and not native.stderr
        snapshot = records.selected_snapshot(ROOT, selector, bindings=BINDINGS)
        for mode, oid in snapshot.objects.values():
            assert mode in selected.REGULAR_MODES
            if oid not in blobs:
                blobs[oid] = run(['git', '--no-replace-objects', 'cat-file', 'blob', oid])['stdout']
        public = run(['scripts/decision_records.py', '--snapshot', selector, 'check'])
        rows.append({'selector': selector, 'revision': snapshot.revision,
                     'objects': snapshot.objects, 'root_paths': snapshot.root_paths,
                     'inventory_bytes': snapshot.inventory_bytes,
                     'native': {'command': command, 'status': native.returncode,
                                'stdout': packed(native.stdout), 'stderr': native.stderr.decode()},
                     'public': public})
    continuity = run(['scripts/decision_records.py', '--snapshot', 'index',
                      '--prior-snapshot', revision, '--bind-file', BINDINGS[0],
                      '--bind-file', BINDINGS[1], 'check-continuity'])
    prior = Path('docs/audits/decision-index-repair-20261008/proof.json').read_bytes()
    proof = {'scope': 'Dated installed index/tree/catalog/control integration; original-coordinate, HIAL, visual, full CI and push remain open.',
             'revision': revision, 'sources': sources, 'bindings': BINDINGS,
             'rows': rows, 'blobs': blobs, 'continuity': continuity,
             'repair_proof': {'bytes': len(prior), 'sha256': hashlib.sha256(prior).hexdigest()},
             'limits': {'inventory': selected.MAX_INVENTORY_BYTES,
                        'paths': selected.MAX_TRACKED_PATHS}}
    (BASE / 'proof.json').write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    print('PASS dated actual installed index/tree/catalog/control capture; final staged integration remains separately gated.')


if __name__ == '__main__':
    main()

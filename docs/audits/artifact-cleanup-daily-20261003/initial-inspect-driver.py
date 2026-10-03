"""Fixed, Git-authenticated source replay cache cleanup; no caller targets."""
import hashlib
import importlib.util
import json
import os
import shutil
import stat
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
BASE = Path(__file__).parent
REVISION = '93ff524834b748004510e10befad4df4cd8cc5fe'
PREFIX = '.artifacts/reservation-coverage-historical-context-20261003/' + REVISION
TARGETS = tuple(PREFIX + '/' + mode for mode in ('ordinary', 'decoy'))
BEFORE = ROOT / '.artifacts/artifact-cleanup-daily-20261003-before.json'
spec = importlib.util.spec_from_file_location('RetainedCleanupBoundary', ROOT / 'docs/audits/artifact-cleanup-daily-20261002/cleanup.py')
legacy = importlib.util.module_from_spec(spec); spec.loader.exec_module(legacy)


def digest(raw): return hashlib.sha256(raw).hexdigest()


def census(relative):
    assert relative in TARGETS, 'unowned cleanup target'
    path = ROOT / relative
    assert not path.is_symlink() and path.is_dir()
    for parent in (path, *path.parents):
        if parent == ROOT: break
        assert not parent.is_symlink() and not (parent / '.git').exists(), 'foreign parent or Git boundary'
    assert sorted(p.name for p in path.iterdir()) == ['index', 'tree']
    files, nodes = [], []
    for directory, children, names in os.walk(path, followlinks=False):
        assert '.git' not in children and '.git' not in names
        for child in children: assert not (Path(directory) / child).is_symlink()
        for item in (Path(directory), *[Path(directory) / name for name in names]):
            info = item.lstat()
            assert info.st_dev == ROOT.stat().st_dev and (stat.S_ISDIR(info.st_mode) or stat.S_ISREG(info.st_mode))
            if item.is_file():
                assert info.st_nlink == 1 and info.st_size <= 64 * 1024 * 1024
                assert item.suffix not in ('.log', '.bin'), 'cache contains a log/native artifact'
                raw = item.read_bytes(); after = item.lstat()
                assert (info.st_dev, info.st_ino, info.st_size, info.st_mtime_ns, info.st_mode) == (
                    after.st_dev, after.st_ino, after.st_size, after.st_mtime_ns, after.st_mode)
                files.append({'path': str(item.relative_to(ROOT)), 'bytes': len(raw), 'sha256': digest(raw)})
            nodes.append({'path': str(item.relative_to(ROOT)), 'device': info.st_dev, 'inode': info.st_ino,
                'mode': info.st_mode, 'nlink': info.st_nlink, 'size': info.st_size, 'mtime_ns': info.st_mtime_ns})
    files.sort(key=lambda row: row['path']); nodes.sort(key=lambda row: row['path'])
    assert len(files) <= 4096 and len(nodes) <= 4608 and sum(r['bytes'] for r in files) <= 512 * 1024 * 1024
    assert not subprocess.check_output(['git', 'ls-files', '--', relative], cwd=ROOT)
    independent = subprocess.check_output(['rg', '--files', '--hidden', '--no-ignore', relative], cwd=ROOT, text=True).splitlines()
    assert sorted(independent) == [r['path'] for r in files]
    context = json.loads((ROOT / 'docs/audits/reservation-coverage-historical-context-20261003' /
        ('ordinary-context.json' if relative.endswith('/ordinary') else 'decoy-context.json')).read_text())
    assert context['revision'] == REVISION
    expected = {relative + '/index'} | {relative + '/tree/' + name for name in context['members']}
    assert {r['path'] for r in files} == expected
    for name, row in context['members'].items():
        raw = subprocess.check_output(['git', 'show', REVISION + ':' + name], cwd=ROOT)
        assert len(raw) == row['bytes'] and digest(raw) == row['sha256']
        actual = (path / 'tree' / name).read_bytes()
        if relative.endswith('/decoy') and name == 't/1960-isf-formal-reservation-coverage.t':
            raw += b'\n# owned projected hot-source decoy\n'
        assert actual == raw, ('generated cache source drift', name)
    env = dict(os.environ, GIT_DIR=str(ROOT / '.git'), GIT_WORK_TREE=str(path / 'tree'), GIT_INDEX_FILE=str(path / 'index'))
    indexed = subprocess.check_output(['git', 'ls-files', '--stage', '-z'], cwd=ROOT, env=env)
    source_tree = subprocess.check_output(['git', 'ls-tree', '-r', '-z', REVISION], cwd=ROOT)
    index_rows = {}
    for entry in indexed.split(b'\0'):
        if not entry: continue
        header, name = entry.split(b'\t', 1); mode, blob, stage = header.split()
        assert stage == b'0'; index_rows[name] = (mode, blob)
    git_rows = {}
    for entry in source_tree.split(b'\0'):
        if not entry: continue
        header, name = entry.split(b'\t', 1); mode, kind, blob = header.split(); git_rows[name] = (mode, blob)
    assert index_rows == git_rows, 'generated separate index does not represent the pinned revision'
    return {'path': relative, 'files': files, 'nodes': nodes,
        'bytes_total': sum(r['bytes'] for r in files), 'git_revision': REVISION,
        'index_entries': len(index_rows), 'independent_membership': 'rg agrees with os.walk'}


def protected():
    result = legacy.protected()
    for path in (ROOT / 'docs/audits').glob('reservation-coverage-*'):
        for item in path.rglob('*'):
            if item.is_file():
                assert not item.is_symlink() and item.stat().st_dev == ROOT.stat().st_dev
                raw = item.read_bytes(); result['members'][str(item.relative_to(ROOT))] = {'bytes': len(raw), 'sha256': digest(raw)}
    result['primary_git'] = {name: digest((ROOT / '.git' / name).read_bytes()) for name in ('index', 'config', 'HEAD')}
    return result


def main():
    assert sys.argv[1:] in (['--inspect'], ['--apply']), 'use a fixed inspect/apply action'
    if sys.argv[1:] == ['--inspect']:
        value = [census(path) for path in TARGETS]
        BEFORE.write_text(json.dumps(value, sort_keys=True, indent=2) + '\n')
        print('PASS fixed complete Git source/index cache inspection', [(r['path'], len(r['files']), r['bytes_total']) for r in value])
        return
    before = json.loads(BEFORE.read_text())
    assert [census(path) for path in TARGETS] == before, 'cache identity changed since inspection'
    old_record = (ROOT / 'docs/ARTIFACT_CLEANUP.md').read_text()
    old_time = datetime.fromisoformat(old_record.splitlines()[2].split(' — ', 1)[0])
    now = datetime.now(timezone.utc)
    assert (now - old_time).total_seconds() > 86400, 'daily cleanup is not yet due'
    rust = legacy.rust_census(); protected_before = protected()
    for relative in TARGETS: shutil.rmtree(ROOT / relative)
    residue = {relative: os.path.lexists(ROOT / relative) for relative in TARGETS}
    assert not any(residue.values())
    protected_after = protected(); assert protected_before == protected_after, 'protected native/source/Git bytes changed'
    (BASE / 'protected.json').write_text(json.dumps({'before': protected_before, 'after': protected_after}, sort_keys=True, indent=2) + '\n')
    report = {'owner': 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.68', 'utc': now.isoformat(),
        'prior_utc': old_time.isoformat(), 'cleanup_revision': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
        'removed': before, 'residue': residue, 'rust': rust,
        'scope': 'Only two Git-authenticated duplicate historical source trees and their generated separate indexes; original source/audits, all logs/native/compiler evidence and current book retained.',
        'reproduction': 'Published Git checkout-index/read-tree recipe in reservation-coverage-historical-context-20261003/run_context.py reconstructs the exact fixed source/index views; actual decoy comment is explicitly bound.'}
    (BASE / 'result.json').write_text(json.dumps(report, sort_keys=True, indent=2) + '\n')
    (ROOT / 'docs/ARTIFACT_CLEANUP.md').write_text('# Latest artifact cleanup\n\n' + now.isoformat() + ' — Removed only two authenticated duplicate historical source/index caches; exact residue and protected-byte checks pass. Current book, logs, native/compiler/audit evidence retained; Rust log/bin census preserved.\n')
    print('PASS exact generated replay caches removed; complete selected residue absent; primary Git/current source/book/native evidence retained')


if __name__ == '__main__': main()

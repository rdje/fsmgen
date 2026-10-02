"""One dated, fixed-target cleanup; never delete arbitrary caller paths."""

import hashlib
import json
import os
import shutil
import stat
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
TARGETS = ('.artifacts/formal-preallocation-admission/book',)
REPORT = ROOT / 'docs/audits/artifact-cleanup-daily-20261002/result.json'
BEFORE = ROOT / '.artifacts/artifact-cleanup-daily-20261002-before.json'


def census(relative):
    path = ROOT / relative
    if path.is_symlink() or not path.is_dir():
        raise ValueError('required regular render directory unavailable: ' + relative)
    for parent in (path, *path.parents):
        if parent == ROOT:
            break
        if parent.is_symlink():
            raise ValueError('render parent is a symlink')
        if (parent / '.git').exists():
            raise ValueError('existing nested Git boundary: ' + relative)
    root_device = ROOT.stat().st_dev
    files, nodes, total = [], [], 0
    for directory, children, names in os.walk(path, followlinks=False):
        if '.git' in children or '.git' in names:
            raise ValueError('nested Git repository inside render')
        for item in [Path(directory), *[Path(directory) / name for name in names]]:
            info = item.lstat()
            if info.st_dev != root_device or not (stat.S_ISDIR(info.st_mode) or stat.S_ISREG(info.st_mode)):
                raise ValueError('render contains a symlink, foreign volume or special node')
            if item.is_file():
                if info.st_nlink != 1:
                    raise ValueError('render file has ambiguous shared hard links')
                if info.st_size > 64 * 1024 * 1024:
                    raise ValueError('render file exceeds cleanup read bound')
                data = item.read_bytes()
                if item.lstat() != info:
                    # Reading can change atime; stable identity excludes it.
                    after = item.lstat()
                    if (after.st_dev, after.st_ino, after.st_size, after.st_mtime_ns, after.st_mode) != (
                            info.st_dev, info.st_ino, info.st_size, info.st_mtime_ns, info.st_mode):
                        raise ValueError('render file changed while reading')
                total += len(data)
                files.append({'path': str(item.relative_to(ROOT)), 'bytes': len(data),
                              'sha256': hashlib.sha256(data).hexdigest()})
            nodes.append({'path': str(item.relative_to(ROOT)), 'device': info.st_dev,
                          'inode': info.st_ino, 'mode': info.st_mode, 'nlink': info.st_nlink, 'size': info.st_size,
                          'mtime_ns': info.st_mtime_ns})
        # Directory symlinks are not followed by os.walk, so reject separately.
        for name in children:
            if (Path(directory) / name).is_symlink():
                raise ValueError('render contains a directory symlink')
        if len(files) > 4096 or len(nodes) > 4608 or total > 512 * 1024 * 1024:
            raise ValueError('render census exceeds fixed cleanup bounds')
    files.sort(key=lambda row: row['path'])
    nodes.sort(key=lambda row: row['path'])
    if subprocess.check_output(['git', 'ls-files', '--', relative], cwd=ROOT):
        raise ValueError('render contains tracked files')
    current_names = {str(p.relative_to(ROOT / 'docs/book/book'))
                     for p in (ROOT / 'docs/book/book').rglob('*') if p.is_file()}
    for member in files:
        name = str(Path(member['path']).relative_to(relative))
        if name not in current_names and not (name.startswith('searchindex-') and name.endswith('.js')):
            raise ValueError('render member is not a maintained mdBook output: ' + name)
    index = (path / 'index.html').read_bytes()
    if b'Book generated using mdBook' not in index or b'FSMGen Book' not in index:
        raise ValueError('target does not identify a generated project book')
    independent = subprocess.run(['rg', '--files', '--hidden', '--no-ignore', relative],
                                 cwd=ROOT, capture_output=True, check=True, timeout=30)
    if sorted(independent.stdout.decode().splitlines()) != [row['path'] for row in files]:
        raise ValueError('independent render member census differs')
    return {'path': relative, 'files': files, 'nodes': nodes, 'bytes_total': total}


def rust_census():
    result = []
    for base in ('target', 'rust/target'):
        for suffix in ('release', 'debug/incremental', 'debug/deps'):
            relative = base + '/' + suffix
            path = ROOT / relative
            if not path.exists():
                result.append({'path': relative, 'status': 'absent', 'retained': []})
                continue
            if path.is_symlink() or path.stat().st_dev != ROOT.stat().st_dev:
                raise ValueError('Rust artifact location is not an owned same-volume directory')
            retained = []
            for directory, children, names in os.walk(path, followlinks=False):
                if Path(directory).stat().st_dev != ROOT.stat().st_dev:
                    raise ValueError('foreign volume in Rust artifact census')
                if '.git' in children or '.git' in names:
                    raise ValueError('nested Git boundary in Rust artifact census')
                children[:] = [name for name in children if not (Path(directory) / name).is_symlink()]
                for name in names:
                    if name.endswith(('.log', '.bin')):
                        item = Path(directory) / name
                        retained.append(str(item.relative_to(ROOT)))
                        if len(retained) > 10000:
                            raise ValueError('Rust artifact candidate census exceeds bound')
            result.append({'path': relative, 'status': 'censused', 'retained': sorted(retained)})
    return result


def protected():
    names = set()
    for directory in ('docs/book/book', 'docs/audits/source-origin-constructor-causes-20261002',
                      'docs/audits/constructor-cause-repair-20261002',
                      'docs/audits/origin-helper-cause-repair-20261002'):
        names.update(str(p.relative_to(ROOT)) for p in (ROOT / directory).rglob('*') if p.is_file())
    names.update(subprocess.check_output(['git', 'ls-files', 'bin', 'perl', 't'], cwd=ROOT).decode().splitlines())
    logs = []
    for directory, children, files in os.walk(ROOT / '.artifacts', followlinks=False):
        if '.git' in children or '.git' in files:
            children[:] = []
            continue
        children[:] = [name for name in children if not (Path(directory) / name).is_symlink()]
        for name in files:
            if name.endswith(('.bin', '.log')):
                p = Path(directory) / name
                if p.is_symlink(): continue
                relative = str(p.relative_to(ROOT)); logs.append(relative); names.add(relative)
    result = {}
    for name in sorted(names):
        p = ROOT / name
        if p.is_symlink() or p.stat().st_dev != ROOT.stat().st_dev:
            raise ValueError('protected member crosses a volume/symlink boundary: ' + name)
        digest = hashlib.sha256(); size = 0
        with p.open('rb') as stream:
            for chunk in iter(lambda: stream.read(1024 * 1024), b''):
                digest.update(chunk); size += len(chunk)
        result[name] = {'bytes': size, 'sha256': digest.hexdigest()}
    return {'members': result, 'log_bin_names': sorted(logs)}


def main():
    if sys.argv[1:] == ['--inspect']:
        before = [census(path) for path in TARGETS]
        BEFORE.parent.mkdir(parents=True, exist_ok=True)
        BEFORE.write_text(json.dumps(before, indent=2, sort_keys=True) + '\n')
        print(json.dumps({row['path']: {'files': len(row['files']), 'bytes_total': row['bytes_total']}
                          for row in before}, sort_keys=True))
    elif sys.argv[1:] == ['--apply']:
        before = json.loads(BEFORE.read_text())
        current = [census(path) for path in TARGETS]
        if current != before:
            raise ValueError('inspected renderer identity changed before deletion')
        rust = rust_census()
        if not (ROOT / 'docs/book/book/index.html').is_file():
            raise ValueError('current generated book is unavailable')
        protected_before = protected()
        # Exact fixed, independently censused generated directories only.
        for path in TARGETS:
            shutil.rmtree(ROOT / path)
        residue = {path: os.path.lexists(ROOT / path) for path in TARGETS}
        if any(residue.values()):
            raise ValueError('selected generated render residue remains')
        protected_after = protected()
        if protected_before != protected_after:
            raise ValueError('protected byte/member identities changed')
        (REPORT.parent / 'protected.json').write_text(json.dumps({'before': protected_before, 'after': protected_after}, indent=2, sort_keys=True) + '\n')
        report = {'owner': 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.67',
            'cleanup_revision': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT).decode().strip(),
            'utc': datetime.now(timezone.utc).isoformat(), 'removed': before,
            'independent_membership': 'os.walk regular-file set equals rg --files --hidden --no-ignore',
            'residue': residue, 'rust': rust,
            'limits': ['Deleted render bytes are intentionally not retained.',
                       'The old renders do not bind their original producing Git revision; their byte census is a dated capture, not a reproduced historical build.'],
            'retained': ['all logs', 'native/receipt evidence', 'spent compiler workspaces', 'docs/book/book'],
            'scope': 'Fixed obsolete generated mdBook copies from completed local documentation slices; no source, existing nested Git repository, native evidence or shared cache deletion.'}
        REPORT.write_text(json.dumps(report, indent=2, sort_keys=True) + '\n')
        print('cleanup: exact generated renders removed; selected residue absent; current book and evidence retained')
    elif sys.argv[1:] == ['--verify-saved']:
        report = json.loads(REPORT.read_text())
        if [row['path'] for row in report['removed']] != list(TARGETS):
            raise ValueError('saved fixed target population changed')
        if any(os.path.lexists(ROOT / path) for path in TARGETS):
            raise ValueError('removed render path is present again')
        if report['residue'] != {path: False for path in TARGETS}:
            raise ValueError('saved residue product changed')
        for row in report['removed']:
            if sum(member['bytes'] for member in row['files']) != row['bytes_total']:
                raise ValueError('saved file allocation differs from aggregate')
        if not (ROOT / 'docs/book/book/index.html').is_file():
            raise ValueError('retained current generated book is unavailable')
        print('cleanup: saved exact target/member allocation and fresh absence verified')
    else:
        raise ValueError('use --inspect, --apply or --verify-saved')


if __name__ == '__main__':
    main()

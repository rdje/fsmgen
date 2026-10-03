"""Replay pinned cold qualification using the same Git store and a local index.

Only repository-owned generated projection/index/log files are written. No new
repository, worktree registration, primary index/config change or archive edit.
"""
import argparse
import hashlib
import json
import os
import subprocess
import sys
from pathlib import Path


def digest(raw): return hashlib.sha256(raw).hexdigest()


def checked_relative(root, value):
    path = Path(value)
    assert not path.is_absolute() and '..' not in path.parts and path.parts
    result = root / path
    assert result.resolve().is_relative_to(root) and not result.is_symlink()
    return result


def selected(name):
    return (name.split('/')[0] in ('bin', 'perl', 't', 'scripts', 'isf')
        or name.startswith('docs/audits/reservation-coverage-')
        or name == 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md')


def replay(binding, output, mode='ordinary'):
    assert mode in ('ordinary', 'decoy')
    root = Path.cwd().resolve()
    git_dir = Path(subprocess.check_output(['git', 'rev-parse', '--absolute-git-dir'], text=True).strip()).resolve()
    assert git_dir == root / '.git', 'run from the primary repository root'
    protected = {name: digest((git_dir / name).read_bytes()) for name in ('index', 'config', 'HEAD')}
    primary_revision = subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip()
    assert set(binding) == {'revision', 'reader', 'reader_bytes', 'reader_sha256', 'workspace'}
    assert len(binding['revision']) == 40 and all(c in '0123456789abcdef' for c in binding['revision'])
    assert binding['reader'] == 'docs/audits/reservation-coverage-source-copy-checks-20261003/reverify.py'
    workspace = checked_relative(root, binding['workspace']) / binding['revision'] / mode
    assert workspace.is_relative_to(root / '.artifacts')
    workspace.mkdir(parents=True, exist_ok=True)
    assert workspace.stat().st_dev == root.stat().st_dev
    tree = workspace / 'tree'; index = workspace / 'index'
    assert not tree.is_symlink() and not index.is_symlink()
    if tree.exists():
        assert tree.is_dir() and tree.stat().st_dev == root.stat().st_dev
        for path in tree.rglob('*'):
            assert not path.is_symlink() and path.stat().st_dev == root.stat().st_dev
    env = dict(os.environ, GIT_DIR=str(git_dir), GIT_WORK_TREE=str(tree), GIT_INDEX_FILE=str(index))
    # Published Git object/index interfaces, with an explicitly separate index.
    entries = subprocess.check_output(['git', 'ls-tree', '-r', '-z', binding['revision']], cwd=root)
    members = {}
    for entry in entries.split(b'\0'):
        if not entry: continue
        header, raw_name = entry.split(b'\t', 1)
        mode_bits, kind, blob = header.decode().split(); name = raw_name.decode()
        if not selected(name): continue
        assert mode_bits in ('100644', '100755') and kind == 'blob', ('non-plain selected source', name)
        assert not Path(name).is_absolute() and '..' not in Path(name).parts
        members[name] = {'blob': blob, 'mode': mode_bits}
    assert binding['reader'] in members and members
    reader = None
    with subprocess.Popen(['git', 'cat-file', '--batch'], cwd=root, stdin=subprocess.PIPE, stdout=subprocess.PIPE) as objects:
        for name, row in members.items():
            objects.stdin.write((row['blob'] + '\n').encode()); objects.stdin.flush()
            header = objects.stdout.readline().decode().split()
            assert header[:2] == [row['blob'], 'blob'] and len(header) == 3
            raw = objects.stdout.read(int(header[2])); assert objects.stdout.read(1) == b'\n'
            row.update(bytes=len(raw), sha256=digest(raw))
            if name == binding['reader']: reader = raw
        objects.stdin.close(); assert objects.wait() == 0
    assert reader is not None
    assert len(reader) == binding['reader_bytes'] and digest(reader) == binding['reader_sha256']
    fresh = not tree.exists()
    if fresh:
        tree.mkdir()
        subprocess.run(['git', 'read-tree', binding['revision']], cwd=root, env=env, check=True)
    existing = {str(p.relative_to(tree)) for p in tree.rglob('*') if p.is_file() or p.is_symlink()}
    assert existing <= set(members), 'unowned projection file'
    missing = set(members) - existing
    if missing:
        names = b''.join(name.encode() + b'\0' for name in sorted(missing))
        subprocess.run(['git', 'checkout-index', '-z', '--stdin', '--prefix=' + str(tree) + '/'], cwd=root, env=env, input=names, check=True)
    if fresh and mode == 'decoy':
        # Genuine source identity drift in an owned projection, never in
        # the primary test or a sealed archive. The unchanged cold source
        # checks must expose this unsafe context even though it is a comment.
        path = tree / 't/1960-isf-formal-reservation-coverage.t'
        path.write_bytes(path.read_bytes() + b'\n# owned projected hot-source decoy\n')
    actual_names = {str(p.relative_to(tree)) for p in tree.rglob('*') if p.is_file() or p.is_symlink()}
    assert actual_names == set(members), 'projection omission or unowned file'
    assert index.is_file() and index.stat().st_dev == root.stat().st_dev
    mismatches = []
    for name, row in members.items():
        path = tree / name
        assert not path.is_symlink() and path.stat().st_dev == root.stat().st_dev
        raw = path.read_bytes()
        if len(raw) != row['bytes'] or digest(raw) != row['sha256']: mismatches.append(name)
    assert mismatches == ([] if mode == 'ordinary' else ['t/1960-isf-formal-reservation-coverage.t']), ('unexpected context drift', mismatches)
    result = subprocess.run([sys.executable, '-B', binding['reader']], cwd=tree, env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    text = result.stdout.decode().replace(str(root), '${REPO_ROOT}')
    output = checked_relative(root, str(output)); output.mkdir(parents=True, exist_ok=True)
    (output / (mode + '.txt')).write_text(text)
    (output / (mode + '.status')).write_text(str(result.returncode) + '\n')
    after = {name: digest((git_dir / name).read_bytes()) for name in protected}
    after_revision = subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip()
    assert after == protected, 'primary Git state changed'
    assert after_revision == primary_revision, 'primary revision changed'
    record = {'revision': binding['revision'], 'reader': binding['reader'], 'mode': mode,
        'members': members, 'mismatches': mismatches, 'reader_status': result.returncode,
        'primary_git_before': protected, 'primary_git_after': after,
        'primary_revision_before': primary_revision, 'primary_revision_after': after_revision,
        'workspace': str(workspace.relative_to(root)), 'same_volume': True}
    (output / (mode + '-context.json')).write_text(json.dumps(record, indent=2, sort_keys=True) + '\n')
    if mode == 'ordinary':
        assert result.returncode == 0 and 'PASS complete initial/current Git/source and done semantic/control owners' in text
    else:
        causes = [line for line in text.splitlines() if line.startswith('AssertionError:')]
        assert result.returncode == 1 and causes == ['AssertionError: t/1960-isf-formal-reservation-coverage.t'], 'decoy did not fail at exact original source identity'
    print('PASS pinned historical cold context' if mode == 'ordinary' else 'PASS actual projected source decoy rejected at the original test identity')
    return record


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--binding', required=True)
    parser.add_argument('--output', required=True)
    parser.add_argument('--mode', choices=('ordinary', 'decoy'), default='ordinary')
    options = parser.parse_args()
    replay(json.loads(Path(options.binding).read_text()), options.output, options.mode)

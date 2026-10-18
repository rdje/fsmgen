"""Retain a separate later source/cache observation without repairing the after gap."""
import argparse
from datetime import datetime, timezone
import gzip
import json
import os
from pathlib import Path
import stat
import subprocess

import execute
import prepare
import selected_checkout as checkout

PATH = execute.AUDIT / 'selected-postrun-sources.json.gz'
CACHE = '.artifacts/knowledge-map/query/questions.jsonl'
EXTRA_DIRECTORIES = ['.artifacts/knowledge-map', '.artifacts/knowledge-map/query']
SOURCES = ('knowledge-map/scripts/query_knowledge_map.sh', 'knowledge-map/scripts/knowledge_map.pl',
           'scripts/check_record_value_publication.py',
           'docs/audits/original-context-cause-consumer-prerequisites-20261012/verify.py')
OPTIONAL = ('.knowledge_map.conf', 'knowledge-map/scripts/knowledge_map.conf')


def runtime_file():
    path = execute.ROOT / checkout.FOLDER / CACHE
    for parent in (execute.ROOT / checkout.FOLDER, *reversed(path.parents)):
        if not parent.is_relative_to(execute.ROOT / checkout.FOLDER):
            continue
        assert parent.is_dir() and not parent.is_symlink()
        assert parent.stat().st_dev == execute.ROOT.stat().st_dev
        if parent != execute.ROOT / checkout.FOLDER:
            assert not (parent / '.git').exists() and not (parent / '.git').is_symlink()
    before = path.lstat()
    assert stat.S_ISREG(before.st_mode) and before.st_dev == execute.ROOT.stat().st_dev
    body = path.read_bytes()
    after = path.lstat()
    keys = ('st_dev', 'st_ino', 'st_size', 'st_mtime_ns', 'st_mode')
    assert all(getattr(before, key) == getattr(after, key) for key in keys)
    assert len(body) == before.st_size
    return dict(prepare.blob(body), mode=stat.S_IMODE(before.st_mode))


def membership(image):
    root = execute.ROOT / checkout.FOLDER
    files, directories = set(), set()
    for folder, dirs, names in os.walk(root, followlinks=False):
        parent = Path(folder)
        assert parent.stat().st_dev == execute.ROOT.stat().st_dev
        for child in dirs[:]:
            path = parent / child
            if path.is_symlink():
                dirs.remove(child)
                names.append(child)
            else:
                assert path.stat().st_dev == execute.ROOT.stat().st_dev
                assert not (path / '.git').exists() and not (path / '.git').is_symlink()
                directories.add(str(path.relative_to(root)))
        files.update(str((parent / name).relative_to(root)) for name in names)
    source_directories = {str(parent) for name in image['members'] for parent in Path(name).parents
                          if str(parent) != '.'}
    assert files == set(image['members']) | {'.git', CACHE}
    assert directories == source_directories | set(image['runtime_directories']) | set(EXTRA_DIRECTORIES)
    return dict(files=sorted(files), directories=sorted(directories))


def capture():
    assert not execute.safe(PATH).exists(), 'exclusive later observation; never overwrite a saved capture'
    image = json.loads(gzip.decompress(execute.read(checkout.MANIFEST)))
    initial = json.loads(gzip.decompress(execute.read(execute.AUDIT / 'selected-prerequisites-actual.json.gz')))
    before = runtime_file()
    names = membership(image)
    source = checkout.inspect(execute.ROOT / checkout.FOLDER, image['members'],
                              image['runtime_directories'] + EXTRA_DIRECTORIES, {'.git', CACHE})
    assert source == initial['snapshot_before']['members']
    git = checkout.git_state()
    assert git['entries'] == initial['snapshot_before']['git']['entries']
    programmes = {}
    for name in SOURCES:
        body = (execute.ROOT / checkout.FOLDER / name).read_bytes()
        assert body == execute.command(['git', '--no-replace-objects', 'show', checkout.constraints.REVISION + ':' + name])
        programmes[name] = prepare.blob(body)
    optional = {}
    for name in OPTIONAL:
        path = execute.ROOT / checkout.FOLDER / name
        if name in image['members']:
            body = path.read_bytes()
            assert body == execute.command(['git', '--no-replace-objects', 'show', checkout.constraints.REVISION + ':' + name])
            optional[name] = prepare.blob(body)
        else:
            assert not path.exists() and not path.is_symlink()
            optional[name] = None
    # Public read-only direct query: it neither creates nor refreshes the cache.
    command = ['scripts/run_with_ram_guard.sh', '--', 'knowledge-map/scripts/query_knowledge_map.sh', '--all', '--no-cache']
    native = subprocess.run(command, cwd=execute.ROOT / checkout.FOLDER, capture_output=True)
    result = dict(command=command, status=native.returncode, stdout=prepare.blob(native.stdout), stderr=prepare.blob(native.stderr))
    value = dict(schema='fsmgen.selected_later_source_cache_observation.v1',
                 timestamp=datetime.now(timezone.utc).isoformat(), revision=checkout.constraints.REVISION,
                 members=source, git=git, membership=names, runtime_directories=image['runtime_directories'] + EXTRA_DIRECTORIES,
                 runtime_files={CACHE: before}, programmes=programmes, optional_programmes=optional, direct_query=result,
                 cache_after=runtime_file(), membership_after=membership(image),
                 source_instruments={name: prepare.blob(execute.read(execute.AUDIT / name))
                                     for name in ('selected_postrun.py', 'selected_checkout.py', 'execute.py', 'prepare.py')},
                 scope='Separate later complete source/member/mode/link/index and cache observation. The original '
                       'immediate after observation remains valueNone/error and unqualified. Native0 semantic stdout '
                       'does not supply custody acceptance. The query is public read-only diagnostics, never a semantic '
                       'cohort or original native/provider producer. No spent slot is replayed or cache removed.')
    execute.save(PATH, value)
    assert type(native.returncode) is int and native.returncode == 0
    assert native.stderr.startswith(b'ram-guard: PID ') and b'ram-guard: terminating PID tree' not in native.stderr
    assert before == value['cache_after'] and names == value['membership_after']
    return value


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true', required=True)
    parser.parse_args()
    capture()
    print('Separate later complete selected source/index and cache custody retained; original immediate-after gap stays unqualified.')

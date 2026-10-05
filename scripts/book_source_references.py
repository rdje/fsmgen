#!/usr/bin/env python3
"""Generate and check the finite native book source-view projection."""
import argparse
import json
import os
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SELECTION = 'docs/audits/book-reference-selection-20261005/selected-routes.json'
SELECTION_REVISION = '3e8bf1b2c0e2d05317e1ed1703ad96c63d44342c'
PLANE = 'docs/book/src/reference-source'
MANIFEST = PLANE + '/routes.jsonl'
CHAPTERS = {'13k-isf-feature-support-matrix', '90-reference-map'}
ROLES = {'retained-engineering-evidence', 'focused-product-or-maintainer-reference',
         'maintainer-policy-or-review', 'operational-state-or-direction', 'decision-reference'}
# Two admitted chapter populations, each bounded by the portable 128-member
# metadata-array domain. Exact semantic membership is separately source-pinned.
CHAPTER_LIMIT = 128
ROW_LIMIT = CHAPTER_LIMIT * len(CHAPTERS)
ROW_BYTES = 1024
MANIFEST_BYTES = ROW_LIMIT * (ROW_BYTES + 1)
# Preserve raw source views within the largest focused canonical source budget;
# other source owners retain their own tighter budgets independently.
SOURCE_BYTES = 262144
SOURCE_LINES = 5000
SOURCE_LINE_BYTES = 8192


def require(condition, message):
    if not condition: raise ValueError(message)


def relative(value, maximum=512):
    require(type(value) is str and 0 < len(value.encode()) <= maximum, 'bounded scalar path')
    require(re.fullmatch(r'[A-Za-z0-9_./-]+', value) is not None, 'portable source path grammar')
    require(not value.startswith('/') and all(v not in ('', '.', '..') for v in value.split('/')), 'repository-relative contained path')
    return value


def asset_for(source):
    return 'reference-source/' + (source[:-3]+'.markdown' if source.endswith('.md') else source) + '.source.txt'


def validate_rows(rows):
    require(type(rows) is list and 0 < len(rows) <= ROW_LIMIT, 'bounded route population')
    for row in rows:
        require(type(row) is dict and set(row) == {'chapter','source','asset','role'}, 'closed route record')
        require(type(row['chapter']) is str and row['chapter'] in CHAPTERS, 'admitted chapter')
        require(type(row['role']) is str and row['role'] in ROLES, 'admitted source role')
        relative(row['source'], 256); relative(row['asset'])
        require(row['asset'] == asset_for(row['source']), 'native-safe source address')
    for chapter in CHAPTERS:
        require(sum(row['chapter'] == chapter for row in rows) <= CHAPTER_LIMIT, 'bounded chapter route population')
    require(len({r['source'] for r in rows}) == len(rows), 'unique complete source identity')
    require(len({r['asset'] for r in rows}) == len(rows), 'injective asset addresses')


def expected_rows():
    raw = local_read(ROOT / SELECTION, MANIFEST_BYTES)
    committed = subprocess.check_output(['git','-C',str(ROOT),'show',SELECTION_REVISION+':'+SELECTION])
    require(raw == committed, 'immutable qualified selection identity')
    rows = [{k:r[k] for k in ('chapter','source','asset','role')} for r in json.loads(raw)['routes']]
    validate_rows(rows)
    return sorted(rows, key=lambda r:r['source'])


def encode(rows):
    validate_rows(rows)
    lines = [json.dumps(r, sort_keys=True, separators=(',', ':'), ensure_ascii=True).encode() for r in rows]
    require(all(len(line) <= ROW_BYTES for line in lines), 'bounded route record bytes')
    raw = b'\n'.join(lines)+b'\n'; require(len(raw) <= MANIFEST_BYTES, 'bounded whole manifest bytes')
    return raw


def local_parents(path):
    require(path.is_relative_to(ROOT), 'contained endpoint')
    for parent in reversed(path.parents):
        if parent == ROOT: continue
        if parent.is_relative_to(ROOT):
            require(not parent.is_symlink() and parent.is_dir(), 'local non-symlink endpoint parent')
            require(parent.stat().st_dev == ROOT.stat().st_dev, 'same-volume endpoint parent')
            require(not (parent / '.git').exists(), 'no foreign repository endpoint')


def source_bytes(source):
    path = ROOT / relative(source, 256)
    raw = local_read(path, SOURCE_BYTES)
    raw.decode('utf-8', errors='strict')
    require(raw.count(b'\n') <= SOURCE_LINES, 'bounded canonical source lines')
    lines = raw.split(b'\n')
    widths = [len(line.removesuffix(b'\r')) if ordinal < len(lines)-1 else len(line)
              for ordinal,line in enumerate(lines)]
    require(all(width <= SOURCE_LINE_BYTES for width in widths), 'bounded canonical source line')
    return raw


def local_read(path, maximum):
    local_parents(path)
    require(not path.is_symlink() and path.is_file(), 'local regular bounded input')
    state = path.stat()
    require(state.st_dev == ROOT.stat().st_dev and state.st_size <= maximum, 'bounded same-volume input before read')
    with path.open('rb') as stream: raw = stream.read(maximum+1)
    require(len(raw) <= maximum, 'bounded input read')
    return raw


def check_admission(paths):
    result = subprocess.run(['git','-C',str(ROOT),'check-ignore','--no-index','--stdin'],
                            input='\n'.join(paths)+'\n', capture_output=True, text=True)
    require(result.returncode == 1 and not result.stdout, 'all canonical inputs and assets admitted by native ignore policy: '+result.stdout.strip())


def endpoints(rows):
    for row in rows:
        asset = ROOT / 'docs/book/src' / row['asset']
        yield row, asset, os.path.relpath(ROOT / row['source'], asset.parent)


def create_parents(path):
    current = ROOT
    for part in path.relative_to(ROOT).parts[:-1]:
        current /= part
        require(not current.is_symlink(), 'refuse symlink output parent before creation')
        if not current.exists(): current.mkdir()
        require(current.is_dir() and current.stat().st_dev == ROOT.stat().st_dev, 'same-volume output directory')
        require(not (current / '.git').exists(), 'no foreign repository output')


def write(rows):
    for row in rows: source_bytes(row['source'])
    require(not (ROOT / PLANE).is_symlink(), 'real local source-plane directory')
    for row, asset, target in endpoints(rows):
        create_parents(asset); local_parents(asset)
        if asset.is_symlink(): require(os.readlink(asset) == target, 'existing source asset endpoint differs')
        else:
            require(not asset.exists(), 'refuse to replace non-generated source asset')
            asset.symlink_to(target)
    manifest = ROOT / MANIFEST; local_parents(manifest)
    require(not manifest.is_symlink(), 'regular route manifest')
    manifest.write_bytes(encode(rows))


def check(rows, build=None):
    raw = local_read(ROOT / MANIFEST, MANIFEST_BYTES)
    require(raw == encode(rows), 'complete current generated route manifest')
    expected = {MANIFEST}
    for row, asset, target in endpoints(rows):
        expected.add(str(asset.relative_to(ROOT))); local_parents(asset)
        require(asset.is_symlink() and os.readlink(asset) == target, 'exact relative generated asset endpoint')
        require(asset.resolve(strict=True) == ROOT / row['source'], 'exact canonical endpoint identity')
        require(asset.stat().st_dev == ROOT.stat().st_dev, 'same-volume source asset')
        canonical = source_bytes(row['source'])
        with asset.open('rb') as stream: alias = stream.read(SOURCE_BYTES+1)
        require(alias == canonical, 'whole bounded current canonical source bytes')
    actual = {str(p.relative_to(ROOT)) for p in (ROOT / PLANE).rglob('*') if p.is_file() or p.is_symlink()}
    require(actual == expected, 'complete source-plane membership')
    check_admission(sorted(expected | {r['source'] for r in rows}))
    if build is not None:
        output = ROOT / relative(build); local_parents(output / 'endpoint')
        for row in rows:
            target = output / row['asset']; local_parents(target)
            require(local_read(target,SOURCE_BYTES) == source_bytes(row['source']), 'fresh whole native copied source bytes')
        require(local_read(output / 'reference-source/routes.jsonl',MANIFEST_BYTES) == raw, 'native complete manifest delivery')


def check_index(rows):
    """Bind intentional symlinks to the published/staged Git result as well."""
    paths = [MANIFEST] + [str(asset.relative_to(ROOT)) for _,asset,_ in endpoints(rows)]
    data = subprocess.check_output(['git','-C',str(ROOT),'ls-files','--stage','-z','--',*paths])
    indexed = {}
    for entry in data.split(b'\0'):
        if not entry: continue
        metadata,path = entry.decode().split('\t',1); mode,oid,stage = metadata.split()
        require(stage == '0' and path not in indexed, 'unique conflict-free indexed source asset')
        indexed[path] = (mode,oid)
    staged = subprocess.run(['git','-C',str(ROOT),'diff','--cached','--quiet']).returncode
    require(staged in (0,1), 'readable repository staged result')
    producer_indexed = subprocess.run(['git','-C',str(ROOT),'ls-files','--error-unmatch','--','scripts/book_source_references.py'],capture_output=True).returncode == 0
    if not indexed and staged == 0 and not producer_indexed: return  # Unpublished factory preflight.
    require(set(indexed) == set(paths), 'complete source-plane assets in the Git result')
    def check_object(path, mode, raw):
        if path not in indexed:
            entry = subprocess.check_output(['git','-C',str(ROOT),'ls-files','--stage','--',path],text=True).strip()
            require(bool(entry), 'canonical source/producer staged result exists: '+path)
            metadata,actual_path = entry.split('\t',1); actual_mode,oid,stage = metadata.split()
            require(actual_path == path and stage == '0', 'unambiguous canonical staged source')
            indexed[path] = (actual_mode,oid)
        wanted = subprocess.check_output(['git','-C',str(ROOT),'hash-object','--stdin'],input=raw,text=False).decode().strip()
        require(indexed[path] == (mode,wanted), 'checked bytes/mode agree with Git result: '+path)
    check_object(MANIFEST,'100644',encode(rows))
    for _,asset,target in endpoints(rows): check_object(str(asset.relative_to(ROOT)),'120000',target.encode())
    if staged:
        for path in [SELECTION,'scripts/book_source_references.py'] + [r['source'] for r in rows]:
            mode = '100755' if (ROOT/path).stat().st_mode & 0o111 else '100644'
            check_object(path,mode,local_read(ROOT/path,max(SOURCE_BYTES,MANIFEST_BYTES)))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    action = parser.add_mutually_exclusive_group()
    action.add_argument('--write', action='store_true')
    action.add_argument('--check', action='store_true')
    parser.add_argument('--verify-build', help='repository-relative freshly built native output')
    args = parser.parse_args(); rows = expected_rows()
    if args.write: write(rows)
    check(rows, args.verify_build)
    if not args.write: check_index(rows)
    print('book-source-references: complete source/role/member/relative-endpoint/current-byte/ignore contracts hold')


if __name__ == '__main__': main()

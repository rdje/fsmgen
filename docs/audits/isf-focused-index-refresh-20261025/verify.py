#!/usr/bin/env python3
"""Verify this dated catalog transformation, live or at an exact Git revision."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]


def digest(data):
    return hashlib.sha256(data).hexdigest()


def git_bytes(revision, path):
    return subprocess.check_output(['git', '-C', str(ROOT), 'show', f'{revision}:{path}'])


def git_population(revision):
    paths = subprocess.check_output(
        ['git', '-C', str(ROOT), 'ls-tree', '-r', '--name-only', revision, '--', 't'], text=True)
    return sorted(p for p in paths.splitlines() if re.fullmatch(r't/[^/]*-isf-[^/]*\.t', p))


def catalog(data):
    text = data.decode()
    marker = '\nFocused tests:\n'
    start = text.index(marker) + len(marker)
    end = text.index('\n## 12. Explicitly Deferred', start)
    body = text[start:end]
    matches = list(re.finditer(
        r'^- \[(t/[0-9]+-isf-[^\]]+\.t)\]\(\.\./\.\./\1\)\n', body, re.M))
    assert matches and matches[0].start() == 0, 'catalog preamble changed'
    paths = [m.group(1) for m in matches]
    assert len(paths) == len(set(paths)), 'duplicate catalog member'
    blocks = {m.group(1): body[m.start():matches[i + 1].start()
              if i + 1 < len(matches) else len(body)] for i, m in enumerate(matches)}
    return text[:start], text[end:], paths, blocks


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--revision', help='exact historical after-revision; default checks live files')
    args = parser.parse_args()
    assert args.revision is None or re.fullmatch(r'[0-9a-f]{40}', args.revision), 'use a full SHA'
    record = json.loads((BASE / 'derivation.json').read_text())
    assert digest(Path(__file__).read_bytes()) == record['reader_sha256'], 'reader identity changed'
    before = git_bytes(record['revision'], record['source'])
    read_after = lambda path: git_bytes(args.revision, path) if args.revision else (ROOT / path).read_bytes()
    after = read_after(record['source'])
    assert digest(before) == record['source_before_sha256'], 'before source identity changed'
    assert digest(after) == record['source_after_sha256'], 'after source identity changed'
    old_head, old_tail, old_paths, old_blocks = catalog(before)
    head, tail, paths, blocks = catalog(after)
    assert (head, tail) == (old_head, old_tail), 'noncatalog content changed'
    assert old_paths == record['listed_before'], 'before population changed'
    expected = record['expected_glob']
    assert expected == record['independent_rg'] == paths == sorted(set(paths)), 'membership/order changed'
    assert git_population(record['revision']) == expected, 'baseline test domain changed'
    assert sorted(set(paths) - set(old_paths)) == record['missing_before'], 'insertion domain changed'
    assert not (set(old_paths) - set(paths)), 'old catalog member lost'
    for path, block in old_blocks.items():
        assert block == blocks[path], f'annotation block changed: {path}'
        assert digest(block.encode()) == record['annotation_blocks_preserved'][path], path
    if not args.revision:
        actual = sorted(p.relative_to(ROOT).as_posix() for p in (ROOT / 't').glob('*-isf-*.t'))
        assert actual == expected, 'live test population changed; use --revision for history'
    else:
        assert git_population(args.revision) == expected, 'historical after test domain changed'
    manifest = 'doctrine/live_document_size/isf_reference_partitions.jsonl'
    assert read_after(manifest) == git_bytes(record['revision'], manifest), 'sealed activation manifest changed'
    print('isf-focused-index: exact membership, annotations and noncatalog bytes verified')


if __name__ == '__main__':
    main()

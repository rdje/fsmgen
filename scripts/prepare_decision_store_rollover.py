#!/usr/bin/env python3
"""Prepare the fixed flat-to-partitioned decision transition from an exact commit.

Writes a reviewable tree below a repository-relative output directory. It never
publishes into the repository's decision paths or chooses authority from edited
working files. The integrating slice installs the independently reviewed pins.
"""

import argparse
import hashlib
import json
import posixpath
import re
import sys
from pathlib import Path

sys.dont_write_bytecode = True
import decision_catalog as catalog
import decision_records as published
import decision_store as store
from decision_store_git import GitSnapshot

ROOT = Path(__file__).resolve().parent.parent
CONTINUITY = frozenset('0053 0054 0062 0064 0065 0066 0067 0068 0069 0070 0071 '
                       '0074 0076 0091 0094 0102 0104 0108'.split())
LANGUAGE_API = frozenset('0052 0058 0105 0106 0107 0109 0110 0111 0112 0113 0114'.split())
INDEX_PREFIX = '| # | Title | Type | Summary |\n| --- | --- | --- | --- |\n'


def encode(document):
    data = (json.dumps(document, ensure_ascii=False, indent=2, sort_keys=True) + '\n').encode('utf-8')
    catalog.require(len(data) <= catalog.MAX_DOCUMENT_BYTES, 'prepared document exceeds byte bound')
    return data


def relocate(text, old_path, new_path):
    """Preserve each existing relative inline destination and authority meaning."""
    def replace(match):
        target = match[2]
        if target.startswith(('#', '/')) or re.match(r'[a-zA-Z][a-zA-Z0-9+.-]*:', target):
            return match[0]
        destination = posixpath.normpath(posixpath.join(posixpath.dirname(old_path), target))
        return match[1] + posixpath.relpath(destination, posixpath.dirname(new_path)) + match[3]
    relocated = catalog.LINK.sub(replace, text)
    # These published commands search their own current status, not an immutable
    # original or exported provenance identifier. Other literal paths retain identity.
    if Path(old_path).name[:4] in ('0062', '0091'):
        relocated = '\n'.join(line.replace(old_path, new_path) if line.startswith('reverify:') else line
                              for line in relocated.splitlines()) + '\n'
    return relocated


def prepare(revision):
    catalog.require(re.fullmatch(r'[0-9a-f]{40}', revision) is not None, 'exact source commit is required')
    snapshot = GitSnapshot(ROOT, revision)
    catalog.require(store.CATALOG not in snapshot.objects, 'source already has a decision catalog')
    old_index = snapshot.read(store.INDEX)
    original_index = old_index.decode('utf-8')
    routes = {}
    for line in original_index.splitlines():
        match = store.ROUTE.fullmatch(line)
        if match:
            identity, filename, cells = match.groups()
            catalog.require(identity not in routes and '/' not in filename, 'source index is not flat and unique')
            columns = cells.split(' | ', 2)
            catalog.require(len(columns) == 3, 'source index has malformed cells')
            routes[identity] = ('docs/decisions/' + filename, cells, columns[1])
    catalog.require(set(snapshot.root_paths) == {row[0] for row in routes.values()} | {store.INDEX},
                    'source root identity population differs from index')
    catalog.require(set(routes) == {f'{number:04}' for number in range(1, 115)},
                    'one-time partition selection requires its complete reviewed source cohort')
    sealed, _ = published.load_records(ROOT, snapshot.read)
    sealed = {row['id']: row for row in sealed}
    catalog.require(set(sealed) <= set(routes), 'source loses published sealed identities')
    source_rows, originals, current, products = [], [], [], {}
    for identity, (path, cells, decision_type) in sorted(routes.items()):
        if identity in sealed:
            catalog.require(sealed[identity]['path'] == path, 'source substitutes sealed path')
            text, kind, part = sealed[identity]['text'], 'sealed', None
        else:
            text = snapshot.read(path).decode('utf-8')
            kind = 'current'
            part = 'continuity' if identity in CONTINUITY else 'language-api' if identity in LANGUAGE_API else 'verification'
        metadata, headings = catalog.record_facts(text, path, identity)
        descriptor = catalog.dimensions(text.encode('utf-8'))
        catalog.verify_content(text.encode('utf-8'), descriptor, identity)
        row = {'id': identity, 'path': path, 'kind': kind, 'part': part, 'type': decision_type,
               'metadata': metadata, 'headings': headings, 'content': descriptor}
        source_rows.append(row)
        originals.append({'id': identity, 'path': path, 'text': text})
        products[path] = store.compatibility_page(row).encode('utf-8')
        if kind == 'current':
            new_path = f'docs/decisions/current/{part}/{Path(path).name}'
            body = relocate(text, path, new_path).encode('utf-8')
            current_metadata, _ = catalog.record_facts(body.decode('utf-8'), new_path, identity)
            catalog.require(current_metadata == metadata, 'relocation changes source authority or question keys')
            current.append({'id': identity, 'path': new_path, 'type': decision_type,
                            'metadata': metadata, 'content': catalog.dimensions(body)})
            products[new_path] = body
    envelope = {'schema_version': 1, 'source_revision': snapshot.revision}
    products[store.SOURCE] = encode({**envelope, 'records': source_rows})
    products[store.ORIGINALS] = encode({**envelope, 'records': originals})
    products[store.CATALOG] = encode({**envelope, 'records': current})
    products[store.ORIGINAL_INDEX] = old_index
    current_by_id = {row['id']: row for row in current}
    prefix = ('# Decision records (layer C)\n\n'
              'Current canonical records are grouped by semantic purpose. Exact captured\n'
              'originals remain available through `scripts/decision_records.py read ID`.\n'
              'Existing compatibility paths and heading destinations stay fixed.\n\n'
              '- [Continuity and governance](current/continuity/INDEX.md)\n'
              '- [Language and public APIs](current/language-api/INDEX.md)\n'
              '- [Verification and execution](current/verification/INDEX.md)\n\n'
              'Add new records only to these parts and the authenticated catalog.\n'
              'Supersede changed decisions explicitly; storage does not change authority.\n\n')
    root_rows = []
    for identity, (old_path, cells, _) in sorted(routes.items()):
        path = current_by_id[identity]['path'] if identity in current_by_id else old_path
        root_rows.append(f'| [{identity}]({posixpath.relpath(path, "docs/decisions")}) | {cells} |\n')
    products[store.INDEX] = (prefix + INDEX_PREFIX + ''.join(root_rows)).encode('utf-8')
    for part in catalog.PARTS:
        rows = [f'| [{row["id"]}]({Path(row["path"]).name}) | {routes[row["id"]][1]} |\n'
                for row in current if catalog.location(row['path'], row['id'], current=True) == part]
        products[f'docs/decisions/current/{part}/INDEX.md'] = (
            f'# {part} decisions\n\n[Complete decision index](../../INDEX.md).\n\n'
            + INDEX_PREFIX + ''.join(rows)).encode('utf-8')
    # Existing immutable view is an input, never a newly authored replacement.
    read = lambda path: products[path] if path in products else snapshot.read(path)
    prepared = store.load(ROOT, hashlib.sha256(products[store.SOURCE]).hexdigest(),
                          hashlib.sha256(old_index).hexdigest(), reader=read)
    selected_routes = store.verify(ROOT, prepared, reader=read, paths=snapshot.root_paths)
    store.verify_transition(prepared, selected_routes)
    return products


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--revision', required=True)
    parser.add_argument('--output-dir', required=True, help='new repository-relative prepared tree')
    args = parser.parse_args()
    try:
        catalog.relative_parts(args.output_dir)
        directory = ROOT / args.output_dir
        catalog.require(not directory.exists() and not directory.is_symlink(), 'prepared output already exists')
        catalog.require(all(not parent.is_symlink() for parent in directory.parents), 'prepared output has symlink parent')
        products = prepare(args.revision)
        for relative, data in products.items():
            target = directory / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
        print(json.dumps({'source_revision': args.revision, 'files': len(products),
                          'source_sha256': hashlib.sha256(products[store.SOURCE]).hexdigest(),
                          'index_sha256': hashlib.sha256(products[store.ORIGINAL_INDEX]).hexdigest()}, sort_keys=True))
    except (OSError, ValueError, KeyError, TypeError, UnicodeError) as error:
        print(f'decision-store-rollover: {error}', file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())

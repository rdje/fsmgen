"""Authenticated decision-store loading and finite navigation verification.

The published reader and authority gate consume the same authenticated store. Callers
supply independently trusted digests, never values taken from these documents.
All locations and identity checks come from the shared catalog.
"""

import hashlib
import posixpath
import re
from pathlib import Path

import decision_catalog as catalog_api

SOURCE = 'docs/audits/decision-store-transition-census.json'
ORIGINALS = 'docs/decisions/history/transition-originals.json'
ORIGINAL_INDEX = 'docs/decisions/history/transition-index.md'
CATALOG = 'docs/decisions/current/catalog.json'
INDEX = 'docs/decisions/INDEX.md'
SEALED_VIEW = 'docs/decisions/history/0001-0050.md'
ROUTE = re.compile(r'^\| \[([0-9]{4})\]\(([^\s)]+)\) \| (.+) \|$')


def index_rows(text, path, expected):
    """Validate complete per-ID routes, not just a matching row count."""
    rows = {}
    for line in catalog_api.visible_lines(text):
        match = ROUTE.fullmatch(line)
        catalog_api.require(match is not None or not line.startswith('| ['),
                            f'unsupported decision index row: {path}')
        if not match:
            continue
        identity, target, cells = match.groups()
        catalog_api.require(identity not in rows, f'index duplicates decision ID: {identity}')
        catalog_api.require(identity in expected, f'index substitutes decision ID: {identity}')
        wanted = posixpath.relpath(expected[identity]['path'], posixpath.dirname(path))
        catalog_api.require(target == wanted, f'index misroutes decision ID: {identity}')
        columns = cells.split(' | ', 2)
        catalog_api.require(len(columns) == 3 and columns[1] == expected[identity]['type'],
                            f'index changes decision type: {identity}')
        rows[identity] = {'target': target, 'cells': cells}
    catalog_api.require(set(rows) == set(expected), f'index membership differs: {path}')
    return rows


def compatibility_page(source):
    """Retain the exact original heading sequence without another slug parser."""
    identity = source['id']
    destination = (f'history/0001-0050.md#decision-{identity}' if source['kind'] == 'sealed'
                   else f"current/{source['part']}/{Path(source['path']).name}")
    link = f'[Read the complete record]({destination}).\n'
    headings = source['headings']
    page = (headings[0] + '\n\n'
            'This compatibility path is fixed; storage does not change decision authority.\n'
            + link + '\n'
            'Retrieve exact captured original text from the repository root:\n\n'
            + f'```sh\nscripts/decision_records.py read {identity}\n```\n')
    for heading in headings[1:]:
        page += '\n' + heading + '\n\n' + link
    return page


def load(root, source_sha256, index_sha256, *, reader=None):
    """Load a supplied store against independent source/index fingerprints."""
    for digest in (source_sha256, index_sha256):
        catalog_api.require(type(digest) is str and re.fullmatch(r'[0-9a-f]{64}', digest),
                            'independent store authority digest is required')
    read = reader or (lambda path: catalog_api.read_bytes(root, path))
    source_bytes, index_bytes = read(SOURCE), read(ORIGINAL_INDEX)
    catalog_api.require(type(source_bytes) is bytes and type(index_bytes) is bytes,
                        'store source access must return bytes')
    catalog_api.require(hashlib.sha256(source_bytes).hexdigest() == source_sha256,
                        'independent transition source census changed')
    catalog_api.require(hashlib.sha256(index_bytes).hexdigest() == index_sha256,
                        'independent original decision index changed')
    source = catalog_api.decode_document(source_bytes)
    originals = catalog_api.decode_document(read(ORIGINALS))
    catalog = catalog_api.decode_document(read(CATALOG))
    prepared = catalog_api.prepare(root, source, originals, catalog, reader=read)
    prepared['source_sha256'] = source_sha256
    prepared['original_index_sha256'] = index_sha256
    original_index = catalog_api.verify_content(index_bytes, catalog_api.dimensions(index_bytes),
                                                'original decision index')
    prepared['original_index'] = original_index
    prepared['original_routes'] = index_rows(original_index, INDEX, prepared['compatibility'])
    return prepared


def verify(root, prepared, *, reader=None, paths=None):
    """Check exact compatibility rendering, complete indexes and root residue.

    Selected Git accessors must supply their own complete root path inventory;
    mixing a selected bytes snapshot with an ambient directory scan is refused.
    """
    catalog_api.require(reader is None or paths is not None,
                        'selected snapshot requires a complete root path inventory')
    read = reader or (lambda path: catalog_api.read_bytes(root, path))
    expected_root = {row['path'] for row in prepared['compatibility'].values()} | {INDEX}
    if paths is None:
        directory = Path(root) / 'docs/decisions'
        paths = [str(path.relative_to(root)) for path in directory.glob('*.md')]
    catalog_api.require(type(paths) in (list, tuple) and len(paths) <= catalog_api.MAX_SOURCE_RECORDS + 1
                        and all(type(path) is str for path in paths), 'invalid root path inventory')
    catalog_api.require(len(paths) == len(set(paths)) and set(paths) == expected_root,
                        'compatibility root membership differs from fixed source')
    for identity, row in prepared['compatibility'].items():
        catalog_api.require(read(row['path']) == compatibility_page(row).encode('utf-8'),
                            f'compatibility page is stale or altered: {identity}')
    current = prepared['current']
    bindings = {identity: row for identity, row in prepared['compatibility'].items()
                if row['kind'] == 'sealed'}
    bindings.update(current)
    root_bytes = read(INDEX)
    root_text = catalog_api.verify_content(root_bytes, catalog_api.dimensions(root_bytes), 'current root index')
    prepared_routes = index_rows(root_text, INDEX, bindings)
    visible = '\n'.join(catalog_api.visible_lines(root_text))
    for part in catalog_api.PARTS:
        path = f'docs/decisions/current/{part}/INDEX.md'
        target = posixpath.relpath(path, 'docs/decisions')
        catalog_api.require(any(match[2] == target for match in catalog_api.LINK.finditer(visible)),
                            f'root index omits semantic part: {part}')
        data = read(path)
        text = catalog_api.verify_content(data, catalog_api.dimensions(data), f'{part} index')
        members = {identity: row for identity, row in current.items()
                   if catalog_api.location(row['path'], identity, current=True) == part}
        rows = index_rows(text, path, members)
        catalog_api.require(all(row['cells'] == prepared_routes[identity]['cells']
                                for identity, row in rows.items()), f'part index metadata differs: {part}')
    if any(row['kind'] == 'sealed' for row in prepared['compatibility'].values()):
        view = read(SEALED_VIEW).decode('utf-8')
        catalog_api.require(len(view.encode('utf-8')) <= catalog_api.MAX_DOCUMENT_BYTES,
                            'sealed view exceeds byte bound')
        for identity, row in prepared['compatibility'].items():
            if row['kind'] == 'sealed':
                catalog_api.require(f'<a id="decision-{identity}"></a>' in view,
                                    f'sealed view omits decision destination: {identity}')
    return prepared_routes


def verify_transition(prepared, routes):
    """Initial migration preserves every index value and ordered metadata key."""
    catalog_api.verify_transition_metadata(prepared)
    for identity, original in prepared['original_routes'].items():
        catalog_api.require(routes[identity]['cells'] == original['cells'],
                            f'transition index values changed: {identity}')

#!/usr/bin/env python3
"""Read exact decision products and verify authenticated navigation and continuity."""

import argparse
import hashlib
import json
import posixpath
import re
import sys
from pathlib import Path

sys.dont_write_bytecode = True

CENSUS = 'docs/audits/decision-record-rollover-census-20260927.json'
CENSUS_SHA256 = '01c08fde970b1a9c8ae4f1418d5d24da80ca0a23f5bead35649d0694b4f1811b'
ARCHIVE = 'docs/decisions/history/0001-0050.json'
VIEW = 'docs/decisions/history/0001-0050.md'
INDEX = 'docs/decisions/INDEX.md'
CATALOG = 'docs/decisions/current/catalog.json'
# Installed only by the atomic source-rollover slice. Supplied stores require
# explicit independent caller fingerprints and an explicit selected root.
STORE_SOURCE_SHA256 = None
STORE_INDEX_SHA256 = None
MAX_BYTES = 1_048_576
LINK = re.compile(r'(\[[^\]\n]*\]\()([^\s)]+)(\))')


def require(condition, message):
    if not condition:
        raise ValueError(message)


def read_bytes(root, relative, reader=None):
    """Bound reads and reject links or paths that escape the chosen root."""
    if reader is not None:
        return reader(relative)
    parts = Path(relative).parts
    require(parts and not Path(relative).is_absolute() and '..' not in parts,
            f'unsafe path: {relative}')
    path = root
    for part in parts:
        path = path / part
        require(not path.is_symlink(), f'symlink is not a retained file: {relative}')
    with path.open('rb') as stream:
        data = stream.read(MAX_BYTES + 1)
    require(len(data) <= MAX_BYTES, f'file exceeds reader bound: {relative}')
    return data


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        require(key not in result, f'duplicate JSON key: {key}')
        result[key] = value
    return result


def load_records(root, reader=None):
    census_bytes = read_bytes(root, CENSUS, reader)
    require(hashlib.sha256(census_bytes).hexdigest() == CENSUS_SHA256,
            'independent source census changed')
    census = json.loads(census_bytes, object_pairs_hook=unique_object)
    archive = json.loads(read_bytes(root, ARCHIVE, reader), object_pairs_hook=unique_object)
    require(set(archive) == {'schema_version', 'source_revision', 'records'},
            'unexpected archive fields')
    require(type(archive['schema_version']) is int and archive['schema_version'] == 1,
            'unsupported archive schema')
    require(archive['source_revision'] == census['source_revision'],
            'archive source revision changed')
    expected = [row for row in census['records'] if '0001' <= row['id'] <= '0050']
    records = archive['records']
    require(isinstance(records, list) and len(records) == len(expected) == 50,
            'archive must retain the complete selected cohort')
    for record, source in zip(records, expected):
        require(isinstance(record, dict) and set(record) == {'id', 'path', 'text'},
                'unexpected record fields')
        require(record['id'] == source['id'] and record['path'] == source['path'],
                'record identity or ordering changed')
        require(isinstance(record['text'], str), f"invalid text: {record['id']}")
        data = record['text'].encode('utf-8')
        require(len(data) == source['bytes'] and data.count(b'\n') == source['lines']
                and hashlib.sha256(data).hexdigest() == source['sha256'],
                f"original text changed: {record['id']}")
    return records, census


def pointer(record):
    title = record['text'].splitlines()[0]
    return (f'{title}\n\n'
            'This record is sealed; its authority and supersession status are unchanged.\n'
            f"[Read the complete record](history/0001-0050.md#decision-{record['id']}).\n\n"
            'Retrieve exact original text from the repository root:\n\n'
            f"```sh\nscripts/decision_records.py read {record['id']}\n```\n")


def render(records):
    output = ['# Sealed decision records: 0001–0050\n\n',
              'Generated from `0001-0050.json`; do not edit this view.\n',
              'Storage does not change decision authority or supersession status.\n',
              'Use [the decision index](../INDEX.md) to discover later decisions.\n\n']
    for record in records:
        output.append(f"<a id=\"decision-{record['id']}\"></a>\n\n")
        # The sealed cohort has only ordinary relative inline Markdown links.
        # Keep original bytes in JSON; relocate links only in the derived view.
        body = LINK.sub(lambda m: m[1] + '../' + m[2] + m[3], record['text'])
        output.append(body + '\n---\n\n')
    return ''.join(output).rstrip() + '\n'


def verify(root, store=None, reader=None):
    records, census = load_records(root, reader)
    require(read_bytes(root, VIEW, reader) == render(records).encode('utf-8'),
            'derived archive view is stale or altered')
    index = read_bytes(root, INDEX, reader).decode('utf-8')
    for record in records:
        if store is None:
            require(read_bytes(root, record['path'], reader) == pointer(record).encode('utf-8'),
                    f"forwarding page changed: {record['id']}")
            require(f"]({Path(record['path']).name})" in index,
                    f"decision index omits {record['id']}")
        else:
            require(store['originals'].get(record['id']) == record['text'],
                    f"transition substitutes published sealed original: {record['id']}")
    for link in census['selected_links']:
        original = posixpath.normpath(posixpath.join('docs/decisions', link['target']))
        relocated = posixpath.normpath(posixpath.join('docs/decisions/history', '../' + link['target']))
        require(original == relocated, f'link meaning changed: {link}')
        read_bytes(root, original, reader)
    for consumer in census['body_or_identity_consumers']:
        if consumer['text'].startswith('reverify:'):
            text = read_bytes(root, consumer['path'], reader).decode('utf-8')
            commands = [line for line in text.splitlines() if line.startswith('reverify:')]
            require(len(commands) == 1, f"missing reverify command: {consumer['path']}")
            command = commands[0]
            ids = [Path(path).name[:4] for path in consumer['decisions']]
            require('scripts/decision_records.py read ' + ' '.join(ids) in command,
                    f"reverify omits exact record reader: {consumer['path']}")
            require(not any(path in command for path in consumer['decisions']),
                    f"reverify still searches a forwarding page: {consumer['path']}")
    return records


def load_store(root, source_digest, index_digest, snapshot=None):
    # Lazy loading preserves the standalone captured legacy-reader capsule when
    # no catalog exists. Live stores always use the one shared location contract.
    import decision_store
    require(CATALOG == decision_store.CATALOG, 'catalog locator differs from shared store contract')
    reader = snapshot.read if snapshot is not None else None
    store = decision_store.load(root, source_digest, index_digest, reader=reader)
    decision_store.verify(root, store, reader=reader,
                          paths=snapshot.root_paths if snapshot is not None else None)
    return store


def selected_snapshot(root, selector):
    if selector == 'worktree':
        return None
    from decision_store_git import GitSnapshot
    return GitSnapshot(root, selector)


def selected_store(root, snapshot, supplied, source_digest, index_digest):
    present = CATALOG in snapshot.objects if snapshot is not None \
        else (root / CATALOG).exists() or (root / CATALOG).is_symlink()
    if not present:
        return None
    require(source_digest is not None and index_digest is not None,
            'catalog store has no installed independent authority')
    store = load_store(root, source_digest, index_digest, snapshot)
    if not supplied:
        # All legacy publication checks consume this same selected snapshot.
        verify(root, store, reader=snapshot.read if snapshot is not None else None)
    return store


def canonical_binding(store, path):
    rows = [row for row in store['current'].values() if row['path'] == path]
    require(len(rows) == 1, 'path is not an exact current canonical decision')
    row = rows[0]
    return {'id': row['id'], 'path': path, 'transition_source_revision': store['source_revision'],
            'content_sha256': row['content']['sha256'],
            'transition_identity': row['id'] in store['compatibility']}


def verify_adoption(root, predecessor, store):
    """First catalog adoption retains the exact selected flat predecessor."""
    require(predecessor is not None and predecessor.revision == store['source_revision'],
            'transition source is not the selected predecessor revision')
    require(set(predecessor.root_paths) == {INDEX} | {
        row['path'] for row in store['compatibility'].values()},
        'transition source omits or substitutes predecessor root identities')
    require(predecessor.read(INDEX).decode('utf-8') == store['original_index'],
            'transition original index differs from selected predecessor')
    sealed = [row for row in store['compatibility'].values() if row['kind'] == 'sealed']
    if sealed:
        archive = json.loads(predecessor.read(ARCHIVE), object_pairs_hook=unique_object)
        require(type(archive) is dict
                and set(archive) == {'schema_version', 'source_revision', 'records'}
                and type(archive['schema_version']) is int and archive['schema_version'] == 1
                and type(archive['records']) is list, 'invalid predecessor sealed archive')
        records = archive['records']
        require(len(records) == len(sealed), 'predecessor sealed cohort differs')
        for record, row in zip(records, sealed):
            require(type(record) is dict and set(record) == {'id', 'path', 'text'}
                    and record['id'] == row['id'] and record['path'] == row['path']
                    and record['text'] == store['originals'][row['id']],
                    'transition substitutes predecessor sealed original')
    for row in store['compatibility'].values():
        if row['kind'] == 'current':
            require(predecessor.read(row['path']).decode('utf-8') == store['originals'][row['id']],
                    f"transition substitutes predecessor current original: {row['id']}")


def change_product(root, prior_snapshot, prior, current, paths, snapshot):
    """Authenticate before calling; emit one complete bounded gate product."""
    from decision_catalog import visible_lines
    from decision_store_git import verify_continuity
    require(current is not None or prior is None, 'catalog store removed from selected change')
    require(len(paths) <= 50 and len(set(paths)) == len(paths), 'invalid bounded canonical path request')
    if current is None:
        require(not paths, 'canonical bindings require an authenticated catalog store')
        return {'catalog': False, 'fresh_ids': [], 'resolved': []}
    if prior is None:
        import decision_store
        routes = decision_store.verify(root, current, reader=snapshot.read if snapshot is not None else None,
                                       paths=snapshot.root_paths if snapshot is not None else None)
        decision_store.verify_transition(current, routes)
        verify_adoption(root, prior_snapshot, current)
        previous_ids = set(current['compatibility'])
    else:
        verify_continuity(prior, current)
        previous_ids = set(prior['compatibility']) | set(prior['current'])
    fresh = sorted(set(current['current']) - previous_ids)
    resolved = []
    for path in paths:
        binding = canonical_binding(current, path)
        row = current['current'][binding['id']]
        markers = [line for line in visible_lines(row['text'])
                   if re.fullmatch(r'- (?:Ceiling authority|Surface|Dimension|Change): `[^`]+`', line)]
        resolved.append({**binding, 'fresh_identity': binding['id'] in fresh,
                         'new_file': path not in prior_snapshot.objects,
                         'authority_markers': markers, 'text': row['text']})
    return {'catalog': True, 'fresh_ids': fresh, 'resolved': resolved}


def selected_file_digest(root, snapshot, path):
    """Bind a gate's control file to the same captured path/object inventory."""
    from decision_catalog import read_bytes as regular_bytes, relative_parts
    relative_parts(path)
    if snapshot is not None:
        if path not in snapshot.objects:
            return None
        data = snapshot.read(path)
    else:
        source = root.joinpath(*relative_parts(path))
        if not source.exists() and not source.is_symlink():
            return None
        data = regular_bytes(root, path)
    return hashlib.sha256(data).hexdigest()


def request_bytes(store, operation, identities):
    require(identities and len(identities) <= 50, 'read requires a bounded nonempty ID list')
    require(all(type(value) is str and re.fullmatch(r'[0-9]{4}', value) for value in identities),
            'invalid decision ID request')
    products = {}
    if operation in ('read', 'read-current'):
        products.update({identity: row['text'] for identity, row in store['current'].items()})
    if operation in ('read', 'read-original'):
        products.update(store['originals'])
    require(all(value in products for value in identities),
            f'unknown decision ID or unavailable {operation} product')
    payload = ''.join(products[value] for value in identities).encode('utf-8')
    require(len(payload) <= MAX_BYTES, 'requested record output exceeds byte bound')
    return payload


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, help='explicit selected store or legacy fixture root')
    parser.add_argument('--source-sha256', help='independently trusted census digest for a supplied store')
    parser.add_argument('--index-sha256', help='independently trusted original-index digest for a supplied store')
    parser.add_argument('--snapshot', default='worktree',
                        help='worktree, index, HEAD, HEAD^ or an exact Git commit')
    parser.add_argument('--prior-snapshot', help='Git predecessor for check-continuity')
    parser.add_argument('--bind-file', action='append', default=[],
                        help='optional selected control-file digest binding for check-continuity')
    parser.add_argument('operation', choices=('check', 'read', 'read-original', 'read-current', 'resolve',
                                             'check-continuity'),
                        nargs='?', default='check')
    parser.add_argument('ids', nargs='*',
                        help='ordered IDs, one resolve path, or optional check-continuity canonical paths')
    args = parser.parse_args(argv)
    try:
        default_root = Path(__file__).resolve().parent.parent
        root = (args.root or default_root).resolve(strict=True)
        supplied = args.source_sha256 is not None or args.index_sha256 is not None
        if supplied:
            require(args.root is not None, 'supplied store fingerprints require explicit --root')
            require(args.source_sha256 is not None and args.index_sha256 is not None,
                    'supplied store requires both independent fingerprints')
            require(root != default_root, 'supplied fingerprints cannot override the actual repository authority')
            require(all(re.fullmatch(r'[0-9a-f]{64}', digest)
                        for digest in (args.source_sha256, args.index_sha256)),
                    'independent store authority digest is required')
            source_digest, index_digest = args.source_sha256, args.index_sha256
        else:
            source_digest, index_digest = STORE_SOURCE_SHA256, STORE_INDEX_SHA256
        require((args.operation == 'check-continuity') == (args.prior_snapshot is not None),
                'check-continuity requires --prior-snapshot; other operations do not accept it')
        require(not args.bind_file or args.operation == 'check-continuity',
                '--bind-file requires check-continuity')
        require(len(args.bind_file) <= 8 and len(set(args.bind_file)) == len(args.bind_file),
                'invalid bounded control-file binding request')
        snapshot = selected_snapshot(root, args.snapshot)
        reader = snapshot.read if snapshot is not None else None
        store = selected_store(root, snapshot, supplied, source_digest, index_digest)
        if supplied and args.operation != 'check-continuity':
            require(store is not None, 'unresolved regular source: ' + CATALOG)
        if not supplied and root == default_root and STORE_SOURCE_SHA256 is not None \
                and args.snapshot == 'worktree' and args.operation != 'check-continuity':
            require(store is not None, 'installed catalog store is absent')
        if args.operation == 'check-continuity':
            require(args.prior_snapshot not in ('worktree', 'index'),
                    'predecessor must be a resolved Git revision')
            prior_snapshot = selected_snapshot(root, args.prior_snapshot)
            prior = selected_store(root, prior_snapshot, supplied, source_digest, index_digest)
            product = change_product(root, prior_snapshot, prior, store, args.ids, snapshot)
            if args.bind_file:
                product['file_bindings'] = {
                    path: {'prior': selected_file_digest(root, prior_snapshot, path),
                           'current': selected_file_digest(root, snapshot, path)}
                    for path in args.bind_file}
            payload = (json.dumps(product, ensure_ascii=False, sort_keys=True) + '\n').encode('utf-8')
            require(len(payload) <= MAX_BYTES, 'change product output exceeds byte bound')
            sys.stdout.buffer.write(payload)
        elif args.operation == 'check':
            require(not args.ids, 'check does not accept record IDs')
            if store is None:
                verify(root, reader=reader)
                print('decision-records: exact originals, view, links and consumers verified')
            else:
                print('decision-records: authenticated originals, current records, compatibility and indexes verified')
        elif args.operation == 'resolve':
            require(store is not None, 'resolve requires an authenticated catalog store')
            require(len(args.ids) == 1, 'resolve requires one canonical decision path')
            print(json.dumps(canonical_binding(store, args.ids[0]), sort_keys=True))
        elif store is not None:
            sys.stdout.buffer.write(request_bytes(store, args.operation, args.ids))
        else:
            require(args.operation != 'read-current', 'read-current requires an authenticated catalog store')
            require(args.ids and len(args.ids) <= 50, 'read requires a bounded nonempty ID list')
            records, _ = load_records(root, reader)
            by_id = {record['id']: record for record in records}
            require(all(re.fullmatch(r'[0-9]{4}', value) and value in by_id
                        for value in args.ids), 'unknown or unsealed decision ID')
            # Validate the whole request before writing any partial result.
            sys.stdout.buffer.write(''.join(by_id[value]['text'] for value in args.ids).encode('utf-8'))
    except (OSError, ValueError, KeyError, TypeError, UnicodeError) as error:
        print(f'decision-records: {error}', file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())

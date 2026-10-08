"""Source-qualified scoped inventory hypothesis; production remains unchanged."""
import copy
import hashlib
import json
import posixpath
import subprocess
import sys
from pathlib import Path

ROOT = Path.cwd()
BASE = Path('docs/audits/decision-index-scope-20261008')
sys.path[:0] = [str(ROOT / 'scripts'), str(ROOT / 't/python')]
import decision_records as published
import decision_store_git as selected
from test_decision_production_growth import ProductionFixture, SOURCE_PIN, INDEX_PIN


def need(value, cause):
    if not value:
        raise ValueError(cause)


def pin(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def inventory(raw, tree=False, allow_trees=False):
    need(not raw or raw.endswith(b'\0'), 'complete native inventory frame')
    result = {}
    for record in raw.split(b'\0')[:-1]:
        header, path = record.split(b'\t', 1); mode, middle, last = header.split()
        if tree:
            if mode == b'040000':
                need(allow_trees and middle == b'tree', 'native directory metadata kind')
                continue
            need(middle == (b'commit' if mode == b'160000' else b'blob'), 'native tree member kind')
            object_id = last
        else:
            need(last == b'0', 'native zero index stage'); object_id = middle
        name = path.decode(); need(name not in result, 'unique complete native path')
        result[name] = (mode.decode(), object_id.decode())
    return result


def graph(census):
    files = {published.CENSUS, 'docs/audits/decision-store-transition-census.json',
             'doctrine/live_document_size/surfaces.jsonl',
             'doctrine/live_document_size/ceiling_increase_authorities.jsonl'}
    files.update(posixpath.normpath(posixpath.join('docs/decisions', row['target'])) for row in census['selected_links'])
    files.update(row['path'] for row in census['body_or_identity_consumers'] if row['text'].startswith('reverify:'))
    # A real non-ASCII nondirectory ancestor exercises raw path selection.
    files.add('λ/registry.json')
    for path in files:
        selected.catalog_api.relative_parts(path)
    parents = {str(parent) for path in files | {'docs/decisions'} for parent in Path(path).parents if str(parent) != '.'}
    return sorted(files), sorted(parents)


def exact_parent(path):
    # A byte class forces wildcard matching of the complete raw name. Merely
    # adding glob magic to a literal directory still selects its descendants.
    raw = path.encode(); first = raw[:1]
    if first in (b'!', b'^', b']', b'-', b'['):
        first = b'\\' + first
    escaped = raw[1:]
    for byte in (b'\\', b'*', b'?', b'[', b']'):
        escaped = escaped.replace(byte, b'\\' + byte)
    return b':(top,glob)[' + first + b']' + escaped


def prototype(root, selector, mapping):
    # Adapter only for testing the unchanged public reader's selected bytes
    # contract. It bypasses the old whole-inventory constructor; it is not a
    # production repair or an admitted API, and must never be promoted as one.
    result = selected.GitSnapshot.__new__(selected.GitSnapshot)
    result.root = root; result.revision = None if selector == 'index' else selector
    result.objects = mapping
    result.root_paths = tuple(sorted(p for p in mapping if p.startswith('docs/decisions/')
                                    and p.count('/') == 2 and p.endswith('.md')))
    return result


def main():
    need(Path.cwd().resolve() == ROOT, 'same repository invocation root')
    inputs = ['scripts/' + name + '.py' for name in ('decision_records', 'decision_catalog', 'decision_store', 'decision_store_git')]
    inputs += ['scripts/check_live_document_ceiling_authority.pl', 't/python/test_decision_store_git.py',
               't/python/test_decision_production_growth.py', 't/python/test_decision_reader_snapshots.py',
               'docs/knowledge/decision-record-exact-retrieval.md', 'docs/book/src/90-reference-map.md']
    sources = {p: dict(identity=pin(Path(p).read_bytes()), source=Path(p).read_text()) for p in inputs}
    fixture = ProductionFixture()
    try:
        for path in inputs[:4]:
            fixture.write(path, Path(path).read_bytes())
        fixture.git('add', '.'); fixture.git('commit', '-q', '-m', 'fixture exact current decision reader')
        baseline = fixture.public('check', selector='index', installed=True)
        need(baseline.returncode == 0 and baseline.stdout == b'decision-records: authenticated originals, current records, compatibility and indexes verified\n'
             and baseline.stderr == b'', 'actual complete installed selected-store baseline')
        before = {p: pin((fixture.root / p).read_bytes()) for p in fixture.original_products}
        payload = b'opaque unrelated qualification data\n'
        object_id = subprocess.check_output(['git', '-C', str(fixture.root), 'hash-object', '-w', '--stdin'], input=payload).decode().strip()
        unrelated = ['unrelated/' + 'x' * 160 + f'{i:05}.bin' for i in range(20_001)]
        records = ''.join('100644 ' + object_id + '\t' + p + '\n' for p in unrelated + ['λ']).encode()
        actual = subprocess.run(['git', '-C', str(fixture.root), 'update-index', '--index-info'], input=records, capture_output=True)
        need(actual.returncode == 0 and not actual.stdout and not actual.stderr, 'legitimate unrelated native index records')
        fixture.git('commit', '-q', '-m', 'fixture unchanged store with unrelated inventory growth')
        need(before == {p: pin((fixture.root / p).read_bytes()) for p in fixture.original_products}, 'whole selected store/source files conserve')
        census_raw = (fixture.root / published.CENSUS).read_bytes()
        need(pin(census_raw)['sha256'] == published.CENSUS_SHA256, 'trusted legacy dependency source')
        files, parents = graph(json.loads(census_raw))
        roots = [b':(top,literal)docs/decisions'] + [b':(top,literal)' + p.encode() for p in files]
        observed = []
        for selector in ('index', fixture.git('rev-parse', 'HEAD').decode().strip()):
            tree = selector != 'index'
            args = ['ls-tree', '-r', '--full-tree', '-z', selector] if tree else ['ls-files', '--stage', '-z']
            whole = fixture.git(*args); complete = inventory(whole, tree)
            canonical_bytes = sum(len(mode.encode()) + 1 + 40 + 3 + len(p.encode()) + 1 for p, (mode, oid) in complete.items())
            need(canonical_bytes > selected.MAX_INVENTORY_BYTES, 'genuine whole canonical inventory overflow')
            failure = fixture.public('check', selector=selector, installed=True)
            need(failure.returncode == 1 and failure.stdout == b''
                 and failure.stderr == b'decision-records: Git output exceeds selected snapshot bound\n', 'actual stock installed reader overflow refusal')
            specs = roots if tree else roots + [exact_parent(p) for p in parents]
            command = ['git', '-C', str(fixture.root), *args, '--', *specs]
            run = subprocess.run(command, capture_output=True)
            saved = json.loads((BASE / 'checks.json').read_bytes())
            saved['attempts'].append(dict(role='Actual current source hypothesis metadata command',
                source=Path(__file__).read_text(), command=[dict(bytes_hex=a.hex()) if type(a) is bytes else a for a in command],
                status=run.returncode, stdout_hex=run.stdout.hex(), stderr=run.stderr.decode()))
            (BASE / 'checks.json').write_text(json.dumps(saved, sort_keys=True, indent=2) + '\n')
            need(run.returncode == 0 and not run.stderr, 'actual public selected metadata command')
            mapping = inventory(run.stdout, tree)
            parent_runs = []
            if tree:
                # These separately selected metadata commands use one immutable
                # resolved revision. A single parent per query avoids directory
                # prefix recursion when overlapping ancestor paths are supplied.
                for parent in parents:
                    query = ['git', '-C', str(fixture.root), 'ls-tree', '--full-tree', '-z', selector, '--', ':(top,literal)' + parent]
                    row = subprocess.run(query, capture_output=True)
                    need(row.returncode == 0 and not row.stderr, 'native immutable ancestor metadata command')
                    members = inventory(row.stdout, tree=True, allow_trees=True)
                    need(all(p == parent for p in members), 'exact native ancestor metadata path')
                    for p, value in members.items():
                        need(p not in mapping or mapping[p] == value, 'immutable repeated ancestor object identity')
                        mapping[p] = value
                    parent_runs.append(dict(command=query, status=row.returncode, stdout_hex=row.stdout.hex(), stderr=row.stderr.decode()))
            wanted = {p: value for p, value in complete.items() if p.startswith('docs/decisions/') or p in files or p in parents}
            selected_bytes = sum(len(mode.encode()) + 1 + 40 + 3 + len(p.encode()) + 1 for p, (mode, oid) in mapping.items())
            need(mapping == wanted and selected_bytes <= selected.MAX_INVENTORY_BYTES, 'independent complete exact relevant path mode object allocation')
            prepared = published.load_store(fixture.root, SOURCE_PIN, INDEX_PIN, prototype(fixture.root, selector, mapping))
            published.verify(fixture.root, prepared, reader=prototype(fixture.root, selector, mapping).read)
            controls = []
            changed = copy.deepcopy(mapping)
            path = next(p for p in sorted(mapping) if p.startswith('docs/decisions/0001-'))
            changed.pop(path); need(changed != mapping, 'real compatible-root omission')
            try:
                published.load_store(fixture.root, SOURCE_PIN, INDEX_PIN, prototype(fixture.root, selector, changed))
            except ValueError as error:
                cause = 'compatibility root membership differs from fixed source'
                need(str(error) == cause, 'intended complete root omission refusal')
                controls.append(dict(name='lost-compatible-root', status=1, cause=cause, removed=path))
            else:
                raise ValueError('false-green compatible-root omission')
            ancestor = prototype(fixture.root, selector, mapping)
            try:
                ancestor.read('λ/registry.json')
            except ValueError as error:
                need(str(error) == 'selected source has a nondirectory ancestor: λ/registry.json', 'actual non-ASCII ancestor refusal')
                controls.append(dict(name='non-ASCII-nondirectory-ancestor', status=1, cause=str(error)))
            else:
                raise ValueError('false-green ancestor control')
            observed.append(dict(selector=selector, complete_wire=whole.decode(), complete=complete,
                canonical_bytes=canonical_bytes, selected_canonical_bytes=selected_bytes,
                stock=dict(command=failure.args, status=failure.returncode, stdout=failure.stdout.decode(), stderr=failure.stderr.decode()),
                selected_command=[dict(bytes_hex=arg.hex()) if type(arg) is bytes else arg for arg in command],
                selected_wire=run.stdout.hex(), ancestor_results=parent_runs, selected=mapping, prepared=prepared, controls=controls))
        proof = dict(revision=subprocess.check_output(['git', 'rev-parse', 'HEAD']).decode().strip(), sources=sources,
            baseline=dict(command=baseline.args, status=baseline.returncode, stdout=baseline.stdout.decode(), stderr=baseline.stderr.decode()),
            complete_before=before, legacy_census=census_raw.decode(), files=files, ancestors=parents,
            results=observed, limits=dict(inventory=selected.MAX_INVENTORY_BYTES, paths=selected.MAX_TRACKED_PATHS,
                                         document=selected.catalog_api.MAX_DOCUMENT_BYTES),
            producer=dict(identity=pin(Path(__file__).read_bytes()), source=Path(__file__).read_text()),
            role='Source/selection hypothesis only. The adapter bypasses the old constructor; real scoped production API and bootstrap/final object conservation are repair-owned, not qualified here.')
    finally:
        fixture.close()
    need(not fixture.root.exists(), 'owned disposable fixture consumed and removed')
    path = BASE / 'proof.json'; need(not path.exists(), 'one new complete diagnosis product')
    path.write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    print('PASS complete stock unrelated-inventory failure and independent scoped-source hypothesis; production repair remains pending.')


if __name__ == '__main__':
    main()

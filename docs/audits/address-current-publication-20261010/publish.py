"""Admit the entire reviewed finite-address card/reader/book epoch together."""
import hashlib
import json
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[3] / 'scripts'))
import check_record_value_publication as current

BASE = Path('docs/audits/address-current-publication-20261010')
REVISION = '924a2a1b7236ce2312d79953b1c98511016e6d25'
DESCRIPTORS = 'doctrine/live_document_size/archive_descriptors.jsonl'
SURFACES = 'doctrine/live_document_size/surfaces.jsonl'
FEATURE = 'docs/book/src/13k-isf-feature-support-matrix.md'
REFERENCE = 'docs/book/src/90-reference-map.md'


def need(ok, cause):
    if not ok:
        raise ValueError(cause)


def pin(raw):
    return {'bytes': len(raw), 'lines': raw.count(b'\n'), 'sha256': hashlib.sha256(raw).hexdigest()}


def git(*args):
    result = subprocess.run(['git', '--no-replace-objects', *args], capture_output=True)
    need(result.returncode == 0 and not result.stderr, 'whole committed address publication source')
    return result.stdout


def before(path):
    return git('cat-file', 'blob', REVISION + ':' + path)


def replace(text, old, new):
    need(text.count(old) == 1, 'unique complete address publication seam: ' + old[:70])
    return text.replace(old, new, 1)


def counts(rows):
    return {'files': len(rows), 'bytes_total': sum(map(len, rows)),
            'lines_total': sum(raw.count(b'\n') for raw in rows)}


def main():
    need(not (BASE / 'publication.json').exists(), 'never overwrite completed address publication')
    proposal = current.address_fact.proposal()
    need(Path(current.address_fact.PROPOSAL).read_bytes() == before(current.address_fact.PROPOSAL),
         'complete committed reviewed address proposal')
    prior = current.historical()
    old = {'__name__': 'before_address', '__file__': 'scripts/check_record_value_publication.py'}
    exec(compile(before(old['__file__']), old['__file__'], 'exec'), old)
    cards = current.expected_cards(prior)
    need(cards == {path: row['text'] for path, row in proposal['cards'].items()},
         'complete exact address proposal admission')
    descriptors = before(DESCRIPTORS)
    need(Path(DESCRIPTORS).read_bytes() == descriptors, 'unchanged complete existing archive descriptor prefix')
    appended = []
    for path, row in proposal['cards'].items():
        original = Path(path).read_bytes()
        need(original == before(path) == Path(row['original']['locator']).read_bytes()
             and pin(original) == row['original']['identity'], 'complete original retained address card')
        appended.append({'schema_version': 1, 'record_type': 'descriptor',
            'descriptor_id': 'address-current-' + Path(path).stem + '-20261010',
            'surface_id': 'exact_history', 'former_path': path,
            'range_id': 'complete-card-before-qualified-finite-address-admission',
            'revision': proposal['revision'], **pin(original), 'retrieval_kind': 'file',
            'retrieval_locator': row['original']['locator'], 'current_pointer': path,
            'sealed_on': '2026-10-10', 'verifier': 'builtin:file'})
    chapters = {path: before(path).decode() for path in (FEATURE, REFERENCE)}
    need(all(Path(path).read_text() == text for path, text in chapters.items()),
         'whole unchanged address book source epoch')
    preparation = Path(current.address_fact.PREPARATION, 'book-addition.md.txt').read_text()
    replacements = {
        FEATURE: [(old['guide'](prior), current.guide(prior)),
                  (preparation, 'Retained address preparation checkpoint (before current admission):\n\n' + preparation)],
        REFERENCE: [(current.coordinate_fact.REFERENCE,
                     'Retained original-coordinate publication checkpoint:\n\n'
                     + current.coordinate_fact.REFERENCE + current.address_fact.REFERENCE)]}
    proposed_book = {}
    for path, text in chapters.items():
        for old_text, new_text in replacements[path]:
            text = replace(text, old_text, new_text)
        proposed_book[path] = text.encode()
    book_paths = sorted(path for path in git('ls-tree', '-r', '--name-only', REVISION, '--', 'docs/book/src').decode().splitlines()
                        if path.endswith('.md') and Path(path).parent == Path('docs/book/src'))
    need(book_paths == sorted(str(path) for path in Path('docs/book/src').glob('*.md')),
         'complete unchanged address book membership')
    original_book = [before(path) for path in book_paths]
    current_book = [proposed_book.get(path, Path(path).read_bytes()) for path in book_paths]
    need([path for path, a, b in zip(book_paths, original_book, current_book) if a != b] == sorted(proposed_book),
         'only complete owned address book chapters change')
    book_before, book_after = counts(original_book), counts(current_book)
    need(Path(SURFACES).read_bytes() == before(SURFACES), 'unchanged whole authority before address admission')
    registry = list(map(json.loads, Path(SURFACES).read_text().splitlines()))
    for row in registry:
        if row.get('surface_id') == 'shipped_behavior':
            row['reference_contract']['aggregate_change'] = {
                'authority_id': 'ADDRESS-CURRENT-PUBLICATION-20261010',
                'baseline': book_before, 'delta': {key: book_after[key] - value for key, value in book_before.items()},
                'owner': (BASE / 'scope.txt').read_text().strip(),
                'rationale': 'Publish exact reviewed finite address cards and current-reader authentication with complete governed beforeimages, preserved questions and unchanged Knowledge Map authority; native identity and final container closure remain separately owned.'}
    authenticated = current.address_fact.authenticate()
    # All evidence, original cards, prior descriptors and full book transformations
    # qualify before any canonical write. This whole owned slice commits together.
    Path(DESCRIPTORS).write_bytes(descriptors + ''.join(json.dumps(row, sort_keys=True, separators=(',', ':')) + '\n'
                                                      for row in appended).encode())
    for path, text in cards.items():
        Path(path).write_text(text)
    for path, raw in proposed_book.items():
        Path(path).write_bytes(raw)
    Path(SURFACES).write_text(''.join(json.dumps(row, sort_keys=True) + '\n' for row in registry))
    product = {'revision': REVISION, 'owner': (BASE / 'scope.txt').read_text().strip(),
        'proposal': pin(Path(current.address_fact.PROPOSAL).read_bytes()),
        'cards': {path: pin(text.encode()) for path, text in cards.items()},
        'descriptors': appended, 'original_descriptor_bytes': pin(descriptors),
        'chapters': {path: {'before': pin(chapters[path].encode()), 'after': pin(raw),
                          'original': chapters[path], 'current': raw.decode()} for path, raw in proposed_book.items()},
        'book_replacements': replacements, 'book_before': book_before, 'book_after': book_after,
        'authenticated_qualification': authenticated,
        'scope': 'Atomic finite address current card/reader/history/source/book publication; complete address-container acceptance and native identity remain separately owned.'}
    (BASE / 'publication.json').write_text(json.dumps(product, sort_keys=True, indent=2) + '\n')
    command = ['git', '--no-replace-objects', 'log', '-1', '--format=%H %s', '-S',
               'return coordinate_fact.cards(result)', '--', 'scripts/check_record_value_publication.py']
    result = subprocess.run(command, capture_output=True, text=True)
    (BASE / 'root-cause.json').write_text(json.dumps({'command': command, 'status': result.returncode,
        'stdout': result.stdout, 'stderr': result.stderr}, sort_keys=True, indent=2) + '\n')
    need(result.returncode == 0 and not result.stderr and result.stdout.startswith('7efdbf512bfd865220fb13f83fbbded9b42cdcf0 '),
         'actual installed predecessor expected-card contract history')
    print('PASS complete atomic finite address fact/reader/book admission, exact governed history and unchanged Knowledge Map authority.')


if __name__ == '__main__':
    main()

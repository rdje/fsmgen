"""Re-derive the full finite guide publication and unchanged fact authority."""
import copy
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-class-frame-admission-20261006')
CHECKS = Path('docs/audits/class-frame-admission-checks-20261006')
ns = {'__name__': 'independent_admission_publication', '__file__': str(BASE / 'verify.py')}
exec(compile((BASE / 'verify.py').read_bytes(), str(BASE / 'verify.py'), 'exec'), ns)
require, same, identity, load = (ns[k] for k in ('require', 'same', 'identity', 'load'))
chapter = Path('docs/book/src/13k-isf-feature-support-matrix.md')
registry = Path('doctrine/live_document_size/surfaces.jsonl')


def original(path):
    return subprocess.check_output(['git', 'show', ns['REVISION'] + ':' + str(path)])


def metrics(blobs):
    return dict(files=len(blobs), lines_total=sum(raw.count(b'\n') for raw in blobs.values()), bytes_total=sum(map(len, blobs.values())))


def check(record, books, before_row):
    book = ns['module'](BASE / 'book.py')
    before = books[str(chapter)].decode()
    marker = 'The own subtest source model now assigns original refusals'
    require(before.count(marker) == 1 and book['COMMAND'] not in before, 'complete original unique guide insertion context')
    after = before.replace(marker, book['GUIDE'] + marker, 1)
    require(record['before'] == before and record['after'] == after and record['chapter'] == str(chapter), 'whole independent admission-only chapter transformation')
    require(same(record['prior_whole_book'], {p:identity(raw) for p, raw in books.items()}), 'whole original physical book member population')
    baseline = metrics(books); actual = metrics({**books, str(chapter):after.encode()})
    require(same(record['baseline'], baseline) and same(record['actual'], actual), 'independently rederived complete book aggregate')
    expected_row = copy.deepcopy(before_row)
    expected_row['reference_contract']['aggregate_change'] = dict(
        authority_id='CLASS-FRAME-ADMISSION-20261006-SHIPPED-BEHAVIOR', owner=ns['OWNER'], baseline=baseline,
        delta={k:actual[k] - baseline[k] for k in baseline},
        rationale='Publish complete prerequisite custody and scoped actual replay only; independent class/frame join and original identity gaps remain open.')
    require(same(record['authority_before'], before_row) and same(record['authority_after'], expected_row), 'exact measured publication authority without ceiling widening')
    require(same(record['before_identity'], identity(before.encode())) and same(record['after_identity'], identity(after.encode())), 'whole finite source publication identities')
    return expected_row


def main():
    paths = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', ns['REVISION'], 'docs/book/src'], text=True).splitlines()
    books = {p:original(p) for p in paths if Path(p).parent == chapter.parent and p.endswith('.md')}
    old_lines = original(registry).decode().splitlines()
    before_row = next(json.loads(s) for s in old_lines if json.loads(s).get('surface_id') == 'shipped_behavior')
    record = load(BASE / 'book-change.json'); expected_row = check(record, books, before_row)
    current_lines = registry.read_text().splitlines()
    current_row = next(json.loads(s) for s in current_lines if json.loads(s).get('surface_id') == 'shipped_behavior')
    require(same(current_row, expected_row), 'whole current measured source guide authority')
    current_books = {str(p):p.read_bytes() for p in chapter.parent.glob('*.md')}
    require(current_books == {**books, str(chapter):record['after'].encode()}, 'complete physical current book change belongs only to admission')
    cards = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', ns['REVISION'], 'docs/knowledge'], text=True).splitlines()
    cards = [p for p in cards if Path(p).parent == Path('docs/knowledge') and p.endswith('.md')]
    actual_cards = sorted(str(p) for p in Path('docs/knowledge').glob('*.md'))
    require(actual_cards == sorted(cards) and all(Path(p).read_bytes() == original(p) for p in cards), 'whole unchanged physical canonical fact population')
    old_knowledge = next(json.loads(s) for s in old_lines if json.loads(s).get('surface_id') == 'knowledge_cards')
    current_knowledge = next(json.loads(s) for s in current_lines if json.loads(s).get('surface_id') == 'knowledge_cards')
    require(same(old_knowledge, current_knowledge), 'whole unchanged collection authority')
    controls = []
    for name, mutate, cause in (
        ('lost-book-member', lambda r:r['prior_whole_book'].pop(next(iter(r['prior_whole_book']))), 'whole original physical book member population'),
        ('invented-book-total', lambda r:r['actual'].update(bytes_total=0), 'independently rederived complete book aggregate'),
        ('invented-join', lambda r:r.update(after=r['after'].replace('Admission is not a class/frame semantic join.', 'Admission completes the semantic join.')), 'whole independent admission-only chapter transformation'),
        ('widened-book-ceiling', lambda r:r['authority_after']['enforcement_ceilings'].update(bytes_total=99999999), 'exact measured publication authority without ceiling widening')):
        changed = copy.deepcopy(record); mutate(changed)
        require(not same(changed, record), 'genuine publication intervention: ' + name)
        try:
            check(changed, books, before_row)
        except ValueError as error:
            require(str(error) == cause, 'intended publication refusal: ' + name)
            controls.append(dict(control=name, status=1, cause=cause))
        else:
            raise ValueError('false-green independent publication: ' + name)
    output = dict(revision=ns['REVISION'], book_change=identity((BASE / 'book-change.json').read_bytes()),
                  unchanged_facts={p:identity(Path(p).read_bytes()) for p in cards}, knowledge_authority=current_knowledge, controls=controls,
                  legs=dict(rederive='whole fixed-Git book membership and byte/LF census plus exact unique source-guide transformation',
                            falsify='genuine member/aggregate/semantic-scope/authority substitutions refuse',
                            durability='tracked independent programme, complete source proof and actual result; unchanged facts/collection are pinned'))
    destination = CHECKS / 'publication-proof.json'
    if destination.exists():
        require(same(load(destination), output), 'whole saved independent publication proof')
    else:
        destination.write_text(json.dumps(output, sort_keys=True, indent=2) + '\n')
    print('PASS complete independent admission-guide aggregate and controls; every physical fact and collection authority unchanged.')


if __name__ == '__main__':
    main()

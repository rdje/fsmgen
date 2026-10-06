"""Publish only the qualified public documentation/profile role."""
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-public-framework-profile-20261006')
ns = {'__name__': 'publish_public_framework_profile_guide'}
exec(compile((BASE / 'verify.py').read_bytes(), str(BASE / 'verify.py'), 'exec'), ns)
book = ns['module'](BASE / 'book.py')
assert not (BASE / 'manifest.json').exists() and not (BASE / 'book-change.json').exists()
chapter = Path('docs/book/src/13k-isf-feature-support-matrix.md')
registry = Path('doctrine/live_document_size/surfaces.jsonl')
marker = 'The own subtest source model now assigns original refusals'
before = chapter.read_text()
assert before == subprocess.check_output(['git', 'show', ns['REVISION'] + ':' + str(chapter)]).decode()
assert before.count(marker) == 1 and before.count(book['COMMAND']) == 0
after = before.replace(marker, book['GUIDE'] + marker, 1)
before_book = {str(p): p.read_bytes() for p in chapter.parent.glob('*.md')}
after_book = {**before_book, str(chapter): after.encode()}
def metrics(blobs):
    return dict(files=len(blobs), lines_total=sum(raw.count(b'\n') for raw in blobs.values()),
                bytes_total=sum(map(len, blobs.values())))
baseline, actual = metrics(before_book), metrics(after_book)
rows = registry.read_text().splitlines()
authority_before = authority_after = None
for i, line in enumerate(rows):
    row = json.loads(line)
    if row.get('surface_id') == 'shipped_behavior':
        authority_before = row
        authority_after = json.loads(line)
        authority_after['reference_contract']['aggregate_change'] = dict(
            authority_id='PUBLIC-FRAMEWORK-PROFILE-20261006-SHIPPED-BEHAVIOR',
            owner=(BASE / 'scope.txt').read_text().splitlines()[0].removeprefix('Owner: '),
            baseline=baseline, delta={k: actual[k]-baseline[k] for k in baseline},
            rationale='Document dated installed public trace interfaces and keep current/profile/original/native boundaries explicit.')
        rows[i] = json.dumps(authority_after, sort_keys=True, separators=(',', ':'))
assert authority_after is not None
chapter.write_text(after)
registry.write_text('\n'.join(rows)+'\n')
ns['save']('book-change.json', dict(chapter=str(chapter), before=before, after=after,
    before_identity=ns['identity'](before.encode()), after_identity=ns['identity'](after.encode()),
    baseline=baseline, actual=actual, authority_before=authority_before, authority_after=authority_after,
    role='Partial current public documentation/profile tooling publication only; native/original joins and full fact publication retain .5.2/.5.3/.5.4 owners. No new source-view href or Knowledge Map mutation.'))
print('PASS scoped public framework/profile guide and exact owning book aggregate; no ceiling/card change.')

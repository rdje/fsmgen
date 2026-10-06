"""Publish qualified public fixture scope from its fixed Git baseline."""
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-public-native-fixtures-20261006')
ns = {'__name__': 'publish_public_native_fixture_guide'}
exec(compile((BASE / 'verify.py').read_bytes(), str(BASE / 'verify.py'), 'exec'), ns)
book = ns['module'](BASE / 'book.py')
assert not (BASE / 'manifest.json').exists() and not (BASE / 'book-change.json').exists()
chapter = Path('docs/book/src/13k-isf-feature-support-matrix.md')
registry = Path('doctrine/live_document_size/surfaces.jsonl')
before = chapter.read_text()
assert before == subprocess.check_output(['git', 'show', ns['REVISION'] + ':' + str(chapter)]).decode()
old = 'This qualifies the installed public documentation/profile only. Independent\npublic native controls and the original outer-boundary join remain next steps.'
new = 'This dated evidence qualifies the installed public documentation/profile.\nThe independent public fixtures below now refine current interface roles; the\noriginal outer-boundary join remains the next step.'
marker = 'The own subtest source model now assigns original refusals'
assert before.count(old) == before.count(marker) == 1 and book['COMMAND'] not in before
after = before.replace(old, new, 1).replace(marker, book['GUIDE'] + marker, 1)
blobs = {str(p): p.read_bytes() for p in chapter.parent.glob('*.md')}
def metrics(data):
    return dict(files=len(data), lines_total=sum(v.count(b'\n') for v in data.values()), bytes_total=sum(map(len, data.values())))
baseline, actual = metrics(blobs), metrics({**blobs, str(chapter): after.encode()})
lines = registry.read_text().splitlines(); authority_before = authority_after = None
for i, line in enumerate(lines):
    row = json.loads(line)
    if row.get('surface_id') == 'shipped_behavior':
        authority_before = row; authority_after = json.loads(line)
        authority_after['reference_contract']['aggregate_change'] = dict(
            authority_id='PUBLIC-NATIVE-FIXTURES-20261006-SHIPPED-BEHAVIOR',
            owner=(BASE / 'scope.txt').read_text().splitlines()[0].removeprefix('Owner: '),
            baseline=baseline, delta={k:actual[k]-baseline[k] for k in baseline},
            rationale='Publish finite current public fixtures and retire only their completed profile deferral; original/private meanings remain explicit.')
        lines[i] = json.dumps(authority_after, sort_keys=True, separators=(',', ':'))
assert authority_after is not None
chapter.write_text(after); registry.write_text('\n'.join(lines) + '\n')
ns['save']('book-change.json', dict(before=before, after=after, before_identity=ns['identity'](before.encode()),
    after_identity=ns['identity'](after.encode()), baseline=baseline, actual=actual,
    authority_before=authority_before, authority_after=authority_after,
    role='Partial current public native tooling guide; original joining and current facts retain separate owners. No source-view href or Knowledge Map change.'))
print('PASS public native fixture guide and fixed-Git aggregate; no ceiling/card change.')

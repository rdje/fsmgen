"""Prepare the current replay guide; commit only after seal qualification."""
import io
import json
import subprocess
import tarfile
from pathlib import Path

BASE = Path('docs/audits/record-value-public-boundary-join-20261006')
CHECKS = Path('docs/audits/public-boundary-join-checks-20261006')
REVISION = 'af4999e7308865968f69ff5ec72591dc24101fd1'
ns = {'__name__': 'publish_resource_safe_public_boundary_guide'}
exec(compile((BASE / 'verify.py').read_bytes(), str(BASE / 'verify.py'), 'exec'), ns)
assert not (BASE / 'manifest.json').exists()
old = ns['module'](BASE / 'checkpoint-book.py.txt')
new = ns['module'](BASE / 'book.py')
chapter = Path('docs/book/src/13k-isf-feature-support-matrix.md')
registry = Path('doctrine/live_document_size/surfaces.jsonl')
before = chapter.read_text()
assert before == subprocess.check_output(['git', 'show', REVISION + ':' + str(chapter)]).decode()
pending = ('The public-header checks and scoped native guide below are qualified as a\n'
           'checkpoint. The current combined seal replay stopped at the unchanged RAM guard\n'
           'cutoff. No whole-member seal or independent final result qualification is\n'
           'claimed yet; these durability steps remain active before full fact publication.\n\n')
assert before.count(old['GUIDE']) == before.count(pending) == 1
after = before.replace(old['GUIDE'], new['GUIDE'], 1).replace(pending, '', 1)


def metrics(blobs):
    return dict(files=len(blobs), lines_total=sum(v.count(b'\n') for v in blobs.values()),
                bytes_total=sum(map(len, blobs.values())))


data = subprocess.check_output(['git', 'archive', REVISION, str(chapter.parent)])
with tarfile.open(fileobj=io.BytesIO(data)) as archive:
    originals = {entry.name: archive.extractfile(entry).read() for entry in archive.getmembers()
                 if entry.isfile() and entry.name.endswith('.md')}
current = {str(p): p.read_bytes() for p in chapter.parent.glob('*.md')}
assert current == originals
baseline = metrics(originals)
actual = metrics({**current, str(chapter): after.encode()})
lines = registry.read_text().splitlines()
for i, line in enumerate(lines):
    row = json.loads(line)
    if row.get('surface_id') == 'shipped_behavior':
        authority_before = json.loads(line)
        row['reference_contract']['aggregate_change'] = dict(
            authority_id='PUBLIC-BOUNDARY-SEALED-REPLAY-20261006-SHIPPED-BEHAVIOR',
            owner=(BASE / 'scope.txt').read_text().splitlines()[0].removeprefix('Owner: '),
            baseline=baseline, delta={k: actual[k] - baseline[k] for k in baseline},
            rationale='Document broad and explicitly scoped saved-prerequisite replay roles; commit only after current seal and independent result qualification. Historical/private boundaries remain open.')
        authority_after = row
        lines[i] = json.dumps(row, sort_keys=True, separators=(',', ':'))
        break
else:
    raise ValueError('missing owned book aggregate')
chapter.write_text(after)
registry.write_text('\n'.join(lines) + '\n')
receipt = dict(revision=REVISION, before=before, after=after,
               before_identity=ns['identity'](before.encode()), after_identity=ns['identity'](after.encode()),
               baseline=baseline, actual=actual, authority_before=authority_before, authority_after=authority_after,
               role='Draft current guide; publication waits for actual current seal and independent result qualification.')
(CHECKS / 'narrow-book-change.json').write_text(json.dumps(receipt, sort_keys=True, indent=2) + '\n')
print('PASS exact committed chapter transformation and measured aggregate for resource-safe replay guide.')

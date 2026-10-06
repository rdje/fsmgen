"""Publish the bounded publication-admission guide with exact measured book authority."""
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-class-frame-publication-admission-20261006')
CHECKS = Path('docs/audits/class-frame-publication-admission-checks-20261006')
ns = {'__name__': 'publish_class_frame_join', '__file__': str(BASE / 'verify.py')}
exec(compile((BASE / 'verify.py').read_bytes(), str(BASE / 'verify.py'), 'exec'), ns)
book = ns['module'](BASE / 'book.py')
chapter = Path('docs/book/src/13k-isf-feature-support-matrix.md')
registry = Path('doctrine/live_document_size/surfaces.jsonl')
assert not (BASE / 'manifest.json').exists() and not (BASE / 'book-change.json').exists()
actual = ns['load'](CHECKS / 'fresh-replay.json')
assert type(actual['status']) is int and actual['status'] == 0
assert actual['command'] == ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', str(BASE / 'verify.py'), '--replay']
assert actual['stdout'] == ''.join('Admitted fresh publication prerequisite: ' + spec['name'] + '\n' for spec in ns['replay_specs']()) + ns['FRESH_SUCCESS']
before = chapter.read_text()
assert before.encode() == subprocess.check_output(['git', 'show', ns['REVISION'] + ':' + str(chapter)])
marker = 'The own subtest source model now assigns original refusals'
assert before.count(marker) == 1 and book['COMMAND'] not in before
after = book['transform'](before)
blobs = {str(p): p.read_bytes() for p in chapter.parent.glob('*.md')}
assert all(raw == subprocess.check_output(['git', 'show', ns['REVISION'] + ':' + p]) for p, raw in blobs.items())
def metrics(data):
    return dict(files=len(data), lines_total=sum(raw.count(b'\n') for raw in data.values()), bytes_total=sum(map(len, data.values())))
baseline = metrics(blobs); updated = metrics({**blobs, str(chapter): after.encode()})
lines = registry.read_text().splitlines()
i = next(i for i, line in enumerate(lines) if json.loads(line).get('surface_id') == 'shipped_behavior')
authority_before, authority_after = json.loads(lines[i]), json.loads(lines[i])
authority_after['reference_contract']['aggregate_change'] = dict(
    authority_id='CLASS-FRAME-PUBLICATION-ADMISSION-20261006-SHIPPED-BEHAVIOR', owner=ns['OWNER'], baseline=baseline,
    delta={key: updated[key] - baseline[key] for key in baseline},
    rationale='Publish bounded full class/frame publication admission and explicit fresh versus retained reader roles; semantic retention and atomic current fact publication remain pending.')
lines[i] = json.dumps(authority_after, sort_keys=True, separators=(',', ':'))
chapter.write_text(after); registry.write_text('\n'.join(lines) + '\n')
ns['save']('book-change.json', dict(chapter=str(chapter), before=before, after=after,
    before_identity=ns['identity'](before.encode()), after_identity=ns['identity'](after.encode()),
    baseline=baseline, actual=updated, authority_before=authority_before, authority_after=authority_after,
    prior_whole_book={p:ns['identity'](raw) for p, raw in blobs.items()},
    role='Publication admission guide; existing facts/questions/source selection and collection authority unchanged.'))
print('PASS scoped publication-admission guide and exact measured book aggregate; current fact publication remains pending.')

#!/usr/bin/env python3
"""Check whole-source/question custody and the small reviewed prose containment."""
import gzip
import hashlib
import io
import json
from pathlib import Path
import subprocess
import tarfile

root = Path(__file__).resolve().parents[3]
assert Path.cwd().resolve() == root
folder = Path('docs/audits/pod-api-20261023')
saved = json.loads((folder / 'knowledge-route-before.json').read_text())
base = saved['base_revision']
path = saved['historical_card_path']
retired = saved['retired_pointer_path']
added = 'docs/knowledge/perl-pod-api.md'
assert len(base) == 40 and all(c in '0123456789abcdef' for c in base)
archive = subprocess.check_output(['git', 'archive', base, 'docs/knowledge'])
with tarfile.open(fileobj=io.BytesIO(archive)) as source:
    original = {p.name: source.extractfile(p).read() for p in source.getmembers()
                if p.isfile() and p.name.endswith('.md')}
names = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', base, 'docs/knowledge']).decode().splitlines()
assert set(original) == {p for p in names if p.endswith('.md')}
assert original[path].decode() == saved['historical_card']
assert original[retired].decode() == saved['retired_pointer']
current = {p.as_posix(): p.read_bytes() for p in Path('docs/knowledge').glob('*.md')}


def custody(candidate):
    assert set(candidate) == (set(original) - {retired}) | {added}
    for name, raw in original.items():
        if name not in (path, retired):
            assert candidate[name] == raw, name
    # All old front-matter, including every answer, evidence path and reverify,
    # stays byte-identical. The complete old/new bodies are retained for review.
    old = original[path].decode()
    new = candidate[path].decode()
    assert old.split('---\n', 2)[:2] == new.split('---\n', 2)[:2]
    old_body = old.split('---\n', 2)[2]
    new_body = new.split('---\n', 2)[2]
    history = '8e0c5f1af948b928908005a7dcd6c73e3db5c152'
    assert f'`{history}:{path}`' in old_body
    assert f'History at this path: `{history}`.' in new_body
    # Explicit reviewed meanings cover the entire small historical body:
    # cause/repair; original exact scope/result; invocation root/command;
    # cwd semantics; unsafe-parent omission; all recovery operations/locations;
    # no rerun/cleanup replay or promotion to current full-book qualification.
    clauses = ['Untyped diagram fences reached rustdoc as Rust; `text` repaired them.',
               'Git retains exact scope/original test result.',
               'Repo-root: `mdbook build docs/book --dest-dir .artifacts/tmp/OWNED/book`.',
               'Destination uses invocation cwd; omit `../../../`.',
               'Saved audit verifies exact misplaced book copy/hash/inspection/removal at both locations.',
               'No rebuild or repeated cleanup; historical rustdoc results do not qualify the current full book.']
    assert all(clause in new_body for clause in clauses)
    guide = Path('knowledge-map/README.md').read_text()
    assert 'default `docs/knowledge/`' in guide
    assert 'Copy `knowledge-map/templates/FACT_TEMPLATE.md` there and rename it `<id>.md`.' in guide
    return {'original_body': old_body, 'contained_body': new_body, 'reviewed_meanings': clauses}


review = custody(current)
before = set(gzip.decompress((folder / 'knowledge-questions-before.tsv.gz').read_bytes()).decode().splitlines())
after = set(subprocess.check_output(['knowledge-map/scripts/query_knowledge_map.sh', '--all']).decode().splitlines())
new_row = 'where is the Perl POD API reference?\tperl-pod-api\t' + added


def questions(rows):
    assert before <= rows and rows - before == {new_row}


questions(after)
registry_path = 'doctrine/live_document_size/surfaces.jsonl'
def authority(raw):
    return next(r for line in raw.decode().splitlines()
                if (r := json.loads(line)).get('surface_id') == 'knowledge_cards')
previous_authority = authority(subprocess.check_output(['git', 'show', base + ':' + registry_path]))
current_authority = authority(Path(registry_path).read_bytes())
assert current_authority == previous_authority, 'Knowledge Map allowance/authority changed'
limits = {key: current_authority['baseline'][key] + current_authority['transition']['max_growth'][key]
          for key in ('files', 'bytes_total')}
# Genuine omissions fail the same custody/question predicates.
controls = []
for label, probe in [
    ('missing old question', lambda: questions(after - {min(before)})),
    ('borrowed question owner', lambda: questions((after - {min(before)}) | {'borrowed\tfake\tfake.md'})),
    ('missing old card', lambda: custody({p: raw for p, raw in current.items() if p != path})),
    ('lost recovery location', lambda: custody({**current, path: current[path].replace(b'both locations', b'one location')})),
    ('changed original metadata', lambda: custody({**current, path: current[path].replace(b'date: 2026-09-13', b'date: 2026-09-14')})),
]:
    try:
        probe()
    except AssertionError:
        controls.append(label)
    else:
        raise AssertionError('Control was falsely accepted: ' + label)
print(json.dumps({'base_revision': base, 'old_source_members': len(original),
                  'current_source_members': len(current), 'old_question_rows': len(before),
                  'only_new_question': new_row, 'all_other_source_bytes_preserved': True,
                  'current_card_bytes': sum(map(len, current.values())),
                  'unchanged_collection_limits': limits,
                  'prose_review': review, 'rejected_controls': controls,
                  'contained_card_sha256': hashlib.sha256(current[path]).hexdigest()}, indent=2))
assert len(current) <= limits['files'] and sum(map(len, current.values())) <= limits['bytes_total']

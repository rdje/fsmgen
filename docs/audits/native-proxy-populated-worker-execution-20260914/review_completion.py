"""Join the first actual execution, retained copies and synchronized documents."""
import argparse
import hashlib
import json
import re
import subprocess

import audit

BASE, ROOT, REVISION = audit.BASE, audit.ROOT, audit.REVISION
LOG = ROOT / '.artifacts/logs' / BASE.name
STAGES = ['audit-final', 'retention', 'book-final', 'book-inspection-final', 'knowledge-generate',
          'knowledge-check', 'claims-write-final', 'claims-check-final', 'claims-review-final', 'containment-check']


def old(path):
    return subprocess.check_output(['git', 'show', REVISION + ':' + path], cwd=ROOT)


def pin(path):
    body = path.read_bytes()
    return dict(path=str(path.relative_to(ROOT)), size_bytes=len(body),
                sha256=hashlib.sha256(body).hexdigest())


def check(outputs):
    assert set(outputs) == set(STAGES) and all(row['exit'] == '0\n' for row in outputs.values())
    for row in audit.read('completion-pins.json'):
        assert pin(ROOT / row['path']) == row
    review = audit.read('review.json')
    first = audit.read('audit-first.json')
    assert json.loads(outputs['audit-final']['stdout']) == first['result'] == review
    assert first['outputs']['exit'] == '0\n' and json.loads(first['outputs']['stdout']) == review
    assert pin(ROOT / first['source']['path']) == first['source']
    for row in audit.read('source-pins.json'):
        assert pin(ROOT / row['path']) == row
    original = audit.read('first-results.json')
    for row in original['first_results']:
        assert pin(ROOT / row['copy']['path']) == row['copy']
    assert len(original['first_results']) == review['retained_files'] == 47
    assert sum(row['copy']['size_bytes'] for row in original['first_results']) == review['retained_bytes']
    assert all(row['exit'] == '0\n' for row in original['raw_outputs'].values())
    assert review['actual_selected_worker_execution_reviewed'] and not review['producer_replayed']
    assert 'knowledge-map: OK' in outputs['knowledge-check']['stdout'] + outputs['knowledge-check']['stderr']
    assert 'all live-document size-containment invariants hold' in outputs['containment-check']['stdout']
    book = audit.read('book-review-final.json')
    assert json.loads(outputs['book-inspection-final']['stdout']) == book
    assert book['same_volume_direct_objects'] and book['exact_output_absent']
    assert len(book['checked_passages']) == 6 and len(book['checked_runtime_passages']) == 2
    assert not (ROOT / book['output']).exists()
    claims, metrics = audit.read('claim-review-final.json'), audit.read('book-metrics-final.json')
    assert claims['candidate_identities_and_semantics_unchanged'] and claims['dispositions_unchanged']
    assert claims['book_baseline'] == metrics['baseline'] and claims['book_delta'] == metrics['delta']
    route = audit.read('knowledge-route.json')
    before, after = old(route['source_path']), (ROOT / route['source_path']).read_bytes()
    assert hashlib.sha256(before).hexdigest() == route['previous_sha256']
    assert hashlib.sha256(after).hexdigest() == route['current_sha256']
    questions = lambda body: re.findall(rb'^  - ".*"$', body, re.M)
    assert questions(before) == questions(after) and len(questions(after)) == 127
    assert len(after) <= len(before) and after.count(b'\n') == before.count(b'\n')
    assert (REVISION + ':' + route['source_path']).encode() in after
    history = ROOT / 'docs/tasks/history/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE/acceptance-history.jsonl'
    rows = [json.loads(line) for line in history.read_bytes().splitlines()]
    assert len(rows) == 2
    h = rows[1]
    source = old(h['source_path'])
    suffix = source[source.rfind(b'## Acceptance Checklist'):]
    assert h['source_revision'] == REVISION and h['source_sha256'] == hashlib.sha256(source).hexdigest()
    assert h['source_bytes'] == len(source) and h['source_lines'] == source.count(b'\n')
    assert h['history_sha256'] == hashlib.sha256(suffix).hexdigest()
    assert h['history_bytes'] == len(suffix) and h['history_lines'] == suffix.count(b'\n') == 5
    task = (ROOT / h['source_path']).read_text()
    status = lambda owner: task.split('- ID: `' + owner + '`\n', 1)[1].splitlines()[0].strip()
    assert status(review['owner']) == 'Status: `done`'
    assert status(review['next_owner']) == 'Status: `proposed`'
    assert status(review['owner'].rsplit('.', 1)[0]) == 'Status: `active`'
    assert task.count('\n') == 6370
    previous = source.decode()
    assert previous[previous.index('## Acceptance Checklist'):previous.rfind('## Acceptance Checklist')] == task[task.index('## Acceptance Checklist'):task.rfind('## Acceptance Checklist')]
    assert all(not (ROOT / path).exists() and not (ROOT / path).is_symlink() for path in review['absent_roots'])
    memory = (ROOT / 'MEMORY.md').read_text()
    assert '- active_work_unit: `' + review['next_owner'] + '`' in memory
    assert '- in_flight_uncommitted: none.' in memory and '- in_flight_background: none.' in memory
    return dict(owner=review['owner'], next_owner=review['next_owner'], source_revision=REVISION,
        result=review, book=book, claims=pin(BASE / 'claim-review-final.json'), previous_acceptance=h,
        raw_outputs=outputs, actual_worker_execution_complete=True,
        final_cross_boundary_join_open=True, native_live_startup_qualification_open=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--retain', action='store_true')
    group.add_argument('--verify-saved', action='store_true')
    args = parser.parse_args()
    if args.retain:
        outputs = {stage: {ext: (LOG / (stage + '.' + ext)).read_text()
                           for ext in ('stdout', 'stderr', 'exit')} for stage in STAGES}
        result = check(outputs)
        with (BASE / 'completion.json').open('x') as stream:
            json.dump(result, stream, sort_keys=True, indent=2)
            stream.write('\n')
    else:
        saved = audit.read('completion.json')
        assert check(saved['raw_outputs']) == saved
    print('Actual populated-worker execution: OK; final cooperative-lifetime join remains open.')

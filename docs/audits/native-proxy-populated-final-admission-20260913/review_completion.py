"""Join this admission slice's retained validation and synchronized documents."""
import argparse
import hashlib
import json
import re
import subprocess

import audit
from contract import BASE, ROOT, OWNER, EXECUTION_OWNER, OUTPUT, TASK, roots
import source_inventory

REVISION = audit.SCOPE['source_revision']
LOG = ROOT / '.artifacts/logs' / BASE.name
STAGES = ['audit-final', 'book', 'book-inspection', 'knowledge-generate',
          'knowledge-check', 'claims-write', 'claims-check', 'claims-review',
          'containment-check']


def pin(path):
    body = path.read_bytes()
    return dict(path=str(path.relative_to(ROOT)), size_bytes=len(body),
                sha256=hashlib.sha256(body).hexdigest())


def old(path):
    return subprocess.check_output(['git', 'show', REVISION + ':' + path], cwd=ROOT)


def check(outputs):
    for row in audit.read('completion-pins.json'):
        assert pin(ROOT / row['path']) == row
    assert set(outputs) == set(STAGES)
    assert all(row['exit'] == '0\n' for row in outputs.values())
    assert source_inventory.pins() == audit.read('execution-source-pins.json')
    review = audit.read('review.json')
    assert json.loads(outputs['audit-final']['stdout']) == review
    first = audit.read('combined-first.json')
    assert first['outputs']['exit'] == '0\n'
    assert json.loads(first['outputs']['stdout']) == first['result'] == review
    for row in first['sources']:
        expected = {key: row[key] for key in ('path', 'size_bytes', 'sha256')}
        assert pin(ROOT / row['path']) == expected
        assert (ROOT / row['original']).read_bytes() == (ROOT / row['path']).read_bytes()
    assert not review['actual_permit_issued'] and not review['actual_worker_execution']
    assert 'knowledge-map: OK' in outputs['knowledge-check']['stdout'] + outputs['knowledge-check']['stderr']
    assert 'all live-document size-containment invariants hold' in outputs['containment-check']['stdout']
    book = audit.read('book-review.json')
    assert json.loads(outputs['book-inspection']['stdout']) == book
    assert book['same_volume_direct_objects'] and book['exact_output_absent']
    assert len(book['checked_passages']) == 6 and len(book['checked_runtime_passages']) == 2
    assert not (ROOT / book['output']).exists()
    claims, metrics = audit.read('claim-review.json'), audit.read('book-metrics.json')
    assert claims['candidate_identities_and_semantics_unchanged'] and claims['dispositions_unchanged']
    assert claims['book_baseline'] == metrics['baseline']
    assert claims['book_delta'] == metrics['delta']
    route = audit.read('knowledge-route.json')
    before, after = old(route['source_path']), (ROOT / route['source_path']).read_bytes()
    assert hashlib.sha256(before).hexdigest() == route['previous_sha256']
    assert hashlib.sha256(after).hexdigest() == route['current_sha256']
    questions = lambda value: re.findall(rb'^  - ".*"$', value, re.M)
    assert questions(after) == questions(before) and len(questions(after)) == 127
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
    task = (ROOT / TASK).read_text()
    status = lambda owner: task.split('- ID: `' + owner + '`\n', 1)[1].splitlines()[0].strip()
    assert status(OWNER) == status(OWNER.rsplit('.', 1)[0]) == 'Status: `done`'
    assert status(EXECUTION_OWNER) == 'Status: `proposed`'
    assert task.count('\n') == 6370
    previous = source.decode()
    assert previous[previous.index('## Acceptance Checklist'):previous.rfind('## Acceptance Checklist')] == task[task.index('## Acceptance Checklist'):task.rfind('## Acceptance Checklist')]
    absent = [OUTPUT, *roots()]
    assert all(not (ROOT / path).exists() and not (ROOT / path).is_symlink() for path in absent)
    memory = (ROOT / 'MEMORY.md').read_text()
    assert '- active_work_unit: `' + EXECUTION_OWNER + '`' in memory
    assert '- in_flight_uncommitted: none.' in memory and '- in_flight_background: none.' in memory
    return dict(owner=OWNER, next_owner=EXECUTION_OWNER, source_revision=REVISION,
                result=review, book=book, claims=pin(BASE / 'claim-review.json'),
                previous_acceptance=h, raw_outputs=outputs, absent_owned_paths=absent,
                final_source_admission_complete=True, actual_worker_execution=False,
                native_live_startup_qualification_open=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    selection = parser.add_mutually_exclusive_group(required=True)
    selection.add_argument('--retain', action='store_true')
    selection.add_argument('--verify-saved', action='store_true')
    args = parser.parse_args()
    if args.retain:
        outputs = {stage: {ext: (LOG / (stage + '.' + ext)).read_text()
                           for ext in ['stdout', 'stderr', 'exit']} for stage in STAGES}
        result = check(outputs)
        with (BASE / 'completion.json').open('x') as stream:
            json.dump(result, stream, sort_keys=True, indent=2)
            stream.write('\n')
    else:
        saved = audit.read('completion.json')
        assert check(saved['raw_outputs']) == saved
    print('Populated-worker final source admission: OK; actual execution remains separate.')

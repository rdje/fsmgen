"""Retain the completed slice's evidence, documentation and handoff checks."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs' / BASE.name
TASK = 'docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md'
STAGES = ('audit-final', 'book', 'book-inspection', 'knowledge-generate',
          'knowledge-check', 'knowledge-query', 'claims-write', 'claims-check',
          'claims-review', 'containment-check')


def read(name):
    return json.loads((BASE / name).read_bytes())


def pin(path):
    body = path.read_bytes()
    return dict(path=str(path.relative_to(ROOT)), size_bytes=len(body),
                sha256=hashlib.sha256(body).hexdigest())


def check(outputs):
    scope = read('scope.json')
    revision = scope['source_revision']
    old = lambda path: subprocess.check_output(
        ['git', 'show', revision + ':' + path], cwd=ROOT)
    for row in read('completion-pins.json'):
        assert pin(ROOT / row['path']) == row
    for row in read('source-pins.json'):
        assert pin(ROOT / row['path']) == row
    assert set(outputs) == set(STAGES)
    assert all(row['exit'] == '0\n' for row in outputs.values())
    review = read('review.json')
    assert json.loads(outputs['audit-final']['stdout']) == review
    first = read('combined-first.json')
    assert first['outputs']['exit'] == '0\n'
    assert json.loads(first['outputs']['stdout']) == first['result'] == review
    assert pin(ROOT / first['source']['path']) == first['source']
    assert (BASE / 'audit.py').read_bytes() == (ROOT / first['source']['path']).read_bytes()
    assert review['cooperative_populated_lifetime_qualified']
    assert review['synthetic_retirement_and_work_records']
    assert review['native_live_startup_qualification_open']
    assert all(not review[field] for field in (
        'producer_replayed', 'native_resampled', 'fixture_mutated',
        'compiler_execution', 'proxy_execution', 'live_collector_execution',
        'python_populated_api_qualified'))
    assert 'knowledge-map: OK' in outputs['knowledge-check']['stdout'] + outputs['knowledge-check']['stderr']
    assert 'all live-document size-containment invariants hold' in outputs['containment-check']['stdout']
    book = read('book-review.json')
    assert json.loads(outputs['book-inspection']['stdout']) == book
    assert book['same_volume_direct_objects'] and book['exact_output_absent']
    assert len(book['checked_passages']) == 6 and len(book['checked_runtime_passages']) == 2
    assert not (ROOT / book['output']).exists()
    claims, metrics = read('claim-review.json'), read('book-metrics.json')
    assert claims['candidate_identities_and_semantics_unchanged'] and claims['dispositions_unchanged']
    assert claims['book_baseline'] == metrics['baseline']
    assert claims['book_delta'] == metrics['delta']
    route = read('knowledge-route.json')
    before, after = old(route['source_path']), (ROOT / route['source_path']).read_bytes()
    assert hashlib.sha256(before).hexdigest() == route['previous_sha256']
    assert hashlib.sha256(after).hexdigest() == route['current_sha256']
    questions = lambda value: re.findall(rb'^  - "(.*)"$', value, re.M)
    previous_questions, current_questions = questions(before), questions(after)
    assert current_questions[:-1] == previous_questions
    assert len(previous_questions) == route['previous_questions_preserved'] == 127
    assert len(current_questions) == route['current_questions'] == 128
    assert current_questions[-1].decode() == route['new_question']
    assert (revision + ':' + route['source_path']).encode() in after
    assert route['source_path'] in outputs['knowledge-query']['stdout']
    history = ROOT / 'docs/tasks/history/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE/acceptance-history.jsonl'
    rows = [json.loads(line) for line in history.read_bytes().splitlines()]
    assert len(rows) == 2
    archived = rows[1]
    source = old(archived['source_path'])
    suffix = source[source.rfind(b'## Acceptance Checklist'):]
    assert archived['source_revision'] == revision
    assert archived['source_sha256'] == hashlib.sha256(source).hexdigest()
    assert archived['source_bytes'] == len(source)
    assert archived['source_lines'] == source.count(b'\n')
    assert archived['history_sha256'] == hashlib.sha256(suffix).hexdigest()
    assert archived['history_bytes'] == len(suffix)
    assert archived['history_lines'] == suffix.count(b'\n') == 5
    task = (ROOT / TASK).read_text()
    status = lambda owner: task.split('- ID: `' + owner + '`\n', 1)[1].splitlines()[0].strip()
    assert status(scope['owner']) == status(scope['parent_owner']) == 'Status: `done`'
    assert status(scope['next_owner']) == 'Status: `proposed`'
    assert task.count('\n') == 6370
    previous = source.decode()
    assert previous[previous.index('## Acceptance Checklist'):previous.rfind('## Acceptance Checklist')] == task[task.index('## Acceptance Checklist'):task.rfind('## Acceptance Checklist')]
    absent = review['empty_store']['roots_absent'] + review['populated']['roots_absent']
    assert len(absent) == len(set(absent)) == 32
    assert all(not (ROOT / path).exists() and not (ROOT / path).is_symlink() for path in absent)
    memory = (ROOT / 'MEMORY.md').read_text()
    assert '- active_work_unit: `' + scope['next_owner'] + '`' in memory
    assert '- in_flight_uncommitted: none.' in memory
    assert '- in_flight_background: none.' in memory
    return dict(owner=scope['owner'], next_owner=scope['next_owner'], source_revision=revision,
                review=pin(BASE / 'review.json'), book=book,
                claims=pin(BASE / 'claim-review.json'), previous_acceptance=archived,
                raw_outputs=outputs, absent_owned_paths=absent,
                cooperative_lifetime_join_complete=True, producer_replayed=False,
                native_live_startup_qualification_open=True,
                handoff='Stop after the normal commit workflow; the user requested /exit.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    selection = parser.add_mutually_exclusive_group(required=True)
    selection.add_argument('--retain', action='store_true')
    selection.add_argument('--verify-saved', action='store_true')
    args = parser.parse_args()
    if args.retain:
        outputs = {stage: {ext: (LOG / (stage + '.' + ext)).read_text()
                           for ext in ('stdout', 'stderr', 'exit')} for stage in STAGES}
        result = check(outputs)
        with (BASE / 'completion.json').open('x') as stream:
            json.dump(result, stream, sort_keys=True, indent=2)
            stream.write('\n')
    else:
        saved = read('completion.json')
        assert check(saved['raw_outputs']) == saved
    print('Cooperative lifetime evidence join: OK; next feature task remains unstarted.')

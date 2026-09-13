"""Join the completed actual compiler census to its durable project state."""
import argparse
import hashlib
import json
import re

import audit
import admission

BASE, ROOT, REVISION = audit.BASE, audit.ROOT, audit.REVISION
LOG = ROOT / '.artifacts/logs' / BASE.name
STAGES = ['saved-audit', 'book', 'book-inspection', 'knowledge-generate', 'knowledge-check',
          'knowledge-query', 'pickaxe', 'claims-write', 'claims-check', 'claims-review']


def old(path):
    return admission.git('show', REVISION + ':' + path)


def check(outputs):
    for row in audit.read('completion-pins.json'):
        assert audit.pin(ROOT / row['path']) == row
    assert set(outputs) == set(STAGES) and all(r['exit'] == '0\n' for r in outputs.values())
    result = audit.verify()
    assert result == audit.read('review.json') == json.loads(outputs['saved-audit']['stdout'])
    assert 'knowledge-map: OK' in outputs['knowledge-check']['stdout'] + outputs['knowledge-check']['stderr']
    assert 'test-subprocess-policy-adapters\tdocs/knowledge/test-subprocess-policy-adapters.md' in outputs['knowledge-query']['stdout']
    assert REVISION in outputs['pickaxe']['stdout']
    book, claims = audit.read('book-review.json'), audit.read('claim-review.json')
    assert len(book['checked_passages']) == 6 and len(book['checked_runtime_passages']) == 2
    assert book['same_volume_direct_objects'] and book['exact_output_absent']
    assert not (ROOT / book['output']).exists()
    assert claims['candidate_identities_and_semantics_unchanged'] and claims['dispositions_unchanged']
    metrics = audit.read('book-metrics.json')
    assert claims['book_baseline'] == metrics['baseline'] == dict(files=64, lines_total=62270, bytes_total=3418959)
    assert claims['book_delta'] == metrics['delta'] == dict(files=0, lines_total=10, bytes_total=667)
    card = 'docs/knowledge/test-subprocess-policy-adapters.md'
    before, after = old(card).decode(), (ROOT / card).read_text()
    questions = lambda text: re.findall(r'^  - ".*"$', text, re.M)
    assert questions(before) == questions(after) and len(questions(after)) == 123
    assert len(after.encode()) <= len(before.encode()) and after.count('\n') == before.count('\n')
    assert REVISION + ':' + card in after and str(BASE.relative_to(ROOT)) + '/audit.py --verify-saved' in after
    prior = audit.read('prior-preservation.json')
    original = json.loads((ROOT / 'docs/audits/native-proxy-compiler-census-20260913/first-run-rejected.json').read_bytes())
    assert prior['records'] == [{k: row[k] for k in ['path', 'size_bytes', 'sha256']} for row in original['outputs']]
    assert prior['old_permit_unconsumed'] and prior['old_run_start_absent'] and prior['old_journal_absent']
    assert prior['old_output_members'] == sorted(['epoch-before.json', 'permit.json', 'runner.stdout', 'runner.stderr', 'runner.exit'])
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
    layout = audit.read('completion-layout.json')
    task = (ROOT / h['source_path']).read_bytes()
    for owner in layout['closed_owners']:
        assert admission.owner_status(task, owner) == 'Status: `done`'
    assert layout['closed_owners'][0] == audit.PLAN['execution_owner']
    assert admission.owner_status(task, layout['next_owner']) == 'Status: `proposed`'
    assert task.count(b'\n') == 6370
    return dict(owner=audit.PLAN['execution_owner'], next_owner=layout['next_owner'],
                admission_revision=REVISION, result=result, book=book,
                claims=audit.pin(BASE / 'claim-review.json'), previous_acceptance=h,
                raw_outputs=outputs, compiler_profile_parents_complete=True,
                wrapper_profile_join_pending=True, native_live_startup_qualification_open=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--retain', action='store_true')
    group.add_argument('--verify-saved', action='store_true')
    args = parser.parse_args()
    if args.retain:
        outputs = {stage: {ext: (LOG / (stage + '.' + ext)).read_text()
                           for ext in ['stdout', 'stderr', 'exit']} for stage in STAGES}
        admission.save(BASE / 'completion.json', check(outputs))
    else:
        saved = audit.read('completion.json')
        assert check(saved['raw_outputs']) == saved
    print('Actual compiler profiles and exact cleanup: OK; wrapper/profile join remains proposed.')

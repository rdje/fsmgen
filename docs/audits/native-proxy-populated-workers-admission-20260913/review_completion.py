"""Close the source inventory and diagnosis, keeping controller repair open."""
import argparse
import hashlib
import json
import re

import audit

BASE, ROOT, REVISION = audit.BASE, audit.ROOT, audit.REVISION
LOG = ROOT / '.artifacts/logs' / BASE.name
STAGES = ['inventory-audit', 'book', 'book-inspection', 'knowledge-generate', 'knowledge-check',
          'knowledge-query', 'pickaxe', 'claims-write', 'claims-check', 'claims-review']


def status(task, owner):
    marker = '- ID: `' + owner + '`\n'
    assert task.count(marker) == 1
    return task.split(marker, 1)[1].splitlines()[0].strip()


def check(outputs):
    for row in audit.read('completion-pins.json'):
        assert audit.pin(ROOT / row['path']) == row
    assert set(outputs) == set(STAGES) and all(r['exit'] == '0\n' for r in outputs.values())
    result = audit.verify()
    assert result == audit.read('review.json') == json.loads(outputs['inventory-audit']['stdout'])
    assert 'knowledge-map: OK' in outputs['knowledge-check']['stdout'] + outputs['knowledge-check']['stderr']
    assert 'test-subprocess-policy-adapters\tdocs/knowledge/test-subprocess-policy-adapters.md' in outputs['knowledge-query']['stdout']
    assert audit.SCOPE['original_empty_store_admission'] in outputs['pickaxe']['stdout']
    book, claims = audit.read('book-review.json'), audit.read('claim-review.json')
    assert len(book['checked_passages']) == 6 and len(book['checked_runtime_passages']) == 2
    assert book['same_volume_direct_objects'] and book['exact_output_absent']
    assert not (ROOT / book['output']).exists()
    assert claims['candidate_identities_and_semantics_unchanged'] and claims['dispositions_unchanged']
    metrics = audit.read('book-metrics.json')
    assert claims['book_baseline'] == metrics['baseline'] == dict(files=64, lines_total=62286, bytes_total=3419888)
    assert claims['book_delta'] == metrics['delta'] == dict(files=0, lines_total=16, bytes_total=1077)
    card = 'docs/knowledge/test-subprocess-policy-adapters.md'
    before, after = audit.old(card).decode(), (ROOT / card).read_text()
    questions = lambda text: re.findall(r'^  - ".*"$', text, re.M)
    previous, current = questions(before), questions(after)
    assert [q for q in current if q in previous] == previous and len(previous) == 123 and len(current) == 124
    assert set(current) - set(previous) == {'  - "why can terminal worker recovery fail before native admission?"'}
    folded = lambda text: ' '.join(text.split('evidence: >-\n', 1)[1].split('reverify:', 1)[0].split())
    assert folded(before) == folded(after)
    assert len(after.encode()) <= len(before.encode()) and after.count('\n') == before.count('\n')
    assert REVISION + ':' + card in after and str(BASE.relative_to(ROOT)) + '/audit.py --verify-saved' in after
    history = ROOT / 'docs/tasks/history/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE/acceptance-history.jsonl'
    rows = [json.loads(line) for line in history.read_bytes().splitlines()]
    assert len(rows) == 2
    h = rows[1]
    source = audit.old(h['source_path'])
    suffix = source[source.rfind(b'## Acceptance Checklist'):]
    assert h['source_revision'] == REVISION and h['source_sha256'] == hashlib.sha256(source).hexdigest()
    assert h['source_bytes'] == len(source) and h['source_lines'] == source.count(b'\n')
    assert h['history_sha256'] == hashlib.sha256(suffix).hexdigest()
    assert h['history_bytes'] == len(suffix) and h['history_lines'] == suffix.count(b'\n') == 5
    task = (ROOT / h['source_path']).read_text()
    assert status(task, audit.SCOPE['owner']) == 'Status: `done`'
    assert status(task, audit.SCOPE['admission_parent']) == 'Status: `active`'
    for owner in ['controller_owner', 'worker_owner', 'final_admission_owner', 'execution_owner', 'join_owner']:
        assert status(task, audit.SCOPE[owner]) == 'Status: `proposed`'
    assert task.count('\n') == 6370
    assert audit.read('recovery-finding.json')['status'] == 'reproduced; repair required before populated-worker admission'
    return dict(owner=audit.SCOPE['owner'], next_owner=audit.SCOPE['controller_owner'],
                source_revision=REVISION, result=result, book=book,
                claims=audit.pin(BASE / 'claim-review.json'), previous_acceptance=h,
                raw_outputs=outputs, inventory_complete=True, recovery_defect_fixed=False,
                operational_admission_qualified=False, native_live_startup_qualification_open=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--retain', action='store_true')
    group.add_argument('--verify-saved', action='store_true')
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
    print('Populated-worker source inventory: OK; reproduced controller recovery repair remains next.')

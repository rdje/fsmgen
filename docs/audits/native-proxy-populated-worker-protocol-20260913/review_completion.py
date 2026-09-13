"""Join this completed source slice with exact outcomes and synchronized documentation."""
import argparse
import hashlib
import json
import re

import audit

BASE, ROOT, REVISION = audit.BASE, audit.ROOT, audit.REVISION
LOG = ROOT / '.artifacts/logs' / BASE.name
STAGES = ['syntax-protocol-first', 'syntax-worker-first', 'syntax-worker-final',
          'protocol-audit-first', 'protocol-audit', 'book', 'book-inspection',
          'knowledge-generate', 'knowledge-check', 'knowledge-query', 'knowledge-wrapper-query',
          'containment-check', 'pickaxe', 'claims-write', 'claims-check', 'claims-review']


def check(outputs):
    for row in audit.read('completion-pins.json'):
        assert audit.pin(ROOT / row['path']) == row
    assert set(outputs) == set(STAGES)
    for name, row in outputs.items():
        assert row['exit'] == ('1\n' if name == 'protocol-audit-first' else '0\n')
    first = audit.read('audit-first.json')
    assert first['outputs'] == outputs['protocol-audit-first']
    assert hashlib.sha256((BASE / 'audit.py.first.source').read_bytes()).hexdigest() == first['source_sha256']
    assert (BASE / 'audit.py.first.source').read_text().replace(
        '["$workspace/rust-tool-resolution", 0700, 65_536]',
        '["$workspace->{path}/rust-tool-resolution", 0700, 65_536]') == (BASE / 'audit.py').read_text()
    assert 'syntax OK' in outputs['syntax-worker-final']['stderr']
    assert 'knowledge-map: OK' in outputs['knowledge-check']['stdout'] + outputs['knowledge-check']['stderr']
    for name in ['knowledge-query', 'knowledge-wrapper-query']:
        assert 'test-subprocess-policy-adapters\tdocs/knowledge/test-subprocess-policy-adapters.md' in outputs[name]['stdout']
    assert '6081e5815b5aa80b1f3f78b43dc4ab0be1688ed6' in outputs['pickaxe']['stdout']
    assert 'all live-document size-containment invariants hold' in outputs['containment-check']['stdout']
    result = audit.verify()
    assert result == audit.read('review.json') == json.loads(outputs['protocol-audit']['stdout'])
    book = audit.read('book-review.json')
    assert json.loads(outputs['book-inspection']['stdout']) == book
    assert book['same_volume_direct_objects'] and book['exact_output_absent']
    assert len(book['checked_passages']) == 6 and len(book['checked_runtime_passages']) == 2
    assert not (ROOT / book['output']).exists()
    claims, metrics = audit.read('claim-review.json'), audit.read('book-metrics.json')
    assert claims['candidate_identities_and_semantics_unchanged'] and claims['dispositions_unchanged']
    assert claims['book_baseline'] == metrics['baseline'] == dict(files=64, lines_total=62314, bytes_total=3421723)
    assert claims['book_delta'] == metrics['delta'] == dict(files=0, lines_total=39, bytes_total=2543)
    route = audit.read('knowledge-route.json')
    before, after = audit.old(route['source_path']), (ROOT / route['source_path']).read_bytes()
    assert hashlib.sha256(before).hexdigest() == route['previous_sha256']
    assert hashlib.sha256(after).hexdigest() == route['current_sha256']
    questions = lambda value: re.findall(rb'^  - ".*"$', value, re.M)
    assert questions(after)[:125] == questions(before) and len(questions(after)) == 127
    assert len(after) < len(before) and after.count(b'\n') <= before.count(b'\n')
    assert (REVISION + ':' + route['source_path']).encode() in after
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
    status = lambda owner: task.split('- ID: `' + owner + '`\n', 1)[1].splitlines()[0].strip()
    assert status(audit.SCOPE['owner']) == 'Status: `done`'
    assert status(audit.SCOPE['next_owner']) == 'Status: `proposed`'
    assert status(audit.SCOPE['owner'].rsplit('.', 1)[0]) == 'Status: `active`'
    assert status(audit.read('observation-wrapper-gap.json')['repair_owner']) == 'Status: `proposed`'
    assert task.count('\n') == 6370
    old_text = source.decode()
    assert old_text[old_text.index('## Acceptance Checklist'):old_text.rfind('## Acceptance Checklist')] == task[task.index('## Acceptance Checklist'):task.rfind('## Acceptance Checklist')]
    return dict(owner=audit.SCOPE['owner'], next_owner=audit.SCOPE['next_owner'], source_revision=REVISION,
                result=result, book=book, claims=audit.pin(BASE / 'claim-review.json'), previous_acceptance=h,
                raw_outputs=outputs, fixed_protocol_complete=True, actual_worker_execution=False,
                final_execution_admission_open=True, native_live_startup_qualification_open=True)


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
    print('Fixed populated-worker protocol: OK; final one-use admission and actual workers remain open.')

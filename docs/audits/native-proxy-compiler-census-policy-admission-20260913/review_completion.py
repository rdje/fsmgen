"""Join this source-only repair to its checked documentation and durable evidence."""
import argparse
import hashlib
import json
import re

import admission
import audit

BASE, ROOT, PLAN = admission.BASE, admission.ROOT, admission.PLAN
LOG = ROOT / '.artifacts/logs' / BASE.name
REVISION = PLAN['source_revision']
STAGES = ['source-audit', 'knowledge-generate', 'knowledge-check', 'knowledge-query',
          'pickaxe', 'book', 'book-inspection', 'claims-write', 'claims-check', 'claims-review']


def read(name):
    return json.loads((BASE / name).read_bytes())


def old(path):
    return admission.git('show', REVISION + ':' + path)


def check(outputs):
    for row in read('completion-pins.json'):
        assert audit.pin(ROOT / row['path']) == row
    assert set(outputs) == set(STAGES)
    assert all(row['exit'] == '0\n' for row in outputs.values())
    result = audit.verify()
    assert result == read('review.json') == json.loads(outputs['source-audit']['stdout'])
    assert 'knowledge-map: OK' in outputs['knowledge-check']['stdout'] + outputs['knowledge-check']['stderr']
    assert 'test-subprocess-policy-adapters\tdocs/knowledge/test-subprocess-policy-adapters.md' in outputs['knowledge-query']['stdout']
    assert '143aafbc05ae5e15e41c4a5cccfefb3142f298d7' in outputs['pickaxe']['stdout']
    book, claims = read('book-review.json'), read('claim-review.json')
    assert len(book['checked_passages']) == 6 and len(book['checked_runtime_passages']) == 2
    assert book['same_volume_direct_objects'] and book['exact_output_absent']
    assert not (ROOT / book['output']).exists()
    assert claims['candidate_identities_and_semantics_unchanged'] and claims['dispositions_unchanged']
    metrics = read('book-metrics.json')
    assert claims['book_baseline'] == metrics['baseline'] == dict(files=64, lines_total=62260, bytes_total=3418256)
    assert claims['book_delta'] == metrics['delta'] == dict(files=0, lines_total=10, bytes_total=703)
    handoff = read('procedure-handoff.json')
    assert hashlib.sha256(old(handoff['source_path'])).hexdigest() == handoff['source_sha256']
    assert not (ROOT / handoff['source_path']).exists() and (ROOT / handoff['destination']).is_file()
    card = 'docs/knowledge/test-subprocess-policy-adapters.md'
    previous, current = old(card).decode(), (ROOT / card).read_text()
    questions = lambda text: re.findall(r'^  - ".*"$', text, re.M)
    before, after = questions(previous), questions(current)
    assert [q for q in after if q in before] == before and len(before) == 122 and len(after) == 123
    assert set(after) - set(before) == {'  - "why can guarded stdin Python exit successfully without running its program?"'}
    folded = lambda text: ' '.join(text.split('evidence: >-\n', 1)[1].split('reverify:', 1)[0].split())
    assert folded(previous) == folded(current)
    assert len(current.encode()) <= len(previous.encode()) and current.count('\n') == previous.count('\n')
    assert REVISION + ':' + card in current and str(BASE.relative_to(ROOT)) + '/audit.py --verify-saved' in current
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
    task = (ROOT / h['source_path']).read_bytes()
    assert admission.owner_status(task, PLAN['owner']) == 'Status: `done`'
    assert admission.owner_status(task, PLAN['execution_owner']) == 'Status: `proposed`'
    assert task.count(b'\n') == 6370
    return dict(owner=PLAN['owner'], next_owner=PLAN['execution_owner'], source_revision=REVISION,
                result=result, book=book, claims=audit.pin(BASE / 'claim-review.json'),
                previous_acceptance=h, raw_outputs=outputs,
                claim_legs=dict(rederive='Exact source pins, retained actual Git views and installed-input capture.',
                                falsify='Original ambient request and altered Git/path/profile controls.',
                                durability='Tracked sources, first outcomes, qualification, task, book and claim review in this commit.'),
                compiler_execution_pending=True)


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
        saved = read('completion.json')
        assert check(saved['raw_outputs']) == saved
    print('Local Git policy and fresh compiler source admission: OK; execution remains proposed.')

"""Join source admission, original failures, documentation and durable outputs."""
from __future__ import annotations

import argparse
import hashlib
import os
import re
import stat
import subprocess

from support import BASE, ROOT, LOG, authenticate, document, pin, write
import audit

STAGES = ('final-admission', 'saved-audit', 'audit-data-diagnostic', 'book', 'book-inspection',
          'claims-write', 'claims-check', 'claims-review', 'knowledge-generate', 'knowledge-check', 'pickaxe')


def raw(row):
    value = bytes.fromhex(row.get('bytes_hex', row.get('raw_hex', '')))
    assert len(value) == row['size_bytes'] and hashlib.sha256(value).hexdigest() == row['sha256']
    return value


def absent(relative):
    path = ROOT; device = ROOT.stat().st_dev
    for component in relative.split('/'):
        assert component not in ('', '.', '..')
        path /= component
        try: metadata = os.lstat(path)
        except FileNotFoundError: return True
        assert stat.S_ISDIR(metadata.st_mode) and metadata.st_dev == device and metadata.st_uid == os.getuid()
    return False


def verify(rows):
    plan = document(BASE / 'plan.json')
    authenticate(plan, document(BASE / 'preflight-pins.json'))
    for item in document(BASE / 'completion-pins.json') + document(BASE / 'documentation-pins.json'):
        assert pin(item['path']) == item
    current = audit.verify(plan); review = document(BASE / 'review.json')
    audit.raw_checks(review['raw_captures'])
    assert current == {key: value for key, value in review.items() if key != 'raw_captures'}
    outputs = {row['path'].rsplit('/', 1)[1]: raw(row) for row in rows}
    assert len(outputs) == len(rows) == len(STAGES) * 3
    for stage in STAGES: assert outputs[stage + '.exit'] == b'0\n'
    assert b'knowledge-map: OK' in outputs['knowledge-check.stdout'] + outputs['knowledge-check.stderr']
    assert outputs['pickaxe.stdout'].startswith(b'0982590d6ef9b6f937ffa8752912e33eb52152b8 ')
    for stage in ('final-admission', 'saved-audit'):
        assert b'lifetime source admission: OK; cases=8 prefixes=64 stages=152 actual_fixture_execution=0' in outputs[stage + '.stdout']
    first = document(BASE / 'first-syntax/result.json'); assert first['exit_code'] == 0
    for row in first['outputs']: raw(row)
    for row in document(BASE / 'first-syntax/inputs.json')['sources']:
        body = (ROOT / row['retained_path']).read_bytes()
        assert len(body) == row['size_bytes'] and hashlib.sha256(body).hexdigest() == row['sha256']
    history = document_lines(ROOT / 'docs/tasks/history/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE/acceptance-history.jsonl')[1]
    old = subprocess.check_output(['git', 'show', history['source_revision'] + ':' + history['source_path']], cwd=ROOT)
    assert history['source_revision'] == plan['source_revision']
    assert hashlib.sha256(old).hexdigest() == history['source_sha256'] and len(old) == history['source_bytes']
    assert old.count(b'\n') == history['source_lines']
    suffix = old[old.rfind(b'## Acceptance Checklist'):]
    assert hashlib.sha256(suffix).hexdigest() == history['history_sha256']
    assert len(suffix) == history['history_bytes'] and suffix.count(b'\n') == history['history_lines'] == 5
    assert len(document_lines(ROOT / 'docs/tasks/history/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE/acceptance-history.jsonl')) == 2
    card = 'docs/knowledge/test-subprocess-policy-adapters.md'
    prior = subprocess.check_output(['git', 'show', plan['source_revision'] + ':' + card], cwd=ROOT).decode()
    present = (ROOT / card).read_text()
    questions = lambda text: re.findall(r'^  - ".*"$', text, re.M)
    assert questions(prior) == questions(present) and len(questions(present)) == 117
    assert plan['source_revision'] + ':' + card in present
    book = document(BASE / 'book-review.json'); assert book['exit_code'] == 0 and book['exact_output_absent']
    assert absent(book['output'])
    claims = document(BASE / 'claim-review.json')
    assert claims['candidate_identities_and_semantics_unchanged'] and claims['dispositions_unchanged']
    assert claims['shifted_candidates'] == []
    for row in claims['raw_outputs']: raw(row)
    assert claims['book_baseline'] == dict(files=64, lines_total=61941, bytes_total=3397894)
    assert claims['book_delta'] == dict(files=0, lines_total=27, bytes_total=1609)
    selection = document(BASE / 'selection.json')
    roots = sorted(path for case in selection['cases'] for path in case['roots'].values())
    synthetic = sorted({path for context in document(BASE / 'prepared.json')['contexts'].values() for path in context['roots']})
    assert not set(roots) & set(synthetic) and len(roots) == 32 and len(synthetic) == 4
    assert all(absent(path) for path in roots + synthetic)
    return dict(schema='fsmgen.inactive_lifetime_files_admission_completion.v1', owner=plan['owner'],
        source_revision=plan['source_revision'], source_review=pin(BASE / 'review.json'),
        preflight_sources=len(document(BASE / 'preflight-pins.json')), book=book, claims=pin(BASE / 'claim-review.json'),
        unchanged_questions=117, historical_acceptance=history, prospective_roots_absent=roots,
        synthetic_roots_never_allocated=synthetic, raw_capture_count=len(rows),
        actual_fixture_execution=False, runtime_qualification=False)


def document_lines(path):
    import json
    return [json.loads(line) for line in path.read_bytes().splitlines()]


def main():
    parser = argparse.ArgumentParser(); group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--retain', action='store_true'); group.add_argument('--verify-saved', action='store_true')
    args = parser.parse_args()
    if args.retain:
        rows = []
        for stage in STAGES:
            for suffix in ('stdout', 'stderr', 'exit'):
                path = LOG / (stage + '.' + suffix)
                rows.append(dict(pin(path), bytes_hex=path.read_bytes().hex()))
        result = verify(rows); result['raw_captures'] = rows; write(BASE / 'completion.json', result)
    else:
        saved = document(BASE / 'completion.json'); result = verify(saved['raw_captures'])
        assert result == {key: value for key, value in saved.items() if key != 'raw_captures'}
    print('lifetime admission completion: OK; durable outputs=%d; fixture roots remain unallocated' % result['raw_capture_count'])


if __name__ == '__main__':
    main()

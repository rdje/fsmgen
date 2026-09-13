"""Authenticate the completed checks and durable bytes without replaying tests."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs/native-proxy-lifetime-files-20260913'
STAGES = ('capture', 'audit', 'saved-audit', 'book', 'book-inspection', 'claims-write',
          'claims-check', 'claims-review', 'knowledge-generate', 'knowledge-check', 'pickaxe')


def document(path):
    return json.loads(path.read_bytes())


def pin(path):
    raw = path.read_bytes()
    return dict(path=str(path.relative_to(ROOT)), size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def raw(row):
    value = bytes.fromhex(row['raw_hex'])
    assert len(value) == row['size_bytes'] and hashlib.sha256(value).hexdigest() == row['sha256']
    return value


def absent(relative):
    path = ROOT
    for component in relative.split('/'):
        assert component not in ('', '.', '..')
        path /= component
        try: metadata = os.lstat(path)
        except FileNotFoundError: return True
        assert stat.S_ISDIR(metadata.st_mode) and metadata.st_dev == ROOT.stat().st_dev and metadata.st_uid == os.getuid()
    return False


def verify(outputs):
    for name in ('completion-pins.json', 'documentation-pins.json', 'audit-pins.json'):
        for row in document(BASE / name): assert pin(ROOT / row['path']) == row
    plan = document(BASE / 'capture-plan.json'); report = document(BASE / 'review.json')
    captured = document(BASE / 'capture.json')
    assert report['admission_commit'] == plan['admission_commit'] == captured['admission_commit']
    assert report['owner'] == plan['owner'] == captured['owner']
    assert report['capture'] == pin(BASE / 'capture.json')
    copies = captured['records'] + captured['first_outputs'] + [captured['execution_admission'], captured['task_at_execution']]
    for row in copies:
        assert pin(ROOT / row['retained']['path']) == row['retained']
        assert all(row['source'][key] == row['retained'][key] for key in ('size_bytes', 'sha256'))
    assert len(captured['records']) == captured['record_count'] == report['journal_records'] == 250
    assert sum(row['retained']['size_bytes'] for row in captured['records']) == captured['record_bytes'] == report['record_bytes']
    assert captured['first_exit'] == 0 and captured['original_outputs_deleted'] is False
    assert len(report['cases']) == 8 and report['stages'] == sum(row['stages'] for row in report['cases']) == 152
    assert report['prefixes'] == sum(row['prefixes'] for row in report['cases']) == 56
    assert report['primary_handles'] == report['file_handles'] + report['directory_handles'] == 19820
    assert report['metadata_observers'] == report['directory_handles'] == 8184
    assert report['native_file_observation_traces'] == report['stages'] * 3 + len(report['cases']) == 464
    assert report['separate_recoveries'] == 0
    assert report['runtime_qualification'] is report['native_process_authentication'] is False
    assert report['original_harness_replayed'] is False and report['journal_unchanged_by_auditor'] is True
    assert report['falsifiers'] == ['omitted_record', 'open_descriptor', 'global_before_private',
        'archive_identity', 'unsettled_work', 'native_authority', 'hold_reappears']
    roots = sorted(path for case in report['cases'] for path in case['roots'])
    assert roots == report['roots_absent'] and len(roots) == len(set(roots)) == 32
    assert all(absent(path) for path in roots)
    values = {row['path'].rsplit('/', 1)[1]: raw(row) for row in outputs}
    assert len(values) == len(outputs) == len(STAGES) * 3
    for stage in STAGES: assert values[stage + '.exit'] == b'0\n'
    assert b'knowledge-map: OK' in values['knowledge-check.stdout'] + values['knowledge-check.stderr']
    assert values['pickaxe.stdout'].startswith(b'0982590d6ef9b6f937ffa8752912e33eb52152b8 ')
    for stage in ('audit', 'saved-audit'):
        assert b'actual inert lifetimes: OK; cases=8 stages=152 handles=19820 roots_absent=32 native_payload_execution=0' in values[stage + '.stdout']
    book = document(BASE / 'book-review.json'); assert book['exit_code'] == 0 and book['exact_output_absent']
    assert absent(book['output'])
    claims = document(BASE / 'claim-review.json')
    assert claims['candidate_identities_and_semantics_unchanged'] and claims['dispositions_unchanged']
    assert claims['book_baseline'] == dict(files=64, lines_total=61968, bytes_total=3399503)
    assert claims['book_delta'] == dict(files=0, lines_total=30, bytes_total=1737)
    for row in claims['raw_outputs']: raw(row)
    card = 'docs/knowledge/test-subprocess-policy-adapters.md'
    prior = subprocess.check_output(['git', 'show', plan['admission_commit'] + ':' + card], cwd=ROOT).decode()
    present = (ROOT / card).read_text()
    questions = lambda text: re.findall(r'^  - ".*"$', text, re.M)
    assert questions(prior) == questions(present) and len(questions(present)) == 117
    assert plan['admission_commit'] + ':' + card in present
    history_rows = [json.loads(line) for line in (ROOT / 'docs/tasks/history/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE/acceptance-history.jsonl').read_bytes().splitlines()]
    assert len(history_rows) == 2
    history = history_rows[1]; assert history['source_revision'] == plan['admission_commit']
    old = subprocess.check_output(['git', 'show', history['source_revision'] + ':' + history['source_path']], cwd=ROOT)
    assert hashlib.sha256(old).hexdigest() == history['source_sha256'] and len(old) == history['source_bytes']
    assert old.count(b'\n') == history['source_lines']
    suffix = old[old.rfind(b'## Acceptance Checklist'):]
    assert hashlib.sha256(suffix).hexdigest() == history['history_sha256']
    assert len(suffix) == history['history_bytes'] and suffix.count(b'\n') == history['history_lines'] == 5
    return dict(schema='fsmgen.inactive_lifetime_actual_files_completion.v1', owner=plan['owner'],
        admission_commit=plan['admission_commit'], qualified_report=pin(BASE / 'review.json'),
        exact_retained_objects=len(copies), first_journal_bytes=report['record_bytes'],
        raw_output_count=len(outputs), book=book, claims=pin(BASE / 'claim-review.json'),
        unchanged_questions=117, prior_acceptance=history, roots_absent=roots,
        no_harness_replay=True, interruption_qualification=False, native_live_qualification=False)


def main():
    parser = argparse.ArgumentParser(); group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--retain', action='store_true'); group.add_argument('--verify-saved', action='store_true')
    args = parser.parse_args()
    if args.retain:
        outputs = []
        for stage in STAGES:
            for suffix in ('stdout', 'stderr', 'exit'):
                path = LOG / (stage + '.' + suffix)
                outputs.append(dict(pin(path), raw_hex=path.read_bytes().hex()))
        result = verify(outputs); result['raw_outputs'] = outputs
        with (BASE / 'completion.json').open('xb') as handle:
            handle.write(json.dumps(result, sort_keys=True, indent=2).encode() + b'\n')
    else:
        saved = document(BASE / 'completion.json'); result = verify(saved['raw_outputs'])
        assert result == {key: value for key, value in saved.items() if key != 'raw_outputs'}
    print('actual lifetime completion: OK; retained objects=%d raw outputs=%d roots_absent=%d' %
          (result['exact_retained_objects'], result['raw_output_count'], len(result['roots_absent'])))


if __name__ == '__main__':
    main()

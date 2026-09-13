"""Join the actual result, rendered scope and exact per-slice continuity."""

import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
ADMISSION_NAME = 'native-proxy-language-coordination-admission-20260913'
REVISION = '295130388c20c6ee94650c610c2df6d597eeffa7'
STAGES = {name: ADMISSION_NAME for name in ('actual-capture', 'actual-audit', 'actual-audit-saved')}
STAGES.update({name: BASE.name for name in (
    'book', 'book-inspection', 'claims-write', 'claims-check', 'claims-review',
    'knowledge-generate', 'knowledge-check', 'pickaxe',
)})


def read(path):
    return json.loads(path.read_bytes())


def pin(path):
    body = path.read_bytes()
    return dict(path=path.relative_to(ROOT).as_posix(), size_bytes=len(body),
                sha256=hashlib.sha256(body).hexdigest())


def git_bytes(path):
    return subprocess.check_output(['git', 'show', REVISION + ':' + path], cwd=ROOT)


def section(task, owner):
    marker = '- ID: `' + owner + '`\n'
    assert task.count(marker) == 1
    return task.split(marker)[1].split('- ID: `', 1)[0]


def verify(outputs):
    for row in read(BASE / 'completion-pins.json'):
        assert pin(ROOT / row['path']) == row
    values = {}
    for row in outputs:
        body = bytes.fromhex(row['bytes_hex'])
        assert len(body) == row['size_bytes'] and hashlib.sha256(body).hexdigest() == row['sha256']
        name = row['path'].rsplit('/', 1)[1]
        assert name not in values
        values[name] = body
    assert len(values) == len(STAGES) * 3
    for stage in STAGES:
        assert values[stage + '.exit'] == b'0\n'
    for stage in ('actual-audit', 'actual-audit-saved'):
        assert json.loads(values[stage + '.stdout']) == dict(cases=12, journal_records=472,
            original_producer_replayed=False, rejected_controls=10, success=True)
    assert json.loads(values['actual-capture.stdout']) == dict(fixture_roots_absent=14,
        groups_absent=20, journal_records=472, native_owners_absent=25,
        original_producer_replayed=False, retained_files=52)
    assert b'knowledge-map: OK' in values['knowledge-check.stdout'] + values['knowledge-check.stderr']
    assert values['pickaxe.stdout'].startswith(b'502006787cb326c8931b914b100a42d35c8f153b ')
    report = read(BASE / 'review.json')
    assert report['admission_commit'] == REVISION and report['source_inputs'] == 88
    assert report['retained_files'] == 52 and len(report['rejected_controls']) == 10
    assert report['result']['first_outcome_success'] and not report['result']['original_producer_replayed']
    assert report['native_live_integration_pending'] and not report['native_proxy_startup_cause_established']
    book = read(BASE / 'book-review.json')
    assert book['same_volume_direct_objects'] and book['exact_output_absent']
    assert len(book['checked_passages']) == 6 and len(book['checked_runtime_passages']) == 2
    assert not (ROOT / book['output']).exists()
    claims = read(BASE / 'claim-review.json')
    assert claims['candidate_identities_and_semantics_unchanged'] and claims['dispositions_unchanged']
    assert claims['book_baseline'] == dict(files=64, lines_total=62150, bytes_total=3410874)
    assert claims['book_delta'] == dict(files=0, lines_total=19, bytes_total=1315)
    card = 'docs/knowledge/test-subprocess-policy-adapters.md'
    current = (ROOT / card).read_text()
    questions = lambda text: re.findall(r'^  - ".*"$', text, re.M)
    assert questions(git_bytes(card).decode()) == questions(current)
    assert len(questions(current)) == 120 and REVISION + ':' + card in current
    assert BASE.relative_to(ROOT).as_posix() + '/audit.py --verify-saved' in current
    history_path = ROOT / 'docs/tasks/history/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE/acceptance-history.jsonl'
    history = [json.loads(line) for line in history_path.read_bytes().splitlines()]
    assert len(history) == 2
    history = history[1]
    assert history['source_revision'] == REVISION
    source = git_bytes(history['source_path'])
    suffix = source[source.rfind(b'## Acceptance Checklist'):]
    assert hashlib.sha256(source).hexdigest() == history['source_sha256']
    assert len(source) == history['source_bytes'] and source.count(b'\n') == history['source_lines']
    assert suffix.count(b'\n') == history['history_lines'] == 5
    assert hashlib.sha256(suffix).hexdigest() == history['history_sha256']
    assert len(suffix) == history['history_bytes']
    task = (ROOT / history['source_path']).read_text()
    owner = report['owner']
    parent = owner.rsplit('.', 1)[0]
    for identity in (owner, parent, parent + '.1'):
        assert 'Status: `done`' in section(task, identity)
    next_owner = parent.rsplit('.', 1)[0] + '.5'
    assert 'Status: `proposed`' in section(task, next_owner)
    return dict(schema='fsmgen.language_coordination_actual_completion.v1',
        owner=owner, closed_owners=[owner, parent], next_owner=next_owner,
        admission_commit=REVISION, qualified_report=pin(BASE / 'review.json'),
        book=book, claims=pin(BASE / 'claim-review.json'), previous_acceptance=history,
        unchanged_questions=120, raw_outputs=outputs, native_live_integration_pending=True)


def main():
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--retain', action='store_true')
    group.add_argument('--verify-saved', action='store_true')
    args = parser.parse_args()
    if args.retain:
        outputs = []
        for stage, folder in STAGES.items():
            for suffix in ('stdout', 'stderr', 'exit'):
                path = ROOT / '.artifacts/logs' / folder / (stage + '.' + suffix)
                outputs.append(dict(**pin(path), bytes_hex=path.read_bytes().hex()))
        result = verify(outputs)
        with (BASE / 'completion.json').open('x') as stream:
            json.dump(result, stream, sort_keys=True, indent=2)
            stream.write('\n')
    else:
        saved = read(BASE / 'completion.json')
        assert verify(saved['raw_outputs']) == saved
    print('Actual coordination completion: OK; inactive closure and native/live prerequisites follow.')


if __name__ == '__main__':
    main()

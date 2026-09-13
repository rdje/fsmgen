"""Join completed lifetime checks, current book state and exact continuity."""

import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
STAGES = (
    'closure', 'closure-saved', 'book', 'book-inspection', 'claims-write',
    'claims-check', 'claims-review', 'knowledge-generate', 'knowledge-check', 'pickaxe',
)


def read(path):
    return json.loads(path.read_bytes())


def pin(path):
    body = path.read_bytes()
    return dict(path=path.relative_to(ROOT).as_posix(), size_bytes=len(body),
                sha256=hashlib.sha256(body).hexdigest())


def raw(row):
    body = bytes.fromhex(row['bytes_hex'])
    assert len(body) == row['size_bytes']
    assert hashlib.sha256(body).hexdigest() == row['sha256']
    return body


def git_bytes(revision, path):
    return subprocess.check_output(['git', 'show', revision + ':' + path], cwd=ROOT)


def section(task, owner):
    marker = '- ID: `' + owner + '`\n'
    assert task.count(marker) == 1
    return task.split(marker)[1].split('- ID: `', 1)[0]


def verify(outputs):
    for name in ('documentation-pins.json', 'completion-pins.json'):
        for row in read(BASE / name):
            assert pin(ROOT / row['path']) == row
    values = {row['path'].rsplit('/', 1)[1]: raw(row) for row in outputs}
    assert len(values) == len(outputs) == len(STAGES) * 3
    for stage in STAGES:
        assert values[stage + '.exit'] == b'0\n'
    expected = dict(success=True, complete_file_cases=8, control_file_cases=14,
                    join_countermodels=9, modeled_orders=390,
                    new_fixture_operations=0, source_inputs=945)
    for stage in ('closure', 'closure-saved'):
        assert json.loads(values[stage + '.stdout']) == expected
    assert b'knowledge-map: OK' in values['knowledge-check.stdout'] + values['knowledge-check.stderr']
    assert values['pickaxe.stdout'].startswith(b'c3fefd0e419a4edd510093f9efd548e1052b064f ')

    plan = read(BASE / 'plan.json')
    report = read(BASE / 'review.json')
    assert report['owner'] == plan['owner']
    assert report['source_revision'] == plan['source_revision']
    assert report['source_inputs'] == len(plan['inputs']) == 945
    assert report['source_bytes'] == sum(row['size_bytes'] for row in plan['inputs']) == 110045666
    assert report['closure_criteria_satisfied']
    assert report['new_fixture_operations'] == 0
    assert report['no_original_producer_or_fixture_replayed']
    assert report['original_clock_domains_kept_separate']
    assert report['actual_process_coordination_pending']
    assert report['next_owner'] == plan['next_owner']
    assert report['native_integration_owner'] == plan['native_integration_owner']
    assert report['remaining_prerequisites'] == plan['missing_native_legs']
    assert report['native_process_authentication'] is report['live_store_authorized'] is False
    scope = report['applicability']
    assert scope['modeled_domain_exhausted'] and not scope['all_modeled_orders_executed_on_files']
    assert scope['modeled_serial_orders'] == 390 and scope['modeled_prefix_states'] == 3120
    assert scope['actual_complete_cases'] == 8 and scope['actual_control_cases'] == 14
    assert scope['actual_stages'] == 384 and scope['retained_journal_records'] == 601
    assert scope['retained_journal_bytes'] == 74571891
    assert len(scope['fixture_roots']) == len(set(scope['fixture_roots'])) == 88
    for relative in scope['fixture_roots']:
        path = ROOT / relative
        assert not path.exists() and not path.is_symlink()
    assert len(report['rejected_join_countermodels']) == 9

    book = read(BASE / 'book-review.json')
    assert book['same_volume_direct_objects'] and book['exact_output_absent']
    assert len(book['checked_passages']) == 5 and len(book['checked_runtime_passages']) == 4
    assert not (ROOT / book['output']).exists()
    claims = read(BASE / 'claim-review.json')
    assert claims['candidate_identities_and_semantics_unchanged'] and claims['dispositions_unchanged']
    assert claims['book_baseline'] == dict(files=64, lines_total=62097, bytes_total=3407332)
    assert claims['book_delta'] == dict(files=0, lines_total=23, bytes_total=1568)
    revision = plan['source_revision']
    card = 'docs/knowledge/test-subprocess-policy-adapters.md'
    old_card = git_bytes(revision, card).decode()
    current_card = (ROOT / card).read_text()
    questions = lambda text: re.findall(r'^  - ".*"$', text, re.M)
    assert questions(old_card) == questions(current_card) and len(questions(current_card)) == 117
    assert revision + ':' + card in current_card
    assert BASE.relative_to(ROOT).as_posix() + '/audit.py --verify-saved' in current_card

    history_path = ROOT / 'docs/tasks/history/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE/acceptance-history.jsonl'
    history = [json.loads(line) for line in history_path.read_bytes().splitlines()]
    assert len(history) == 2
    history = history[1]
    assert history['source_revision'] == revision
    source = git_bytes(revision, history['source_path'])
    suffix = source[source.rfind(b'## Acceptance Checklist'):]
    assert hashlib.sha256(source).hexdigest() == history['source_sha256']
    assert len(source) == history['source_bytes'] and source.count(b'\n') == history['source_lines']
    assert suffix.count(b'\n') == history['history_lines'] == 5
    assert hashlib.sha256(suffix).hexdigest() == history['history_sha256']
    assert len(suffix) == history['history_bytes']
    task = (ROOT / history['source_path']).read_text()
    closed = (plan['owner'], plan['parent'], plan['custody_parent'])
    for owner in closed:
        assert 'Status: `done`' in section(task, owner)
    for parent, count in ((plan['parent'], 5), (plan['custody_parent'], 6)):
        for child in range(1, count + 1):
            assert 'Status: `done`' in section(task, parent + '.' + str(child))
    for owner in (plan['next_owner'], plan['native_integration_owner']):
        assert 'Status: `proposed`' in section(task, owner)
    return dict(schema='fsmgen.inactive_lifetime_closure_completion.v1', owner=plan['owner'],
                source_revision=revision, qualified_report=pin(BASE / 'review.json'),
                closed_owners=list(closed), next_owner=plan['next_owner'], book=book,
                claims=pin(BASE / 'claim-review.json'), previous_acceptance=history,
                unchanged_questions=117, raw_output_count=len(outputs), raw_outputs=outputs,
                actual_process_coordination_pending=True, native_live_integration_pending=True)


def main():
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--retain', action='store_true')
    group.add_argument('--verify-saved', action='store_true')
    args = parser.parse_args()
    if args.retain:
        outputs = []
        for stage in STAGES:
            for suffix in ('stdout', 'stderr', 'exit'):
                path = ROOT / '.artifacts/logs' / BASE.name / (stage + '.' + suffix)
                outputs.append(dict(**pin(path), bytes_hex=path.read_bytes().hex()))
        result = verify(outputs)
        with (BASE / 'completion.json').open('x') as stream:
            json.dump(result, stream, sort_keys=True, indent=2)
            stream.write('\n')
    else:
        saved = read(BASE / 'completion.json')
        assert verify(saved['raw_outputs']) == saved
    print('Inactive lifetime closure completion: OK; actual language coordination follows.')


if __name__ == '__main__':
    main()

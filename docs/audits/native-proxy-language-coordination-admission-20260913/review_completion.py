"""Join source-only admission, rendered documentation and exact continuity."""

import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
STAGES = (
    'admission-audit', 'admission-saved', 'book', 'book-inspection',
    'claims-write-final', 'claims-check-final', 'claims-review-final', 'knowledge-generate-final',
    'knowledge-check-final', 'knowledge-query-final', 'pickaxe',
)


def read(path):
    return json.loads(path.read_bytes())


def pin(path):
    body = path.read_bytes()
    return dict(path=path.relative_to(ROOT).as_posix(), size_bytes=len(body),
                sha256=hashlib.sha256(body).hexdigest())


def git_bytes(revision, path):
    return subprocess.check_output(['git', 'show', revision + ':' + path], cwd=ROOT)


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
        assert len(body) == row['size_bytes']
        assert hashlib.sha256(body).hexdigest() == row['sha256']
        name = row['path'].rsplit('/', 1)[1]
        assert name not in values
        values[name] = body
    assert len(values) == len(STAGES) * 3
    for stage in STAGES:
        assert values[stage + '.exit'] == b'0\n'
    expected = dict(actual_worker_execution=False, event_controls=20,
                    identity_controls=12, permit_controls=16, prospective_cases=12)
    for stage in ('admission-audit', 'admission-saved'):
        assert json.loads(values[stage + '.stdout']) == expected
    assert b'knowledge-map: OK' in values['knowledge-check-final.stdout'] + values['knowledge-check-final.stderr']
    assert b'test-subprocess-policy-adapters\tdocs/knowledge/test-subprocess-policy-adapters.md' in values['knowledge-query-final.stdout']
    assert values['pickaxe.stdout'].startswith(b'502006787cb326c8931b914b100a42d35c8f153b ')

    plan = read(BASE / 'plan.json')
    report = read(BASE / 'review.json')
    assert report['owner'] == plan['owner']
    assert report['actual_worker_execution'] is report['actual_permit_issued'] is False
    assert report['native_proxy_startup_cause_established'] is False
    assert report['prospective_cases'] == len(plan['cases']) == 12
    assert report['prospective_workers'] == 20 and report['prospective_exec_probes'] == 4
    assert report['selected_source_inputs'] == len(plan['inputs']) == 10
    assert report['current_runtime_inputs'] == len(plan['runtime_pins']) == 21
    identity = report['native_image_repair']
    assert identity['original_rejection_reproduced'] and identity['read_only_current_python_native_match']
    assert identity['rejected_owned_worker_termination_qualified_with_mocked_signal']
    assert identity['actual_perl_worker_identity_pending']
    assert read(BASE / 'identity-disposition.json')['status'] == 'source_data_repair_qualified'

    book = read(BASE / 'book-review.json')
    assert book['same_volume_direct_objects'] and book['exact_output_absent']
    assert len(book['checked_passages']) == 6 and len(book['checked_runtime_passages']) == 2
    assert not (ROOT / book['output']).exists()
    claims = read(BASE / 'claim-review.json')
    assert claims['candidate_identities_and_semantics_unchanged'] and claims['dispositions_unchanged']
    assert claims['book_baseline'] == dict(files=64, lines_total=62120, bytes_total=3408900)
    assert claims['book_delta'] == dict(files=0, lines_total=30, bytes_total=1974)
    revision = plan['source_revision']
    card = 'docs/knowledge/test-subprocess-policy-adapters.md'
    current_card = (ROOT / card).read_text()
    questions = lambda text: re.findall(r'^  - ".*"$', text, re.M)
    prior_questions = questions(git_bytes(revision, card).decode())
    assert len(prior_questions) == 117 and questions(current_card)[:117] == prior_questions
    assert len(questions(current_card)) == 120
    assert revision + ':' + card in current_card
    assert BASE.relative_to(ROOT).as_posix() + '/audit.py --verify-saved' in current_card
    fact = ROOT / card
    first_fact = BASE / 'first-source/python-framework-native-image.md.documentation-first.source'
    assert questions(current_card)[117:] == questions(first_fact.read_text())
    epoch = read(BASE / 'documentation-first-epoch.json')
    for row in epoch['recovery']:
        recovered = (ROOT / row['recoverable_from']).read_bytes()
        assert len(recovered) == row['size_bytes']
        assert hashlib.sha256(recovered).hexdigest() == row['sha256']
    first_gate = read(BASE / 'staged-gate-first.json')
    assert first_gate['result'] == 'failed'
    exits = [bytes.fromhex(row['bytes_hex']) for row in first_gate['outputs'] if row['path'].endswith('.exit')]
    assert exits == [b'1\n']

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
    closed = [plan['owner'], plan['owner'] + '.1', plan['owner'] + '.2']
    for owner in closed:
        assert 'Status: `done`' in section(task, owner)
    assert 'Status: `active`' in section(task, plan['owner'].rsplit('.', 1)[0])
    assert 'Status: `proposed`' in section(task, plan['execution_owner'])
    return dict(schema='fsmgen.language_coordination_admission_completion.v1',
                owner=plan['owner'], source_revision=revision,
                qualified_report=pin(BASE / 'review.json'), closed_owners=closed,
                next_owner=plan['execution_owner'], book=book,
                claims=pin(BASE / 'claim-review.json'), previous_acceptance=history,
                preserved_questions=117, added_questions=3, canonical_card=pin(fact),
                first_documentation_gate_failure_preserved=True,
                raw_outputs=outputs, actual_worker_execution_pending=True,
                actual_permit_issued=False, native_live_integration_pending=True)


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
    print('Coordination source/data admission completion: OK; actual execution is pending.')


if __name__ == '__main__':
    main()

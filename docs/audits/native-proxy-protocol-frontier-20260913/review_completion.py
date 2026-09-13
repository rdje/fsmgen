"""Join the prerequisite audit, rendered scope and exact per-slice continuity."""

import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
REVISION = '2f144f7a18f9a4023b697c58cc5866480343d8c5'
STAGES = {name: BASE.name for name in (
    'audit', 'audit-saved', 'book', 'book-inspection', 'claims-write', 'claims-check',
    'claims-review', 'knowledge-generate', 'knowledge-check', 'knowledge-query', 'pickaxe',
)}


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
    for stage in ('audit', 'audit-saved'):
        assert json.loads(values[stage + '.stdout']) == dict(final_protocol_closure=False,
            indexed_contract_clauses=9, new_live_execution=False, rejected_controls=10,
            source_inputs=34, workspace_mode_mismatch=True)
    assert b'knowledge-map: OK' in values['knowledge-check.stdout'] + values['knowledge-check.stderr']
    assert b'test-subprocess-policy-adapters\tdocs/knowledge/test-subprocess-policy-adapters.md' in values['knowledge-query.stdout']
    assert values['pickaxe.stdout'].startswith(b'4bc8f5ebc48173a26fbec6a30a248b86df7eda71 ')
    report = read(BASE / 'review.json')
    assert report['source_revision'] == REVISION and report['source_inputs'] == 34
    assert report['source_bytes'] == 673891 and report['indexed_contract_clauses'] == 9
    assert len(report['rejected_controls']) == 10 and report['first_wrong_fixture_annotation_preserved']
    result = report['result']
    assert result['workspace_profile']['producer_mode'] == '0755'
    assert result['workspace_profile']['inert_wrapper_mode'] == '0700'
    assert result['workspace_profile']['producer_mode_rejected']
    assert result['new_live_execution'] is result['final_protocol_closure_established'] is False
    book = read(BASE / 'book-review.json')
    assert book['same_volume_direct_objects'] and book['exact_output_absent']
    assert len(book['checked_passages']) == 6 and len(book['checked_runtime_passages']) == 2
    assert not (ROOT / book['output']).exists()
    claims = read(BASE / 'claim-review.json')
    assert claims['candidate_identities_and_semantics_unchanged'] and claims['dispositions_unchanged']
    assert claims['book_baseline'] == dict(files=64, lines_total=62169, bytes_total=3412189)
    assert claims['book_delta'] == dict(files=0, lines_total=31, bytes_total=2026)
    card = 'docs/knowledge/test-subprocess-policy-adapters.md'
    current = (ROOT / card).read_text()
    questions = lambda text: re.findall(r'^  - ".*"$', text, re.M)
    assert questions(git_bytes(card).decode()) == questions(current)[:120]
    assert len(questions(current)) == 121 and REVISION + ':' + card in current
    assert questions(current)[-1] == '  - "why does inactive retirement reject the real Rust proxy wrapper?"'
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
    assert 'Status: `done`' in section(task, owner)
    assert 'Status: `active`' in section(task, parent)
    for identity in report['prerequisite_owners'].values():
        assert 'Status: `proposed`' in section(task, identity)
    next_owner = report['next_owner']
    assert 'Status: `proposed`' in section(task, next_owner)
    return dict(schema='fsmgen.native_proxy_protocol_frontier_completion.v1',
        owner=owner, closed_owners=[owner], next_owner=next_owner,
        source_revision=REVISION, qualified_report=pin(BASE / 'review.json'),
        book=book, claims=pin(BASE / 'claim-review.json'), previous_acceptance=history,
        preserved_questions=120, new_questions=1, raw_outputs=outputs,
        compatibility_fix_pending=True, native_live_integration_pending=True)



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
    print('Protocol frontier completion: OK; owned workspace compatibility fix is next.')


if __name__ == '__main__':
    main()

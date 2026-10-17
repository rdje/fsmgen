"""Verify the dated lossless documentation compaction, without freezing progress."""
from pathlib import Path
import base64
import copy
import gzip
import hashlib
import json
import re
import subprocess
import sys

AUDIT = Path('docs/audits/task-acceptance-index-observer-20261017')
TASK = 'docs/tasks/TASK-ACCEPTANCE-CHECKLIST-BODY-BOUNDARY.md'
BOOK = 'docs/book/src/16dc-vial-portable-verilator-runtime-measurement.md'
CARD = 'docs/knowledge/task-acceptance-portable-contract.md'


def body(row):
    value = base64.b64decode(row['body_base64'], validate=True)
    assert len(value) == row['bytes'] and hashlib.sha256(value).hexdigest() == row['sha256']
    return value.decode()


def nodes(text):
    matches = list(re.finditer(r'^- ID: `([^`]+)`$', text, re.M))
    return {match[1]: text[match.start():matches[i+1].start() if i+1 < len(matches) else text.index('\n## Decisions')]
            for i, match in enumerate(matches)}


def verify(record):
    before = {path: body(row) for path, row in record['before'].items()}
    after = {path: body(row) for path, row in record['after'].items()}
    baseline = {path: body(row) for path, row in record['baseline'].items()}
    def words(text):
        return text.replace('```sh\n', '').replace('`', '').split()
    assert words(before[BOOK]) == words(after[BOOK]), 'complete book text/command conservation'
    assert after[BOOK].count('\n') == baseline[BOOK].count('\n'), 'book line allowance'
    old_questions = re.findall(r'^  - (.+)$', baseline[CARD], re.M)
    questions = re.findall(r'^  - (.+)$', after[CARD], re.M)
    assert questions[:-1] == old_questions and len(questions) == len(set(questions)), 'ordered questions'
    for probe in ('neutral checker', 'path EREs and scoped families', 'change_paths.tsv',
                  'evidence_signatures.tsv', 'doctrine/task_acceptance/', 'fresh checked',
                  'ROOT CAUSE/ADDRESSED/NO REGRESSION', 'one staged task', 'box-scoped',
                  'every header must change in the staged diff', 'Other edits cannot reuse old boxes',
                  'presence/freshness/scope/shape in hooks/CI', 'tests establish truth',
                  'FSM::Test::TaskAcceptanceIndexRuntime', 'bounded fixed cases', "this repository's alternate index",
                  'T2068 checks native status/evidence/cleanup', 'T2070', 'audit_*', 'evidence/doc fixtures',
                  'declaration coverage separate', 'may refresh stat-cache, never staged entries',
                  'retain raw observations and exact native index bytes', '.py/.pl/.pm/.sh/.c/.t',
                  'docs/audits/', 'requires fresh evidence', 'doc neighbors are unclassified',
                  'Outdented siblings end boxes', 'tabs use four-column stops'):
        assert probe in after[CARD], 'reviewed prior proposition: ' + probe
    for path in (TASK, CARD):
        assert len(after[path].encode()) <= len(baseline[path].encode()), 'non-growing canonical bytes'
        assert after[path].count('\n') <= baseline[path].count('\n'), 'non-growing canonical lines'
    old_nodes, current = nodes(baseline[TASK]), nodes(after[TASK])
    assert set(old_nodes) == set(current), 'complete live node graph'
    checkpoint = 'TASK-ACCEPTANCE-CHECKLIST-BODY-BOUNDARY.1.1'
    terminal = current[checkpoint]
    assert 'Terminal: `version_object`' in terminal
    assert re.search(r'  Revision: `([^`]+)`', terminal)[1] == record['revision']
    assert re.search(r'  Retrieved SHA256: `([^`]+)`', terminal)[1] == hashlib.sha256(baseline[TASK].encode()).hexdigest()
    assert 'Archived node count: `1`' in terminal and 'Retention contract: `fsmgen_required_history`' in terminal
    for node_id, old in old_nodes.items():
        for field in ('Goal', 'Children', 'Acceptance'):
            if node_id == checkpoint and field == 'Acceptance':
                continue  # Complete original contract remains in the exact version object.
            assert re.findall(r'^  ' + field + r': (.+)$', old, re.M) == re.findall(
                r'^  ' + field + r': (.+)$', current[node_id], re.M), 'unchanged node contract'
    return True


if __name__ == '__main__':
    assert sys.argv[1:] in ([], ['--current'])
    record = json.loads(gzip.decompress((AUDIT / 'documentation-pressure-proof.json.gz').read_bytes()))
    verify(record)
    for path, row in record['baseline'].items():
        actual = subprocess.check_output(['git', 'show', record['revision'] + ':' + path], timeout=30)
        assert actual.decode() == body(row), 'exact baseline version retrieval'
    for mutation in ('book', 'question', 'proposition', 'terminal'):
        candidate = copy.deepcopy(record)
        path = {'book': BOOK, 'question': CARD, 'proposition': CARD, 'terminal': TASK}[mutation]
        value = body(candidate['after'][path])
        value = re.sub(r'^  - .+\n', '', value, count=1, flags=re.M) if mutation == 'question' else (
            value.replace('neutral checker', 'changed checker', 1) if mutation == 'proposition' else (
            value.replace('Land the verified lexical boundary checkpoint', 'Changed goal', 1)
            if mutation == 'terminal' else value.replace('The fixed index observer', 'Changed observer', 1)))
        raw = value.encode()
        candidate['after'][path] = dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest(),
                                      body_base64=base64.b64encode(raw).decode())
        try:
            verify(candidate)
        except AssertionError:
            continue
        raise AssertionError('loss control was accepted: ' + mutation)
    if sys.argv[1:]:
        for path, row in record['after'].items():
            assert Path(path).read_text() == body(row), 'current capture epoch changed'
    print('Complete book text, ordered questions, prior propositions and exact checkpoint history retain.')

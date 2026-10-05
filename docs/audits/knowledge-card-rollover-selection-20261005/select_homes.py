"""Make the reviewed question-to-information-role map explicit."""
import json
import re
from pathlib import Path

BASE = Path('docs/audits/knowledge-card-rollover-selection-20261005')
ROOT = 'LIVE_DOCUMENT_SIZE_CONTAINMENT.md'
ADOPTION = 'docs/tasks/LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.md'
GROUPS = [
    ([0, 3], 'Bounded live views', ROOT, 'current'),
    ([1, 16, 21], 'Health targets', ROOT, 'current milestones and ceilings supersede legacy hard_pct'),
    ([2], 'Decisions 0046-0049', 'COMMIT.md', 'current authority and retained chronology'),
    ([4, 33, 34, 35], 'Migration evidence', ROOT, 'current'),
    ([5, 6], 'project- and harness-neutral', ROOT, 'current'),
    ([7, 8, 10, 15, 19], 'The bounded JSONL control plane', ROOT, 'current'),
    ([9, 12, 17, 18, 20], 'Detailed adoption outcomes', ADOPTION, 'dated outcome or design rationale retained complete'),
    ([11, 23], 'Current task', 'docs/TASK_TREE.md', 'derive current ownership and lifecycle; retain prior observations'),
    ([13, 14], 'Utility review precedes', ADOPTION, 'current utility procedure and dated retirement candidates'),
    ([22], '[[live-document-surface-growth-procedure]]', 'docs/knowledge/live-document-surface-growth-procedure.md', 'current'),
    ([24, 25], 'Declared `core:`', 'scripts/run_live_document_adapter_verifiers.pl', 'current executed-verifier contract and doctrine-driver reachability'),
    ([26, 27, 28], 'Currency is', ROOT, 'current'),
    ([29, 30, 31, 32], 'Author-overflow', ROOT, 'current'),
    ([36], 'bounded review front door', 'docs/LIVE_DOCUMENT_SIZE_CONTAINMENT_AUDIT.md', 'current front door and retained full packet'),
    ([37], '`maintained_reference`', 'docs/decisions/0045-maintained-reference-bounds-the-read-path-not-product-scope.md', 'current decision authority through public record reader'),
    ([38], 'Rolling ledgers', 'doctrine/live_document_size/ledger_manifests.jsonl', 'current'),
    ([39, 40, 41, 42], 'The Knowledge Map keeps', 'knowledge-map/KNOWLEDGE_MAP_ARCHITECTURE.md', 'current'),
    ([43], '`docs/index/FOCUSED_DOCUMENTS.md`', 'docs/index/FOCUSED_DOCUMENTS.md', 'current'),
    ([44, 45], 'T1569 checks current structure', 'doctrine/live_document_size/isf_reference_partitions.jsonl', 'current structure and separately retained activation/failure'),
    ([46, 47, 48, 49], 'Decision `0054`', 'doctrine/live_document_size/derived_state_contracts.jsonl', 'current'),
    ([50], 'downstream', 'docs/LIVE_DOCUMENT_SIZE_CONTAINMENT_ADOPTION_GUIDE.md', 'current'),
    ([51], 'Repeated task acceptance narration', 'scripts/check_task_tree_integrity.pl', 'current'),
    ([52], 'common checker alone owns', 't/1554-live-document-size-doctrine.t', 'current public assertion contract; gated native test is not replayed'),
    ([53], "predecessor's T1554", 'docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md', 'historical observations; current explicit native qualification gate'),
]


def expected():
    text = (BASE / 'live-document-size-containment.proposed.txt').read_text()
    answers = [json.loads(line[4:]) for line in re.search(r'^answers:\n((?:  - .*\n)+)', text, re.M)[1].splitlines()]
    rows = []
    for indices, marker, home, role in GROUPS:
        assert marker in text and Path(home).is_file(), 'reviewed semantic marker and canonical home'
        for index in indices:
            rows.append({'index': index, 'question': answers[index], 'card_marker': marker,
                         'authority_home': home, 'role': role,
                         'historical_home': 'read_source.py live-document-size-containment (complete authenticated source)'})
    rows.sort(key=lambda row: row['index'])
    assert [row['index'] for row in rows] == list(range(len(answers))), 'each original question has an explicit information-role home'
    return rows


if __name__ == '__main__':
    (BASE / 'question-homes.json').write_text(json.dumps(expected(), indent=2) + '\n')

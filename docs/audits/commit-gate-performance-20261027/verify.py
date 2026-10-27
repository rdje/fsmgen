#!/usr/bin/env python3
"""Re-derive saved gate coverage/work counts; never rerun gates or touch Git."""
import argparse
from collections import Counter
import copy
import gzip
import hashlib
import json
import math
from pathlib import Path
import re

IDS = ('DOCTRINE-BOOTSTRAP MEMORY-ARCH KNOWLEDGE-MAP DOC-PATHS '
       'LIVE-DOCUMENT-SIZE README-ENTRYPOINT PROJECT-DATA-LOCALITY '
       'TASK-TREE-INTEGRITY CLAIM-VERIFICATION CLAIM-INVENTORY '
       'CLAIM-DISPOSITIONS TASK-ACCEPTANCE').split()
CORE = {
    'derived-state contract active_task_index_frontier': 'scripts/check_task_tree_integrity.pl',
    'surface focused_document_index freshness': 'scripts/focused_document_index.pl',
    'surface active_index currency active_task_tree_alignment': 'scripts/check_task_tree_integrity.pl',
    'surface fact_index freshness': 'knowledge-map/scripts/check_knowledge_map.sh',
    'surface fact_index_shards freshness': 'knowledge-map/scripts/check_knowledge_map.sh',
    'surface book_source_manifest freshness': 'scripts/book_source_references.py',
    'surface book_source_manifest currency book_source_git_result': 'scripts/check_book_source_index.py',
}
ADAPTER = '''currency:knowledge_cards surface:decision_archive_view surface:decision_compatibility
archive:changes-retired-2026-08-01 archive:achievement-status-retired-2026-08-01
archive:roadmap-status-retired-2026-08-01 archive:roadmap-v2-pre-containment-2026-08-01
archive:engineering-rationale-source-2026-08-01 archive:engineering-rationale-range-0001
archive:knowledge-ial2-priority-pre-containment-2026-08-01
archive:knowledge-ial2-next-slice-pre-containment-2026-08-01
archive:knowledge-direct-vhdl-pre-containment-2026-08-01
archive:knowledge-vial-execution-scale-reachability-pre-partition-2026-08-20
archive:isf-spec-pre-partition-2026-08-01
archive:isf-downstream-pre-partition-2026-08-01
archive:isf-public-interface-pre-partition-2026-08-01 ledger:engineering_rationale'''.split()


def require(condition, message):
    if not condition:
        raise ValueError(message)


def inspect_run(run, suites, core_exec, adapter_shared):
    log, report = run['log'], run['report']
    for path, identity in report['identities'].items():
        require(hashlib.sha256(run['sources'][path].encode()).hexdigest() == identity['sha256'],
                'source identity: ' + path)
    require(re.fullmatch('[0-9a-f]{64}', report['index_sha256']), 'index identity')
    require(report['exit'] == 0, 'actual exit')
    require([row.split('\t')[0] for row in report['registry'].splitlines()] == IDS, 'declared registry')
    require(re.findall(r'^\[doctrine\] RUN:  ([A-Z-]+) ', log, re.M) == IDS, 'actual complete execution')
    require(re.findall(r'^\[doctrine\] PASS: ([A-Z-]+)$', log, re.M) == IDS, 'actual complete success')
    require(not re.search(r'^\[doctrine\] FAIL:', log, re.M), 'actual failure')
    require(log.count('[doctrine] all doctrine checks passed\n') == 1, 'unique complete verdict')
    require([e['id'] for e in report['events']] == IDS
            and all(e['status'] == 'PASS' for e in report['events']), 'parent event inventory')
    require(all(math.isfinite(e['seconds']) and e['seconds'] >= 0 for e in report['events']), 'event timing')
    real = re.findall(r'^real ([0-9]+\.[0-9]+)$', log, re.M)
    require(len(real) == 1, 'independent POSIX wall time')
    wall = report['parent_wall_seconds']
    require(math.isfinite(wall) and wall > 0 and abs(wall - float(real[0])) < 1, 'parent/POSIX agreement')
    require(len(re.findall(r'^live-doc-size: all live-document size-containment invariants hold', log, re.M)) == suites,
            'complete live suite count')
    roles = re.findall(r'^live-doc-size: ok:   (.+) core verifier (?:executed|result shared within invocation): (.+)$', log, re.M)
    require(Counter(roles) == Counter({pair: suites for pair in CORE.items()}), 'every core proof role')
    proofs = re.findall(r'adapter verifier execution proved: ([^\s]+)', log)
    require(Counter(proofs) == Counter({proof: suites for proof in ADAPTER}), 'every adapter proof role')
    physical_core = log.count('core verifier executed:')
    shared = log.count('live-doc-adapter-verifier: shared execution')
    require(physical_core == core_exec and shared == adapter_shared, 'physical execution inventory')
    return {'wall_seconds': wall, 'core_executions': physical_core,
            'adapter_executions': len(proofs) - shared,
            'delegated_executions': physical_core + len(proofs) - shared}


def verify(data):
    require(data['format'] == 'commit-gate-observations-v1', 'receipt format')
    return {key: inspect_run(data[key], *counts) for key, counts in
            [('baseline', (2, 14, 0)), ('optimized', (1, 5, 8))]}


def self_test(data):
    controls = []
    missing = copy.deepcopy(data)
    missing['optimized']['log'] = missing['optimized']['log'].replace('[doctrine] PASS: TASK-ACCEPTANCE\n', '')
    controls.append(missing)
    proof = copy.deepcopy(data)
    proof['optimized']['log'] = re.sub(r'^.*execution proved: currency:knowledge_cards\n', '', proof['optimized']['log'], flags=re.M)
    controls.append(proof)
    timing = copy.deepcopy(data)
    timing['optimized']['report']['parent_wall_seconds'] = float('nan')
    controls.append(timing)
    source = copy.deepcopy(data)
    source['optimized']['sources']['scripts/check_doctrines.sh'] += '# changed\n'
    controls.append(source)
    for control in controls:
        try:
            verify(control)
        except ValueError:
            continue
        raise ValueError('negative receipt control incorrectly accepted')
    return len(controls)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--self-test', action='store_true')
    args = parser.parse_args()
    data = json.loads(gzip.decompress(Path(__file__).with_name('receipt.json.gz').read_bytes()))
    result = verify(data)
    if args.self_test:
        print('commit-gate-profile: rejected', self_test(data), 'altered receipt controls')
    print('commit-gate-profile: saved complete coverage and observations verified:', json.dumps(result, sort_keys=True))
    print('commit-gate-profile: elapsed speedup unproven; input states and host load differ; no full CI or hosted claim')

"""Independently qualify exact guide registration and complete claim dispositions."""
import json
import sys
from pathlib import Path
import oracle_repaired as oracle

BASE = oracle.BASE


def rows(path):
    return [json.loads(line) for line in Path(path).read_bytes().splitlines()]


def derive():
    report = json.loads((BASE / 'gate-repair.json').read_bytes())
    before = rows(BASE / 'before-gate-surfaces.jsonl.txt')
    current = rows(BASE / 'after-gate-surfaces.jsonl.txt')
    oracle.must(oracle.identical(current, before + report['exact_surfaces']), 'whole exact surface additions and unchanged prior authority')
    owner = (BASE / 'scope.txt').read_text().strip()
    measurements = {}
    for name, identifier, limit in [('GUIDE.md', 'observer_display_guide', 160), ('fact-proposal.md', 'observer_display_fact_proposal', 64)]:
        row, = [r for r in report['exact_surfaces'] if r['surface_id'] == identifier]
        caps = dict(bytes_each=limit * 64, bytes_total=limit * 64, files=1, line_bytes_each=512,
                    lines_each=limit, lines_total=limit)
        oracle.must(row['targets'] == [str(BASE / name)] and row['owner'] == owner
                    and row['lifecycle'] == 'bounded_snapshot' and row['locator'] == 'file'
                    and row['enforcement_ceilings'] == caps and row['health_targets'] == caps, 'exact bounded guide/proposal envelopes')
        raw = (BASE / name).read_bytes()
        measured = dict(bytes=len(raw), lines=raw.count(b'\n'), max_line_bytes=max(map(len, raw.splitlines())))
        oracle.must(measured['bytes'] <= caps['bytes_each'] and measured['lines'] <= limit
                    and measured['max_line_bytes'] <= 512, 'whole guide/proposal measured within fixed caps')
        measurements[name] = measured
    before = rows(BASE / 'before-gate-dispositions.jsonl.txt')
    current = rows(BASE / 'after-gate-dispositions.jsonl.txt')
    expected = [before[0]] + sorted(before[1:] + report['derived_dispositions'], key=lambda r: r['candidate_id'])
    oracle.must(oracle.identical(current, expected), 'every old disposition and exact new evidence rows conserve')
    inventory = rows(BASE / 'after-gate-inventory.jsonl.txt')
    old = {r['candidate_id'] for r in before[1:]}
    candidates = {r['candidate_id']: r for r in inventory if r.get('record_type') == 'published_candidate'
                  and r.get('path') == 'docs/book/src/13k-isf-feature-support-matrix.md' and r['candidate_id'] not in old}
    oracle.must(set(candidates) == {r['candidate_id'] for r in report['derived_dispositions']}, 'complete newly published book claim population')
    for r in report['derived_dispositions']:
        oracle.must(r['disposition'] == 'derived_gate' and r['owner_task'] == 'CLAIM-VERIFICATION-ADOPTION.5.3'
                    and r['rederive']['producer_paths'] != r['falsify']['oracle_paths']
                    and r['rederive']['producer_paths'] != r['durability']['watcher_paths'], 'three distinct mechanical review evidence legs')
    failed = json.loads((BASE / 'checks.json').read_bytes())['staged-doctrines']
    text = failed['stdout'] + failed['stderr']
    oracle.must(type(failed['status']) is int and failed['status'] == 1
                and all(s in text for s in ['[task-acceptance] OK:', 'tracked document is not covered by any surface: ' + str(BASE / 'GUIDE.md'),
                    'tracked document is not covered by any surface: ' + str(BASE / 'fact-proposal.md'),
                    'group general_book requires completeness but has 5 open candidate(s)']), 'whole genuine first staged-gate refusal')
    return dict(exact_surface_rows=report['exact_surfaces'], measured_documents=measurements,
                added_dispositions=report['derived_dispositions'], complete_candidates=candidates,
                scope='Existing full surface/ceiling and claim-disposition authority unchanged; two exact bounded documents and complete new book-claim evidence admitted only.')


def main():
    assert sys.argv[1:] in ([], ['--current'])
    result = derive()
    if sys.argv[1:]:
        for name, live in [('surfaces', 'doctrine/live_document_size/surfaces.jsonl'),
                           ('dispositions', 'doctrine/claim_verification/dispositions.jsonl'),
                           ('inventory', 'doctrine/claim_verification/inventory.jsonl')]:
            oracle.must(Path(live).read_bytes() == (BASE / ('after-gate-' + name + '.jsonl.txt')).read_bytes(), 'whole current and saved gate repair sources')
    path = BASE / 'gate-repair-proof.json'
    if path.exists():
        oracle.must(oracle.identical(result, json.loads(path.read_bytes())), 'whole dated gate repair products')
    else:
        path.write_text(json.dumps(result, sort_keys=True, indent=2) + '\n')
    print('PASS exact bounded document registration and complete three-leg book dispositions; every prior surface, ceiling and disposition conserves.')


if __name__ == '__main__':
    main()

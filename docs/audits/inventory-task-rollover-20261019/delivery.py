"""Bind closed rollover delivery, current-owner conservation and measured budgets."""
import argparse
import copy
import gzip
import json
from pathlib import Path

import rollover as r

C = r.retained
BOOK = 'docs/book/src/90-reference-map.md'
SURFACES = 'doctrine/live_document_size/surfaces.jsonl'
RATIONALE = ('Retain one exact flat completed inventory subtree and its runnable proof while preserving '
             'all active roles and native limitations; no product behavior or ceiling changes.')


def qualify(sources):
    original = C.unpack(C.local(r.BASE / 'source.json.gz').read_bytes())
    compacted = r.body('compacted.md.gz')
    final = sources[C.TASK]
    before, after = C.nodes(compacted), C.nodes(final)
    assert before.keys() == after.keys()
    assert all(after[name] == raw for name, raw in before.items() if name != r.OWNER)
    assert final == compacted.replace(before[r.OWNER], after[r.OWNER], 1)
    assert C.field(after[r.OWNER], 'Status') == 'done' and C.field(after[r.OWNER], 'Commit') != 'pending'
    owners = C.owner_census(sources)
    assert not any(C.selected(row['owner'], r.ROOT) for row in owners)
    assert all(row['owner'] in after for row in owners if C.selected(row['owner'], C.TREE))
    task_sources = {name: raw for name, raw in original.items() if name.startswith('docs/tasks/') and name.endswith('.md')}
    task_sources[C.TASK] = final
    measured = C.metrics(task_sources)
    old_rows = [json.loads(line) for line in original[SURFACES].splitlines()]
    rows = [json.loads(line) for line in sources[SURFACES].splitlines()]
    expected = copy.deepcopy(old_rows)
    book_names = [name for name in C.git('ls-tree', '-r', '--name-only', r.REVISION).decode().splitlines()
                  if C.re.fullmatch(r'docs/book/src/[^/]+\.md', name)]
    books = C.frozen_sources(book_names)
    baseline = C.metrics(books)['metrics']
    books[BOOK] = sources[BOOK]
    current = C.metrics(books)['metrics']
    for row in expected:
        if row.get('surface_id') == 'task_evidence':
            previous = dict(row['transition']['max_growth'])
            for key, value in measured['metrics'].items():
                growth = max(0, value + row['transition']['ratchet_step'][key] - row['baseline'][key])
                assert growth <= previous[key] and value <= row['enforcement_ceilings'][key]
                row['transition']['max_growth'][key] = growth
        elif row.get('surface_id') == 'shipped_behavior':
            keys = ('files', 'bytes_total', 'lines_total')
            row['reference_contract']['aggregate_change'] = dict(authority_id='INVENTORY-TASK-ROLLOVER-20261019',
                owner=r.OWNER, baseline={key: baseline[key] for key in keys},
                delta={key: current[key] - baseline[key] for key in keys}, rationale=RATIONALE)
    assert C.canonical(rows) == C.canonical(expected)
    for name, raw in original.items():
        if name.startswith('doctrine/') and name not in (SURFACES, 'doctrine/claim_verification/inventory.jsonl'):
            assert sources[name] == raw
    independent = r.native.independent(task_sources, dict(final=final))
    return dict(owners=owners, measured=measured, independent=independent,
                scope='Exact closed owner-only final transition, unchanged registry-owner availability and ceilings, '
                      'independently measured complete task working set. Full original source and retrieved subtree overlap; '
                      'no summation or historical loss, runtime role closure or semantic execution is inferred.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    parser.add_argument('--current', action='store_true')
    args = parser.parse_args()
    if args.write:
        names = [name for name in r.source_names() if name.startswith('doctrine/')]
        names += [C.TASK, BOOK, 'MEMORY.md', 'docs/TASK_TREE.md']
        sources = {name: C.local(name).read_bytes() for name in sorted(set(names))}
        C.save(r.BASE / 'delivered-strict-source.json.gz', C.pack(sources))
        result = qualify(sources)
        result['programme'] = C.local(r.BASE / 'delivery.py').read_text()
        r.save('delivered-strict-proof.json.gz', result)
    else:
        sources = C.unpack(C.local(r.BASE / 'delivered-strict-source.json.gz').read_bytes())
        result = qualify(sources)
        result['programme'] = C.local(r.BASE / 'delivery.py').read_text()
        assert r.exact(r.load('delivered-strict-proof.json.gz'), result)
    if args.current:
        assert all(C.local(name).read_bytes() == raw for name, raw in sources.items())
    print('Closed exact task-retention delivery, independent current metrics and unchanged owner/budget contracts pass.')

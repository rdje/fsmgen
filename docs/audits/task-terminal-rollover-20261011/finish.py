"""Close only SEM.83; tighten every measured task dimension, then capture currency."""
import argparse
import copy
import gzip
import json
import re
from pathlib import Path
from common import *


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--capture', action='store_true')
    args = parser.parse_args()
    sources = unpack(local(BASE / 'complete-source.json.gz').read_bytes())
    census = json.loads(local(BASE / 'source-census.json').read_bytes())
    if args.capture:
        names = set(census['doctrine_names']) | {TASK, BOOK, CARD, 'MEMORY.md', 'docs/TASK_TREE.md'}
        save(BASE / 'qualified-source.json.gz', pack({name: local(name).read_bytes() for name in names}))
        print('Retained whole final task, registry, book, canonical card and resume epoch.')
        return
    current = local(TASK).read_bytes()
    block = nodes(current)[OWNER]
    need(field(block, 'Status') == 'active', 'only active owning leaf may finish')
    checks = json.loads(local(BASE / 'checks.json').read_bytes())
    focused = checks['focused']
    need(focused['status'] == 0 and focused['epoch_conserved'] is True
         and 'All tests successful.' in focused['stdout'] and 'Files=4, Tests=364' in focused['stdout'],
         'fresh actual focused validation')
    need(checks['native-controls']['status'] == 0 and checks['native-controls']['epoch_conserved'] is True,
         'fresh complete genuine native controls')
    new = block.replace(b'  Status: `active`\n', b'  Status: `done`\n', 1)
    verification = ('Complete fixed predecessor/task/doctrine/book bodies retain in task-terminal-rollover-20261011. '
        'Two disjoint flat closed subtrees reconstruct every original node byte; expanded owner census keeps policy and claim references live. '
        'Independent Perl whole-member/whole-node census, exact dated/default and current readers, native positive/hostile controls and strict seal controls gate closure. '
        'Preparation first refused growing canonical wording after saving the task projection; exact programme/result retain and guarded recovery passes with a non-growing correction. '
        'Fresh focused All tests successful; Files=4, Tests=364. All task dimensions ratchet down under unchanged ceilings; Knowledge Map allowance does not grow. '
        'Final book/native/claim/staged/normal gates require actual success before commit and raw .5.2 activation. Original host-native/private and push gates remain open.')
    new = re.sub(rb'^  Verification: `[^\n]*`\n', ('  Verification: `' + verification + '`\n').encode(), new, count=1, flags=re.M)
    new = new.replace(b'  Commit: `pending`\n', ('  Commit: `' + OWNER + ': retain exact completed task subtrees`\n').encode(), 1)
    new += (f'  - [x] **ROOT CAUSE (WHY + WHERE)** — git log -S preserves original task ownership history; complete fixed-source census locates live growth before rollover. Expanded doctrine-owner census rejects `.51` because policy owners remain live. Exact first non-growing-card refusal and programme retain in prepare-first-failure.json.\n'
        '  - [x] **ADDRESSED (verified)** — Complete version objects reconstruct every selected original goal, acceptance, child, verification and commit byte; all other nodes and raw acceptance contracts remain exact. Separate source, semantic, working-set and residue products retain with independent native parity and genuine production-checker corruptions.\n'
        '  - [x] **NO REGRESSION** — All tests successful; Files=4, Tests=364 in checks.json focused. Exact saved/default and current-source proofs, strict namespace controls, current native/book currency, claim/source/staged doctrines and normal hooks gate commit; every actual command/result retains.\n\n').encode()
    # Place checklist inside the owner, before its existing trailing separator.
    new = new.replace(b'\n\n  - [x]', b'\n  - [x]', 1)
    final = current.replace(block, new, 1)
    local(TASK).write_bytes(final)
    memory = local('MEMORY.md').read_text().replace(OWNER + '` (active)', RAW + '.5.2` (pending)', 1)
    start, end = memory.index('- next_action:'), memory.index('- in_flight_uncommitted:')
    memory = memory[:start] + '- next_action: Activate the complete raw-stack semantic join .5.2 from the committed bounded task tree; preserve all original class/frame/coordinate/address and primary/source/context contracts, dated instruments and explicit native/private gaps.\n' + memory[end:]
    local('MEMORY.md').write_text(memory)
    index = local('docs/TASK_TREE.md').read_text()
    need('task containment .83; raw join next.' in index, 'current task-index frontier')
    local('docs/TASK_TREE.md').write_text(index.replace('task containment .83; raw join next.', 'task contained; raw join next.', 1))
    task_names = sorted(str(path) for pattern in ('docs/tasks/*.md', 'docs/tasks/segments/*/*.md')
                        for path in Path('.').glob(pattern))
    independent = sorted(name for name in subprocess.check_output(['rg', '--files', '--hidden', '-uuu', 'docs/tasks'], text=True).splitlines()
                         if re.fullmatch(r'docs/tasks/(?:[^/]+|segments/[^/]+/[^/]+)\.md', name))
    need(task_names == independent == census['task_names'], 'complete independent unchanged task membership')
    task_sources = {name: local(name).read_bytes() for name in task_names}
    need(all(task_sources[name] == sources[name] for name in task_names if name != TASK), 'entire other task sources unchanged')
    actual = metrics(task_sources)['metrics']
    rows = [json.loads(line) for line in sources[SURFACES].splitlines()]
    before = copy.deepcopy(rows)
    for old, row in zip(before, rows):
        if row.get('surface_id') == 'task_evidence':
            for dimension, value in actual.items():
                growth = max(0, value + row['transition']['ratchet_step'][dimension] - row['baseline'][dimension])
                need(growth <= old['transition']['max_growth'][dimension], 'measured ratchet never widens')
                need(value <= row['enforcement_ceilings'][dimension], 'unchanged ceiling')
                row['transition']['max_growth'][dimension] = growth
        elif row.get('surface_id') == 'shipped_behavior':
            baseline = metrics({name: sources[name] for name in census['book_names']})['metrics']
            current_book = {name: sources[name] for name in census['book_names']}
            current_book[BOOK] = local(BOOK).read_bytes()
            measured = metrics(current_book)['metrics']
            keys = ('files', 'bytes_total', 'lines_total')
            row['reference_contract']['aggregate_change'] = dict(authority_id='TASK-TERMINAL-ROLLOVER-20261011',
                owner=OWNER, baseline={key: baseline[key] for key in keys},
                delta={key: measured[key] - baseline[key] for key in keys},
                rationale='Describe exact completed-subtree version objects and replay, preserving active raw contracts and all live registry owners; no product behavior or ceilings change.')
    need(local(SURFACES).read_bytes() == sources[SURFACES], 'registry unchanged before exact ratchet')
    local(SURFACES).write_bytes(b''.join(canonical(row) for row in rows))
    print('Closed owner; measured all task dimensions and tightened unused allowances:', actual)


if __name__ == '__main__':
    main()

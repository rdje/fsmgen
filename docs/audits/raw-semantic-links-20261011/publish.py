"""Close only independently qualified finite semantic associations."""
import re
from common import *
import verify

BOOK = 'docs/book/src/13k-isf-feature-support-matrix.md'
SURFACES = 'doctrine/live_document_size/surfaces.jsonl'
MARKER = b'Only the finite observer and class/frame predecessor containers close here.\n'
ADDITION = (b'The construction checkpoint above retains its dated pending semantic label.\n'
    b'The independent successor now reconstructs the entire association product\n'
    b'from the qualified original raw, class, frame, header, argument, coordinate\n'
    b'and address source products. Explicit links bind complete ordered bodies,\n'
    b'first causes, source callers, visible operands and simultaneous holders.\n'
    b'Nested errors retain the whole inner cause, new outer prefix and outer trace.\n\n'
    b'For example, assigning a valid visible address to another source argument\n'
    b'leaves the inherited body intact and passes the namespace-adapted body reader, but\n'
    b'fails the new address/holder association. Whole-stack, first-cause, caller,\n'
    b'header-order, argument, opaque, scope, omission, phase and nested-cause\n'
    b'interventions similarly reach their intended semantic assertions. Complete\n'
    b'positive and hostile products, programmes and actual streams are retained.\n\n'
    b'The first semantic checker accepted Boolean false as integer phase zero.\n'
    b'That complete false-green epoch remains saved. Typed canonical coordinate\n'
    b'comparisons now refuse it, and a separate Perl reader rejects its Boolean\n'
    b'JSON kind. Every original semantic control reexecutes with the corrected\n'
    b'programmes before signoff.\n\n'
    b'The interrupted host-memory attempt remains non-success. Complete control\n'
    b'execution and proof replay now use separate processes under the unchanged\n'
    b'RAM guard.\n\n'
    b'The body reader changes only its own candidate-path boundary.\n'
    b'The producer reads the complete candidate; the independent checker reads\n'
    b'the original qualified source products. Their shared source models remain\n'
    b'explicit assumptions. The original native class, hooks, provider, settings,\n'
    b'flags, encoding, hidden arguments and private or referent identities remain\n'
    b'unmeasured. Parent acceptance and full raw canonical publication remain\n'
    b'separate. Replay requires the complete fixed source/instrument context:\n\n'
    b'```bash\nscripts/run_with_ram_guard.sh -- python3 -B docs/audits/raw-semantic-links-20261011/verify.py\n```\n\n')


def authority(before, task_sources, book_sources, book_after):
    rows = [json.loads(line) for line in before.splitlines()]
    measured = metrics(task_sources)['metrics']
    for row in rows:
        if row.get('surface_id') == 'task_evidence':
            need(row['state'] == 'warning_debt' and measured['lines_each'] < 7200, 'bounded owned task growth before rollover')
            for key, value in measured.items():
                need(value <= row['enforcement_ceilings'][key], 'unchanged task ceilings')
                row['transition']['max_growth'][key] = max(0, value + row['transition']['ratchet_step'][key] - row['baseline'][key])
        elif row.get('surface_id') == 'shipped_behavior':
            baseline = metrics(book_sources)['metrics']
            current = dict(book_sources)
            current[BOOK] = book_after
            after = metrics(current)['metrics']
            keys = ('files', 'bytes_total', 'lines_total')
            row['reference_contract']['aggregate_change'] = dict(authority_id='RAW-SEMANTIC-LINKS-20261011', owner=LEAF,
                baseline={key: baseline[key] for key in keys}, delta={key: after[key] - baseline[key] for key in keys},
                rationale='Document complete finite original semantic associations and genuine prior-preserving controls. Parent/canonical publication and original native/private scopes remain open.')
    return b''.join(canonical(row) for row in rows)


def main():
    verify.core()
    task = local(TASK).read_bytes()
    graph = verify.nodes(task)
    block = graph[OWNER]
    need(verify.field(block, 'Status') == b'active', 'active independent semantic qualification leaf')
    final = block.replace(b'  Status: `active`\n', b'  Status: `done`\n', 1)
    text = ('Complete admitted source/native/product and directory custody conserves. The candidate-derived explicit links agree with '
        'a separate source-first reconstruction of every full original body/class/phase/frame/header/argument/coordinate/address/holder '
        'and nested inner/outer cause association. Genuine whole new-link interventions preserve every inherited component and pass '
        'the separate actual namespace-adapted original-body predicate before intended independent semantic refusals. Complete predecessor defaults '
        'freshly pass before and after the group. Full saved products, programmes, commands and streams retain. Qualified source '
        'models are shared assumptions; original native/private gaps conserve. Current/book/native/focused/claim/staged/normal '
        'gates require actual success before commit. Only this finite semantic leaf closes; parent acceptance and full raw publication remain separate.')
    final = final.replace(b'  Verification: `' + verify.field(block, 'Verification') + b'`\n', ('  Verification: `' + text + '`\n').encode(), 1)
    final = final.replace(b'  Commit: `pending`\n', ('  Commit: `' + LEAF + ': qualify typed complete original semantic associations`\n').encode(), 1)
    task = task.replace(block, final, 1)
    block = verify.nodes(task)[LEAF]
    need(verify.field(block, 'Status') == b'active', 'active typed semantic repair leaf')
    final = block.replace(b'  Status: `active`\n', b'  Status: `done`\n', 1)
    final = final.replace(b'  Verification: `pending`\n', ('  Verification: `' + text + ' Strict typed canonical record/phase comparison and separate native JSON-kind refusal close the reproduced Boolean false green; complete first results and programmes retain. The interrupted host-RAM attempt stays non-success; all corrected controls qualify in separate fresh processes under the unchanged guard.`\n').encode(), 1)
    final = final.replace(b'  Commit: `pending`\n', ('  Commit: `' + LEAF + ': qualify typed complete original semantic associations`\n').encode(), 1)
    diagnostic = load('checks.json')['bounded-typed-boolean']['stderr']
    locus = re.search(r' at [^\s]+ line [0-9]+', diagnostic)
    need(locus is not None, 'actual independent native JSON-kind refusal locus')
    final = final.rstrip() + (f'\n  Acceptance Checklist (enforced):\n'
        f'  - [x] **ROOT CAUSE (WHY + WHERE)** — First full Boolean phase candidate passed the original independent semantic reader because Python sequence equality aliases false and integer zero. Complete first programmes and both actual streams retain. The separate native check now emits semantic phase coordinate requires a JSON integer{locus[0]}; checks.json bounded-typed-boolean retains full programme/command/result.\n'
        '  - [x] **ADDRESSED (verified)** — Strict typed canonical record/phase equality rejects the actual Boolean false green; separate native JSON wire-kind controls agree. Independent complete source-first reconstruction and every genuine prior-preserving full semantic control reexecute under the corrected programme epoch, preserving every inherited source/native/product byte and all original Goal/Acceptance clauses.\n'
        '  - [x] **NO REGRESSION** — All tests successful in checks.json bounded-focused; complete fresh predecessor defaults before and after controls, whole source/native/product custody, current/book/native/claim/staged scripts/check_doctrines.sh and normal hooks require actual success before commit.\n\n').encode()
    task = task.replace(block, final, 1)
    local(TASK).write_bytes(task)
    verify.contracts(task)
    successor = OWNER.rsplit('.', 1)[0] + '.3'
    memory = local('MEMORY.md').read_text().replace(LEAF + '` (active)', successor + '` (pending)', 1)
    memory = re.sub(r'^- next_action:.*$', '- next_action: Confirm terminal complete semantic qualification gates and commit any dirty owned state, then activate .5.2.2.3 to close the complete unchanged association acceptance. Full .5.2.3 parent acceptance and distinct raw canonical publication .5.3 remain separate.', memory, flags=re.M)
    memory = re.sub(r'^- in_flight_background:.*$', '- in_flight_background: Derive incomplete started/actual checks under docs/audits/raw-semantic-links-20261011/checks.json. Consume every required result before handoff.', memory, flags=re.M)
    local('MEMORY.md').write_text(memory)
    index = local('docs/TASK_TREE.md').read_text()
    need('raw admitted; candidates done; typed semantic repair.' in index, 'owned bounded semantic frontier')
    local('docs/TASK_TREE.md').write_text(index.replace('raw admitted; candidates done; typed semantic repair.', 'raw semantic done; association closure next.', 1))
    book_before = git('show', REVISION + ':' + BOOK)
    need(local(BOOK).read_bytes() == book_before and book_before.count(MARKER) == 1, 'whole unique fixed semantic publication baseline')
    local(BOOK).write_bytes(book_before.replace(MARKER, ADDITION + MARKER, 1))
    names = git('ls-tree', '-r', '--name-only', REVISION).decode().splitlines()
    task_names = sorted(name for name in names if re.fullmatch(r'docs/tasks/(?:[^/]+|segments/[^/]+/[^/]+)\.md', name))
    book_names = sorted(name for name in names if re.fullmatch(r'docs/book/src/[^/]+\.md', name))
    fixed = fixed_sources(task_names + book_names + [SURFACES])
    tasks = {name: local(name).read_bytes() for name in task_names}
    need(all(raw == fixed[name] for name, raw in tasks.items() if name != TASK), 'every unrelated task source conserves')
    need(sorted(str(p) for pattern in ('docs/tasks/*.md', 'docs/tasks/segments/*/*.md') for p in Path('.').glob(pattern)) == task_names,
         'whole unchanged task collection membership')
    save('task-census.json', metrics(tasks))
    need(local(SURFACES).read_bytes() == fixed[SURFACES], 'whole unchanged registry before measured semantic authority')
    registry = authority(fixed[SURFACES], tasks, {name: fixed[name] for name in book_names}, local(BOOK).read_bytes())
    local(SURFACES).write_bytes(registry)
    for name, raw in (('registry-before.txt', fixed[SURFACES]), ('registry-after.txt', registry)):
        path = local(BASE / name, exists=False)
        need(not path.exists(), 'retain first complete semantic registry source')
        path.write_bytes(raw)
    for name, raw in (('qualified-task.md.gz', task), ('book-before.md.gz', book_before), ('book-after.md.gz', local(BOOK).read_bytes())):
        path = local(BASE / name, exists=False)
        need(not path.exists(), 'retain first complete semantic publication source')
        path.write_bytes(gzip.compress(raw, mtime=0))
    save('publication.json', dict(task_names=task_names, book_names=book_names, revision=REVISION,
                                book_before=pin(book_before), book_after=pin(local(BOOK).read_bytes()), registry_after=pin(registry)))
    print('Prepared complete finite semantic publication and unchanged original acceptance; all external gates require actual success.')


if __name__ == '__main__':
    main()

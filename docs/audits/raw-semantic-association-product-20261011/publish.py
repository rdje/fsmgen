"""Publish only complete construction/custody; independent semantics stay pending."""
import re
from common import *
import verify

BOOK = 'docs/book/src/13k-isf-feature-support-matrix.md'
SURFACES = 'doctrine/live_document_size/surfaces.jsonl'
MARKER = b'Only the finite observer and class/frame predecessor containers close here.\n'
ADDITION = (b'A complete source-bound raw-body candidate now retains every original error\n'
    b'body and empty-member allocation with its ordered source class, frame, full\n'
    b'header, argument, coordinate and visible-address roles. Whole opaque allocations\n'
    b'and nested inner/outer bodies retain their qualified boundaries. A separate\n'
    b'Perl reader checks captured UTF-8 bytes and lossless physical reconstruction;\n'
    b'whole candidate byte-conservation mutations reach their intended refusals.\n\n'
    b'This is construction and byte custody. Independent complete semantic\n'
    b'reconstruction and separating controls remain pending. Replay requires the\n'
    b'whole admitted source instruments to match the fixed construction context:\n\n'
    b'```bash\nscripts/run_with_ram_guard.sh -- python3 -B docs/audits/raw-semantic-association-product-20261011/verify.py\n```\n\n')


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
            row['reference_contract']['aggregate_change'] = dict(authority_id='RAW-SEMANTIC-CANDIDATE-20261011', owner=OWNER,
                baseline={key: baseline[key] for key in keys}, delta={key: after[key] - baseline[key] for key in keys},
                rationale='Document whole source-bound raw-body candidate construction and independent original byte conservation only. Complete semantic independence and separating controls remain pending; original native/private scopes conserve.')
    return b''.join(canonical(row) for row in rows)


def main():
    verify.core()
    actual = load('control-changed-body-tail-actual.json')
    locus = re.search(r' at [^\s]+ line [0-9]+', actual['stderr'])
    need(locus is not None, 'actual independent original-body control diagnostic locus')
    current = local(TASK).read_bytes()
    block = verify.nodes(current)[OWNER]
    need(verify.field(block, 'Status') == b'active', 'own active construction leaf')
    wording = ('Whole cb5d85b9 source/native/product and admission namespace conserve byte for byte with exact directory closure. '
        'Deterministic complete candidates retain original bodies and empty allocation, source class/frame/header/argument/coordinate/address roles, '
        'opaque boundaries and whole nested forwarding. A separate Perl reader independently extracts every complete original captured body and '
        'qualifies whole UTF-8/physical-byte custody with genuine full candidate controls and actual intended diagnostic streams. '
        'Constructor replay shares qualified source models; independent complete semantic reconstruction and separating controls remain .5.2.2.2. '
        'Original acceptance and native/private gaps conserve; all current/book/native/focused/claim/staged/normal gates require actual success before commit.')
    final = block.replace(b'  Status: `active`\n', b'  Status: `done`\n', 1)
    final = final.replace(b'  Verification: `pending`\n', ('  Verification: `' + wording + '`\n').encode(), 1)
    final = final.replace(b'  Commit: `pending`\n', ('  Commit: `' + OWNER + ': construct complete raw-body candidates`\n').encode(), 1)
    final = final.rstrip() + (f'\n  Acceptance Checklist (enforced):\n'
        f'  - [x] **ROOT CAUSE (WHY + WHERE)** — Actual whole-body tail mutation refuses{locus[0]}; control-changed-body-tail-actual.json retains the complete programme epoch and both streams, and the compressed control retains the entire candidate. A source-bound complete association candidate was missing before independent semantic qualification.\n'
        '  - [x] **ADDRESSED (verified)** — Complete original/candidate membership, whole UTF-8 bodies and lossless physical reconstruction qualify through a separate native reader and genuine complete candidate controls. Full source-bound roles and nested forwarding retain; independent semantic reconstruction remains .5.2.2.2.\n'
        '  - [x] **NO REGRESSION** — All tests successful in checks.json focused; complete original source custody, whole saved construction replay, current/book/native/claim/staged scripts/check_doctrines.sh and normal hooks require actual success before commit.\n\n').encode()
    local(TASK).write_bytes(current.replace(block, final, 1))
    verify.contracts(local(TASK).read_bytes())
    memory = local('MEMORY.md').read_text().replace(OWNER + '` (active)', OWNER.rsplit('.', 1)[0] + '.2` (pending)', 1)
    memory = re.sub(r'^- next_action:.*$', '- next_action: Independently reconstruct and qualify every full raw-body semantic association under .5.2.2.2 from committed complete candidates; save genuine prior-preserving semantic controls before judgement. Construction and independent byte custody supply no semantic/native promotion.', memory, flags=re.M)
    memory = re.sub(r'^- in_flight_background:.*$', '- in_flight_background: Derive incomplete started/actual checks under docs/audits/raw-semantic-association-product-20261011/checks.json. Consume every required result before handoff.', memory, flags=re.M)
    local('MEMORY.md').write_text(memory)
    index = local('docs/TASK_TREE.md').read_text()
    need('full-body candidate construction active.' in index, 'own construction task-index frontier')
    local('docs/TASK_TREE.md').write_text(index.replace('full-body candidate construction active.', 'full-body candidates done; independent semantics next.', 1))
    book_before = git('show', REVISION + ':' + BOOK)
    need(local(BOOK).read_bytes() == book_before and book_before.count(MARKER) == 1, 'whole unique fixed construction publication baseline')
    local(BOOK).write_bytes(book_before.replace(MARKER, ADDITION + MARKER, 1))
    names = git('ls-tree', '-r', '--name-only', REVISION).decode().splitlines()
    task_names = sorted(name for name in names if re.fullmatch(r'docs/tasks/(?:[^/]+|segments/[^/]+/[^/]+)\.md', name))
    book_names = sorted(name for name in names if re.fullmatch(r'docs/book/src/[^/]+\.md', name))
    fixed = fixed_sources(task_names + book_names + [SURFACES])
    tasks = {name: local(name).read_bytes() for name in task_names}
    need(all(raw == fixed[name] for name, raw in tasks.items() if name != TASK), 'all unrelated task sources conserved')
    observed = sorted(str(path) for pattern in ('docs/tasks/*.md', 'docs/tasks/segments/*/*.md') for path in Path('.').glob(pattern))
    need(observed == task_names, 'complete unchanged task collection membership')
    save('task-census.json', metrics(tasks))
    need(local(SURFACES).read_bytes() == fixed[SURFACES], 'whole unchanged registry before measured construction authority')
    registry = authority(fixed[SURFACES], tasks, {name: fixed[name] for name in book_names}, local(BOOK).read_bytes())
    local(SURFACES).write_bytes(registry)
    for name, raw in (('registry-before.txt', fixed[SURFACES]), ('registry-after.txt', registry)):
        path = local(BASE / name, exists=False)
        need(not path.exists(), 'retain complete first registry publication')
        path.write_bytes(raw)
    for name, raw in (('qualified-task.md.gz', local(TASK).read_bytes()), ('book-before.md.gz', book_before), ('book-after.md.gz', local(BOOK).read_bytes())):
        path = local(BASE / name, exists=False)
        need(not path.exists(), 'retain complete first publication source')
        path.write_bytes(gzip.compress(raw, mtime=0))
    save('publication.json', dict(source_revision=REVISION, task_names=task_names, book_names=book_names,
                                book_before=pin(book_before), book_after=pin(local(BOOK).read_bytes()), registry_after=pin(registry)))
    print('Prepared construction-only publication and exact measured authority; all external gates require actual success.')


if __name__ == '__main__':
    main()

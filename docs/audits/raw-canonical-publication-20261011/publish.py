"""Publish only the admitted finite raw fact, current guide and owning leaf."""
import ast
import gzip
import json
from pathlib import Path
import re
import subprocess
import sys

from capture import BASE, canonical, pin, save

sys.path.insert(0, 'scripts')
import record_value_raw_fact as fact

PLAN = json.loads((BASE / 'plan.json').read_bytes())
TASK = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
BOOK = 'docs/book/src/13k-isf-feature-support-matrix.md'
REGISTRY = 'doctrine/live_document_size/surfaces.jsonl'


def need(value, message):
    if not value:
        raise ValueError(message)


def metrics(sources):
    rows = [dict(bytes=len(raw), lines=raw.count(b'\n'), width=max(map(len, raw.splitlines()), default=0))
            for raw in sources.values()]
    return dict(files=len(rows), bytes_total=sum(r['bytes'] for r in rows), lines_total=sum(r['lines'] for r in rows),
                bytes_each=max(r['bytes'] for r in rows), lines_each=max(r['lines'] for r in rows),
                line_bytes_each=max(r['width'] for r in rows))


def main():
    admission = json.loads((BASE / 'admission.json').read_bytes())
    need(admission['qualification'] == fact.authenticate() and admission['candidate'] == fact.admission()
         and admission['after'] == fact.published(admission['candidate']), 'whole unchanged original raw admission before publication')
    names = (TASK, BOOK, REGISTRY, 'MEMORY.md', 'docs/TASK_TREE.md', fact.CARD)
    before = {n: Path(n).read_bytes() for n in names}
    need(before[fact.CARD] == admission['before'].encode(), 'whole original canonical raw fact before admission')
    syntax = ast.parse(Path(PLAN['preparation'] + '/publish.py').read_bytes())
    old_notice = next(ast.literal_eval(n.value) for n in syntax.body if isinstance(n, ast.Assign)
                      and any(isinstance(t, ast.Name) and t.id == 'NOTICE' for t in n.targets))
    need(before[BOOK].count(old_notice) == 1, 'unique owned raw preparation notice')
    book = before[BOOK].replace(old_notice, fact.GUIDE.encode(), 1)
    need(len(book) <= 292485, 'unchanged chapter allowance')
    owner = PLAN['owner']
    task = before[TASK].decode()
    start = task.index('- ID: `' + owner + '`\n')
    end = task.index('\n- ID:', start + 1)
    block = task[start:end]
    need(block.count('  Status: `active`\n') == 1 and block.count('  Verification: `pending`') == 1,
         'exact active canonical publication frontier')
    evidence = ('Complete admitted preparation and original fixed Git file/directory/mode/body graph authenticate before and after '
        'current verification. The canonical fact extends only finite raw source joins; two exactly reviewed equivalent wording '
        'contractions preserve old meaning and the current publication date changes at equal byte size. Every original question, '
        'fact id, evidence and probe retains, and no Knowledge Map metric or authority grows. Existing factory actual1 refuses the '
        'prepared meaning before implementation. The maintained factory then admits exact current meanings/questions, whole global '
        'source/query/capacity, source assets and rendered native guidance under its compatible success stream. Permanent current '
        'meaning/query/native and exact typed checkpoint controls separate native promotion, narrowed scope, borrowed current/source '
        'roles and malformed results. The unchanged full dated parent passes before the genuine advanced-producer fixture; that '
        'fixture refuses the fixed-source predicate, exact restoration conserves the entire source population and full native result. '
        'Original e428/prerequisite and later parent source epochs, first failures and unmeasured interrupted peak RSS/first outer '
        'launch diagnostic remain authoritative. Authentication is not fresh original semantic/native/private recapture or later '
        'historical-programme currency. Distinct claim legs are complete original fixed Git/native evidence and current product '
        're-derivation, real current/fixed-source and permanent separating controls, and committed full source/native/publication '
        'custody with ignored-view-independent qualification. Focused/book/native/size/claim/inventory/staged/normal gates accompany '
        'commit. Only canonical publication closes; complete raw acceptance and every higher owner remain separate.')
    final = block.replace('  Status: `active`\n', '  Status: `done`\n', 1)
    final = final.replace('  Verification: `pending`', '  Verification: `' + evidence + '`', 1)
    final = final.replace('  Commit: `pending`', '  Commit: `' + owner + ': admit finite raw canonical source meanings`', 1)
    final = final.rstrip() + (
        '\n  Acceptance Checklist (enforced):\n'
        '  - [x] **ROOT CAUSE (WHY + WHERE)** — git log -S observer_fact.cards identifies the existing target-admission chain. Actual gate-before native1 names the missing new raw target meaning; the genuine borrowed advanced-producer fixture returns1 at the original complete fixed-source predicate. Historical receipt and current programme roles require distinct source contexts.\n'
        '  - [x] **ADDRESSED (verified)** — The complete fixed preparation and original source graph authenticate; the prepared finite raw extension and equivalent contractions publish with no collection growth. The maintained factory checks exact current meanings, source/query/capacity and native guidance while preserving every original source condition and opaque/native/private boundary. Genuine current-instrument substitution rejects, and exact restoration passes.\n'
        '  - [x] **NO REGRESSION** — All tests successful in the focused gate, including permanent current meaning/query/native/typed checkpoint controls and recovery/task/claim/book checks. Whole current native source-copy, Knowledge Map, size, claim/inventory, committed-only proof, staged scripts/check_doctrines.sh and normal hooks gate this commit.\n\n')
    task = (task[:start] + final + task[end:]).encode()
    selected = subprocess.check_output(['git', '--no-replace-objects', 'ls-tree', '-r', '--name-only', PLAN['revision']]).decode().splitlines()
    task_names = sorted(n for n in selected if re.fullmatch(r'docs/tasks/(?:[^/]+|segments/[^/]+/[^/]+)\.md', n))
    book_names = sorted(n for n in selected if re.fullmatch(r'docs/book/src/[^/]+\.md', n))
    card_names = sorted(str(p) for p in Path('docs/knowledge').glob('*.md'))
    tasks, books, cards = ({n: Path(n).read_bytes() for n in names} for names in (task_names, book_names, card_names))
    previous_book, previous_cards = metrics(books), metrics(cards)
    tasks[TASK], books[BOOK], cards[fact.CARD] = task, book, admission['after'].encode()
    measured_book, measured_cards = metrics(books), metrics(cards)
    need(all(value <= previous_cards[key] for key, value in measured_cards.items()), 'whole canonical collection does not grow')
    rows = list(map(json.loads, before[REGISTRY].splitlines()))
    for row in rows:
        if row.get('surface_id') == 'task_evidence':
            for key, value in metrics(tasks).items():
                need(value <= row['enforcement_ceilings'][key], 'unchanged task ceiling')
                row['transition']['max_growth'][key] = max(0, value + row['transition']['ratchet_step'][key] - row['baseline'][key])
        elif row.get('surface_id') == 'shipped_behavior':
            keys = ('files', 'bytes_total', 'lines_total')
            row['reference_contract']['aggregate_change'] = dict(authority_id='RAW-CANONICAL-PUBLICATION-20261011', owner=owner,
                baseline={k: previous_book[k] for k in keys}, delta={k: measured_book[k] - previous_book[k] for k in keys},
                rationale='Replace only the owned raw preparation status with admitted finite source meanings and explicit original source/native/private gaps. No ceilings or Knowledge Map allowances widen.')
    memory = before['MEMORY.md'].decode()
    need(memory.count(owner + '` (active)') == 1, 'exact active canonical publication pointer')
    memory = memory.replace(owner + '` (active)', PLAN['parent'] + '.3` (pending)', 1)
    memory = re.sub(r'^- next_action:.*$', '- next_action: Activate unchanged complete raw acceptance .5.3.3 from clean committed canonical publication. Join every original raw/container/descendant obligation with complete fixed-source/native/current canonical and separating control evidence before closing only full raw owners; all higher scopes retain.', memory, flags=re.M)
    memory = re.sub(r'^- in_flight_background:.*$', '- in_flight_background: None after canonical publication delivery and commit; derive later gate state under docs/audits/raw-canonical-publication-20261011.', memory, flags=re.M)
    marker = b'raw canonical publication active.'
    need(before['docs/TASK_TREE.md'].count(marker) == 1, 'unique canonical frontier marker')
    after = {TASK: task, BOOK: book, REGISTRY: b''.join(canonical(row) for row in rows), 'MEMORY.md': memory.encode(),
             'docs/TASK_TREE.md': before['docs/TASK_TREE.md'].replace(marker, b'raw canonical publication done.', 1),
             fact.CARD: admission['after'].encode()}
    snapshots = {}
    need(not (BASE / 'publication.json').exists(), 'fresh canonical publication')
    for i, name in enumerate(names):
        snapshots[name] = {}
        for role, body in (('before', before[name]), ('after', after[name])):
            path = BASE / ('publication-' + role + '-' + str(i) + '.gz')
            need(not path.exists(), 'every publication target preflights before writes')
            snapshots[name][role] = dict(snapshot=str(path), identity=pin(body))
    for name in names:
        for role in ('before', 'after'):
            Path(snapshots[name][role]['snapshot']).write_bytes(gzip.compress((before if role == 'before' else after)[name], mtime=0))
    save('publication.json', dict(owner=owner, snapshots=snapshots, old_notice=old_notice.decode(), guide=fact.GUIDE,
                                task_names=task_names, book_names=book_names, card_names=card_names,
                                previous_cards=previous_cards, measured_cards=measured_cards))
    need(all(Path(name).read_bytes() == body for name, body in before.items()), 'whole unchanged final publication inputs')
    for name, body in after.items():
        Path(name).write_bytes(body)
    print('Published only admitted finite raw source meanings and current guidance; complete raw acceptance remains open.')


if __name__ == '__main__':
    main()

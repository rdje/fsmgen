"""Publish finite own parser joins without borrowing historical live currency."""
import argparse
import copy
import io
import json
import subprocess
import tarfile
from functools import lru_cache
from html.parser import HTMLParser
from pathlib import Path

BASE = Path('docs/audits/record-value-parser-path-publication-20261006')
CONTEXT = Path('docs/audits/record-value-parser-context-join-20261006')
CHECKS = Path('docs/audits/parser-context-join-checks-20261006')
REVISION = '4cceb992edf4ee03486b5d47fc9a20738d4c1a43'
OWNER = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.2.2.2.4.4'
SOURCE_OWNER = OWNER.removesuffix('.4.4') + '.4.3.3'
CARD = 'docs/knowledge/isf-record-output-source-contexts.md'
CHAPTER = 'docs/book/src/13k-isf-feature-support-matrix.md'
REGISTRY = 'doctrine/live_document_size/surfaces.jsonl'
OLD_ROUTE = 'docs/audits/record-value-parser-path-models-20261006/verify.py --current'
ROUTE = str(BASE / 'verify.py') + ' --current'
COMMAND = 'scripts/run_with_ram_guard.sh -- python3 -B ' + ROUTE
QUESTION = 'what qualifies original parser function argument and helper context joins?'
FACT = ('Original refusals match source-selected own function order and visible argument roles through every '
        'parser/API/observer/helper/subtest phase. Core overlap/order, helper/load adjacency and complete own '
        'frame membership qualify. Completed nested calls retain empty errors and no throw frames. False '
        'denotes source predicate truth, not native encoding; reference kinds/prefixes do not prove referents '
        'or hidden suffixes. Framework/formatter/coordinates/addresses remain unmeasured.\n')
GUIDE = '''The full parser publication now qualifies current facts and question ownership
for these finite own joins. It preserves the original source inventory and
source-expression roles, while qualifying visible function/argument footprints,
complete own operation/helper/subtest phases and completed nested allocations.
Normalized false remains a source predicate role; reference kinds and visible
prefixes do not qualify referent identity or hidden suffixes. Framework/provider,
formatter, scalar encoding, coordinates and addresses remain unmeasured.

Current replay checks the scoped fact, actual direct/cache questions, unchanged
physical card authority and this complete guide. Default replay authenticates
the original sources and saved publication snapshot; snapshot success cannot
supply live semantic currency. Replay the current role from the repository root:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-parser-path-publication-20261006/verify.py --current
```

An optional `--build repository-relative-output` additionally checks complete
current native source copies and rendered guidance. Visual QA remains pending.

'''


def module(path):
    namespace = {'__name__': 'parser_publication_prerequisite'}
    exec(compile(path.read_bytes(), str(path), 'exec'), namespace)
    return namespace


context = module(CONTEXT / 'verify.py')
old = module(Path('docs/audits/record-value-parser-path-models-20261006/publication.py'))
require, same, identity, load = (context[key] for key in ('require', 'same', 'identity', 'load'))
metrics, collection = (old['previous'][key] for key in ('metrics', 'collection'))


def git(path):
    return subprocess.check_output(['git', 'show', REVISION + ':' + path])


@lru_cache(maxsize=None)
def committed(root):
    raw = subprocess.check_output(['git', 'archive', REVISION, root])
    with tarfile.open(fileobj=io.BytesIO(raw), mode='r:') as archive:
        return {entry.name: archive.extractfile(entry).read() for entry in archive.getmembers()
                if entry.isfile() and Path(entry.name).parent == Path(root)}


def pins(blobs):
    return {name: identity(raw) for name, raw in sorted(blobs.items())}


def members():
    paths = list(BASE.iterdir())
    require(all(p.is_file() and not p.is_symlink() for p in paths), 'whole regular publication member domain')
    return {p.name: identity(p.read_bytes()) for p in paths if p.name != 'manifest.json'}


def save(name, value):
    path = BASE / name
    if path.exists():
        require(same(load(path), value), 'whole saved parser publication product: ' + name)
    else:
        require(not (BASE / 'manifest.json').exists(), 'sealed parser publication cannot save')
        path.write_text(json.dumps(value, sort_keys=True, indent=2) + '\n')


def authenticate(replay=True):
    binding = load(BASE / 'binding.json')
    task = git(binding['task_path'])
    start = task.decode().index('- ID: `' + SOURCE_OWNER + '`')
    end = task.decode().index('\n- ID:', start + 1)
    require(binding['revision'] == REVISION and binding['owner'] == SOURCE_OWNER
            and same(binding['task_identity'], identity(task))
            and binding['owner_body'] == task.decode()[start:end]
            and '\n  Status: `done`\n' in binding['owner_body'], 'whole committed done context source owner')
    require(set(binding['archives']) == {str(CONTEXT), str(CHECKS)}, 'complete context publication prerequisite domain')
    for directory, expected in binding['archives'].items():
        actual = {str(p): p.read_bytes() for p in Path(directory).iterdir()}
        require(actual == committed(directory) and same(pins(actual), expected),
                'whole committed context publication source/product/receipt members')
    if (BASE / 'manifest.json').exists():
        require(same(load(BASE / 'manifest.json'), members()), 'whole publication seal and member kinds')
    receipts = []
    if replay:
        for programme in (CONTEXT / 'verify.py', CHECKS / 'verify_seal.py'):
            command = ['python3', '-B', str(programme)]
            result = subprocess.run(command, capture_output=True, text=True)
            receipts.append(dict(command=command, status=result.returncode,
                                 stdout=result.stdout, stderr=result.stderr))
            require(result.returncode == 0, 'complete context source and actual sealed-result replay')
    return receipts


def replace_once(text, before, after, cause):
    require(text.count(before) == 1, cause)
    return text.replace(before, after, 1)


def transform():
    before_card, before_chapter = (git(path).decode() for path in (CARD, CHAPTER))
    card = replace_once(before_card, 'date: 2026-10-01\n',
                        '  - "' + QUESTION + '"\ndate: 2026-10-01\n', 'unique existing question boundary')
    card = replace_once(card, OLD_ROUTE, ROUTE, 'unique prior fact current route')
    old_evidence = '  docs/audits/record-value-parser-path-models-20261006/scope.txt;'
    card = replace_once(card, old_evidence, old_evidence + ' ' + str(CONTEXT / 'scope.txt') + '; '
                        + str(BASE / 'scope.txt') + ';', 'unique retained source evidence boundary')
    # Only completed-work deferrals change. Every source fact remains literal;
    # exact before/after bodies make the scope of supersession reviewable.
    card = replace_once(card,
        'argument models, complete native/API/helper joins, framework/display contracts,',
        'argument models and own joins have separate proofs; framework/display contracts,',
        'unique original inventory qualification boundary')
    card = replace_once(card,
        'source-family proofs; native/API/helper frame matching remains separate.\n',
        'source-family proofs; own native/API/helper matching is qualified separately.\n' + FACT,
        'unique source-model and finite-join boundary')
    chapter = replace_once(before_chapter,
        'replay adds the finite frame join; full combined fact publication is the next\nstage.',
        'replay adds the finite frame join; full current fact publication is qualified\nbelow.',
        'unique completed context publication deferral')
    chapter = replace_once(chapter,
        'source models below qualify own ancestry and argument roles; complete\nAPI/helper/native frame joins remain separate work.',
        'source models below qualify own ancestry and argument roles; complete\nown frame joins have their separate replay above.', 'unique inventory guide source-only role')
    chapter = replace_once(chapter, 'python3 -B ' + OLD_ROUTE,
        'scripts/run_with_ram_guard.sh -- python3 -B ' + OLD_ROUTE.removesuffix(' --current'), 'unique historical source-model snapshot route')
    chapter = replace_once(chapter,
        'The\ncurrent reader additionally checks all physical collection dimensions:',
        'The\nsource-model reader preserves its dated publication snapshot:', 'unique source-model snapshot guide')
    chapter = replace_once(chapter,
        'The scoped current reader preserves all qualified prior and new source meanings,\n'
        'question ownership, source guidance and physical collection bounds. Historical\n'
        'publication replay remains distinct from current semantic qualification. Visual\nQA is pending.',
        'The source-model reader preserves its qualified source meanings and dated\n'
        'publication snapshot. Current finite-join qualification has its own reader\n'
        'below. Historical replay does not supply current semantic currency. Visual\nQA is pending.',
        'unique source-model historical publication role')
    chapter = replace_once(chapter,
        'it does not establish a new native stack. Complete API/helper/native frame joins\n'
        'and public formatter, coordinate and address contracts remain separate work.',
        'it does not establish a new native stack. Own frame joins are qualified above;\n'
        'public formatter, coordinate and address contracts remain separate work.',
        'unique source-model native qualification boundary')
    chapter = replace_once(chapter, '[portable replay repair](', GUIDE + '[portable replay repair](',
                           'unique full publication guide insertion')
    return dict(revision=REVISION, before_card=before_card, card=card,
                before_chapter=before_chapter, chapter=chapter)


def protected(chapter):
    start = chapter.index('The complete own parser context replay')
    return chapter[start:chapter.index('[portable replay repair](', start)]


def source_proof():
    proposal = transform()
    before = {p: raw for p, raw in committed('docs/knowledge').items() if p.endswith('.md')}
    after = {**before, CARD: proposal['card'].encode()}
    book = {p: raw for p, raw in committed('docs/book/src').items() if p.endswith('.md')}
    new_book = {**book, CHAPTER: proposal['chapter'].encode()}
    declaration = next(row for row in map(json.loads, git(REGISTRY).decode().splitlines())
                       if row.get('surface_id') == 'knowledge_cards')
    within(metrics(after), declaration)
    require(set(before) == set(after) and all(after[p] == raw for p, raw in before.items() if p != CARD),
            'complete unchanged other card population')
    require(metrics(after)['lines_total'] - metrics(before)['lines_total'] == 2,
            'exact bounded two-LF question and fact extension')
    meta = old['previous']['source_reader'].prior.metadata()
    old_rows = meta.allocation({CARD: proposal['before_card'].encode()})['rows'].splitlines()
    new_rows = meta.allocation({CARD: proposal['card'].encode()})['rows'].splitlines()
    expected_new = QUESTION + '\tisf-record-output-source-contexts\t' + CARD
    require(set(new_rows) == set(old_rows) | {expected_new} and len(new_rows) == len(old_rows) + 1,
            'complete preserved question identities and unique join question')
    keys = ('files', 'lines_total', 'bytes_total')
    return dict(collection_before=metrics(before), collection_after=metrics(after),
        collection_member_roots=dict(before=identity(json.dumps(pins(before), sort_keys=True).encode()),
                                     after=identity(json.dumps(pins(after), sort_keys=True).encode())),
        book_before={k: metrics(book)[k] for k in keys},
        book_delta={k: metrics(new_book)[k] - metrics(book)[k] for k in keys},
        book_member_roots=dict(before=identity(json.dumps(pins(book), sort_keys=True).encode()),
                               after=identity(json.dumps(pins(new_book), sort_keys=True).encode())),
        summary_identity=identity(book['docs/book/src/SUMMARY.md']),
        questions_before=old_rows, questions_after=new_rows,
        source_models_identity=identity((CONTEXT / 'proofs.json').read_bytes()),
        fact_role='Finite own source/visible context joins qualified by complete authenticated root replay; broader native meanings remain open.')


def within(census, surface):
    original = next(row for row in map(json.loads, git(REGISTRY).decode().splitlines())
                    if row.get('surface_id') == 'knowledge_cards')
    require(same(surface, original), 'whole unchanged physical card authority')
    require(set(census) == set(original['baseline']), 'complete physical card census dimensions')
    for key, value in census.items():
        require(type(value) is int and value >= 0 and
                value <= min(original['baseline'][key] + original['transition']['max_growth'][key],
                             original['enforcement_ceilings'][key]), 'physical card kind/allowance: ' + key)
    require(census['line_bytes_each'] <= 819, 'canonical public card content-line cap')


def current_input():
    queries = {}
    for role, options in (('direct', ['--all', '--no-cache']), ('cached', ['--all'])):
        command = ['knowledge-map/scripts/query_knowledge_map.sh', *options]
        result = subprocess.run(command, capture_output=True, text=True)
        queries[role] = dict(command=command, status=result.returncode,
                             stdout=result.stdout, stderr=result.stderr)
    surface = next(row for row in map(json.loads, Path(REGISTRY).read_text().splitlines())
                   if row.get('surface_id') == 'knowledge_cards')
    return dict(card=Path(CARD).read_text(), chapter=Path(CHAPTER).read_text(),
                queries=queries, census=metrics(collection()), surface=surface)


def check_current(record):
    proposal = transform()
    require(record['card'] == proposal['card'], 'whole preserved source facts and finite-join meanings/routes')
    require(record['chapter'].count(protected(proposal['chapter'])) == 1,
            'unique complete source/current/snapshot publication guide')
    require(record['chapter'].count(COMMAND) == 1, 'unique full publication current command')
    within(record['census'], record['surface'])
    require(set(record['queries']) == {'direct', 'cached'}, 'complete full publication query roles')
    expected = source_proof()['questions_after']
    wanted = {row.split('\t')[0] for row in expected}
    for role, result in record['queries'].items():
        require(type(result['status']) is int and result['status'] == 0,
                'actual publication query integer success')
        options = ['--all', '--no-cache'] if role == 'direct' else ['--all']
        require(result['command'] == ['knowledge-map/scripts/query_knowledge_map.sh', *options],
                'actual distinct direct/cache query command roles')
        rows = []
        for row in result['stdout'].splitlines():
            fields = row.split('\t')
            require(len(fields) == 3, 'whole actual publication query row grammar')
            if fields[0] in wanted or 'isf-record-output-source-contexts' in fields[1].split(','):
                rows.append(row)
        require(sorted(rows) == sorted(expected), 'complete current prior/join question ownership')


def controls(record):
    checks = [
        ('lost-prior-source-fact', lambda r: r.update(card=r['card'].replace('nearest formal/local/drive masks', 'outer masks')), 'whole preserved source facts and finite-join meanings/routes'),
        ('borrowed-join-assurance', lambda r: r.update(card=r['card'].replace('no throw frames', 'active throw frames')), 'whole preserved source facts and finite-join meanings/routes'),
        ('invented-native-false-encoding', lambda r: r.update(card=r['card'].replace('not native encoding', 'the native encoding')), 'whole preserved source facts and finite-join meanings/routes'),
        ('lost-source-evidence', lambda r: r.update(card=r['card'].replace('  t/2031-isf-record-output-source-contexts.t;\n', '')), 'whole preserved source facts and finite-join meanings/routes'),
        ('lost-prior-question', lambda r: r.update(card=r['card'].replace('  - "which source checks must run for an output-only record actor?"\n', '')), 'whole preserved source facts and finite-join meanings/routes'),
        ('borrowed-question-owner', lambda r: r['queries']['direct'].update(stdout=r['queries']['direct']['stdout'].replace(QUESTION+'\tisf-record-output-source-contexts\t', QUESTION+'\trecord-value-original-observer-helper-paths\t')), 'complete current prior/join question ownership'),
        ('Boolean-query-status', lambda r: r['queries']['cached'].update(status=True), 'actual publication query integer success'),
        ('float-query-status', lambda r: r['queries']['direct'].update(status=0.0), 'actual publication query integer success'),
        ('borrowed-cached-query-command', lambda r: r['queries']['cached'].update(command=r['queries']['direct']['command']), 'actual distinct direct/cache query command roles'),
        ('wrong-current-reader-guide', lambda r: r.update(chapter=r['chapter'].replace(COMMAND, COMMAND.removesuffix(' --current'))), 'unique complete source/current/snapshot publication guide'),
        ('Boolean-physical-files', lambda r: r['census'].update(files=True), 'physical card kind/allowance: files'),
        ('float-physical-lines', lambda r: r['census'].update(lines_total=float(r['census']['lines_total'])), 'physical card kind/allowance: lines_total'),
        ('missing-physical-dimension', lambda r: r['census'].pop('bytes_total'), 'complete physical card census dimensions'),
        ('unadmitted-new-card', lambda r: r['census'].update(files=r['census']['files']+1), 'physical card kind/allowance: files'),
        ('widened-physical-allowance', lambda r: r['surface']['transition']['max_growth'].update(files=111), 'whole unchanged physical card authority'),
    ]
    receipts = []
    for name, mutate, cause in checks:
        changed = copy.deepcopy(record)
        mutate(changed)
        require(not same(changed, record), 'genuine publication intervention: ' + name)
        try:
            check_current(changed)
        except ValueError as error:
            require(str(error) == cause, 'intended publication refusal: ' + name)
            receipts.append(dict(control=name, status=1, cause=str(error)))
        else:
            raise ValueError('false-green publication control: ' + name)
    return receipts


class Visible(HTMLParser):
    def __init__(self):
        super().__init__()
        self.parts, self.codes, self.code = [], [], None

    def handle_starttag(self, tag, attributes):
        if tag == 'code':
            self.code = []

    def handle_data(self, data):
        self.parts.append(data)
        if self.code is not None:
            self.code.append(data)

    def handle_endtag(self, tag):
        if tag == 'code' and self.code is not None:
            self.codes.append(''.join(self.code).strip())
            self.code = None


def rendered(html):
    parser = Visible()
    parser.feed(html)
    require(parser.codes.count(COMMAND) == 1, 'native exact publication current command')
    text = ' '.join(' '.join(parser.parts).split())
    require(' '.join(GUIDE.replace('```bash\n', '').replace('```\n', '').replace('`', '').split()) in text,
            'native complete publication source/current/snapshot guide')


def native_proof(html):
    rendered(html)
    receipts = []
    for name, before, after, cause in (
        ('extra-current-argument', COMMAND, COMMAND + ' --borrowed', 'native exact publication current command'),
        ('borrowed-live-currency', 'snapshot success cannot', 'snapshot success can', 'native complete publication source/current/snapshot guide'),
        ('invented-reference-identity', 'prefixes do not qualify', 'prefixes qualify', 'native complete publication source/current/snapshot guide'),
    ):
        changed = html.replace(before, after)
        require(changed != html, 'genuine native publication control: ' + name)
        try:
            rendered(changed)
        except ValueError as error:
            require(str(error) == cause, 'intended native publication refusal: ' + name)
            receipts.append(dict(control=name, status=1, cause=str(error)))
        else:
            raise ValueError('false-green native publication: ' + name)
    return dict(native_identity=identity(html.encode()), controls=receipts, visual_QA='pending; separately owned')


def verify_recoveries():
    first = module(BASE / 'initial-guide-reader.py.txt')
    first_record = load(BASE / 'initial-current-input.json')
    first['check_current'](first_record)
    require(same(first['controls'](first_record), load(BASE / 'initial-current-controls.json'))
            and same(first['source_proof'](), load(BASE / 'initial-source-proof.json')),
            'whole independently regenerated first current/source products')
    html = (BASE / 'initial-guide-book.html').read_text()
    require(same(first['native_proof'](html), load(BASE / 'initial-native-proof.json')),
            'whole independently regenerated first native guide success')
    try:
        rendered(html)
    except ValueError as error:
        repair = load(BASE / 'guard-guide-repair.json')
        require(str(error) == repair['cause'] == 'native exact publication current command'
                and type(repair['first_predicate_status']) is int and repair['first_predicate_status'] == 0
                and type(repair['qualified_predicate_status']) is int and repair['qualified_predicate_status'] == 1
                and same(repair['initial_programme'], identity((BASE / 'initial-guide-reader.py.txt').read_bytes()))
                and same(repair['initial_native_identity'], identity(html.encode())),
                'complete first displayed-command diagnosis')
    else:
        raise ValueError('false-green retained first native command')
    prior = load(BASE / 'prior-current-refusal.json')
    require(type(prior['status']) is int and prior['status'] == 1 and prior['restored'] is True
            and prior['before'][CARD] == transform()['before_card']
            and prior['before'][CHAPTER] == transform()['before_chapter']
            and prior['candidate']['card'] == first['transform']()['card']
            and prior['candidate']['chapter'] == first['transform']()['chapter']
            and same(prior['programme_identity'], identity(Path('docs/audits/record-value-parser-path-models-20261006/publication.py').read_bytes())),
            'complete actual prior-current refusal source/candidate/restoration identity')
    try:
        old['check_current'](first_record)
    except ValueError as error:
        require(str(error) == 'whole prior qualified source-context body'
                and 'ValueError: ' + str(error) in prior['stderr'], 'actual prior source-current refusal cause')
    else:
        raise ValueError('false-green superseded source-only current role')
    progress = load(BASE / 'unrelated-progress.json')
    require(type(progress['status']) is int and progress['status'] == 0 and progress['restored'] is True
            and type(progress['authority']['status']) is int and progress['authority']['status'] == 0
            and progress['before'][CARD] == transform()['card']
            and progress['before'][CHAPTER] == transform()['chapter'],
            'complete actual unrelated current/authority/restoration result')
    expected_book = {p: raw for p, raw in committed('docs/book/src').items() if p.endswith('.md')}
    expected_book[CHAPTER] = transform()['chapter'].encode()
    expected_book['docs/book/src/00-introduction.md'] = progress['candidates']['docs/book/src/00-introduction.md'].encode()
    surface = next(row for row in map(json.loads, progress['candidates'][REGISTRY].splitlines())
                   if row.get('surface_id') == 'shipped_behavior')
    proof = source_proof()
    require(same(surface['reference_contract']['aggregate_change']['baseline'], proof['book_before'])
            and same(surface['reference_contract']['aggregate_change']['delta'],
                     {k: metrics(expected_book)[k] - proof['book_before'][k] for k in proof['book_before']}),
            'whole independently measured unrelated-progress aggregate authority')
    first_authority = load(BASE / 'first-unrelated-authority-refusal.json')
    require(type(first_authority['status']) is int and first_authority['status'] == 1
            and first_authority['restored'] is True
            and 'surface shipped_behavior aggregate baseline' in first_authority['stderr'],
            'actual first invalid unrelated authority refusal remains unadmitted')


def publish():
    require(not (BASE / 'manifest.json').exists(), 'sealed publication cannot mutate live sources')
    authenticate(replay=False)
    proposal = transform()
    require(Path(CARD).read_text() == proposal['before_card'] and Path(CHAPTER).read_text() == proposal['before_chapter'],
            'whole untouched publication source inputs')
    require(collection() == {p: raw for p, raw in committed('docs/knowledge').items() if p.endswith('.md')},
            'complete original Git-bound physical card population')
    book = {str(p): p.read_bytes() for p in Path('docs/book/src').glob('*.md')}
    require(book == {p: raw for p, raw in committed('docs/book/src').items() if p.endswith('.md')},
            'complete original Git-bound chapter population')
    proof = source_proof()
    lines = Path(REGISTRY).read_text().splitlines()
    for index, line in enumerate(lines):
        row = json.loads(line)
        if row.get('surface_id') == 'shipped_behavior':
            row['reference_contract']['aggregate_change'] = dict(
                authority_id='PARSER-PATH-PUBLICATION-20261006-SHIPPED-BEHAVIOR', owner=OWNER,
                baseline=proof['book_before'], delta=proof['book_delta'],
                rationale='Publish full finite own joins and preserve source/current/snapshot qualification roles and wider native limits.')
            lines[index] = json.dumps(row, sort_keys=True, separators=(',', ':'))
    Path(CARD).write_text(proposal['card'])
    Path(CHAPTER).write_text(proposal['chapter'])
    Path(REGISTRY).write_text('\n'.join(lines)+'\n')
    save('publication.json', proposal)
    save('source-proof.json', proof)
    print('PASS bounded full parser path publication within unchanged physical authority.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--publish', action='store_true')
    parser.add_argument('--current', action='store_true')
    parser.add_argument('--build')
    parser.add_argument('--seal', action='store_true')
    args = parser.parse_args()
    if args.publish:
        require(not args.current and not args.build and not args.seal, 'exclusive publication mutation role')
        publish()
        return
    receipts = authenticate()
    save('prerequisite-replays.json', receipts)
    save('publication.json', transform())
    save('source-proof.json', source_proof())
    verify_recoveries()
    record = current_input() if args.current else load(BASE / 'current-input.json')
    check_current(record)
    saved = load(BASE / 'current-input.json') if (BASE / 'current-input.json').exists() else record
    check_current(saved)
    save('current-input.json', saved)
    save('current-controls.json', controls(saved))
    if args.build:
        command = ['python3', '-B', 'scripts/book_source_references.py', '--check', '--verify-build', args.build]
        result = subprocess.run(command, capture_output=True, text=True)
        require(result.returncode == 0, 'complete current native source-copy contracts')
        html = (Path(args.build) / '13k-isf-feature-support-matrix.html').read_text()
        rendered(html)
        if not (BASE / 'book-input.html').exists():
            require(not (BASE / 'manifest.json').exists(), 'sealed publication cannot save native input')
            (BASE / 'book-input.html').write_text(html)
    if (BASE / 'book-input.html').exists():
        save('book-proofs.json', native_proof((BASE / 'book-input.html').read_text()))
    if args.seal:
        save('manifest.json', members())
    print('PASS complete parser source/visible/context joins with scoped current facts, queries and saved snapshot; broader native meanings remain open.')


if __name__ == '__main__':
    main()

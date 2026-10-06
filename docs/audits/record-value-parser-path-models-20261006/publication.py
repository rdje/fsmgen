"""Scoped current source meanings; historical publication is not live currency."""
import copy
import json
import io
import tarfile
from functools import lru_cache
import subprocess
from html.parser import HTMLParser
from pathlib import Path

ns = {'__name__': 'parser_path_publication_prerequisite'}
BASE = Path('docs/audits/record-value-parser-path-models-20261006')
exec(compile((BASE / 'verify.py').read_bytes(), str(BASE / 'verify.py'), 'exec'), ns)
require, same, identity, save, load = (ns[k] for k in ('require', 'same', 'identity', 'save', 'load'))
previous = ns['module'](ns['PUBLICATION'] / 'verify.py')
CARD, CHAPTER, REGISTRY = (previous[k] for k in ('CARD', 'CHAPTER', 'REGISTRY'))
OWNER = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.2.2.2.4.2'
COMMAND = 'python3 -B docs/audits/record-value-parser-path-models-20261006/verify.py --current'
FACT = '''Finite source models distinguish the original refused paths: list actor-port
admission stops before record contexts; output-field writes reach the write guard.
Complete positional/named roles identify supplied source expressions. Receiver,
normalized AST and partial-actor payloads remain unmeasured. Returned callees are
excluded from active own ancestry. Complete nested API allocations reuse dated
source-family proofs; native/API/helper frame matching remains separate.
'''
GUIDE = '''The finite source models now distinguish active own ancestors from returned
delegates. List actor-port admission stops at the aggregate type guard before
record-context validation. Output-field admission reaches the transaction write
guard before assignment RHS validation or actor publication. Both models retain
every supplied positional and named argument role as a source expression.

Receiver, normalized AST and whole partial-actor payloads remain unmeasured.
The independently evaluated original Perl guards agree with the finite model.
Complete nested API membership reuses the dated qualified source-family models;
it does not establish a new native stack. Complete API/helper/native frame joins
and public formatter, coordinate and address contracts remain separate work.

The scoped current reader preserves all qualified prior and new source meanings,
question ownership, source guidance and physical collection bounds. Historical
publication replay remains distinct from current semantic qualification. Visual
QA is pending.

'''


def git(path):
    return subprocess.check_output(['git', 'show', ns['REVISION'] + ':' + path])


@lru_cache(maxsize=None)
def git_members(root):
    raw = subprocess.check_output(['git', 'archive', ns['REVISION'], root])
    with tarfile.open(fileobj=io.BytesIO(raw), mode='r:') as archive:
        return {entry.name: archive.extractfile(entry).read() for entry in archive.getmembers()
                if entry.isfile() and Path(entry.name).parent == Path(root) and entry.name.endswith('.md')}


def source_proof():
    proposal = transform(); before = git_members('docs/knowledge'); after = {**before, CARD: proposal['card'].encode()}
    book = git_members('docs/book/src'); new_book = {**book, CHAPTER: proposal['chapter'].encode()}
    keys = ['files', 'lines_total', 'bytes_total']; baseline = {k: previous['metrics'](book)[k] for k in keys}
    actual = {k: previous['metrics'](new_book)[k] for k in keys}
    return {'collection_before': previous['metrics'](before), 'collection_after': previous['metrics'](after),
        'book_before': baseline, 'book_after': actual, 'book_delta': {k: actual[k]-baseline[k] for k in keys},
        'collection_members_before': identity(json.dumps({p: identity(raw) for p, raw in before.items()}, sort_keys=True).encode()),
        'collection_members_after': identity(json.dumps({p: identity(raw) for p, raw in after.items()}, sort_keys=True).encode()),
        'book_members_before': identity(json.dumps({p: identity(raw) for p, raw in book.items()}, sort_keys=True).encode()),
        'book_members_after': identity(json.dumps({p: identity(raw) for p, raw in new_book.items()}, sort_keys=True).encode()),
        'member_proof_role': 'Full raw Git-derived populations reconstruct on every replay; typed identity roots bind every member/name/byte identity without duplicating earlier complete maps.',
        'summary': book['docs/book/src/SUMMARY.md'].decode()}


def body(card):
    require(card.startswith('---\n') and card.count('\n---\n') == 1, 'complete fact metadata/body grammar')
    return card.split('\n---\n', 1)[1]


def transform():
    before_card, before_chapter = git(CARD).decode(), git(CHAPTER).decode()
    old_command = 'docs/audits/record-value-parser-source-publication-20261005/verify.py --current'
    new_command = 'docs/audits/record-value-parser-path-models-20261006/verify.py --current'
    require(before_card.count(old_command) == before_chapter.count(old_command) == 1, 'unique previous current reader routes')
    card = before_card.replace(old_command, new_command).replace('evidence: >-\n',
        'evidence: >-\n  docs/audits/record-value-parser-path-models-20261006/scope.txt;\n')
    card = card.rstrip() + '\n\n' + FACT
    chapter = before_chapter.replace(old_command, new_command).replace(
        'does not establish active failure paths or native argument meanings; independent\n'
        'path models and complete API/helper/frame joins remain subsequent work.',
        'does not establish active failure paths or native argument meanings. The finite\n'
        'source models below qualify own ancestry and argument roles; complete\n'
        'API/helper/native frame joins remain separate work.')
    marker = '[portable replay repair]('
    require(chapter.count(marker) == 1, 'unique source-model guide insertion boundary')
    chapter = chapter.replace(marker, GUIDE + marker)
    return {'before_card': before_card, 'card': card, 'before_chapter': before_chapter,
            'chapter': chapter, 'fact': FACT, 'guide': GUIDE, 'revision': ns['REVISION']}


def protected_guide(chapter):
    start = chapter.index('The original parser source inventory binds')
    end = chapter.index('[portable replay repair](', start)
    return chapter[start:end]


def query_inputs():
    result = {}
    for role, options in [('direct', ['--all', '--no-cache']), ('cached', ['--all'])]:
        r = subprocess.run(['knowledge-map/scripts/query_knowledge_map.sh', *options], capture_output=True, text=True)
        result[role] = {'status': r.returncode, 'stdout': r.stdout, 'stderr': r.stderr}
    return result


def current_input():
    return {'card': Path(CARD).read_text(), 'chapter': Path(CHAPTER).read_text(), 'queries': query_inputs(),
            'census': previous['metrics'](previous['collection']()), 'surface': previous['declaration']()}


def check_current(record):
    proposal = transform(); card = record['card']; chapter = record['chapter']
    # Protect the complete qualified prior body and new source block, not an
    # unrelated whole-card epoch. Extra progress has no assurance from this
    # reader; only these explicitly scoped facts/questions are qualified here.
    require(body(card).startswith(body(proposal['before_card'])), 'whole prior qualified source-context body')
    require(card.count(FACT) == 1, 'whole new qualified source-model meaning')
    meta = previous['source_reader'].prior.metadata()
    for field in ['id:', 'title:', 'date:', 'status:', 'tags:']:
        original = next(line for line in proposal['before_card'].splitlines() if line.startswith(field))
        require(card.splitlines().count(original) == 1, 'complete stable fact identity/status/date/tags')
    old_rows = meta.allocation({CARD: proposal['before_card'].encode()})['rows'].splitlines()
    rows = meta.allocation({CARD: card.encode()})['rows'].splitlines()
    require(all(row in rows for row in old_rows), 'complete stable prior source question identities')
    # Ordered metadata questions are preserved, even when subsequent qualified
    # work adds another question outside the present reader scope.
    old_questions = proposal['before_card'].split('answers:\n', 1)[1].split('\ndate:', 1)[0]
    require(card.split('answers:\n', 1)[1].split('\ndate:', 1)[0].startswith(old_questions),
            'whole ordered prior source questions')
    old_evidence = proposal['before_card'].split('evidence: >-\n', 1)[1].split('reverify: >-', 1)[0]
    require(old_evidence in card, 'whole prior fact evidence routes')
    verification_prefix = proposal['card'].split('reverify: >-\n', 1)[1].split('\n---\n', 1)[0]
    require(card.split('reverify: >-\n', 1)[1].split('\n---\n', 1)[0].startswith(verification_prefix),
            'whole prior source-context tests and current verification prefix')
    require(card.count(COMMAND.removeprefix('python3 -B ')) == 1, 'unique current fact reader route')
    require(chapter.count(protected_guide(proposal['chapter'])) == 1 and chapter.count(COMMAND) == 1, 'unique complete current source-model guide')
    previous['within'](record['census'], record['surface'])
    require(set(record['queries']) == {'direct', 'cached'}, 'complete current source-model query roles')
    target = meta.metadata(card.encode())[0]
    expected = sorted(old_rows)
    for r in record['queries'].values():
        require(type(r['status']) is int and r['status'] == 0, 'actual current source-model query integer status')
        wanted_questions = {row.split('\t')[0] for row in old_rows}
        actual = []
        for row in r['stdout'].splitlines():
            fields = row.split('\t'); require(len(fields) == 3, 'actual source-model query row grammar')
            if fields[0] in wanted_questions:
                actual.append(row)
        require(sorted(actual) == expected and all(target in r.split('\t')[1].split(',') for r in actual),
                'complete scoped old question current ownership')


def controls(record):
    output = []
    changes = [
        ('lost-prior-body', lambda r: r.update(card=r['card'].replace('actor_has_record_port', 'actor_has_record_input', 1)), 'whole prior qualified source-context body'),
        ('lost-prior-evidence', lambda r: r.update(card=r['card'].replace('  t/2031-isf-record-output-source-contexts.t;\n', '')), 'whole prior fact evidence routes'),
        ('lost-prior-test-command', lambda r: r.update(card=r['card'].replace('  t/2030-isf-record-output-writer-admission.t\n', '')), 'whole prior source-context tests and current verification prefix'),
        ('invented-native-assurance', lambda r: r.update(card=r['card'].replace('payloads remain unmeasured', 'payloads are measured')), 'whole new qualified source-model meaning'),
        ('missing-ordered-question', lambda r: r.update(card=r['card'].replace('  - "which source checks must run for an output-only record actor?"\n', '')), 'complete stable prior source question identities'),
        ('Boolean-query-status', lambda r: r['queries']['direct'].update(status=False), 'actual current source-model query integer status'),
        ('borrowed-query-ID', lambda r: r['queries']['direct'].update(stdout=r['queries']['direct']['stdout'].replace('\tisf-record-output-source-contexts\t', '\trecord-value-original-parser-source-inventory\t')), 'complete scoped old question current ownership'),
        ('wrong-reader-guide', lambda r: r.update(chapter=r['chapter'].replace(COMMAND, COMMAND.replace(' --current', ''))), 'unique complete current source-model guide'),
        ('excess-cardinality', lambda r: r['census'].update(files=1261), 'knowledge-card unchanged physical allowance'),
    ]
    for name, mutate, cause in changes:
        bad = copy.deepcopy(record); mutate(bad)
        require(not same(bad, record), 'genuine intended current source-model control: ' + name)
        try:
            check_current(bad)
        except ValueError as error:
            # Capacity's own independently declared checker supplies its
            # precise dimension refusal, rather than a guessed local message.
            if name == 'excess-cardinality':
                require('files' in str(error) and 'allowance' in str(error), 'intended physical cardinality refusal')
            else:
                require(str(error) == cause, 'intended current source-model control cause: ' + name)
            output.append({'control': name, 'status': 1, 'error': str(error)})
        else:
            raise ValueError('false-green current source-model control: ' + name)
    return output


class Visible(HTMLParser):
    def __init__(self):
        super().__init__(); self.parts = []

    def handle_data(self, data):
        self.parts.append(data)


def rendered(html):
    parser = Visible(); parser.feed(html)
    text = ' '.join(' '.join(parser.parts).split())
    require(text.count(COMMAND) == 1, 'native unique current source-model command')
    section = '\n'.join(line for line in protected_guide(transform()['chapter']).splitlines() if not line.startswith('```'))
    require(' '.join(section.replace('`', '').split()) in text, 'native complete source-model scope and missing legs')


def verify(current=False, build=None):
    proposal = transform(); save('publication.json', proposal); save('source-proof.json', source_proof())
    record = current_input() if current else load(BASE / 'current-input.json')
    check_current(record)
    saved = load(BASE / 'current-input.json') if (BASE / 'current-input.json').exists() else record
    check_current(saved); save('current-input.json', saved); save('current-controls.json', controls(saved))
    initial = ns['module'](BASE / 'initial-published-programme.py.txt')
    require(same(initial['source_proof'](), load(BASE / 'initial-source-proof.json')), 'whole preserved first independently reconstructed source epoch')
    first = copy.deepcopy(saved); first['chapter'] = initial['transform']()['chapter']
    initial['check_current'](first)
    try:
        check_current(first)
    except ValueError as error:
        require(str(error) == 'unique complete current source-model guide', 'first source-guide defect independently refuses')
        recovery = {'programme': identity((BASE / 'initial-published-programme.py.txt').read_bytes()),
                    'first_chapter': identity(first['chapter'].encode()), 'initial_predicate_status': 0,
                    'qualified_predicate_status': 1, 'error': str(error),
                    'scope': 'Exact first current predicate accepts the awkward transition; whole protected source-section qualification refuses it while all other current inputs conserve.'}
    else:
        raise ValueError('false-green original source-guide recovery')
    save('source-guide-recovery.json', recovery)

    if build is not None:
        html = (Path(build) / '13k-isf-feature-support-matrix.html').read_text()
        rendered(html)
        path = BASE / 'book-input.html'
        if path.exists():
            require(path.read_text() == html, 'whole saved native source-model guide rendering')
        else:
            require(not (BASE / 'manifest.json').exists(), 'sealed model publisher cannot save rendering')
            path.write_text(html)
    if (BASE / 'book-input.html').exists():
        html = (BASE / 'book-input.html').read_text(); rendered(html)
        rejects = []
        for name, before, after, cause in [
            ('native-wrong-reader-role', COMMAND, COMMAND.replace(' --current', ''), 'native unique current source-model command'),
            ('native-invented-payload-measurement', 'payloads remain unmeasured', 'payloads are measured', 'native complete source-model scope and missing legs')]:
            bad = html.replace(before, after); require(bad != html, 'genuine native source-model control')
            try:
                rendered(bad)
            except ValueError as error:
                require(str(error) == cause, 'intended native source-model control cause')
                rejects.append({'control': name, 'status': 1, 'error': str(error)})
            else:
                raise ValueError('false-green native source-model control')
        save('book-proofs.json', {'whole_rendered': identity(html.encode()), 'controls': rejects})


def publish():
    require(not (BASE / 'manifest.json').exists(), 'sealed parser model publisher cannot mutate live facts')
    proposal = transform(); require(Path(CARD).read_text() == proposal['before_card'] and
                                   Path(CHAPTER).read_text() == proposal['before_chapter'], 'untouched whole prepublication source inputs')
    before = git_members('docs/knowledge'); after = {**before, CARD: proposal['card'].encode()}
    require(previous['collection']() == before, 'whole independently Git-bound prepublication card population')
    previous['within'](previous['metrics'](after), previous['declaration']())
    book = git_members('docs/book/src')
    require({str(p): p.read_bytes() for p in Path('docs/book/src').glob('*.md')} == book,
            'whole independently Git-bound prepublication book population')
    proof = source_proof(); save('source-proof.json', proof)
    keys = ['files', 'lines_total', 'bytes_total']; baseline = proof['book_before']; actual = proof['book_after']
    Path(CARD).write_text(proposal['card']); Path(CHAPTER).write_text(proposal['chapter'])
    lines = Path(REGISTRY).read_text().splitlines()
    for index, line in enumerate(lines):
        row = json.loads(line)
        if row.get('surface_id') == 'shipped_behavior':
            row['reference_contract']['aggregate_change'] = {'authority_id': 'PARSER-PATH-MODELS-20261006-SHIPPED-BEHAVIOR',
                'owner': OWNER, 'baseline': baseline, 'delta': {k: actual[k]-baseline[k] for k in keys},
                'rationale': 'Publish finite source guard/ancestry/argument role models with explicit native and payload gaps.'}
            lines[index] = json.dumps(row, sort_keys=True, separators=(',', ':'))
    Path(REGISTRY).write_text('\n'.join(lines)+'\n')
    print('PASS unchanged-authority bounded parser source-model publication')

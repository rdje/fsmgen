"""Supersede the unadmitted new-card proposal within the existing source topic."""
import argparse
import copy
import hashlib
import importlib.util
import json
import re
import subprocess
from html.parser import HTMLParser
from pathlib import Path

BASE = Path('docs/audits/record-value-parser-source-publication-20261005')
SOURCE = Path('docs/audits/record-value-original-parser-sources-20261005')
REVISION = 'e11d97f0c79c22c240243350a27e000a13bc6243'
OWNER = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.2.2.2.4.1'
CARD = 'docs/knowledge/isf-record-output-source-contexts.md'
WITHDRAWN = 'docs/knowledge/record-value-original-parser-source-inventory.md'
CHAPTER = 'docs/book/src/13k-isf-feature-support-matrix.md'
REGISTRY = 'doctrine/live_document_size/surfaces.jsonl'
QUESTIONS = ['what inventories original parser refusal source bodies?', 'does the original parser source inventory qualify active native paths?']
BLOCK = '''The original parser source inventory binds complete own facade, parser and
record-context source units, lexical declarations, selected whole function bodies,
parameter roles and ordered call/guard statements. Output-field source admission
and aggregate actor-port admission have distinct source boundaries. This inventory
does not establish active failure paths or native argument meanings; independent
path models and complete API/helper/frame joins remain subsequent work.

The initial new-card proposal exceeded the collection file allowance and was
withdrawn. Its complete source proof and candidate publication remain immutable.
The qualified provenance now extends the existing source-context topic while
preserving its prior body, identity, questions and verification command. The
current reader additionally checks all physical collection dimensions:

```bash
python3 -B docs/audits/record-value-parser-source-publication-20261005/verify.py --current
```

The original source reader defaults to historical replay; its withdrawn live
proposal is not current authority. This publication reader separates that source
proof from live fact, query, capacity and guide checks. Framework/display,
coordinates, native identity and broader consumer/alias/cold meanings remain
separately owned. Visual QA is pending.

'''


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    result = importlib.util.module_from_spec(spec); spec.loader.exec_module(result)
    return result


source_reader = module('superseding_parser_source', SOURCE / 'verify.py')
source_pub = module('withdrawn_parser_source_proposal', SOURCE / 'publication.py')
require, same, identity = source_reader.require, source_reader.same, source_reader.identity


def load(path):
    return json.loads(path.read_text())


def save(name, product):
    path = BASE / name
    if path.exists():
        require(same(load(path), product), 'whole superseding parser publication product: ' + name)
    else:
        require(not (BASE / 'manifest.json').exists(), 'sealed superseding publication cannot publish')
        path.write_text(json.dumps(product, sort_keys=True, indent=2) + '\n')


def git(path):
    return subprocess.check_output(['git', 'show', REVISION + ':' + path])


def metrics(blobs):
    values = list(blobs.values())
    return {'files': len(values), 'lines_total': sum(v.count(b'\n') for v in values), 'bytes_total': sum(map(len, values)),
            'lines_each': max(v.count(b'\n') for v in values), 'bytes_each': max(map(len, values)),
            'line_bytes_each': max(len(line.rstrip(b'\r')) for v in values for line in v.split(b'\n'))}


def collection():
    paths = sorted(Path('docs/knowledge').glob('*.md'))
    require(all(path.is_file() and not path.is_symlink() and path.stat().st_dev == Path('.').stat().st_dev for path in paths),
            'current canonical card nodes are regular same-volume files')
    return {str(path): path.read_bytes() for path in paths}


def declaration():
    return next(row for row in map(json.loads, Path(REGISTRY).read_text().splitlines()) if row.get('surface_id') == 'knowledge_cards')


def within(census, surface):
    original = next(row for row in map(json.loads, git(REGISTRY).decode().splitlines()) if row.get('surface_id') == 'knowledge_cards')
    require(same(surface, original), 'whole knowledge-card authority unchanged')
    for key, value in census.items():
        require(type(value) is int and type(surface['baseline'][key]) is int and
                value <= surface['baseline'][key] + surface['transition']['max_growth'][key] and
                value <= surface['enforcement_ceilings'][key], 'current physical card allowance/kind: ' + key)
    require(census['line_bytes_each'] <= 819, 'canonical Knowledge Map card line cap')


def transform():
    before = git(CARD).decode()
    question_lines = ''.join('  - "' + q + '"\n' for q in QUESTIONS)
    after = before.replace('date: 2026-10-01\n', question_lines + 'date: 2026-10-01\n')
    after = after.replace('evidence: >-\n', 'evidence: >-\n  '+str(SOURCE / 'scope.txt')+';\n  '+str(BASE / 'scope.txt')+';\n')
    after = after.replace('  t/1991-isf-record-port-sample-contexts.t\n---',
                          '  t/1991-isf-record-port-sample-contexts.t &&\n  scripts/run_with_ram_guard.sh -- python3 -B\n  '+str(BASE / 'verify.py')+' --current\n---')
    provenance = source_pub.CARD_TEXT.split('---\n', 2)[2]
    after += '\n## Original parser source inventory\n' + provenance
    require(before.split('---\n', 2)[2] in after, 'whole prior context meaning preserved')
    require(after.count(str(BASE / 'verify.py')+' --current') == 1, 'unique current source-context reverify addition')
    before_chapter = git(CHAPTER).decode()
    require(before_chapter.count(source_pub.MARKER) == 1, 'unique committed superseding book boundary')
    chapter = before_chapter.replace(source_pub.MARKER, BLOCK + source_pub.MARKER)
    return {'before_card': before, 'card': after, 'before_chapter': before_chapter, 'chapter': chapter, 'block': BLOCK,
            'source_provenance': provenance, 'revision': REVISION}


def check_current(card, chapter, queries, census, surface, withdrawn_exists):
    proposal = transform()
    require(card == proposal['card'], 'whole old/new source-context meaning/question/reader epoch')
    require(chapter.count(BLOCK) == 1, 'unique complete superseding source/current/capacity reader guidance')
    require(withdrawn_exists is False, 'unadmitted new-card proposal is absent from live collection')
    within(census, surface)
    require(set(queries) == {'direct', 'cached'}, 'complete superseding current query roles')
    meta = source_reader.prior.metadata()
    expected = meta.allocation({CARD: card.encode()})['rows'].splitlines()
    target = meta.metadata(card.encode())[0]
    all_questions = [row.split('\t')[0] for row in expected]
    for result in queries.values():
        require(type(result['status']) is int and result['status'] == 0, 'actual superseding query integer status')
        rows = []
        for row in result['stdout'].splitlines():
            fields = row.split('\t'); require(len(fields) == 3, 'superseding actual query row grammar')
            if target in fields[1].split(',') or 'record-value-original-parser-source-inventory' in fields[1].split(',') or fields[0] in all_questions:
                rows.append(row)
        require(sorted(rows) == sorted(expected), 'complete old/new question ownership without withdrawn ID')


def current_input():
    queries = {}
    for role, options in (('direct', ['--all', '--no-cache']), ('cached', ['--all'])):
        result = subprocess.run(['knowledge-map/scripts/query_knowledge_map.sh', *options], capture_output=True, text=True)
        queries[role] = {'status': result.returncode, 'stdout': result.stdout, 'stderr': result.stderr}
    return {'card': Path(CARD).read_text(), 'chapter': Path(CHAPTER).read_text(), 'queries': queries,
            'census': metrics(collection()), 'surface': declaration(), 'withdrawn_exists': Path(WITHDRAWN).exists()}


def controls(record):
    check_current(**record)
    receipts = []
    cases = [
        ('lost-old-context', lambda r: r.update(card=r['card'].replace('nearest formal/local/drive masks still apply.', 'source masks are unqualified.')), 'whole old/new source-context meaning/question/reader epoch'),
        ('lost-new-provenance', lambda r: r.update(card=r['card'].replace('Source order records provenance;', 'Trace order supplies intended provenance;')), 'whole old/new source-context meaning/question/reader epoch'),
        ('borrowed-withdrawn-ID', lambda r: r['queries']['direct'].update(stdout=r['queries']['direct']['stdout'].replace(QUESTIONS[0]+'\tisf-record-output-source-contexts\t', QUESTIONS[0]+'\trecord-value-original-parser-source-inventory\t')), 'complete old/new question ownership without withdrawn ID'),
        ('Boolean-status', lambda r: r['queries']['cached'].update(status=False), 'actual superseding query integer status'),
        ('new-card-still-live', lambda r: r.update(withdrawn_exists=True), 'unadmitted new-card proposal is absent from live collection'),
        ('too-many-files', lambda r: r['census'].update(files=1261), 'current physical card allowance/kind: files'),
        ('Boolean-file-count', lambda r: r['census'].update(files=False), 'current physical card allowance/kind: files'),
        ('widened-allowance', lambda r: r['surface']['transition']['max_growth'].update(files=111), 'whole knowledge-card authority unchanged'),
        ('wrong-current-guide', lambda r: r.update(chapter=r['chapter'].replace('parser-source-publication-20261005/verify.py --current', 'original-parser-sources-20261005/verify.py --current')), 'unique complete superseding source/current/capacity reader guidance'),
    ]
    for name, mutate, cause in cases:
        changed = copy.deepcopy(record); mutate(changed)
        require(not same(changed, record), 'genuine superseding publication control: ' + name)
        try:
            check_current(**changed)
        except ValueError as error:
            require(str(error) == cause, 'intended superseding publication control: ' + name)
            receipts.append({'control': name, 'status': 1, 'cause': str(error)})
        else:
            raise ValueError('false-green superseding publication: ' + name)
    changed = copy.deepcopy(record); changed['chapter'] += '\nUnrelated guide prose retains this source inventory.\n'; check_current(**changed)
    return receipts


def authenticate():
    binding = load(BASE / 'binding.json')
    require(set(binding['source_members']) == {p.name for p in SOURCE.iterdir()}, 'whole immutable first source inventory membership')
    for name, pin in binding['source_members'].items():
        require(same(identity((SOURCE / name).read_bytes()), pin), 'whole immutable first source inventory identity')
    failure = load(Path(binding['failed_gate']))
    require(type(failure['status']) is int and failure['status'] == 1 and
            'files is 1261 (> baseline 1150 + growth 110)' in failure['stderr'], 'actual rejected collection proposal capacity')
    require(same(identity(Path(binding['failed_gate']).read_bytes()), binding['failed_gate_identity']), 'whole actual failed admission receipt')
    withdrawn = load(Path(binding['withdrawn_current_reader']))
    require(same(identity(Path(binding['withdrawn_current_reader']).read_bytes()), binding['withdrawn_reader_identity']),
            'whole actual withdrawn current-reader receipt')
    require(type(withdrawn['status']) is int and withdrawn['status'] == 1 and
            withdrawn['command'] == ['python3', '-B', str(SOURCE / 'verify.py'), '--current'] and
            'FileNotFoundError' in withdrawn['stderr'] and WITHDRAWN in withdrawn['stderr'],
            'actual withdrawn proposal cannot supply live current authority')
    result = subprocess.run(['python3', '-B', str(SOURCE / 'verify.py')], capture_output=True, text=True)
    require(type(result.returncode) is int and result.returncode == 0, 'whole historical original source inventory replay')
    if (BASE / 'manifest.json').exists():
        require(same(load(BASE / 'manifest.json'), {p.name: identity(p.read_bytes()) for p in BASE.iterdir() if p.name != 'manifest.json'}),
                'whole superseding publication seal/member/kind identity')


class Text(HTMLParser):
    def __init__(self):
        super().__init__(); self.parts = []

    def handle_data(self, data):
        self.parts.append(data)


def rendered(html):
    mains = re.findall(r'<main\b[^>]*>(.*?)</main>', html, re.S)
    require(len(mains) == 1, 'unique superseding native chapter body')
    parser = Text(); parser.feed(mains[0]); visible = ' '.join(' '.join(parser.parts).split())
    paragraphs = [' '.join(p.split()) for p in BLOCK.replace('```bash\n', '').replace('```\n', '').strip().split('\n\n')]
    require(all(visible.count(p) == 1 for p in paragraphs), 'complete exact rendered source/current/withdrawal/capacity guide')
    return paragraphs


def render_proof(html):
    paragraphs = rendered(html)
    receipts = []
    for name, old, new in [
        ('wrong-current-command', 'parser-source-publication-20261005/verify.py --current', 'original-parser-sources-20261005/verify.py --current'),
        ('lost-withdrawal', 'withdrawn live', 'admitted live'),
    ]:
        changed = html.replace(old, new)
        require(changed != html, 'genuine superseding render control')
        try:
            rendered(changed)
        except ValueError as error:
            require(str(error) == 'complete exact rendered source/current/withdrawal/capacity guide', 'intended superseding rendered boundary')
            receipts.append({'control': name, 'status': 1, 'cause': str(error)})
        else:
            raise ValueError('false-green superseding native guide')
    return {'paragraphs': paragraphs, 'controls': receipts, 'scope': 'Exact native guide; visual QA remains pending.'}


def book_source(build=None):
    paths = [path for path in subprocess.check_output(
        ['git', 'ls-tree', '-r', '--name-only', REVISION, 'docs/book/src'], text=True).splitlines() if path.endswith('.md')]
    before = {path: git(path) for path in paths}
    after = {**before, CHAPTER: transform()['chapter'].encode()}
    baseline = {key: metrics(before)[key] for key in ('files', 'lines_total', 'bytes_total')}
    actual = {key: metrics(after)[key] for key in baseline}
    proof = {'before': baseline, 'after': actual, 'delta': {key: actual[key] - baseline[key] for key in baseline},
             'summary': before['docs/book/src/SUMMARY.md'].decode(), 'paths': paths}
    save('book-source-proof.json', proof)
    if build is not None:
        require(all(Path(path).read_bytes() == raw for path, raw in after.items()), 'whole current superseding book publication source')
        surface = next(row for row in map(json.loads, Path(REGISTRY).read_text().splitlines()) if row.get('surface_id') == 'shipped_behavior')
        authority = surface['reference_contract']['aggregate_change']
        require(authority['owner'] == OWNER and same(authority['baseline'], baseline) and same(authority['delta'], proof['delta']),
                'whole independent superseding book aggregate authority')


def collection_conservation():
    paths = [path for path in subprocess.check_output(
        ['git', 'ls-tree', '-r', '--name-only', REVISION, 'docs/knowledge'], text=True).splitlines()
        if Path(path).parent == Path('docs/knowledge') and path.endswith('.md')]
    before = {path: git(path) for path in paths}
    proposed = {**before, WITHDRAWN: source_pub.CARD_TEXT.encode()}
    after = {**before, CARD: transform()['card'].encode()}
    saved = load(BASE / 'collection-proof.json')
    require(same(saved['before'], metrics(proposed)) and same(saved['after'], metrics(after)),
            'whole independently reconstructed proposed/admitted physical populations')
    product = {'before_members': {path: identity(raw) for path, raw in proposed.items()},
               'after_members': {path: identity(raw) for path, raw in after.items()},
               'scope': 'Complete original members and bytes conserve; only new proposal removal and source-context provenance extension change.'}
    save('collection-members.json', product)
    return after


def publish():
    require(not (BASE / 'manifest.json').exists(), 'sealed superseding publisher cannot mutate live publication')
    authenticate()
    proposal = transform(); before = collection(); surface = declaration()
    require(before[WITHDRAWN].decode() == source_pub.CARD_TEXT and before[CARD].decode() == proposal['before_card'], 'whole untouched proposed/prior live card sources')
    require(Path(CHAPTER).read_text() == source_pub.expected()['after'], 'whole first proposed book source before withdrawal')
    after = {path: raw for path, raw in before.items() if path != WITHDRAWN}; after[CARD] = proposal['card'].encode()
    within(metrics(after), surface)
    save('publication.json', proposal)
    save('collection-proof.json', {'before': metrics(before), 'after': metrics(after), 'surface': surface,
         'withdrawn_bytes': before[WITHDRAWN].decode(), 'scope': 'Whole proposal remains in the immutable source seal; all prior card members and meanings conserve within unchanged limits.'})
    Path(WITHDRAWN).unlink(); Path(CARD).write_text(proposal['card']); Path(CHAPTER).write_text(proposal['chapter'])
    rows = Path(REGISTRY).read_text().splitlines()
    blobs = {str(p): p.read_bytes() for p in Path('docs/book/src').glob('*.md')}; prior = {**blobs, CHAPTER: proposal['before_chapter'].encode()}
    baseline = {k: metrics(prior)[k] for k in ('files','lines_total','bytes_total')}; actual = {k: metrics(blobs)[k] for k in baseline}
    for index, line in enumerate(rows):
        row = json.loads(line)
        if row.get('surface_id') == 'shipped_behavior':
            row['reference_contract']['aggregate_change'] = {'authority_id': 'PARSER-SOURCE-TOPIC-20261005-SHIPPED-BEHAVIOR',
                'owner': OWNER, 'baseline': baseline, 'delta': {k: actual[k]-baseline[k] for k in baseline},
                'rationale': 'Re-home source-qualified provenance in an existing bounded topic; preserve withdrawn proposal as history.'}
            rows[index] = json.dumps(row, sort_keys=True, separators=(',', ':'))
    Path(REGISTRY).write_text('\n'.join(rows)+'\n')
    print('PASS source-faithful existing topic publication after independent unchanged-capacity preflight.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--publish', action='store_true'); parser.add_argument('--current', action='store_true'); parser.add_argument('--build')
    args = parser.parse_args()
    if args.publish:
        require(not args.current and args.build is None, 'publisher and reader roles are separate'); publish(); return
    require(args.current or args.build is None, 'native current guide requires explicit current role')
    authenticate()
    save('publication.json', transform())
    expected_cards = collection_conservation()
    book_source(args.build)
    record = current_input() if args.current else load(BASE / 'current-input.json')
    check_current(**record)
    if args.current and not (BASE / 'current-input.json').exists():
        save('current-input.json', record)
    save('controls.json', controls(record))
    if args.build:
        require(same({path: identity(raw) for path, raw in collection().items()},
                     {path: identity(raw) for path, raw in expected_cards.items()}), 'whole current superseding publication member/byte conservation')
        html = (Path(args.build) / (Path(CHAPTER).stem + '.html')).read_text()
        target = BASE / 'book-input.html'
        if target.exists():
            require(target.read_text() == html, 'exact first superseding native render input')
        else:
            require(not (BASE / 'manifest.json').exists(), 'sealed native render input cannot publish')
            target.write_text(html)
        save('book-proofs.json', render_proof(html))
    elif (BASE / 'manifest.json').exists():
        save('book-proofs.json', render_proof((BASE / 'book-input.html').read_text()))
    if (BASE / 'unrelated-progress.json').exists():
        unrelated = load(BASE / 'unrelated-progress.json')
        require(type(unrelated['status']) is int and unrelated['status'] == 0 and unrelated['restored'] is True and
                unrelated['command'] == ['python3', '-B', str(BASE / 'verify.py'), '--current'], 'actual superseding unrelated progress and restoration')
    else:
        require(not (BASE / 'manifest.json').exists(), 'sealed superseding current reader requires actual unrelated-progress evidence')
    print('PASS original source proof plus '+('current fact/query/guide/physical-capacity roles' if args.current else 'historical source/topic publication; current currency is not established')+'.')


if __name__ == '__main__':
    main()

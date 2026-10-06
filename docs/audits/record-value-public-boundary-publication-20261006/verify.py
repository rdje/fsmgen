"""Authenticate finite public-fact publication; current currency is explicit."""
import argparse
import copy
import hashlib
import io
import json
import subprocess
import tarfile
from functools import lru_cache
from html.parser import HTMLParser
from pathlib import Path

BASE = Path('docs/audits/record-value-public-boundary-publication-20261006')
CHECKS = Path('docs/audits/public-boundary-publication-checks-20261006')
RETENTION = Path('docs/audits/record-value-public-boundary-retention-20261006')
RETAINED_RESULT = Path('docs/audits/public-boundary-retention-checks-20261006')
REVISION = '066a576877e19a020e5ae48a53fe50e216c22543'
OWNER = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.2.2.2.5.4.2.2'
TASK = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
CARD = 'docs/knowledge/record-value-original-observer-helper-paths.md'
ID = 'record-value-original-observer-helper-paths'
CHAPTER = 'docs/book/src/13k-isf-feature-support-matrix.md'
REGISTRY = 'doctrine/live_document_size/surfaces.jsonl'
QUESTION = 'what qualifies original public subtest header and boundary compatibility?'
COMMAND = 'scripts/run_with_ram_guard.sh -- python3 -B ' + str(BASE / 'verify.py') + ' --current'
SUCCESS = 'PASS authenticated finite public-fact publication snapshot and controls; current currency requires --current.\n'
CURRENT_SUCCESS = 'PASS fresh current public facts, direct/cache ownership, unchanged capacity and scoped reader/source roles.\n'
GUIDE = '''The public-boundary fact publication now qualifies the finite original
Test::Builder/Test::More header relationship: authored-name prefixes, CODE kinds
and body/delegate/entry/do-load order match at every retained throw phase.
Independent dated public fixtures select the symbols. Original provider/version,
private eval purposes, formatter/settings, hidden arguments, receiver/callback
contents and identity, class/frame joins, coordinates and addresses remain open.

The canonical observer/helper topic retains every reviewed source fact and prior
question, adding one public-boundary question. Its exact admitted body does not
grow in encoded bytes or line feeds. Collection authority remains unchanged;
this publication supplies no new physical card allowance or healthy-collection
claim. The review is an explicit semantic judgment, not a language oracle.

Current replay checks the exact fact, actual direct/cache question ownership,
all physical capacity dimensions, this scoped guide and current source routes:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-public-boundary-publication-20261006/verify.py --current
```

Default replay authenticates committed prerequisites and the saved publication
snapshot; snapshot success cannot supply live currency. Unrelated book progress
does not invalidate this scoped current reader. An optional
`--build repository-relative-output` checks current native source copies and
rendered guidance. Visual QA remains separately pending.

The retained proposal's default replay still authenticates its source snapshot.
Its `--live-unchanged` pre-publication role now refuses the changed live card.
The superseded own-boundary publication also retains its default snapshot replay;
its old whole-card current role refuses this qualified extension. Use the new
current command above for this observer topic. The tooling companion still
advertises the superseded current role; its immediate owned repair remains
pending before the public publication parent can close. Original programmes
and seals remain unchanged.

'''


def require(value, cause):
    if not value:
        raise ValueError(cause)


def same(a, b):
    return json.dumps(a, sort_keys=True, allow_nan=False) == json.dumps(b, sort_keys=True, allow_nan=False)


def identity(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def load(path):
    return json.loads(path.read_bytes())


def module(path):
    ns = {'__name__': 'publication_prerequisite', '__file__': str(path)}
    exec(compile(path.read_bytes(), str(path), 'exec'), ns)
    return ns


def git(path):
    return subprocess.check_output(['git', 'show', REVISION + ':' + str(path)])


@lru_cache(maxsize=None)
def committed(root):
    raw = subprocess.check_output(['git', 'archive', REVISION, str(root)])
    with tarfile.open(fileobj=io.BytesIO(raw)) as archive:
        return {m.name: archive.extractfile(m).read() for m in archive.getmembers() if m.isfile()}


def whole(root):
    paths = list(root.iterdir())
    require(all(p.is_file() and not p.is_symlink() for p in paths), 'whole regular publication member domain')
    return {str(p): p.read_bytes() for p in paths}


def pins(blobs):
    return {p: identity(raw) for p, raw in sorted(blobs.items())}


def members():
    return {Path(p).name: identity(raw) for p, raw in whole(BASE).items() if Path(p).name != 'manifest.json'}


def save(name, value):
    path = BASE / name
    if path.exists():
        require(same(load(path), value), 'whole saved publication product: ' + name)
    else:
        require(not (BASE / 'manifest.json').exists(), 'sealed publication cannot add products')
        path.write_text(json.dumps(value, sort_keys=True, indent=2) + '\n')


def metrics(blobs):
    values = list(blobs.values())
    return dict(files=len(values), lines_total=sum(v.count(b'\n') for v in values),
        bytes_total=sum(map(len, values)), lines_each=max(v.count(b'\n') for v in values),
        bytes_each=max(map(len, values)),
        line_bytes_each=max(len(line.rstrip(b'\r')) for v in values for line in v.split(b'\n')))


def cards():
    root = Path.cwd()
    paths = list(Path('docs/knowledge').glob('*.md'))
    require(all(p.is_file() and not p.is_symlink() and p.stat().st_dev == root.stat().st_dev for p in paths),
            'complete regular same-volume physical card population')
    return {str(p): p.read_bytes() for p in paths}


def authority(raw):
    return next(json.loads(s) for s in raw.decode().splitlines() if json.loads(s).get('surface_id') == 'knowledge_cards')


def expected_card():
    return load(RETENTION / 'proposal.json')['after']


def queries():
    results = {}
    for role, options in (('direct', ['--all', '--no-cache']), ('cached', ['--all'])):
        command = ['knowledge-map/scripts/query_knowledge_map.sh', *options]
        result = subprocess.run(command, capture_output=True, text=True)
        results[role] = dict(command=command, status=result.returncode, stdout=result.stdout, stderr=result.stderr)
    return results


def target_rows(text):
    wanted = set(module(RETENTION / 'verify.py')['questions'](expected_card()))
    rows = []
    for row in text.splitlines():
        fields = row.split('\t')
        require(len(fields) == 3, 'complete actual query row grammar')
        if fields[0] in wanted or ID in fields[1].split(','):
            rows.append(row)
    return sorted(rows)


def within(census, surface):
    original = authority(git(REGISTRY))
    require(same(surface, original), 'whole unchanged physical card authority')
    require(set(census) == set(original['baseline']), 'complete physical capacity dimensions')
    for key, value in census.items():
        require(type(value) is int and value >= 0 and value <= min(
            original['baseline'][key] + original['transition']['max_growth'][key], original['enforcement_ceilings'][key]),
            'physical capacity kind/allowance: ' + key)


def current_input():
    return dict(card=Path(CARD).read_text(), chapter=Path(CHAPTER).read_text(),
                queries=queries(), census=metrics(cards()), surface=authority(Path(REGISTRY).read_bytes()))


def check_current(record):
    require(record['card'] == expected_card(), 'whole admitted source facts questions identity and route')
    require(record['chapter'].count(GUIDE) == 1 and record['chapter'].count(COMMAND) == 1,
            'unique scoped source/current/snapshot publication guide')
    within(record['census'], record['surface'])
    require(set(record['queries']) == {'direct', 'cached'}, 'complete current direct/cache query roles')
    expected = sorted(q + '\t' + ID + '\t' + CARD for q in module(RETENTION / 'verify.py')['questions'](expected_card()))
    for role, result in record['queries'].items():
        require(type(result['status']) is int and result['status'] == 0, 'actual query integer success')
        command = ['knowledge-map/scripts/query_knowledge_map.sh', '--all'] + (['--no-cache'] if role == 'direct' else [])
        require(result['command'] == command, 'actual distinct direct/cache query command roles')
        require(target_rows(result['stdout']) == expected, 'complete current question ownership')


def authenticate(replay=True):
    binding = load(BASE / 'binding.json')
    require(binding['revision'] == REVISION and binding['owner'] == OWNER.removesuffix('.2') + '.1',
            'committed semantic retention epoch/owner')
    task = git(TASK); start = task.decode().index('- ID: `' + binding['owner'] + '`')
    end = task.decode().index('\n- ID:', start + 1)
    require(same(binding['task_identity'], identity(task)) and binding['owner_body'] == task.decode()[start:end]
            and '\n  Status: `done`\n' in binding['owner_body'], 'whole committed completed retention owner')
    require(set(binding['archives']) == {str(RETENTION), str(RETAINED_RESULT)}, 'complete retention/result prerequisite domain')
    for directory, expected in binding['archives'].items():
        actual = whole(Path(directory))
        require(actual == committed(directory) and same(pins(actual), expected), 'whole committed retention/result members')
    for programme, pin in binding['programmes'].items():
        raw = Path(programme).read_bytes()
        require(raw == git(programme) and same(identity(raw), pin), 'whole committed query/source programme')
    if replay:
        result = subprocess.run(['python3', '-B', str(RETAINED_RESULT / 'verify_seal.py')], capture_output=True, text=True)
        require(type(result.returncode) is int and result.returncode == 0
                and result.stdout.startswith('PASS independently consumed actual retention seal,'),
                'fresh complete retention/public-join actual-result replay')
    if (BASE / 'manifest.json').exists():
        require(same(load(BASE / 'manifest.json'), members()), 'whole immutable publication seal')


def source_proof():
    proposal = load(RETENTION / 'proposal.json')
    before = {p: raw for p, raw in committed('docs/knowledge').items() if Path(p).parent == Path('docs/knowledge') and p.endswith('.md')}
    require(before[CARD].decode() == proposal['before'], 'whole fixed source card')
    after = {**before, CARD: proposal['after'].encode()}
    publication = load(BASE / 'publication.json')
    require(same(publication['before_members'], pins(before)) and same(publication['after_members'], pins(after)),
            'whole initial physical publication conservation')
    require(publication['chapter_before'].encode() == git(CHAPTER), 'whole fixed source chapter')
    require(publication['chapter_after'] == transform_chapter(publication['chapter_before']), 'whole scoped chapter transformation')
    book_before = {p:raw for p,raw in committed('docs/book/src').items()
                   if Path(p).parent == Path('docs/book/src') and p.endswith('.md')}
    book_after = {**book_before, CHAPTER:publication['chapter_after'].encode()}
    require(same(publication['book_before'], pins(book_before)) and same(publication['book_after'], pins(book_after)),
            'whole source book publication conservation')
    keys = ('files', 'lines_total', 'bytes_total')
    baseline = {k:metrics(book_before)[k] for k in keys}
    delta = {k:metrics(book_after)[k]-baseline[k] for k in keys}
    require(same(publication['baseline'], baseline) and same(publication['delta'], delta), 'independent whole source book aggregate')
    before_authority = next(json.loads(s) for s in git(REGISTRY).decode().splitlines()
                            if json.loads(s).get('surface_id') == 'shipped_behavior')
    after_authority = copy.deepcopy(before_authority)
    after_authority['reference_contract']['aggregate_change'] = dict(
        authority_id='PUBLIC-BOUNDARY-PUBLICATION-20261006-SHIPPED-BEHAVIOR', owner=OWNER, baseline=baseline, delta=delta,
        rationale='Publish admitted finite public facts and explicit source/snapshot/current native reader roles.')
    require(same(publication['authority_before'], before_authority) and same(publication['authority_after'], after_authority),
            'whole exact publication book authority')
    check_current(publication['snapshot'])
    require(publication['snapshot']['chapter'] == publication['chapter_after']
            and same(publication['snapshot']['census'], metrics(after)), 'whole initial snapshot scope/capacity')
    new = QUESTION + '\t' + ID + '\t' + CARD
    old_queries = publication['before_queries']
    logical_before = {**committed('docs/knowledge'), **committed('docs/decisions')}
    allocation = module(Path('docs/audits/knowledge-card-rollover-20261005/verify.py'))['allocation']
    source_rows = allocation({p:raw for p,raw in logical_before.items() if p.endswith('.md')})['rows']
    require(set(old_queries) == {'direct', 'cached'}, 'whole pre-publication query roles')
    for role, result in old_queries.items():
        command = ['knowledge-map/scripts/query_knowledge_map.sh', '--all'] + (['--no-cache'] if role == 'direct' else [])
        require(type(result['status']) is int and result['status'] == 0 and result['command'] == command,
                'actual pre-publication query role/status')
        require(result['stdout'] == source_rows, 'independent whole source-derived pre-publication query population')
        old_rows = result['stdout'].splitlines(); new_rows = publication['snapshot']['queries'][role]['stdout'].splitlines()
        require(new not in old_rows and sorted(new_rows) == sorted(old_rows + [new]), 'whole initial global question conservation')
    return dict(revision=REVISION, before=metrics(before), after=metrics(after),
        byte_delta=len(after[CARD])-len(before[CARD]), LF_delta=after[CARD].count(b'\n')-before[CARD].count(b'\n'),
        physical_before=pins(before), physical_after=pins(after),
        book_baseline=baseline, book_delta=delta,
        target_questions=target_rows(publication['snapshot']['queries']['direct']['stdout']),
        role='Authenticated source and initial publication snapshot; no live currency.')


def transform_chapter(before):
    old = module(RETAINED_RESULT / 'book.py')['GUIDE']
    require(before.count(old) == 1, 'whole original retention guide')
    historical = old.replace('This is proposal qualification. Atomic live fact publication, actual current\nqueries and reader routes remain the next slice.',
                            'This command qualifies the retained proposal snapshot. Live publication and\ncurrent query/reader qualification use the new command below.')
    after = before.replace(old, historical + GUIDE, 1)
    after = after.replace('full current fact publication remains the next owned step.', 'current fact publication is qualified below.')
    after = after.replace('Full current fact publication and the class/frame and coordinate/address\njoins retain their own next steps;', 'Current fact publication is qualified below. Class/frame and coordinate/address\njoins retain their own next steps;')
    old_command = 'python3 -B docs/audits/record-value-own-boundary-publication-20261005/verify.py --current'
    require(after.count(old_command) == 1, 'unique superseded own-boundary advertised current role')
    after = after.replace(old_command, old_command.removesuffix(' --current'), 1)
    after = after.replace('The current publication reader also qualifies the own subtest/do-load source',
                          'The superseded publication snapshot preserves the own subtest/do-load source')
    after = after.replace('adapter separately, then checks current canonical source-view selection,', 'adapter separately. The new current reader above checks canonical source-view selection,')
    first = after.index('The live helper reader checks the current core and topic,')
    end = after.index('The superseded publication snapshot preserves', first)
    after = after[:first] + '''The superseded helper reader retains its original whole-card current epoch.
Its default replay preserves the historical source census and book authority;
the new observer current command above qualifies this admitted extension.
The tooling companion's old current route still needs its immediate owned repair.
Relevant source, question and route changes require qualification; unrelated
book progress does not invalidate the scoped observer reader.

''' + after[end:]
    after = after.replace('The publication reader preserves the complete source\nmeaning and question ownership, checks actual direct and cached queries, and\nrejects lost source roles, wrong routes and invented parser identity:',
        'The historical publication preserves the original source meaning and question\nownership. Its default snapshot replay remains available below; use the new\nobserver command above for current facts, queries and source roles:')
    return after


def controls(record):
    cases = [
        ('lost-receiver-fact', lambda r: r.update(card=r['card'].replace('The parser receiver role is declared;', 'The parser role is declared;')), 'whole admitted source facts questions identity and route'),
        ('wrong-fact-id', lambda r: r.update(card=r['card'].replace('id: '+ID, 'id: borrowed')), 'whole admitted source facts questions identity and route'),
        ('wrong-current-route', lambda r: r.update(card=r['card'].replace('verify.py --current', 'verify.py')), 'whole admitted source facts questions identity and route'),
        ('lost-new-question', lambda r: r.update(card=r['card'].replace('  - "'+QUESTION+'"\n', '')), 'whole admitted source facts questions identity and route'),
        ('borrowed-owner', lambda r: r['queries']['direct'].update(stdout=r['queries']['direct']['stdout'].replace(QUESTION+'\t'+ID, QUESTION+'\tborrowed')), 'complete current question ownership'),
        ('Boolean-query-success', lambda r: r['queries']['cached'].update(status=True), 'actual query integer success'),
        ('float-query-success', lambda r: r['queries']['direct'].update(status=0.0), 'actual query integer success'),
        ('borrowed-query-command', lambda r: r['queries']['cached'].update(command=r['queries']['direct']['command']), 'actual distinct direct/cache query command roles'),
        ('borrowed-snapshot-guide', lambda r: r.update(chapter=r['chapter'].replace(COMMAND, COMMAND.removesuffix(' --current'))), 'unique scoped source/current/snapshot publication guide'),
        ('Boolean-capacity', lambda r: r['census'].update(files=True), 'physical capacity kind/allowance: files'),
        ('missing-capacity', lambda r: r['census'].pop('bytes_total'), 'complete physical capacity dimensions'),
        ('extra-physical-card', lambda r: r['census'].update(files=r['census']['files']+1), 'physical capacity kind/allowance: files'),
        ('widened-allowance', lambda r: r['surface']['transition']['max_growth'].update(files=111), 'whole unchanged physical card authority'),
    ]
    results = []
    for name, mutate, cause in cases:
        candidate = copy.deepcopy(record); mutate(candidate)
        require(not same(candidate, record), 'genuine publication intervention: '+name)
        try:
            check_current(candidate)
        except ValueError as error:
            require(str(error) == cause, 'intended publication refusal: '+name)
            results.append(dict(control=name, status=1, cause=cause))
        else:
            raise ValueError('false-green publication control: '+name)
    return results


class Visible(HTMLParser):
    def __init__(self):
        super().__init__(); self.parts, self.codes, self.current = [], [], None

    def handle_starttag(self, tag, attrs):
        if tag == 'code': self.current = []

    def handle_data(self, data):
        self.parts.append(data)
        if self.current is not None: self.current.append(data)

    def handle_endtag(self, tag):
        if tag == 'code' and self.current is not None:
            self.codes.append(''.join(self.current).strip()); self.current = None


def rendered(html):
    reader = Visible(); reader.feed(html)
    require(reader.codes.count(COMMAND) == 1, 'native exact current publication command')
    expected = GUIDE.replace('```bash\n', '').replace('```\n', '').replace('`', '').replace("proposal's", 'proposal’s')
    require(' '.join(expected.split()) in ' '.join(' '.join(reader.parts).split()), 'native complete scoped publication guide')


def native_proof(html):
    rendered(html); results = []
    for name, old, new, cause in (
        ('borrowed-native-command', COMMAND, COMMAND.removesuffix(' --current'), 'native exact current publication command'),
        ('borrowed-native-currency', 'snapshot success cannot', 'snapshot success can', 'native complete scoped publication guide'),
        ('invented-native-identity', 'coordinates and addresses remain open', 'coordinates and addresses are complete', 'native complete scoped publication guide'),
    ):
        candidate = html.replace(old, new); require(candidate != html, 'genuine native intervention: '+name)
        try: rendered(candidate)
        except ValueError as error:
            require(str(error) == cause, 'intended native refusal: '+name)
            results.append(dict(control=name, status=1, cause=cause))
        else: raise ValueError('false-green native intervention: '+name)
    return dict(input_identity=identity(html.encode()), controls=results, visual_QA='pending; separately owned')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--current', action='store_true')
    parser.add_argument('--build')
    parser.add_argument('--seal', action='store_true')
    args = parser.parse_args()
    require(args.current or args.build is None, 'native current build needs explicit current role')
    authenticate(); save('source-proof.json', source_proof())
    snapshot = load(BASE / 'publication.json')['snapshot']
    save('controls.json', controls(snapshot))
    save('native-proof.json', native_proof((BASE / 'native-input.html').read_text()))
    if args.current:
        check_current(current_input())
        plane = module(Path('scripts/book_source_references.py')); rows = plane['expected_rows']()
        plane['check'](rows); plane['check_index'](rows)
        subprocess.run(['python3', '-B', 'scripts/check_book_source_index.py'], check=True, stdout=subprocess.DEVNULL)
        if args.build:
            destination = Path(args.build)
            require(not destination.is_absolute() and '..' not in destination.parts
                    and destination.resolve().is_relative_to(Path.cwd())
                    and destination.stat().st_dev == Path.cwd().stat().st_dev, 'repository-relative same-volume native build')
            plane['check'](rows, args.build)
            rendered((destination / '13k-isf-feature-support-matrix.html').read_text())
    if args.seal: save('manifest.json', members())
    print(CURRENT_SUCCESS if args.current else SUCCESS, end='')


if __name__ == '__main__':
    main()

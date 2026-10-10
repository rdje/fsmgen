"""Fixed scope and exact transformations for the finite address closure."""
import ast
import hashlib
import json
import re
import subprocess
from pathlib import Path

BASE = Path('docs/audits/address-current-closure-20261010')
REVISION = 'd82d1ef6620796b9c191a9a191b42a76e17f453d'
TASK = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
MODULE = 'scripts/record_value_address_fact.py'
TEST = 't/python/test_record_value_current_publication.py'
FEATURE = 'docs/book/src/13k-isf-feature-support-matrix.md'
REFERENCE = 'docs/book/src/90-reference-map.md'
REGISTRY = 'doctrine/live_document_size/surfaces.jsonl'
ARCHIVES = 'doctrine/live_document_size/archive_descriptors.jsonl'
PREPARATION = 'docs/audits/address-publication-preparation-20261010'
PUBLICATION = 'docs/audits/address-current-publication-20261010'
PARENT = 'docs/audits/address-parent-acceptance-20261010'
OWNER = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.2.2.4.4.3'
PUBLICATION_OWNER = OWNER.rsplit('.', 1)[0]
ADDRESS = PUBLICATION_OWNER.rsplit('.', 1)[0]
NEXT = ADDRESS.rsplit('.', 1)[0] + '.5'
CLOSED = {OWNER, PUBLICATION_OWNER, ADDRESS}
SCOPE = ('Complete unchanged finite address/lifetime and governed publication acceptance. '
         'Original source graphs, active holders, whole raw bodies and simultaneous numerical '
         'relations join the exact reviewed original/proposed/current facts, history, questions, '
         'book and native sources. Only completed finite address nodes close. '
         'This dated closure does not establish later current publication or native identity.')
OPEN = ['complete raw-stack joining', 'original private/provider/formatter identity',
        'external/native/CODE/Regexp identity and hidden referents', 'native payload/flags',
        'cross-call/capture numerical reuse', 'global heap census', 'cause/consumer/alias successors',
        'cold replay and permanent/hot/host-native successors', 'visual book QA', 'HIAL/full-CI/push qualification']
ROLE = 'Complete dated finite address closure; saved current inputs do not establish later currency.'
NEXT_ACTION = 'Start full raw-stack joining from every complete qualified inventory/class/frame/coordinate/address reader and original source/context prerequisite. Preserve whole raw bytes; reject full-stack/first-cause/wrong-caller/borrowed-address controls before closing its parent. Cause/consumer/alias/cold/permanent and host-native successors remain open.'
INDEX_OLD = 'raw-parent done; address publication done; container acceptance next.'
INDEX_NEW = 'raw-parent/address container/publication done; full raw-stack joining next.'
NAMESPACES = ['address-source-boundaries', 'address-source-integration', 'address-raw-admission',
              'address-raw-operands', 'address-raw-join', 'address-numeric-join',
              'address-parent-acceptance', 'address-publication-preparation', 'address-current-publication']
GUIDE_OLD = '''cold and visual scopes remain separately owned. Final address-container
acceptance follows atomic publication; HIAL and full CI/push gates stay open.'''
GUIDE_NEW = '''cold and visual scopes remain separately owned. Full unchanged address-container
acceptance now qualifies through fresh complete semantic readers and independent
whole original/proposed/current reconstruction. Only finite address nodes close;
full raw-stack joining is next. HIAL and full CI/push gates stay open.'''
REFERENCE_OLD = '''authority now reject that challenge before any seal. Full address-container
acceptance remains the next owned step; private/downstream/alias/cold/visual/HIAL
and full CI/push work retain their separate owners.

'''
REFERENCE_NEW = '''authority now reject that challenge before any seal. Full unchanged finite
address-container and publication acceptance now qualify together. Fresh complete
source, class/frame, coordinate, operand, holder, numerical and parent readers
join independent original/proposed/current source, question, history, scope and
native reconstruction. Every descendant is complete before its parent closes.
Earlier address paragraphs describe retained checkpoints; their then-open scopes
do not replace this current frontier. Full raw-stack joining is next;
private/downstream/alias/cold/visual/HIAL and full CI/push retain their owners.

Replay the complete dated closure independently of later current progress:

```sh
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/address-current-closure-20261010/verify.py
```

The dated replay authenticates its complete retained actual results. Run the
maintained current reader above to establish current source and native currency.
Neither mode recaptures original executions or supplies native object identity.

'''
SUCCESS = 'PASS complete dated finite address/container/publication acceptance; fresh semantic and current/native readers, original/proposed/current/history and genuine controls qualify; full raw-stack joining remains next.\n'
READERS = {
    'source-boundaries-approved': ['python3', '-B', 'docs/audits/address-source-boundaries-20261010/verify.py'],
    'source-integration': ['python3', '-B', 'docs/audits/address-source-integration-20261010/verify.py'],
    'class-frame': ['python3', '-B', 'docs/audits/record-value-class-frame-join-20261006/verify.py'],
    'coordinate': ['python3', '-B', 'docs/audits/coordinate-original-hostile-checks-20261009/verify_hostile.py'],
    **{name: ['python3', '-B', 'docs/audits/' + folder + '-20261010/verify.py'] for name, folder in (
        ('admission', 'address-raw-admission'), ('operands', 'address-raw-operands'),
        ('holders', 'address-raw-join'), ('numerical', 'address-numeric-join'), ('parent', 'address-parent-acceptance'))},
    'preparation': ['python3', '-B', PREPARATION + '/verify.py', '--snapshot']}


def need(ok, cause):
    if not ok:
        raise ValueError(cause)


def root():
    need(Path(__file__).resolve().parents[3] == Path.cwd().resolve(), 'invoke finite address closure from its own repository root')


def same(left, right):
    return json.dumps(left, sort_keys=True, allow_nan=False) == json.dumps(right, sort_keys=True, allow_nan=False)


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def read(path, maximum=134217728):
    path = Path(path); root = Path.cwd().resolve(); full = root / path
    need(not path.is_absolute() and not {'..', '.git'}.intersection(path.parts), 'own relative closure input')
    need(full.resolve() == full and full.is_file() and full.stat().st_dev == root.stat().st_dev,
         'plain own same-volume closure input')
    for parent in full.parents:
        if parent == root:
            break
        need(not (parent / '.git').exists(), 'own closure repository boundary')
    with full.open('rb') as stream:
        raw = stream.read(maximum + 1)
    need(len(raw) <= maximum, 'bounded complete closure input')
    return raw


def load(path):
    return json.loads(read(path))


def git(*args, data=None):
    result = subprocess.run(['git', '--no-replace-objects', *args], input=data, capture_output=True)
    need(result.returncode == 0 and not result.stderr, 'whole immutable closure Git input')
    return result.stdout


def paths(prefix):
    return git('ls-tree', '-r', '--name-only', REVISION, '--', prefix).decode().splitlines()


def objects(names, revision=REVISION):
    raw = git('cat-file', '--batch', data=''.join(revision + ':' + p + '\n' for p in names).encode())
    result, offset = {}, 0
    for path in names:
        end = raw.index(b'\n', offset); _, kind, size = raw[offset:end].split()
        need(kind == b'blob', 'whole closure blob kind')
        offset, size = end + 1, int(size); result[path] = raw[offset:offset + size]
        need(raw[offset + size:offset + size + 1] == b'\n', 'whole binary closure framing')
        offset += size + 1
    need(offset == len(raw), 'complete closure Git population consumed')
    return result


def literal(raw, name):
    found = [ast.literal_eval(n.value) for n in ast.parse(raw).body if isinstance(n, ast.Assign)
             and any(isinstance(t, ast.Name) and t.id == name for t in n.targets)]
    need(len(found) == 1, 'unique fixed closure literal')
    return found[0]


def swap(text, old, new):
    need(text.count(old) == 1, 'unique whole closure transformation seam')
    return text.replace(old, new, 1)


def wanted(before):
    module = before[MODULE].decode()
    guide = swap(literal(module, 'GUIDE'), GUIDE_OLD, GUIDE_NEW)
    reference = swap(literal(module, 'REFERENCE'), REFERENCE_OLD, REFERENCE_NEW)
    changed = swap(swap(module, literal(module, 'GUIDE'), guide), literal(module, 'REFERENCE'), reference)
    books = {p: raw for p, raw in before.items() if Path(p).parent == Path('docs/book/src') and p.endswith('.md')}
    books[FEATURE] = swap(books[FEATURE].decode(), literal(module, 'GUIDE'), guide).encode()
    books[REFERENCE] = swap(books[REFERENCE].decode(), literal(module, 'REFERENCE'), reference).encode()
    return changed.encode(), books, guide, reference


def metrics(rows):
    values = list(rows.values())
    return dict(files=len(values), bytes_total=sum(map(len, values)), lines_total=sum(r.count(b'\n') for r in values),
                bytes_each=max(map(len, values)), lines_each=max(r.count(b'\n') for r in values),
                line_bytes_each=max(len(line.rstrip(b'\r')) for r in values for line in r.split(b'\n')))


def counts(rows):
    measured = metrics(rows)
    return {k: measured[k] for k in ('files', 'bytes_total', 'lines_total')}


def nodes(raw):
    matches = list(re.finditer(r'^- ID: `([^`]+)`\n.*?(?=^- ID: |\Z)', raw.decode(), re.M | re.S))
    result = {m[1]: m[0] for m in matches}
    need(len(result) == len(matches), 'unique whole closure task identities')
    return result


def contract(block):
    return {field: re.findall(r'^  ' + field + r':.*$', block, re.M) for field in ('Goal', 'Acceptance', 'Children')}


def baseline():
    root()
    canonical = sorted(p for prefix in ('docs/knowledge', 'docs/decisions') for p in paths(prefix) if p.endswith('.md'))
    books = sorted(p for p in paths('docs/book/src') if Path(p).parent == Path('docs/book/src') and p.endswith('.md'))
    extras = [MODULE, TASK, REGISTRY, ARCHIVES, 'MEMORY.md', 'docs/TASK_TREE.md',
              'scripts/check_record_value_publication.py', 'scripts/record_value_coordinate_fact.py',
              'scripts/book_source_references.py', 't/python/test_record_value_current_publication.py',
              'scripts/run_with_ram_guard.sh', 'docs/audits/book-reference-selection-20261005/selected-routes.json']
    return canonical, books, objects(sorted(set(canonical + books + extras)))


def aggregate(before, books):
    original = {p: raw for p, raw in before.items() if Path(p).parent == Path('docs/book/src') and p.endswith('.md')}
    first, final = counts(original), counts(books)
    return {'authority_id': 'ADDRESS-CURRENT-CLOSURE-20261010', 'owner': OWNER,
            'baseline': first, 'delta': {key: final[key] - value for key, value in first.items()},
            'rationale': 'Qualify unchanged complete finite address/container/publication acceptance with fresh whole semantic and current/native readers, conserved original/proposed/current history and unchanged collection authority; raw-stack and native identity scopes remain owned.'}


def navigation(before):
    memory = swap(before['MEMORY.md'].decode(), OWNER + '` (pending)', NEXT + '` (pending)')
    begin, end = memory.index('- next_action:'), memory.index('- in_flight_uncommitted:')
    memory = memory[:begin] + '- next_action: ' + NEXT_ACTION + '\n' + memory[end:]
    return memory, swap(before['docs/TASK_TREE.md'].decode(), INDEX_OLD, INDEX_NEW)


def test_source(before):
    old = "('Full address-container\\nacceptance remains the next owned step', 'All address-container acceptance is complete')"
    new = "('Full raw-stack joining is next;', 'All raw-stack acceptance is complete;')"
    return swap(before[TEST].decode(), old, new).encode()

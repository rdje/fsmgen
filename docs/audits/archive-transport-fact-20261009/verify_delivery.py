"""Independent whole-book delivery and complete actual slice-result consumption."""
import copy
import hashlib
import json
import shlex
import subprocess
from pathlib import Path

BASE = Path('docs/audits/archive-transport-fact-20261009')
REVISION = '0c86d2491e486e902e90f493bd883df8bc5fc6bf'
CHAPTER = 'docs/book/src/90-reference-map.md'
COMMANDS = {
    'source-current': ['python3', '-B', 'scripts/book_source_references.py', '--check'],
    'book-build': ['mdbook', 'build', 'docs/book'],
    'native-staged': ['python3', '-B', 'scripts/book_source_references.py', '--check', '--verify-build', 'docs/book/book'],
    'current-native': ['python3', '-B', 'scripts/check_record_value_publication.py', '--build', 'docs/book/book'],
}


def need(ok, why):
    if not ok:
        raise ValueError(why)


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def git(*args):
    run = subprocess.run(['git', '--no-replace-objects', *args], capture_output=True)
    need(run.returncode == 0 and not run.stderr, 'complete independent book source')
    return run.stdout


def counts(rows):
    return {'files': len(rows), 'bytes_total': sum(map(len, rows)),
            'lines_total': sum(len(raw.splitlines(keepends=True)) for raw in rows)}


def expectation():
    paths = sorted(p for p in git('ls-tree', '-r', '--name-only', REVISION, '--', 'docs/book/src').decode().splitlines()
                   if Path(p).parent == Path('docs/book/src') and p.endswith('.md'))
    need(paths == sorted(str(p) for p in Path('docs/book/src').glob('*.md')), 'whole current book membership')
    before = [git('show', REVISION + ':' + p) for p in paths]
    after = [Path(p).read_bytes() for p in paths]
    need([p for p,a,b in zip(paths,before,after) if a != b] == [CHAPTER], 'unique current book delta')
    old, current = before[paths.index(CHAPTER)], after[paths.index(CHAPTER)]
    first = old.index(b'Archive permissions use an explicit transport mask;')
    last = old.index(b'Original coordinate selections,', first)
    a = current.index(b"Archive permissions follow Git's transport mask")
    b = current.index(b'Original coordinate selections,', a)
    need(old[:first] == current[:a] and old[last:] == current[b:], 'reversible complete scoped book publication')
    return {'revision': REVISION, 'owner': (BASE / 'scope.txt').read_text().strip(),
            'source': CHAPTER, 'before': pin(old), 'after': pin(current),
            'original_block': old[first:last].decode(), 'current_block': current[a:b].decode(),
            'book_before': counts(before), 'book_after': counts(after)}


def publication_check(actual, expected):
    for key in expected:
        need(json.dumps(actual[key], sort_keys=True) == json.dumps(expected[key], sort_keys=True),
             'independent complete delivery field: ' + key)


def receipt_check(receipt, command, stdout=None):
    need(type(receipt['status']) is int and receipt['status'] == 0, 'actual native receipt status')
    need(receipt['command'] == ['scripts/run_with_ram_guard.sh', '--', *command], 'actual native receipt command')
    instruments = {str(BASE / 'checks.py'), 'scripts/run_with_ram_guard.sh'} | {p for p in command if Path(p).is_file()}
    need(receipt['instruments'] == {p:pin(Path(p).read_bytes()) for p in instruments}, 'complete actual native instruments')
    need(type(receipt['stdout']) is str and type(receipt['stderr']) is str
         and 'host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s' in receipt['stderr'],
         'complete actual streams and unchanged RAM cutoffs')
    if stdout is not None:
        need(receipt['stdout'] == stdout, 'complete actual native stdout')


def main():
    actual = json.loads((BASE / 'book.json').read_bytes())
    expected = expectation()
    publication_check(actual, expected)
    prior = list(map(json.loads, git('show', REVISION + ':doctrine/live_document_size/surfaces.jsonl').splitlines()))
    current = list(map(json.loads, Path('doctrine/live_document_size/surfaces.jsonl').read_text().splitlines()))
    need([r.get('surface_id') for r in prior] == [r.get('surface_id') for r in current], 'whole capacity surface membership')
    for old, new in zip(prior, current):
        need(old.get('enforcement_ceilings') == new.get('enforcement_ceilings'), 'every original ceiling unchanged')
        if new.get('surface_id') == 'knowledge_cards':
            need(old == new, 'whole card authority and rollover debt unchanged')
        if new.get('surface_id') == 'shipped_behavior':
            change = new['reference_contract']['aggregate_change']
            need(change['authority_id'] == 'ARCHIVE-TRANSPORT-FACT-20261009'
                 and change['owner'] == expected['owner'] and change['baseline'] == expected['book_before']
                 and change['delta'] == {k:expected['book_after'][k]-expected['book_before'][k] for k in expected['book_before']},
                 'exact complete book aggregate authority')
        if new.get('surface_id') == 'task_evidence':
            paths = sorted({p for pattern in new['targets'] for p in Path('.').glob(pattern)})
            data = [p.read_bytes() for p in paths]
            measured = {**counts(data), 'bytes_each': max(map(len,data)),
                        'lines_each': max(len(raw.splitlines(keepends=True)) for raw in data),
                        'line_bytes_each': max(len(line.rstrip(b'\r')) for raw in data for line in raw.split(b'\n'))}
            product = json.loads((BASE / 'task-metrics.json').read_bytes())
            need(product['actual'] == measured and product['owner'] == expected['owner'], 'complete independently measured task evidence')
            corrected = copy.deepcopy(old)
            corrected['transition']['max_growth'] = {k:max(0,min(v + new['transition']['ratchet_step'][k],
                new['enforcement_ceilings'][k]) - new['baseline'][k]) for k,v in measured.items()}
            need(corrected == new, 'only exact measured owned task allowance changes')
    checks = json.loads((BASE / 'checks.json').read_bytes())
    for name, command in COMMANDS.items():
        output = None
        if name in ('source-current', 'native-staged'):
            output = 'book-source-references: complete source/role/member/relative-endpoint/current-byte/ignore contracts hold\n'
        if name == 'current-native':
            output = 'PASS current class/frame facts, complete current source/query allocation and unchanged capacity/source contracts.\n'
        receipt_check(checks[name], command, output)
    audit_commands = {name:['python3','-B',str(BASE / programme)] for name,programme in (
        ('compact','compact.py'), ('publish','publish.py'), ('book','book.py'),
        ('task-pressure','task_pressure.py'), ('archive','archive.py'),
        ('independent-repaired','verify.py'), ('canonical-probes','reverify_routes.py'))}
    audit_commands['focused'] = ['prove','-Iperl','t/2066-record-value-current-publication.t',
        't/1303-isf-public-live-book-paths-audit.t','t/1305-isf-book-feature-matrix-audit.t']
    audit_commands['knowledge-map'] = ['knowledge-map/scripts/check_knowledge_map.sh']
    for name,command in audit_commands.items():
        receipt_check(checks[name], command)
    focused = checks['focused']['stdout']
    need('All tests successful.' in focused and 'Files=3, Tests=310' in focused, 'actual focused regression results')
    native_results = [json.loads(line) for line in checks['independent-repaired']['stdout'].splitlines()]
    independent = native_results[-1]
    need(independent['result'] == 'PASS complete originals, reviewed semantic closure, whole questions and non-growing authority',
         'complete independent compaction result')
    need([r['status'] for r in independent['native_archives']] == [0,1,1,1], 'complete genuine native archive control results')
    probes = [json.loads(line) for line in checks['canonical-probes']['stdout'].splitlines()]
    need([r['source'] for r in probes[:-1]] == ['docs/knowledge/decision-record-exact-retrieval.md',
        'docs/knowledge/decision-selected-inventory-byte-budget.md'] and all(r['status'] == 0 for r in probes[:-1]),
        'complete actual canonical probe population and statuses')
    for row in probes[:-1]:
        front = Path(row['source']).read_text().split('---\n',2)[1].splitlines()
        index = next(i for i,line in enumerate(front) if line.startswith('reverify: '))
        declared = front[index].split(': ',1)[1]
        if declared == '>-':
            declared = ' '.join(line.strip() for line in front[index+1:] if line.startswith('  '))
        need(row['command'] == ['bash','-c',declared], 'complete actual canonical probe command')
        paths = {row['source']} | {p for p in shlex.split(declared) if Path(p).is_file()}
        need(row['instruments'] == {p:pin(Path(p).read_bytes()) for p in paths}, 'actual retained canonical probe instruments')
        need(type(row['stdout']) is str and type(row['stderr']) is str, 'complete canonical probe streams')
    need(probes[-1]['result'] == 'PASS every original executable probe and new transport route', 'complete original probe closure')
    # Retain both actual oracle failures and exact programmes rather than making
    # a repaired success erase the original result. The current predicate uses
    # the native checker's real missing-file and digest-change diagnostics.
    for name, path in (('independent', 'first/verify.py.txt'),
                       ('independent-refusal-token', 'first/verify-refusal-token.py.txt')):
        row = checks[name]
        need(type(row['status']) is int and row['status'] == 1
             and 'intended actual archive source refusal' in row['stderr']
             and row['instruments'][str(BASE / 'verify.py')] == pin((BASE / path).read_bytes()),
             'complete retained oracle failure and exact programme')
    controls = {}
    for name, field, mutate in (
        ('borrowed-book', 'before', lambda p:p.update(before=p['after'])),
        ('Boolean-count', 'book_after', lambda p:p['book_after'].update(files=True)),
        ('omitted-block', 'current_block', lambda p:p.update(current_block=''))):
        bad = copy.deepcopy(actual); mutate(bad)
        try:
            publication_check(bad, expected)
        except ValueError as error:
            need(str(error) == 'independent complete delivery field: ' + field, 'intended book control')
            controls[name] = str(error)
        else:
            raise ValueError('false-green book control: ' + name)
    for name, mutate, message in (
        ('false-green-status', lambda r:r.update(status=True), 'actual native receipt status'),
        ('borrowed-command', lambda r:r['command'].append('--foreign'), 'actual native receipt command'),
        ('borrowed-stdout', lambda r:r.update(stdout='PASS\n'), 'complete actual native stdout')):
        bad = copy.deepcopy(checks['current-native']); mutate(bad)
        try:
            receipt_check(bad, COMMANDS['current-native'], checks['current-native']['stdout'])
        except ValueError as error:
            need(str(error) == message, 'intended actual receipt control')
            controls[name] = str(error)
        else:
            raise ValueError('false-green native receipt control: ' + name)
    print(json.dumps({'result': 'PASS whole source/native book delivery and complete actual compaction/probe results',
                      'book': expected, 'controls': controls}, sort_keys=True))


if __name__ == '__main__':
    main()

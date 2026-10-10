"""Independently consume whole hostile qualification and source/native delivery."""
import copy
import hashlib
import json
import subprocess
import runpy
from pathlib import Path

BASE = Path('docs/audits/coordinate-original-hostile-independent-checks-20261009')
OLD_CHECKS = Path('docs/audits/coordinate-original-hostile-checks-20261009')
PRODUCT = Path('docs/audits/coordinate-original-hostile-20261009')
REVISION = '1626bd7ca68741492d1b5bc9377f32dd9f64d334'
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
    need(run.returncode == 0 and not run.stderr, 'complete independent hostile book source')
    return run.stdout


def counts(rows):
    return {'files': len(rows), 'bytes_total': sum(map(len, rows)),
            'lines_total': sum(len(raw.splitlines(keepends=True)) for raw in rows)}


def expectation():
    paths = sorted(p for p in git('ls-tree', '-r', '--name-only', REVISION, '--', 'docs/book/src').decode().splitlines()
                   if Path(p).parent == Path('docs/book/src') and p.endswith('.md'))
    need(paths == sorted(str(p) for p in Path('docs/book/src').glob('*.md')), 'whole current hostile book membership')
    before = [git('show', REVISION + ':' + p) for p in paths]
    after = [Path(p).read_bytes() for p in paths]
    need([p for p, a, b in zip(paths, before, after) if a != b] == [CHAPTER], 'unique current hostile book delta')
    old, current = before[paths.index(CHAPTER)], after[paths.index(CHAPTER)]
    marker = b'\n<div id="knowledge-map-architecture">'
    old_start = old.index(b'Full independent reconstruction remains unfinished.')
    old_end = old.index(marker, old_start)
    start = current.index(b'Full independent reconstruction now qualifies the complete dated product.')
    end = current.index(marker, start)
    need(current[:start] == old[:old_start] and current[end:] == old[old_end:],
         'reversible complete hostile guide replacement')
    return {'revision': REVISION, 'owner': (BASE / 'scope.txt').read_text().strip(),
            'source': CHAPTER, 'before': pin(old), 'after': pin(current),
            'original_block': old[old_start:old_end].decode(), 'current_block': current[start:end].decode(),
            'book_before': counts(before), 'book_after': counts(after)}


def publication_check(actual, expected):
    for key in expected:
        need(json.dumps(actual[key], sort_keys=True) == json.dumps(expected[key], sort_keys=True),
             'independent complete hostile delivery field: ' + key)


def receipt_check(receipt, command, stdout=None):
    need(type(receipt['status']) is int and receipt['status'] == 0, 'actual hostile receipt status')
    need(receipt['command'] == ['scripts/run_with_ram_guard.sh', '--', *command], 'actual hostile receipt command')
    instruments = {str(BASE / 'checks.py'), 'scripts/run_with_ram_guard.sh'} | {p for p in command if Path(p).is_file()}
    need(receipt['instruments'] == {p: pin(Path(p).read_bytes()) for p in instruments}, 'complete actual hostile instruments')
    need(type(receipt['stdout']) is str and type(receipt['stderr']) is str
         and 'host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s' in receipt['stderr'],
         'complete actual hostile streams and unchanged RAM cutoffs')
    if stdout is not None:
        need(receipt['stdout'] == stdout, 'complete actual hostile stdout')


def capacity(expected):
    prior = list(map(json.loads, git('show', REVISION + ':doctrine/live_document_size/surfaces.jsonl').splitlines()))
    current = list(map(json.loads, Path('doctrine/live_document_size/surfaces.jsonl').read_text().splitlines()))
    need([r.get('surface_id') for r in prior] == [r.get('surface_id') for r in current], 'whole hostile capacity membership')
    for old, new in zip(prior, current):
        corrected = copy.deepcopy(old)
        if new.get('surface_id') == 'shipped_behavior':
            change = new['reference_contract']['aggregate_change']
            need(change['authority_id'] == 'COORDINATE-ORIGINAL-HOSTILE-INDEPENDENT-20261009'
                 and change['owner'] == expected['owner'] and change['baseline'] == expected['book_before']
                 and change['delta'] == {k: expected['book_after'][k] - expected['book_before'][k]
                                         for k in expected['book_before']}, 'exact hostile book aggregate authority')
            corrected['reference_contract']['aggregate_change'] = change
        elif new.get('surface_id') == 'task_evidence':
            paths = sorted({p for pattern in new['targets'] for p in Path('.').glob(pattern)})
            data = [p.read_bytes() for p in paths]
            measured = {**counts(data), 'bytes_each': max(map(len, data)),
                        'lines_each': max(len(raw.splitlines(keepends=True)) for raw in data),
                        'line_bytes_each': max(len(line.rstrip(b'\r')) for raw in data for line in raw.split(b'\n'))}
            product = json.loads((BASE / 'task-metrics.json').read_bytes())
            need(product['actual'] == measured and product['owner'] == expected['owner'],
                 'complete independently measured hostile task evidence')
            corrected['transition']['max_growth'] = {
                k: max(0, min(v + new['transition']['ratchet_step'][k], new['enforcement_ceilings'][k]) - new['baseline'][k])
                for k, v in measured.items()}
        need(json.dumps(corrected, sort_keys=True) == json.dumps(new, sort_keys=True), 'only exact owned hostile book/task authority changes: ' + new.get('surface_id', 'collection-header'))


def qualify_results(checks):
    commands = {
        'book': ['python3', '-B', str(BASE / 'book.py')],
        'task-pressure': ['python3', '-B', str(BASE / 'task_pressure.py')],
        'published-independent': ['python3', '-B', str(OLD_CHECKS / 'verify_hostile.py')],
        'focused': ['prove', '-Iperl', 't/2066-record-value-current-publication.t',
                    't/1303-isf-public-live-book-paths-audit.t', 't/1305-isf-book-feature-matrix-audit.t'],
        'claim-inventory': ['perl', 'scripts/check_claim_verification_inventory.pl', '--write'],
    }
    for name, command in commands.items():
        receipt_check(checks[name], command)
    need('All tests successful.' in checks['focused']['stdout']
         and 'Files=3, Tests=310' in checks['focused']['stdout'], 'actual focused independent regression')
    prior_bytes = git('show', REVISION + ':' + str(OLD_CHECKS / 'checks.json'))
    need((OLD_CHECKS / 'checks.json').read_bytes() == prior_bytes, 'every prior actual receipt remains exact')
    prior = json.loads(prior_bytes)
    stopped = prior['published']
    need(type(stopped['status']) is int and stopped['status'] == 137
         and 'cutoff 88%' in stopped['stderr'], 'first stopped independent attempt is not promoted')
    need((OLD_CHECKS / 'verify_hostile.py').read_bytes()
         == git('show', REVISION + ':' + str(OLD_CHECKS / 'verify_hostile.py')),
         'unchanged fixed-seal published reader source')
    reader = runpy.run_path(str(OLD_CHECKS / 'verify_hostile.py'))
    reader['authenticate'](PRODUCT)
    product = json.loads((PRODUCT / 'qualification.json').read_bytes())
    need(product['revision'] == '32c5f718528c9ca38b72ef0333e26703663674ab',
         'unchanged original hostile source epoch')
    for path, identity in product['inputs'].items():
        raw = Path(path).read_bytes()
        need(pin(raw) == identity and raw == git('show', product['revision'] + ':' + path),
             'complete original hostile input source: ' + path)
    custody = json.loads(Path('docs/audits/coordinate-original-intake-20261009/admission.json').read_bytes())['custody']
    need(pin(json.dumps(custody, sort_keys=True).encode()) == product['original_custody'],
         'whole original custody allocation')
    for path, row in custody['members'].items():
        need(pin(Path(path).read_bytes()) == row['identity'], 'complete original custody member: ' + path)
    result = json.loads(checks['published-independent']['stdout'])
    need(set(result) == {'result', 'whole_qualification', 'actual_matching_reader', 'coverage', 'controls'}
         and result['result'] == 'PASS complete independent original-coordinate hostile qualification and predecessor preservation',
         'closed actual complete independent hostile result')
    need(result['whole_qualification'] == pin(json.dumps(product, sort_keys=True).encode())
         and json.dumps(result['actual_matching_reader'], sort_keys=True)
         == json.dumps(product['actual_matching_reader'], sort_keys=True),
         'entire independently reconstructed hostile product and nested actual reader')
    need(product['actual_matching_reader']['stdout'] == json.loads(git('show', REVISION +
         ':docs/audits/coordinate-original-matching-qualified-checks-20261009/checks.json'))['published']['stdout'],
         'complete original source/matching prerequisite results conserve')
    journal = OLD_CHECKS / 'qualification-repaired-controls.jsonl'
    replay = OLD_CHECKS / 'actual-matching-replay.json'
    for path in (journal, replay):
        need(path.read_bytes() == git('show', REVISION + ':' + str(path)), 'whole producer journal/replay conserve')
    need(json.dumps(product['controls'], sort_keys=True)
         == json.dumps(list(map(json.loads, journal.read_text().splitlines())), sort_keys=True)
         and json.dumps(product['actual_matching_reader'], sort_keys=True)
         == json.dumps(json.loads(replay.read_bytes()), sort_keys=True), 'complete actual producer result domain')
    original_keys = {(mode['mode'], domain, row['index']) for mode in product['original']['inventories']
                     for domain, values in mode['domains'].items() for row in values['nonempty']}
    coverage = {'points': len(product['points']), 'source_recipe_modes': len(product['representatives']),
                'semantic_controls': len(product['controls']), 'forwarding_pairs': len(product['forwarding']),
                'intervened_records': len(original_keys)}
    need(json.dumps(result['coverage'], sort_keys=True) == json.dumps(coverage, sort_keys=True),
         'whole independent coverage allocation')
    recipe_modes = {(point['key'][0], point['selection']['recipe_id']) for point in product['points']}
    need({(point['key'][0], point['selection']['recipe_id']) for point in product['representatives']} == recipe_modes,
         'every observed used source recipe and mode')
    for point in product['representatives']:
        controls = [control for control in product['controls'] if control['point'] == point]
        need([control['field'] for control in controls] == ['line', 'path', 'source'], 'every separating axis per representative')
    for pair in product['forwarding']:
        need(all(any(control['field'] == field and control['affected'] == sorted([pair['child'], pair['parent']])
                     for control in product['controls']) for field in ('line', 'path')), 'every coherent forwarded intervention')
    for field in ('line', 'path'):
        need({tuple(key) for control in product['controls'] if control['field'] == field
              for key in control['affected']} == original_keys, 'every nonempty original receives coordinate interventions')
    expected_controls = {
        'lost-point': 'points', 'lost-source-recipe': 'representatives', 'borrowed-intervention': 'controls',
        'false-green-prior': 'controls', 'lost-forwarded-pair': 'forwarding', 'lost-empty': 'original',
        'Boolean-reader-status': 'actual_matching_reader', 'borrowed-reader-command': 'actual_matching_reader',
        'borrowed-reader-stdout': 'actual_matching_reader',
    }
    need(result['controls'] == {name: 'complete independent hostile field: ' + field
                               for name, field in expected_controls.items()}, 'complete genuine whole-result control outcomes')
    for filename, key, status, cause in (
        ('first-probe-result.json', 'probe', 1, 'unique finite forwarding pairs'),
        ('first-qualification-result.json', 'qualification', 1, 'min() iterable argument is empty'),
        ('ram-stopped-result.json', 'qualification-repaired', 137, 'host memory 89.1% reached cutoff 88%'),
    ):
        record = json.loads((PRODUCT / filename).read_bytes())
        need(json.dumps(record, sort_keys=True) == json.dumps(prior[key], sort_keys=True)
             and type(record['status']) is int and record['status'] == status and cause in record['stderr'],
             'entire retained constructor/stopped attempt: ' + filename)
    progress = json.loads((OLD_CHECKS / 'progress.json').read_bytes())
    need(progress == {'stage': 'independent-complete', 'controls': len(product['controls'])},
         'fresh complete independent progress, not original producer progress')
    need((BASE / 'before-progress.json').read_bytes()
         == git('show', REVISION + ':' + str(OLD_CHECKS / 'progress.json')), 'committed pre-run progress retains exactly')
    for path in ('doctrine/claim_verification/dispositions.jsonl', 'doctrine/claim_verification/disposition_groups.jsonl'):
        need(Path(path).read_bytes() == git('show', REVISION + ':' + path), 'whole existing claim authority unchanged')
    return coverage


def main():
    actual = json.loads((BASE / 'book.json').read_bytes())
    expected = expectation()
    publication_check(actual, expected)
    capacity(expected)
    checks = json.loads((BASE / 'checks.json').read_bytes())
    for name, command in COMMANDS.items():
        output = None
        if name in ('source-current', 'native-staged'):
            output = 'book-source-references: complete source/role/member/relative-endpoint/current-byte/ignore contracts hold\n'
        elif name == 'current-native':
            output = 'PASS current class/frame facts, complete current source/query allocation and unchanged capacity/source contracts.\n'
        receipt_check(checks[name], command, output)
    coverage = qualify_results(checks)
    controls = {}
    for name, field, mutate in (
        ('borrowed-book', 'before', lambda p: p.update(before=p['after'])),
        ('Boolean-count', 'book_after', lambda p: p['book_after'].update(files=True)),
        ('omitted-block', 'current_block', lambda p: p.update(current_block=''))):
        bad = copy.deepcopy(actual)
        mutate(bad)
        try:
            publication_check(bad, expected)
        except ValueError as error:
            need(str(error) == 'independent complete hostile delivery field: ' + field, 'intended hostile book control')
            controls[name] = str(error)
        else:
            raise ValueError('false-green hostile book control: ' + name)
    for name, mutate, message in (
        ('false-green-status', lambda r: r.update(status=True), 'actual hostile receipt status'),
        ('borrowed-command', lambda r: r['command'].append('--foreign'), 'actual hostile receipt command'),
        ('borrowed-stdout', lambda r: r.update(stdout='PASS\n'), 'complete actual hostile stdout')):
        bad = copy.deepcopy(checks['current-native'])
        mutate(bad)
        try:
            receipt_check(bad, COMMANDS['current-native'], checks['current-native']['stdout'])
        except ValueError as error:
            need(str(error) == message, 'intended actual hostile receipt control')
            controls[name] = str(error)
        else:
            raise ValueError('false-green hostile native receipt control: ' + name)
    print(json.dumps({'result': 'PASS complete hostile qualification, whole source/native book delivery and actual receipts',
                      'coverage': coverage, 'book': expected, 'controls': controls}, sort_keys=True))


if __name__ == '__main__':
    main()

"""Independent whole-book delivery and complete actual slice-result consumption."""
import copy
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/coordinate-original-matching-qualified-checks-20261009')
REVISION = 'c8fe740b93f6be988d74729d0baf4b11fabda96a'
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
    marker = b'\n<div id="knowledge-map-architecture">'
    old_start = old.index(b'Full original-coordinate matching resumes after this observer qualification')
    old_end = old.index(marker, old_start)
    start = current.index(b'Complete dated original own-coordinate matching now joins every error origin,')
    end = current.index(marker, start)
    need(current[:start] == old[:old_start] and current[end:] == old[old_end:], 'reversible complete original-matching guide replacement')
    return {'revision':REVISION, 'owner':Path('docs/audits/coordinate-original-matching-qualified-20261009/scope.txt').read_text().strip(),
            'source':CHAPTER, 'before':pin(old), 'after':pin(current),
            'original_block':old[old_start:old_end].decode(), 'current_block':current[start:end].decode(),
            'book_before':counts(before), 'book_after':counts(after)}



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
    actual = json.loads((BASE / 'book-final.json').read_bytes())
    expected = expectation()
    publication_check(actual, expected)
    first_publication = json.loads((BASE / 'book.json').read_bytes())
    first_source = Path(CHAPTER).read_bytes().replace(b'this original guard call matches both source labels at line 107,',
        b'this original guard call matches both source labels at line107,',1)
    need(first_publication['after'] == pin(first_source)
         and first_publication['before'] == expected['before']
         and first_publication['current_block'].replace('at line107,','at line 107,',1) == expected['current_block']
         and first_publication['book_after'] == {**expected['book_after'],'bytes_total':expected['book_after']['bytes_total']-1},
         'whole first book publication and exact final prose spacing correction')
    prior = list(map(json.loads, git('show', REVISION + ':doctrine/live_document_size/surfaces.jsonl').splitlines()))
    current = list(map(json.loads, Path('doctrine/live_document_size/surfaces.jsonl').read_text().splitlines()))
    need([r.get('surface_id') for r in prior] == [r.get('surface_id') for r in current], 'whole capacity surface membership')
    for old, new in zip(prior, current):
        need(old.get('enforcement_ceilings') == new.get('enforcement_ceilings'), 'every original ceiling unchanged')
        if new.get('surface_id') == 'knowledge_cards':
            need(old == new, 'whole card authority and rollover debt unchanged')
        if new.get('surface_id') == 'shipped_behavior':
            change = new['reference_contract']['aggregate_change']
            need(change['authority_id'] == 'COORDINATE-ORIGINAL-MATCHING-QUALIFIED-20261009'
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
        ('book','book.py'),('book-format','book_format.py'),('task-pressure-repaired','task_pressure.py'),('seal','seal.py'),
        ('seal-controls','seal_controls.py'),('published','verify_matching.py'))}
    audit_commands.update({name:['python3','-B','docs/audits/coordinate-original-matching-qualified-20261009/'+programme]
                          for name,programme in (('matching','match.py'),('independent-preseal','verify.py'))})
    audit_commands['focused'] = ['prove','-Iperl','t/2066-record-value-current-publication.t',
        't/1303-isf-public-live-book-paths-audit.t','t/1305-isf-book-feature-matrix-audit.t']
    for name,command in audit_commands.items():
        receipt_check(checks[name],command)
    need('All tests successful.' in checks['focused']['stdout'] and 'Files=3, Tests=310' in checks['focused']['stdout'], 'actual focused original-matching regression')
    independent = json.loads(checks['independent-preseal']['stdout'])
    published = json.loads(checks['published']['stdout'])
    need(independent == published and independent['result'] == 'PASS complete independent original coordinate matching and separating controls',
         'complete actual preseal/published independent results conserve')
    sealed = json.loads(checks['seal-controls']['stdout'])
    need(sealed['result'] == 'PASS genuine copied matching seal controls and whole original conservation'
         and set(sealed['controls']) == {'valid','missing-seal','missing-member','borrowed-body','extra-member','rewritten-seal','symlink-root'}, 'complete actual copied matching controls')
    product = json.loads(Path('docs/audits/coordinate-original-matching-qualified-20261009/matching.json').read_bytes())
    need(product['actual_readers'] == independent['actual_readers'], 'complete actually regenerated original/source/observer results')
    need(independent['matching_identity'] == pin(json.dumps(product['matches'],sort_keys=True).encode())
         and independent['original_identity'] == pin(json.dumps(product['original'],sort_keys=True).encode()),
         'whole actual original and independent sequential matching identities')
    original_observer = json.loads(git('show', REVISION + ':docs/audits/coordinate-observer-caller-checks-20261009/checks.json'))['published']['stdout']
    need(product['actual_readers'][-1]['stdout'] == original_observer,
         'complete fresh observer result conserves committed qualification and all first failures')
    selected = [b['selection'] for row in product['matches'] for phase in row['phases']
                for b in phase['callers_inner_to_outer'] if b['selection'] is not None]
    example = json.loads(expected['current_block'].split('```json\n',1)[1].split('\n```',1)[0])
    need(set(example) == {'recipe_id','reported_filename','reported_line','matching_line_labels','all_line_alternatives'}
         and any(json.dumps({k:row[k] for k in example},sort_keys=True) == json.dumps(example,sort_keys=True) for row in selected)
         and len(example['matching_line_labels']) > 1, 'complete actual equivalent-label book example')
    dispositions_path = 'doctrine/claim_verification/dispositions.jsonl'
    original_dispositions = list(map(json.loads,git('show',REVISION+':'+dispositions_path).splitlines()))
    current_dispositions = list(map(json.loads,Path(dispositions_path).read_text().splitlines()))
    new_dispositions = [r for r in current_dispositions if r not in original_dispositions]
    need(len(new_dispositions)==1 and all(r in current_dispositions for r in original_dispositions),
         'all original claim dispositions conserve with one exact illustrated-line gate')
    disposition = new_dispositions[0]
    need(Path('doctrine/claim_verification/disposition_groups.jsonl').read_bytes() == git('show',REVISION+':doctrine/claim_verification/disposition_groups.jsonl'),
         'complete original claim-group authority unchanged')
    receipt_check(checks['claim-inventory-repaired'],['scripts/check_claim_verification_inventory.pl','--write'])
    group = next(r for r in map(json.loads,Path('doctrine/claim_verification/disposition_groups.jsonl').read_text().splitlines())
                 if r.get('group_id')=='general_book')
    first_disposition = json.loads((BASE/'first-disposition.json').read_bytes())
    repaired = copy.deepcopy(first_disposition)
    repaired['owner_task']=group['owner_task'];repaired['owner_path']='docs/tasks/CLAIM-VERIFICATION-ADOPTION.md'
    repaired['durability']['watcher_paths']=sorted(repaired['durability']['watcher_paths'])
    need(repaired==disposition and first_disposition['owner_task']==expected['owner']
         and first_disposition['durability']['watcher_paths']!=repaired['durability']['watcher_paths'],
         'exact first claim metadata refusal and canonical-owner/sorted-path repair')
    failed_claim = checks['claim-dispositions']
    need(type(failed_claim['status']) is int and failed_claim['status']==1
         and 'owner_task does not match candidate group general_book' in failed_claim['stderr']
         and 'durability watcher_paths must be sorted and unique' in failed_claim['stderr'],
         'complete first actual claim-disposition refusal')
    receipt_check(checks['claim-dispositions-repaired'],['scripts/check_claim_verification_dispositions.pl'])
    need(disposition['candidate_id']=='published-b44fa204fc3c1dcba0ce2bf1'
         and disposition['disposition']=='derived_gate' and disposition['owner_task']==group['owner_task']
         and set(disposition['rederive']['producer_paths'])=={'docs/audits/coordinate-original-matching-qualified-20261009/match.py',
                                                             'docs/audits/coordinate-original-matching-qualified-20261009/matching.json'}
         and set(disposition['falsify']['oracle_paths'])=={'docs/audits/coordinate-original-matching-qualified-20261009/verify.py',str(BASE/'verify_delivery.py')}
         and set(disposition['durability']['watcher_paths'])=={str(BASE/'verify_matching.py'),str(BASE/'verify_delivery.py')},
         'distinct source/sequential/durable illustrated-line evidence legs')
    phases = [phase for row in product['matches'] for phase in row['phases']]
    bindings = [b for p in phases for b in p['callers_inner_to_outer']]
    coverage = {'nonempty_records':len(product['matches']), 'throw_phases':len(phases),
        'own_coordinates':sum(2+sum(b['selection'] is not None for b in p['callers_inner_to_outer']) for p in phases),
        'frames':sum(sum(part['kind']=='frame' for part in r['segments']) for m in product['original']['inventories']
                     for values in m['domains'].values() for r in values['nonempty']),
        'opaque_bound_callers':sum(b['selection'] is None for b in bindings),
        'opaque_framework_frames':sum(len(p['opaque_framework']) for p in phases),
        'used_source_recipes':len(product['source_phases']['statements']),
        'full_candidate_recipes':len(product['expression_alternatives']['candidates']),
        'observer_callers':len(product['observer_qualification']['associations'])}
    need(coverage == independent['coverage'], 'complete actual matching coverage independently remeasured')
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
    print(json.dumps({'result': 'PASS whole source/native book delivery and complete actual original matching results',
                      'book': expected, 'controls': controls}, sort_keys=True))


if __name__ == '__main__':
    main()

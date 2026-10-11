"""Verify saved cleanup and source-copy authority; never repeat deletion."""
import argparse
import copy
from datetime import datetime
import gzip
import hashlib
import json
from pathlib import Path
import stat
import subprocess
import sys

from capture import BASE, canonical, pin, save

sys.path.insert(0, 'scripts')
import record_value_raw_fact as fact

PLAN = json.loads((BASE / 'plan.json').read_bytes())
SUFFIXES = ('.bin', '.log', '.pyc', '.stdout', '.stderr')
ALLOWED = {'.artifacts/raw-canonical-preparation-20261011/' + name: source for name, source in (
    ('source-view', 'source.json'), ('source-view-v2', 'source-v2.json'),
    ('source-view-v3', 'source-v3.json'), ('source-view-v3-held-for-restoration', 'source-v3.json'))}
SUCCESS = 'PASS saved due cleanup, complete duplicate-source disposal authority and original/native/book protection; no deletion repeats.\n'
EXCLUDED = {'proof.json', 'manifest.json'} | {
    label + suffix for label in ('seal', 'default', 'staged-doctrines')
    for suffix in ('-started.json', '-actual.json')}


def need(value, message):
    if not value:
        raise ValueError(message)


def read(name):
    return json.loads((BASE / name).read_bytes())


def ordinary(row):
    members = [entry['path'] for entry in row['artifacts']]
    need(members == sorted(set(members)), 'unique complete ordinary artifact population')
    for entry in row['artifacts']:
        path = Path(entry['path'])
        need(not path.is_absolute() and not {'..', '.git'}.intersection(path.parts)
             and path.suffix in SUFFIXES, 'ordinary relative artifact scope')
        need(set(entry) == {'path', 'bytes', 'device', 'inode', 'mode', 'nlink', 'mtime_ns'}
             and all(type(value) is int for key, value in entry.items() if key != 'path')
             and stat.S_ISREG(entry['mode']) and entry['bytes'] >= 0 and entry['nlink'] >= 1,
             'complete typed regular ordinary artifact metadata')
        need(all(entry['path'] != boundary['path'] and not entry['path'].startswith(boundary['path'] + '/')
                 for boundary in row['boundaries']), 'all Git/symlink/volume boundaries exclude')
    actual = row['independent_rg']
    need(type(actual['status']) is int and actual['status'] in (0, 1) and actual['stderr'] == ''
         and sorted(actual['stdout'].splitlines()) == members, 'independent complete ordinary artifact membership')
    roots = [base + '/' + tail for base in ('target', 'rust/target')
             for tail in ('release', 'debug/incremental', 'debug/deps')]
    need([entry['path'] for entry in row['rust']] == roots, 'complete conventional Rust locations')
    for entry in row['rust']:
        expected = [name for name in members if name.startswith(entry['path'] + '/') and name.endswith(('.bin', '.log'))]
        need(entry['status'] in ('absent', 'censused') and entry['retained'] == expected
             and (entry['status'] != 'absent' or not expected), 'complete retained Rust artifact census')


def authority(record, sources):
    need(record['owner'] == PLAN['owner'] and len(record['copies']) == len(ALLOWED)
         and {entry['path']: entry['source'] for entry in record['copies']} == ALLOWED,
         'only complete explicitly owned duplicate copy population')
    for entry in record['copies']:
        source = sources[entry['source']]
        need(entry['source_identity'] == pin(canonical(source))
             and record['sources'][entry['source']] == entry['source_identity'], 'whole immutable fixed Git source association')
        need(set(entry['files']) == set(source['members'])
             and sorted(set(entry['directories']) - {'.'}) == source['directories'], 'complete duplicate file/directory membership')
        root_device = entry['directories']['.']['dev']
        for name, node in entry['files'].items():
            expected = source['members'][name]
            need(set(node) == {'dev', 'ino', 'mode', 'size', 'nlink', 'mtime_ns'}
                 and all(type(value) is int for value in node.values()) and stat.S_ISREG(node['mode'])
                 and node['nlink'] == 1 and node['dev'] == root_device and node['size'] == expected['bytes']
                 and bool(node['mode'] & 0o111) == (expected['mode'] == '100755'), 'complete unshared same-volume exact-mode duplicate identities')
        actual = entry['independent']
        need(type(actual['status']) is int and actual['status'] == 0 and actual['stderr'] == ''
             and sorted(actual['stdout'].splitlines()) == sorted(str(Path(entry['path']) / name) for name in source['members']),
             'independent whole duplicate source membership')
        need(entry['disposition'] == 'delete', 'explicit disposition precedes each deletion')


def gate(label, command, stdout=None, *, current=False):
    row, started = read(label + '-actual.json'), read(label + '-started.json')
    need(all(row[key] == value for key, value in started.items()), 'whole started native declaration')
    need(type(row['status']) is int and row['status'] == 0
         and type(row['expected_status']) is int and row['expected_status'] == 0
         and row['command'] == ['scripts/run_with_ram_guard.sh', '--', *command], 'complete actual typed native success')
    need(row['programmes'] == row['programmes_after'], 'whole native programme epoch conserves')
    for name, entry in row['programmes'].items():
        body = entry['body'].encode() if 'body' in entry else bytes.fromhex(entry['body_hex'])
        need(pin(body) == entry['identity'], 'whole dated actual programme/input body')
        if current:
            need(Path(name).read_bytes() == body, 'whole current actual programme/input body')
    import re
    need(re.match(r'ram-guard: PID [0-9]+; host [0-9]+\.[0-9]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n', row['stderr'])
         and 'ram-guard: terminating PID tree' not in row['stderr'], 'unchanged successful cleanup RAM guard')
    if stdout is not None:
        need(row['stdout'] == stdout and row['stderr'].count('\n') == 1, 'whole intended cleanup native terminal')
    return pin(canonical(row))


def core(*, current=False):
    fact.preparation()
    sources = {name: json.loads((fact.PREPARATION / name).read_bytes()) for name in set(ALLOWED.values())}
    for source in sources.values():
        fact.source_census(source)
    record, declared = read('cleanup-result.json'), read('authority.json')
    authority(declared, sources)
    prior = subprocess.check_output(['git', '--no-replace-objects', 'show', PLAN['revision'] + ':docs/ARTIFACT_CLEANUP.md']).decode()
    need(record['owner'] == PLAN['owner'] and record['revision'] == PLAN['revision'] and record['prior_record'] == prior,
         'whole committed prior cleanup and dated authority')
    previous_time = datetime.fromisoformat(prior.splitlines()[2].split(' — ', 1)[0])
    need((datetime.fromisoformat(record['utc']) - previous_time).total_seconds() > 86400, 'actual due daily interval')
    ordinary(record['before'])
    ordinary(record['after'])
    expected = {entry['path']: entry for entry in record['before']['artifacts']
                if not any(entry['path'].startswith(root + '/') for root in ALLOWED)}
    need({entry['path']: entry for entry in record['after']['artifacts']} == expected, 'all other ordinary artifact identities conserve')
    need(record['authority'] == pin((BASE / 'authority.json').read_bytes())
         and record['protected'] == pin(canonical(declared['protected'])), 'whole deletion authority and protected-data custody')
    for index, (entry, actual) in enumerate(zip(declared['copies'], record['removed'], strict=True)):
        need(actual == read('removal-' + str(index) + '.json') and type(actual['status']) is int and actual['status'] == 0
             and actual['path'] == entry['path'] and actual['files'] == len(entry['files'])
             and actual['logical_bytes'] == sum(node['size'] for node in entry['files'].values())
             and actual['residue'] == [], 'exact completed duplicate disposal and dated residue')
    need([entry['name'] for entry in declared['controls']] == ['protected book selection', 'omitted copy member', 'changed whole copy identity'],
         'complete actual protected/member/whole-byte authority interventions')
    post = read('post-core-result.json')
    need(type(post['status']) is int and post['status'] == 0 and post['stderr'] == ''
         and post['command'] == ['python3', '-B', 'docs/audits/raw-canonical-publication-20261011/verify.py', '--core']
         and post['stdout'] == 'PASS complete finite raw admission and current canonical core; delivery remains separate.\n'
         and set(post['before']) == set(ALLOWED) and post['before'] == post['after']
         and all(value is False for value in post['before'].values()), 'actual current core with every selected ignored view absent')
    native = {
        'cleanup': gate('gate-cleanup', ['python3', '-B', str(BASE / 'cleanup.py')],
            'PASS due artifact cleanup: exact authenticated duplicate copies removed; original/native/compiler/book data retain.\n', current=current),
        'post-core': gate('gate-post-core', ['python3', '-B', str(BASE / 'after.py')],
            'PASS current canonical core without any selected ignored view; original source/native evidence remains qualified.\n', current=current)}
    controls = []
    for name, mutate, cause in (
        ('protected root selection', lambda r: r['copies'][0].update(path='docs/book/book'), 'only complete explicitly owned duplicate copy population'),
        ('missing source member', lambda r: r['copies'][0]['files'].pop(next(iter(r['copies'][0]['files']))), 'complete duplicate file/directory membership'),
        ('Boolean file size', lambda r: next(iter(r['copies'][0]['files'].values())).update(size=True), 'complete unshared same-volume exact-mode duplicate identities')):
        altered = copy.deepcopy(declared)
        mutate(altered)
        try:
            authority(altered, sources)
        except ValueError as error:
            need(str(error) == cause, 'intended saved disposal authority refusal')
            controls.append(dict(name=name, cause=str(error)))
        else:
            raise ValueError('changed disposal authority accepted')
    return dict(owner=PLAN['owner'], record=pin(canonical(record)), authority=pin(canonical(declared)),
                sources={name: pin(canonical(source)) for name, source in sources.items()}, native=native, controls=controls,
                condition=PLAN['condition'], legs=dict(
                    rederive='Complete fixed Git source bodies/modes, whole dated file/directory/node identities, independent rg/os.walk membership, exact removal/residue and protected-byte custody.',
                    falsify='Actual protected-path, missing-member and changed-whole-byte checks reject before deletion; independent saved protected/member/Boolean-size controls reject.',
                    durability='Whole source authority, original archived bodies, complete classification/census/native streams, per-copy disposal outcomes, protected data and saved no-deletion reader. Logical byte sizes are not physical disk reclamation claims.'))


def catalogue():
    result = {}
    for path in sorted(BASE.iterdir()):
        need(not path.is_symlink() and stat.S_ISREG(path.lstat().st_mode)
             and path.stat().st_dev == Path.cwd().stat().st_dev, 'complete ordinary flat cleanup archive')
        if path.name not in EXCLUDED:
            result[path.name] = pin(path.read_bytes())
    return result


def publication(*, current=False):
    row = read('publication.json')
    expected = {'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md',
                'docs/book/src/09-generated-hdl-debugging-and-inspection.md',
                'doctrine/live_document_size/surfaces.jsonl', 'MEMORY.md',
                'docs/TASK_TREE.md', 'docs/ARTIFACT_CLEANUP.md'}
    need(row['owner'] == PLAN['owner'] and set(row['snapshots']) == expected,
         'complete owned cleanup publication population')
    source = {}
    for name, roles in row['snapshots'].items():
        need(set(roles) == {'before', 'after'}, 'complete cleanup source roles')
        source[name] = {}
        for role, entry in roles.items():
            path = Path(entry['snapshot'])
            need(path.parent == BASE and path.name.startswith('publication-' + role + '-')
                 and path.suffix == '.gz' and not path.is_symlink(), 'ordinary cleanup source snapshot')
            body = gzip.decompress(path.read_bytes())
            need(pin(body) == entry['identity'], 'whole cleanup source role bytes')
            source[name][role] = body
    chapter = source['docs/book/src/09-generated-hdl-debugging-and-inspection.md']
    need(chapter['before'].count(row['old_guide'].encode()) == 1
         and chapter['after'] == chapter['before'].replace(row['old_guide'].encode(), row['guide'].encode(), 1),
         'sole complete cleanup guidance replacement')
    from publish import metrics
    tracked = subprocess.check_output(['git', '--no-replace-objects', 'ls-tree', '-r', '--name-only', PLAN['revision']]).decode().splitlines()
    import re
    need(row['book_names'] == sorted(name for name in tracked if re.fullmatch(r'docs/book/src/[^/]+\.md', name))
         and row['task_names'] == sorted(name for name in tracked if re.fullmatch(r'docs/tasks/(?:[^/]+|segments/[^/]+/[^/]+)\.md', name)),
         'complete fixed-revision cleanup book/task membership')
    def dated(name):
        return source[name]['after'] if name in source else subprocess.check_output(
            ['git', '--no-replace-objects', 'show', PLAN['revision'] + ':' + name])
    books = {name: dated(name) for name in row['book_names']}
    tasks = {name: dated(name) for name in row['task_names']}
    need(metrics(books) == row['book_after'] and metrics(tasks) == row['task_metrics'],
         'complete dated cleanup book/task metrics')
    registry = source['doctrine/live_document_size/surfaces.jsonl']
    before, after = (list(map(json.loads, registry[role].splitlines())) for role in ('before', 'after'))
    need(len(before) == len(after), 'whole unchanged surface population')
    for old, new in zip(before, after, strict=True):
        allowed = copy.deepcopy(old)
        if old.get('surface_id') == 'task_evidence':
            for key, value in row['task_metrics'].items():
                need(value <= old['enforcement_ceilings'][key], 'unchanged cleanup task ceiling')
                allowed['transition']['max_growth'][key] = max(0, value + old['transition']['ratchet_step'][key] - old['baseline'][key])
        elif old.get('surface_id') == 'shipped_behavior':
            change = new['reference_contract']['aggregate_change']
            need(change['owner'] == PLAN['owner'] and change['authority_id'] == 'ARTIFACT-SWEEP-DUE-20261011'
                 and change['baseline'] == {key: row['book_before'][key] for key in change['baseline']}
                 and change['delta'] == {key: row['book_after'][key] - row['book_before'][key] for key in change['delta']},
                 'exact owned cleanup book aggregate authority')
            allowed['reference_contract']['aggregate_change'] = change
        need(new == allowed, 'only measured cleanup task/book authority changes; other allowances and ceilings retain')
    correction = read('publication-role-correction.json')
    task = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
    registry_name = 'doctrine/live_document_size/surfaces.jsonl'
    need(correction['owner'] == PLAN['owner'] and set(correction['snapshots']) == {task, registry_name},
         'complete separately owned dated-role correction')
    original = {name: source[name]['after'] for name in (task, registry_name)}
    for name, roles in correction['snapshots'].items():
        previous = gzip.decompress(Path(roles['before']['snapshot']).read_bytes())
        updated = gzip.decompress(Path(roles['after']['snapshot']).read_bytes())
        need(pin(previous) == roles['before']['identity'] and pin(updated) == roles['after']['identity']
             and previous == source[name]['after'], 'whole original and corrected dated publication roles')
        source[name]['after'] = updated
    start = original[task].index(('- ID: `' + PLAN['owner'] + '`\n').encode())
    locus = original[task].index(b'  Acceptance Checklist (enforced):\n', start)
    need(source[task]['after'] == original[task][:locus] + correction['finding'].encode() + original[task][locus:],
         'only the owned dated-role finding changes task source')
    tasks[task] = source[task]['after']
    measured = metrics(tasks)
    old_rows, new_rows = (list(map(json.loads, raw.splitlines()))
                          for raw in (original[registry_name], source[registry_name]['after']))
    need(len(old_rows) == len(new_rows), 'unchanged corrected registry population')
    for old, new in zip(old_rows, new_rows, strict=True):
        allowed = copy.deepcopy(old)
        if old.get('surface_id') == 'task_evidence':
            for key, value in measured.items():
                need(value <= old['enforcement_ceilings'][key], 'unchanged corrected task ceiling')
                allowed['transition']['max_growth'][key] = max(0, value + old['transition']['ratchet_step'][key] - old['baseline'][key])
        need(new == allowed, 'only exact measured task growth changes for dated-role correction')
    need(correction['task_metrics'] == measured, 'complete corrected task metrics')
    if current:
        need(all(Path(name).read_bytes() == roles['after'] for name, roles in source.items()),
             'whole current cleanup publication source')
    return dict(identity=pin(canonical(row)), correction=pin(canonical(correction)),
        native=gate('gate-publish', ['python3', '-B', str(BASE / 'publish.py')],
        'Published dated cleanup guidance and closed only daily cleanup; unchanged full raw acceptance remains next.\n', current=current))


def role_controls(*, current=False):
    before = read('gate-dated-role-before-actual.json')
    need(type(before['status']) is int and before['status'] == 1
         and type(before['expected_status']) is int and before['expected_status'] == 1
         and before['command'] == ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', str(BASE / 'dated_role_before.py')]
         and before['programmes'] == before['programmes_after'] and before['stdout'] == ''
         and before['stderr'].endswith('ValueError: whole current cleanup publication source\n'),
         'actual original saved/current conflation refuses intended source predicate')
    row = read('saved-role-controls.json')
    need(row['changed'] == row['before'] + '\n<!-- owned later-pointer intervention -->\n'
         and row['restored'] == row['before'], 'genuine later pointer and exact restoration')
    for name, body in row['programmes'].items():
        need(name in (str(BASE / 'verify.py'), str(BASE / 'publish.py'))
             and (BASE / ('role-tested-' + Path(name).name + '.txt')).read_text() == body,
             'whole actual dated role-test programme bodies retain')
    need(set(row['programmes']) == {str(BASE / 'verify.py'), str(BASE / 'publish.py')}
         and set(row['results']) == {'saved', 'current'}, 'complete actual separating source roles')
    for role, actual in row['results'].items():
        code = ("import sys; sys.path.insert(0, 'docs/audits/artifact-sweep-due-20261011'); "
                "import verify; verify.publication(current=" + str(role == 'current') + "); print('PASS " + role + " publication role')")
        need(type(actual['status']) is int and actual['command'] == ['python3', '-B', '-c', code],
             'exact actual typed separating role invocation')
        if role == 'saved':
            need(actual['status'] == 0 and actual['stdout'] == 'PASS saved publication role\n' and actual['stderr'] == '',
                 'actual saved publication accepts changed later pointer')
        else:
            need(actual['status'] == 1 and actual['stdout'] == ''
                 and actual['stderr'].endswith('ValueError: whole current cleanup publication source\n'),
                 'actual current selector refuses changed later pointer')
    return dict(before=pin(canonical(before)), controls=pin(canonical(row)),
        correction=gate('gate-correct', ['python3', '-B', str(BASE / 'correct.py')],
            'PASS separate saved/current role correction; original dated publication and disposal authority retain.\n', current=current),
        native=gate('gate-roles', ['python3', '-B', str(BASE / 'roles.py')],
            'PASS actual saved reader accepts later pointer while current selector refuses; exact original bytes restore.\n', current=current))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--core', action='store_true')
    parser.add_argument('--seal', action='store_true')
    parser.add_argument('--current', action='store_true', help='also require current publication and programme bytes')
    args = parser.parse_args()
    need(not (args.core and args.seal), 'one explicit cleanup qualification role')
    result = core(current=args.current or args.seal)
    if args.core:
        print('PASS complete saved cleanup/source authority core; no deletion repeats.')
        return
    result['publication'] = publication(current=args.current or args.seal)
    result['roles'] = role_controls(current=args.current or args.seal)
    commands = {
        'focused': ['prove', '-v', 't/1549-task-tree-integrity-doctrine.t', 't/1636-claim-verification-doctrine.t',
                    't/1303-isf-public-live-book-paths-audit.t', 't/1305-isf-book-feature-matrix-audit.t'],
        'book': ['mdbook', 'build', 'docs/book'], 'size': ['scripts/check_live_document_size.sh'],
        'native': ['python3', '-B', 'scripts/check_record_value_publication.py', '--build', 'docs/book/book'],
        'claims': ['scripts/check_claim_verification.pl'],
        'inventory-write': ['scripts/check_claim_verification_inventory.pl', '--write'],
        'inventory': ['scripts/check_claim_verification_inventory.pl'],
        'size-corrected': ['scripts/check_live_document_size.sh'],
        'inventory-write-corrected': ['scripts/check_claim_verification_inventory.pl', '--write'],
        'inventory-corrected': ['scripts/check_claim_verification_inventory.pl']}
    result['external'] = {name: gate(name, command, current=args.current or args.seal) for name, command in commands.items()}
    need('All tests successful' in read('focused-actual.json')['stdout'], 'actual focused cleanup regression success')
    if args.seal:
        save('proof.json', result)
        save('manifest.json', catalogue())
    else:
        need(read('proof.json') == result and read('manifest.json') == catalogue(), 'whole immutable dated cleanup proof')
    print(SUCCESS, end='')


if __name__ == '__main__':
    main()

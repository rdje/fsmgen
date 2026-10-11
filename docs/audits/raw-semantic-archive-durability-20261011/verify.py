"""Complete required-archive Git custody; no semantic or original native promotion."""
import argparse
import os
import re
import subprocess
from common import *

REPAIR = Path('docs/audits/raw-semantic-association-product-gate-repair-20261011')
ARCHIVE = REPAIR / 'first-epoch.zip'
BOOK = 'docs/book/src/13k-isf-feature-support-matrix.md'
SURFACES = 'doctrine/live_document_size/surfaces.jsonl'
SUCCESS = 'PASS complete required archive and whole construction/repair Git custody; original semantic/native/private scopes conserve.\n'


def actual(name, command, success=True):
    row = load('checks.json')[name]
    need(row['command'] == command and type(row.get('status')) is int
         and (row['status'] == 0 if success else row['status'] != 0), 'actual complete archive-custody role: ' + name)
    need(row['programmes'] == programs() and row['inputs'] == row['inputs_after'] and row['epoch_conserved'] is True,
         'whole current custody programme and source epoch: ' + name)
    return row


def source():
    names = git('ls-tree', '-r', '--name-only', REVISION, '--', str(PRIOR), str(REPAIR)).decode().splitlines()
    need(str(ARCHIVE) not in names, 'actual original committed archive absence')
    fixed = fixed_sources(names)
    observed = sorted(str(path) for root in (PRIOR, REPAIR) for path in root.rglob('*') if path.is_file() or path.is_symlink())
    need(observed == sorted(names + [str(ARCHIVE)]), 'whole unchanged construction/repair member population plus exact missing archive')
    for name, body in fixed.items():
        need(local(name).read_bytes() == body, 'whole fixed/current original construction and repair source byte equality')
    archive = identity(ARCHIVE)
    need(archive == load('before-gap.json')['identity']
         == json.loads(local(REPAIR / 'qualified-manifest.json').read_bytes())['first-epoch.zip'],
         'whole required authenticated archive unchanged before and after forced tracking')
    members = {name: identity(name) for name in observed}
    directories = sorted(str(path) for root in (PRIOR, REPAIR) for path in (root, *root.rglob('*')) if path.is_dir())
    return dict(revision=REVISION, members=members, directories=directories, archive=str(ARCHIVE))


def nodes(raw):
    matches = list(re.finditer(rb'^- ID: `([^`]+)`\n.*?(?=^- ID: |\Z)', raw, re.M | re.S))
    result = {match[1].decode(): match[0] for match in matches}
    need(len(result) == len(matches), 'unique complete custody task identities')
    return result


def field(block, name):
    match = re.search(rb'^  ' + name.encode() + rb': `(.*)`$', block, re.M)
    return match[1] if match else None


def contracts(final):
    before = git('show', REVISION + ':' + TASK)
    declared = gzip.decompress(local(BASE / 'declared-task.md.gz').read_bytes())
    old, start, end = nodes(before), nodes(declared), nodes(final)
    parent = OWNER.rsplit('.', 1)[0]
    need(set(start) == set(old) | {OWNER} and set(end) == set(start), 'only the required custody child is declared')
    for key in old:
        if key == parent:
            need(all(field(old[key], k) == field(start[key], k) == field(end[key], k) for k in ('Goal', 'Acceptance'))
                 and field(old[key], 'Status') == field(end[key], 'Status') == b'done'
                 and field(start[key], 'Status') == b'active'
                 and field(start[key], 'Children') == field(end[key], 'Children') == OWNER.encode(),
                 'whole original construction acceptance reopens only for exact custody and closes unchanged')
        else:
            need(old[key] == start[key] == end[key], 'every unrelated original task node conserves')
    need(all(field(start[OWNER], k) == field(end[OWNER], k) for k in ('Goal', 'Acceptance'))
         and field(start[OWNER], 'Status') == b'active' and field(end[OWNER], 'Status') == b'done',
         'complete declared custody child closes without narrowing')
    return dict(original=pin(before), declared=pin(declared), final=pin(final))


def core():
    condition = source()
    command = ['perl', str(BASE / 'durability.pl')]
    before = actual('git-custody-before-final', command, success=False)
    need(before['stdout'] == '' and before['stderr'].startswith('required archived repair member is absent from Git index at '),
         'actual intended missing required Git member before correction')
    after = actual('git-custody-after-final', command)
    need(after['stderr'] == '', 'whole actual independent staged/source census stream')
    native = json.loads(after['stdout'])
    wanted = {name: dict(bytes=row['bytes'], sha256=row['sha256'], executable=row['executable'])
              for name, row in condition['members'].items()}
    observed = {name: dict(bytes=row['bytes'], sha256=row['sha256'], executable=row['mode'] == '100755')
                for name, row in native['members'].items()}
    need(wanted == observed and condition['directories'] == native['directories'],
         'whole independent Python source and native Git/member/mode/directory parity')
    fresh = subprocess.run(command, capture_output=True)
    result = dict(command=command, status=fresh.returncode, stdout=fresh.stdout.decode(), stderr=fresh.stderr.decode())
    need(type(result['status']) is int and result['status'] == 0 and result['stderr'] == ''
         and json.loads(result['stdout']) == native, 'fresh complete current Git/source custody, never an old result borrowed as current')
    for name, argv, expected in (
        ('construction-default', ['python3', '-B', str(PRIOR / 'verify.py')],
         'PASS complete source-bound raw-body candidate construction, independent whole original body conservation and strict dated custody; independent semantic reconstruction and separating controls remain pending.\n'),
        ('layout-default', ['python3', '-B', str(REPAIR / 'qualify.py')],
         'PASS whole first repair epoch, dated original reader, typed source copies, fresh separate native width parity and exact retirement; all document allowances remain unchanged.\n')):
        row = actual(name, argv)
        need(row['stdout'] == expected and row['stderr'] == '', 'whole fresh complete sealed default in its proper role')
    return dict(scope=SCOPE, source=condition, before=pin(canonical(before)), after=pin(canonical(after)), fresh=result,
        independence='Separate Perl reads the actual Git index and whole blob stream, while Python compares whole fixed Git/source bytes and independent current file identities. Required archive bytes match the earlier authenticated complete manifest; no old source programme or first result is overwritten.')


def publication():
    import publish
    record = load('publication.json')
    tasks = fixed_sources(record['task_names'])
    task = gzip.decompress(local(BASE / 'qualified-task.md.gz').read_bytes())
    tasks[TASK] = task
    need(metrics(tasks) == load('task-census.json'), 'whole exact measured custody task collection')
    books = fixed_sources(record['book_names'])
    before = gzip.decompress(local(BASE / 'book-before.md.gz').read_bytes())
    after = gzip.decompress(local(BASE / 'book-after.md.gz').read_bytes())
    need(before == books[BOOK] and after == before.replace(publish.MARKER, publish.ADDITION + publish.MARKER, 1),
         'whole exact current-Git custody book addition without semantic promotion')
    registry = fixed_sources([SURFACES])[SURFACES]
    need(local(BASE / 'registry-before.txt').read_bytes() == registry
         and local(BASE / 'registry-after.txt').read_bytes() == publish.authority(registry, tasks, books, after),
         'complete measured custody authority without widened ceilings')
    return dict(contracts=contracts(task), book=pin(after), registry=pin(local(BASE / 'registry-after.txt').read_bytes()))


def catalog():
    rows = {}
    for path in sorted(BASE.iterdir()):
        local(path)
        if path.name not in ('manifest.json', 'checks.json'):
            rows[path.name] = identity(path)
    return rows


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--seal', action='store_true')
    args = parser.parse_args()
    proof = dict(owner=OWNER, revision=REVISION, scope=SCOPE, custody=core(), publication=publication(),
        legs=dict(rederive='Whole fixed Git/source namespace bytes plus the exact already-authenticated required archive.',
                  falsify='Actual missing-member refusal before forced tracking and separate native complete index/blob/source/mode/directory census afterward; default freshly reruns current Git custody.',
                  durability='The required ZIP is itself tracked with complete Git bytes; whole programmes/commands/streams, task contracts and strict namespace retain in the owning commit.'),
        condition='Construction and repair instruments require the complete fixed 8bdb187 source condition plus the exact authenticated archive. Current staged Git custody freshly reexecutes; no original native/semantic currency follows.')
    if args.seal:
        save('proof.json', proof)
        save('manifest.json', catalog())
    else:
        need(load('proof.json') == proof and load('manifest.json') == catalog(), 'whole strict current-Git custody proof and source namespace')
    print(SUCCESS, end='')

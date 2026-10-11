"""Qualify the whole first repair epoch in typed archival storage, without a live Markdown surface."""
import argparse
import gzip
import json
import re
import stat
import subprocess
import sys
import zipfile
from pathlib import Path

sys.path.insert(0, 'docs/audits/raw-semantic-association-product-20261011')
from common import BASE as PRODUCT, OWNER, REVISION, canonical, identity, load, local, need, pin, programs

BASE = Path('docs/audits/raw-semantic-association-product-gate-repair-20261011')


def write(name, raw):
    path = local(BASE / name, exists=False)
    need(not path.exists(), 'retain first complete qualified archival layout evidence')
    path.write_bytes(raw)


def archived():
    members, modes = {}, {}
    with zipfile.ZipFile(local(BASE / 'first-epoch.zip')) as archive:
        for entry in archive.infolist():
            need('/' not in entry.filename and entry.filename not in ('', '.', '..')
                 and entry.filename not in members and stat.S_ISREG(entry.external_attr >> 16),
                 'whole ordinary closed first-epoch archive member')
            members[entry.filename] = archive.read(entry)
            modes[entry.filename] = bool((entry.external_attr >> 16) & 0o111)
    manifest = json.loads(members['manifest.json'])
    need(set(members) == set(manifest) | {'manifest.json'}, 'whole first-epoch archived namespace and directory closure')
    need(all(dict(**pin(members[name]), executable=modes[name]) == expected for name, expected in manifest.items()),
         'every whole first-epoch byte and executable mode')
    first = load('checks.json')['index-width-repair']
    old_path = str(BASE / 'repair.py')
    need(type(first['status']) is int and first['status'] == 0
         and first['command'] == ['python3', '-B', old_path]
         and first['inputs'][old_path] == first['inputs_after'][old_path] == pin(members['repair.py'])
         and first['programmes'] == programs(), 'whole first actual repair command and original programme epoch')
    namespace = {'__name__': 'whole_dated_first_index_repair'}
    exec(compile(members['repair.py'], old_path, 'exec'), namespace)
    original_proof = json.loads(members['proof.json'])
    original_native = json.loads(members['native-width.json'])
    original_failure = json.loads(members['first-size-refusal.json'])
    need(original_failure == load('checks.json')['size'], 'whole first actual size refusal retained')
    derived = namespace['check'](members['index-before.md'], members['index-after.md'], original_failure, original_native)
    need(original_proof['qualification'] == derived, 'complete dated first reader qualification in its original whole source context')
    return members, namespace, derived


def task_transition():
    before = local(BASE / 'task-before.txt').read_bytes()
    after = local(BASE / 'task-after.txt').read_bytes()
    need(before == gzip.decompress(local(PRODUCT / 'qualified-task.md.gz').read_bytes()), 'whole original qualified construction task source')
    pattern = rb'^- ID: `' + re.escape(OWNER.encode()) + rb'`\n.*?(?=^- ID: |\Z)'
    match = re.search(pattern, before, re.M | re.S)
    need(match is not None, 'unique owning construction task before findings correction')
    replacement = re.search(pattern, after, re.M | re.S)
    need(replacement is not None, 'unique owning construction task after findings correction')
    clean = lambda raw: re.sub(rb'^  Findings: `.*`$', b'  Findings: `owned gate corrections`', raw, flags=re.M)
    need(clean(match[0]) == clean(replacement[0])
         and before[:match.start()] == after[:replacement.start()]
         and before[match.end():] == after[replacement.end():] and len(after) <= len(before),
         'only non-growing owned Findings changes; every goal acceptance and other task node conserves')
    return dict(before=pin(before), after=pin(after))


def catalog():
    return {path.name: identity(path) for path in sorted(BASE.iterdir()) if path.name != 'qualified-manifest.json'}


def qualify(members, old, prior, native):
    for source, target in (('index-before.md', 'index-before.txt'), ('index-after.md', 'index-after.txt')):
        need(local(BASE / target).read_bytes() == members[source], 'whole typed copy of original index source')
    command = ['perl', '-e', old['NATIVE'], str(BASE / 'index-before.txt'), str(BASE / 'index-after.txt')]
    need(native['command'] == command and native['programme'] == old['NATIVE']
         and type(native['status']) is int and native['status'] == 0 and native['stderr'] == ''
         and json.loads(native['stdout']) == prior['metrics'], 'complete actual separate native census in the qualified typed layout')
    failure = json.loads(local(BASE / 'first-layout-refusal.json').read_bytes())
    need(failure == load('checks.json')['size-index'] and type(failure['status']) is int and failure['status'] == 1
         and all('tracked document is not covered by any surface: ' + str(BASE / name) in failure['stderr']
                 for name in ('index-before.md', 'index-after.md')), 'whole actual intended first layout refusal')
    need(not any((BASE / name).exists() for name in members), 'exact original first-epoch residue census after verified retirement')
    return dict(owner=OWNER, revision=REVISION, archive=identity(BASE / 'first-epoch.zip'),
        original_members={name: pin(raw) for name, raw in members.items()}, dated_reader=prior,
        typed_native=pin(canonical(native)), first_layout_refusal=pin(canonical(failure)), task=task_transition(),
        scope='Whole first repair source/programmes/native streams/manifests retain inside first-epoch.zip. Complete dated first-reader logic reexecutes against the original whole archived context. Typed text copies and fresh native width parity qualify the current storage layout; no earlier success is compared with a changed programme or granted current native currency.',
        legs=dict(rederive='Whole archived original namespace, unchanged dated reader, fixed cb5d85b9 Git source and complete typed copy equality.',
                  falsify='Original actual width/layout failures and freshly executed separate native byte-width census in the typed layout; exact no-residue census follows copy/verify/use/delete.',
                  durability='Every original filename and byte, full programmes/commands/streams, complete task transition and strict current archival manifest in the owning commit.'))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--seal-layout', action='store_true')
    args = parser.parse_args()
    members, old, prior = archived()
    if args.seal_layout:
        for name, raw in members.items():
            need(local(BASE / name).read_bytes() == raw, 'whole original source before archival layout migration')
        for source, target in (('index-before.md', 'index-before.txt'), ('index-after.md', 'index-after.txt')):
            write(target, members[source])
        write('first-layout-refusal.json', canonical(load('checks.json')['size-index']))
        command = ['perl', '-e', old['NATIVE'], str(BASE / 'index-before.txt'), str(BASE / 'index-after.txt')]
        epoch = {str(BASE / 'qualify.py'): pin(local(BASE / 'qualify.py').read_bytes())}
        result = subprocess.run(command, capture_output=True)
        native = dict(command=command, programme=old['NATIVE'], instrument_epoch=epoch,
                      inputs_after={path: pin(local(path).read_bytes()) for path in epoch},
                      status=result.returncode, stdout=result.stdout.decode(), stderr=result.stderr.decode())
        write('qualified-native-width.json', canonical(native))
        need(native['instrument_epoch'] == native['inputs_after'] and type(native['status']) is int
             and native['status'] == 0 and native['stderr'] == '' and json.loads(native['stdout']) == prior['metrics'],
             'use verified complete typed copies before retiring exact old source files')
        need(local('docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md').read_bytes() == local(BASE / 'task-after.txt').read_bytes(),
             'whole current owning task findings after logged gate failures')
        task_transition()
        for name, raw in members.items():
            path = local(BASE / name)
            need(path.read_bytes() == raw, 'exact verified old member immediately before retirement')
            path.unlink()
        proof = qualify(members, old, prior, native)
        write('qualified-proof.json', canonical(proof))
        write('qualified-manifest.json', canonical(catalog()))
    else:
        native = json.loads(local(BASE / 'qualified-native-width.json').read_bytes())
        need(native['instrument_epoch'] == native['inputs_after']
             == {str(BASE / 'qualify.py'): pin(local(BASE / 'qualify.py').read_bytes())}, 'whole unchanged qualified layout programme')
        proof = qualify(members, old, prior, native)
        need(json.loads(local(BASE / 'qualified-proof.json').read_bytes()) == proof
             and json.loads(local(BASE / 'qualified-manifest.json').read_bytes()) == catalog(), 'whole strict qualified archival namespace')
    print('PASS whole first repair epoch, dated original reader, typed source copies, fresh separate native width parity and exact retirement; all document allowances remain unchanged.')


if __name__ == '__main__':
    main()

"""Admit complete dated original/source inputs before address interpretation."""
import hashlib
import json
import re
import subprocess
import tarfile
from pathlib import Path

BASE = Path('docs/audits/address-raw-admission-20261010')
A = Path('docs/audits')
REVISION = 'c2b2a7f4a006bb267c4b077c37c5a295d24f44a5'
SOURCE = A / 'address-source-integration-20261010'
CLASS = A / 'record-value-class-frame-join-20261006'
COORD = A / 'coordinate-original-hostile-20261009'
CAPTURE = A / 'record-value-original-candidate-20261004'
ROLE = ('Complete dated original/raw/source prerequisite custody and actual replay only; '
        'reference-operand parsing, original numeric role/lifetime joins and governed '
        'canonical publication remain successor-owned. No original execution is recaptured.')
READERS = {
    'source': [str(SOURCE / 'verify.py')],
    'class-frame': [str(CLASS / 'verify.py')],
    'coordinate': [str(A / 'coordinate-original-hostile-checks-20261009/verify_hostile.py')],
}


def need(ok, why):
    if not ok:
        raise ValueError(why)


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def read(path):
    root = Path.cwd().resolve()
    path = Path(path)
    need(not path.is_absolute() and not {'..', '.git'}.intersection(path.parts), 'own relative admission input')
    full = root / path
    need(full.resolve() == full and full.is_file() and full.stat().st_dev == root.stat().st_dev,
         'plain same-volume admission input')
    for parent in full.parents:
        if parent == root:
            break
        need(not (parent / '.git').exists(), 'own repository admission boundary')
    return full.read_bytes()


def load(path):
    return json.loads(read(path))


def git(*args):
    run = subprocess.run(['git', '--no-replace-objects', *args], capture_output=True)
    need(run.returncode == 0 and not run.stderr, 'actual complete admission Git result')
    return run.stdout


def roots():
    selected = set(load(A / 'coordinate-original-intake-20261009/admission.json')['custody']['roots'])
    # Preserve entire audit namespaces, not only the files reached by a reader.
    for path in load(SOURCE / 'binding.json')['inputs']:
        selected.add(str(Path(path).parent) if path.startswith(str(A) + '/') else path)
    selected.update(map(str, (SOURCE, A / 'coordinate-original-intake-20261009',
        A / 'coordinate-original-intake-checks-20261009',
        A / 'coordinate-original-matching-qualified-20261009',
        A / 'coordinate-original-matching-qualified-checks-20261009',
        A / 'coordinate-expression-alternatives-20261009',
        A / 'coordinate-expression-alternative-checks-20261009',
        A / 'coordinate-observer-caller-20261009',
        A / 'coordinate-observer-caller-checks-20261009',
        A / 'coordinate-original-mismatch-20261009',
        COORD, A / 'coordinate-original-hostile-checks-20261009')))
    # Remove redundant children without losing their complete parent namespace.
    return sorted(p for p in selected if not any(p.startswith(q + '/') for q in selected if q != p))


def custody():
    selected = roots()
    tree = git('--literal-pathspecs', 'ls-tree', '-r', '-z', REVISION, '--', *selected)
    entries = {}
    for row in tree.rstrip(b'\0').split(b'\0'):
        header, name = row.split(b'\t', 1)
        mode, kind, oid = header.decode().split()
        need(kind == 'blob' and mode in ('100644', '100755') and name.decode() not in entries,
             'complete unique regular admission tree')
        entries[name.decode()] = {'mode': mode, 'oid': oid}
    command = ['git', '--no-replace-objects', '-c', 'tar.umask=0022', '--literal-pathspecs',
               'archive', '--format=tar', REVISION, '--', *selected]
    process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    members = {}
    try:
        with tarfile.open(fileobj=process.stdout, mode='r|') as archive:
            for member in archive:
                if member.isdir():
                    continue
                need(member.isfile() and member.name in entries and member.name not in members,
                     'complete regular admission archive membership')
                path = Path(member.name)
                # read validates repository/volume boundaries; archive comparisons stream
                # large members, so validate the path using its bounded parents instead.
                root, full = Path.cwd().resolve(), path.resolve()
                need(full == root / path and full.is_file() and full.stat().st_dev == root.stat().st_dev,
                     'plain same-volume streamed admission input')
                for parent in full.parents:
                    if parent == root:
                        break
                    need(not (parent / '.git').exists(), 'streamed admission repository boundary')
                digest, size = hashlib.sha256(), 0
                with archive.extractfile(member) as old, path.open('rb') as current:
                    while chunk := old.read(1024 * 1024):
                        need(current.read(len(chunk)) == chunk, 'complete fixed admission member bytes')
                        digest.update(chunk)
                        size += len(chunk)
                    need(not current.read(1), 'complete fixed admission member boundary')
                entry = entries[member.name]
                need(member.mode == (int(entry['mode'], 8) & 0o777), 'explicit admission archive transport mode')
                members[member.name] = {**entry, 'identity': {'bytes': size, 'sha256': digest.hexdigest()}}
    except BaseException:
        process.terminate()
        raise
    finally:
        process.stdout.close()
        stderr = process.stderr.read()
        status = process.wait()
        process.stderr.close()
    need(status == 0 and not stderr and set(members) == set(entries), 'whole actual admission archive success')
    for selected_root in selected:
        path = Path(selected_root)
        actual = {str(p) for p in path.rglob('*') if p.is_file() or p.is_symlink()} if path.is_dir() else {selected_root}
        expected = {p for p in entries if p == selected_root or p.startswith(selected_root + '/')}
        need(actual == expected and expected, 'complete admission namespace conservation')
    return {'revision': REVISION, 'roots': selected, 'members': members,
            'transport': {'command': command, 'status': status, 'stderr': stderr.decode()}}


def allocation():
    raw = load(CLASS / 'raw-product.json')
    source = load(SOURCE / 'hypotheses.json')
    qualified = load(CLASS / 'proofs.json')
    models = load(CLASS / 'source-models.json')
    coordinate = load(COORD / 'qualification.json')
    need(coordinate['original'] == raw and coordinate['source_models'] == models,
         'whole raw and source coordinate prerequisites conserve')
    keys, modes = set(), []
    for mode in raw['inventories']:
        domains = {}
        for name, rows in mode['domains'].items():
            nonempty = []
            for row in rows['nonempty']:
                key = (mode['mode'], name, row['index'])
                need(key not in keys, 'unique complete admission refusal')
                keys.add(key)
                need(pin(row['body'].encode()) == row['body_identity'], 'complete unnormalized original body identity')
                nonempty.append({'index': row['index'], 'body': row['body_identity'],
                                 'context': row['context'], 'wire_kind': row['wire_kind']})
            need(sorted(rows['empty_string_members'] + [r['index'] for r in nonempty]) == list(range(rows['population'])),
                 'complete empty/nonempty admission allocation')
            domains[name] = {'population': rows['population'], 'empty': rows['empty_string_members'], 'nonempty': nonempty}
        modes.append({'mode': mode['mode'], 'domains': domains})
    own = {(m['mode'], r['domain'], r['index']) for m in qualified['modes'] for r in m['cases']}
    views = [tuple(v['domain']) for m in source['modes'] for v in m['views']]
    phases = [(m['mode'], r['domain'], r['index'], p['phase'])
              for m in models['modes'] for r in m['cases'] for p in r['phases']]
    need(own == keys and set(views) == set(phases) and len(views) == len(phases),
         'whole source class/frame/phase admission membership')
    return {'modes': modes, 'source_views': views,
            'products': {str(p): pin(read(p)) for p in (CLASS / 'raw-product.json', CLASS / 'source-models.json',
                CLASS / 'proofs.json', SOURCE / 'hypotheses.json', SOURCE / 'proof.json', COORD / 'qualification.json')}}


def owners():
    path = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
    raw = git('show', REVISION + ':' + path)
    text = raw.decode()
    result = {}
    for folder in (SOURCE, CLASS, COORD):
        scope = read(folder / 'scope.txt').decode()
        identifier = re.search(r'(?:Owner: )?(SEMANTIC-INTROSPECTION-MCP-FRONTIER[.0-9]+)', scope)[1]
        marker = '- ID: `' + identifier + '`'
        need(text.count(marker) == 1, 'unique complete committed prerequisite owner')
        start = text.index(marker)
        end = text.find('\n- ID: ', start + len(marker))
        block = text[start:end if end >= 0 else None]
        need('\n  Status: `done`\n' in block, 'complete prerequisite owner is done')
        result[str(folder)] = {'id': identifier, 'body': block, 'scope': pin(scope.encode())}
    return {'path': path, 'task': pin(raw), 'completed': result}


def main():
    path = BASE / 'admission.json'
    need(not path.exists(), 'retain first complete raw/source admission')
    product = {'owner': (BASE / 'scope.txt').read_text().strip(), 'role': ROLE,
               'custody': custody(), 'allocation': allocation(), 'prerequisite_owners': owners(),
               'actual_readers': {name: load(BASE / 'checks.json')[name] for name in READERS}}
    path.write_text(json.dumps(product, sort_keys=True, indent=2) + '\n')
    print('PASS complete dated raw/source custody admission produced; independent qualification and operand/address meanings remain required.')


if __name__ == '__main__':
    main()

"""Authenticate complete original inputs before selecting coordinate meanings."""
import hashlib
import json
import subprocess
import tarfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
BASE = Path('docs/audits/coordinate-original-intake-20261009')
REVISION = '390e4dda5eea6efac6637e65921524194a4aa68b'
A = Path('docs/audits')
CLASS = A / 'record-value-class-frame-join-20261006'
SOURCE = A / 'coordinate-source-hypotheses-20261009'
CAPTURE = A / 'record-value-original-candidate-20261004'
EXTRA = (CLASS, A / 'class-frame-join-checks-20261006', SOURCE,
         A / 'coordinate-source-hypothesis-checks-20261009',
         A / 'archive-transport-fact-20261009')
READERS = (
    ('source-hypotheses', A / 'coordinate-source-hypothesis-checks-20261009/verify_hypotheses.py'),
    ('class-frame', CLASS / 'verify.py'),
    ('archive-policy', A / 'archive-transport-fact-20261009/archive.py'))
ROLE = 'Complete original raw/source custody and lossless allocation only; coordinate selection and private/framework/formatter/toolchain/address/alias meanings remain successor-owned.'


def need(ok, why):
    if not ok:
        raise ValueError(why)


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def native(*args):
    result = subprocess.run(['git', '--no-replace-objects', *args], capture_output=True)
    need(result.returncode == 0 and not result.stderr, 'complete fixed original-intake Git result')
    return result.stdout


def fixed(path):
    raw = native('show', REVISION + ':' + str(path))
    need(Path(path).read_bytes() == raw, 'unchanged whole original-intake declaration')
    return raw


def roots():
    prior = json.loads(fixed(CLASS / 'binding.json'))
    source = json.loads(fixed(SOURCE / 'qualification.json'))
    selected = set(prior['inputs']) | set(source['custody']['roots']) | set(map(str, EXTRA))
    selected = sorted(selected)
    need(not any(p == str(BASE) or p.startswith(str(BASE) + '/') for p in selected), 'intake excludes its own outputs')
    return selected


def custody():
    selected = roots()
    tree = native('--literal-pathspecs', 'ls-tree', '-r', '-z', REVISION, '--', *selected)
    entries = {}
    for row in tree.rstrip(b'\0').split(b'\0'):
        fields, name = row.split(b'\t', 1)
        mode, kind, oid = fields.decode().split()
        path = name.decode()
        need(kind == 'blob' and mode in ('100644', '100755') and path not in entries,
             'complete unique own regular Git population')
        entries[path] = {'mode': mode, 'oid': oid}
    # Stream the full retained corpus. Read only one bounded member at a time,
    # and hash it in chunks instead of retaining an archive-sized byte string.
    command = ['git', '--no-replace-objects', '-c', 'tar.umask=0022', '--literal-pathspecs',
               'archive', '--format=tar', REVISION, '--', *selected]
    process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    actual = {}
    try:
        with tarfile.open(fileobj=process.stdout, mode='r|') as archive:
            for member in archive:
                if member.isdir():
                    continue
                need(member.isfile() and member.name in entries and member.name not in actual,
                     'exact unique complete archive membership')
                path = ROOT / member.name
                need(path.resolve() == path and path.is_file() and path.stat().st_dev == ROOT.stat().st_dev,
                     'unchanged own regular same-volume member')
                for parent in path.parents:
                    if parent == ROOT:
                        break
                    need(not (parent / '.git').exists(), 'original-intake own repository boundary')
                digest, size = hashlib.sha256(), 0
                with archive.extractfile(member) as old, path.open('rb') as current:
                    while chunk := old.read(1024 * 1024):
                        need(current.read(len(chunk)) == chunk, 'whole original member byte conservation')
                        digest.update(chunk); size += len(chunk)
                    need(not current.read(1), 'whole original member byte boundary')
                entry = entries[member.name]
                need(member.mode == int(entry['mode'], 8) & 0o777, 'explicit 0022 archive transport mode')
                actual[member.name] = {**entry, 'identity': {'bytes': size, 'sha256': digest.hexdigest()}}
    except BaseException:
        process.terminate()
        raise
    finally:
        process.stdout.close()
        stderr = process.stderr.read()
        status = process.wait()
        process.stderr.close()
    need(status == 0 and not stderr and set(actual) == set(entries), 'complete actual original-intake archive success')
    for selected_root in selected:
        path = Path(selected_root)
        members = {str(p) for p in path.rglob('*') if p.is_file() or p.is_symlink()} if path.is_dir() else {selected_root}
        expected = {p for p in actual if p == selected_root or p.startswith(selected_root + '/')}
        need(members == expected and expected, 'whole unchanged declared input namespace')
    return {'revision': REVISION, 'roots': selected, 'members': actual,
            'transport': {'command': command, 'status': status, 'stderr': stderr.decode()}}


def allocation():
    raw = json.loads(fixed(CLASS / 'raw-product.json'))
    sources = json.loads(fixed(CLASS / 'source-models.json'))
    qualified = json.loads(fixed(CLASS / 'proofs.json'))
    hypotheses = json.loads(fixed(SOURCE / 'qualification.json'))
    source_keys = {(r['mode'], r['domain'], r['index']) for r in hypotheses['refusals']}
    source_cases = {(m['mode'], r['domain'], r['index']) for m in sources['modes'] for r in m['cases']}
    qualified_cases = {(m['mode'], r['domain'], r['index']) for m in qualified['modes'] for r in m['cases']}
    native_keys, modes = set(), []
    for mode in raw['inventories']:
        domains = {}
        for domain, rows in mode['domains'].items():
            nonempty = []
            for row in rows['nonempty']:
                key = mode['mode'], domain, row['index']
                need(key not in native_keys, 'unique complete original refusal allocation')
                native_keys.add(key)
                nonempty.append({'index': row['index'], 'whole_body': row['body_identity'],
                    'whole_record': pin(json.dumps(row, sort_keys=True).encode()), 'original_selection': None})
            domains[domain] = {'population': rows['population'],
                'empty_string_members': rows['empty_string_members'], 'nonempty': nonempty}
        modes.append({'mode': mode['mode'], 'domains': domains})
    need(native_keys == source_keys == source_cases == qualified_cases, 'complete original/source/hypothesis refusal domain join')
    capture = json.loads(fixed(CLASS / 'binding.json'))['original_capture']
    need(capture['root'] == str(CAPTURE) and capture['modes'] == [m['mode'] for m in modes], 'complete original mode custody')
    return {'modes': modes, 'raw_product': pin(fixed(CLASS / 'raw-product.json')),
            'source_models': pin(fixed(CLASS / 'source-models.json')),
            'class_frame_qualification': pin(fixed(CLASS / 'proofs.json')),
            'source_hypotheses': pin(fixed(SOURCE / 'qualification.json')),
            'complete_capture': capture, 'unresolved': hypotheses['unresolved'],
            'scope': ROLE}


def main():
    need(Path.cwd().resolve() == ROOT, 'invoke original intake from repository root')
    need(not (BASE / 'seal.json').exists() and not (BASE / 'admission.json').exists(), 'refuse to rewrite original intake')
    before = custody()
    product = {'role': ROLE, 'owner': (BASE / 'scope.txt').read_text().strip(),
               'custody': before, 'allocation': allocation(), 'actual_readers': []}
    for name, path in READERS:
        command = ['python3', '-B', str(path)]
        run = subprocess.run(command, capture_output=True, text=True)
        product['actual_readers'].append({'name': name, 'command': command, 'status': run.returncode,
            'stdout': run.stdout, 'stderr': run.stderr, 'programme': pin(path.read_bytes())})
        need(run.returncode == 0 and not run.stderr, 'complete actual original-intake reader: ' + name)
    need(custody() == before, 'complete original-intake conservation after actual readers')
    product['legs'] = {'rederive': 'admit.py fixed Git archive stream, complete original allocations and actual unchanged readers.',
        'falsify': 'verify.py independently streams Git blobs, reselects every original empty/error allocation and reconstructs lossless bodies/coordinates/arguments, with genuine scope/source/allocation/result controls.',
        'durability': 'Fixed source epoch, complete member identities and original product references, sealed admission/programmes, retained actual results and normal-hook Git commit.'}
    (BASE / 'admission.json').write_text(json.dumps(product, sort_keys=True, indent=2) + '\n')
    print('PASS complete original raw/source custody and lossless allocations admitted; coordinate selection remains pending.')


if __name__ == '__main__':
    main()

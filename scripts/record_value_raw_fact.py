"""Authenticate admitted finite raw source facts at their original source epochs."""
import hashlib
import json
from pathlib import Path
import subprocess

import book_source_references as plane
import record_value_observer_fact as finite
import record_value_observer_namespace_fact as namespace

PREPARATION = Path('docs/audits/raw-canonical-preparation-20261011')
CARD = 'docs/knowledge/record-value-finite-copy-probe-reader.md'
CANDIDATE = {'bytes': 15449, 'sha256': 'ef7b15d1140a3d39a64834cbd815b1a099b643189e4b8085c5dead67e78303ad'}
EXTRAS = {'default-actual.json': {'bytes': 91885,
                         'sha256': '05d444017c103cd6cd1a5a06e4d4dc65a0d65edd397dfb9685b1632032caa732'},
 'default-started.json': {'bytes': 46033,
                          'sha256': '8876aac711d019c9c609ff5c957b7d006b578e600cec10ccde00751d7c744c58'},
 'manifest.json': {'bytes': 10733,
                   'sha256': 'f96ab59e57c9302ed43bc907af6cd85d8babb0e59292c6f7266ebff3f2280b9d'},
 'proof.json': {'bytes': 191324,
                'sha256': 'f426739f810b1ec98313bccd0f47f56cba0e519d90a53b48d85085d18c948757'},
 'seal-actual.json': {'bytes': 91888,
                      'sha256': 'df7d13bccd2ed63a742e3133cc8b839daae224f937ff6292dc5873e7e79d15ca'},
 'seal-started.json': {'bytes': 46036,
                       'sha256': '19d4adb3f94d512368be63c440a5df8e227ff077496368ff5174513fdc14bf5e'},
 'staged-doctrines-actual.json': {'bytes': 119958,
                                  'sha256': '386ec8fa876ffe537ea92b441df53ed22ef417302fbda97a2ada0bbb23fc9161'},
 'staged-doctrines-started.json': {'bytes': 27142,
                                   'sha256': '9b59e7469574402255835e5ff0af1954003dbf33aa9e93db387a96251140b01c'}}
PARENT_SUCCESS = 'PASS complete unchanged raw semantic parent acceptance; canonical and higher native/private scopes remain open.\n'
GUIDE = '''Canonical raw facts qualify finite source joins, nested causes, whole bodies
and controls. Fixed-source replay preserves earlier epochs; full raw closure
remains separate. Recovery refuses unsafe paths/conflicts. Earlier failures and
unknown interrupted peak RSS/first launch diagnostic retain; native/private stay open.

'''


def require(condition, cause):
    if not condition:
        raise ValueError(cause)


def encoded(value):
    return (json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=True, allow_nan=False) + '\n').encode()


def admission():
    return json.loads(finite.local(PREPARATION / 'candidate.json', CANDIDATE))


def published(candidate):
    before, after = candidate['before'], candidate['after']
    require(candidate['target'] == CARD and finite.identity(before.encode()) == candidate['before_identity']
            and finite.identity(after.encode()) == candidate['after_identity'], 'whole admitted raw candidate bodies')
    require(before.split('---\n', 2)[:2] == after.split('---\n', 2)[:2],
            'all admitted original raw fact questions evidence and probes retain')
    for key, value in candidate['proposed'].items():
        require(type(value) is int and type(candidate['previous'][key]) is int
                and value <= candidate['previous'][key], 'non-growing admitted raw candidate')
    require(after.count('date: 2026-10-10\n') == 1, 'exact original raw fact date')
    # This admission's date changes without changing any capacity dimension.
    return after.replace('date: 2026-10-10\n', 'date: 2026-10-11\n', 1)


def cards(previous):
    candidate = admission()
    require(CARD in previous and previous[CARD] == candidate['before'], 'whole predecessor raw meanings and routes')
    result = dict(previous)
    result[CARD] = published(candidate)
    return result


def preparation():
    manifest = json.loads(finite.local(PREPARATION / 'manifest.json', EXTRAS['manifest.json']))
    declared, modes = {}, {}
    for name, entry in manifest.items():
        require(Path(name).name == name and type(entry) is dict
                and set(entry) == {'bytes', 'sha256', 'executable'} and type(entry['executable']) is bool,
                'closed complete raw preparation member')
        declared[name] = {k: entry[k] for k in ('bytes', 'sha256')}
        modes[name] = entry['executable']
    require(not set(declared).intersection(EXTRAS), 'distinct raw preparation seal and external receipt roles')
    declared.update(EXTRAS)
    modes.update({name: False for name in EXTRAS})
    plane.local_parents(plane.ROOT / PREPARATION / 'endpoint')
    namespace.check_tree(plane.ROOT / PREPARATION, declared)
    require(all(bool((plane.ROOT / PREPARATION / name).stat().st_mode & 0o111) == mode
                for name, mode in modes.items()), 'complete raw preparation executable modes')
    return declared


def source_census(source):
    """Check the complete dated Git graph without comparing it to later live code."""
    result = subprocess.run(['git', '--no-replace-objects', '--literal-pathspecs', 'ls-tree',
                             '-r', '-z', source['revision'], '--', *source['roots']],
                            cwd=plane.ROOT, capture_output=True)
    require(result.returncode == 0 and result.stderr == b'', 'complete original raw fixed source selection')
    entries = {}
    for record in result.stdout.rstrip(b'\0').split(b'\0'):
        header, name = record.split(b'\t', 1)
        mode, kind, oid = header.decode().split()
        path = name.decode()
        plane.relative(path)
        require(kind == 'blob' and mode in ('100644', '100755') and path not in entries,
                'ordinary unique original raw fixed source member')
        entries[path] = dict(mode=mode, oid=oid)
    require(set(entries) == set(source['members'])
            and all(entry == {k: source['members'][name][k] for k in ('mode', 'oid')}
                    for name, entry in entries.items()), 'complete original raw fixed Git object population')
    directories = sorted({str(parent) for name in entries for parent in Path(name).parents if str(parent) != '.'})
    require(directories == source['directories'], 'complete original raw source directory graph')
    process = subprocess.Popen(['git', '--no-replace-objects', 'cat-file', '--batch'], cwd=plane.ROOT,
                               stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    try:
        for name, entry in sorted(entries.items()):
            expected = source['members'][name]
            process.stdin.write(entry['oid'].encode() + b'\n')
            process.stdin.flush()
            header = process.stdout.readline().split()
            require(len(header) == 3 and header[0].decode() == entry['oid'] and header[1] == b'blob'
                    and type(expected['bytes']) is int and int(header[2]) == expected['bytes'],
                    'complete original raw source blob header')
            remaining = expected['bytes']
            digest = hashlib.sha256()
            while remaining:
                chunk = process.stdout.read(min(1048576, remaining))
                require(chunk, 'complete original raw source body')
                digest.update(chunk)
                remaining -= len(chunk)
            require(process.stdout.read(1) == b'\n' and digest.hexdigest() == expected['sha256'],
                    'whole original raw fixed source bytes')
        process.stdin.close()
        require(process.stderr.read() == b'' and process.wait() == 0 and process.stdout.read(1) == b'',
                'complete original raw source Git terminal')
    finally:
        if process.poll() is None:
            process.kill()
            process.wait()
    return finite.identity(encoded(source))


def check_checkpoint(actual, source):
    require(type(actual) is dict and set(actual) == {
        'revision', 'cwd', 'command', 'source', 'status', 'stdout', 'stderr', 'after', 'condition'},
        'closed complete admitted raw checkpoint')
    require(type(actual['status']) is int and actual['status'] == 0, 'actual admitted raw checkpoint integer success')
    require(actual['revision'] == '2ca3774542dc776e534930c139b43042344140cd'
            and actual['cwd'] == '.artifacts/raw-canonical-preparation-20261011/source-view-v3'
            and actual['command'] == ['python3', '-B', 'docs/audits/raw-semantic-parent-closure-20261011/verify.py'],
            'complete original raw checkpoint source role and command')
    require(actual['source'] == actual['after'] == source, 'whole conserved original raw checkpoint source')
    require(actual['stdout'] == PARENT_SUCCESS and actual['stderr'] == '', 'complete actual original raw checkpoint terminal')


def authenticate():
    declared = preparation()
    candidate = admission()
    published(candidate)
    source = json.loads(finite.local(PREPARATION / 'source-v3.json', declared['source-v3.json']))
    original = source_census(source)
    actual = json.loads(finite.local(PREPARATION / 'parent-checkpoint-v3-actual.json', declared['parent-checkpoint-v3-actual.json']))
    check_checkpoint(actual, original)
    proof = json.loads(finite.local(PREPARATION / 'proof.json', EXTRAS['proof.json']))
    require(proof['source'] == original and proof['actual'] == finite.identity(encoded(actual))
            and proof['candidate'] == candidate, 'complete admitted raw proof and candidate association')
    require(proof['prerequisite']['source_revision'] == 'e42845fc43a61b2da76d5ad3fb5b4158c80765ff'
            and proof['prerequisite']['archive_revision'] == '2ca3774542dc776e534930c139b43042344140cd',
            'original e428 and later raw archive source conditions retain')
    return dict(preparation=declared, source=original, checkpoint=finite.identity(encoded(actual)),
                candidate=CANDIDATE, prerequisite=proof['prerequisite'],
                scope='Complete admitted finite raw source joining and original committed source/native evidence authentication. No fresh original semantic execution, native/private measurement or later historical-programme currency is claimed.')

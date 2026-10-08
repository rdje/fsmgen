"""Consume complete dated source/native result evidence with hostile controls."""
import ast
import base64
import copy
import hashlib
import json
import posixpath
import re
import subprocess
from pathlib import Path

BASE = Path('docs/audits/coordinate-public-final-replay-20261008')
PREPARATION = Path('docs/audits/coordinate-public-final-preparation-20261008')
REVISION = 'a2840582fc1722c29da808713d6f3c06bd42cd78'
TRANSPORT_REVISION = '0f14b5ad5d919191ef92393c48bea1b20108f593'
READERS = ('docs/audits/record-value-coordinate-public-route-20261008/verify.py',
           'docs/audits/record-value-coordinate-public-reference-20261008/verify.py',
           'docs/audits/record-value-coordinate-public-qualification-20261008/verify.py')
SCOPE = 'Unchanged dated finite-public route only; current publication and original-coordinate identities remain separate.'


def need(ok, cause):
    if not ok:
        raise ValueError(cause)


def same(left, right):
    return json.dumps(left, sort_keys=True) == json.dumps(right, sort_keys=True)


def native(args):
    result = subprocess.run(['git', '--no-replace-objects', *args], capture_output=True)
    need(result.returncode == 0 and not result.stderr, 'complete independent native result')
    return result.stdout


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def object_manifests(rows):
    objects, result = {}, {}
    alias_objects = {row['oid'] for row in rows.values() if row['mode'] == '120000'}
    process = subprocess.Popen(['git', '--no-replace-objects', 'cat-file', '--batch'],
                               stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    try:
        for path, row in sorted(rows.items()):
            oid = row['oid']
            if oid not in objects:
                process.stdin.write((oid + '\n').encode())
                process.stdin.flush()
                header = process.stdout.readline().decode().strip().split()
                need(len(header) == 3 and header[:2] == [oid, 'blob'], 'whole native source blob framing')
                size = int(header[2]); raw = process.stdout.read(size)
                need(len(raw) == size and process.stdout.read(1) == b'\n', 'complete native source blob bytes')
                objects[oid] = (pin(raw), raw.decode() if oid in alias_objects else None)
            identity, alias = objects[oid]
            if row['mode'] == '120000':
                endpoint = posixpath.normpath(posixpath.join(posixpath.dirname(path), alias))
                need(alias and not alias.startswith('/') and endpoint in rows
                     and rows[endpoint]['mode'] in ('100644', '100755'), 'complete contained canonical alias target')
            result[path] = {'content': identity, 'kind': 'alias' if row['mode'] == '120000' else 'regular',
                            'mode': {'100644': '0o644', '100755': '0o755', '120000': None}[row['mode']],
                            'same_volume': True}
        process.stdin.close()
        need(process.wait() == 0 and not process.stderr.read(), 'complete independent object stream')
    finally:
        if process.poll() is None:
            process.kill(); process.wait()
        process.stdout.close(); process.stderr.close()
    return result


def expectation():
    admission = (BASE / 'attempt-2.json').read_bytes()
    need(hashlib.sha256(admission).hexdigest() == 'f59c4f0d4e1baaadca3923c2ce29989170ac23bb50412a3a63f026eaf4b2ac92', 'immutable first successful source-scope admission')
    proof = json.loads(admission)
    need(type(proof['actual']['status']) is int and proof['actual']['status'] == 0
         and proof['actual']['stderr'] == '', 'actual first source-scope admission')
    raw = native(['--literal-pathspecs', 'ls-tree', '-r', '--full-tree', '-z', REVISION, '--', *proof['names']])
    rows = {}
    for entry in raw.rstrip(b'\0').split(b'\0'):
        header, path = entry.split(b'\t', 1); mode, kind, oid = header.decode().split()
        need(kind == 'blob' and mode in ('100644', '100755', '120000'), 'declared source blob modes')
        rows[path.decode()] = {'mode': mode, 'oid': oid}
    successes = {}
    for reader in READERS:
        source = native(['show', REVISION + ':' + reader])
        values = [node.value.value for node in ast.parse(source).body
                  if isinstance(node, ast.Assign) and isinstance(node.value, ast.Constant)
                  and any(isinstance(target, ast.Name) and target.id == 'SUCCESS' for target in node.targets)]
        need(len(values) == 1 and isinstance(values[0], str), 'complete original reader success contract')
        successes[reader] = values[0]
    return raw, rows, object_manifests(rows), successes, {
        key: proof[key] for key in ('selection_roots', 'programme_roots')}


def check(proof, expected):
    raw, rows, recovered, successes, declarations = expected
    recovered = {path: dict(row) for path, row in recovered.items()}
    need(proof['revision'] == REVISION and proof['scope'] == SCOPE, 'closed dated public scope')
    need(proof['source'] == (BASE / 'replay.py').read_text(), 'complete actual replay programme currency')
    transport = {name: pin(native(['show', TRANSPORT_REVISION + ':' + str(PREPARATION / name)]))
                 for name in ('epoch.py', 'git_readonly.py')}
    need(proof['transport'] == transport and transport == {name: pin((PREPARATION / name).read_bytes()) for name in transport},
         'exact committed qualified recovery transport')
    need(proof['names'] == sorted(rows) and len(proof['names']) == len(set(proof['names']))
         and base64.b64decode(proof['metadata'], validate=True) == raw and proof['rows'] == rows,
         'complete explicit native source membership')
    need(all(proof[key] == value for key, value in declarations.items()), 'whole immutable admitted scope declarations')
    # Git's 120000 records link kind and target bytes, not host permission bits.
    # Keep complete dated permissions as observations; never compare them to
    # another platform or another process's current umask.
    observed = proof['recovered_before']
    for path, row in rows.items():
        if row['mode'] == '120000' and path in observed:
            mode = observed[path].get('mode')
            need(type(mode) is str and re.fullmatch(r'0o[0-7]{1,3}', mode) is not None,
                 'typed retained alias permission observation')
            recovered[path] = dict(recovered[path], mode=mode)
    need(same(proof['recovered_before'], recovered) and same(proof['recovered_after'], recovered),
         'whole source bytes modes aliases and same-volume conservation')
    need(same(proof['primary_before'], proof['primary_after']), 'observed primary Git metadata conservation')
    need(len(proof['results']) == len(READERS), 'complete actual reader population')
    for result, reader in zip(proof['results'], READERS):
        need(result['command'] == ['python3', '-B', reader] and type(result['status']) is int
             and result['status'] == 0 and result['stdout'] == successes[reader] and result['stderr'] == '',
             'complete typed native reader result')
    fixture = proof['fixture']
    need(fixture['relative_path'].startswith('.artifacts/coordinate-public-final-')
         and fixture['removed'] is True, 'exact owned fixture cleanup')
    calls = [json.loads(line) for line in proof['git_calls'].splitlines()]
    need(calls and all(row['operation'] in ('archive', 'cat-file', 'check-ignore', 'diff', 'for-each-ref',
         'hash-object', 'log', 'ls-files', 'ls-tree', 'rev-parse', 'show', 'status') for row in calls), 'actual read-only Git call population')
    for call in calls:
        args = call['arguments']
        for index, value in enumerate(args):
            if value == '-C':
                working = args[index + 1]
                need(working == fixture['observed_root'] or working.startswith(fixture['observed_root'] + '/'),
                     'actual contained fixture Git roots')


def main():
    proof = json.loads((BASE / 'attempt-4.json').read_bytes())
    expected = expectation(); check(proof, expected)
    first = json.loads((BASE / 'attempt-1.json').read_bytes())
    need(type(first['actual']['status']) is int and first['actual']['status'] == 1
         and first['actual']['stderr'].endswith("FileNotFoundError: [Errno 2] No such file or directory: 'docs/audits/book-source-plane-20261005/book-authority.json'\n")
         and 'docs/audits/book-source-plane-20261005/book-authority.json' not in first['names'],
         'complete first missing-prerequisite refusal')
    controls = (
        ('lost-source', lambda p: p['recovered_before'].pop(READERS[0]), 'whole source bytes modes aliases and same-volume conservation'),
        ('wrong-blob', lambda p: p['recovered_after'][READERS[0]]['content'].update(sha256='0' * 64), 'whole source bytes modes aliases and same-volume conservation'),
        ('alias-permission-drift', lambda p: p['recovered_after']['docs/book/src/reference-source/README_POLICY.markdown.source.txt'].update(mode='0o777'), 'whole source bytes modes aliases and same-volume conservation'),
        ('Boolean-alias-permission', lambda p: p['recovered_before']['docs/book/src/reference-source/README_POLICY.markdown.source.txt'].update(mode=True), 'typed retained alias permission observation'),
        ('Boolean-status', lambda p: p['results'][0].update(status=False), 'complete typed native reader result'),
        ('lost-reader', lambda p: p['results'].pop(), 'complete actual reader population'),
        ('scope-promotion', lambda p: p.update(scope='original coordinate identities qualified'), 'closed dated public scope'),
        ('primary-change', lambda p: p['primary_after'].update(refs='changed'), 'observed primary Git metadata conservation'),
        ('foreign-working-root', lambda p: p.update(git_calls=json.dumps({'operation':'show','arguments':['-C','foreign','show','HEAD']})+'\n'), 'actual contained fixture Git roots'),
        ('unremoved-fixture', lambda p: p['fixture'].update(removed=False), 'exact owned fixture cleanup'),
    )
    for name, mutate, cause in controls:
        candidate = copy.deepcopy(proof); mutate(candidate)
        need(not same(candidate, proof), 'genuine independent control')
        try:
            check(candidate, expected)
        except ValueError as error:
            need(str(error) == cause, 'intended independent refusal: ' + name)
        else:
            raise ValueError('false-green independent control: ' + name)
    print('PASS complete unchanged dated public route/reference/qualification, whole source and primary-Git conservation and independent hostile controls; original identities remain unmeasured.')


if __name__ == '__main__':
    main()

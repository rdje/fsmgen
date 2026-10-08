"""Independently consume exact native preparation evidence and genuine controls."""
import base64
import copy
import gzip
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/coordinate-public-final-preparation-20261008')
REVISION = 'a2840582fc1722c29da808713d6f3c06bd42cd78'
NAMES = ['README_POLICY.md', 'docs/book/src/reference-source/README_POLICY.markdown.source.txt',
         'scripts/check_docs_relative_paths.sh']
SCOPE = 'Explicit small preparation population only; complete dated replay/current publication remains successor-owned. Logical historical path-size sum is not .git size or corruption evidence; whole-tree recovery was retired before copying.'


def need(ok, cause):
    if not ok:
        raise ValueError(cause)


def native(args):
    result = subprocess.run(['git', '--no-replace-objects', *args], capture_output=True)
    need(result.returncode == 0 and not result.stderr, 'complete independent native source')
    return result.stdout


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def check(proof):
    need(proof['revision'] == REVISION and proof['names'] == NAMES and proof['scope'] == SCOPE,
         'closed explicit preparation scope')
    need(proof['sources'] == {name: (BASE / name).read_text() for name in
         ('epoch.py', 'git_readonly.py', 'qualify.py', 'verify.py')}, 'complete preparation programme currency')
    raw = native(['--literal-pathspecs', 'ls-tree', '-r', '--full-tree', '-z', REVISION, '--', *NAMES])
    need(base64.b64decode(proof['metadata_base64'], validate=True) == raw, 'complete source metadata')
    rows = {}
    for record in raw.rstrip(b'\0').split(b'\0'):
        header, path = record.split(b'\t')
        mode, kind, oid = header.decode().split()
        need(kind == 'blob', 'published blob source')
        rows[path.decode()] = {'mode': mode, 'oid': oid}
    need(proof['rows'] == rows and set(rows) == set(NAMES) and set(proof['recovered']) == set(NAMES),
         'complete declared source membership')
    expected_objects = {}
    for path, row in rows.items():
        content = native(['show', REVISION + ':' + path])
        expected_objects[row['oid']] = base64.b64encode(content).decode()
        record = proof['recovered'][path]
        need(record['identity'] == pin(content) and type(record['identity']['bytes']) is int
             and record['mode'] == row['mode'] and record['same_volume'] is True
             and record['executable'] is (row['mode'] != '100644'), 'exact source bytes mode and same-volume recovery')
    need(proof['objects'] == expected_objects, 'complete native object bytes')
    alias = native(['show', REVISION + ':' + NAMES[1]]).decode()
    need(alias == '../../../../README_POLICY.md', 'published contained canonical alias')
    need(proof['primary_before'] == proof['primary_after'] and
         set(proof['primary_before']['files']) == {'index', 'config', 'HEAD', 'packed-refs'},
         'observed primary index configuration and reference conservation')
    positives = proof['positives']
    need(len(positives) == 5 and all(type(p['status']) is int and p['status'] == 0 and p['stderr'] == '' for p in positives[:4]),
         'typed actual positive statuses')
    need(positives[0]['arguments'] == ['git', 'rev-parse', 'HEAD']
         and len(positives[0]['stdout'].strip()) == 40
         and positives[1]['arguments'] == ['git', 'show', REVISION + ':README_POLICY.md']
         and positives[1]['stdout'] == native(['show', REVISION + ':README_POLICY.md']).decode(), 'complete actual object reader')
    expected_index = b''.join((row['mode'] + ' ' + row['oid'] + ' 0\t' + path).encode() + b'\0'
                             for path, row in sorted(rows.items()))
    need(positives[2]['arguments'] == ['git', 'ls-files', '--stage', '-z', '--', *NAMES]
         and positives[2]['stdout'].encode() == expected_index, 'complete private-index source identities')
    need(positives[3]['arguments'] == ['git', '-C', 'docs/book', 'rev-parse', '--show-toplevel']
         and Path(positives[3]['stdout'].strip()).name.startswith('coordinate-epoch-preparation-'),
         'owned nested Git working root')
    ignored = positives[4]
    need(ignored['arguments'] == ['git', 'check-ignore', '--no-index', '--stdin']
         and type(ignored['status']) is int and ignored['status'] == 1
         and ignored['stdout'] == ignored['stderr'] == '', 'native admitted source ignore policy')
    calls = [json.loads(line) for line in proof['accepted_calls'].splitlines()]
    need([r['arguments'] for r in calls] == [r['arguments'][1:] for r in positives]
         and [r['operation'] for r in calls] == ['rev-parse', 'show', 'ls-files', 'rev-parse', 'check-ignore'], 'closed actually accepted read operations')
    controls = proof['controls']
    need(len(controls) == 16 and len({c['name'] for c in controls}) == 16, 'complete genuine refusal population')
    for control in controls[:5]:
        actual = control['actual']
        need(type(actual['status']) is int and actual['status'] == 2 and actual['stdout'] == ''
             and actual['stderr'].startswith('readonly epoch replay: Git command refused: '), 'actual Git mutation refusals')
    foreign = controls[5]['actual']
    need(controls[5]['name'] == 'foreign-working-root' and type(foreign['status']) is int
         and foreign['status'] == 2 and foreign['stdout'] == ''
         and foreign['stderr'] == 'readonly epoch replay: foreign Git working root\n', 'foreign working-root refusal')
    need({c['name']: c['cause'] for c in controls[6:]} == {
        'root-wildcard': 'contained canonical source path',
        'missing-scope': 'explicit nonempty unique recovery scope',
        'duplicate-scope': 'explicit nonempty unique recovery scope',
        'path-escape': 'contained canonical source path',
        'absolute-path': 'contained canonical source path',
        'metadata-path': 'contained canonical source path',
        'alias-escape': 'contained canonical source path',
        'member-loss': 'archive source membership',
        'blob-substitution': 'whole source blob identity',
        'fixture-metadata-alias': 'fresh plain fixture metadata directory'}, 'complete intended recovery refusal causes')


def main():
    proof = json.loads((BASE / 'proof.json').read_bytes())
    check(proof)
    first = json.loads((BASE / 'first-reader-result.json').read_bytes())
    first_proof = json.loads(gzip.decompress((BASE / 'first-proof.json.gz').read_bytes()))
    need(type(first['status']) is int and first['status'] == 1 and first['stdout'] == ''
         and first['stderr'].endswith('ValueError: genuine result control\n')
         and first['source'] == first_proof['sources']['verify.py']
         and "need(candidate != proof, 'genuine result control')" in first['source'],
         'complete first Boolean-equality oracle failure')
    need(False == 0 and json.dumps(False) != json.dumps(0), 'typed Boolean/integer separation')
    controls = (
        ('missing-member', lambda p: p['recovered'].pop(NAMES[0]), 'complete declared source membership'),
        ('substituted-object', lambda p: p['objects'].update({p['rows'][NAMES[0]]['oid']: 'eA=='}), 'complete native object bytes'),
        ('Boolean-status', lambda p: p['positives'][0].update(status=False), 'typed actual positive statuses'),
        ('mutation-accepted', lambda p: p['controls'][0]['actual'].update(status=0), 'actual Git mutation refusals'),
        ('primary-change', lambda p: p['primary_after'].update(refs='changed'), 'observed primary index configuration and reference conservation'),
        ('full-replay-promotion', lambda p: p.update(scope='whole public replay qualified'), 'closed explicit preparation scope'),
    )
    for name, mutate, cause in controls:
        candidate = copy.deepcopy(proof)
        mutate(candidate)
        need(json.dumps(candidate, sort_keys=True) != json.dumps(proof, sort_keys=True), 'genuine result control')
        try:
            check(candidate)
        except ValueError as error:
            need(str(error) == cause, 'intended independent refusal: ' + name)
        else:
            raise ValueError('false-green independent control: ' + name)
    print('PASS complete explicit preparation evidence and independent hostile controls; full dated replay/current publication remains open.')


if __name__ == '__main__':
    main()

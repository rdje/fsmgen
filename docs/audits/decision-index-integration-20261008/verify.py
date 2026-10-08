"""Independently reconstruct complete dated native membership and actual joins."""
import base64
import copy
import gzip
import hashlib
import json
import posixpath
import re
import subprocess
from pathlib import Path

BASE = Path('docs/audits/decision-index-integration-20261008')
SCOPE = 'Dated installed index/tree/catalog/control integration; original-coordinate, HIAL, visual, full CI and push remain open.'
BINDINGS = ['doctrine/live_document_size/surfaces.jsonl',
            'doctrine/live_document_size/ceiling_increase_authorities.jsonl']
CENSUS = 'docs/audits/decision-record-rollover-census-20260927.json'


def need(ok, cause):
    if not ok:
        raise ValueError(cause)


def unpack(row):
    raw = gzip.decompress(base64.b64decode(row['gzip_base64'], validate=True))
    need(type(row['bytes']) is int and row['bytes'] == len(raw)
         and row['sha256'] == hashlib.sha256(raw).hexdigest(), 'complete native wire custody')
    return raw


def parse(raw, tree):
    need(raw.endswith(b'\0'), 'complete native NUL framing')
    objects = {}
    for record in raw.split(b'\0')[:-1]:
        header, name = record.split(b'\t', 1)
        fields = header.split(b' ')
        need(len(fields) == 3, 'native metadata header')
        mode, oid = fields[0], fields[2] if tree else fields[1]
        need(mode in (b'100644', b'100755', b'120000', b'160000')
             and re.fullmatch(b'[0-9a-f]{40}', oid)
             and (fields[1] == (b'commit' if mode == b'160000' else b'blob')
                  if tree else fields[2] == b'0'), 'native metadata kinds')
        path = name.decode()
        need(path not in objects, 'native unique raw paths')
        objects[path] = [mode.decode(), oid.decode()]
    return objects


def check(proof, native):
    need(proof['scope'] == SCOPE, 'dated integration scope')
    need(proof['limits'] == {'inventory': 4_194_304, 'paths': 4_194_304 // 52}
         and all(type(v) is int for v in proof['limits'].values()), 'unchanged typed inventory limits')
    need(proof['bindings'] == BINDINGS and len(proof['rows']) == 2, 'complete selector/control population')
    blobs = {oid: text.encode() for oid, text in proof['blobs'].items()}
    need(all(oid == hashlib.sha1(b'blob ' + str(len(raw)).encode() + b'\0' + raw).hexdigest()
             for oid, raw in blobs.items()), 'every complete selected blob identity')
    used = set()
    expected_digests = {}
    for number, row in enumerate(proof['rows']):
        need(row['selector'] == ('index' if number == 0 else proof['revision'])
             and row['revision'] == (None if number == 0 else proof['revision']), 'fixed selector identity')
        wire = row['native']
        command = (['git', '--no-replace-objects', 'ls-files', '--stage', '-z'] if number == 0 else
                   ['git', '--no-replace-objects', 'ls-tree', '-r', '--full-tree', '-z', proof['revision']])
        need(wire['command'] == command and type(wire['status']) is int
             and wire['status'] == 0 and wire['stderr'] == '', 'complete actual native command result')
        objects = parse(unpack(wire['stdout']), bool(number))
        need(objects == native, 'immutable complete dated native population')
        census_raw = blobs[objects[CENSUS][1]]
        authority = re.search(r"^CENSUS_SHA256 = '([0-9a-f]{64})'", proof['sources']['scripts/decision_records.py'], re.M)[1]
        need(hashlib.sha256(census_raw).hexdigest() == authority, 'independent pinned census authority')
        census = json.loads(census_raw)
        files = {CENSUS, 'docs/audits/decision-store-transition-census.json', *BINDINGS}
        files.update(posixpath.normpath('docs/decisions/' + r['target']) for r in census['selected_links'])
        files.update(r['path'] for r in census['body_or_identity_consumers'] if r['text'].startswith('reverify:'))
        ancestors = {'/'.join(p.split('/')[:i]) for p in files | {'docs/decisions'}
                     for i in range(1, len(p.split('/')))}
        expected = {p: v for p, v in native.items()
                    if p.startswith('docs/decisions/') or p in files or p in ancestors}
        need(row['objects'] == expected, 'complete selected source/mode/object allocation')
        used.update(v[1] for v in expected.values())
        size = sum(len(f'{mode} {oid} 0\t{p}\0'.encode()) for p, (mode, oid) in expected.items())
        need(type(row['inventory_bytes']) is int and row['inventory_bytes'] == size
             and size <= 4_194_304, 'complete bounded canonical accounting')
        need(row['root_paths'] == sorted(p for p in expected if re.fullmatch(r'docs/decisions/[^/]+\.md', p)),
             'complete compatibility root membership')
        result = row['public']
        need(result == {'command': ['scripts/decision_records.py', '--snapshot', row['selector'], 'check'],
                        'status': 0, 'stdout': 'decision-records: authenticated originals, current records, compatibility and indexes verified\n',
                        'stderr': ''} and type(result['status']) is int, 'complete actual public authentication')
        expected_digests['current' if number == 0 else 'prior'] = {
            path: hashlib.sha256(blobs[expected[path][1]]).hexdigest() for path in BINDINGS}
    need(set(blobs) == used, 'complete unique selected blob population')
    receipt = proof['continuity']
    need(type(receipt['status']) is int and receipt['status'] == 0 and receipt['stderr'] == ''
         and receipt['command'] == ['scripts/decision_records.py', '--snapshot', 'index', '--prior-snapshot', proof['revision'],
                                    '--bind-file', BINDINGS[0], '--bind-file', BINDINGS[1], 'check-continuity'],
         'complete actual continuity command result')
    expected = {'catalog': True, 'fresh_ids': [], 'resolved': [],
                'file_bindings': {p: {k: v[p] for k, v in expected_digests.items()} for p in BINDINGS}}
    need(receipt['stdout'] == json.dumps(expected, ensure_ascii=False, sort_keys=True) + '\n',
         'complete continuity/control binding product')


def main():
    proof = json.loads((BASE / 'proof.json').read_text())
    need(re.fullmatch('[0-9a-f]{40}', proof['revision']), 'exact dated source revision')
    tree = subprocess.check_output(['git', '--no-replace-objects', 'ls-tree', '-r', '--full-tree', '-z', proof['revision']])
    native = parse(tree, True)
    expected_sources = {'scripts/' + name + '.py' for name in
                        ('decision_records', 'decision_store_git', 'decision_store', 'decision_catalog')}
    expected_sources.update(str(BASE / name) for name in ('qualify.py', 'verify.py'))
    need(set(proof['sources']) == expected_sources, 'complete programme/source population')
    for path, text in proof['sources'].items():
        need(Path(path).read_text() == text, 'complete current programme/source currency')
        if path.startswith('scripts/'):
            need(subprocess.check_output(['git', '--no-replace-objects', 'show', proof['revision'] + ':' + path]) == text.encode(),
                 'complete committed production source identity')
    raw = Path('docs/audits/decision-index-repair-20261008/proof.json').read_bytes()
    need(proof['repair_proof'] == {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}, 'entire prior repair binding')
    check(proof, native)
    packed = (BASE / 'first-proof.json.gz').read_bytes()
    first_raw = gzip.decompress(packed)
    metadata = json.loads((BASE / 'checks.json').read_text())['first_proof']
    need(metadata['bytes'] == len(first_raw) and metadata['sha256'] == hashlib.sha256(first_raw).hexdigest()
         and metadata['packed_bytes'] == len(packed) and metadata['packed_sha256'] == hashlib.sha256(packed).hexdigest(),
         'entire first proof custody')
    first = json.loads(first_raw)
    need(first['revision'] == proof['revision'], 'same first/final dated source')
    # Reproduce the first actual reader failure from its complete saved source;
    # the corrected independent reader also authenticates its native capture.
    namespace = {'__name__': 'saved_first_reader'}
    exec(compile(first['sources'][str(BASE / 'verify.py')], 'saved-first-reader.py', 'exec'), namespace)
    try:
        namespace['check'](first, native)
    except KeyError as error:
        need(error.args == ('docs/audits/decision-records-transition-census.json',), 'exact first reader refusal')
    else:
        raise ValueError('first reader refusal disappeared')
    check(first, native)
    controls = []
    for name, mutate, cause in [
        ('member-loss', lambda p: p['rows'][0]['objects'].pop(next(iter(p['rows'][0]['objects']))), 'complete selected source/mode/object allocation'),
        ('object-substitution', lambda p: p['rows'][0]['objects'][CENSUS].__setitem__(1, '0' * 40), 'complete selected source/mode/object allocation'),
        ('Boolean-public-status', lambda p: p['rows'][0]['public'].update(status=False), 'complete actual public authentication'),
        ('widened-limit', lambda p: p['limits'].update(inventory=8_388_608), 'unchanged typed inventory limits'),
        ('lost-control-binding', lambda p: p.update(bindings=BINDINGS[:1]), 'complete selector/control population'),
        ('borrowed-continuity', lambda p: p['continuity'].update(stdout='{}\n'), 'complete continuity/control binding product'),
        ('full-CI-promotion', lambda p: p.update(scope='All full CI and push gates closed.'), 'dated integration scope'),
    ]:
        bad = copy.deepcopy(proof)
        mutate(bad)
        need(json.dumps(bad, sort_keys=True) != json.dumps(proof, sort_keys=True), 'genuine control intervention')
        try:
            check(bad, native)
        except ValueError as error:
            need(str(error) == cause, 'intended control cause: ' + name)
            controls.append({'control': name, 'status': 1, 'cause': str(error)})
        else:
            raise ValueError('false-green integration control: ' + name)
    print(json.dumps({'status': 0, 'scope': SCOPE, 'controls': controls}, sort_keys=True))


if __name__ == '__main__':
    main()

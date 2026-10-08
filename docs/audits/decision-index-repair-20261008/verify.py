"""Independent binary/object/source reconstruction of the dated production repair."""
import copy
import hashlib
import json
import posixpath
import re
import subprocess
import sys
import types
from pathlib import Path

BASE = Path('docs/audits/decision-index-repair-20261008')
OLD = Path('docs/audits/decision-index-scope-20261008')
ROLE = 'Real production constructor and installed public reader on the exact dated stock population; integration closure remains SEM.78.3-owned.'


def need(condition, cause):
    if not condition:
        raise ValueError(cause)


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def parse(raw, tree):
    need(raw.endswith(b'\0'), 'independent complete native wire')
    result = {}
    for record in raw.split(b'\0')[:-1]:
        header, name = record.split(b'\t', 1)
        fields = header.split(b' ')
        need(len(fields) == 3, 'independent exact metadata header')
        mode, oid = fields[0], fields[2] if tree else fields[1]
        need(mode in (b'100644', b'100755', b'120000', b'160000')
             and re.fullmatch(b'[0-9a-f]{40}', oid), 'independent native modes and object identities')
        need(fields[1] == (b'commit' if mode == b'160000' else b'blob') if tree else fields[2] == b'0',
             'independent native object kinds or zero stages')
        path = name.decode()
        need(path not in result, 'independent unique raw path')
        result[path] = [mode.decode(), oid.decode()]
    return result


def size(objects):
    return sum(len(f'{mode} {oid} 0\t{path}\0'.encode()) for path, (mode, oid) in objects.items())


def check(product, expected):
    need(product['role'] == ROLE, 'independent exact qualified scope')
    need(type(product['limits']['inventory']) is int and product['limits'] == expected['limits'],
         'independent unchanged limits')
    need(len(product['results']) == 2, 'independent complete selector population')
    for actual, wanted in zip(product['results'], expected['results']):
        need(actual['complete_wire'] == wanted['complete_wire'], 'independent complete native wire')
        need(actual['objects'] == wanted['objects'], 'independent complete relevant raw-path/mode/object allocation')
        need(type(actual['canonical_bytes']) is int and actual['canonical_bytes'] == wanted['canonical_bytes']
             and type(actual['selected_bytes']) is int and actual['selected_bytes'] == wanted['selected_bytes'],
             'independent actual canonical byte accounting')
        need(actual['prepared'] == wanted['prepared'], 'independent complete semantic products')
        public = actual['public']
        need(type(public['status']) is int and public['status'] == 0 and public['stderr'] == ''
             and public['stdout'] == 'decision-records: authenticated originals, current records, compatibility and indexes verified\n',
             'independent complete actual installed result')
        refusal = actual['default_refusal']
        need(type(refusal['status']) is int and refusal ==
             {'status': 1, 'cause': 'Git output exceeds selected snapshot bound'}, 'independent default refusal')
        need(actual['controls'] == wanted['controls'] and all(type(c['status']) is int and c['status'] == 1
                                                            for c in actual['controls']),
             'independent complete actual scoped controls')


def main():
    product = json.loads((BASE / 'proof.json').read_bytes())
    prior = json.loads((OLD / 'proof.json').read_bytes())
    need(product['diagnosis']['identity'] == pin((OLD / 'proof.json').read_bytes()),
         'independent entire immutable diagnosis binding')
    diagnosis = subprocess.run([sys.executable, '-B', str(OLD / 'verify.py')], capture_output=True)
    need(diagnosis.returncode == 0 and not diagnosis.stderr and diagnosis.stdout ==
         product['diagnosis']['actual']['stdout'].encode(), 'independent actual immutable diagnosis execution')
    need(type(product['diagnosis']['actual']['status']) is int
         and product['diagnosis']['actual']['status'] == 0 and not product['diagnosis']['actual']['stderr'],
         'independent complete saved diagnosis receipt')
    for path, row in product['sources'].items():
        raw = row['source'].encode()
        need(row['identity'] == pin(raw) and Path(path).read_bytes() == raw,
             'independent complete programme/source currency')
    fixture_revision = re.search(r"REVISION = '([0-9a-f]{40})'",
                                product['sources']['t/python/test_decision_production_growth.py']['source'])[1]
    data = {name: value.encode() for name, value in product['inputs'].items()}
    need(set(data) == set(prior['complete_before']), 'independent complete input population')
    for path, raw in data.items():
        if path in product['sources']:
            need(raw == product['sources'][path]['source'].encode(), 'independent exact repaired reader input')
        else:
            original = subprocess.check_output(['git', '--no-replace-objects', 'show', fixture_revision + ':' + path])
            need(raw == original, 'independent complete fixed-Git fixture source')
        if path not in ('scripts/decision_records.py', 'scripts/decision_store_git.py'):
            need(pin(raw) == prior['complete_before'][path], 'independent non-repair conservation')
    # Use the captured unchanged semantic source modules, not the scope producer.
    old = {}
    for name in ('decision_catalog', 'decision_store', 'decision_records'):
        module = types.ModuleType(name)
        module.__file__ = 'scripts/' + name + '.py'
        sys.modules[name] = module
        exec(compile(prior['sources'][module.__file__]['source'], module.__file__, 'exec'), module.__dict__)
        old[name] = module
    published = old['decision_records']
    census = json.loads(data[published.CENSUS])
    need(hashlib.sha256(data[published.CENSUS]).hexdigest() == published.CENSUS_SHA256,
         'independent trusted dependency source')
    files = {published.CENSUS, 'docs/audits/decision-store-transition-census.json',
             'doctrine/live_document_size/surfaces.jsonl',
             'doctrine/live_document_size/ceiling_increase_authorities.jsonl', 'λ/registry.json'}
    files.update(posixpath.normpath('docs/decisions/' + row['target']) for row in census['selected_links'])
    files.update(row['path'] for row in census['body_or_identity_consumers'] if row['text'].startswith('reverify:'))
    parents = {'/'.join(path.split('/')[:i]) for path in files | {'docs/decisions'}
               for i in range(1, len(path.split('/')))}
    payload = b'opaque unrelated qualification data\n'
    opaque_oid = hashlib.sha1(b'blob ' + str(len(payload)).encode() + b'\0' + payload).hexdigest()
    opaque = {'unrelated/' + 'x' * 160 + f'{i:05}.bin' for i in range(20_001)} | {'λ'}
    expected = copy.deepcopy(product)
    expected['limits'] = {'inventory': 4_194_304, 'paths': 4_194_304 // 52,
                          'document': 1_048_576, 'scope_declarations': 256}
    need(product['results'][0]['selector'] == 'index'
         and re.fullmatch('[0-9a-f]{40}', product['results'][1]['selector']), 'independent native selectors')
    for number, row in enumerate(expected['results']):
        complete = parse(row['complete_wire'].encode(), bool(number))
        need(set(complete) == set(data) | opaque, 'independent exact unchanged opaque population')
        for path, value in complete.items():
            raw = payload if path in opaque else data[path]
            need(value == ['100644', hashlib.sha1(b'blob ' + str(len(raw)).encode() + b'\0' + raw).hexdigest()],
                 'independent every native source/opaque object')
        need(all(complete[path] == ['100644', opaque_oid] for path in opaque), 'independent opaque allocation')
        row['objects'] = {p: v for p, v in complete.items()
                          if p.startswith('docs/decisions/') or p in files or p in parents}
        row['canonical_bytes'] = size(complete)
        row['selected_bytes'] = size(row['objects'])
        need(row['canonical_bytes'] > 4_194_304 >= row['selected_bytes'], 'independent genuine whole overflow and bounded selection')
        reader = lambda path: data[path]
        prepared = old['decision_store'].load(Path.cwd(), published.STORE_SOURCE_SHA256,
                                              published.STORE_INDEX_SHA256, reader=reader)
        old['decision_store'].verify(Path.cwd(), prepared, reader=reader,
                                     paths=tuple(sorted(p for p in row['objects']
                                                        if re.fullmatch('docs/decisions/[^/]+\\.md', p))))
        published.verify(Path.cwd(), prepared, reader=reader)
        need(prepared == prior['results'][number]['prepared'], 'independent original complete semantic conservation')
        row['prepared'] = prepared
        row['controls'] = [{'path': 'λ/registry.json', 'status': 1,
                            'cause': 'selected source has a nondirectory ancestor: λ/registry.json'},
                           {'path': 'unrelated/' + 'x' * 160 + '00000.bin', 'status': 1,
                            'cause': 'selected source is outside declared scope: unrelated/' + 'x' * 160 + '00000.bin'}]
    check(product, expected)
    for name, mutate, cause in (
        ('lost-member', lambda c: c['results'][0]['objects'].pop('λ'), 'independent complete relevant raw-path/mode/object allocation'),
        ('borrowed-object', lambda c: next(iter(c['results'][0]['objects'].values())).__setitem__(1, '0' * 40), 'independent complete relevant raw-path/mode/object allocation'),
        ('Boolean-status', lambda c: c['results'][0]['public'].update(status=False), 'independent complete actual installed result'),
        ('Boolean-budget', lambda c: c['results'][0].update(selected_bytes=True), 'independent actual canonical byte accounting'),
        ('widened-budget', lambda c: c['limits'].update(inventory=4_194_305), 'independent unchanged limits'),
        ('lost-control', lambda c: c['results'][0]['controls'].pop(), 'independent complete actual scoped controls'),
        ('lost-selector', lambda c: c['results'].pop(), 'independent complete selector population'),
        ('integration-promotion', lambda c: c.update(role='All integration and full CI closed.'), 'independent exact qualified scope'),
    ):
        candidate = copy.deepcopy(product)
        mutate(candidate)
        need(json.dumps(candidate, sort_keys=True) != json.dumps(product, sort_keys=True),
             'independent genuine control')
        try:
            check(candidate, expected)
        except ValueError as error:
            need(str(error) == cause, 'independent intended candidate refusal: ' + name)
        else:
            raise ValueError('independent false green: ' + name)
    print('PASS independent complete native/source/object/semantic repair reconstruction and genuine controls; integration closure remains pending.')


if __name__ == '__main__':
    main()

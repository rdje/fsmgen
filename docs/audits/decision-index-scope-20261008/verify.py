"""Independently reconstruct the dated stock failure and source hypothesis."""
import copy
import hashlib
import json
import posixpath
import re
import subprocess
import sys
import types
from pathlib import Path

BASE = Path('docs/audits/decision-index-scope-20261008')


def need(value, cause):
    if not value:
        raise ValueError(cause)


def pin(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def git(revision, path):
    return subprocess.check_output(['git', '--no-replace-objects', 'show', revision + ':' + path])


def parse(raw, tree=False, directories=False):
    need(not raw or raw[-1:] == b'\0', 'independent complete native metadata frame')
    result = {}
    for record in raw.split(b'\0')[:-1]:
        header, name = record.split(b'\t', 1); words = header.split(); need(len(words) == 3, 'independent metadata header')
        mode, oid = words[0], words[2] if tree else words[1]
        need(re.fullmatch(b'[0-9a-f]{40}', oid), 'independent native object kind')
        if tree and mode == b'040000':
            need(directories and words[1] == b'tree', 'independent native directory kind'); continue
        need(mode in (b'100644', b'100755', b'120000', b'160000'), 'independent native mode')
        need(words[1] == (b'commit' if mode == b'160000' else b'blob') if tree else words[2] == b'0', 'independent zero stage or object type')
        path = name.decode(); need(path not in result, 'independent unique native path'); result[path] = [mode.decode(), oid.decode()]
    return result


def size(members):
    return sum(len(mode) + 1 + len(oid) + 3 + len(path.encode()) + 1 for path, (mode, oid) in members.items())


def check(product, expected):
    need(product['role'] == expected['role'], 'independent hypothesis preserves production gap')
    for actual, wanted in zip(product['results'], expected['results']):
        need(actual['complete'] == wanted['complete'] and actual['complete_wire'] == wanted['complete_wire'], 'independent complete native source wire')
        need(type(actual['stock']['status']) is int and actual['stock']['status'] == 1
             and actual['stock']['stdout'] == ''
             and actual['stock']['stderr'] == 'decision-records: Git output exceeds selected snapshot bound\n', 'independent complete actual stock refusal')
        need(actual['selected'] == wanted['selected'], 'independent complete relevant mode object raw-path allocation')
        need(type(actual['canonical_bytes']) is int and actual['canonical_bytes'] == size(wanted['complete'])
             and actual['canonical_bytes'] > 4_194_304
             and type(actual['selected_canonical_bytes']) is int and actual['selected_canonical_bytes'] == size(wanted['selected'])
             and actual['selected_canonical_bytes'] <= 4_194_304, 'independent unchanged whole and selected byte bounds')
        need(actual['prepared'] == wanted['prepared'], 'independent whole fixed-source reader product')


def main():
    product = json.loads((BASE / 'proof.json').read_bytes()); expected = copy.deepcopy(product)
    for path, row in product['sources'].items():
        raw = git(product['revision'], path)
        need(row['source'].encode() == raw and row['identity'] == pin(raw), 'independent whole committed source binding')
    producer = product['producer']; need(producer['source'].encode() == (BASE / 'diagnose.py').read_bytes()
        and producer['identity'] == pin(producer['source'].encode()), 'independent exact retained producer')
    old = {}
    for name in ('decision_catalog', 'decision_store', 'decision_store_git', 'decision_records'):
        module = types.ModuleType(name); module.__file__ = 'scripts/' + name + '.py'; sys.modules[name] = module
        exec(compile(product['sources'][module.__file__]['source'], module.__file__, 'exec'), module.__dict__); old[name] = module
    published, selected = old['decision_records'], old['decision_store_git']
    need(product['limits'] == dict(inventory=selected.MAX_INVENTORY_BYTES, paths=selected.MAX_TRACKED_PATHS,
                                  document=selected.catalog_api.MAX_DOCUMENT_BYTES), 'independent complete unchanged limits')
    fixture_revision = re.search(r"REVISION = '([0-9a-f]{40})'", product['sources']['t/python/test_decision_production_growth.py']['source'])[1]
    data = {path: git(product['revision'] if path in ('scripts/decision_records.py', 'scripts/decision_catalog.py',
             'scripts/decision_store.py', 'scripts/decision_store_git.py') else fixture_revision, path) for path in product['complete_before']}
    need(product['complete_before'] == {p: pin(raw) for p, raw in data.items()}, 'independent complete fixed fixture bytes')
    need(product['legacy_census'].encode() == data[published.CENSUS]
         and pin(data[published.CENSUS])['sha256'] == published.CENSUS_SHA256, 'independent trusted legacy dependency source')
    census = json.loads(data[published.CENSUS]); files = {published.CENSUS, 'docs/audits/decision-store-transition-census.json',
        'doctrine/live_document_size/surfaces.jsonl', 'doctrine/live_document_size/ceiling_increase_authorities.jsonl', 'λ/registry.json'}
    files.update(posixpath.normpath('docs/decisions/' + row['target']) for row in census['selected_links'])
    files.update(row['path'] for row in census['body_or_identity_consumers'] if row['text'].startswith('reverify:'))
    parents = {str(p) for name in files | {'docs/decisions'} for p in Path(name).parents if str(p) != '.'}
    need(product['files'] == sorted(files) and product['ancestors'] == sorted(parents), 'independent whole dependency and ancestor allocation')
    baseline = product['baseline']; need(type(baseline['status']) is int and baseline['status'] == 0 and not baseline['stderr']
        and baseline['stdout'] == 'decision-records: authenticated originals, current records, compatibility and indexes verified\n', 'independent actual stock baseline')
    need(len(product['results']) == 2 and product['results'][0]['selector'] == 'index'
         and re.fullmatch('[0-9a-f]{40}', product['results'][1]['selector']), 'independent complete native selectors')
    for row in expected['results']:
        tree = row['selector'] != 'index'; complete = parse(row['complete_wire'].encode(), tree)
        need(row['complete'] == complete, 'independent complete native source wire')
        payload = b'opaque unrelated qualification data\n'
        opaque = hashlib.sha1(b'blob ' + str(len(payload)).encode() + b'\0' + payload).hexdigest()
        unrelated = {'unrelated/' + 'x' * 160 + f'{i:05}.bin' for i in range(20_001)} | {'λ'}
        need(set(complete) == set(data) | unrelated and all(complete[p] == ['100644', opaque] for p in unrelated),
             'independent complete literal unrelated data allocation')
        wanted = {p: m for p, m in complete.items() if p.startswith('docs/decisions/') or p in files or p in parents}
        captured = parse(bytes.fromhex(row['selected_wire']), tree)
        for parent in row['ancestor_results']:
            need(type(parent['status']) is int and parent['status'] == 0 and not parent['stderr'], 'independent actual ancestor result')
            for path, member in parse(bytes.fromhex(parent['stdout_hex']), tree=True, directories=True).items():
                need(path not in captured or captured[path] == member, 'independent immutable ancestor identity'); captured[path] = member
        need(captured == wanted, 'independent complete scoped wire and ancestry')
        for path, raw in data.items():
            oid = hashlib.sha1(b'blob ' + str(len(raw)).encode() + b'\0' + raw).hexdigest()
            need(complete[path] == ['100644', oid], 'independent exact native input object identity')
        row['complete'] = complete; row['selected'] = wanted
        reader = lambda path: data[path]
        prepared = old['decision_store'].load(Path.cwd(), published.STORE_SOURCE_SHA256, published.STORE_INDEX_SHA256, reader=reader)
        old['decision_store'].verify(Path.cwd(), prepared, reader=reader, paths=tuple(sorted(p for p in wanted
            if p.startswith('docs/decisions/') and p.count('/') == 2 and p.endswith('.md'))))
        published.verify(Path.cwd(), prepared, reader=reader); row['prepared'] = prepared
    check(product, expected)
    controls = []
    for name, mutate, cause in (
        ('Boolean-status', lambda c: c['results'][0]['stock'].update(status=True), 'independent complete actual stock refusal'),
        ('lost-native-record', lambda c: c['results'][0]['complete'].pop(next(p for p in c['results'][0]['complete'] if p.startswith('unrelated/'))), 'independent complete native source wire'),
        ('lost-ancestor', lambda c: c['results'][0]['selected'].pop('λ'), 'independent complete relevant mode object raw-path allocation'),
        ('borrowed-object', lambda c: next(iter(c['results'][0]['selected'].values())).__setitem__(1, '0' * 40), 'independent complete relevant mode object raw-path allocation'),
        ('Boolean-budget', lambda c: c['results'][0].update(canonical_bytes=True), 'independent unchanged whole and selected byte bounds'),
        ('production-promotion', lambda c: c.update(role='Scoped production reader qualifies.'), 'independent hypothesis preserves production gap'),
    ):
        candidate = copy.deepcopy(product); mutate(candidate); need(json.dumps(candidate, sort_keys=True) != json.dumps(product, sort_keys=True), 'independent genuine mutation')
        try:
            check(candidate, expected)
        except ValueError as error:
            need(str(error) == cause, 'independent intended hypothesis refusal'); controls.append(dict(name=name, cause=cause, status=1))
        else:
            raise ValueError('independent false-green hypothesis control')
    print('PASS independent complete stock failure, binary inputs/source graph/reader products and genuine controls; production repair remains pending.')


if __name__ == '__main__':
    main()

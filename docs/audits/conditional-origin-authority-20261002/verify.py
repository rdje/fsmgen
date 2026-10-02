import copy
import hashlib
import json
import subprocess
from pathlib import Path

root = Path('docs/audits/conditional-origin-authority-20261002')
prior = Path('docs/audits/conditional-origin-parser-20261002/current-corrected')
baseline = 'cb2a156df5a3c8169ad9ca1cfaa9c05046e33bf8'

def encoded(value):
    return json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=False)

def verify_products(products):
    names = sorted(p.name for p in prior.glob('*.json'))
    assert len(names) == 54 and sorted(products) == names
    for name in names:
        expected = json.loads((prior / name).read_text())
        actual = products[name]
        assert actual['source'] == expected['source'] and actual['label'] == expected['label'], name
        assert encoded(actual['actor']) == encoded(expected['ordinary']), name
        assert encoded(actual['reconstructed_actor']) == encoded(expected['ordinary']), name
        assert encoded(actual['ledger']) == encoded(expected['ledger']), name
        assert encoded(actual['reconstructed_ledger']) == encoded(expected['ledger']), name
        assert actual['ledger']['source_sha256'] == hashlib.sha256(actual['source'].encode()).hexdigest(), name
        controls = actual['controls']
        mutations = ['source_identity', 'catalog_owner', 'catalog_form', 'target', 'omission',
            'duplicate', 'schema_kind', 'extra_field', 'actor_identity', 'actor_kind']
        assert [c['name'] for c in controls] == mutations, name
        for control in controls:
            actor = copy.deepcopy(expected['ordinary'])
            ledger = copy.deepcopy(expected['ledger'])
            mutation = control['name']
            group = 'entries' if ledger['entries'] else 'residuals'
            if mutation == 'source_identity': ledger['source_sha256'] = '0' * 64
            elif mutation == 'catalog_owner': ledger['catalog'][0]['owner']['name'] = 'forged_source_owner'
            elif mutation == 'catalog_form': ledger['catalog'][0]['source_form'][1] = 'forged_source_operand'
            elif mutation == 'target': ledger[group][0]['target'][1] = 'forged_target'
            elif mutation == 'omission': ledger[group].pop(0)
            elif mutation == 'duplicate': ledger[group].append(copy.deepcopy(ledger[group][0]))
            elif mutation == 'schema_kind': ledger['schema_version'] = '1'
            elif mutation == 'extra_field': ledger['extra'] = 'forged'
            elif mutation == 'actor_identity': actor['actor_name'] = 'forged_actor'
            else:
                assert type(actor['interface']['inputs'][0]['width']) is int
                actor['interface']['inputs'][0]['width'] = str(actor['interface']['inputs'][0]['width'])
                assert sorted(actor) == sorted(expected['ordinary'])
            assert encoded(control['actor']) == encoded(actor), (name, mutation)
            assert encoded(control['ledger']) == encoded(ledger), (name, mutation)
            assert control['accepted'] is False, (name, mutation)
            category = 'actor' if mutation.startswith('actor_') else 'ledger'
            assert 'conditional origin ' + category + ' differs from authoritative source' in control['diagnostic']
            assert ' at t/lib/FSM/Test/ConditionalOriginAuthority.pm line ' in control['diagnostic']

products = {p.name: json.loads(p.read_text()) for p in (root / 'current-bound').glob('*.json')}
verify_products(products)
for p in (root / 'red-bound').glob('*.json'):
    actual = json.loads(p.read_text())
    expected = json.loads((prior / p.name).read_text())
    assert encoded(actual['actor']) == encoded(expected['ordinary'])
    assert encoded(actual['trusted_ledger']) == encoded(expected['ledger'])
    forged = copy.deepcopy(expected['ledger'])
    forged['catalog'][0]['owner']['name'] = 'forged_source_owner'
    forged['source_sha256'] = '0' * 64
    assert encoded(actual['forged_ledger']) == encoded(forged) and actual['accepted'] is True
assert len(list((root / 'red-bound').glob('*.json'))) == 54
positive = (root / 'current-bound.tap').read_text()
negative = (root / 'red-bound.tap').read_text()
assert 'All tests successful.' in positive and 'Files=1, Tests=58,' in positive and 'Result: PASS' in positive
assert 'Failed 54/54 subtests' in negative and 'Files=1, Tests=54,' in negative and 'Result: FAIL' in negative
assert 'valid authored-when catalog plus matching embedded digest cannot replace select intent' in positive
assert 'explicit boundary refuses before external document resolution' in positive
macro = products['twin_macro.json']
authored = products['twin_authored.json']
assert encoded(macro['actor']) == encoded(authored['actor'])
assert [macro['ledger']['catalog'][e['origin']['catalog_id']]['operation'] for e in macro['ledger']['entries']] == ['select', 'select']
assert [authored['ledger']['catalog'][e['origin']['catalog_id']]['operation'] for e in authored['ledger']['entries']] == ['when', 'when']

for corruption in ['shared_actor_kind', 'shared_owner', 'source_identity', 'false_control_admission', 'omission']:
    bad = copy.deepcopy(products)
    sample = bad['twin_macro.json']
    if corruption == 'shared_actor_kind':
        for key in ('actor', 'reconstructed_actor'):
            sample[key]['interface']['inputs'][0]['width'] = '1'
    elif corruption == 'shared_owner':
        for key in ('ledger', 'reconstructed_ledger'):
            sample[key]['catalog'][0]['owner']['name'] = 'shared_forgery'
    elif corruption == 'source_identity': sample['source'] += '\n'
    elif corruption == 'false_control_admission': sample['controls'][0]['accepted'] = True
    else: sample['ledger']['entries'].pop()
    try:
        verify_products(bad)
    except AssertionError:
        pass
    else:
        raise AssertionError('independent falsification accepted ' + corruption)

for name in ('current-bound', 'red-bound'):
    recipe = json.loads((root / (name + '-recipe.json')).read_text())
    assert recipe['before'] == recipe['after']
    assert recipe['exit_status'] == recipe['expected_status'] == (0 if name == 'current-bound' else 1)
    for path, digest in recipe['before'].items():
        saved_path = json.loads((root / 'normalization.json').read_text()).get(path, path)
        assert hashlib.sha256(Path(saved_path).read_bytes()).hexdigest() == digest, path

originals = subprocess.check_output(['git', 'ls-tree', '-rz', baseline, '--', 'bin', 'perl',
    'docs/audits/conditional-origin-parser-20261002', 'docs/audits/conditional-origin-parser-gate-20261002',
    't/2043-isf-conditional-origin-parser.t', 't/lib/FSM/Test/ConditionalOriginParser.pm'])
inventory = {}
for entry in originals.split(b'\0'):
    if not entry: continue
    header, raw_path = entry.split(b'\t', 1)
    mode, kind, oid = header.decode().split()
    assert kind == 'blob' and mode in ('100644', '100755')
    path = raw_path.decode()
    raw = Path(path).read_bytes()
    assert hashlib.sha1(b'blob ' + str(len(raw)).encode() + b'\0' + raw).hexdigest() == oid, path
    inventory[path] = {'git_blob': oid, 'sha256': hashlib.sha256(raw).hexdigest()}
assert inventory == json.loads((root / 'originals.json').read_text())
assert not subprocess.check_output(['git', 'diff', baseline, '--', 'bin', 'perl'])
if (root / 'manifest.json').exists():
    manifest = json.loads((root / 'manifest.json').read_text())
    actual = {str(p.relative_to(root)): {'bytes': p.stat().st_size,
        'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}
        for p in sorted(root.rglob('*')) if p.is_file() and p.name != 'manifest.json'}
    assert manifest['files'] == actual
print('PASS complete source-bound reload products, exact control mutations, original kinds, twin intent, genuine unbound RED, five shared corruptions, bound recipes and immutable originals; no HDL/runtime/public widening')

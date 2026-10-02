"""Cold artifact qualification. Does not run parsers, schedulers or HDL tools."""
import copy
import hashlib
import json
import sys
from pathlib import Path

BASE = Path(__file__).parent


def encoded(value):
    # Preserve JSON primitive kinds; Python == alone equates bool/int/float.
    return json.dumps(value, sort_keys=True, separators=(',', ':'))


def same(actual, expected):
    assert encoded(actual) == encoded(expected)


def at(value, path):
    for part in path:
        value = value[part]
    return value


def product(value):
    context, proof = value['context'], value['proof']
    same(context['actor']['transactions'][0]['clauses'], value['literal_clauses'])
    ledger = proof['source_ledger']
    same(ledger['schema_version'], 1)
    assert proof['model'] == 'private_local_formal_origin_v1'
    assert ledger['source_sha256'] == hashlib.sha256(value['source'].encode()).hexdigest()
    assert ledger['residuals'] == []
    assert len(proof['entries']) == len(ledger['entries'])
    same([ledger['catalog'][e['origin']['catalog_id']]['operation']
          for e in proof['entries']], value['literal_operations'])
    for index, entry in enumerate(proof['entries']):
        source = ledger['entries'][index]
        same(entry['source_entry'], index)
        same(entry['origin'], source['origin'])
        same(entry['source_path'], source['path'])
        same(entry['physical_path'], source['path'])
        same(entry['before'], source['target'])
        same(entry['after'], at(context['actor'], entry['physical_path']))
        same(entry['lineage'], ['lowering_ir', 'storable'])
        assert entry['transaction'] == 'main'
        for name, direction in (('allow', 'input'), ('payload', 'input'),
                                ('other', 'input'), ('result', 'output')):
            formal = entry['formals'][name]
            same(formal['identity'], ['transaction_port', 'formal_origin', 'main', name])
            assert formal['physical_name'] == 'isf_port_main_' + name
            assert formal['direction'] == direction
            assert formal['placement'] == 'direct_private'
            same(formal, context['plan']['formals']['main'][name])
    assert len(value['controls']) == 8
    for control in value['controls']:
        assert control['accepted'] == 0
        assert 'differs from authoritative source' in control['error'].splitlines()[0]


def verify():
    prior = Path('docs/audits/local-formal-origin-20261002')
    recipe = json.loads((BASE / 'recipe.json').read_text())
    for name, bound in recipe['instruments'].items():
        raw = Path(name).read_bytes()
        assert len(raw) == bound['bytes']
        assert hashlib.sha256(raw).hexdigest() == bound['sha256']
        assert raw == (BASE / 'instruments' / Path(name).name).read_bytes()
    for name, bound in json.loads((prior / 'production.json').read_text()).items():
        raw = Path(name).read_bytes()
        assert len(raw) == bound['bytes']
        assert hashlib.sha256(raw).hexdigest() == bound['sha256']
    old_manifest = json.loads((prior / 'manifest.json').read_text())
    for name, bound in old_manifest['members'].items():
        raw = (prior / name).read_bytes()
        assert len(raw) == bound['bytes']
        assert hashlib.sha256(raw).hexdigest() == bound['sha256']
    names = ['select', 'min', 'max', 'cond', 'when-bit', 'unless-bit',
             'when-field', 'unless-field', 'authored', 'nested', 'local', 'calls',
             'first_authored_sample', 'first_macro_sample']
    values = {}
    for name in names:
        value = json.loads((BASE / 'current-bound' / (name + '.json')).read_text())
        product(value)
        previous = json.loads((prior / 'current-bound' / (name + '.json')).read_text())
        for field in ('source', 'context', 'proof', 'literal_clauses', 'literal_operations'):
            same(value[field], previous[field])
        bypass = json.loads((BASE / 'bypass-red' / (name + '.json')).read_text())
        assert all(c['accepted'] == 1 for c in bypass['controls'])
        values[name] = value
    old_network = json.loads((prior / 'current-bound' / 'actor_network_boundary.json').read_text())
    reason = 'reusable/network scope is not qualified'
    assert old_network['error'].splitlines()[0] == "Error: unknown actor clause 'actors' in actor 'formal_origin'"
    assert reason in old_network['error']
    # Genuine artifact-consumer counterfactual: alter the actual diagnostic
    # predicate, preserving the same archived wrong reason and echoed regex.
    subject = old_network['error'] if '--full-stack' in sys.argv else old_network['error'].splitlines()[0]
    assert reason not in subject, 'echoed caller regex incorrectly authenticated as reason'
    for name, expected in (
        ('actor_network_boundary', 'local formal origin reusable/network scope is not qualified'),
        ('imported_producer_boundary', 'conditional origin imported source authority is not qualified'),
        ('generated_transaction_boundary', 'local formal origin generated specialization is not qualified'),
        ('domain_constructor_boundary', 'local formal origin domain scope is not qualified'),
        ('no_formal_preparation_boundary', 'local formal origin requires an unprojected direct formal')):
        value = json.loads((BASE / 'current-bound' / (name + '.json')).read_text())
        assert value['accepted'] == 0
        assert value['error'].splitlines()[0] == expected
    echo = json.loads((BASE / 'current-bound' / 'diagnostic_echo.json').read_text())
    assert echo['matched'] == 0 and echo['error'].splitlines()[0] == 'unrelated failure'
    assert echo['expected'] in echo['error']
    red_echo = json.loads((BASE / 'full-stack-red' / 'diagnostic_echo.json').read_text())
    assert red_echo['matched'] == 1
    rejected = []
    for name in ('guard', 'operation', 'scope', 'coverage', 'kind'):
        bad = copy.deepcopy(values['select'])
        if name == 'guard':
            bad['context']['actor']['transactions'][0]['clauses'][1][1] = 'forged'
            bad['proof']['entries'][0]['after'][1] = 'forged'
        elif name == 'operation':
            bad['proof']['source_ledger']['catalog'][0]['operation'] = 'when'
        elif name == 'scope':
            bad['context']['plan']['formals']['main']['payload']['identity'][2] = 'sibling'
            bad['proof']['entries'][0]['formals']['payload']['identity'][2] = 'sibling'
        elif name == 'coverage':
            bad['proof']['entries'].pop()
            bad['proof']['source_ledger']['entries'].pop()
        else:
            bad['proof']['entries'][0]['source_entry'] = '0'
        try:
            product(bad)
        except AssertionError:
            rejected.append(name)
            continue
        raise AssertionError('shared corruption accepted: ' + name)
    assert 'All tests successful' in (BASE / 'focused.txt').read_text()
    assert 'Files=1, Tests=19' in (BASE / 'focused.txt').read_text()
    assert 'Tests: 19 Failed: 1' in (BASE / 'full-stack-red.txt').read_text()
    assert 'Tests: 19 Failed: 14' in (BASE / 'bypass-red.txt').read_text()
    for name in ('clone', 'storable'):
        text = (BASE / (name + '-red.txt')).read_text()
        assert 'Tests: 1 Failed: 1' in text and 'conditional clone association missing' in text
    for name in ('regression', 'docs'):
        assert 'All tests successful' in (BASE / (name + '.txt')).read_text()
    if (BASE / 'manifest.json').exists():
        manifest = json.loads((BASE / 'manifest.json').read_text())
        paths = {str(p.relative_to(BASE)) for p in BASE.rglob('*')
                 if p.is_file() and p.name != 'manifest.json'}
        assert paths == set(manifest['members'])
        for name, bound in manifest['members'].items():
            raw = (BASE / name).read_bytes()
            assert len(raw) == bound['bytes']
            assert hashlib.sha256(raw).hexdigest() == bound['sha256']
    print('PASS first-line literal reasons, whole local products/kinds, echoed-regex/full-stack RED, '
          'actual clone/comparison RED, unchanged prior archive/production and hostile controls: ' + ', '.join(rejected))


if __name__ == '__main__':
    verify()

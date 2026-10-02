"""Cold artifact qualification. Does not run parsers, schedulers or HDL tools."""
import copy
import hashlib
import json
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
        assert 'differs from authoritative source' in control['error']


def verify():
    recipe = json.loads((BASE / 'recipe.json').read_text())
    assert recipe['baseline'] == '828691e567f2f8d7b7541566303c195e63ffbf90'
    for filename, bound in recipe['instruments'].items():
        raw = Path(filename).read_bytes()
        assert len(raw) == bound['bytes']
        assert hashlib.sha256(raw).hexdigest() == bound['sha256']
        assert raw == (BASE / 'instruments' / Path(filename).name).read_bytes()
    for filename, bound in json.loads((BASE / 'production.json').read_text()).items():
        raw = Path(filename).read_bytes()
        assert len(raw) == bound['bytes']
        assert hashlib.sha256(raw).hexdigest() == bound['sha256']
    names = ['select', 'min', 'max', 'cond', 'when-bit', 'unless-bit',
             'when-field', 'unless-field', 'authored', 'nested', 'local', 'calls',
             'first_authored_sample', 'first_macro_sample']
    values = {}
    for name in names:
        value = json.loads((BASE / 'current-bound' / (name + '.json')).read_text())
        product(value)
        values[name] = value
        bypass = json.loads((BASE / 'bypass-red' / (name + '.json')).read_text())
        assert all(c['accepted'] == 1 for c in bypass['controls'])
    same(values['select']['context'], values['authored']['context'])
    assert encoded(values['select']['proof']) != encoded(values['authored']['proof'])
    siblings = json.loads((BASE / 'current-bound' / 'siblings.json').read_text())
    same([e['transaction'] for e in siblings['proof']['entries']],
         ['main', 'main', 'sibling', 'sibling'])
    same(siblings['context']['actor']['transactions'][1]['clauses'],
         [['on', 'start'],
          ['when', 'isf_port_sibling_allow',
           ['set', 'isf_port_sibling_result', 'isf_port_sibling_payload']],
          ['when', ['!', 'isf_port_sibling_allow'],
           ['set', 'isf_port_sibling_result', 'isf_port_sibling_other']],
          ['complete', 'done']])
    for name, diagnostic in (
            ('imported_producer_boundary', 'imported source authority is not qualified'),
            ('actor_network_boundary', 'reusable/network scope is not qualified'),
            ('generated_transaction_boundary', 'generated specialization is not qualified'),
            ('domain_constructor_boundary', 'domain scope is not qualified'),
            ('no_formal_preparation_boundary', 'requires an unprojected direct formal')):
        control = json.loads((BASE / 'current-bound' / (name + '.json')).read_text())
        assert control['accepted'] == 0 and diagnostic in control['error']
    # Shared mutations cannot fool the independently written whole-clause,
    # operation, explicit scope and primitive-kind predicates.
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
    receipts = BASE / 'receipts'
    focused = (receipts / 'bound-focused.log').read_text()
    assert 'All tests successful' in focused and 'Files=1, Tests=18' in focused
    bypass = (receipts / 'bound-bypass-red.log').read_text()
    assert 'Tests: 18 Failed: 14' in bypass and 'Result: FAIL' in bypass
    for name in ('clone', 'storable'):
        red = (receipts / ('bound-' + name + '-red.log')).read_text()
        assert 'conditional clone association missing' in red
        assert 'Tests: 1 Failed: 1' in red and 'Result: FAIL' in red
        assert 'perl/FSM/Scheduler/ISF/FormalClauseResolver.pm' in red
    regression = (receipts / 'regression.log').read_text()
    assert 'All tests successful' in regression and 'Files=7, Tests=170' in regression
    docs = (receipts / 'bound-docs.log').read_text()
    assert 'All tests successful' in docs and 'Files=3, Tests=293' in docs
    assert '115 complete fixtures lowered cleanly' in docs
    if (BASE / 'manifest.json').exists():
        manifest = json.loads((BASE / 'manifest.json').read_text())
        paths = {str(p.relative_to(BASE)) for p in BASE.rglob('*')
                 if p.is_file() and p.name != 'manifest.json'}
        assert paths == set(manifest['members'])
        for filename, bound in manifest['members'].items():
            raw = (BASE / filename).read_bytes()
            assert len(raw) == bound['bytes']
            assert hashlib.sha256(raw).hexdigest() == bound['sha256']
    print('PASS local formal whole products, literal clauses, explicit origins/kinds; '
          'actual clone/comparison RED; hostile controls: ' + ', '.join(rejected))


if __name__ == '__main__':
    verify()

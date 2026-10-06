"""Source ancestry/guard models; native frame joins are a separate work unit."""
import argparse
import copy
import itertools
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-parser-path-models-20261006')
SOURCE = Path('docs/audits/record-value-original-parser-sources-20261005')
PUBLICATION = Path('docs/audits/record-value-parser-source-publication-20261005')
REVISION = '781749b7eb6675ac912125a30ded3be860c57360'
OWNER = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.2.2.2.4.1'


def module(path):
    namespace = {'__name__': 'finite_parser_model_prerequisite'}
    exec(compile(path.read_bytes(), str(path), 'exec'), namespace)
    return namespace


source_reader = module(SOURCE / 'verify.py')
require, same, identity, load = (source_reader[key] for key in ('require', 'same', 'identity', 'load'))
model = module(BASE / 'model.py')


def members(directory):
    return {p.name: identity(p.read_bytes()) for p in directory.iterdir() if p.name != 'manifest.json'}


def save(name, product):
    path = BASE / name
    if path.exists():
        require(same(load(path), product), 'whole saved finite parser model product: ' + name)
    else:
        require(not (BASE / 'manifest.json').exists(), 'sealed parser model producer cannot publish')
        path.write_text(json.dumps(product, sort_keys=True, indent=2) + '\n')


def authenticate():
    binding = load(BASE / 'binding.json')
    require(binding['revision'] == REVISION and binding['owner'] == OWNER, 'exact done parser-source intake')
    task = subprocess.check_output(['git', 'show', REVISION + ':' + binding['task_path']])
    require(same(identity(task), binding['task_identity']), 'whole committed source intake task identity')
    text = task.decode(); start = text.index('- ID: `' + OWNER + '`'); end = text.index('\n- ID:', start + 1)
    require(text[start:end] == binding['owner_body'] and '\n  Status: `done`\n' in binding['owner_body'],
            'whole done source intake leaf')
    require(set(binding['archives']) == {str(SOURCE), str(PUBLICATION)}, 'complete immediate source prerequisite domain')
    for directory, pins in binding['archives'].items():
        root = Path(directory)
        require(set(pins) == {p.name for p in root.iterdir()}, 'complete source prerequisite members')
        for name, pin in pins.items():
            path = root / name; raw = path.read_bytes()
            require(same(identity(raw), pin) and raw == subprocess.check_output(['git', 'show', REVISION + ':' + str(path)]),
                    'whole committed source prerequisite identity')
    expected = {'docs/audits/parser-source-checks-20261005/superseding-sealed-reader.json',
                'docs/audits/parser-source-checks-20261005/verify_superseding_receipt.py'}
    require(set(binding['receipts']) == expected, 'complete actual source publication receipt domain')
    for name, pin in binding['receipts'].items():
        raw = Path(name).read_bytes()
        require(same(identity(raw), pin) and raw == subprocess.check_output(['git', 'show', REVISION + ':' + name]),
                'whole committed actual source publication receipt')
    for programme in [str(PUBLICATION / 'verify.py'), 'docs/audits/parser-source-checks-20261005/verify_superseding_receipt.py']:
        result = subprocess.run(['python3', '-B', programme], capture_output=True, text=True)
        require(type(result.returncode) is int and result.returncode == 0,
                'complete historical source prerequisite replay: ' + programme)
    if (BASE / 'manifest.json').exists():
        require(same(load(BASE / 'manifest.json'), members(BASE)), 'whole parser model seal/member/kind identity')


def inputs():
    primary = module(Path('docs/audits/record-value-original-primary-20261005/verify.py'))
    authored = load(primary['context']['ACTORS'] / 'actor-models.json')['refused_sources']
    original = source_reader['original_sources']()
    inventory = source_reader['derive'](original)
    require(same(inventory, load(SOURCE / 'proofs.json')['inventory']), 'complete original source inventory projection')
    return inventory, authored, primary


def nested_allocations():
    # Reuse complete dated source-family algorithms/allocations already
    # qualified by the historical replay. Native stack frames supply neither
    # source selection nor expected order here.
    products_reader = module(Path('docs/audits/record-value-original-products-20261005/verify.py'))
    families = products_reader['models']()
    products = load(products_reader['PRODUCTS'] / 'products.json')
    require(sorted(i for rows in families.values() for i in rows) == list(range(len(products['apis']))),
            'complete independently qualified source API partition')
    result = []
    for parse_index in [2, 3]:
        rows = []
        for product in products['apis']:
            link = product['parse_link']
            if link is None or link['index'] != parse_index:
                continue
            family, _ = products_reader['FAMILIES'][product['kind']]
            source = families[family][product['source_index']]
            require(product['source_index'] == product['index'] and
                    same(product['whole_source_model'], products_reader['digest'](source)),
                    'complete nested source API model allocation')
            rows.append({'index': product['index'], 'kind': product['kind'], 'family': family,
                         'source_index': product['source_index'], 'whole_source_model': products_reader['digest'](source),
                         'source_links': product['source_links'], 'source_parse_link': link})
        result.append({'parse_index': parse_index, 'source_API_members': rows,
                       'qualification_role': 'dated complete source-family models; no new native ancestry assertion'})
    return result


def guard_truth(inventory):
    functions = {(r['unit'], r['name']): r['body'] for r in inventory['functions']}
    type_expression = functions[('parser', '_resolve_typed_width_entry')].split('if $is_aggregate', 1)[1].split(';', 1)[0]
    type_expression = '$is_aggregate' + type_expression
    write_expression = functions[('contexts', '_reference')].split('_require(!($scope->{whole_output_writes_only}', 1)[1].split(')),', 1)[0]
    write_expression = '$scope->{whole_output_writes_only}' + write_expression + ')'
    # Original predicates are evaluated by Perl, independently of Python's
    # model calculations. Only exact original guard text and the full original
    # _port_root body are executed; this is not a new original/native capture.
    programme = r'''
use strict; use warnings; use JSON::PP;
__PORT_ROOT__
my $json = JSON::PP->new->canonical; local $/; my $input = $json->decode(<STDIN>);
my @actual;
for my $row (@{$input->{type}}) {
    my ($is_aggregate, $aggregate, $record, $kind) = @$row;
    my %options = (allow_aggregate => $aggregate, allow_record => $record);
    push @actual, 0 + !!(__TYPE__);
}
my @write;
for my $row (@{$input->{write}}) {
    my ($policy, $access, $exists, $role, $path, $root_role, $root_kind) = @$row;
    my $scope = {whole_output_writes_only => $policy};
    my $value = $exists ? {role => $role, path_text => $path} : undef;
    my $name = 'value'; my $roots = {value => {role => $root_role, type_spec => {kind => $root_kind}}};
    push @write, 0 + !!(__WRITE__);
}
print $json->encode({type => \@actual, write => \@write});
'''.replace('__PORT_ROOT__', functions[('contexts', '_port_root')]).replace('__TYPE__', type_expression).replace('__WRITE__', write_expression)
    types = [list(row) for row in itertools.product([0, 1], [0, 1], [0, 1], ['bit', 'bits', 'record', 'list'])]
    writes = [list(row) for row in itertools.product([0, 1], ['read', 'write'], [0, 1], ['input', 'output', 'local'],
                                   ['', 'flag'], ['input', 'output', 'local'], ['record', 'bits'])]
    expected = {'type': [int(bool(a and not b and not (c and d == 'record'))) for a, b, c, d in types],
                'write': [int(bool(p and a == 'write' and e and r == 'output' and path
                                   and rr in ['input', 'output'] and rk == 'record'))
                          for p, a, e, r, path, rr, rk in writes]}
    result = subprocess.run(['perl', '-e', programme], input=json.dumps({'type': types, 'write': writes}),
                            capture_output=True, text=True)
    require(type(result.returncode) is int and result.returncode == 0 and result.stderr == '',
            'actual isolated original Perl guard predicate evaluation')
    actual = json.loads(result.stdout)
    require(same(actual, expected), 'independent complete finite Perl/Python guard truth agreement')
    return {'programme': programme, 'inputs': {'type': types, 'write': writes}, 'actual': actual,
            'expected': expected, 'command': ['perl', '-e', programme], 'status': result.returncode,
            'stdout': result.stdout, 'stderr': result.stderr}


def check(product, canonical):
    require(same(product['paths'], canonical['paths']), 'complete source guard/ancestry/argument/member/kind models')
    require(same(product['nested'], canonical['nested']), 'complete dated nested source API allocation')
    require(same(product['guard_truth'], canonical['guard_truth']), 'complete independent original guard truth proof')


def controls(canonical):
    output = []
    changes = [
        ('lost-type-option', lambda p: p['paths'][1]['active_own_ancestry_outer_to_inner'][-1]['supplied_arguments'].pop(), 'paths'),
        ('returned-function-as-active', lambda p: p['paths'][0]['active_own_ancestry_outer_to_inner'].append(p['paths'][1]['active_own_ancestry_outer_to_inner'][-1]), 'paths'),
        ('wrong-write-access', lambda p: p['paths'][0]['active_own_ancestry_outer_to_inner'][-2]['supplied_arguments'][2].update(source_value='read'), 'paths'),
        ('borrowed-refusal-source', lambda p: p['paths'][0].update(source=p['paths'][1]['source']), 'paths'),
        ('Boolean-guard-predicate', lambda p: p['paths'][0]['active_own_ancestry_outer_to_inner'][-1]['supplied_arguments'][0].update(source_value=False), 'paths'),
        ('lost-field-guard', lambda p: p['paths'][0]['guards'].pop(), 'paths'),
        ('reordered-ancestry', lambda p: p['paths'][0]['active_own_ancestry_outer_to_inner'].reverse(), 'paths'),
        ('invented-measured-receiver', lambda p: p['paths'][0]['active_own_ancestry_outer_to_inner'][0]['supplied_arguments'][0].update(native_identity='measured'), 'paths'),
        ('missing-nested-member', lambda p: p['nested'][0]['source_API_members'].pop(), 'nested'),
        ('borrowed-empty-allocation', lambda p: p['nested'][1].update(source_API_members=p['nested'][0]['source_API_members']), 'nested'),
        ('borrowed-nested-source-model', lambda p: p['nested'][0]['source_API_members'][0].update(whole_source_model=p['nested'][0]['source_API_members'][1]['whole_source_model']), 'nested'),
        ('wrong-independent-type-truth', lambda p: p['guard_truth']['actual']['type'].__setitem__(0, 1), 'guard_truth'),
        ('Boolean-independent-truth', lambda p: p['guard_truth']['actual']['write'].__setitem__(0, False), 'guard_truth'),
    ]
    causes = {'paths': 'complete source guard/ancestry/argument/member/kind models',
              'nested': 'complete dated nested source API allocation',
              'guard_truth': 'complete independent original guard truth proof'}
    for name, mutate, domain in changes:
        bad = copy.deepcopy(canonical); mutate(bad)
        require(not same(bad, canonical), 'genuine intended parser model control: ' + name)
        try:
            check(bad, canonical)
        except ValueError as error:
            require(str(error) == causes[domain], 'intended parser model control cause: ' + name)
            output.append({'control': name, 'status': 1, 'error': str(error)})
        else:
            raise ValueError('false-green parser source model control: ' + name)
    return output


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--seal', action='store_true'); parser.add_argument('--current', action='store_true')
    parser.add_argument('--publish', action='store_true'); parser.add_argument('--build')
    args = parser.parse_args()
    if args.publish:
        require(not (BASE / 'manifest.json').exists(), 'sealed parser model publisher cannot mutate live facts')
    authenticate()
    inventory, authored, primary = inputs()
    paths = model['derive'](inventory, authored, require, identity)
    sources = primary['load'](primary['result_reader']['CAPTURE'] / 'binding.json')['sources']
    own_source = primary['context']['source_models']()[0]
    require([r['primary'] for r in paths] == primary['parser_causes'](own_source, sources)[2:],
            'independent finite ancestry causes agree with qualified original primary causes')
    product = {'paths': paths, 'nested': nested_allocations(), 'guard_truth': guard_truth(inventory)}
    check(product, product)
    save('proofs.json', dict(product, controls=controls(product)))
    publication = module(BASE / 'publication.py')
    if args.publish:
        publication['publish']()
    elif args.current or (BASE / 'current-input.json').exists():
        publication['verify'](current=args.current, build=args.build)
    if args.seal:
        require((BASE / 'current-input.json').exists() and (BASE / 'book-proofs.json').exists(), 'complete current/native model publication before seal')
        save('manifest.json', members(BASE))
    print('PASS finite original source guard/ancestry/argument roles and dated nested source allocations; native joins remain open.')
    if not args.publish and (BASE / 'current-input.json').exists():
        print('PASS ' + ('current scoped source meanings/query/guide/capacity' if args.current else 'saved source/publication snapshot; current currency is not established'))


if __name__ == '__main__':
    main()

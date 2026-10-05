"""Finite original own parser source inventory; active/native paths remain open."""
import argparse
import copy
import hashlib
import importlib.util
import json
import re
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-original-parser-sources-20261005')
PRIOR = Path('docs/audits/record-value-own-boundary-publication-20261005')
REVISION = 'e11d97f0c79c22c240243350a27e000a13bc6243'
OWNER = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.2.2.2.3.4.2.2'


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


prior = module('parser_source_publication_prerequisite', PRIOR / 'verify.py')
recipes = module('finite_parser_source_recipes', BASE / 'recipes.py')
require, same, identity = prior.require, prior.same, prior.identity


def load(path):
    return json.loads(path.read_text())


def save(name, value):
    path = BASE / name
    if path.exists():
        require(same(load(path), value), 'whole saved parser source product: ' + name)
    else:
        require(not (BASE / 'manifest.json').exists(), 'sealed parser source producer cannot publish')
        path.write_text(json.dumps(value, sort_keys=True, indent=2) + '\n')


def members(directory):
    return {p.name: identity(p.read_bytes()) for p in directory.iterdir() if p.name != 'manifest.json'}


def authenticate():
    binding = load(BASE / 'binding.json')
    require(binding['revision'] == REVISION and binding['owner'] == OWNER, 'exact completed own-source publication intake')
    task = subprocess.check_output(['git', 'show', REVISION + ':' + binding['task_path']], text=True)
    require(task == binding['task_body'], 'whole committed parser source intake task')
    start = task.index('- ID: `' + OWNER + '`')
    end = task.index('\n- ID:', start + 1)
    require(task[start:end] == binding['owner_body'] and '\n  Status: `done`\n' in binding['owner_body'],
            'whole completed own-source publication owner')
    require(set(binding['archives']) == {str(PRIOR)}, 'complete parser source immediate dependency domain')
    for directory, pins in binding['archives'].items():
        root = Path(directory)
        require(set(pins) == {p.name for p in root.iterdir()}, 'whole parser source dependency membership')
        for name, pin in pins.items():
            path = root / name
            require(same(identity(path.read_bytes()), pin) and path.read_bytes() ==
                    subprocess.check_output(['git', 'show', REVISION + ':' + str(path)]),
                    'whole committed parser source dependency identity')
    expected = {'docs/audits/own-boundary-publication-checks-20261005/sealed-reader.json',
                'docs/audits/own-boundary-publication-checks-20261005/verify_receipt.py'}
    require(set(binding['receipts']) == expected, 'whole actual publication receipt input domain')
    for name, pin in binding['receipts'].items():
        raw = Path(name).read_bytes()
        require(same(identity(raw), pin) and raw == subprocess.check_output(['git', 'show', REVISION + ':' + name]),
                'whole committed actual publication receipt input')
    # Invoke exact historical CLI roles without leaking this reader's arguments.
    for programme in (str(PRIOR / 'verify.py'), 'docs/audits/own-boundary-publication-checks-20261005/verify_receipt.py'):
        result = subprocess.run(['python3', '-B', programme], capture_output=True, text=True)
        require(type(result.returncode) is int and result.returncode == 0, 'complete source/semantic/historical prerequisite replay: ' + programme)
    if (BASE / 'manifest.json').exists():
        require(same(load(BASE / 'manifest.json'), members(BASE)), 'whole parser source seal identity/member/kind')


def original_sources():
    primary = module('qualified_parser_primary_prerequisite', Path('docs/audits/record-value-original-primary-20261005/verify.py'))
    original = primary.load(primary.result_reader['CAPTURE'] / 'binding.json')['sources']
    return {key: original[path]['body'] for key, (path, _) in recipes.UNITS.items()}


def derive(source):
    require(set(source) == set(recipes.UNITS) and all(type(v) is str for v in source.values()), 'complete parser source unit/text kind')
    result = {'source_units': {}, 'functions': []}
    # A bounded lexical catalogue of this exact original source, not a general
    # Perl parser, syntax verifier or executable call graph.
    pattern = re.compile(r'^sub (\w+)([^\n{]*)\{', re.M)
    for key, (path, package) in recipes.UNITS.items():
        body = source[key]
        require(body.count('package ' + package + ';') == 1, 'exact own parser source package')
        declarations = [{'name': m[1], 'declaration': m[0], 'offset_bytes': len(body[:m.start()].encode()),
                         'line': body[:m.start()].count('\n') + 1} for m in pattern.finditer(body)]
        require(len({row['name'] for row in declarations}) == len(declarations), 'unique lexical own parser source declarations')
        result['source_units'][key] = {'path': path, 'package': package, 'body': body,
                                      'identity': identity(body.encode()), 'declarations': declarations}
        for name, (parameters, role) in recipes.FUNCTIONS[key].items():
            matches = [m for m in pattern.finditer(body) if m[1] == name]
            require(len(matches) == 1, 'unique selected own parser function declaration')
            match = matches[0]
            # All selected finite functions close at a column-zero brace. The
            # complete source is separately authenticated before this projection.
            close = re.search(r'^}\n', body[match.end():], re.M)
            require(close is not None, 'complete selected own parser function boundary')
            end = match.end() + close.end()
            function = body[match.start():end]
            if match[2].strip():
                require(match[2].strip() == '(' + parameters + ')', 'exact own parser signature parameter roles')
            elif parameters is not None:
                statement = 'my %args = @_;' if parameters == '%args' else 'my (' + parameters + ') = @_;'
                require(function.count(statement) == 1, 'exact own context parameter role declaration')
            else:
                require(name == '_require' and '@_ == 2' in function, 'exact positional context guard parameters')
            statements = []
            for text in recipes.STATEMENTS[(key, name)]:
                positions = [m.start() for m in re.finditer(re.escape(text), function)]
                count = 2 if (key, name, text) in {
                    ('parser', '_finalize_actor_type_references', 'for my $direction (qw(inputs outputs)) {'),
                    ('contexts', 'validate_actor_record_contexts', '$local->{whole_output_writes_only} = $whole_only;'),
                } else 1
                require(len(positions) == count, 'exact selected parser source statement occurrences')
                statements.append({'statement': text, 'offsets_bytes': [len(function[:p].encode()) for p in positions]})
            require([row['offsets_bytes'][0] for row in statements] == sorted(row['offsets_bytes'][0] for row in statements),
                    'selected parser statements retain source order')
            result['functions'].append({'unit': key, 'name': name, 'role': role, 'parameters': parameters,
                                        'body': function, 'identity': identity(function.encode()),
                                        'offset_bytes': len(body[:match.start()].encode()), 'statements': statements})
    require(set(recipes.STATEMENTS) == {(key, name) for key, names in recipes.FUNCTIONS.items() for name in names},
            'complete selected parser source statement domain')
    return result


def check(product, source, canonical):
    require(same(source, canonical), 'whole original own parser source authority')
    expected = derive(canonical)
    require(same(product, expected), 'whole parser source body/declaration/role/statement/member/kind inventory')


def controls(product, source):
    mutations = [
        ('wrong-output-policy', lambda p, s: s.update(parser=s['parser'].replace('whole_output_writes_only => 1', 'whole_output_writes_only => 0')), 'whole original own parser source authority'),
        ('wrong-type-admission', lambda p, s: s.update(parser=s['parser'].replace('allow_record => 1', 'allow_aggregate => 1')), 'whole original own parser source authority'),
        ('wrong-write-role', lambda p, s: s.update(contexts=s['contexts'].replace("_reference($target, $scope, 'write'", "_reference($target, $scope, 'read'")), 'whole original own parser source authority'),
        ('missing-source-unit', lambda p, s: s.pop('facade'), 'whole original own parser source authority'),
        ('missing-function', lambda p, s: p['functions'].pop(), 'whole parser source body/declaration/role/statement/member/kind inventory'),
        ('borrowed-parameter-role', lambda p, s: p['functions'][0].update(parameters='$borrowed'), 'whole parser source body/declaration/role/statement/member/kind inventory'),
        ('wrong-whole-body', lambda p, s: p['functions'][0].update(body='sub new {}\n'), 'whole parser source body/declaration/role/statement/member/kind inventory'),
        ('missing-statement', lambda p, s: p['functions'][0]['statements'].pop(), 'whole parser source body/declaration/role/statement/member/kind inventory'),
        ('Boolean-source-offset', lambda p, s: p['functions'][0].update(offset_bytes=False), 'whole parser source body/declaration/role/statement/member/kind inventory'),
        ('missing-declaration', lambda p, s: p['source_units']['parser']['declarations'].pop(), 'whole parser source body/declaration/role/statement/member/kind inventory'),
    ]
    receipts = []
    for name, mutate, cause in mutations:
        changed, altered = copy.deepcopy(product), copy.deepcopy(source)
        mutate(changed, altered)
        require(not same([changed, altered], [product, source]), 'genuine parser source control input: ' + name)
        try:
            check(changed, altered, source)
        except ValueError as error:
            require(str(error) == cause, 'intended parser source control boundary: ' + name)
            receipts.append({'control': name, 'status': 1, 'cause': str(error)})
        else:
            raise ValueError('false-green parser source control: ' + name)
    return receipts


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--current', action='store_true')
    parser.add_argument('--build')
    args = parser.parse_args()
    require(args.current or args.build is None, 'current native book requires explicit current role')
    authenticate()
    source = original_sources()
    product = derive(source)
    check(product, source, source)
    save('proofs.json', {'inventory': product, 'controls': controls(product, source),
                         'scope': 'Complete original own source units and lexical/relevant-body/parameter/statement provenance only; active paths, native arguments, framework/display/coordinates/addresses remain open.'})
    publication = module('parser_source_publication', BASE / 'publication.py')
    publication.verify(current=args.current, build=args.build)
    if (BASE / 'unrelated-progress.json').exists():
        unrelated = load(BASE / 'unrelated-progress.json')
        require(type(unrelated['status']) is int and unrelated['status'] == 0 and unrelated['restored'] is True
                and unrelated['command'] == ['python3', '-B', str(BASE / 'verify.py'), '--current'],
                'actual unrelated parser inventory current-reader progress and restoration')
    else:
        require(not (BASE / 'manifest.json').exists(), 'sealed parser inventory requires actual unrelated-progress evidence')
    print('PASS complete finite original own parser source inventory and genuine controls; active/native path meanings remain separately owned.')


if __name__ == '__main__':
    main()

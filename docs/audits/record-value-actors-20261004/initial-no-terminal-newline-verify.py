"""Independent whole source/actor/property/kind and parse-outcome reader."""
import argparse
import copy
import hashlib
import json
import re
import subprocess
from pathlib import Path

BASE = Path(__file__).parent
parser = argparse.ArgumentParser()
for flag in ('omit-product', 'swap-source-role', 'trust-private-product', 'numeric-source-tokens', 'omit-default-family'):
    parser.add_argument('--' + flag, action='store_true')
args = parser.parse_args()
if (BASE / 'manifest.json').exists():
    manifest = json.loads((BASE / 'manifest.json').read_text())
    assert {path.name for path in BASE.iterdir()} == set(manifest) | {'manifest.json'}
    for name, row in manifest.items():
        raw = (BASE / name).read_bytes()
        assert len(raw) == row['bytes'] and hashlib.sha256(raw).hexdigest() == row['sha256'], name
binding = json.loads((BASE / 'binding.json').read_text())
assert binding['revision'] == 'f315d5848d4d51b6a0b47d6f3c8ac1699c1a04e3' and len(binding['sources']) == 20
mutable = {'docs/knowledge/isf-aggregate-port-request-baseline.md', 'docs/book/src/13k-isf-feature-support-matrix.md'}
for path, row in binding['sources'].items():
    raw = subprocess.check_output(['git', 'show', binding['revision'] + ':' + path])
    assert raw.decode() == row['body'] and len(raw) == row['bytes'] and hashlib.sha256(raw).hexdigest() == row['sha256']
    if path not in mutable:
        assert raw == Path(path).read_bytes(), 'selected current source drift: ' + path
if (BASE / 'doc-updates.json').exists():
    updates = json.loads((BASE / 'doc-updates.json').read_text())
    assert {row['path'] for row in updates} == mutable
    for row in updates:
        assert row['before'] == binding['sources'][row['path']]['body']
        text = row['before']
        for old, new in row['replacements']:
            assert text.count(old) == 1
            text = text.replace(old, new)
        assert text == row['after'] == Path(row['path']).read_text(), 'current model document drift: ' + row['path']
else:
    assert all(binding['sources'][path]['body'] == Path(path).read_text() for path in mutable)
for archive in ('record-value-runtime-20261004', 'record-value-fields-20261004',
        'record-value-copy-fields-20261004', 'record-value-field-join-20261004'):
    directory = Path('docs/audits') / archive
    manifest = json.loads((directory / 'manifest.json').read_text())
    assert {path.name for path in directory.iterdir()} == set(manifest) | {'manifest.json'}
    for name, row in manifest.items():
        raw = (directory / name).read_bytes()
        assert len(raw) == row['bytes'] and hashlib.sha256(raw).hexdigest() == row['sha256'], name
native_path = Path('docs/audits/record-value-runtime-20261004/ordinary.json')
native = json.loads(native_path.read_text())
capture = json.loads((BASE / 'parses.json').read_text())
assert capture['native_input'] == {'bytes': native_path.stat().st_size,
    'sha256': hashlib.sha256(native_path.read_bytes()).hexdigest()}
models = json.loads((BASE / 'actor-models.json').read_text())
authored = json.loads(Path('docs/audits/record-value-fields-20261004/authored-models.json').read_text())
source = binding['sources']['t/1986-isf-record-port-value-gates.t']['body']
provider = binding['sources']['perl/FSM/Adapter/ISF/Parser.pm']['body']
assert "ISF_DEFAULT_CLOCK_NAME => 'clk'" in provider and "ISF_DEFAULT_RESET_NAME => 'rst_n'" in provider
assert "ISF_DEFAULT_WATCHDOG_LIMIT => '65535'" in provider
assert "origin => $singleton_actor_clauses->{reset} ? 'explicit' : 'legacy_default'" in provider

def exact(a, b):
    if type(a) is not type(b):
        return False
    if isinstance(a, dict):
        return set(a) == set(b) and all(exact(a[key], b[key]) for key in a)
    if isinstance(a, list):
        return len(a) == len(b) and all(exact(x, y) for x, y in zip(a, b))
    return a == b

def graph(value):
    if isinstance(value, dict):
        return ['hash', {key: graph(child) for key, child in value.items()}]
    if isinstance(value, list):
        return ['array', [graph(child) for child in value]]
    return value

def source_ast(text):
    # Independent recursive reader: primitive DSL tokens always remain text.
    position = 0
    def form():
        nonlocal position
        while position < len(text) and text[position].isspace():
            position += 1
        if text[position] == '(':
            position += 1
            children = []
            while True:
                while text[position].isspace():
                    position += 1
                if text[position] == ')':
                    position += 1
                    return children
                children.append(form())
        start = position
        while position < len(text) and not text[position].isspace() and text[position] not in '()':
            position += 1
        assert position > start
        return text[start:position]
    result = form()
    assert not text[position:].strip()
    return result

actors = copy.deepcopy(models['actors'])
if args.omit_product:
    del actors['imported']
if args.swap_source_role:
    actors['imported']['storage'][0]['type'] = 'frame'
if args.numeric_source_tokens:
    actors['local']['type_declarations'][0][2][2][1][1] = 7
if args.omit_default_family:
    del actors['local']['reset_provenance']
assert set(actors) == {'local', 'imported'}, 'complete authored whole actor product membership'
local_source = source.split("<<'ISF', 'record-value-controls.isf');\n", 1)[1].split('\nISF\n', 1)[0]
assert local_source == models['sources']['local']
assert "print {$file} '" + models['sources']['shared'] + "';" in source
imported_source = ''.join(re.findall(r"\. '([^']*)'", source[source.index("$parser->parse_source('(actor imported"):source.index('my $scope = scope_for($imported')]))
assert '(actor imported (imports (package shared))' + imported_source == models['sources']['imported']
default_keys = {'actor_name', 'clock', 'reset', 'reset_provenance', 'clock_domains', 'watchdog',
    'actor_network', 'verification_bridge', 'interface', 'handshakes', 'procs', 'drives',
    'constant_symbols', 'type_symbols', 'enum_symbols', 'transactions', 'rules', 'resources',
    'storage', 'constants', 'crossings', 'priorities', 'phases', 'stages', 'verification_observations',
    'params', 'imports', 'package_imports', 'type_declarations', 'enum_declarations', 'package_roots',
    'uses', 'library_uses', 'interface_port_metadata'}
for name, actor in actors.items():
    ast = source_ast(models['sources'][name])
    assert set(actor) == default_keys, 'complete default/optional actor product families'
    assert actor['actor_name'] == ast[1] and actor['clock'] == 'clk' and actor['watchdog'] == '65535'
    assert exact(actor['reset'], {'name': 'rst_n', 'kind': 'async', 'polarity': 'active_low'})
    assert exact(actor['reset_provenance'], [{'domain': None, 'origin': 'legacy_default'}])
    assert actor['clock_domains'] is None and actor['actor_network'] is None and actor['verification_bridge'] is None
    clauses = {clause[0]: clause for clause in ast[2:]}
    assert exact(actor['type_declarations'], clauses.get('types', ['types'])[1:]), 'complete authored DSL type tokens/order/kinds'
    assert exact(actor['transactions'], [{'name': clauses['transaction'][1], 'clauses': clauses['transaction'][2:],
        'ports': {'inputs': [], 'outputs': []}}])
    ports = clauses['interface'][1:]
    assert exact(actor['interface'], {direction + 's': [{'name': port[1], 'width': 1} for port in ports if port[0] == direction]
        for direction in ('input', 'output')})
    assert exact(actor['interface_port_metadata'], [{'name': port[1], 'width': 1, 'direction': direction}
        for direction in ('input', 'output') for port in ports if port[0] == direction])
    types = authored['types'] if name == 'local' else {}
    packages = {} if name == 'local' else {'shared': {'frame': authored['imported']['shared.frame']}}
    assert exact(actor['type_symbols'], {'local': types, 'packages': packages})
    assert exact(actor['constant_symbols'], {'packages': {} if name == 'local' else {'shared': {}}})
    assert exact(actor['enum_symbols'], {'local': {}, 'packages': {} if name == 'local' else {'shared': {}}})
    assert exact(actor['package_imports'], [] if name == 'local' else ['shared'])
    assert exact(actor['package_roots'], [] if name == 'local' else [source_ast(models['sources']['shared'])])
    assert len(actor['storage']) == len(clauses['storage']) - 1
    for declaration, stored in zip(clauses['storage'][1:], actor['storage']):
        kind, root, type_clause = declaration
        type_name = type_clause[1]
        spec = types[type_name] if name == 'local' else packages['shared']['frame']
        expected = {'kind': kind, 'name': root, 'type': type_name, 'type_spec': spec, 'width': spec['width'],
            'signals': [{'name': root, 'type': type_name, 'type_spec': spec, 'width': spec['width']}]}
        assert exact(stored, expected), 'whole storage/signal source alias/role/numeric type product'
    for family in ('rules', 'resources', 'constants', 'crossings', 'priorities', 'phases', 'stages',
            'verification_observations', 'params', 'imports', 'enum_declarations', 'uses', 'library_uses'):
        assert actor[family] == []
    assert actor['handshakes'] == actor['procs'] == actor['drives'] == {}
rows = capture['rows']
assert exact(rows, native['parses']) and len(rows) == 4
assert [row['accepted'] for row in rows] == [1, 1, 0, 0]
expected_sources = [models['sources']['local'], models['sources']['imported']] + models['refused_sources']
for index, row in enumerate(rows):
    assert row['kind'] == 'source' and row['caller'][1] == './t/1986-isf-record-port-value-gates.t'
    assert exact(row['before'], row['after']) and row['before'][0] == 'array'
    assert row['before'][1][0] == expected_sources[index], 'whole exact authored source parse input'
    label = row['before'][1][1]
    if index == 0:
        assert label == 'record-value-controls.isf'
    elif index == 1:
        assert re.fullmatch(r'\$\{REPO_ROOT\}/\.artifacts/tmp/tests/[A-Za-z0-9_]+/imported\.isf', label)
    else:
        assert label == 'still-refused.isf' and row['result'] is None and row['error']
        assert row['primary'] == row['error'].split('\n')[0]
    if index < 2:
        actual = row['result']
        if args.trust_private_product and index == 0:
            candidate = native['copies'][80]
            assert candidate['kind'] == 'test' and candidate['caller'][2] == 122
            actual = candidate['copy']
        assert exact(actual, graph(actors['local' if index == 0 else 'imported'])), 'whole numeric source actor product, not private kind-changing copy'
        assert row['error'] == '' and row['primary'] == ''
assert [row['helper'] for row in rows] == [None, None, 41, 42]
print('PASS all four original source parse outcomes, exact caller inputs/coordinates and complete source-authored local/imported actor products with strict primitive kinds, defaults, raw DSL tokens, storage/signals/types/packages/metadata/transactions. Refusals publish no product. Value/path/core API semantics and actual cause/copy assurance remain separately owned.')

"""Whole actor models from authored source and public project parser contracts."""
import copy
import json
import re
from pathlib import Path

BASE = Path(__file__).parent
binding = json.loads((BASE / 'binding.json').read_text())
source = binding['sources']['t/1986-isf-record-port-value-gates.t']['body']
authored = json.loads(Path('docs/audits/record-value-fields-20261004/authored-models.json').read_text())

def sexpr(text):
    # This finite fixture grammar contains no quoted strings or comments.
    tokens = re.findall(r'\(|\)|[^\s()]+', text)
    stack = [[]]
    for token in tokens:
        if token == '(':
            child = []
            stack[-1].append(child)
            stack.append(child)
        elif token == ')':
            assert len(stack) > 1
            stack.pop()
        else:
            stack[-1].append(token)
    assert len(stack) == 1 and len(stack[0]) == 1
    return stack[0][0]

def actor(ast, local_types, packages=None, package_root=None):
    # Exact published project parser shape/defaults. Empty optional families
    # remain present; DSL numeric tokens stay strings, resolved widths numeric.
    result = {
        'actor_name': ast[1], 'clock': 'clk', 'reset': {'name': 'rst_n', 'kind': 'async', 'polarity': 'active_low'},
        'reset_provenance': [{'domain': None, 'origin': 'legacy_default'}],
        'clock_domains': None, 'watchdog': '65535', 'actor_network': None,
        'verification_bridge': None, 'interface': {'inputs': [], 'outputs': []},
        'handshakes': {}, 'procs': {}, 'drives': {},
        'constant_symbols': {'packages': {}}, 'type_symbols': {'local': copy.deepcopy(local_types), 'packages': {}},
        'enum_symbols': {'local': {}, 'packages': {}},
    }
    for name in ('transactions', 'rules', 'resources', 'storage', 'constants', 'crossings', 'priorities',
            'phases', 'stages', 'verification_observations', 'params', 'imports', 'package_imports',
            'type_declarations', 'enum_declarations', 'package_roots', 'uses', 'library_uses'):
        result[name] = []
    if packages:
        result['type_symbols']['packages'] = copy.deepcopy(packages)
        result['constant_symbols']['packages'] = {name: {} for name in packages}
        result['enum_symbols']['packages'] = {name: {} for name in packages}
        result['package_roots'] = [package_root]
    for clause in ast[2:]:
        head = clause[0]
        if head == 'types':
            result['type_declarations'] = copy.deepcopy(clause[1:])
        elif head == 'imports':
            assert all(entry[0] == 'package' for entry in clause[1:])
            result['package_imports'] = [entry[1] for entry in clause[1:]]
        elif head == 'interface':
            for direction, name in clause[1:]:
                result['interface'][direction + 's'].append({'name': name, 'width': 1})
        elif head == 'storage':
            for kind, name, type_clause in clause[1:]:
                assert kind == 'var' and type_clause[0] == 'type'
                type_name = type_clause[1]
                if '.' in type_name:
                    package, member = type_name.split('.')
                    spec = packages[package][member]
                else:
                    spec = local_types[type_name]
                signal = {'name': name, 'type': type_name, 'width': spec['width'], 'type_spec': copy.deepcopy(spec)}
                result['storage'].append({'kind': 'var', 'name': name, 'type': type_name,
                    'width': spec['width'], 'type_spec': copy.deepcopy(spec), 'signals': [signal]})
        elif head == 'transaction':
            result['transactions'].append({'name': clause[1], 'ports': {'inputs': [], 'outputs': []},
                'clauses': copy.deepcopy(clause[2:])})
        else:
            raise AssertionError('fixture clause outside the declared finite model: ' + head)
    result['interface_port_metadata'] = [dict(port, direction=direction)
        for direction in ('input', 'output') for port in result['interface'][direction + 's']]
    return result

local_source = re.search(r"<<'ISF', 'record-value-controls.isf'\);\n(.*?)\nISF\n", source, re.S)[1]
shared_source = '(?pkg:shared (+types (type frame (record (flag bit) (data (bits 7))))))'
imported_source = '(actor imported (imports (package shared)) (interface (output done)) (storage (var value (type shared.frame))) (transaction main (complete done)))'
assert "print {$file} '" + shared_source + "';" in source
assert "'(actor imported (imports (package shared))'" in source
assert "' (interface (output done)) (storage (var value (type shared.frame)))'" in source
assert "' (transaction main (complete done)))'" in source
local_ast = sexpr(local_source)
imported_ast = sexpr(imported_source)
package_ast = sexpr(shared_source)
models = {
    'authority': 'Complete original authored controls/imported/shared package sources and published project actor parser/type/timing contracts; expected values are built before reading any native actor product.',
    'sources': {'local': local_source, 'imported': imported_source, 'shared': shared_source},
    'actors': {'local': actor(local_ast, authored['types']),
        'imported': actor(imported_ast, {}, {'shared': {'frame': authored['imported']['shared.frame']}}, package_ast)},
    'refused_sources': [
        '(actor refused (types (type frame (record (flag bit))) (type lanes (list bit bit))) (interface (output value (type frame)) (output done)) (transaction main (set value.flag 1)))',
        '(actor refused (types (type frame (record (flag bit))) (type lanes (list bit bit))) (interface (input value (type lanes)) (output done)) (transaction main (complete done)))'],
}
(BASE / 'actor-models.json').write_text(json.dumps(models, sort_keys=True, indent=2) + '\n')
print('PASS source-first whole local/imported actor models and exact authored parse inputs written; native comparison and independent controls remain required.')

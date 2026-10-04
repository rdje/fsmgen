"""Source-only complete copy references and ordered call/context recipes."""
import copy
import json
import importlib.util
from pathlib import Path

loader = importlib.util.spec_from_file_location('qualified_scope_graph_helpers',
    Path('docs/audits/record-value-scopes-20261004/source_recipes.py'))
helpers = importlib.util.module_from_spec(loader)
loader.loader.exec_module(helpers)
graph_source = helpers.graph

BASE = Path(__file__).parent
ROOTS = json.loads(Path('docs/audits/record-value-copy-fields-20261004/source-models.json').read_text())['roots']

def recipes():
    rows = []
    def reference(name, role, kind, width=None):
        spec = copy.deepcopy(ROOTS[kind if ':' in kind else 'authored:' + kind])
        return {'root': name, 'role': role, 'path_text': '', 'type_spec': spec,
            'width': spec['width'] if width is None else width}
    def add(label, source, target, helper=None, context='copy control', line=82):
        rows.append({'label': label, 'arguments': graph_source(['source', source, 'target', target, 'context', context]),
            'helper': helper, 'caller': ['main', './t/1986-isf-record-port-value-gates.t', line]})
    add('first-touch', reference('packet', 'input', 'source:first-touch-frame'), reference('held', 'storage', 'source:first-touch-frame'), context='first touch', line=62)
    add('input-storage-alias', reference('packet', 'input', 'frame'), reference('held', 'storage', 'alias'))
    add('storage-output-alias', reference('held', 'storage', 'alias'), reference('output', 'output', 'alias'))
    add('input-output-alias', reference('packet', 'input', 'frame'), reference('output', 'output', 'alias'))
    add('input-target', reference('packet', 'input', 'frame'), reference('packet', 'input', 'frame'), helper=0, context='forged write', line=114)
    for helper, name in enumerate(('renamed', 'reordered', 'signed_data', 'four', 'two', 'bit_kind'), 3):
        add('identity:' + name, reference('packet', 'input', 'frame'), reference('held', 'storage', name), helper)
    add('explicit-state', reference('packet', 'input', 'four'), reference('held', 'storage', 'two'), helper=9)
    add('nested-flat', reference('packet', 'input', 'nested'), reference('held', 'storage', 'flat'), helper=10)
    add('nested-list-order', reference('packet', 'input', 'nested'), reference('held', 'storage', 'source:swapped-nested-list'), helper=11)
    add('storage-prior-contract', reference('old', 'storage', 'frame'), reference('held', 'storage', 'signed_data'))
    add('scalar-prior-contract', reference('scalar', 'output', 'source:scalar'), reference('scalar', 'output', 'source:scalar'))
    add('literal-prior-contract', None, None, context='literal', line=226)
    add('scalar-record', reference('scalar', 'output', 'source:scalar'), reference('output', 'output', 'signed_data'), helper=23)
    add('expression-record', None, reference('output', 'output', 'signed_data'), helper=24, context='expression', line=230)
    add('list-record', reference('lanes', 'storage', 'lanes'), reference('output', 'output', 'signed_data'), helper=25)
    add('imported-local', reference('packet', 'input', 'imported:shared.frame'), reference('held', 'storage', 'frame'))
    add('contradictory-width', reference('packet', 'input', 'frame', 9), reference('held', 'storage', 'frame'), helper=40, context='hostile', line=279)
    assert len(rows) == 22
    return rows

if __name__ == '__main__':
    (BASE / 'source-recipes.json').write_text(json.dumps(recipes(), sort_keys=True, indent=2) + '\n')
    print('PASS source-only twenty-two whole reference/type/role/root/width/context/caller copy recipes; no native API/copy/result is read.')

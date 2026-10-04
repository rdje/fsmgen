"""Source-only recursive clone and preorder operation producer."""
import json
from pathlib import Path
from source_roots import graph, exact, thaw, digest

CLASS = 'FSM::Package::AggregatePathSupport'
FILE = 'perl/FSM/Package/AggregatePathSupport.pm'


def clone(value):
    if type(value) is dict:
        return {key: clone(value[key]) for key in sorted(value)}
    if type(value) is list:
        return [clone(child) for child in value]
    assert value is None or type(value) in (str, int, float)
    return value


def operations(root):
    rows = []

    def visit(value, path, parent, caller):
        index = root['index'] + len(rows)
        result = clone(value)
        arguments = graph([CLASS, value])
        rows.append({'index': index, 'root_index': root['index'],
            'whole_source_root': digest(root), 'source_path': path,
            'parent_index': parent,
            'record': {'kind': 'structured-clone', 'before': arguments,
                'after': arguments, 'result': graph(result), 'accepted': 1,
                'error': '', 'primary': '', 'warnings': [], 'caller': caller,
                'helper': root['helper'], 'parse': root['parse']},
            'joint': graph({'input': value, 'result': result})})
        if type(value) is dict:
            for key in sorted(value):
                visit(value[key], path + [key], index, [CLASS, FILE, 428])
        elif type(value) is list:
            for i, child in enumerate(value):
                visit(child, path + [i], index, [CLASS, FILE, 433])

    visit(thaw(root['expected_input']), [], None, root['caller'])
    return rows


def products():
    roots = json.loads(Path('docs/audits/record-value-clone-root-20261004/root-recipes.json').read_text())['rows']
    return [row for root in roots for row in operations(root)]

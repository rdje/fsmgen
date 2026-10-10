"""Reproduce the missed frontier mutation and qualify the genuine successor probe."""
import ast
import json
import sys
import types
import unittest
from html.parser import HTMLParser
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from contracts import BASE, MODULE, REVISION, TEST, git, literal, load, need, pin, read, root, same, test_source

SUCCESS = 'PASS retained first non-genuine frontier mutation assertion and genuine corrected whole-native raw-stack scope refusal.\n'


class Visible(HTMLParser):
    def __init__(self):
        super().__init__()
        self.parts = []

    def handle_data(self, value):
        self.parts.append(value)


def pairs(raw):
    tree = ast.parse(raw)
    methods = [n for n in ast.walk(tree) if isinstance(n, ast.FunctionDef)
               and n.name == 'test_native_tooling_preserves_address_limits_and_checkpoint_roles']
    need(len(methods) == 1, 'whole unique native frontier test method')
    loops = [n for n in ast.walk(methods[0]) if isinstance(n, ast.For)]
    need(len(loops) == 1, 'whole native frontier intervention table')
    return ast.literal_eval(loops[0].iter)


def reconstruct():
    original = git('show', REVISION + ':' + TEST)
    first_test, fact = read(BASE / 'first-focused-test.py.txt'), read(BASE / 'first-focused-fact.py.txt')
    need(first_test == original, 'exact first admitted test programme epoch')
    updated = test_source({TEST: original})
    old_pairs, new_pairs = pairs(first_test), pairs(updated)
    coordinate = git('show', REVISION + ':scripts/record_value_coordinate_fact.py')
    address_reference = literal(fact, 'REFERENCE')
    coordinate_reference = literal(coordinate, 'REFERENCE')
    html = (coordinate_reference + address_reference).replace('```sh\n', '').replace('```\n', '').replace('`', '')
    html = html.replace('final-proof.json.', '<code>final-proof.json</code>.')
    old = html.replace(*old_pairs[-1]); changed = html.replace(*new_pairs[-1])
    need(old == html and changed != html, 'first stale replacement and genuine corrected whole-native candidate')
    case = unittest.TestCase()
    try:
        case.assertNotEqual(old, html)
    except AssertionError as error:
        assertion = str(error)
    else:
        raise ValueError('first unchanged hostile candidate unexpectedly passed genuine-change assertion')
    checker = git('show', REVISION + ':scripts/check_record_value_publication.py')
    sys.path.insert(0, str(Path('scripts').resolve()))
    ns = {'__name__': 'retained_frontier_current_reader', '__file__': 'scripts/check_record_value_publication.py'}
    exec(compile(checker, ns['__file__'], 'exec'), ns)
    ns['address_fact'] = types.SimpleNamespace(REFERENCE=address_reference)
    ns['coordinate_fact'] = types.SimpleNamespace(REFERENCE=coordinate_reference)
    prior = {'book': {'Visible': Visible}}
    ns['check_tooling_native'](html, prior)
    try:
        ns['check_tooling_native'](changed, prior)
    except ValueError as error:
        need(str(error) == 'native complete current tooling scope and gaps', 'intended corrected native frontier refusal')
        refusal = str(error)
    else:
        raise ValueError('false-green corrected native frontier mutation')
    return {'first_test': pin(first_test), 'first_fact': pin(fact), 'corrected_test': pin(updated),
            'checker': pin(checker), 'original_pairs': old_pairs, 'corrected_pairs': new_pairs,
            'whole_html': html, 'first_unchanged_candidate': old, 'first_assertion': assertion,
            'corrected_candidate': changed, 'corrected_refusal': refusal,
            'scope': 'Reproduce the actual first unchanged mutation assertion and genuine successor-scope refusal; no native identity or broader raw-stack closure.'}


def main():
    root()
    product = reconstruct(); destination = BASE / 'frontier-probe-repair.json'
    need(not destination.exists() or same(load(destination), product), 'whole immutable frontier probe reproduction')
    if not destination.exists():
        destination.write_text(json.dumps(product, sort_keys=True, indent=2) + '\n')
    print(SUCCESS, end='')


if __name__ == '__main__':
    main()

"""Independent binary-source, ownership and full-product qualification.

Do not import the producer. Reconstruct line ranges and named/subtest owners
from original committed bytes, and consume the whole public example product.
"""
import argparse
import copy
import hashlib
import json
import re
import subprocess
from pathlib import Path

BASE = Path('docs/audits/coordinate-source-sites-20261008')
ROOT = Path(__file__).resolve().parents[3]
ADMISSION = 'docs/audits/coordinate-source-admission-20261008'
REVISION = '4ceb96fdc11317c77b3d18f5a5a163c12bfc58c4'
ROLE = 'Complete lexical source-site bank with conditional filename/line alternatives and dated public examples; per-refusal statement/path composition and original coordinate selection remain pending.'


def need(condition, cause):
    if not condition:
        raise ValueError(cause)


def equal(left, right):
    return json.dumps(left, sort_keys=True) == json.dumps(right, sort_keys=True)


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def native(*args):
    result = subprocess.run(['git', '--no-replace-objects', *args], capture_output=True)
    need(result.returncode == 0 and not result.stderr, 'complete independent native source result')
    return result.stdout


def expectation():
    raw = native('show', REVISION + ':' + ADMISSION + '/proof.json')
    need(Path(ADMISSION, 'proof.json').read_bytes() == raw, 'unchanged admitted whole source')
    admitted = json.loads(raw)
    source, catalog = admitted['inputs']['source'], admitted['inputs']['catalog']
    bodies = {}
    for unit, row in source['units'].items():
        body = row['body'].encode()
        if unit != 'observer':
            need(body == native('show', source['source_authority']['original_revision'] + ':' + row['path']),
                 'original committed source-unit authority')
        need(equal(pin(body), row['identity']), 'complete original source-unit identity')
        bodies[unit] = body
    transform = source['transform']
    before = native('show', source['source_authority']['capture_revision'] + ':' + transform['source_path'])
    need(before == transform['before'].encode(), 'whole original observer generator beforeimage')
    for old, new in transform['replacements']:
        need(before.count(old.encode()) == 1, 'unique ordered binary observer transform')
        before = before.replace(old.encode(), new.encode())
    need(before == bodies['observer'] == transform['after'].encode(), 'whole independently generated observer')

    entries = []
    for unit in sorted(catalog['units']):
        value = catalog['units'][unit]
        entries.extend(('named/' + unit + '/' + row['name'], unit, 'named_function', row) for row in value['named'])
        entries.extend(('guard-call/' + unit + '/' + row['role'], unit, row['role'], row) for row in value['guard_calls'])
    entries.extend(('qualified/' + str(index), row['unit'], row['role'], row)
                   for index, row in enumerate(catalog['qualified_lexical_spans']))
    sites = []
    extent_roles = ('named_function', 'installed_wrapper', 'observer_function',
                    'test_function', 'compiled_helper_wrapper', 'named_subtest_body', 'parser_function')
    for key, unit, role, row in entries:
        body = bodies[unit]
        statement = row['text'].encode()
        start, end = row['offset_bytes'], row['offset_bytes'] + row['bytes']
        need(type(start) is int and type(row['bytes']) is int and body[start:end] == statement
             and equal(pin(statement), row['identity']), 'independent complete binary source span')
        first = len(body[:start].split(b'\n'))
        closing = len(body[:start + len(statement.rstrip(b'\n'))].split(b'\n'))
        need(type(row['start_line']) is int and type(row['end_line']) is int
             and (first, closing) == (row['start_line'], row['end_line']),
             'independent exact lexical endpoint kinds')
        functions = list(re.finditer(rb'^sub ([A-Za-z_]\w*)[^\n]*?\{(?:[^\n]*\}$|\n.*?^})', body, re.M | re.S))
        need([match[1] for match in functions] == re.findall(rb'^sub ([A-Za-z_]\w*)', body, re.M),
             'complete independently scanned named owner domain')
        named = [match[1].decode() for match in functions if match.start() <= start and end <= match.end()]
        subtests = [match[1].decode() for match in re.finditer(rb"^subtest '([^']+)' => sub \{\n.*?^};", body, re.M | re.S)
                    if match.start() <= start and end <= match.end()]
        need(len(named) <= 1 and len(subtests) <= 1, 'unique independent containing lexical owner')
        path = source['units'][unit]['path']
        owner = ({'kind': 'named_function', 'name': named[0]} if named else
                 {'kind': 'authored_subtest', 'name': subtests[0]} if subtests else
                 {'kind': 'file', 'name': path})
        need('owner' not in row or row['owner'] == owner['name'], 'independent guard declaration ownership')
        sites.append({'id': key, 'unit': unit, 'role': role,
                      'kind': 'lexical_extent' if role in extent_roles else 'callback_call_container' if role == 'helper_callback' else 'statement',
                      'lexical_owner': owner, 'source_path': path,
                      'source_identity': source['units'][unit]['identity'], 'span': row,
                      'line_alternatives': {'first': first, 'closing': closing},
                      'equivalent_line_labels': [['first', 'closing']] if first == closing else [],
                      'filename_alternatives': ['./' + path, path] if unit == 'test' else [path],
                      'original_selection': None, 'coordinate_prediction': False,
                      'composition_owner': json.loads((BASE / 'owners.json').read_bytes())['composition']})
    owners = json.loads((BASE / 'owners.json').read_bytes())
    need(owners['site_bank'] == (BASE / 'scope.txt').read_text().strip(), 'persistent actual site-bank scope')
    tree = Path('docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md').read_text()
    for name, value in owners.items():
        need(tree.count('- ID: `' + value + '`\n') == 1, 'exact downstream owner exists: ' + name)
    return {'role': ROLE, 'authority': {'revision': REVISION, 'path': ADMISSION + '/proof.json', 'identity': pin(raw)},
            'owners': owners, 'sites': sites, 'invocations': source['modes'],
            'generation': {'transform': source['transform'], 'generator': source['generator'],
                           'observer_identity': pin(bodies['observer']), 'source_authority': source['source_authority']},
            'public_examples': admitted['public'],
            'unresolved': {'per_refusal_statement_paths': owners['composition'], 'original_coordinates': owners['original_join'],
                           'original_private_formatter_toolchain_identity': owners['original_join'], 'address_lifetimes': owners['addresses']}}


def check(actual, expected):
    need(actual['role'] == expected['role'] and equal(actual['unresolved'], expected['unresolved']), 'conditional scope and exact unresolved owners')
    need(equal(actual['authority'], expected['authority']) and equal(actual['owners'], expected['owners']), 'whole committed input and owning task identities')
    need(equal(actual['invocations'], expected['invocations']), 'whole original invocation roots and commands')
    need(equal(actual['generation'], expected['generation']), 'whole source and ordered generation custody')
    need(equal(actual['public_examples'], expected['public_examples']), 'complete dated public labels and refusal examples')
    need(equal(actual['sites'], expected['sites']), 'whole independent source role/owner/span/line/filename/alternative allocation')
    need(set(actual) == set(expected), 'complete conditional source-site product domain')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--record-controls', action='store_true')
    args = parser.parse_args()
    need(Path.cwd().resolve() == ROOT and BASE.resolve() == ROOT / BASE
         and BASE.stat().st_dev == ROOT.stat().st_dev
         and all(path.is_file() and not path.is_symlink() for path in BASE.iterdir()),
         'own complete same-volume regular source-site members')
    seal = BASE / 'seal.json'
    if seal.exists():
        need(equal(json.loads(seal.read_bytes()), {path.name: pin(path.read_bytes()) for path in sorted(BASE.iterdir()) if path.name != 'seal.json'}),
             'whole immutable source-site membership and bytes')
    actual = json.loads((BASE / 'sites.json').read_bytes())
    expected = expectation()
    check(actual, expected)
    controls = (
        ('lost-site', lambda p: p['sites'].pop(), 'whole independent source role/owner/span/line/filename/alternative allocation'),
        ('wrong-role', lambda p: p['sites'][0].update(role='borrowed'), 'whole independent source role/owner/span/line/filename/alternative allocation'),
        ('wrong-owner', lambda p: p['sites'][0]['lexical_owner'].update(name='borrowed'), 'whole independent source role/owner/span/line/filename/alternative allocation'),
        ('Boolean-line', lambda p: p['sites'][0]['line_alternatives'].update(first=True), 'whole independent source role/owner/span/line/filename/alternative allocation'),
        ('wrong-closing', lambda p: p['sites'][0]['line_alternatives'].update(closing=999999), 'whole independent source role/owner/span/line/filename/alternative allocation'),
        ('borrowed-body', lambda p: p['sites'][0]['span'].update(text=p['sites'][1]['span']['text']), 'whole independent source role/owner/span/line/filename/alternative allocation'),
        ('borrowed-filename', lambda p: p['sites'][0].update(filename_alternatives=['borrowed.pm']), 'whole independent source role/owner/span/line/filename/alternative allocation'),
        ('lost-equivalent-label', lambda p: next(row for row in p['sites'] if row['equivalent_line_labels'])['equivalent_line_labels'].clear(), 'whole independent source role/owner/span/line/filename/alternative allocation'),
        ('extent-as-coordinate', lambda p: p['sites'][0].update(coordinate_prediction=True), 'whole independent source role/owner/span/line/filename/alternative allocation'),
        ('foreign-root', lambda p: p['invocations'][0].update(fixture='../foreign'), 'whole original invocation roots and commands'),
        ('changed-generation', lambda p: p['generation']['transform']['replacements'][0].__setitem__(1, 'borrowed'), 'whole source and ordered generation custody'),
        ('lost-public-refusal', lambda p: p['public_examples']['native_controls'].pop(), 'complete dated public labels and refusal examples'),
        ('original-selection', lambda p: p['sites'][0].update(original_selection={'line': 1}), 'whole independent source role/owner/span/line/filename/alternative allocation'),
        ('unowned-gap', lambda p: p['unresolved'].update(original_coordinates='borrowed'), 'conditional scope and exact unresolved owners'),
    )
    decisions = []
    for name, change, cause in controls:
        candidate = copy.deepcopy(actual)
        change(candidate)
        need(not equal(candidate, actual), 'genuine complete source-site control')
        try:
            check(candidate, expected)
        except ValueError as error:
            need(str(error) == cause, 'intended source-site refusal: ' + name)
            decisions.append({'name': name, 'status': 'refused', 'cause': cause,
                              'candidate_identity': pin((json.dumps(candidate, sort_keys=True, indent=2) + '\n').encode())})
        else:
            raise ValueError('false-green source-site control: ' + name)
    if args.record_controls:
        need(not seal.exists(), 'sealed controls cannot be overwritten')
        (BASE / 'controls.json').write_text(json.dumps(decisions, sort_keys=True, indent=2) + '\n')
    else:
        need(equal(json.loads((BASE / 'controls.json').read_bytes()), decisions), 'complete independently replayed control outcomes')
    print('PASS complete independent binary source-site allocation and genuine controls; lexical extents do not predict original coordinates.')


if __name__ == '__main__':
    main()

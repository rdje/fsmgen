"""Complete lexical associations; statement/path composition is a later slice.

This source-only product never reads original frame/error coordinates. Public
recipes are dated examples, not evidence of an original runtime selection.
"""
import argparse
import copy
import hashlib
import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
BASE = Path('docs/audits/coordinate-source-sites-20261008')
ADMISSION = Path('docs/audits/coordinate-source-admission-20261008')
REVISION = '4ceb96fdc11317c77b3d18f5a5a163c12bfc58c4'
ROLE = 'Complete lexical source-site bank with conditional filename/line alternatives and dated public examples; per-refusal statement/path composition and original coordinate selection remain pending.'
EXTENTS = {'installed_wrapper', 'observer_function', 'test_function',
           'compiled_helper_wrapper', 'named_subtest_body', 'parser_function'}


def need(condition, cause):
    if not condition:
        raise ValueError(cause)


def same(left, right):
    return json.dumps(left, sort_keys=True) == json.dumps(right, sort_keys=True)


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def fixed(path):
    result = subprocess.run(['git', '--no-replace-objects', '-C', str(ROOT),
                             'show', REVISION + ':' + str(path)], capture_output=True)
    need(result.returncode == 0 and not result.stderr, 'complete fixed source input result')
    return result.stdout


def inputs():
    raw = fixed(ADMISSION / 'proof.json')
    need((ROOT / ADMISSION / 'proof.json').read_bytes() == raw,
         'unchanged whole source admission authority')
    return json.loads(raw), pin(raw)


def descriptors(admitted):
    """Enumerate the whole admitted catalog, preserving repeated source labels."""
    catalog = admitted['inputs']['catalog']
    for unit, rows in catalog['units'].items():
        for row in rows['named']:
            yield 'named/' + unit + '/' + row['name'], unit, 'named_function', row
        for row in rows['guard_calls']:
            yield 'guard-call/' + unit + '/' + row['role'], unit, row['role'], row
    for index, row in enumerate(catalog['qualified_lexical_spans']):
        yield 'qualified/' + str(index), row['unit'], row['role'], row


def lexical_owner(unit, row, catalog):
    lower, upper = row['offset_bytes'], row['offset_bytes'] + row['bytes']
    owners = [candidate['name'] for candidate in catalog['units'][unit]['named']
              if candidate['offset_bytes'] <= lower and upper <= candidate['offset_bytes'] + candidate['bytes']]
    need(len(owners) <= 1, 'unique containing named lexical owner')
    if owners:
        return {'kind': 'named_function', 'name': owners[0]}
    subtests = [candidate['name'] for candidate in catalog['qualified_lexical_spans']
                if candidate['unit'] == unit and candidate['role'] == 'named_subtest_body'
                and candidate['offset_bytes'] <= lower
                and upper <= candidate['offset_bytes'] + candidate['bytes']]
    need(len(subtests) <= 1, 'unique containing authored subtest owner')
    return {'kind': 'authored_subtest', 'name': subtests[0]} if subtests else {'kind': 'file', 'name': catalog['units'][unit]['path']}


def derive(admitted, authority):
    source, catalog = admitted['inputs']['source'], admitted['inputs']['catalog']
    owner = (ROOT / BASE / 'scope.txt').read_text().strip()
    successor = owner.rsplit('.', 1)[0] + '.2'
    # The exact join owner is supplied as a persistent declaration, never guessed
    # from a commit message or a captured coordinate.
    owners = json.loads((ROOT / BASE / 'owners.json').read_bytes())
    need(owners['site_bank'] == owner and owners['composition'] == successor,
         'persistent exact source-site and composition owners')
    sites = []
    for key, unit, role, row in descriptors(admitted):
        body = source['units'][unit]['body'].encode()
        text = row['text'].encode()
        start, size = row['offset_bytes'], row['bytes']
        need(type(start) is int and type(size) is int and body[start:start + size] == text
             and pin(text) == row['identity'], 'complete own binary site span')
        first = body[:start].count(b'\n') + 1
        closing = body[:start + len(text.rstrip(b'\n'))].count(b'\n') + 1
        need(type(row['start_line']) is int and type(row['end_line']) is int
             and (first, closing) == (row['start_line'], row['end_line']),
             'exact integer lexical line endpoints')
        enclosing = lexical_owner(unit, row, catalog)
        if 'owner' in row:
            need(row['owner'] == enclosing['name'], 'guard/call declared lexical owner')
        path = source['units'][unit]['path']
        filenames = ['./' + path, path] if unit == 'test' else [path]
        kind = ('lexical_extent' if role == 'named_function' or role in EXTENTS
                else 'callback_call_container' if role == 'helper_callback' else 'statement')
        sites.append({'id': key, 'unit': unit, 'role': role, 'kind': kind,
                      'lexical_owner': enclosing, 'source_path': path,
                      'source_identity': source['units'][unit]['identity'],
                      'span': copy.deepcopy(row), 'line_alternatives': {'first': first, 'closing': closing},
                      'equivalent_line_labels': [['first', 'closing']] if first == closing else [],
                      'filename_alternatives': filenames, 'original_selection': None,
                      'coordinate_prediction': False, 'composition_owner': successor})
    need(len({row['id'] for row in sites}) == len(sites), 'unique whole site identity domain')
    invocations = copy.deepcopy(source['modes'])
    for row in invocations:
        need(type(row['same_volume']) is bool and row['same_volume'], 'genuine same-volume invocation kind')
        root = Path(row['fixture'])
        need(not root.is_absolute() and '..' not in root.parts, 'legitimate original root recipe')
    return {'role': ROLE, 'authority': {'revision': REVISION, 'path': str(ADMISSION / 'proof.json'), 'identity': authority},
            'owners': owners, 'sites': sites, 'invocations': invocations,
            'generation': {'transform': copy.deepcopy(source['transform']),
                           'generator': copy.deepcopy(source['generator']),
                           'observer_identity': catalog['generated_observer'],
                           'source_authority': source['source_authority']},
            'public_examples': copy.deepcopy(admitted['public']),
            'unresolved': {'per_refusal_statement_paths': owners['composition'],
                           'original_coordinates': owners['original_join'],
                           'original_private_formatter_toolchain_identity': owners['original_join'],
                           'address_lifetimes': owners['addresses']}}


def save(name, value):
    path = ROOT / BASE / name
    raw = (json.dumps(value, sort_keys=True, indent=2) + '\n').encode()
    if path.exists():
        need(path.read_bytes() == raw, 'unchanged complete saved site bank')
    else:
        need(not (ROOT / BASE / 'seal.json').exists(), 'sealed site bank cannot grow')
        path.write_bytes(raw)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--seal', action='store_true')
    args = parser.parse_args()
    need(Path.cwd().resolve() == ROOT, 'invoke source-site bank from repository root')
    need((ROOT / BASE).resolve() == ROOT / BASE
         and (ROOT / BASE).stat().st_dev == ROOT.stat().st_dev
         and all(path.is_file() and not path.is_symlink() for path in (ROOT / BASE).iterdir()),
         'plain same-volume complete source-site members')
    admitted, authority = inputs()
    product = derive(admitted, authority)
    save('sites.json', product)
    if args.seal:
        save('seal.json', {path.name: pin(path.read_bytes()) for path in sorted((ROOT / BASE).iterdir())
                           if path.name != 'seal.json'})
    print('PASS complete conditional source-site bank; per-refusal composition and original coordinate selection remain pending.')


if __name__ == '__main__':
    main()

"""Whole current results joined to their own qualified authored source models.

The source/model algorithms are dated qualified prerequisites, not new oracles.
Changed input/private graphs, consumer truth and raw causes remain sibling work.
"""
import copy
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-original-products-20261005')
CAPTURE = Path('docs/audits/record-value-original-candidate-20261004')
PRODUCTS = Path('docs/audits/record-value-products-20261004')
COPY = Path('docs/audits/record-value-original-copy-reader-20261004')
FAMILIES = {
    'scope': ('scopes', 'scope-products.json'),
    'reference': ('references', 'reference-products.json'),
    'copy': ('copies', 'copy-products.json'),
    'capture': ('captures', 'capture-products.json'),
    'snapshot': ('snapshots', 'snapshot-products.json'),
    'range': ('ranges', 'range-products.json'),
    'structured-clone': ('clone-join', 'join-products.json'),
    'identity': ('identities', 'identity-products.json'),
    'payload': ('identities', 'identity-products.json'),
}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def load(path):
    return json.loads(path.read_text())


def same(a, b):
    if type(a) is not type(b):
        return False
    if isinstance(a, dict):
        return set(a) == set(b) and all(same(a[k], b[k]) for k in a)
    if isinstance(a, list):
        return len(a) == len(b) and all(same(x, y) for x, y in zip(a, b))
    return a == b


def digest(value):
    raw = json.dumps(value, sort_keys=True, separators=(',', ':')).encode()
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def identity(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def sealed(path):
    manifest = load(path / 'manifest.json')
    require({p.name for p in path.iterdir()} == set(manifest) | {'manifest.json'}, 'whole archive membership')
    for name, expected in manifest.items():
        require(identity((path / name).read_bytes()) == expected, 'whole archive identity: ' + str(path / name))
    return manifest


def authenticate():
    binding = load(BASE / 'binding.json')
    task = subprocess.check_output(['git', 'show', binding['revision'] + ':' + binding['task_path']], text=True)
    require(task == binding['task_body'], 'complete committed owner context')
    require(binding['owners'] and len({r['id'] for r in binding['owners']}) == len(binding['owners']), 'unique complete prerequisite owners')
    for owner in binding['owners']:
        start = task.index('- ID: `' + owner['id'] + '`'); end = task.index('\n- ID:', start + 1)
        require(task[start:end] == owner['body'] and '\n  Status: `done`\n' in owner['body'], 'exact done prerequisite source')
    required = {str(CAPTURE), str(COPY), str(PRODUCTS),
                'docs/audits/record-value-semantic-join-20261004',
                'docs/audits/record-value-actors-20261004',
                'docs/audits/record-value-api-join-20261004',
                'docs/audits/record-value-core-join-20261004'}
    required |= {str(Path('docs/audits/record-value-' + family + '-20261004'))
                 for family, filename in FAMILIES.values()}
    require(set(binding['archives']) == required, 'complete whole prerequisite archive domain')
    for path, manifest in binding['archives'].items():
        require(manifest == sealed(Path(path)), 'complete current prerequisite seal')
        for name in (*manifest, 'manifest.json'):
            raw = subprocess.check_output(['git', 'show', binding['revision'] + ':' + str(Path(path) / name)])
            require(raw == (Path(path) / name).read_bytes(), 'complete committed prerequisite body')
    # Reexecute the qualified copy graph reader; its complete source/archive
    # authentication also binds original programs, runtime and fixture data.
    source = {'__name__': 'original_copy_prerequisite'}
    exec(compile((COPY / 'verify.py').read_bytes(), str(COPY / 'verify.py'), 'exec'), source)
    source['main']()
    old_sources = load(PRODUCTS / 'binding.json')['sources']
    current_sources = load(CAPTURE / 'binding.json')['sources']
    for path, row in old_sources.items():
        if path.startswith(('perl/', 't/')):
            require(row['body'] == current_sources[path]['body']
                    and Path(path).read_bytes() == row['body'].encode(), 'whole unchanged model/candidate source contract')
    if (BASE / 'manifest.json').exists():
        sealed(BASE)


def models():
    result = {}
    for family, filename in set(FAMILIES.values()):
        rows = load(Path('docs/audits/record-value-' + family + '-20261004') / filename)['rows']
        result[family] = {r['index']: r for r in rows}
        require(len(result[family]) == len(rows), 'unique complete source model indices')
    return result


def source_product(kind, model):
    if kind in ('scope', 'reference', 'capture', 'snapshot', 'range'):
        return model['expected_product']
    if kind == 'copy':
        return model['meaning']['product']
    if kind == 'structured-clone':
        return model['source_product']['result']
    return model['expected_result']


def check(records, products, source_models):
    apis, actors = products['apis'], products['actors']
    require([r['index'] for r in apis] == list(range(9283)), 'complete original source product membership')
    require([r['index'] for r in actors] == list(range(4)), 'complete original authored parser product membership')
    require(sorted(i for family in source_models.values() for i in family) == list(range(9283)), 'complete source family partition')
    private_models = products['private']
    require([r['index'] for r in private_models] == sorted(i for r in apis for i in r['private_indices']), 'complete own private-stage product allocation')
    original_actors = load(Path('docs/audits/record-value-actors-20261004/actor-models.json'))
    proofs = []
    for mode in ('ordinary', 'storable', 'controls'):
        native = records[mode]
        require(len(native['api']) == len(apis) and len(native['parses']) == len(actors)
                and len(native['copies']) == 697, 'complete current API/parser/private populations')
        require(native['warnings'] == [], 'complete current warning population')
        expected_private = {}
        for index, (actual, row) in enumerate(zip(native['api'], apis)):
            kind = row['kind']; family, filename = FAMILIES[kind]
            model = source_models[family][index]
            require(row['source_index'] == index and row['family'] == family
                    and row['whole_source_model'] == digest(model), 'exact own source model allocation')
            expected = source_product(kind, model)
            require(same(row['expected_product'], expected), 'whole qualified source product authority')
            require(same(actual['result'], expected), 'whole current result primitive kinds and source meaning')
            original = row['whole_native']
            for key in ('kind', 'caller', 'helper', 'parse', 'accepted', 'warnings'):
                require(same(actual[key], original[key]), 'complete source operation/caller/context allocation')
            require(type(actual['accepted']) is int, 'actual acceptance observation kind')
            # Accepted/error status conservation is observational here. Complete
            # cause truth, raw streams and altered argument graphs stay open.
            for copy_index in row['private_indices']:
                require(copy_index not in expected_private, 'unique own private-stage membership')
                expected_private[copy_index] = index
                require(native['copies'][copy_index]['api'] == index, 'actual private-stage API ownership')
            parse_index = actual['parse']
            if parse_index is None:
                require(row['parse_link'] is None, 'exact absent source parse allocation')
            else:
                parse = native['parses'][parse_index]
                require(row['parse_link']['index'] == parse_index
                        and row['parse_link']['whole_source_parse'] == digest(actors[parse_index])
                        and row['parse_link']['bounds'] == [parse['api_start'], parse['api_end']]
                        and parse['api_start'] <= index < parse['api_end'], 'whole own parser operation allocation')
        for row in private_models:
            index = row['index']; actual = native['copies'][index]
            require(row['api'] == expected_private[index], 'whole private source model allocation')
            for key in ('kind', 'caller', 'api', 'helper', 'parse', 'accepted'):
                require(same(actual[key], row['whole_native'][key]), 'whole private operation/caller/context allocation')
        require(sorted(expected_private) == [i for i, r in enumerate(native['copies']) if r['kind'] != 'test'], 'complete actual private-stage membership')
        for index, (actual, row) in enumerate(zip(native['parses'], actors)):
            name = ('local', 'imported')[index] if index < 2 else None
            require(same(row['source_actor'], original_actors['actors'][name] if name else None), 'whole authored parser model allocation')
            require(actual['before'][1][0] == row['source'], 'exact original parser authored source')
            require(same(actual['result'], row['expected_product']), 'whole current authored parser product primitive kinds')
            for key in ('kind', 'caller', 'helper', 'accepted', 'api_start', 'api_end'):
                require(same(actual[key], row['whole_native'][key]), 'complete source parser operation allocation')
        proofs.append({'mode': mode, 'api_source_products': len(apis), 'authored_parser_products': len(actors),
                       'private_source_allocations': len(expected_private),
                       'results': digest([r['result'] for r in native['api']]),
                       'parser_results': digest([r['result'] for r in native['parses']])})
    return proofs


def controls(records, products, source_models):
    result = []

    def rejects(name, expected, change):
        bad_records, bad_products = copy.deepcopy(records), copy.deepcopy(products)
        change(bad_records, bad_products)
        try:
            check(bad_records, bad_products, source_models)
        except ValueError as error:
            require(str(error) == expected, 'wrong reached control cause: ' + name + ': ' + str(error))
            result.append({'control': name, 'status': 1, 'error': str(error)})
        else:
            raise ValueError('false-green result/source control: ' + name)

    rejects('omit-api', 'complete current API/parser/private populations', lambda r, p: r['ordinary']['api'].pop())
    rejects('borrow-source-model', 'exact own source model allocation',
            lambda r, p: p['apis'][0].update(whole_source_model=p['apis'][1]['whole_source_model']))
    rejects('wrong-source-role', 'exact own source model allocation', lambda r, p: p['apis'][0].update(family='scopes'))
    target = next(i for i, row in enumerate(products['apis']) if row['kind'] == 'scope' and row['expected_product'] is not None)
    rejects('kind-only-result', 'whole current result primitive kinds and source meaning',
            lambda r, p: r['ordinary']['api'][target]['result'][1]['packet'][1]['type_spec'][1].update(width='8'))
    rejects('wrong-call-owner', 'complete source operation/caller/context allocation',
            lambda r, p: r['ordinary']['api'][target].update(helper=0))
    rejects('false-acceptance-kind', 'complete source operation/caller/context allocation',
            lambda r, p: r['ordinary']['api'][target].update(accepted=True))
    private = products['private'][0]['index']
    rejects('wrong-private-api', 'actual private-stage API ownership',
            lambda r, p: r['ordinary']['copies'][private].update(api=1))
    rejects('omit-parser', 'complete current API/parser/private populations', lambda r, p: r['controls']['parses'].pop())
    rejects('kind-only-parser', 'whole current authored parser product primitive kinds',
            lambda r, p: r['ordinary']['parses'][0]['result'][1].update(watchdog=65535))
    return result


def main():
    authenticate()
    records = {m: load(CAPTURE / (m + '.json')) for m in ('ordinary', 'storable', 'controls')}
    products, source_models = load(PRODUCTS / 'products.json'), models()
    proofs = check(records, products, source_models)
    result = {'proofs': proofs, 'controls': controls(records, products, source_models)}
    destination = BASE / 'proofs.json'
    if destination.exists():
        require(same(load(destination), result), 'complete independent saved source-product proof')
    else:
        destination.write_text(json.dumps(result, sort_keys=True, indent=2) + '\n')
    print('PASS all original9283 API/four authored parser whole results and680 private source allocations across candidate/Storable/unchanged-input-control modes. Input/private graphs, consumers/helpers/raw causes and full alias downstream semantics remain open.')


if __name__ == '__main__':
    main()

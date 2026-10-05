"""Finite source contexts/spans; raw causes and consumer operand truth stay open."""
import copy
import json
import re
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-original-contexts-20261005')
JOIN = Path('docs/audits/record-value-original-input-join-20261005')
SEMANTICS = Path('docs/audits/record-value-semantic-join-20261004')
ACTORS = Path('docs/audits/record-value-actors-20261004')


def module(path):
    namespace = {'__name__': 'original_context_prerequisite'}
    exec(compile(path.read_bytes(), str(path), 'exec'), namespace)
    return namespace


join_reader = module(JOIN / 'verify.py')
field_reader = join_reader['field_reader']
graph_reader = join_reader['graph_reader']
result_reader = join_reader['result_reader']
require, load, same, sealed = (join_reader[k] for k in ('require', 'load', 'same', 'sealed'))
identity, digest = result_reader['identity'], result_reader['digest']


def authenticate():
    binding = load(BASE / 'binding.json')
    task = subprocess.check_output(['git', 'show', binding['revision'] + ':' + binding['task_path']], text=True)
    require(task == binding['task_body'], 'complete committed context task authority')
    require([r['id'] for r in binding['owners']] == [join_reader['PREFIX'] + '3'], 'exact done input/private context prerequisite')
    for row in binding['owners']:
        start = task.index('- ID: `' + row['id'] + '`'); end = task.index('\n- ID:', start + 1)
        require(task[start:end] == row['body'] and '\n  Status: `done`\n' in row['body'], 'whole done context prerequisite body')
    expected = set(load(JOIN / 'binding.json')['archives']) | {str(JOIN), str(SEMANTICS), str(ACTORS)}
    require(set(binding['archives']) == expected, 'complete context/source/operation prerequisite archive domain')
    for path, manifest in binding['archives'].items():
        require(manifest == sealed(Path(path)), 'whole context/source prerequisite seal')
        for name in (*manifest, 'manifest.json'):
            raw = subprocess.check_output(['git', 'show', binding['revision'] + ':' + str(Path(path) / name)])
            require(raw == (Path(path) / name).read_bytes(), 'whole committed context/source prerequisite member')
    join_reader['main']()
    if (BASE / 'manifest.json').exists():
        sealed(BASE)


def source_models():
    source = load(graph_reader['INPUTS'] / 'binding.json')['sources']['t/1986-isf-record-port-value-gates.t']['body']
    catalog = module(BASE / 'source_catalog.py')
    helpers, consumers = catalog['catalog'](source)
    require(same(load(BASE / 'source-context-catalog.json'), dict(helpers=helpers, consumers=consumers)), 'whole independently rebuilt finite source context catalog')
    products = load(result_reader['PRODUCTS'] / 'products.json')
    # Complete old source/operation allocations are dated prerequisites. Their
    # raw consumer observations are not used as operand or outcome authority.
    old = load(SEMANTICS / 'semantics.json')
    require(len(old['helpers']) == 43 and len(products['actors']) == 4, 'complete qualified original operation domain')
    for index, helper in enumerate(helpers):
        prior = old['helpers'][index]['whole_native']
        helper['api_members'] = [r['index'] for r in products['apis'] if r['whole_native']['helper'] == index]
        helper['consumer_members'] = [r['index'] for r in consumers if r['helper'] == index]
        helper['parse_members'] = [r['index'] for r in products['actors'] if r['whole_native']['helper'] == index]
        helper['copy_members'] = [r['index'] for r in products['private'] if r['whole_native']['helper'] == index]
        helper['api_bounds'] = [prior['api_start'], prior['api_end']]
        helper['parse_bounds'] = [prior['parse_start'], prior['parse_end']]
        require(helper['api_members'] == list(range(*helper['api_bounds'])), 'complete own qualified source helper API span')
        require(helper['parse_members'] == list(range(*helper['parse_bounds'])), 'complete own qualified source helper parser span')
        require(helper['consumer_members'] == list(range(*[prior['consumer_start'], prior['consumer_end']])), 'independent source consumer/helper span')
    return source, helpers, consumers, products


def check(records, execution, source, helpers, consumers, products):
    actor_models = load(ACTORS / 'actor-models.json')
    parser_sources = [actor_models['sources']['local'], actor_models['sources']['imported'], *actor_models['refused_sources']]
    require("'record-value-controls.isf'" in source and "\"$work/imported.isf\"" in source and "'still-refused.isf'" in source, 'exact source-authored filename roles')
    proof = []
    for mode in ('ordinary', 'storable', 'controls'):
        native = records[mode]
        require(len(native['helpers']) == 43 and len(native['consumers']) == 125 and len(native['parses']) == 4
                and len(native['api']) == 9283 and len(native['copies']) == 697, 'complete current context operation population')
        for model, actual in zip(helpers, native['helpers']):
            require(same({k: actual[k] for k in ('label', 'pattern', 'caller')},
                         {k: model[k] for k in ('label', 'pattern', 'caller')}), 'exact source-authored helper label/pattern/caller')
            index = model['index']
            for section, label in (('api', 'api'), ('consumers', 'consumer'), ('parses', 'parse')):
                members = model[label + '_members']
                bounds = [actual[label + '_start'], actual[label + '_end']]
                require(all(type(n) is int for n in bounds) and members == list(range(*bounds)), 'whole own source helper operation span')
                require(members == [i for i, row in enumerate(native[section]) if row['helper'] == index], 'complete own source helper operation membership')
            require(model['copy_members'] == [i for i, row in enumerate(native['copies']) if row['helper'] == index], 'complete own source helper private copy membership')
        for model, actual in zip(consumers, native['consumers']):
            require(same({k: actual[k] for k in ('kind', 'label', 'helper', 'caller')},
                         {k: model[k] for k in ('kind', 'label', 'helper', 'caller')}), 'exact source-authored consumer kind/label/helper/caller')
        receipt = next(r for r in execution['modes'] if r['mode'] == mode)
        parsed = []
        for index, actual in enumerate(native['parses']):
            original = products['actors'][index]['whole_native']
            require(same(actual['caller'], original['caller']) and same(actual['helper'], original['helper']), 'own qualified parser caller/helper context')
            arguments = graph_reader['thaw'](actual['before'])
            require(type(arguments) is list and len(arguments) == 2 and type(arguments[1]) is str
                    and arguments[0] == parser_sources[index], 'whole source-authored parser input text/context')
            filename = arguments[1]
            if index == 1:
                # The random basename and historical absolute prefix are opaque
                # retained capture coordinates, not reusable runtime paths.
                suffix = receipt['fixture'] + r'/\.artifacts/tmp/tests/[A-Za-z0-9_]+/imported\.isf'
                require(re.search(r'(?:^|/)' + re.escape(receipt['fixture']) + r'/\.artifacts/tmp/tests/[A-Za-z0-9_]+/imported\.isf$', filename) is not None,
                        'own imported parser filename role/fixture suffix')
                require("print {$file} '" + actor_models['sources']['shared'] + "';" in source, 'whole source-authored imported package fixture')
            else:
                require(filename == ('record-value-controls.isf' if index == 0 else 'still-refused.isf'), 'exact source-authored logical parser filename')
            require(same(actual['before'], actual['after']), 'whole parser input context readonly')
            members = [r['index'] for r in products['apis'] if r['whole_native']['parse'] == index]
            require(members == list(range(actual['api_start'], actual['api_end']))
                    and members == [i for i, row in enumerate(native['api']) if row['parse'] == index], 'complete own parser API operation span')
            parsed.append(dict(index=index, raw_filename=filename, source_input=identity(arguments[0].encode()),
                               whole_before=digest(actual['before']), caller=actual['caller'], helper=actual['helper'], api_members=members))
        proof.append(dict(mode=mode, source_helpers=helpers, source_consumers=consumers, parsers=parsed,
                          raw_helpers=digest(native['helpers']), raw_consumers=digest(native['consumers']), raw_parsers=digest(native['parses'])))
    return proof


def controls(records, execution, source, helpers, consumers, products):
    rejected = []

    def reject(name, change, cause):
        bad = copy.deepcopy(records); change(bad)
        try:
            check(bad, execution, source, helpers, consumers, products)
        except ValueError as error:
            require(str(error) == cause, 'wrong intended source-context control cause: ' + name)
            rejected.append(dict(control=name, status=1, error=str(error)))
        else:
            raise ValueError('false-green source-context control: ' + name)

    reject('wrong-helper-label', lambda n: n['ordinary']['helpers'][0].update(label='whole input target'), 'exact source-authored helper label/pattern/caller')
    reject('wrong-helper-pattern', lambda n: n['ordinary']['helpers'][0].update(pattern='(?^:wrong cause)'), 'exact source-authored helper label/pattern/caller')
    reject('wrong-helper-caller', lambda n: n['ordinary']['helpers'][0]['caller'].__setitem__(2, 116), 'exact source-authored helper label/pattern/caller')
    reject('wrong-helper-span', lambda n: n['ordinary']['helpers'][0].update(consumer_end=12), 'whole own source helper operation span')
    reject('borrow-api-owner', lambda n: n['ordinary']['api'][820].update(helper=1), 'complete own source helper operation membership')
    reject('wrong-consumer-label', lambda n: n['ordinary']['consumers'][0].update(label='reference validation retains original typed JSON'), 'exact source-authored consumer kind/label/helper/caller')
    reject('wrong-consumer-kind', lambda n: n['ordinary']['consumers'][0].update(kind='ok'), 'exact source-authored consumer kind/label/helper/caller')
    reject('wrong-consumer-caller', lambda n: n['ordinary']['consumers'][0]['caller'].__setitem__(2, 56), 'exact source-authored consumer kind/label/helper/caller')
    reject('wrong-parser-source', lambda n: n['ordinary']['parses'][0]['before'][1].__setitem__(0, '(actor wrong)'), 'whole source-authored parser input text/context')
    reject('borrow-parser-fixture', lambda n: n['ordinary']['parses'][1]['before'][1].__setitem__(1, 'imported.isf'), 'own imported parser filename role/fixture suffix')
    reject('omit-helper', lambda n: n['controls']['helpers'].pop(), 'complete current context operation population')
    reject('omit-consumer', lambda n: n['controls']['consumers'].pop(), 'complete current context operation population')
    reject('omit-parser', lambda n: n['controls']['parses'].pop(), 'complete current context operation population')
    return rejected


def main():
    authenticate()
    source, helpers, consumers, products = source_models()
    records = {m: load(result_reader['CAPTURE'] / (m + '.json')) for m in ('ordinary', 'storable', 'controls')}
    execution = load(result_reader['CAPTURE'] / 'execution.json')
    result = dict(proofs=check(records, execution, source, helpers, consumers, products),
                  controls=controls(records, execution, source, helpers, consumers, products))
    path = BASE / 'proofs.json'
    if path.exists():
        require(same(load(path), result), 'complete saved original source-context/span proof')
    else:
        path.write_text(json.dumps(result, sort_keys=True, indent=2) + '\n')
    print('PASS complete finite source-authored helper/consumer/parser contexts and qualified own operation spans. '
          'Raw operands/errors retain; primary/raw-coordinate and consumer-operand truth remain open.')


if __name__ == '__main__':
    main()

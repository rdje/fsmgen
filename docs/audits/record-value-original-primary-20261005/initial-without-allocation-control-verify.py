"""Source-derived finite primary causes; complete raw stacks remain open."""
import copy
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-original-primary-20261005')
CONTEXT = Path('docs/audits/record-value-original-contexts-20261005')
OWNER = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.1'


def module(path):
    namespace = {'__name__': 'original_primary_prerequisite'}
    exec(compile(path.read_bytes(), str(path), 'exec'), namespace)
    return namespace


context = module(CONTEXT / 'verify.py')
graph = context['graph_reader']
result_reader = context['result_reader']
require, load, same, sealed = (context[key] for key in ('require', 'load', 'same', 'sealed'))
identity, digest = context['identity'], context['digest']


def authenticate():
    binding = load(BASE / 'binding.json')
    task = subprocess.check_output(['git', 'show', binding['revision'] + ':' + binding['task_path']], text=True)
    require(task == binding['task_body'], 'whole committed primary task authority')
    require([row['id'] for row in binding['owners']] == [OWNER], 'exact done source-context owner')
    start = task.index('- ID: `' + OWNER + '`'); end = task.index('\n- ID:', start + 1)
    require(binding['owners'][0]['body'] == task[start:end] and '\n  Status: `done`\n' in task[start:end], 'whole completed source-context owner body')
    require(set(binding['archives']) == set(load(CONTEXT / 'binding.json')['archives']) | {str(CONTEXT)}, 'whole primary prerequisite archive domain')
    for path, manifest in binding['archives'].items():
        require(manifest == sealed(Path(path)), 'whole primary prerequisite identity')
        for name in (*manifest, 'manifest.json'):
            raw = subprocess.check_output(['git', 'show', binding['revision'] + ':' + str(Path(path) / name)])
            require(raw == (Path(path) / name).read_bytes(), 'complete committed primary prerequisite body')
    context['main']()
    if (BASE / 'manifest.json').exists():
        sealed(BASE)


def parser_causes(source, sources):
    model = load(context['ACTORS'] / 'actor-models.json')
    # These exact complete source declarations establish the two admission
    # branches. The model is intentionally finite, not a general DSL parser.
    output, root_list = model['refused_sources']
    require('(actor refused' in output and '(output value (type frame))' in output
            and '(transaction main' in output and '(set value.flag 1)' in output,
            'whole source-authored output-field refusal input')
    require('(actor refused' in root_list and '(input value (type lanes))' in root_list
            and '(type lanes (list bit bit))' in root_list,
            'whole source-authored list-root refusal input')
    contexts = sources['perl/FSM/Support/ISFRecordPortContexts.pm']['body']
    parser = sources['perl/FSM/Adapter/ISF/Parser.pm']['body']
    require('whole_output_writes_only' in contexts and 'record output field writes are not yet admitted; ' in contexts
            and "target '$token' requires output-field writer qualification" in contexts,
            'exact output-field source admission precedence')
    require("if $is_aggregate && !$options{allow_aggregate}" in parser
            and "!($options{allow_record} && $kind eq 'record')" in parser,
            'exact aggregate parser source admission precedence')
    require(source.count('"$direction $type source"') == 1, 'own finite refused parser source loop')
    return [None, None,
            "Invalid ISF record context: transaction 'main' set target record output field writes are not yet admitted; target 'value.flag' requires output-field writer qualification",
            "Error: actor 'refused' interface port 'value' references aggregate type 'lanes'; this ISF slice accepts aggregate type aliases only on actor-owned storage variables and packed record actor ports"]


def models():
    source, helpers, consumers, products = context['source_models']()
    sources = load(result_reader['CAPTURE'] / 'binding.json')['sources']
    intervention_api, private, ingredients = graph['source_interventions']()
    primary = module(BASE / 'cause_model.py')['primary']
    expected = {}
    for mode in ('ordinary', 'storable', 'controls'):
        rows = []
        for row in products['apis']:
            index = row['index']
            arguments = intervention_api[index] if mode != 'storable' and index in intervention_api else graph['thaw'](row['whole_native']['before'])
            message = primary(row['kind'], arguments)
            rows.append(dict(index=index, kind=row['kind'], helper=row['whole_native']['helper'],
                             parse=row['whole_native']['parse'], primary=message,
                             source_arguments=digest(row['whole_native']['before']) if mode == 'storable' or index not in intervention_api
                             else dict(source_intervention=index)))
        expected[mode] = rows
    return expected, parser_causes(source, sources), helpers, products


def check(records, expected, parser_expected, helpers):
    proof = []
    for mode in ('ordinary', 'storable', 'controls'):
        native, rows = records[mode], expected[mode]
        require(len(native['api']) == len(rows) == 9283 and len(native['parses']) == len(parser_expected) == 4,
                'complete own primary API/parser population')
        failures = []
        for row, actual in zip(rows, native['api']):
            message = row['primary']; error = actual['error']
            require(type(error) is str, 'raw API cause body kind')
            require((error.splitlines()[0] if error else None) == message, 'exact own source-derived API first cause')
            require(type(actual['accepted']) is int and actual['accepted'] == (0 if message is not None else 1),
                    'source-derived API acceptance truth')
            if message is not None:
                require(actual['result'] is None, 'refused API publishes no product')
                failures.append(dict(**row, raw_error=identity(error.encode()), caller=actual['caller']))
        parses = []
        for index, (message, actual) in enumerate(zip(parser_expected, native['parses'])):
            error = actual['error']
            require(type(error) is str and (error.splitlines()[0] if error else None) == message,
                    'exact own source-derived parser first cause')
            require(actual['primary'] == (message or '') and type(actual['accepted']) is int
                    and actual['accepted'] == (0 if message is not None else 1), 'source-derived parser primary/acceptance truth')
            if message is not None:
                require(actual['result'] is None, 'refused parser publishes no actor')
            parses.append(dict(index=index, primary=message, raw_error=identity(error.encode())))
        helper_causes = []
        for helper in helpers:
            failed = [row for row in failures if row['helper'] == helper['index']]
            parsed = [parses[index] for index in helper['parse_members'] if parses[index]['primary'] is not None]
            require(bool(failed) != bool(parsed), 'own helper has exactly one failing API or parser family')
            first = min(failed, key=lambda row: row['index']) if failed else parsed[0]
            helper_causes.append(dict(index=helper['index'], label=helper['label'], primary=first['primary'],
                                      failing_api_members=[row['index'] for row in failed], failing_parse_members=[row['index'] for row in parsed]))
        proof.append(dict(mode=mode, complete_source_API_primary_models=rows, API_failures=failures,
                          parsers=parses, helpers=helper_causes))
    return proof


def controls(records, expected, parsers, helpers):
    result = []

    def reject(name, mutate, cause):
        bad = copy.deepcopy(records); mutate(bad)
        try:
            check(bad, expected, parsers, helpers)
        except ValueError as error:
            require(str(error) == cause, 'wrong intended primary control cause: ' + name)
            result.append(dict(control=name, status=1, error=str(error)))
        else:
            raise ValueError('false-green primary cause control: ' + name)

    reject('wrong-first-cause', lambda n: n['ordinary']['api'][820].update(error="Invalid ISF record value: wrong role\n" + n['ordinary']['api'][820]['error']), 'exact own source-derived API first cause')
    reject('stack-echo', lambda n: n['ordinary']['api'][820].update(error="Unrelated source failure\n" + n['ordinary']['api'][820]['error']), 'exact own source-derived API first cause')
    reject('borrow-other-path', lambda n: n['ordinary']['api'][878].update(error=n['ordinary']['api'][877]['error']), 'exact own source-derived API first cause')
    reject('borrow-inner-metadata', lambda n: n['ordinary']['api'][7750].update(error=n['ordinary']['api'][7839]['error']), 'exact own source-derived API first cause')
    reject('hide-inner-metadata', lambda n: n['ordinary']['api'][7839].update(error=''), 'exact own source-derived API first cause')
    reject('false-green-API', lambda n: n['ordinary']['api'][820].update(accepted=1), 'source-derived API acceptance truth')
    reject('accepted-status-kind', lambda n: n['ordinary']['api'][0].update(accepted='1'), 'source-derived API acceptance truth')
    reject('refused-API-product', lambda n: n['ordinary']['api'][820].update(result=1), 'refused API publishes no product')
    reject('parser-source-echo', lambda n: n['ordinary']['parses'][2].update(error="Unrelated parser failure\n" + n['ordinary']['parses'][2]['error']), 'exact own source-derived parser first cause')
    reject('false-green-parser', lambda n: n['ordinary']['parses'][2].update(accepted=1), 'source-derived parser primary/acceptance truth')
    reject('borrow-parser-primary', lambda n: n['ordinary']['parses'][2].update(primary=n['ordinary']['parses'][3]['primary']), 'source-derived parser primary/acceptance truth')
    reject('omit-API', lambda n: n['controls']['api'].pop(), 'complete own primary API/parser population')
    reject('omit-parser', lambda n: n['controls']['parses'].pop(), 'complete own primary API/parser population')
    return result


def main():
    authenticate()
    expected, parsers, helpers, products = models()
    records = {mode: load(result_reader['CAPTURE'] / (mode + '.json')) for mode in expected}
    proof = dict(proofs=check(records, expected, parsers, helpers), controls=controls(records, expected, parsers, helpers))
    path = BASE / 'proofs.json'
    if path.exists():
        require(same(load(path), proof), 'complete saved source-derived primary proof')
    else:
        path.write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    print('PASS complete finite source-derived API/helper/parser primary causes and acceptance; full raw coordinates/address and consumer operand truth remain open.')


if __name__ == '__main__':
    main()

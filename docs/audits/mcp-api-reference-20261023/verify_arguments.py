#!/usr/bin/env python3
"""Re-derive labeled argument admission and caller-kind findings from raw data."""
import copy
import gzip
import hashlib
import json
from pathlib import Path
import subprocess
import sys
from functools import lru_cache

from verify_inventory import check_schema, encoded, errors, same_value

ROOT = Path(__file__).resolve().parents[3]
SCALARS = {'null': None, 'false': False, 'true': True, 'zero': 0, 'one': 1,
           'fraction': 1.5, 'array': [], 'object': {}, 'empty_string': '',
           'numeric_string': '1', 'unicode_string': 'é'}
NUMERIC = {'integral_decimal': '1.0', 'integral_exponent': '1e0',
           'large_integer': '1e30', 'negative_integer': '-1'}
ENVELOPE = {'type': 'object', 'properties': {'name': {'type': 'string'},
             'arguments': {'type': 'object'}}, 'required': ['name']}


@lru_cache(maxsize=None)
def native_digest(head, path):
    return hashlib.sha256(subprocess.check_output(['git', 'show', head + ':' + path])).hexdigest()


def expected_cases(tools):
    result = {}
    for tool in tools:
        name, schema = tool['name'], tool['inputSchema']
        for suffix in ('valid_base', 'arguments_omitted', 'unknown_field', 'params_omitted'):
            result[name + ':' + suffix] = (name, suffix, None)
        for place in ('root', 'name', 'params'):
            for kind in SCALARS:
                result[name + ':' + place + '_' + kind] = (name, place, kind)
        for field, definition in schema['properties'].items():
            for kind in SCALARS:
                result[name + ':' + field + ':' + kind] = (name, field, kind)
            if definition['type'] == 'integer':
                for kind in NUMERIC:
                    result[name + ':' + field + ':' + kind] = (name, field, kind)
            for value in definition.get('enum', []):
                result[name + ':' + field + ':enum_' + str(value)] = (name, field, value)
            if definition['type'] == 'integer' and 'enum' in definition:
                result[name + ':' + field + ':version_string'] = (name, field, 'version_string')
    return result


def validate_cases(record):
    tools = {t['name']: t for t in record['tools']}
    assert len(tools) == len(record['tools'])
    wanted = expected_cases(record['tools'])
    cases = record['cases']
    assert len(cases) == len(wanted) and {c['label'] for c in cases} == set(wanted), 'case population mismatch'
    baselines = {c['tool']: json.loads(c['request_utf8'])['params']['arguments']
                 for c in cases if c['label'].endswith(':valid_base')}
    for case in cases:
        name, place, kind = wanted[case['label']]
        request = json.loads(case['request_utf8'])
        assert case['tool'] == name and request['method'] == 'tools/call'
        if place == 'params_omitted':
            assert 'params' not in request, 'omitted params case actually supplies params'
            continue
        params = request['params']
        if place == 'params':
            assert same_value(params, SCALARS[kind]), 'wrong params-kind case'
            continue
        assert isinstance(params, dict)
        if place == 'name':
            assert same_value(params['name'], SCALARS[kind]), 'wrong name-kind case'
            assert params['arguments'] == {}
            continue
        assert params['name'] == name
        if place == 'arguments_omitted':
            assert 'arguments' not in params
            continue
        if place == 'root':
            assert same_value(params['arguments'], SCALARS[kind]), 'wrong root-kind case'
            continue
        arguments = params['arguments']
        if place == 'valid_base':
            assert not errors(arguments, tools[name]['inputSchema'])
        elif place == 'unknown_field':
            assert encoded(arguments) == encoded(dict(baselines[name], unpublished_argument=True))
        else:
            if kind in SCALARS:
                value = SCALARS[kind]
            elif kind in NUMERIC:
                value = json.loads(NUMERIC[kind])
                assert '"' + place + '": ' + NUMERIC[kind] in case['request_utf8']
            elif kind == 'version_string':
                value = '2'
            else:
                value = kind
            assert same_value(arguments, dict(baselines[name], **{place: value})), 'field case borrowed or mislabeled'
    return tools


def verify(record):
    tools = validate_cases(record)
    assert record['orderly_eof'] is True and type(record['exit_status']) is int and record['exit_status'] == 0
    expected_native = {p for p in subprocess.check_output(['git', 'ls-tree', '-r', '--name-only',
        record['head'], 'perl/FSM']).decode().splitlines() if p.endswith('.pm')}
    assert set(record['source_sha256']) == expected_native | set(record['observer_sources'])
    overrides = record.get('native_source_overrides', {})
    assert set(overrides) <= expected_native, 'unowned native overlay path'
    for path in expected_native:
        identity = record['source_sha256'][path]
        if path in overrides:
            assert native_digest(record['head'], path) != identity, 'redundant native overlay'
            assert hashlib.sha256(overrides[path].encode('utf-8')).hexdigest() == identity, 'native overlay hash mismatch'
        else:
            assert native_digest(record['head'], path) == identity, 'native source boundary mismatch'
    for path, source in record['observer_sources'].items():
        assert hashlib.sha256(source.encode('utf-8')).hexdigest() == record['source_sha256'][path]
    sent = [json.loads(line) for line in record['sent_utf8'].splitlines()]
    replies = [json.loads(line) for line in record['received_utf8'].splitlines()]
    assert [r for r in sent if 'id' not in r] == [{'jsonrpc': '2.0', 'method': 'notifications/initialized'}]
    requests = [r for r in sent if 'id' in r]
    assert requests[0]['method'] == 'initialize' and requests[1]['method'] == 'tools/list'
    assert encoded(replies[1]['result']['tools']) == encoded(record['tools'])
    assert encoded(replies[2:]) == encoded(record['wire_replies']), 'wire reply join failed'
    assert len(requests) == len(replies) == len(record['cases']) + 2
    assert [r['id'] for r in requests] == list(range(len(requests)))
    for request, reply in zip(requests, replies):
        assert type(request['id']) is int and type(reply['id']) is int
        assert request['id'] == reply['id']
        assert request['jsonrpc'] == reply['jsonrpc'] == '2.0'
    assert len(record['api']['rows']) == len(record['cases'])
    findings = {'unsupported_input_admitted': [], 'invalid_input_error_class': [],
                'caller_value_changed': [], 'caller_clone_changed': []}
    fields = []
    for name, tool in tools.items():
        check_schema(tool['inputSchema'])
        fields.extend(name + '/' + key for key in tool['inputSchema']['properties'])
    for case, request, wire_reply, api in zip(record['cases'], requests[2:], replies[2:], record['api']['rows']):
        expected = json.loads(case['request_utf8'])
        assert same_value(request, expected) and api['label'] == case['label']
        assert type(wire_reply['id']) is int and wire_reply['id'] == request['id']
        response = api['response']
        assert type(response['id']) is int and response['id'] == request['id']
        assert response['jsonrpc'] == wire_reply['jsonrpc'] == '2.0'
        assert ('result' in response) == ('result' in wire_reply), 'API/pipe admission differs'
        for key in ('request_before_json', 'request_before_clone_json'):
            assert same_value(json.loads(api[key]), expected), 'API input is already mislabeled or changed'
        params = expected.get('params')
        invalid = errors(params, ENVELOPE)
        if not invalid and params['name'] in tools:
            invalid = errors(params.get('arguments', {}), tools[params['name']]['inputSchema'])
        if case['label'].endswith(':valid_base'):
            assert not invalid and 'result' in response and response['result']['isError'] is False
        if 'result' in response:
            assert encoded(response) == encoded(wire_reply), 'complete API/pipe result differs'
            result = response['result']
            assert type(result['isError']) is bool
            assert same_value(json.loads(result['content'][0]['text']), result['structuredContent'])
            if invalid:
                findings['unsupported_input_admitted'].append(case['label'])
        else:
            assert response['error']['code'] == wire_reply['error']['code']
            if invalid and response['error']['code'] != -32602:
                findings['invalid_input_error_class'].append(case['label'])
        if not same_value(json.loads(api['request_before_json']), json.loads(api['request_after_json'])):
            assert invalid, 'a valid request changes caller values'
            findings['caller_value_changed'].append(case['label'])
        if not same_value(json.loads(api['request_before_clone_json']), json.loads(api['request_after_clone_json'])):
            assert invalid, 'a valid request changes caller kinds'
            findings['caller_clone_changed'].append(case['label'])
    literal_population = ['null', 'true', 'false', '0', '1', '1.0', '1e0', '1e30', '1.5', '"1"', '"é"', '[]', '{}']
    assert [p['input_literal'] for p in record['api']['kind_probes']] == literal_population, 'scalar prototype literal population mismatch'
    for probe in record['api']['kind_probes']:
        value = json.loads(probe['input_literal'])
        kind = 'integer' if type(value) in (int, float) and float(value).is_integer() else {
            type(None): 'null', bool: 'boolean', str: 'string', list: 'array', dict: 'object', float: 'number'}[type(value)]
        assert probe['kind'] == kind
        assert same_value(json.loads(probe['before_clone_json']), json.loads(probe['after_clone_json']))
    controls = record['api']['text_inspection_controls']
    assert [c['operation'] for c in controls] == ['length', 'lc']
    for control in controls:
        assert same_value(json.loads(control['before_clone_json']), {'value': 0})
        assert same_value(json.loads(control['direct_after_clone_json']), {'value': '0'}), 'direct text control lost mutation'
        assert same_value(json.loads(control['detached_after_clone_json']), {'value': 0}), 'detached text control changed kind'
    return {'tools': len(tools), 'input_fields': len(fields), 'labeled_cases_per_entrypoint': len(record['cases']),
            'selected_native_sources': len(expected_native), 'findings': findings}


def rewire(record, requests=False):
    headers = record['received_utf8'].splitlines()[:2]
    record['received_utf8'] = '\n'.join(headers + [json.dumps(r) for r in record['wire_replies']]) + '\n'
    if requests:
        headers = record['sent_utf8'].splitlines()[:3]
        record['sent_utf8'] = '\n'.join(headers + [c['request_utf8'] for c in record['cases']]) + '\n'


def controls(record):
    rejected = []
    variants = [('missing_case', 'case population mismatch'),
                ('false_omission', 'omitted params case actually supplies params'),
                ('wrong_scalar_kind', 'field case borrowed or mislabeled'),
                ('borrowed_api_reply', 'complete API/pipe result differs'),
                ('lost_wire_reply', 'wire reply join failed'),
                ('prechanged_api_input', 'API input is already mislabeled or changed'),
                ('concealed_text_control', 'direct text control lost mutation'),
                ('boolean_detached_control', 'detached text control changed kind')]
    for name, expected in variants:
        bad = copy.deepcopy(record)
        if name == 'missing_case':
            bad['cases'].pop()
            bad['wire_replies'].pop()
            bad['api']['rows'].pop()
            rewire(bad, requests=True)
        elif name == 'false_omission':
            index = next(i for i,c in enumerate(bad['cases']) if c['label'].endswith(':params_omitted'))
            request = json.loads(bad['cases'][index]['request_utf8']); request['params'] = None
            bad['cases'][index]['request_utf8'] = json.dumps(request)
            for key in ('request_before_json', 'request_before_clone_json', 'request_after_json', 'request_after_clone_json'):
                bad['api']['rows'][index][key] = json.dumps(request)
            rewire(bad, requests=True)
        elif name in ('wrong_scalar_kind', 'prechanged_api_input'):
            index = next(i for i,c in enumerate(bad['cases']) if c['label'] == 'fsmgen_support_summary:limit_examples:numeric_string')
            request = json.loads(bad['cases'][index]['request_utf8'])
            request['params']['arguments']['limit_examples'] = 1
            if name == 'wrong_scalar_kind':
                bad['cases'][index]['request_utf8'] = json.dumps(request)
                for key in ('request_before_json', 'request_before_clone_json', 'request_after_json', 'request_after_clone_json'):
                    bad['api']['rows'][index][key] = json.dumps(request)
                rewire(bad, requests=True)
            else:
                bad['api']['rows'][index]['request_before_clone_json'] = json.dumps(request)
        elif name == 'borrowed_api_reply':
            indexes = [i for i,c in enumerate(bad['cases']) if c['label'].endswith(':valid_base')]
            destination, source = indexes[0], indexes[-1]
            value = copy.deepcopy(bad['api']['rows'][source]['response'])
            value['id'] = json.loads(bad['cases'][destination]['request_utf8'])['id']
            bad['api']['rows'][destination]['response'] = value
        elif name == 'lost_wire_reply':
            bad['received_utf8'] = bad['received_utf8'].rsplit('\n', 2)[0] + '\n'
        elif name == 'concealed_text_control':
            bad['api']['text_inspection_controls'][0]['direct_after_clone_json'] = '{"value":0}'
        else:
            bad['api']['text_inspection_controls'][0]['detached_after_clone_json'] = '{"value":false}'
        try:
            verify(bad)
        except AssertionError as error:
            assert str(error) == expected, (name, str(error))
            rejected.append(name)
        else:
            raise AssertionError('Control accepted: ' + name)
    return rejected


def main():
    assert len(sys.argv) == 2
    record = json.loads(gzip.decompress(Path(sys.argv[1]).read_bytes()))
    result = verify(record)
    result['controls_rejected'] = controls(record)
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""Independently join complete saved error contexts, sources and wire frames."""
import copy
import gzip
import hashlib
import json
from pathlib import Path
import subprocess
import sys

from verify_source_identity import original_source

ROOT = Path(__file__).resolve().parents[3]
ADAPTER = 'perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm'
PROBE = 'docs/audits/mcp-api-reference-20261023/probe_error_context.pl'
COLLECTOR = 'docs/audits/mcp-api-reference-20261023/capture_error_context.py'
FIXTURE = 'fsm/ahb_lite_subordinate.fsm'
NAMES = ['missing_source', 'quoted_version', 'unknown_tool', 'unknown_method',
         'callback_plain', 'callback_authored_location', 'callback_authored_plus_native',
         'callback_fake_suffix', 'callback_quotes', 'callback_external_path',
         'callback_long_ascii', 'callback_long_unicode', 'ping']
EXPECTED = [
    'Invalid params: source_path or source_id is required',
    'Invalid params: VIAL language_version must be a JSON integer',
    'Unsupported MCP tool: fsmgen_no_such_tool',
    'Unsupported JSON-RPC method: widgets/missing',
    "Callback rejected operator '/'",
    'Authored diagnostic at design.isf line 17.',
    'Authored diagnostic at design.isf line 17.',
    "Reason at design.isf line 17, <pretend> line 9; operator '/' rejected",
    "Unsupported expression operator '/' at 'design.isf:17'",
    "Operator '/' while opening '[absolute-path-redacted]'",
    'x' * (2048 - len(' [truncated]')) + ' [truncated]',
    'é' * (2048 - len(' [truncated]')) + ' [truncated]', None]
MESSAGES = [None] * 4 + [EXPECTED[4], EXPECTED[5] + '\n', EXPECTED[6], EXPECTED[7],
    EXPECTED[8] + '\n', "Operator '/' while opening '/outside/private dir/source.fsm'\n",
    'x' * 2200, 'é' * 2200, None]
CODES = [-32602, -32602, -32000, -32601] + [-32000] * 8 + [None]
CUSTOM = ['callback_plain', 'callback_authored_location', 'callback_fake_suffix',
          'callback_quotes', 'callback_external_path', 'callback_long_unicode']


def canonical(value):
    return json.dumps(value, sort_keys=True, ensure_ascii=True, separators=(',', ':'))


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def source(record, path):
    if path in record['observer_sources']:
        raw = record['observer_sources'][path].encode()
    elif path in record['native_source_overrides']:
        raw = record['native_source_overrides'][path].encode()
    else:
        raw = original_source(path, record['source_sha256'][path], record['head'])
    assert sha(raw) == record['source_sha256'][path], 'source identity mismatch'
    return raw


def expected_request(name, identity):
    index = NAMES.index(name)
    methods = ['tools/call', 'tools/call', 'tools/call', 'widgets/missing']
    params = [{'name': 'fsmgen_check', 'arguments': {}},
              {'name': 'fsmgen_vial_inspect', 'arguments': {'source_id': 'vial/missing.vial', 'language_version': '2'}},
              {'name': 'fsmgen_no_such_tool', 'arguments': {}}, {}]
    method = methods[index] if index < 4 else ('ping' if name == 'ping' else 'tools/call')
    arguments = params[index] if index < 4 else ({} if name == 'ping' else {
        'name': 'fsmgen_check', 'arguments': {'source_id': FIXTURE}})
    return {'jsonrpc': '2.0', 'id': identity, 'method': method, 'params': arguments}


def response_check(name, request, response, findings, label):
    assert response['jsonrpc'] == '2.0' and type(response['id']) is type(request['id'])
    assert response['id'] == request['id'], 'response identity mismatch'
    if name == 'ping':
        assert set(response) == {'jsonrpc', 'id', 'result'} and response['result'] == {}, 'ping changed'
        return
    assert set(response) == {'jsonrpc', 'id', 'error'}
    error = response['error']
    assert set(error) == {'code', 'message'}, 'raw error data exposed'
    i = NAMES.index(name)
    assert type(error['code']) is int and error['code'] == CODES[i], 'error class changed'
    message = error['message']
    assert isinstance(message, str) and len(message) <= 2048, 'message character bound failed'
    if message != EXPECTED[i]:
        findings.append({'label': label, 'case': name, 'expected': EXPECTED[i], 'actual': message})


def native_check(case, events, root, context):
    i = NAMES.index(case)
    assert len(events) == (0 if case == 'ping' else 1), 'native event population changed'
    if not events:
        return
    event = events[0]
    path = PROBE if case.startswith('callback_') else ADAPTER
    assert event['origin_file_label'] == root + '/' + path, 'native throw source changed'
    assert type(event['origin_line']) is int and event['origin_line'] > 0
    reason = MESSAGES[i]
    if reason is None:
        reason = EXPECTED[i].replace('Invalid params: ', 'FSMGEN_JSONRPC_INVALID_PARAMS: ')
        if case == 'unknown_method':
            reason = 'FSMGEN_JSONRPC_METHOD_NOT_FOUND: widgets/missing'
    suffix = ' at %s line %d' % (event['origin_file_label'], event['origin_line'])
    if context != 'no_input_record':
        handle = '$custom_input' if context == 'custom_stdio' else '$record_input'
        unit = 'chunk' if context == 'chunk_record' else 'line'
        suffix += ', <%s> %s 1' % (handle, unit)
        assert event['input_record'] == 1
    expected = reason if reason.endswith('\n') else reason + suffix + '.\n'
    assert event['exception'] == expected, 'native suffix grammar mismatch'


def frames(sent, received, requests, responses):
    assert sent.endswith('\n') and received.endswith('\n')
    assert canonical([json.loads(s) for s in sent.splitlines()]) == canonical(requests), 'sent frame mismatch'
    assert canonical([json.loads(s) for s in received.splitlines()]) == canonical(responses), 'received frame mismatch'


def verify(record):
    native = {p for p in subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', record['head'],
               'perl']).decode().splitlines() if p.endswith('.pm')}
    copies = native | {'README.md', 'bin/fsmgen', 'bin/fsmgen-mcp', FIXTURE, PROBE}
    selected = copies | {COLLECTOR, 'scripts/generate_pod_reference.py', 't/python/test_fixture_mcp_stdio.py'}
    assert set(record['source_sha256']) == selected, 'selected source population mismatch'
    assert set(record['relocation']['files']) == copies, 'relocation population mismatch'
    assert set(record['observer_sources']) == selected - native
    assert set(record['native_source_overrides']) <= native
    for path in selected:
        raw = source(record, path)
        if path in copies:
            assert record['relocation']['files'][path] == {'sha256': sha(raw), 'bytes': len(raw)}
    assert [r['root_kind'] for r in record['runs']] == ['original', 'spaced']
    findings, checked = [], 0
    for run in record['runs']:
        root, api = run['implementation_root_label'], run['api']
        assert canonical(json.loads(run['api_capture']['stdout_utf8'])) == canonical(api), 'API raw/decoded mismatch'
        assert run['api_capture']['exit_status'] == 0 and run['api_capture']['stderr_utf8'] == ''
        assert api['adapter_file_label'] == root + '/' + ADAPTER
        assert root + '/' + PROBE in api['native_file_labels']
        assert [c['name'] for c in api['cases']] == NAMES
        assert [g['context'] for g in api['groups']] == ['no_input_record', 'line_record', 'chunk_record']
        for group in api['groups']:
            assert [r['case'] for r in group['rows']] == NAMES, 'API case population mismatch'
            for row in group['rows']:
                name, context = row['case'], group['context']
                request = expected_request(name, context + ':' + name)
                for key in ('request_before_json', 'request_before_clone_json', 'request_after_json', 'request_after_clone_json'):
                    assert canonical(json.loads(row[key])) == canonical(request), 'caller preservation failed'
                native_check(name, row['native_events'], root, context)
                response_check(name, request, row['response'], findings, run['root_kind'] + ':' + context)
                checked += 1
        assert len(run['one_shot']) == 4
        for i, row in enumerate(run['one_shot']):
            assert row['request'] == expected_request(NAMES[i], i)
            assert row['capture']['exit_status'] == 0 and row['capture']['stderr_utf8'] == ''
            assert canonical(json.loads(row['capture']['stdout_utf8'])) == canonical(row['response'])
            response_check(NAMES[i], row['request'], row['response'], findings, run['root_kind'] + ':one_shot')
            checked += 1
        wire = run['persistent']
        assert wire['exit_status'] == 0 and wire['orderly_eof'] is True
        assert wire['requests'] == [expected_request(n, i) for i, n in enumerate(NAMES[:4] + ['ping'])]
        frames(wire['sent_utf8'], wire['received_utf8'], wire['requests'], wire['responses'])
        assert len(wire['responses']) == 5
        for name, request, response in zip(NAMES[:4] + ['ping'], wire['requests'], wire['responses']):
            response_check(name, request, response, findings, run['root_kind'] + ':persistent')
            checked += 1
        assert [r['case'] for r in run['custom_stdio']] == CUSTOM
        for row in run['custom_stdio']:
            assert row['requests'] == [expected_request(row['case'], 1), expected_request('ping', 2)]
            assert row['capture']['exit_status'] == 0
            frames(row['sent_utf8'], row['capture']['stdout_utf8'], row['requests'], row['responses'])
            assert len(row['responses']) == 2
            assert json.loads(row['capture']['stderr_utf8']) == {'probe_native_events': row['native_events']}
            native_check(row['case'], row['native_events'], root, 'custom_stdio')
            for name, request, response in zip([row['case'], 'ping'], row['requests'], row['responses']):
                response_check(name, request, response, findings, run['root_kind'] + ':custom_stdio')
                checked += 1
    return {'selected_sources': len(selected), 'copied_files': len(copies),
            'checked_responses': checked, 'findings': findings}


def controls(record):
    rejected = []
    for name, expected in [('missing_case', 'API case population mismatch'),
                           ('wrong_native_origin', 'native throw source changed'),
                           ('borrowed_wire', 'received frame mismatch'),
                           ('caller_mutation', 'caller preservation failed'),
                           ('raw_data', 'raw error data exposed'),
                           ('source', 'source identity mismatch')]:
        bad = copy.deepcopy(record)
        run = bad['runs'][0]
        row = run['api']['groups'][0]['rows'][0]
        if name == 'missing_case':
            run['api']['groups'][0]['rows'].pop()
        elif name == 'wrong_native_origin':
            row['native_events'][0]['origin_file_label'] += '.other'
        elif name == 'borrowed_wire':
            run['persistent']['received_utf8'] = run['persistent']['received_utf8'].replace('required', 'different')
        elif name == 'caller_mutation':
            row['request_after_clone_json'] = '{}'
        elif name == 'raw_data':
            row['response']['error']['data'] = 'private'
        else:
            bad['observer_sources'][PROBE] += '\n'
        if name not in ('borrowed_wire', 'source'):
            run['api_capture']['stdout_utf8'] = json.dumps(run['api'])
        try:
            verify(bad)
        except AssertionError as error:
            assert str(error) == expected, (name, str(error))
            rejected.append(name)
        else:
            raise AssertionError('Control accepted: ' + name)
    return rejected


if __name__ == '__main__':
    assert len(sys.argv) == 2
    record = json.loads(gzip.decompress(Path(sys.argv[1]).read_bytes()))
    result = verify(record)
    result['reader_controls'] = controls(record)
    print(json.dumps(result, ensure_ascii=False, indent=2))

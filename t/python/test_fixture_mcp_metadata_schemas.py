"""Join MCP metadata descriptors to actual persistent query results."""
import gzip
import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import unittest

from test_fixture_mcp_stdio import ROOT, Session

_spec = importlib.util.spec_from_file_location(
    'mcp_metadata_schema_reader', ROOT / 'docs/audits/mcp-api-reference-20261023/verify_inventory.py')
_reader = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_reader)

CODE = 'FSMGEN_COMPOSITION_CHILD_ITEM_LIST_SHAPE'
FIELDS = ('id', 'relpath', 'family', 'classification', 'coverage', 'source_kind',
          'strict_supported', 'diagnostic_code')
LIMITS = ((None, 10), (0, 10), (1, 1), (2, 2), (100, 100), (101, 100), (-1, 10))


def capture_diagnostic(server):
    exchanges = []

    def call(method, params=None):
        request = {'jsonrpc': '2.0', 'id': len(exchanges), 'method': method}
        if params is not None:
            request['params'] = params
        server.send(request)
        response = server.receive()
        assert response['id'] == request['id']
        exchanges.append({'request': request, 'response': response})
        return response['result']

    call('initialize', {'protocolVersion': '2025-06-18', 'capabilities': {},
                        'clientInfo': {'name': 'metadata-schema-regression', 'version': '1'}})
    server.send({'jsonrpc': '2.0', 'method': 'notifications/initialized'})
    call('tools/list')
    call('resources/read', {'uri': 'fsmgen://capabilities'})
    for limit, _ in LIMITS:
        arguments = {'code': CODE}
        if limit is not None:
            arguments['limit_examples'] = limit
        call('tools/call', {'name': 'fsmgen_explain_diagnostic', 'arguments': arguments})
    call('tools/call', {'name': 'fsmgen_support_summary', 'arguments': {'limit_examples': 0}})
    return exchanges


class MCPMetadataSchemaTest(unittest.TestCase):
    def test_diagnostic_limit_discovery_and_real_catalog_values(self):
        with Session(['perl', 'bin/fsmgen-mcp', '--workspace-root', '.']) as server:
            exchanges = capture_diagnostic(server)
            tools = {t['name']: t for t in exchanges[1]['response']['result']['tools']}
            schema = tools['fsmgen_explain_diagnostic']['inputSchema']
            _reader.check_schema(schema)
            manifest = json.loads(exchanges[2]['response']['result']['contents'][0]['text'])
            diagnostic = next(d for d in manifest['diagnostics']['stable_codes'] if d['code'] == CODE)
            matches = [e for e in manifest['support_accounting']['catalog_entries']
                       if e.get('diagnostic_code') == CODE]
            self.assertTrue(matches, 'actual catalog must exercise diagnostic samples')
            for exchange, (limit, maximum) in zip(exchanges[3:-1], LIMITS):
                with self.subTest(limit=limit):
                    self.assertEqual(_reader.errors(exchange['request']['params']['arguments'], schema), [])
                    wanted = {'code': CODE, 'diagnostic': diagnostic,
                              'registry_contract': manifest['diagnostics']['stable_code_registry'],
                              'support_examples': [{key: e[key] for key in FIELDS} for e in matches[:maximum]]}
                    result = exchange['response']['result']
                    self.assertIs(result['isError'], False)
                    self.assertEqual(_reader.encoded(result['structuredContent']), _reader.encoded(wanted))
                    self.assertEqual(_reader.encoded(json.loads(result['content'][0]['text'])), _reader.encoded(wanted))
                    for entry in result['structuredContent']['support_examples']:
                        self.assertIs(type(entry['strict_supported']), bool)
            self.assertEqual(exchanges[-1]['response']['result']['structuredContent']['sample_catalog_entries'], [])
            for invalid in (True, '1', [], {}, None):
                self.assertTrue(_reader.errors({'code': CODE, 'limit_examples': invalid}, schema))


def save_capture(argument):
    sys.path.insert(0, str(ROOT / 'scripts'))
    from generate_pod_reference import local_path
    output = local_path(ROOT, argument)
    assert output.suffix == '.gz' and not output.exists()
    paths = [p for p in subprocess.check_output(['git', 'ls-files', '-z', 'perl/FSM']).decode().split('\0')
             if p.endswith('.pm')]
    paths += ['bin/fsmgen-mcp', 't/python/test_fixture_mcp_stdio.py',
              't/python/test_fixture_mcp_metadata_schemas.py']
    record = {'head': subprocess.check_output(['git', 'rev-parse', 'HEAD']).decode().strip(),
              'source_sha256': {p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in paths}}
    with Session(['perl', 'bin/fsmgen-mcp', '--workspace-root', '.']) as server:
        record['exchanges'] = capture_diagnostic(server)
        record['sent_utf8'] = server.sent.decode('utf-8')
        record['received_utf8'] = server.received.decode('utf-8')
    record['exit_status'] = server.process.returncode
    record['orderly_eof'] = True
    with gzip.GzipFile(filename=str(output), mode='wb', mtime=0) as out:
        out.write((json.dumps(record, indent=2, ensure_ascii=False) + '\n').encode())
    print('Saved complete live diagnostic queries: ' + output.relative_to(ROOT).as_posix())


if __name__ == '__main__':
    if len(sys.argv) == 3 and sys.argv[1] == '--capture-diagnostic':
        save_capture(sys.argv[2])
    else:
        unittest.main()

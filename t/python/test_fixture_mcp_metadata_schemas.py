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


class MetadataClient:
    def __init__(self, server):
        self.server = server
        self.exchanges = []
        self.call('initialize', {'protocolVersion': '2025-06-18', 'capabilities': {},
                                'clientInfo': {'name': 'metadata-schema-regression', 'version': '1'}})
        server.send({'jsonrpc': '2.0', 'method': 'notifications/initialized'})

    def call(self, method, params=None):
        request = {'jsonrpc': '2.0', 'id': len(self.exchanges), 'method': method}
        if params is not None:
            request['params'] = params
        self.server.send(request)
        response = self.server.receive()
        assert response['id'] == request['id']
        self.exchanges.append({'request': request, 'response': response})
        return response['result']


def capture_diagnostic(server):
    client = MetadataClient(server)
    client.call('tools/list')
    client.call('resources/read', {'uri': 'fsmgen://capabilities'})
    for limit, _ in LIMITS:
        arguments = {'code': CODE}
        if limit is not None:
            arguments['limit_examples'] = limit
        client.call('tools/call', {'name': 'fsmgen_explain_diagnostic', 'arguments': arguments})
    client.call('tools/call', {'name': 'fsmgen_support_summary', 'arguments': {'limit_examples': 0}})
    return client.exchanges


def capture_capability(server):
    client = MetadataClient(server)
    client.call('tools/list')
    result = client.call('resources/read', {'uri': 'fsmgen://capabilities'})
    manifest = json.loads(result['contents'][0]['text'])
    for uri in ('fsmgen://examples', 'fsmgen://vial/1/capabilities', 'fsmgen://vial/2/capabilities'):
        client.call('resources/read', {'uri': uri})
    aliases = {'all', 'contracts', 'examples', 'vial_tooling_v1', 'vial_tooling_v2', 'vial_inspection'}
    for section in sorted(set(manifest) | aliases):
        client.call('tools/call', {'name': 'fsmgen_capability_query', 'arguments': {'section': section}})
    return client.exchanges


class MCPMetadataSchemaTest(unittest.TestCase):
    def test_capability_sections_match_output_schema_and_public_values(self):
        with Session(['perl', 'bin/fsmgen-mcp', '--workspace-root', '.']) as server:
            exchanges = capture_capability(server)
            tools = {t['name']: t for t in exchanges[1]['response']['result']['tools']}
            schema = tools['fsmgen_capability_query']['outputSchema']
            _reader.check_schema(schema)
            manifest = json.loads(exchanges[2]['response']['result']['contents'][0]['text'])
            resources = {e['request']['params']['uri']: json.loads(e['response']['result']['contents'][0]['text'])
                         for e in exchanges if e['request']['method'] == 'resources/read'}
            seen = set()
            for exchange in exchanges:
                if exchange['request']['method'] != 'tools/call':
                    continue
                section = exchange['request']['params']['arguments']['section']
                seen.add(section)
                with self.subTest(section=section):
                    result = exchange['response']['result']
                    payload = result['structuredContent']
                    self.assertIs(result['isError'], False)
                    self.assertEqual(_reader.errors(payload, schema), [])
                    self.assertEqual(_reader.encoded(json.loads(result['content'][0]['text'])), _reader.encoded(payload))
                    if section == 'all':
                        wanted = manifest
                    elif section == 'contracts':
                        wanted = {key: manifest[key] for key in ('manifest_contract', 'semantic_introspection')}
                    elif section == 'examples':
                        wanted = resources['fsmgen://examples']
                    elif section.startswith('vial_tooling_v'):
                        wanted = {'section': section, 'payload': resources['fsmgen://vial/' + section[-1] + '/capabilities']}
                    elif section == 'vial_inspection':
                        self.assertIs(type(payload['payload']), dict)
                        continue  # Exact public API/transport parity is also covered by T1882.
                    else:
                        wanted = {'section': section, 'payload': manifest[section]}
                    self.assertEqual(_reader.encoded(payload), _reader.encoded(wanted))
            self.assertTrue(set(manifest) <= seen)
            self.assertEqual(_reader.errors({'section': 'manifest_schema_version', 'payload': 1.0}, schema), [])
            for invalid in (True, '1', [], None):
                self.assertTrue(_reader.errors({'section': 'manifest_schema_version', 'payload': invalid}, schema))

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


def save_capture(argument, capture):
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
        record['exchanges'] = capture(server)
        record['sent_utf8'] = server.sent.decode('utf-8')
        record['received_utf8'] = server.received.decode('utf-8')
    record['exit_status'] = server.process.returncode
    record['orderly_eof'] = True
    with gzip.GzipFile(filename=str(output), mode='wb', mtime=0) as out:
        out.write((json.dumps(record, indent=2, ensure_ascii=False) + '\n').encode())
    print('Saved complete live metadata queries: ' + output.relative_to(ROOT).as_posix())


if __name__ == '__main__':
    if len(sys.argv) == 3 and sys.argv[1] == '--capture-diagnostic':
        save_capture(sys.argv[2], capture_diagnostic)
    elif len(sys.argv) == 3 and sys.argv[1] == '--capture-capability':
        save_capture(sys.argv[2], capture_capability)
    else:
        unittest.main()

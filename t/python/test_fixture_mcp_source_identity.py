"""Compare published source-selector constraints with a real persistent server."""
import copy
import importlib.util
import json
import sys
import unittest
from urllib.parse import quote

from test_fixture_mcp_stdio import ROOT, Session
from test_fixture_mcp_metadata_schemas import MetadataClient, save_capture

# Reuse the qualified, deliberately bounded audit reader instead of maintaining
# a second schema evaluator. It rejects keywords outside its supported vocabulary.
_spec = importlib.util.spec_from_file_location(
    'mcp_census_reader', ROOT / 'docs/audits/mcp-api-reference-20261023/verify_inventory.py')
_reader = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_reader)

SOURCE = 'ppif/axi_aw_valid_ready.ppif'
TOOLS = {'fsmgen_check': 'check', 'fsmgen_semantic_introspect': 'semantic',
         'fsmgen_schedule_preview': 'schedule'}


def exchange(server, method, params=None):
    request = {'jsonrpc': '2.0', 'id': len(server.sent), 'method': method}
    if params is not None:
        request['params'] = params
    server.send(request)
    # Source compilation is synchronous and can exceed the transport-only
    # helper's short ping deadline. Keep a bounded source-query deadline.
    response = server.receive(timeout=120)
    assert response['id'] == request['id'] and response['jsonrpc'] == '2.0'
    return response


def arguments_cases():
    valid = [{'source_id': SOURCE}, {'source_path': SOURCE},
             {'source_path': SOURCE, 'source_id': 'missing-ignored-identity.ppif'},
             {'source_path': str(ROOT / SOURCE)}]
    invalid = [{}]
    for key, other in [('source_id', 'source_path'), ('source_path', 'source_id')]:
        for value in ['', None, [], {}, True, False, 0, 1, 1.5]:
            invalid.extend([{key: value}, {key: value, other: SOURCE}])
    return valid, invalid


def capture(server):
    """Retain full requests/results for before/after evidence, without projection."""
    discovery = exchange(server, 'tools/list')
    records = []
    valid, invalid = arguments_cases()
    for name in TOOLS:
        for accepted, population in [(True, valid), (False, invalid)]:
            for arguments in population:
                response = exchange(server, 'tools/call', {'name': name, 'arguments': arguments})
                records.append({'name': name, 'arguments': arguments,
                                'expected_valid': accepted, 'response': response})
    return {'discovery': discovery, 'calls': records}


def capture_version_resources(server):
    client = MetadataClient(server)
    client.call('tools/list')
    for version, source in ((1, 'vial/ahb_subordinate_base_output_arbitration.vial'),
                            (2, 'vial/ahb_subordinate_base_output_arbitration_lifecycle_v2.vial')):
        client.call('resources/read', {'uri': 'fsmgen://vial/%s/capabilities' % version})
        for kind, tool in (('check', 'fsmgen_check'), ('semantic', 'fsmgen_semantic_introspect'),
                           ('inspection', 'fsmgen_vial_inspect')):
            client.call('tools/call', {'name': tool, 'arguments': {'source_id': source, 'language_version': version}})
            client.call('resources/read', {'uri': 'fsmgen://vial/%s/source/%s/%s' % (version, quote(source, safe=''), kind)})
            if version == 1 and kind != 'inspection':
                client.call('resources/read', {'uri': 'fsmgen://source/%s/%s' % (quote(source, safe=''), kind)})
    return client.exchanges


class MCPSourceIdentityTest(unittest.TestCase):
    def test_versioned_resources_preserve_complete_tool_values(self):
        with Session(['perl', 'bin/fsmgen-mcp', '--workspace-root', '.']) as server:
            exchanges = capture_version_resources(server)
        previous = None
        resources = []
        for exchange in exchanges[2:]:
            request, result = exchange['request'], exchange['response']['result']
            if request['method'] == 'tools/call':
                self.assertIs(result['isError'], False)
                previous = result['structuredContent']
                self.assertEqual(_reader.encoded(json.loads(result['content'][0]['text'])), _reader.encoded(previous))
            else:
                uri = request['params']['uri']
                resources.append(uri)
                if not uri.endswith('/capabilities'):
                    self.assertEqual(_reader.encoded(json.loads(result['contents'][0]['text'])), _reader.encoded(previous))
        self.assertEqual(len(resources), 10)

    def test_source_selectors_join_discovery_to_actual_requests(self):
        with Session(['perl', 'bin/fsmgen-mcp', '--workspace-root', '.']) as server:
            record = capture(server)
            tools = {tool['name']: tool for tool in record['discovery']['result']['tools']}
            baseline = {}
            for call in record['calls']:
                name, arguments, response = call['name'], call['arguments'], call['response']
                with self.subTest(tool=name, arguments=arguments):
                    schema = tools[name]['inputSchema']
                    _reader.check_schema(schema)
                    self.assertEqual(not _reader.errors(arguments, schema), call['expected_valid'],
                                     'discovery must describe the existing selector requirement')
                    if call['expected_valid']:
                        result = response['result']
                        self.assertIs(result['isError'], False)
                        payload = result['structuredContent']
                        self.assertEqual(_reader.encoded(json.loads(result['content'][0]['text'])),
                                         _reader.encoded(payload))
                        self.assertEqual(payload['source_id'], SOURCE)
                        self.assertEqual(payload['source_path'], SOURCE)
                        self.assertEqual(payload['query_kind'], TOOLS[name])
                        self.assertEqual(_reader.encoded(payload), baseline.setdefault(
                            name, _reader.encoded(payload)), 'aliases preserve the entire result')
                    else:
                        self.assertEqual(response['error']['code'], -32602)
                        expected = ('source_path or source_id is required' if not arguments
                                    else 'source identity must be a nonempty string')
                        self.assertIn(expected, response['error']['message'])
            for name in TOOLS:
                schema = tools[name]['inputSchema']
                # These controls break real requirements, rather than changing
                # an irrelevant description or accepting our own expected fixture.
                without_identity = copy.deepcopy(schema)
                del without_identity['anyOf']
                self.assertEqual(_reader.errors({}, without_identity), [])
                for key in ('source_id', 'source_path'):
                    without_length = copy.deepcopy(schema)
                    del without_length['properties'][key]['minLength']
                    self.assertEqual(_reader.errors({key: ''}, without_length), [])
                self.assertTrue(_reader.errors({'source_id': SOURCE, 'extra': True}, schema))

    def test_vial_selectors_keep_version_applicability(self):
        source = 'vial/ahb_subordinate_base_output_arbitration_lifecycle_v2.vial'
        with Session(['perl', 'bin/fsmgen-mcp', '--workspace-root', '.']) as server:
            tools = {tool['name']: tool for tool in exchange(server, 'tools/list')['result']['tools']}
            for name in ('fsmgen_check', 'fsmgen_semantic_introspect'):
                arguments = {'source_id': source, 'language_version': 2}
                self.assertEqual(_reader.errors(arguments, tools[name]['inputSchema']), [])
                result = exchange(server, 'tools/call', {'name': name, 'arguments': arguments})['result']
                self.assertIs(result['isError'], False)
                self.assertEqual(result['structuredContent']['source_id'], source)
                self.assertEqual(result['structuredContent']['adapter_provenance']['language_version'], 2)
                refused = exchange(server, 'tools/call', {
                    'name': name, 'arguments': {'source_id': SOURCE, 'language_version': 2}})
                self.assertEqual(refused['error']['code'], -32602)
                self.assertIn('language_version applies only to VIAL', refused['error']['message'])
            for name in ('fsmgen_check', 'fsmgen_semantic_introspect', 'fsmgen_vial_inspect'):
                for version in ('1', '2', True, False, None, 1.5):
                    with self.subTest(tool=name, version=version):
                        refused = exchange(server, 'tools/call', {
                            'name': name, 'arguments': {'source_id': source, 'language_version': version}})
                        self.assertEqual(refused['error']['code'], -32602)
                result = exchange(server, 'tools/call', {
                    'name': name, 'arguments': {'source_id': source, 'language_version': 2.0}})['result']
                self.assertIs(result['isError'], False)
            schedule = tools['fsmgen_schedule_preview']['inputSchema']
            self.assertTrue(_reader.errors({'source_id': SOURCE, 'language_version': 2}, schedule))
            refused = exchange(server, 'tools/call', {
                'name': 'fsmgen_schedule_preview', 'arguments': {'source_id': source}})
            self.assertEqual(refused['error']['code'], -32602)
            self.assertIn('VIAL supports check and semantic queries only', refused['error']['message'])


if __name__ == '__main__':
    if len(sys.argv) == 3 and sys.argv[1] == '--capture-resources':
        save_capture(sys.argv[2], capture_version_resources,
                     extra_paths=('t/python/test_fixture_mcp_source_identity.py',))
    else:
        unittest.main()

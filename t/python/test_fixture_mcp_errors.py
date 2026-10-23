"""Check exact public error messages over stock and custom stdio, including spaces."""
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

from test_fixture_mcp_stdio import ROOT, Session

PROBE = 'docs/audits/mcp-api-reference-20261023/probe_error_context.pl'


class MCPErrorTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        temporary = ROOT / '.artifacts/tmp'
        temporary.mkdir(parents=True, exist_ok=True)
        cls.work = Path(tempfile.mkdtemp(prefix='mcp-error-regression-', dir=temporary))
        cls.moved = cls.work / 'MCP at shelf line 7 [copy]'
        paths = list((ROOT / 'perl').rglob('*.pm')) + [ROOT / p for p in (
            'README.md', 'bin/fsmgen', 'bin/fsmgen-mcp', 'fsm/ahb_lite_subordinate.fsm', PROBE)]
        for origin in paths:
            destination = cls.moved / origin.relative_to(ROOT)
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(origin, destination)
            assert destination.read_bytes() == origin.read_bytes()

    @classmethod
    def tearDownClass(cls):
        # Only this class's exact disposable copy, never other captures.
        shutil.rmtree(cls.work)

    def test_stock_refusals_are_exact_before_eof_at_both_roots(self):
        cases = [
            ('tools/call', {'name': 'fsmgen_check', 'arguments': {}}, -32602,
             'Invalid params: source_path or source_id is required'),
            ('tools/call', {'name': 'fsmgen_no_such_tool', 'arguments': {}}, -32000,
             'Unsupported MCP tool: fsmgen_no_such_tool'),
            ('widgets/missing', {}, -32601, 'Unsupported JSON-RPC method: widgets/missing'),
        ]
        for root in (ROOT, self.moved):
            with self.subTest(root=root.relative_to(ROOT).as_posix()):
                command = ['perl', str(root / 'bin/fsmgen-mcp'), '--repo-root', str(root),
                           '--workspace-root', str(root)]
                with Session(command) as server:
                    for i, (method, params, code, message) in enumerate(cases):
                        request = {'jsonrpc': '2.0', 'id': i, 'method': method, 'params': params}
                        server.send(request)
                        expected = {'jsonrpc': '2.0', 'id': i, 'error': {'code': code, 'message': message}}
                        self.assertEqual(server.receive(), expected)
                        one_shot = subprocess.run(command + ['--request-json', json.dumps(request)],
                                                  cwd=ROOT, capture_output=True, timeout=30)
                        self.assertEqual(one_shot.returncode, 0)
                        self.assertEqual(one_shot.stderr, b'')
                        self.assertEqual(json.loads(one_shot.stdout), expected)
                    server.send({'jsonrpc': '2.0', 'id': 'after-errors', 'method': 'ping'})
                    self.assertEqual(server.receive(), {'jsonrpc': '2.0', 'id': 'after-errors', 'result': {}})
                    self.assertIsNone(server.process.poll())

    def test_custom_input_preserves_authored_and_fake_locations(self):
        cases = [
            ('callback_plain', "Callback rejected operator '/'"),
            ('callback_authored_location', 'Authored diagnostic at design.isf line 17.'),
            ('callback_fake_suffix', "Reason at design.isf line 17, <pretend> line 9; operator '/' rejected"),
            ('callback_quotes', "Unsupported expression operator '/' at 'design.isf:17'"),
        ]
        for root in (ROOT, self.moved):
            for name, expected in cases:
                with self.subTest(root=root.relative_to(ROOT).as_posix(), case=name):
                    command = ['perl', '-I' + str(root / 'perl'), str(root / PROBE),
                               '--root', str(root), '--mode', 'stdio', '--case', name]
                    requests = [{'jsonrpc': '2.0', 'id': 1, 'method': 'tools/call', 'params': {
                        'name': 'fsmgen_check', 'arguments': {'source_id': 'fsm/ahb_lite_subordinate.fsm'}}},
                        {'jsonrpc': '2.0', 'id': 2, 'method': 'ping'}]
                    result = subprocess.run(command, cwd=ROOT, input=''.join(json.dumps(r) + '\n' for r in requests).encode(),
                                            capture_output=True, timeout=30)
                    self.assertEqual(result.returncode, 0)
                    self.assertEqual([json.loads(line) for line in result.stdout.splitlines()], [
                        {'jsonrpc': '2.0', 'id': 1, 'error': {'code': -32000, 'message': expected}},
                        {'jsonrpc': '2.0', 'id': 2, 'result': {}}])
                    # Instrumentation only: this fixture reports throw origins on stderr.
                    self.assertEqual(set(json.loads(result.stderr)), {'probe_native_events'})


if __name__ == '__main__':
    unittest.main()

"""Exercise live request/response delivery before a real MCP pipe reaches EOF."""
import json
import os
from pathlib import Path
import select
import shutil
import subprocess
import tempfile
import time
import unittest

ROOT = Path(__file__).resolve().parents[2]


class Session:
    def __init__(self, arguments):
        temporary = ROOT / '.artifacts/tmp'
        temporary.mkdir(parents=True, exist_ok=True)
        self.work = Path(tempfile.mkdtemp(prefix='mcp-live-stdio-', dir=temporary))
        self.arguments = arguments
        self.sent = bytearray()
        self.received = bytearray()
        self.pending = bytearray()
        self.process = subprocess.Popen(arguments, cwd=ROOT, stdin=subprocess.PIPE,
                                        stdout=subprocess.PIPE, stderr=subprocess.PIPE, bufsize=0)

    def __enter__(self):
        return self

    def send(self, value):
        raw = (json.dumps(value, ensure_ascii=False) + '\n').encode('utf-8')
        self.sent.extend(raw)
        self.process.stdin.write(raw)
        self.process.stdin.flush()

    def receive(self, timeout=10):
        deadline = time.monotonic() + timeout
        while b'\n' not in self.pending:
            remaining = deadline - time.monotonic()
            if remaining <= 0 or not select.select([self.process.stdout], [], [], remaining)[0]:
                raise AssertionError('MCP response was not delivered while stdin remained open')
            raw = os.read(self.process.stdout.fileno(), 65536)
            if not raw:
                raise AssertionError('MCP stdout reached EOF while stdin remained open')
            self.received.extend(raw)
            self.pending.extend(raw)
        line, _, self.pending = self.pending.partition(b'\n')
        return json.loads(line)

    def __exit__(self, error_type, error, traceback):
        self.process.stdin.close()
        self.process.stdin = None
        try:
            tail, errors = self.process.communicate(timeout=10)
        except subprocess.TimeoutExpired:
            self.process.kill()
            tail, errors = self.process.communicate()
            if error_type is None:
                error = AssertionError('MCP did not stop after input EOF')
        (self.work / 'stdin.jsonl').write_bytes(self.sent)
        (self.work / 'before-eof.jsonl').write_bytes(self.received)
        (self.work / 'after-eof.jsonl').write_bytes(tail)
        (self.work / 'stderr').write_bytes(errors)
        (self.work / 'process.json').write_text(json.dumps(
            {'arguments': self.arguments, 'exit_status': self.process.returncode}, indent=2) + '\n')
        if error_type is None and error is None:
            if self.process.returncode != 0 or errors or tail or self.pending:
                error = AssertionError('Unexpected exit, stderr or undelivered response after EOF')
        if error_type is not None or error is not None:
            print('MCP live-stdio evidence retained: ' + self.work.relative_to(ROOT).as_posix())
            if error_type is None:
                raise error
        else:
            shutil.rmtree(self.work)  # Only this exact successful fixture.


class MCPStdioTest(unittest.TestCase):
    def test_launcher_delivers_responses_before_eof_across_requests(self):
        with Session(['perl', 'bin/fsmgen-mcp', '--workspace-root', '.']) as server:
            server.send({'jsonrpc': '2.0', 'id': 'first-é', 'method': 'ping'})
            self.assertEqual(server.receive(), {'jsonrpc': '2.0', 'id': 'first-é', 'result': {}})
            server.send({'jsonrpc': '2.0', 'id': 2, 'method': 'initialize',
                         'params': {'protocolVersion': '2025-06-18', 'capabilities': {},
                                    'clientInfo': {'name': 'live-pipe-regression', 'version': '1'}}})
            initialized = server.receive()
            self.assertEqual(initialized['id'], 2)
            self.assertEqual(initialized['result']['protocolVersion'], '2025-06-18')
            server.send({'jsonrpc': '2.0', 'method': 'notifications/initialized'})
            server.send({'jsonrpc': '2.0', 'id': 3, 'method': 'unsupported-live-test'})
            refused = server.receive()
            self.assertEqual(refused['id'], 3)
            self.assertEqual(refused['error']['code'], -32601)
            server.send({'jsonrpc': '2.0', 'id': 4, 'method': 'ping'})
            self.assertEqual(server.receive(), {'jsonrpc': '2.0', 'id': 4, 'result': {}})
            self.assertIsNone(server.process.poll())

    def test_embedded_custom_output_handle_preserves_selected_handle_and_buffering(self):
        program = '''use FSM::Support::SemanticIntrospectionMCPAdapter;
open my $output, '>&', \\*STDOUT or die $!;
my $selected = select();
my $buffering = $|;
FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => '.', workspace_root => '.')
    ->run_stdio(in => \\*STDIN, out => $output);
die "Changed selected handle" unless select() eq $selected;
die "Changed selected handle buffering" unless $| == $buffering;
my $prior = select($output);
my $custom_buffering = $|;
select($prior);
die "Changed custom handle buffering" unless $custom_buffering == 0;
'''
        with Session(['perl', '-Iperl', '-e', program]) as server:
            for request_id in (0, 'second'):
                server.send({'jsonrpc': '2.0', 'id': request_id, 'method': 'ping'})
                self.assertEqual(server.receive(), {'jsonrpc': '2.0', 'id': request_id, 'result': {}})
            self.assertIsNone(server.process.poll())


if __name__ == '__main__':
    unittest.main()

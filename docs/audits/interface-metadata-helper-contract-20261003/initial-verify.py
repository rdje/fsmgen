"""Independent exact source and literal contract routing, without execution."""
import argparse
import copy
import hashlib
import json
import re
import subprocess
from pathlib import Path

BASE = Path(__file__).parent
parser = argparse.ArgumentParser()
parser.add_argument('--trust-label-calls', action='store_true')
parser.add_argument('--omit-copy', action='store_true')
args = parser.parse_args()
if (BASE / 'manifest.json').exists():
    manifest = json.loads((BASE / 'manifest.json').read_text())
    assert {p.name for p in BASE.iterdir()} == set(manifest) | {'manifest.json'}
    for name, row in manifest.items():
        raw = (BASE / name).read_bytes()
        assert len(raw) == row['bytes'] and hashlib.sha256(raw).hexdigest() == row['sha256'], name
data = json.loads((BASE / 'contracts.json').read_text())
for name, row in data['sources'].items():
    raw = subprocess.check_output(['git', 'show', data['revision'] + ':' + name])
    assert raw.decode() == row['body'] and len(raw) == row['bytes']
    assert hashlib.sha256(raw).hexdigest() == row['sha256'], name
source = data['sources']['t/1983-isf-interface-port-metadata.t']['body']
prior = json.loads(Path('docs/audits/aggregate-record-helper-plan-20261003/plan.json').read_text())
original = next(r for r in prior['rows'] if r['path'] == 't/1983-isf-interface-port-metadata.t')
assert original['source'] == source
expected = []
offset = 0
for line_number, line in enumerate(source.splitlines(keepends=True), 1):
    if 'rejects' in line:
        for match in re.finditer(r'\brejects\b', line):
            stripped = line.strip()
            role = 'definition' if stripped.startswith('sub rejects {') else (
                'snapshot_helper_call' if stripped.startswith('rejects(sub { snapshot_interface_port_metadata') else (
                'capture_helper_call' if stripped.startswith('for my $bad (@bad) { rejects(sub { capture_interface_port_metadata')
                else 'string_label'))
            expected.append({'line': line_number, 'offset': offset + match.start(), 'role': role, 'whole_line': line.rstrip('\n')})
    offset += len(line)
assert expected == data['tokens'] and len(expected) == 5
tokens = copy.deepcopy(data['tokens'])
if args.trust_label_calls:
    for row in tokens:
        if row['role'] == 'string_label': row['role'] = 'snapshot_helper_call'
assert [r['line'] for r in tokens if r['role'].endswith('_helper_call')] == [196, 219], 'label tokens cannot establish helper call sites'
start = source.index('sub rejects {'); end = source.index('sub write_file {', start)
assert data['helper'] == source[start:end]
helper = data['helper']
assert 'my $ok = eval { $operation->(); 1 };' in helper
assert 'like($@, qr/Invalid ISF interface port metadata:/' in helper
assert 'ok(!$ok, "$label fails closed")' in helper
assert 'is_deeply(\\@warnings, []' in helper
assert 'my $error = $@' not in helper
assert source.splitlines()[109].strip().startswith("like($line // '',qr/\\AInvalid ISF interface port metadata:")
assert source.splitlines()[127].strip().startswith('like($@, qr/record output field writes are not yet admitted/')
expected_copies = []
offset = 0
for number, line in enumerate(source.splitlines(keepends=True), 1):
    for match in re.finditer(r'\bdclone\(', line):
        expected_copies.append({'line': number, 'offset': offset + match.start(), 'whole_line': line.rstrip('\n')})
    offset += len(line)
copies = data['copies'][:-1] if args.omit_copy else data['copies']
assert copies == expected_copies and len(copies) == 8, 'complete original source copy-site membership'
provider = data['sources']['perl/FSM/Support/ISFInterfacePortMetadata.pm']['body']
assert 'confess "Invalid ISF interface port metadata: $_[1]\\n" unless $_[0]' in provider
assert '$interface = dclone($interface);' in provider and '$value = dclone($value);' in provider
assert 'width => 0 + $port->{width}' in provider
assert '$_ => 0 + $field->{$_}' in provider
assert 'sub _positive_integer' in provider and 'validation requires a predicate and message' in provider
frontend = data['sources']['perl/FSM/Pipeline/SourceFrontend.pm']['body']
assert 'my $raw_ast = Lispish::multi(\\$prepared_source_text);' in frontend
assert "open my $fh, '<', $fsm_file" in frontend
assert not re.search(r'\b(?:system|exec|fork)\s*\(|qx\b', source)
assert data['probe_plan']['excluded_execution'] == ['HDL compiler/simulator', 'native proxy/controller runtime', 'macro transport', 'submodule implementation']
assert len(data['probe_plan']['actual_helper_routes']) == 2
print('PASS complete immutable source/helper/token/copy contracts independently bind source-owned metadata routes. Generic context/warning assertions are not promoted to full cause or kind/native runtime assurance; actual probes and semantic/control qualification remain owned.')

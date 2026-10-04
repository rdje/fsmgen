"""Independent source-role and admission reader; no native assurance inference."""
import argparse
import copy
import hashlib
import json
import re
import subprocess
from pathlib import Path

BASE = Path(__file__).parent
parser = argparse.ArgumentParser()
for option in ('trust-label-calls', 'omit-copy', 'trust-synthetic-native', 'trust-stale-output'):
    parser.add_argument('--' + option, action='store_true')
args = parser.parse_args()
if (BASE / 'manifest.json').exists():
    manifest = json.loads((BASE / 'manifest.json').read_text())
    assert {p.name for p in BASE.iterdir()} == set(manifest) | {'manifest.json'}
    for name, row in manifest.items():
        raw = (BASE / name).read_bytes()
        assert len(raw) == row['bytes'] and hashlib.sha256(raw).hexdigest() == row['sha256'], name
data = json.loads((BASE / 'contracts.json').read_text())
assert data['revision'] == '1255cfbc744f5804912524bfc20373dab6c8c9f0'
assert len(data['sources']) == 18
card_path = 'docs/knowledge/isf-aggregate-port-request-baseline.md'
for path, row in data['sources'].items():
    raw = subprocess.check_output(['git', 'show', data['revision'] + ':' + path])
    assert raw.decode() == row['body'] and len(raw) == row['bytes']
    assert hashlib.sha256(raw).hexdigest() == row['sha256'], path
    if path != card_path:
        assert Path(path).read_bytes() == raw, 'selected current source drift: ' + path
source = data['sources']['t/1986-isf-record-port-value-gates.t']['body']
prior = json.loads(Path('docs/audits/aggregate-record-helper-plan-20261003/plan.json').read_text())
original = next(row for row in prior['rows'] if row['path'] == 't/1986-isf-record-port-value-gates.t')
assert original['source'] == source, 'complete original/current test identity'
call_lines = [114, 117, 119, 131, 135, 144, 150, 179, 181, 196, 203, 215,
    228, 230, 235, 267, 269, 271, 274, 279, 293]
tokens = []
copies = []
offset = 0
for number, line in enumerate(source.splitlines(keepends=True), 1):
    for match in re.finditer(r'\brefuses\b', line):
        stripped = line.strip()
        if stripped == 'sub refuses {':
            role = 'definition'
        elif stripped == 'ok(!$ok, "$name refuses");':
            role = 'assertion_label_string'
        else:
            assert stripped.startswith('refuses(sub {'), 'unclassified name token'
            role = 'operation_call_expression'
        tokens.append({'line': number, 'offset': offset + match.start(), 'role': role,
            'whole_line': line.rstrip('\n')})
    for match in re.finditer(r'\bdclone\(', line):
        copies.append({'line': number, 'offset': offset + match.start(),
            'whole_line': line.rstrip('\n')})
    offset += len(line)
assert tokens == data['tokens'] and len(tokens) == 23
candidate_tokens = copy.deepcopy(data['tokens'])
if args.trust_label_calls:
    candidate_tokens[1]['role'] = 'operation_call_expression'
assert [r['line'] for r in candidate_tokens if r['role'] == 'operation_call_expression'] == call_lines, \
    'actual assertion-label string cannot establish an operation expression'
assert [(r['line'], r['offset']) for r in tokens if r['role'] == 'definition'] == [(85, 4050)]
candidate_copies = data['copies'][:-1] if args.omit_copy else data['copies']
assert candidate_copies == copies and [r['line'] for r in copies] == [59, 122, 146, 223, 233, 261, 265], \
    'complete Storable source-expression inventory'
assert data['helper'] == source[source.index('sub refuses {'):source.index('sub diagnostic_line ')]
assert data['source_helpers'] == source[source.index('sub scope_for {'):source.index('sub refuses {')]
assert data['diagnostic_line'] == source[source.index('sub diagnostic_line '):source.index("subtest 'diagnostic oracle")]
assert data['synthetic_oracle'] == source[source.index("subtest 'diagnostic oracle"):source.index("subtest 'resolved alias")]
assert data['fixture'] == source[source.index('(actor controls\n'):source.index('\nISF\n')]
assert 'my $ok = eval { $run->(); 1 };' in data['helper']
assert 'my $diagnostic = diagnostic_line($@);' in data['helper']
assert 'like($diagnostic, $pattern,' in data['helper']
assert 'my $error = $@' not in data['helper'], 'prior helper retains its actual immediate first-line projection'
assert 'eval { confess "Deliberately wrong diagnostic\\n" };' in data['diagnostic_line']
assert 'wrong_cause_with_pattern_in_stack(qr/expected_cause_only_in_argument/)' in data['synthetic_oracle']
candidate_native = data['synthetic_oracle'] if args.trust_synthetic_native else ''
assert not candidate_native, 'artificial Carp self-test is not a genuine provider cause/control'
values = data['sources']['perl/FSM/Support/ISFRecordPortValues.pm']['body']
for fragment in (
    '_keys(\\%args, [qw(outer local)]', 'for my $layer (qw(outer local))',
    '$root = dclone($root);', 'clone_structured_value($spec)',
    '$source = dclone($source) if ref($source) eq \'HASH\';',
    '$target = dclone($target) if ref($target) eq \'HASH\';',
    'return 0 unless _record_port($source) || _record_port($target);',
    '_whole_record($source) && _whole_record($target)',
    'FSM::Composition::InterfacePortBuilder->declared_type_conflicts(',
    '$result{width} = 0 + $spec->{width};',
    "($resolved->{code} // 'unresolved')", 'my $error = $@;',
    '_require($ok, "$context has invalid resolved type: $error");',
    'confess "Invalid ISF record value: $_[1]\\n" unless $_[0];',
):
    assert fragment in values, fragment
payload = data['sources']['perl/FSM/Package/PayloadTypeSupport.pm']['body']
assert 'sub payload_compatible_with_type_spec' in payload
assert 'sub declared_type_conflicts' in data['sources']['perl/FSM/Composition/InterfacePortBuilder.pm']['body']
assert 'resolve_packed_range' in data['sources']['perl/FSM/Package/AggregatePathSupport.pm']['body']
assert 'Lispish::multi(\\$prepared_source_text)' in data['sources']['perl/FSM/Pipeline/SourceFrontend.pm']['body']
assert "tempdir(CLEANUP => 1)" in source and 'shared.fsm' in source
assert 'ProjectDataLocality' in source and "$_[0]{members}{data} = $_[0]" in source
assert not re.search(r'\b(?:system|exec|fork)\s*\(|qx\b', source)
assert data['native_plan']['actual_producers'] == ['record_value_scope', 'record_value_reference',
    'validate_record_port_copy', 'FSM::Adapter::ISF parse_source', 'PayloadTypeSupport payload_compatible_with_type_spec']
assert data['native_plan']['excluded_execution'] == ['HDL compiler/simulator',
    'native proxy/controller runtime', 'macro transport', 'submodule implementation']
assert 'inert/uninvoked' in data['native_plan']['native_types']
assert 'remain .2-owned' in data['native_plan']['unproved_legs']
before_card = data['sources'][card_path]['body']
assert 'Record outputs,\nroot-list ports and transaction-local aggregate ports remain deferred.' in before_card
current_card = Path(card_path).read_text()
assert current_card == (BASE / 'card-after.txt').read_text(), 'complete corrected fact/card watcher'
expected_card = before_card
for old, new in json.loads((BASE / 'card-changes.json').read_text()):
    assert expected_card.count(old) == 1, old
    expected_card = expected_card.replace(old, new)
assert expected_card == current_card, 'exact reviewed fact-preserving replacements'
candidate_card = before_card if args.trust_stale_output else current_card
assert '[Record outputs](isf-record-output-source-admission.md) now admit declarations/whole copies;' in candidate_card, \
    'historical intake must not override current admitted record-output declarations/whole copies'
assert 'fields, root-list and transaction aggregate ports stay closed.' in candidate_card
assert 'At intake' in current_card and 'These receipts are historical.' in current_card
assert '25c01f0127144922ade78951b91439e1d9221c08' in current_card
canonical = data['sources']['docs/knowledge/isf-record-output-source-admission.md']['body']
assert 'declaration' in canonical and 'whole' in canonical and 'field' in canonical
assert 'record-output' in data['sources']['docs/book/src/13j-type-enum-aggregate.md']['body']
print('PASS complete 18-source original/current T1986 contract: 23 name tokens '
    '(one definition, one label, 21 operation expressions), seven source copy expressions; '
    'first-line fragment/synthetic roles and public strict-identity/payload/import/local/cycle '
    'boundaries bind independently. Stale output-card authority rejects; native populations, '
    'full causes/products/kinds and actual controls remain successor-owned.')

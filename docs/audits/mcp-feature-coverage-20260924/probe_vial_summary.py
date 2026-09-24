"""Capture the existing public summary boundary; no private compiler API."""
from pathlib import Path
import hashlib
import json
import subprocess


def run(argv, stdin=None):
    result = subprocess.run(argv, input=stdin, capture_output=True, text=True, check=True)
    assert not result.stderr, result.stderr
    return json.loads(result.stdout)


source = 'vial/ahb_subordinate_base_output_arbitration_lifecycle_v2.vial'
command = ['bin/fsmgen', 'vial', 'check', '--json', '--language-version', '2', source]
native = run(command)
request = {'jsonrpc': '2.0', 'id': 1, 'method': 'tools/call', 'params': {
    'name': 'fsmgen_semantic_introspect',
    'arguments': {'source_id': source, 'language_version': 2},
}}
mcp = run(['perl', 'bin/fsmgen-mcp', '--workspace-root', '.'], json.dumps(request) + '\n')
assert native['success'] and not mcp['result']['isError']
assert mcp['result']['structuredContent']['report'] == native
package = native['semantic_report']['packages'][0]
family = package['intent_families'][0]
fixture = package['fixtures'][0]
assert set(family) == {'semantic_id', 'family_id', 'revision', 'node_count'}
assert 'nodes' not in family
assert all('actions' not in scenario for scenario in fixture['scenarios'])
assert all(set(item) == {'semantic_id', 'name'} for item in package['transactions'])
text = Path(source).read_text()
# These authored values are independent of both report producers.
for token in ['(readiness ready)', '(within 1024)', '(within 32)',
              '(target fixture_background)', '(seed 1)', '(reset bus 3)']:
    assert token in text, token
record = {
    'schema': 'fsmgen.vial_summary_boundary_audit.v1',
    'owner': 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.3.2.3.1',
    'capture_base_revision': subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip(),
    'source_id': source,
    'source_sha256': hashlib.sha256(Path(source).read_bytes()).hexdigest(),
    'native_command': command,
    'mcp_request': request,
    'native_mcp_complete_report_equal': True,
    'public_package_projection': package,
    'independent_authored_observations': {
        'readiness_name': 'ready', 'deadline_cycles': {'total': 1024, 'startup': 32},
        'service_target': 'fixture_background', 'random_seed': '1', 'reset_cycles': 3,
    },
    'root_cause': {
        'producer': 'perl/FSM/VIAL/SemanticReport.pm',
        'mechanism': '_package_summary keeps only the family identity/revision/count; _named_summaries and _fixture_summary intentionally omit declaration and action bodies.',
        'contract': 'docs/VIAL_SOURCE_AND_SEMANTIC_IR_V1_CONTRACT.md#sanitized-semantic-report',
        'introduced_contract_commit': '08f59167b',
    },
    'evidence_legs': {
        'rederive': 'Actual native CLI and newline MCP source reports compared completely.',
        'falsify': 'Direct source-text assertions identify authored values absent from the family/scenario summary; exact public record keys exclude a hidden node carrier. T1808 separately guards their typed compiler semantics.',
        'durability': 'Tracked probe, source, output and owning task/decision retain the boundary and additive repair selection.',
    },
    'limits': ['This is a public projection gap against deep inspection, not lost compiler meaning or MCP truncation.',
               'Existing summary contracts remain valid and frozen; the additive inspection route is selected, not implemented.'],
}
Path('docs/audits/mcp-feature-coverage-20260924/vial-summary-boundary.json').write_text(
    json.dumps(record, indent=2, sort_keys=True) + '\n')
print('VIAL summary boundary and complete native/MCP equality: PASS')

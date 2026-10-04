"""Bind the complete pre-qualification T1986 source contracts, without execution."""
import hashlib
import json
import re
import subprocess
from pathlib import Path

BASE = Path(__file__).parent
REVISION = '1255cfbc744f5804912524bfc20373dab6c8c9f0'
PATHS = [
    't/1986-isf-record-port-value-gates.t',
    'perl/FSM/Support/ISFRecordPortValues.pm',
    'perl/FSM/Support/ISFRecordPortContexts.pm',
    'perl/FSM/Support/ISFInterfacePortMetadata.pm',
    'perl/FSM/Package/AggregatePathSupport.pm',
    'perl/FSM/Package/PayloadTypeSupport.pm',
    'perl/FSM/Composition/InterfacePortBuilder.pm',
    'perl/FSM/Adapter/ISF.pm', 'perl/FSM/Adapter/ISF/Parser.pm',
    'perl/FSM/Package/ImportResolver.pm', 'perl/FSM/Package/Parser.pm',
    'perl/FSM/Pipeline/SourceFrontend.pm',
    't/lib/FSM/Test/ProjectDataLocality.pm',
    'docs/knowledge/isf-aggregate-port-request-baseline.md',
    'docs/knowledge/isf-record-output-source-admission.md',
    'docs/decisions/current/language-api/0113-isf-record-interface-ports-reuse-packed-type-and-writer-contracts.md',
    'docs/decisions/current/language-api/0114-record-value-validation-detaches-facts-before-reading.md',
    'docs/book/src/13j-type-enum-aggregate.md',
]
sources = {}
for path in PATHS:
    raw = subprocess.check_output(['git', 'show', REVISION + ':' + path])
    sources[path] = {'body': raw.decode(), 'bytes': len(raw),
        'sha256': hashlib.sha256(raw).hexdigest()}
source = sources[PATHS[0]]['body']
tokens = []
for match in re.finditer(r'\brefuses\b', source):
    line = source[:match.start()].count('\n') + 1
    role = ('definition' if line == 85 else 'assertion_label_string' if line == 89
        else 'operation_call_expression')
    tokens.append({'line': line, 'offset': match.start(), 'role': role,
        'whole_line': source.splitlines()[line - 1]})
copies = [{'line': source[:m.start()].count('\n') + 1, 'offset': m.start(),
    'whole_line': source.splitlines()[source[:m.start()].count('\n')]}
    for m in re.finditer(r'\bdclone\(', source)]
start = source.index('sub refuses {')
diagnostic = source.index('sub diagnostic_line ', start)
synthetic = source.index("subtest 'diagnostic oracle", diagnostic)
resolved = source.index("subtest 'resolved alias", synthetic)
plan = {'revision': REVISION, 'sources': sources, 'tokens': tokens, 'copies': copies,
    'helper': source[start:diagnostic],
    'diagnostic_line': source[diagnostic:synthetic],
    'synthetic_oracle': source[synthetic:resolved],
    'source_helpers': source[source.index('sub scope_for {'):start],
    'fixture': source[source.index('(actor controls\n'):source.index('\nISF\n')],
    'native_plan': {
        'actual_producers': ['record_value_scope', 'record_value_reference',
            'validate_record_port_copy', 'FSM::Adapter::ISF parse_source',
            'PayloadTypeSupport payload_compatible_with_type_spec'],
        'native_types': 'Plain parsed HASH/ARRAY/scalar facts; preserve kinds/sharing/cycle/isolation. '
            'No arbitrary native-class copy/serialization promise. Cyclic input must use actual source '
            'candidate and unmodified refusal guard; native CODE earlier controls only if needed and inert/uninvoked.',
        'excluded_execution': ['HDL compiler/simulator', 'native proxy/controller runtime',
            'macro transport', 'submodule implementation'],
        'public_dependency_routes': ['public Lispish multi parse API via SourceFrontend',
            'project package ImportResolver/Parser and same-volume shared.fsm fixture',
            'AggregatePathSupport resolve_packed_range and clone_structured_value',
            'InterfacePortBuilder declared_type_conflicts',
            'PayloadTypeSupport width/ordered-shape compatibility distinct from exact recursive identity'],
        'unproved_legs': 'Actual callback/API/copy/consumer/error/warning populations, complete intended '
            'cause/source/product models, input/output kinds, real native earlier/primary/caller/exact-prior/'
            'guard-bypass and native cyclic applicability remain .2-owned; lexical sites and artificial stack '
            'self-test do not qualify them.',
    },
}
(BASE / 'contracts.json').write_text(json.dumps(plan, sort_keys=True, indent=2) + '\n')
card = sources['docs/knowledge/isf-aggregate-port-request-baseline.md']['body']
for old, new in json.loads((BASE / 'card-changes.json').read_text()):
    assert card.count(old) == 1, old
    card = card.replace(old, new)
(BASE / 'card-after.txt').write_text(card)
print('PASS complete T1986 Git source contracts captured; lexical expressions and synthetic '
    'stack checks remain distinct from native operation or semantic assurance.')

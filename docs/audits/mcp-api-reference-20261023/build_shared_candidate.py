#!/usr/bin/env python3
"""Project shared candidate/contributor/type metadata from retained evidence."""
import argparse
import gzip
import json
import sys
from pathlib import Path

from build_diagnostic_families import sha, snapshot

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
OWNER = 'PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.5.2'
CONTEXTS = {
    'composition_shared_datapath_': 'semantic.composition.shared_datapath_candidates[]',
    'success_forward_ir_lowered_rtl_ir_composition_shared_datapath_': 'semantic.forward_ir.lowered_rtl_ir.composition_shared_datapath_candidates[]'}
SUFFIXES = {
    'candidate_entry_keys': ('', 'core'),
    'candidate_declared_type_extension_keys': ('', 'optional_extension'),
    'candidate_contributor_entry_keys': ('.contributors[]', 'core'),
    'candidate_contributor_declared_type_extension_keys': ('.contributors[]', 'optional_extension')}
SOURCES = ['perl/FSM/Support/' + name + '.pm' for name in (
    'CapabilityManifest', 'SemanticExportsSection', 'NormalizedSemanticReportContract',
    'NormalizedSemanticPayloadContract', 'NormalizedSemanticForwardIRContract',
    'NormalizedSemanticCompositionContract', 'NormalizedSemanticLoweredRTLIRContract')]
SOURCES += ['perl/FSM/Composition/SharedDatapathCandidateBuilder.pm']


def build():
    partition = json.loads(gzip.decompress((BASE / 'shared-datapath-partition.json.gz').read_bytes()))
    fields = {prefix + suffix: {'subject': root + relative, 'rule': rule,
        'alias_owner': 'FSM::Support::NormalizedSemantic' + ('LoweredRTLIRContract' if prefix.startswith('success_') else 'CompositionContract'),
        'value_owner': 'FSM::Support::NormalizedSemanticLoweredRTLIRContract',
        'value': partition['selected_values'][prefix + suffix]}
        for prefix, root in CONTEXTS.items() for suffix, (relative, rule) in SUFFIXES.items()}
    prefix = BASE.relative_to(ROOT).as_posix() + '/'
    return {'schema': 'fsmgen.shared_candidate.v1', 'owner': OWNER,
        'inputs': {name: sha((BASE / name).read_bytes()) for name in ('shared-datapath-partition.json.gz', 'composition-final-qualified.json.gz')},
        'fields': fields,
        'remaining_shared': {key: value for key, value in partition['selected_values'].items() if key not in fields},
        'remaining_fields': partition['remaining_fields'],
        'sources': {path: snapshot(path) for path in SOURCES},
        'documents': {path: snapshot(path) for path in ('docs/book/src/11-extensions-and-embedding.md', SOURCES[0])},
        'instruments': {prefix + name: snapshot(prefix + name) for name in ('build_shared_candidate.py', 'verify_shared_candidate.py')},
        'python': {'implementation': sys.implementation.name, 'version': list(sys.version_info)},
        'evidence_legs': {
            'rederive': 'Project exact partition-owned original native metadata, current source/doc/instrument identity and complete remaining delegations.',
            'falsify': 'Separate reviewed subject/literal/owner oracle, exact public report/payload/forward/composition delegation and independent defined-only builder projections, genuine missing-guide refusal and coherent adverse controls.',
            'durability': 'Retain source-bearing original/qualified packets, current/code-current replay, focused metadata regressions and selected native rendered tables.'},
        'limits': 'Shallow candidate/contributor/type-extension metadata only. Deeper type/IR/value, binding/drive/aggregate/assertion models, source availability, execution and original compiler/backend epochs remain separately owned.'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    target = args.output.resolve()
    if target.parent != BASE or target.exists():
        raise SystemExit('Output must be a new audit-directory file')
    target.write_bytes(gzip.compress((json.dumps(build(), sort_keys=True, indent=2) + '\n').encode(), mtime=0))
    print('Wrote shared candidate census; independent qualification required.')


if __name__ == '__main__':
    main()

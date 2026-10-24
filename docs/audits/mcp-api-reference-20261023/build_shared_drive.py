#!/usr/bin/env python3
"""Project partition-owned shared binding/drive metadata from retained inputs."""
import argparse
import gzip
import json
import sys
from pathlib import Path

from build_diagnostic_families import sha, snapshot

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
OWNER = 'PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.5.3'
CONTEXTS = {
    'composition_shared_datapath_': 'semantic.composition.shared_datapath_candidates[]',
    'success_forward_ir_lowered_rtl_ir_composition_shared_datapath_': 'semantic.forward_ir.lowered_rtl_ir.composition_shared_datapath_candidates[]'}
FAMILIES = {
    'bound_connection_expr_keys': ('.contributors[].bound_connection_expr', 'signal_ref_variant'),
    'candidate_contributor_drive_intent_entry_keys': ('.contributors[].drive_intent', 'object'),
    'candidate_contributor_drive_intent_rhs_enable_family_entry_keys': ('.contributors[].drive_intent.rhs_enable_families[]', 'array_element')}
SOURCES = ['perl/FSM/Support/' + name + '.pm' for name in (
    'CapabilityManifest', 'SemanticExportsSection', 'NormalizedSemanticReportContract',
    'NormalizedSemanticPayloadContract', 'NormalizedSemanticForwardIRContract',
    'NormalizedSemanticCompositionContract', 'NormalizedSemanticLoweredRTLIRContract')]
SOURCES += ['perl/FSM/Composition/SharedDatapathCandidateBuilder.pm', 'perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm']


def build():
    previous = json.loads(gzip.decompress((BASE / 'shared-candidate-qualified.json.gz').read_bytes()))
    partition = json.loads(gzip.decompress((BASE / 'shared-datapath-partition.json.gz').read_bytes()))
    fields = {prefix + suffix: {'subject': root + relative, 'rule': rule,
        'alias_owner': 'FSM::Support::NormalizedSemantic' + ('LoweredRTLIRContract' if prefix.startswith('success_') else 'CompositionContract'),
        'value_owner': 'FSM::Support::NormalizedSemanticLoweredRTLIRContract',
        'value': partition['selected_values'][prefix + suffix]}
        for prefix, root in CONTEXTS.items() for suffix, (relative, rule) in FAMILIES.items()}
    prefix = BASE.relative_to(ROOT).as_posix() + '/'
    instruments = ('build_shared_drive.py', 'verify_shared_drive.py', 'verify_shared_binding.py', 'probe_shared_binding.pl')
    return {'schema': 'fsmgen.shared_drive.v1', 'owner': OWNER,
        'inputs': {name: sha((BASE / name).read_bytes()) for name in (
            'shared-datapath-partition.json.gz', 'shared-candidate-qualified.json.gz', 'shared-binding-public-probe.json.gz')},
        'fields': fields,
        'remaining_shared': {key: value for key, value in previous['remaining_shared'].items() if key not in fields},
        'remaining_fields': previous['remaining_fields'],
        'sources': {path: snapshot(path) for path in SOURCES},
        'documents': {path: snapshot(path) for path in ('docs/book/src/11-extensions-and-embedding.md', SOURCES[0])},
        'instruments': {prefix + name: snapshot(prefix + name) for name in instruments},
        'python': {'implementation': sys.implementation.name, 'version': list(sys.version_info)},
        'evidence_legs': {
            'rederive': 'Project exact original partition-owned binding/drive fields and current source/doc/instrument identities; preserve all remaining shared/deeper delegation.',
            'falsify': 'Separate reviewed subject/container/literal and public delegation oracle, typed drive projection, authenticated signal-versus-compound public probe and coherent field/variant/value/source/doc controls.',
            'durability': 'Track complete source-bearing original/qualified packets and public probe, saved/current/code-current replay, metadata/copy regressions and selected native tables.'},
        'limits': 'Bounded field subjects and signal_ref family only; compound grammar, deeper value/type/IR semantics, source availability and compiler/backend execution remain separately owned.'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    target = args.output.resolve()
    if target.parent != BASE or target.exists():
        raise SystemExit('Output must be a new audit-directory file')
    target.write_bytes(gzip.compress((json.dumps(build(), sort_keys=True, indent=2) + '\n').encode(), mtime=0))
    print('Wrote shared binding/drive census; independent qualification required.')


if __name__ == '__main__':
    main()

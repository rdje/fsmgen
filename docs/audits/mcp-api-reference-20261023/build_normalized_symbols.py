#!/usr/bin/env python3
"""Project root and intent-HIR symbol metadata from retained native evidence."""
import argparse
import gzip
import json
import sys
from pathlib import Path

from build_diagnostic_families import sha, snapshot

ROOT = Path(__file__).resolve().parents[3]
BASE = Path(__file__).resolve().parent
OWNER = 'PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.3'
PREFIXES = {'symbol_contract_': 'semantic.symbol_contract',
    'success_forward_ir_intent_hir_symbol_contract_': 'semantic.forward_ir.intent_hir.symbol_contract'}
FAMILIES = {
    'constant_value_entry_keys': ('constants.<name>', 'core_keys'),
    'constant_scalar_value_extension_keys': ('constants.<name>', 'scalar_extension'),
    'constant_list_value_extension_keys': ('constants.<name>', 'list_extension'),
    'enum_entry_value_kinds': ('enums.<name>', 'value_kinds'),
    'enum_member_value_kinds': ('enums.<name>.<member>', 'value_kinds'),
    'type_entry_keys': ('types.<name>', 'recursive_core_keys'),
    'type_scalar_value_kinds': ('types.<name>', 'scalar_kinds'),
    'type_aggregate_value_kinds': ('types.<name>', 'aggregate_kinds'),
    'type_state_model_extension_keys': ('types.<name>', 'scalar_state_extension'),
    'type_list_extension_keys': ('types.<name>', 'recursive_list_extension'),
    'type_record_extension_keys': ('types.<name>', 'recursive_record_extension'),
    'package_import_entry_value_kinds': ('package_imports[]', 'value_kinds'),
    'package_import_entry_value_meaning': ('package_imports[]', 'scalar_meaning'),
}
SOURCES = ['perl/FSM/Support/' + name + '.pm' for name in (
    'CapabilityManifest', 'SemanticExportsSection', 'NormalizedSemanticReportContract',
    'NormalizedSemanticPayloadContract', 'NormalizedSemanticForwardIRContract',
    'NormalizedSemanticIntentHIRContract', 'NormalizedSemanticSymbolContract')]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    target = args.output.resolve()
    if target.parent != BASE or target.exists():
        raise SystemExit('Output must be a new audit-directory file')
    native = json.loads(gzip.decompress((BASE / 'model-roots-qualified.json.gz').read_bytes()))
    model = native['native_api']['manifest']['semantic_exports']['normalized_semantic_json']
    predecessor = json.loads(gzip.decompress((BASE / 'normalized-baseline-current-qualified.json.gz').read_bytes()))
    fields = {}
    for prefix, root in PREFIXES.items():
        for suffix, (subject, rule) in FAMILIES.items():
            key = prefix + suffix
            semantic_key = key.removeprefix('success_')
            fields[key] = {'value': model[key], 'subject': root + '.' + subject,
                'rule': rule, 'owner': 'FSM::Support::NormalizedSemanticSymbolContract',
                'presence_map_value': model['presence_key_family_map'][key],
                'semantic_map_key': semantic_key,
                'semantic_map_value': model['semantic_presence_key_family_map'][semantic_key]}
    scripts = [Path(__file__).relative_to(ROOT).as_posix(),
        (BASE / 'verify_normalized_symbols.py').relative_to(ROOT).as_posix()]
    packet = {'schema': 'fsmgen.normalized_symbol_families.v1', 'owner': OWNER,
        'capture_sha256': sha((BASE / 'model-roots-qualified.json.gz').read_bytes()),
        'capture_head': native['head'],
        'predecessor_sha256': sha((BASE / 'normalized-baseline-current-qualified.json.gz').read_bytes()),
        'predecessor_fields': predecessor['baseline']['remaining_fields'], 'fields': fields,
        'remaining_fields': {k: v for k, v in predecessor['baseline']['remaining_fields'].items() if k not in fields},
        'sources': {p: snapshot(p) for p in SOURCES},
        'documents': {p: snapshot(p) for p in ('docs/book/src/11-extensions-and-embedding.md', SOURCES[0])},
        'instruments': {p: snapshot(p) for p in scripts},
        'python': {'implementation': sys.implementation.name, 'version': list(sys.version_info)},
        'evidence_legs': {
            'rederive': 'Select native root/HIR symbol fields and both grouped projections, preserving every predecessor delegation with complete source/doc/producer identity.',
            'falsify': 'Independent subject/rule oracle and dedicated literal owner values; exact public delegation and factory/grouped-source joins; guide-absence and coherent adverse controls.',
            'durability': 'Tracked dated packet and original observations, complete source/instrument/doc bytes, saved/current reader, existing contract regressions and rendered table join.'},
        'limits': 'Selected metadata families and declared subjects only; arbitrary source/runtime payloads, complete nested models and broader grouped closure remain delegated. No compiler/source capture or backend execution.'}
    target.write_bytes(gzip.compress((json.dumps(packet, sort_keys=True, indent=2) + '\n').encode(), mtime=0))
    print('Wrote symbol-family census; independent qualification required.')


if __name__ == '__main__':
    main()

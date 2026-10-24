#!/usr/bin/env python3
"""Census normalized payload/IR baseline family subjects from retained metadata."""
import argparse
import gzip
import json
import sys
from pathlib import Path

from build_diagnostic_families import sha, snapshot

ROOT = Path(__file__).resolve().parents[3]
BASE = Path(__file__).resolve().parent
OWNER = 'PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.2'
BOOK = 'docs/book/src/11-extensions-and-embedding.md'
POD = 'perl/FSM/Support/CapabilityManifest.pm'
FAMILIES = {
    'public_layers': ('public_layer_names', 'advertised_values'),
    'success_semantic_presence_keys': ('semantic', 'success_base'),
    'success_semantic_optional_child_presence_keys': ('semantic', 'optional_children'),
    'success_module_presence_keys': ('semantic.module', 'base_fields'),
    'success_module_optional_metric_keys': ('semantic.module', 'optional_metrics'),
    'success_explicit_system_contract_presence_keys': ('semantic.explicit_system_contract', 'when_preserved_object'),
    'success_signal_analysis_presence_keys': ('semantic.signal_analysis', 'bucket_names'),
    'success_signal_analysis_entry_presence_keys': ('semantic.signal_analysis.<bucket>[]', 'common_entry_fields'),
    'success_system_contract_presence_keys': ('semantic.system_contract', 'effective_system_fields'),
    'success_symbol_contract_presence_keys': ('semantic.symbol_contract', 'when_available_object'),
    'success_forward_ir_presence_keys': ('semantic.forward_ir', 'tier_names'),
    'success_forward_ir_intent_hir_presence_keys': ('semantic.forward_ir.intent_hir', 'tier_base_fields'),
    'success_forward_ir_intent_hir_optional_composition_keys': ('semantic.forward_ir.intent_hir', 'optional_composition_fields'),
    'success_forward_ir_lowered_rtl_ir_presence_keys': ('semantic.forward_ir.lowered_rtl_ir', 'tier_base_fields'),
    'success_forward_ir_lowered_rtl_ir_optional_composition_keys': ('semantic.forward_ir.lowered_rtl_ir', 'optional_composition_fields'),
    'success_forward_ir_structural_rtl_ir_presence_keys': ('semantic.forward_ir.structural_rtl_ir', 'tier_base_fields'),
}
OWNERS = {
    'semantic_contract_source': 'semantic', 'module_contract_source': 'module',
    'explicit_system_contract_source': 'explicit_system_contract',
    'signal_analysis_contract_source': 'signal_analysis', 'system_contract_source': 'system_contract',
    'symbol_contract_source': 'symbol_contract', 'forward_ir_contract_source': 'forward_ir',
    'composition_contract_source': 'composition', 'forward_ir_intent_hir_contract_source': 'forward_ir_intent_hir',
    'forward_ir_lowered_rtl_ir_contract_source': 'forward_ir_lowered_rtl_ir',
    'forward_ir_structural_rtl_ir_contract_source': 'forward_ir_structural_rtl_ir',
}


def build():
    capture_path = BASE / 'model-roots-qualified.json.gz'
    capture = json.loads(gzip.decompress(capture_path.read_bytes()))
    native = capture['native_api']['manifest']['semantic_exports']['normalized_semantic_json']
    previous_path = BASE / 'normalized-envelope-qualified.json.gz'
    previous = json.loads(gzip.decompress(previous_path.read_bytes()))
    fields = {key: {'value': native[key], 'subject': subject, 'rule': rule}
              for key, (subject, rule) in FAMILIES.items()}
    for key, name in OWNERS.items():
        fields[key] = {'value': native[key], 'subject': 'nested_owner:' + name, 'rule': 'dedicated_owner_identity'}
    sources = {POD, 'perl/FSM/Support/NormalizedSemanticReportContract.pm',
               'perl/FSM/Support/NormalizedSemanticReport.pm'}
    sources.update('perl/' + native[key].replace('::', '/') + '.pm' for key in OWNERS)
    builder = Path(__file__).relative_to(ROOT).as_posix()
    helper = 'docs/audits/mcp-api-reference-20261023/build_diagnostic_families.py'
    return {'schema': 'fsmgen.normalized_baseline_families.v1', 'owner': OWNER,
        'capture_sha256': sha(capture_path.read_bytes()), 'capture_head': capture['head'],
        'predecessor_sha256': sha(previous_path.read_bytes()),
        'predecessor_fields': previous['remaining_fields'], 'fields': fields,
        'remaining_fields': {key: [OWNER.rsplit('.', 1)[0] + '.8',
            'PERL-POD-API-REFERENCE.6.1.2.3.2.3', 'PERL-POD-API-REFERENCE.6.1.2.3.3',
            'PERL-POD-API-REFERENCE.6.4'] for key in sorted(set(previous['remaining_fields']) - set(fields))},
        'sources': {path: snapshot(path) for path in sorted(sources)},
        'documents': {path: snapshot(path) for path in (BOOK, POD)},
        'builder': {'path': builder, **snapshot(builder)}, 'helpers': {helper: snapshot(helper)},
        'python': {'implementation': sys.implementation.name, 'version': list(sys.version_info)},
        'evidence_legs': {
            'rederive': 'Project selected native baseline/owner fields and preserve every predecessor field; retain complete source/doc/producer/runtime identities.',
            'falsify': 'Independent per-field owner/function literal-list oracle and subject/rule table; public factory required/optional/nullable source joins, pre-guide RED and coherent adverse controls.',
            'durability': 'Tracked dated packet, authenticated predecessor/native observation, complete source/doc/producer inputs and independent saved/current reader.'},
        'limits': 'Baseline family subjects and source-defined shape only; no source query/compiler/backend epoch, full nested value semantics, arbitrary Perl parsing or platform qualification.'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    target = args.output.resolve()
    if target.parent != BASE or target.exists():
        raise SystemExit('Output must be a new file in this audit directory')
    target.write_bytes(gzip.compress((json.dumps(build(), sort_keys=True, indent=2) + '\n').encode(), mtime=0))
    print('Wrote dated normalized-baseline census; independent qualification required.')


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""Project partition-owned standalone-DT child metadata from retained evidence."""
import argparse
import gzip
import json
import sys
from pathlib import Path

from build_diagnostic_families import sha, snapshot

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
OWNER = 'PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.4.3'
CONTEXTS = {
    'composition_standalone_dt_': 'semantic.composition.standalone_dt_children[]',
    'success_forward_ir_intent_hir_composition_standalone_dt_': 'semantic.forward_ir.intent_hir.composition_standalone_dt_children[]',
}
FAMILIES = {
    'child_entry_keys': ('', 'shallow_entry'),
    'enable_family_entry_keys': ('.standalone_dt_enable_families[]', 'array_element'),
    'module_enable_family_keys': ('.standalone_dt_module_enable_family', 'object'),
    'multi_drive_target_entry_keys': ('.standalone_dt_multi_drive_targets[]', 'array_element'),
    'multi_drive_assertion_keys': ('.standalone_dt_multi_drive_targets[].multi_drive_assertion', 'object'),
}
SOURCES = ['perl/FSM/Support/' + n + '.pm' for n in (
    'CapabilityManifest', 'SemanticExportsSection', 'NormalizedSemanticReportContract',
    'NormalizedSemanticPayloadContract', 'NormalizedSemanticForwardIRContract',
    'NormalizedSemanticIntentHIRContract', 'NormalizedSemanticCompositionContract',
    'NormalizedSemanticLoweredRTLIRContract')] + ['perl/FSM/Composition/ChildExportBuilder.pm']


def build():
    predecessor = json.loads(gzip.decompress((BASE / 'composition-overrides-qualified.json.gz').read_bytes()))
    partition = json.loads(gzip.decompress((BASE / 'normalized-composition-partition.json.gz').read_bytes()))
    fields = {prefix + suffix: {'value': partition['selected_values'][prefix + suffix],
        'subject': root + relative, 'rule': rule,
        'alias_owner': 'FSM::Support::NormalizedSemanticCompositionContract',
        'value_owner': 'FSM::Support::NormalizedSemantic' + ('LoweredRTLIRContract' if suffix.startswith('multi_drive_') else 'CompositionContract')}
        for prefix, root in CONTEXTS.items() for suffix, (relative, rule) in FAMILIES.items()}
    return {'schema': 'fsmgen.composition_dt_families.v1', 'owner': OWNER,
        'inputs': {n: sha((BASE / n).read_bytes()) for n in ('normalized-composition-partition.json.gz', 'composition-overrides-qualified.json.gz')},
        'fields': fields,
        'remaining_composition': {k: v for k, v in predecessor['remaining_composition'].items() if k not in fields},
        'remaining_fields': predecessor['remaining_fields'],
        'sources': {p: snapshot(p) for p in SOURCES},
        'documents': {p: snapshot(p) for p in ('docs/book/src/11-extensions-and-embedding.md', SOURCES[0])},
        'instruments': {BASE.relative_to(ROOT).as_posix() + '/' + n: snapshot(BASE.relative_to(ROOT).as_posix() + '/' + n)
            for n in ('build_composition_dt.py', 'verify_composition_dt.py')},
        'python': {'implementation': sys.implementation.name, 'version': list(sys.version_info)},
        'evidence_legs': {
            'rederive': 'Project exact partition-owned original native metadata and preserve every remaining delegation with current source/doc/instrument identity.',
            'falsify': 'Separate subject/container/literal oracle, exact dedicated public delegation and typed shallow-builder source joins, absent-guide refusal and coherent field/owner/shape/assertion/source controls.',
            'durability': 'Track complete source-bearing packets, saved/current/current-contracts reader modes, original native/partition/predecessor inputs, current metadata regressions and native rendered tables.'},
        'limits': 'Shallow family subjects/container kinds and dedicated metadata only. No new original source/compiler/backend epoch, complete nested models, source availability, assertion execution or verified arbitration.'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    target = args.output.resolve()
    if target.parent != BASE or target.exists():
        raise SystemExit('Output must be a new audit-directory file')
    target.write_bytes(gzip.compress((json.dumps(build(), sort_keys=True, indent=2) + '\n').encode(), mtime=0))
    print('Wrote standalone-DT census; independent qualification required.')


if __name__ == '__main__':
    main()

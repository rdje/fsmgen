#!/usr/bin/env python3
"""Project the partition-owned ordinary/generated override alias families."""
import argparse
import gzip
import json
import sys
from pathlib import Path

from build_diagnostic_families import sha, snapshot

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
OWNER = 'PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.4.2'
CONTEXTS = {
    'composition_child_parameter_override_': 'semantic.composition.children[].parameter_overrides[]',
    'composition_generated_child_parameter_override_': 'semantic.composition.generated_children[].parameter_overrides[]',
    'success_forward_ir_intent_hir_composition_child_parameter_override_': 'semantic.forward_ir.intent_hir.composition_children[].parameter_overrides[]',
    'success_forward_ir_intent_hir_composition_generated_child_parameter_override_': 'semantic.forward_ir.intent_hir.composition_generated_children[].parameter_overrides[]',
}
SHAPES = ('entry_keys', 'raw_value_extension_keys', 'value_metadata_extension_keys')
SOURCES = ['perl/FSM/Support/' + n + '.pm' for n in (
    'CapabilityManifest', 'SemanticExportsSection', 'NormalizedSemanticReportContract',
    'NormalizedSemanticPayloadContract', 'NormalizedSemanticForwardIRContract',
    'NormalizedSemanticIntentHIRContract', 'NormalizedSemanticCompositionContract',
    'NormalizedSemanticStructuralRTLIRContract')]


def build():
    partition = json.loads(gzip.decompress((BASE / 'normalized-composition-partition.json.gz').read_bytes()))
    shallow = json.loads(gzip.decompress((BASE / 'composition-shallow-qualified.json.gz').read_bytes()))
    fields = {prefix + shape: {'value': partition['selected_values'][prefix + shape],
        'subject': subject, 'rule': shape,
        'alias_owner': 'FSM::Support::NormalizedSemanticCompositionContract',
        'value_owner': 'FSM::Support::NormalizedSemanticStructuralRTLIRContract'}
        for prefix, subject in CONTEXTS.items() for shape in SHAPES}
    return {'schema': 'fsmgen.composition_override_aliases.v1', 'owner': OWNER,
        'inputs': {n: sha((BASE / n).read_bytes()) for n in ('normalized-composition-partition.json.gz', 'composition-shallow-qualified.json.gz')},
        'fields': fields,
        'remaining_composition': {k: v for k, v in shallow['remaining_composition'].items() if k not in fields},
        'remaining_fields': shallow['remaining_fields'], 'sources': {p: snapshot(p) for p in SOURCES},
        'documents': {p: snapshot(p) for p in ('docs/book/src/11-extensions-and-embedding.md', SOURCES[0])},
        'instruments': {BASE.relative_to(ROOT).as_posix() + '/' + n: snapshot(BASE.relative_to(ROOT).as_posix() + '/' + n)
            for n in ('build_composition_overrides.py', 'verify_composition_overrides.py')},
        'python': {'implementation': sys.implementation.name, 'version': list(sys.version_info)},
        'evidence_legs': {
            'rederive': 'Select every partition-owned override family from retained native metadata and conserve remaining composition/deeper ownership with exact sources/docs/instruments.',
            'falsify': 'Separate context/shape/literal oracle, exact public structural delegation and factory joins, genuine missing-guide refusal and coherent subject/optionality/owner/value/source controls.',
            'durability': 'Tracked dated packet, authenticated original native and shallow predecessor, saved/current reader, native rendered tables and existing public metadata regressions.'},
        'limits': 'Alias metadata subjects and optional extension interpretation only; no full raw AST/value models, source availability, backend execution or original compiler/source capture.'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    target = args.output.resolve()
    if target.parent != BASE or target.exists():
        raise SystemExit('Output must be a new audit-directory file')
    target.write_bytes(gzip.compress((json.dumps(build(), sort_keys=True, indent=2) + '\n').encode(), mtime=0))
    print('Wrote override alias census; independent qualification required.')


if __name__ == '__main__':
    main()

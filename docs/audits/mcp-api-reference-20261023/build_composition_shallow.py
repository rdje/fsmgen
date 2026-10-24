#!/usr/bin/env python3
"""Project the partition-owned shallow composition fields from saved metadata."""
import argparse
import gzip
import json
import sys
from pathlib import Path

from build_diagnostic_families import sha, snapshot

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
OWNER = 'PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.4.1'
BOOK = 'docs/book/src/11-extensions-and-embedding.md'
POD = 'perl/FSM/Support/CapabilityManifest.pm'
SOURCES = ['perl/FSM/Support/' + name + '.pm' for name in (
    'CapabilityManifest', 'SemanticExportsSection', 'NormalizedSemanticReportContract',
    'NormalizedSemanticPayloadContract', 'NormalizedSemanticForwardIRContract',
    'NormalizedSemanticIntentHIRContract', 'NormalizedSemanticCompositionContract')]


def build():
    partition_path = BASE / 'normalized-composition-partition.json.gz'
    partition = json.loads(gzip.decompress(partition_path.read_bytes()))
    fields = {}
    for key in partition['cohorts'][OWNER]:
        if key == 'composition_presence_keys':
            subject = 'semantic.composition'
            function = 'normalized_semantic_composition_presence_keys'
        else:
            hir = key.startswith('success_')
            generated = 'generated_child' in key
            collection = 'generated_children' if generated else 'children'
            subject = ('semantic.forward_ir.intent_hir.composition_' if hir else
                       'semantic.composition.') + collection + '[]'
            function = 'normalized_semantic_composition_' + ('generated_child' if generated else 'child') + '_entry_keys'
        fields[key] = {'value': partition['selected_values'][key], 'subject': subject,
            'function': function, 'owner': 'FSM::Support::NormalizedSemanticCompositionContract'}
    instruments = [BASE.relative_to(ROOT).as_posix() + '/' + n for n in (
        'build_composition_shallow.py', 'verify_composition_shallow.py')]
    return {'schema': 'fsmgen.composition_shallow.v1', 'owner': OWNER,
        'partition_sha256': sha(partition_path.read_bytes()), 'fields': fields,
        'remaining_composition': {k: v for k, v in partition['selected_values'].items() if k not in fields},
        'remaining_fields': partition['remaining_fields'],
        'sources': {p: snapshot(p) for p in SOURCES},
        'documents': {p: snapshot(p) for p in (BOOK, POD)},
        'instruments': {p: snapshot(p) for p in instruments},
        'python': {'implementation': sys.implementation.name, 'version': list(sys.version_info)},
        'evidence_legs': {
            'rederive': 'Project exactly the partition-owned saved native metadata and preserve every other composition/deeper delegation with complete current source/doc snapshots.',
            'falsify': 'Separate explicit subject/function oracle, original source literal/delegation joins, native metadata comparison, real absent-guide refusal and coherent field/subject/source/doc controls.',
            'durability': 'Tracked source-bearing packet, authenticated original capture/partition, saved/current replay, actual rendered-content join and current public metadata regressions.'},
        'limits': 'Shallow metadata subjects only. No new source/compiler/backend epoch, full nested model, equal child population, unconditional availability or complete MCP/reference/browser signoff.'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    target = args.output.resolve()
    if target.parent != BASE or target.exists():
        raise SystemExit('Output must be a new audit-directory file')
    target.write_bytes(gzip.compress((json.dumps(build(), sort_keys=True, indent=2) + '\n').encode(), mtime=0))
    print('Wrote shallow composition packet; independent qualification required.')


if __name__ == '__main__':
    main()

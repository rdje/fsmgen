#!/usr/bin/env python3
"""Project only the remaining partition-owned aggregate/assertion metadata."""
import argparse
import gzip
import json
from pathlib import Path
import sys

from build_diagnostic_families import sha, snapshot

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
OWNER = 'PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.5.4'
CONTEXTS = {
    'composition_shared_datapath_': 'semantic.composition.shared_datapath_candidates[]',
    'success_forward_ir_lowered_rtl_ir_composition_shared_datapath_': 'semantic.forward_ir.lowered_rtl_ir.composition_shared_datapath_candidates[]'}
FAMILIES = {
    'aggregate_enable_family_entry_keys': (['.aggregate_enable_families[]'], 'array_element'),
    'aggregate_enable_contributor_entry_keys': (['.aggregate_enable_families[].contributors[]'], 'array_element'),
    'assertion_keys': (['.multi_value_assertion', '.aggregate_enable_families[].same_value_assertion'], 'object')}
BOOK = 'docs/book/src/11a-perl-api-reference.md'
POD = 'perl/FSM/Support/CapabilityManifest.pm'


def build():
    previous = json.loads(gzip.decompress((BASE / 'shared-drive-final-qualified.json.gz').read_bytes()))
    partition = json.loads(gzip.decompress((BASE / 'shared-datapath-partition.json.gz').read_bytes()))
    fields = {prefix + suffix: {'subjects': [root + relative for relative in relatives],
        'rule': rule, 'value': partition['selected_values'][prefix + suffix],
        'value_owner': 'FSM::Support::NormalizedSemanticLoweredRTLIRContract',
        'alias_owner': 'FSM::Support::NormalizedSemantic' + ('LoweredRTLIRContract' if prefix.startswith('success_') else 'CompositionContract')}
        for prefix, root in CONTEXTS.items() for suffix, (relatives, rule) in FAMILIES.items()}
    sources = set(previous['sources']) | {'perl/FSM/Composition/SharedDatapathSupport.pm'}
    prefix = BASE.relative_to(ROOT).as_posix() + '/'
    return {'schema': 'fsmgen.shared_aggregate.v1', 'owner': OWNER,
        'inputs': {name: sha((BASE / name).read_bytes()) for name in
                   ('shared-datapath-partition.json.gz', 'shared-drive-final-qualified.json.gz')},
        'fields': fields,
        'remaining_shared': {key: value for key, value in previous['remaining_shared'].items() if key not in fields},
        'remaining_fields': previous['remaining_fields'],
        'sources': {path: snapshot(path) for path in sorted(sources)},
        'documents': {path: snapshot(path) for path in (BOOK, POD)},
        'instruments': {prefix + name: snapshot(prefix + name) for name in
                        ('build_shared_aggregate.py', 'verify_shared_aggregate.py')},
        'python': {'implementation': sys.implementation.name, 'version': list(sys.version_info)},
        'evidence_legs': {
            'rederive': 'Project remaining original partition fields/values and current dedicated source/document/instrument identities.',
            'falsify': 'Independent explicit subjects, literal values, public delegation and builder/support assertion-input oracle; coherent field/container/context/owner/source/doc controls.',
            'durability': 'Retain complete source-bearing packets, original native/source custody, dated/current replay and selected native guide checks.'},
        'limits': 'Bounded metadata subjects and source construction rules only; deeper models, source availability, emitted assertions and verified arbitration/execution remain separate.'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    require_new = args.output.resolve().parent == BASE and not args.output.exists()
    if not require_new:
        raise SystemExit('Output must be a new owned audit-directory packet')
    args.output.write_bytes(gzip.compress((json.dumps(build(), sort_keys=True, indent=2) + '\n').encode(), mtime=0))
    print('Wrote aggregate/assertion projection; independent qualification required.')


if __name__ == '__main__':
    main()

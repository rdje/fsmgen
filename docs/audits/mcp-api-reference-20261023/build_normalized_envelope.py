#!/usr/bin/env python3
"""Bind normalized report-envelope families to saved native metadata and sources."""
import argparse
import gzip
import json
import sys
from pathlib import Path

from build_diagnostic_families import sha, snapshot

ROOT = Path(__file__).resolve().parents[3]
BASE = Path(__file__).resolve().parent
OWNER = 'PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.1'
BOOK = 'docs/book/src/11-extensions-and-embedding.md'
POD = 'perl/FSM/Support/CapabilityManifest.pm'
PATH = '/semantic_exports/normalized_semantic_json'
FAMILIES = {
    'public_top_level_presence_keys': ('normalized_report', 'both_outcomes'),
    'success_only_top_level_keys': ('normalized_report', 'success_only'),
    'command_presence_keys': ('normalized_report.command', 'both_outcomes'),
    'generated_output_presence_keys': ('normalized_report.generated_output', 'both_outcomes'),
    'producer_presence_keys': ('normalized_report.producer', 'both_outcomes'),
    'producer_extra_presence_keys': ('normalized_report.producer', 'additive_both_outcomes'),
    'source_presence_keys': ('normalized_report.source', 'both_outcomes'),
    'source_optional_fields': ('normalized_report.source', 'optional_success_declarations'),
    'support_accounting_presence_keys': ('normalized_report.support_accounting', 'both_outcomes'),
    'matched_success_support_accounting_presence_keys': ('normalized_report.support_accounting', 'matched_success_additions'),
    'matched_failure_support_accounting_presence_keys': ('normalized_report.support_accounting', 'matched_failure_additions'),
    'failure_diagnostic_presence_keys': ('normalized_report.diagnostics[]', 'failure_element'),
    'matched_failure_diagnostic_presence_keys': ('normalized_report.diagnostics[]', 'matched_failure_additions'),
    'failure_diagnostic_optional_artifact_keys': ('normalized_report.diagnostics[]', 'optional_artifact'),
    'failure_diagnostic_support_accounting_presence_keys': ('normalized_report.diagnostics[].support_accounting', 'failure_element'),
    'matched_failure_diagnostic_support_accounting_presence_keys': ('normalized_report.diagnostics[].support_accounting', 'matched_failure_additions'),
}
SHARED = ('command', 'generated_output', 'producer', 'source', 'support_accounting',
          'failure_diagnostic', 'diagnostic_summary', 'generation_result_snapshot')


def build():
    capture_path = BASE / 'model-roots-qualified.json.gz'
    capture = json.loads(gzip.decompress(capture_path.read_bytes()))
    native = capture['native_api']['manifest']['semantic_exports']['normalized_semantic_json']
    identity_path = BASE / 'enriched-identity-final.json.gz'
    identity = json.loads(gzip.decompress(identity_path.read_bytes()))
    prior = next(r['deferred_fields'] for r in identity['records'] if r['pointer'] == PATH)
    fields = {key: {'value': native[key], 'subject': subject, 'condition': condition}
              for key, (subject, condition) in FAMILIES.items()}
    for name in SHARED:
        key = name + '_contract_source'
        fields[key] = {'value': native[key], 'subject': 'nested_owner:' + name,
                       'condition': 'dedicated_owner_identity'}
    sources = {POD, 'perl/FSM/Support/NormalizedSemanticReportContract.pm',
               'perl/FSM/Support/NormalizedSemanticReport.pm', 'perl/FSM/Support/CheckDiagnostics.pm'}
    sources.update('perl/' + native[name + '_contract_source'].replace('::', '/') + '.pm' for name in SHARED)
    builder = Path(__file__).relative_to(ROOT).as_posix()
    return {'schema': 'fsmgen.normalized_envelope_families.v1', 'owner': OWNER,
        'pointer': PATH, 'capture_sha256': sha(capture_path.read_bytes()), 'capture_head': capture['head'],
        'identity_sha256': sha(identity_path.read_bytes()), 'prior_fields': prior,
        'fields': fields, 'remaining_fields': {key: [OWNER.rsplit('.', 1)[0] + '.8',
            'PERL-POD-API-REFERENCE.6.1.2.3.2.3', 'PERL-POD-API-REFERENCE.6.1.2.3.3',
            'PERL-POD-API-REFERENCE.6.4'] for key in sorted(set(prior) - set(fields))},
        'sources': {path: snapshot(path) for path in sorted(sources)},
        'documents': {path: snapshot(path) for path in (BOOK, POD)},
        'builder': {'path': builder, **snapshot(builder)},
        'helpers': {'docs/audits/mcp-api-reference-20261023/build_diagnostic_families.py':
                    snapshot('docs/audits/mcp-api-reference-20261023/build_diagnostic_families.py')},
        'python': {'implementation': sys.implementation.name, 'version': list(sys.version_info)},
        'evidence_legs': {
            'rederive': 'Project exact selected native metadata and every remaining identity delegation; retain complete canonical source/doc/instrument bytes.',
            'falsify': 'Independent subject/condition and source-derived report-root/producer/command/source key joins, dedicated owners, genuine pre-guide RED and coherent adverse controls.',
            'durability': 'Tracked dated packet and saved native capture, complete source/doc/producer snapshots, independent saved/current reader and task-scoped Git.'},
        'limits': 'Common normalized report-envelope family metadata only. Deeper payload and grouped maps retain exact selected successors. Source review is not a new source/compiler/backend epoch or full operating-reference qualification.'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    target = args.output.resolve()
    if target.parent != BASE or target.exists():
        raise SystemExit('Output must be a new file in this audit directory')
    target.write_bytes(gzip.compress((json.dumps(build(), sort_keys=True, indent=2) + '\n').encode(), mtime=0))
    print('Wrote dated normalized-envelope census; independent qualification required.')


if __name__ == '__main__':
    main()

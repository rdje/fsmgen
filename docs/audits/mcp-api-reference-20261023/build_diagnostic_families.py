#!/usr/bin/env python3
"""Bind diagnostic family subjects to the qualified saved native metadata."""
import argparse
import gzip
import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
BASE = Path(__file__).resolve().parent
OWNER = 'PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.1'
BOOK = 'docs/book/src/11-extensions-and-embedding.md'
POD = 'perl/FSM/Support/CapabilityManifest.pm'
IDENTITY = ('schema_version', 'status', 'contract_source', 'report_source',
            'entrypoints', 'guidance')
CHECK = {
    'public_top_level_presence_keys': ('check_report', 'required_both_outcomes'),
    'success_only_top_level_keys': ('check_report', 'success_only'),
    'command_presence_keys': ('check_report.command', 'required_both_outcomes'),
    'generated_output_presence_keys': ('check_report.generated_output', 'required_both_outcomes'),
    'producer_presence_keys': ('check_report.producer', 'required_both_outcomes'),
    'source_presence_keys': ('check_report.source', 'required_both_outcomes'),
    'source_optional_fields': ('check_report.source', 'optional_declarations'),
    'success_result_presence_keys': ('check_report.result', 'success_only'),
    'success_support_accounting_presence_keys': ('check_report.support_accounting', 'success_only'),
    'matched_success_support_accounting_presence_keys': ('check_report.support_accounting', 'matched_success_additions'),
    'failure_diagnostic_presence_keys': ('check_report.diagnostics[]', 'failure_element'),
    'matched_failure_diagnostic_presence_keys': ('check_report.diagnostics[]', 'matched_failure_additions'),
    'failure_diagnostic_optional_artifact_keys': ('check_report.diagnostics[]', 'optional_artifact'),
    'failure_diagnostic_support_accounting_presence_keys': ('check_report.diagnostics[].support_accounting', 'failure_element'),
    'matched_failure_diagnostic_support_accounting_presence_keys': ('check_report.diagnostics[].support_accounting', 'matched_failure_additions'),
    'nested_contract_source_map': ('check_nested_subjects', 'owner_namespaces'),
    'nested_presence_key_map': ('check_nested_subjects', 'base_keys_by_subject'),
    'presence_key_family_map': ('check_family_metadata', 'same_named_mirrors'),
}
REGISTRY = {
    'public_sibling_keys': ('manifest.diagnostics', 'registry_siblings'),
    'entry_presence_keys': ('manifest.diagnostics.stable_codes[]', 'entry_keys'),
    'key_family_map': ('registry_key_metadata', 'same_named_mirrors'),
    'bounded_severity_values': ('stable_code_entry.severity', 'allowed_values'),
    'bounded_stability_values': ('stable_code_entry.stability', 'allowed_values'),
    'bounded_family_values': ('stable_code_entry.family', 'allowed_values'),
    'bounded_value_family_map': ('registry_value_metadata', 'same_named_mirrors'),
    'code_shape': ('stable_code_entry.code', 'code_pattern'),
}


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def snapshot(path):
    raw = (ROOT / path).read_bytes()
    return {'sha256': sha(raw), 'text': raw.decode('utf-8')}


def build():
    capture_path = BASE / 'model-roots-qualified.json.gz'
    capture = json.loads(gzip.decompress(capture_path.read_bytes()))
    identity_path = BASE / 'enriched-identity-final.json.gz'
    identity = json.loads(gzip.decompress(identity_path.read_bytes()))
    records = []
    sources = {POD, 'perl/FSM/Support/DiagnosticsSection.pm',
               'perl/FSM/Support/CheckDiagnostics.pm', 'perl/FSM/Support/DiagnosticCodes.pm'}
    for name, meanings in (('check_json', CHECK), ('stable_code_registry', REGISTRY)):
        obj = capture['native_api']['manifest']['diagnostics'][name]
        owner = 'perl/' + obj['contract_source'].replace('::', '/') + '.pm'
        sources.add(owner)
        sources.update('perl/' + value.replace('::', '/') + '.pm'
                       for value in obj.get('nested_contract_source_map', {}).values())
        fields = {key: {'value': obj[key], 'subject': subject, 'rule': rule}
                  for key, (subject, rule) in meanings.items()}
        for key, namespace in obj.get('nested_contract_source_map', {}).items():
            scalar = key + '_contract_source'
            fields[scalar] = {'value': obj[scalar], 'subject': 'nested_owner:' + key,
                              'rule': 'same_named_owner_mirror'}
        records.append({'pointer': '/diagnostics/' + name,
                        'owner': obj['contract_source'], 'fields': fields,
                        'identity_fields': list(IDENTITY),
                        'delegated_fields': {key: [
                            'PERL-POD-API-REFERENCE.6.1.2.3.2.2',
                            'PERL-POD-API-REFERENCE.6.1.2.3.3',
                            'PERL-POD-API-REFERENCE.6.4']
                            for key in sorted(set(obj) - set(fields) - set(IDENTITY))}})
    return {
        'schema': 'fsmgen.diagnostic_family_subjects.v1', 'owner': OWNER,
        'capture': capture_path.relative_to(ROOT).as_posix(),
        'capture_sha256': sha(capture_path.read_bytes()), 'capture_head': capture['head'],
        'identity_sha256': sha(identity_path.read_bytes()),
        'prior_delegation': {r['pointer']: r['deferred_fields'] for r in identity['records']
                             if r['pointer'].startswith('/diagnostics/')},
        'records': records,
        'sources': {path: snapshot(path) for path in sorted(sources)},
        'documents': {path: snapshot(path) for path in (BOOK, POD)},
        'builder': {'path': Path(__file__).relative_to(ROOT).as_posix(),
                    **snapshot(Path(__file__).relative_to(ROOT).as_posix())},
        'python': {'implementation': sys.implementation.name, 'version': list(sys.version_info)},
        'limits': 'Saved metadata and selected common-family subjects only; no source/compiler/backend epoch. Nested field values, diagnostic-code meanings and remaining metadata retain exact deeper owners. No complete MCP-reference or browser qualification.',
        'evidence_legs': {
            'rederive': 'Project all selected families and complete remaining-field delegation from the authenticated original native observation; retain exact source, documentation and builder bytes.',
            'falsify': 'Independent explicit subject/condition/domain table, complete native value and owner joins, grouped mirror and sibling/entry/value checks, pre-guide RED and coherent adverse controls.',
            'durability': 'Tracked dated source/document/instrument packet, original qualified capture, independent saved/current reader, controls and work-unit Git.'},
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    target = args.output.resolve()
    if target.parent != BASE or target.exists():
        raise SystemExit('Output must be a new file in this audit directory')
    raw = (json.dumps(build(), sort_keys=True, indent=2) + '\n').encode()
    with target.open('xb') as stream:
        stream.write(gzip.compress(raw, mtime=0))
    print('Wrote dated diagnostic-family packet; independent qualification required.')


if __name__ == '__main__':
    main()

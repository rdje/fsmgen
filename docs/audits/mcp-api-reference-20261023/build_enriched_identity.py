#!/usr/bin/env python3
"""Bind enriched identity/route fields to the qualified saved native observation."""
import argparse
import gzip
import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
BASE = Path(__file__).resolve().parent
OWNER = 'PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.1'
PARENT = OWNER.rsplit('.', 1)[0]
BOOK = 'docs/book/src/11-extensions-and-embedding.md'
POD = 'perl/FSM/Support/CapabilityManifest.pm'
COMMON = ('schema_version', 'status', 'contract_source', 'report_source',
          'entrypoints', 'mcp_adapter_entrypoints', 'guidance')
ROLES = {
    'HDLExternalValidationContract': 'external_validation',
    'CheckDiagnosticsContract': 'check_report',
    'DiagnosticCodeRegistryContract': 'diagnostic_registry',
    'NormalizedSemanticReportContract': 'normalized_semantic_report',
    'SemanticIntrospectionContract': 'manifest_discovery',
    'SupportAccountingContract': 'manifest_discovery',
    'VerificationOutputsContract': 'manifest_discovery',
}


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def kind(value):
    return {bool: 'boolean', int: 'integer', str: 'string', dict: 'object',
            list: 'array', type(None): 'null'}[type(value)]


def snapshot(path):
    raw = (ROOT / path).read_bytes()
    return {'sha256': sha(raw), 'text': raw.decode('utf-8')}


def build():
    capture_path = BASE / 'model-roots-qualified.json.gz'
    cohort_path = BASE / 'common-record-cohorts.json'
    capture = json.loads(gzip.decompress(capture_path.read_bytes()))
    cohorts = json.loads(cohort_path.read_bytes())
    records, sources = [], {POD}
    for selected in cohorts['cohorts'][PARENT]:
        obj = capture['native_api']['manifest']
        for token in selected['pointer'].split('/')[1:]:
            obj = obj[token]
        namespace = obj['contract_source']
        owner_path = 'perl/' + namespace.replace('::', '/') + '.pm'
        section = selected['pointer'].split('/')[1]
        section_source = {
            'semantic_introspection': 'SemanticIntrospectionSection',
            'support_accounting': 'SupportAccountingSection',
            'verification_outputs': 'VerificationOutputsSection',
        }.get(section)
        construction = ('perl/FSM/Support/' + section_source + '.pm'
                        if section_source and '/' not in selected['pointer'][1:] else owner_path)
        sources.update((owner_path, construction))
        fields = {}
        for name in COMMON:
            fields[name] = {'present': name in obj}
            if name in obj:
                fields[name].update(kind=kind(obj[name]), value=obj[name])
        successor = PARENT + ('.2' if section in
            ('backend_validation', 'diagnostics', 'semantic_exports') else '.3')
        records.append({
            'pointer': selected['pointer'], 'owner': namespace,
            'owner_source': owner_path, 'construction_source': construction,
            'route_role': ROLES[namespace.rsplit('::', 1)[1]],
            'fields': fields,
            'deferred_fields': {k: successor for k in sorted(set(obj) - set(COMMON))},
            'extension': 'bounded named families; deliberate documented regression-backed widening',
            'ordering': 'retain observed array order; no positional priority promised',
        })
    builder = Path(__file__).resolve().relative_to(ROOT).as_posix()
    return {
        'schema': 'fsmgen.enriched_identity.v1', 'owner': OWNER,
        'capture': capture_path.relative_to(ROOT).as_posix(),
        'capture_sha256': sha(capture_path.read_bytes()), 'capture_head': capture['head'],
        'cohorts_sha256': sha(cohort_path.read_bytes()),
        'builder': {'path': builder, **snapshot(builder)},
        'python': {'implementation': sys.implementation.name, 'version': list(sys.version_info)},
        'records': records,
        'sources': {p: snapshot(p) for p in sorted(sources)},
        'documents': {p: snapshot(p) for p in (BOOK, POD)},
        'facets': {'universal_record_schema': False, 'all_statuses_bounded_public': False,
                   'report_source_always_manifest_builder': False,
                   'entrypoints_are_mcp_tool_names': False,
                   'absent_common_fields_are_null': False, 'array_priority_promised': False},
        'evidence_legs': {
            'rederive': 'Enumerate seven identity/route/guidance fields, including absence, at each exact selected saved-native path; bind complete dedicated source/document/builder bytes.',
            'falsify': 'Independent explicit path/owner/role/status/shape/projection join, authenticated native/wire/source custody, actual pre-guide RED and coherent adverse controls.',
            'durability': 'Tracked saved capture, cohorts, exact source/doc/instrument snapshots, saved/current reader, controls and task-scoped Git.'},
        'limits': 'Selected enriched identity/routes only. Every other field is delegated by exact path; family and deeper payload semantics remain pending. No source epoch, backend, simulation or publication qualification.',
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    output = args.output.resolve()
    if output.parent != BASE or output.exists():
        raise SystemExit('Output must be a new file in this audit directory')
    raw = (json.dumps(build(), sort_keys=True, indent=2) + '\n').encode()
    with output.open('xb') as stream:
        stream.write(gzip.compress(raw, mtime=0))
    print('Wrote dated enriched identity census; independent verification required.')


if __name__ == '__main__':
    main()

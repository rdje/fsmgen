#!/usr/bin/env python3
"""Independently verify enriched identity/routes, explicit absence and delegation."""
import argparse
import copy
import gzip
import hashlib
import json
import sys
from pathlib import Path

from verify_error_context import source
from verify_model_roots import capture_check

ROOT = Path(__file__).resolve().parents[3]
BASE = Path(__file__).resolve().parent
OWNER = 'PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.1'
PARENT = OWNER.rsplit('.', 1)[0]
BOOK = 'docs/book/src/11-extensions-and-embedding.md'
POD = 'perl/FSM/Support/CapabilityManifest.pm'
BUILDER = 'docs/audits/mcp-api-reference-20261023/build_enriched_identity.py'
# Explicit reviewed native subjects; not imported from the producing classifier.
SUBJECTS = {
    '/backend_validation/systemverilog_external': ('HDLExternalValidationContract', 'HDLExternalValidation', 'external_validation'),
    '/diagnostics/check_json': ('CheckDiagnosticsContract', 'CheckDiagnostics', 'check_report'),
    '/diagnostics/stable_code_registry': ('DiagnosticCodeRegistryContract', 'DiagnosticCodes', 'diagnostic_registry'),
    '/semantic_exports/normalized_semantic_json': ('NormalizedSemanticReportContract', 'NormalizedSemanticReport', 'normalized_semantic_report'),
    '/semantic_introspection': ('SemanticIntrospectionContract', 'CapabilityManifest', 'manifest_discovery'),
    '/semantic_introspection/section_contract': ('SemanticIntrospectionContract', 'CapabilityManifest', 'manifest_discovery'),
    '/support_accounting': ('SupportAccountingContract', 'RegressionCorpus', 'manifest_discovery'),
    '/support_accounting/section_contract': ('SupportAccountingContract', 'RegressionCorpus', 'manifest_discovery'),
    '/verification_outputs': ('VerificationOutputsContract', 'CapabilityManifest', 'manifest_discovery'),
    '/verification_outputs/section_contract': ('VerificationOutputsContract', 'CapabilityManifest', 'manifest_discovery'),
}


def require(ok, why):
    if not ok:
        raise ValueError(why)


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def exact(value):
    return json.dumps(value, sort_keys=True, ensure_ascii=True, separators=(',', ':'))


def at(obj, path):
    for part in path.split('/')[1:]:
        obj = obj[part]
    return obj


def verify(packet, capture, current=False):
    require(packet['schema'] == 'fsmgen.enriched_identity.v1' and packet['owner'] == OWNER, 'census identity')
    require(packet['capture'] == 'docs/audits/mcp-api-reference-20261023/model-roots-qualified.json.gz', 'capture path')
    require(packet['capture_sha256'] == sha((BASE / 'model-roots-qualified.json.gz').read_bytes()), 'capture identity')
    require(packet['capture_head'] == capture['head'], 'capture epoch')
    require(packet['cohorts_sha256'] == sha((BASE / 'common-record-cohorts.json').read_bytes()), 'cohort identity')
    selected = json.loads((BASE / 'common-record-cohorts.json').read_bytes())['cohorts'][PARENT]
    require({x['pointer'] for x in selected} == set(SUBJECTS), 'selected path population')
    rows = {r['pointer']: r for r in packet['records']}
    require(len(rows) == len(packet['records']) and rows.keys() == SUBJECTS.keys(), 'complete unique record population')
    builder = packet['builder']
    require(builder['path'] == BUILDER and sha(builder['text'].encode()) == builder['sha256'], 'builder identity')
    require(packet['python']['implementation'] and len(packet['python']['version']) == 5, 'Python identity')
    if current:
        require((ROOT / BUILDER).read_bytes() == builder['text'].encode(), 'current builder stale')
        require(packet['python'] == {'implementation': sys.implementation.name, 'version': list(sys.version_info)}, 'current runtime stale')
    manifest = capture['native_api']['manifest']
    expected_sources = {POD}
    common = {'schema_version': int, 'status': str, 'contract_source': str,
              'report_source': str, 'entrypoints': dict, 'mcp_adapter_entrypoints': list,
              'guidance': list}
    kinds = {int: 'integer', str: 'string', dict: 'object', list: 'array'}
    field_count, absent_count, deferred_count = 0, 0, 0
    for path, (contract, producer, role) in SUBJECTS.items():
        row, native = rows[path], at(manifest, path)
        namespace = 'FSM::Support::' + contract
        owner_source = 'perl/FSM/Support/' + contract + '.pm'
        construction = 'perl/FSM/Support/' + contract.replace('Contract', 'Section') + '.pm' if path in (
            '/semantic_introspection', '/support_accounting', '/verification_outputs') else owner_source
        expected_sources.update((owner_source, construction))
        require(row['owner'] == native['contract_source'] == namespace, 'dedicated owner: ' + path)
        require(row['owner_source'] == owner_source and row['construction_source'] == construction, 'construction source: ' + path)
        require(row['route_role'] == role, 'route subject: ' + path)
        require(native['report_source'] == 'FSM::Support::' + producer, 'dedicated report source: ' + path)
        require(set(row['fields']) == set(common), 'identity-field census: ' + path)
        for name, cls in common.items():
            field = row['fields'][name]
            require(type(field['present']) is bool and field['present'] == (name in native), 'explicit presence: ' + path + '/' + name)
            if name not in native:
                absent_count += 1
                require(set(field) == {'present'}, 'absence must not synthesize null/value: ' + path)
                continue
            field_count += 1
            require(set(field) == {'present', 'kind', 'value'}, 'field shape: ' + path)
            require(type(field['value']) is cls and field['kind'] == kinds[cls], 'field type: ' + path + '/' + name)
            require(exact(field['value']) == exact(native[name]), 'complete native value/order: ' + path + '/' + name)
        require(type(native['schema_version']) is int and native['schema_version'] == 1, 'contract numeric schema')
        expected_status = 'optional_when_tools_installed' if role == 'external_validation' else 'bounded_public'
        require(native['status'] == expected_status, 'status availability boundary')
        entries = native['entrypoints']
        labels = {'cli', 'in_process'}
        if not path.startswith('/verification_outputs'):
            labels.add('cli_aliases')
        if path.startswith('/semantic_introspection'):
            labels.add('mcp_adapter')
            require(exact(entries['mcp_adapter']) == exact(native['mcp_adapter_entrypoints']), 'adapter route projection')
        require(set(entries) == labels and type(entries['cli']) is str, 'entrypoint labels/types')
        for label in labels - {'cli'}:
            require(type(entries[label]) is list and all(type(v) is str for v in entries[label]), 'entrypoint array elements')
        require('guidance' in native or path == '/semantic_introspection', 'guidance absence scope')
        if 'guidance' in native:
            require(all(type(v) is str for v in native['guidance']), 'guidance string elements')
        if role in ('manifest_discovery', 'diagnostic_registry'):
            require(entries['cli'] == './bin/fsmgen --capability-manifest', 'manifest versus report route')
        else:
            flag = {'external_validation': '--verify-hdl', 'check_report': '--check --json',
                    'normalized_semantic_report': '--emit-semantic-json'}[role]
            require(flag in entries['cli'], 'dedicated report route')
        target = PARENT + ('.2' if role != 'manifest_discovery' else '.3')
        require(row['deferred_fields'] == {k: target for k in native if k not in common}, 'complete exact deeper delegation: ' + path)
        deferred_count += len(row['deferred_fields'])
        require(row['ordering'] == 'retain observed array order; no positional priority promised', 'ordering meaning')
        require(row['extension'] == 'bounded named families; deliberate documented regression-backed widening', 'extension boundary')
    for section in ('semantic_introspection', 'support_accounting', 'verification_outputs'):
        outer, inner = rows['/' + section]['fields'], rows['/' + section + '/section_contract']['fields']
        require(all(exact(outer[k]) == exact(inner[k]) for k in common if k != 'guidance'), 'repeated identity projection')
    facets = ('universal_record_schema', 'all_statuses_bounded_public',
              'report_source_always_manifest_builder', 'entrypoints_are_mcp_tool_names',
              'absent_common_fields_are_null', 'array_priority_promised')
    require(exact(packet['facets']) == exact(dict.fromkeys(facets, False)), 'semantic boundary facets')
    require(set(packet['sources']) == expected_sources, 'complete source membership')
    for path, saved in packet['sources'].items():
        raw = saved['text'].encode()
        require(sha(raw) == saved['sha256'], 'source snapshot identity')
        original = source(capture, path)
        require(raw.split(b'\n__END__\n', 1)[0] == original.split(b'\n__END__\n', 1)[0], 'source runtime conservation: ' + path)
        if path != POD:
            require(raw == original, 'dedicated source identity: ' + path)
        if current:
            require((ROOT / path).read_bytes() == raw, 'current source stale: ' + path)
    require(set(packet['documents']) == {BOOK, POD}, 'documentation membership')
    for path, saved in packet['documents'].items():
        require(sha(saved['text'].encode()) == saved['sha256'], 'document identity')
        if current:
            require((ROOT / path).read_bytes() == saved['text'].encode(), 'current document stale')
    require(packet['sources'][POD] == packet['documents'][POD], 'POD/source join')
    for path, heading, end in ((BOOK, '### Enriched contract identity and routes\n', '\n### '),
                               (POD, '=head2 Enriched identity and routes\n', '\n=head1 ')):
        text = packet['documents'][path]['text']
        require(heading in text, 'missing operational identity guide: ' + path)
        guide = text.split(heading, 1)[1].split(end, 1)[0]
        for phrase in ('optional_when_tools_installed', 'RegressionCorpus', 'cli_aliases',
                       'mcp_adapter_entrypoints', 'guidance', 'absent', 'report_source'):
            require(phrase in guide, 'missing documented distinction: ' + phrase)
        require('not MCP tool names' in guide, 'missing MCP route boundary')
    return {'records': len(rows), 'present_identity_fields': field_count,
            'absent_identity_fields': absent_count, 'delegated_fields': deferred_count,
            'semantic_sources': len(expected_sources)}


def controls(packet, capture):
    results = {}
    for label in ('missing_record', 'extra_record', 'wrong_owner', 'wrong_route_role',
                  'wrong_status', 'borrowed_report_source', 'numeric_boolean',
                  'missing_guidance_is_null', 'invented_aliases', 'reordered_route',
                  'lost_delegation', 'false_execution', 'borrowed_source',
                  'missing_guide', 'stale_document', 'stale_builder'):
        bad = copy.deepcopy(packet)
        first = bad['records'][0]
        if label == 'missing_record':
            bad['records'].pop()
        elif label == 'extra_record':
            r = copy.deepcopy(first); r['pointer'] += '/invented'; bad['records'].append(r)
        elif label == 'wrong_owner':
            first['owner'] = bad['records'][1]['owner']
        elif label == 'wrong_route_role':
            first['route_role'] = 'manifest_discovery'
        elif label in ('wrong_status', 'borrowed_report_source', 'numeric_boolean'):
            key, value = {'wrong_status': ('status', 'bounded_public'),
                          'borrowed_report_source': ('report_source', 'FSM::Support::CapabilityManifest'),
                          'numeric_boolean': ('schema_version', True)}[label]
            first['fields'][key]['value'] = value
        elif label == 'missing_guidance_is_null':
            r = next(r for r in bad['records'] if r['pointer'] == '/semantic_introspection')
            r['fields']['guidance'] = {'present': True, 'kind': 'null', 'value': None}
        elif label == 'invented_aliases':
            r = next(r for r in bad['records'] if r['pointer'] == '/verification_outputs')
            r['fields']['entrypoints']['value']['cli_aliases'] = []
        elif label == 'reordered_route':
            first['fields']['entrypoints']['value']['in_process'].reverse()
        elif label == 'lost_delegation':
            first['deferred_fields'].pop(next(iter(first['deferred_fields'])))
        elif label == 'false_execution':
            bad['facets']['entrypoints_are_mcp_tool_names'] = True
        elif label == 'borrowed_source':
            s = bad['sources'][first['owner_source']]; s['text'] += '\n# borrowed\n'; s['sha256'] = sha(s['text'].encode())
        elif label in ('missing_guide', 'stale_document'):
            s = bad['documents'][BOOK]
            s['text'] = s['text'].replace('### Enriched contract identity and routes\n', '') if label == 'missing_guide' else s['text'] + '\n'
            s['sha256'] = sha(s['text'].encode())
        else:
            s = bad['builder']; s['text'] += '\n# stale\n'; s['sha256'] = sha(s['text'].encode())
        try:
            verify(bad, capture, current=label in ('stale_document', 'stale_builder'))
        except (ValueError, KeyError) as error:
            results[label] = str(error)
        else:
            raise ValueError('Control accepted: ' + label)
    return results


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('packet', type=Path)
    parser.add_argument('--current', action='store_true')
    args = parser.parse_args()
    packet = json.loads(gzip.decompress(args.packet.read_bytes()))
    capture = json.loads(gzip.decompress((BASE / 'model-roots-qualified.json.gz').read_bytes()))
    capture_check(capture)  # Authenticate saved observations; never execute their producers.
    result = verify(packet, capture, args.current)
    result['rejected_controls'] = controls(packet, capture)
    result['reader_source_text'] = Path(__file__).read_text()
    result['reader_source_sha256'] = sha(Path(__file__).read_bytes())
    print(json.dumps(result, sort_keys=True))


if __name__ == '__main__':
    main()

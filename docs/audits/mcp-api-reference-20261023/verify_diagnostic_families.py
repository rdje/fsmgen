#!/usr/bin/env python3
"""Independently join diagnostic family subjects, conditions, owners and docs."""
import argparse
import copy
import gzip
import hashlib
import json
import re
import sys
from pathlib import Path

from verify_error_context import source
from verify_model_roots import capture_check

ROOT = Path(__file__).resolve().parents[3]
BASE = Path(__file__).resolve().parent
BOOK = 'docs/book/src/11-extensions-and-embedding.md'
POD = 'perl/FSM/Support/CapabilityManifest.pm'
BUILDER = 'docs/audits/mcp-api-reference-20261023/build_diagnostic_families.py'
OWNER = 'PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.1'


def require(ok, why):
    if not ok:
        raise ValueError(why)


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def exact(obj):
    return json.dumps(obj, sort_keys=True, ensure_ascii=True, separators=(',', ':'))


def read(path):
    return json.loads(gzip.decompress(path.read_bytes()))


def verify(packet, capture, current=False):
    require(packet['schema'] == 'fsmgen.diagnostic_family_subjects.v1' and packet['owner'] == OWNER, 'packet identity')
    require(packet['capture'] == 'docs/audits/mcp-api-reference-20261023/model-roots-qualified.json.gz', 'capture path')
    require(packet['capture_sha256'] == sha((BASE / 'model-roots-qualified.json.gz').read_bytes())
            and packet['capture_head'] == capture['head'], 'capture identity')
    identity = read(BASE / 'enriched-identity-final.json.gz')
    require(packet['identity_sha256'] == sha((BASE / 'enriched-identity-final.json.gz').read_bytes()), 'identity predecessor')
    paths = {'/diagnostics/check_json', '/diagnostics/stable_code_registry'}
    prior = {r['pointer']: r['deferred_fields'] for r in identity['records'] if r['pointer'] in paths}
    require(packet['prior_delegation'] == prior, 'original field delegation')
    rows = {r['pointer']: r for r in packet['records']}
    require(len(rows) == len(packet['records']) and rows.keys() == paths, 'unique complete selected records')
    native = capture['native_api']['manifest']['diagnostics']
    # Independently enumerate subjects from the reviewed public report contracts.
    expected = {
        'public_top_level_presence_keys': ('check_report', 'required_both_outcomes'),
        'success_only_top_level_keys': ('check_report', 'success_only'),
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
    for subject in ('command', 'generated_output', 'producer', 'source'):
        expected[subject + '_presence_keys'] = ('check_report.' + subject, 'required_both_outcomes')
    nested_owners = {
        'command': 'ReportCommandContract', 'diagnostic_summary': 'SerializableDiagnosticSummary',
        'failure_diagnostic': 'CheckFailureDiagnosticContract', 'generated_output': 'ReportGeneratedOutputContract',
        'producer': 'ReportProducerContract', 'result': 'CheckResultContract',
        'source': 'ReportSourceContract', 'support_accounting': 'SupportAccountingMatchContract',
    }
    for key in nested_owners:
        expected[key + '_contract_source'] = ('nested_owner:' + key, 'same_named_owner_mirror')
    registry = {
        'public_sibling_keys': ('manifest.diagnostics', 'registry_siblings'),
        'entry_presence_keys': ('manifest.diagnostics.stable_codes[]', 'entry_keys'),
        'key_family_map': ('registry_key_metadata', 'same_named_mirrors'),
        'bounded_value_family_map': ('registry_value_metadata', 'same_named_mirrors'),
        'code_shape': ('stable_code_entry.code', 'code_pattern'),
    }
    for name in ('severity', 'stability', 'family'):
        registry['bounded_' + name + '_values'] = ('stable_code_entry.' + name, 'allowed_values')
    identity_keys = {'schema_version', 'status', 'contract_source', 'report_source', 'entrypoints', 'guidance'}
    source_paths = {POD, 'perl/FSM/Support/DiagnosticsSection.pm',
                    'perl/FSM/Support/CheckDiagnostics.pm', 'perl/FSM/Support/DiagnosticCodes.pm'}
    for name, table, contract in (('check_json', expected, 'CheckDiagnosticsContract'),
                                   ('stable_code_registry', registry, 'DiagnosticCodeRegistryContract')):
        path = '/diagnostics/' + name
        row, obj = rows[path], native[name]
        namespace = 'FSM::Support::' + contract
        require(row['owner'] == obj['contract_source'] == namespace, 'contract owner')
        source_paths.add('perl/FSM/Support/' + contract + '.pm')
        require(set(row['identity_fields']) == identity_keys and len(row['identity_fields']) == len(identity_keys), 'identity partition')
        require(set(row['fields']) == set(table), 'family field population: ' + name)
        for key, (subject, rule) in table.items():
            field = row['fields'][key]
            require(set(field) == {'value', 'subject', 'rule'}, 'field shape')
            require(field['subject'] == subject and field['rule'] == rule, 'subject/condition: ' + key)
            require(exact(field['value']) == exact(obj[key]), 'native complete value/type/order: ' + key)
        delegated = set(obj) - identity_keys - set(table)
        require(set(row['delegated_fields']) == delegated, 'remaining fields complete')
        require(set(prior[path]) == set(table) | delegated, 'prior field conservation')
        targets = ['PERL-POD-API-REFERENCE.6.1.2.3.2.2',
                   'PERL-POD-API-REFERENCE.6.1.2.3.3', 'PERL-POD-API-REFERENCE.6.4']
        require(all(v == targets for v in row['delegated_fields'].values()), 'exact deeper owners')
    check = native['check_json']
    require(check['nested_contract_source_map'] == {key: 'FSM::Support::' + owner for key, owner in nested_owners.items()}, 'nested owner domain')
    source_paths.update('perl/FSM/Support/' + owner + '.pm' for owner in nested_owners.values())
    require(set(check['nested_presence_key_map']) == set(nested_owners), 'nested key domain')
    for key, namespace in check['nested_contract_source_map'].items():
        require(check[key + '_contract_source'] == namespace, 'scalar owner mirror')
        family = {'result': 'success_result_presence_keys', 'failure_diagnostic': 'failure_diagnostic_presence_keys',
                  'support_accounting': 'success_support_accounting_presence_keys'}.get(key, key + '_presence_keys')
        if key != 'diagnostic_summary':
            require(exact(check['nested_presence_key_map'][key]) == exact(check[family]), 'nested key mirror')
    family_names = set(expected) - {'public_top_level_presence_keys', 'nested_contract_source_map', 'nested_presence_key_map', 'presence_key_family_map'} - {k + '_contract_source' for k in nested_owners}
    require(set(check['presence_key_family_map']) == family_names, 'check mirror domain')
    require(exact(check['presence_key_family_map']) == exact({k: check[k] for k in family_names}), 'check grouped mirrors')
    require(type(check['source_optional_fields']) is dict and set(check['source_optional_fields']) == {'interface_ports', 'reset_provenance', 'reductions'}, 'optional declaration map is not an array')
    reg = native['stable_code_registry']
    require(set(reg['public_sibling_keys']) == {'registry_source', 'stable_codes', 'stable_code_registry'}, 'registry siblings, not contract fields')
    require(set(reg['public_sibling_keys']) <= set(native), 'registry sibling placement')
    require(set(reg['entry_presence_keys']) == {'code', 'severity', 'stability', 'family', 'summary'}, 'catalog entry subject')
    for group, names in (('key_family_map', {'public_sibling_keys', 'entry_presence_keys'}),
                         ('bounded_value_family_map', {'bounded_severity_values', 'bounded_stability_values', 'bounded_family_values'})):
        require(exact(reg[group]) == exact({k: reg[k] for k in names}), 'registry grouped mirrors')
    require(reg['bounded_severity_values'] == ['error'] and reg['bounded_stability_values'] == ['stable'], 'registry allowed values')
    require(set(reg['bounded_family_values']) == {'strict_mode', 'language_contract', 'direct_generation_contract', 'composition_contract'}, 'registry family values')
    codes = native['stable_codes']
    require([x['code'] for x in codes] == sorted({x['code'] for x in codes}), 'ordered unique manifest catalog')
    for entry in codes:
        require(set(entry) == set(reg['entry_presence_keys']), 'actual catalog entry keys')
        require(re.fullmatch(reg['code_shape'], entry['code']) is not None, 'actual catalog code shape')
        for key in ('severity', 'stability', 'family'):
            require(entry[key] in reg['bounded_' + key + '_values'], 'actual catalog allowed value')
    require(set(packet['sources']) == source_paths, 'complete semantic source membership')
    for path, saved in packet['sources'].items():
        raw = saved['text'].encode()
        require(sha(raw) == saved['sha256'], 'source snapshot digest')
        original = source(capture, path)
        require(raw.split(b'\n__END__\n', 1)[0] == original.split(b'\n__END__\n', 1)[0], 'source runtime conservation: ' + path)
        if path != POD:
            require(raw == original, 'dedicated source identity: ' + path)
        if current:
            require((ROOT / path).read_bytes() == raw, 'current source stale: ' + path)
    builder = packet['builder']
    require(builder['path'] == BUILDER and sha(builder['text'].encode()) == builder['sha256'], 'builder identity')
    require(packet['python']['implementation'] and len(packet['python']['version']) == 5, 'runtime identity')
    if current:
        require((ROOT / BUILDER).read_bytes() == builder['text'].encode(), 'current builder stale')
        require(packet['python'] == {'implementation': sys.implementation.name, 'version': list(sys.version_info)}, 'current runtime stale')
    require(set(packet['documents']) == {BOOK, POD} and packet['sources'][POD] == packet['documents'][POD], 'document membership/POD join')
    for path, heading in ((BOOK, '### Diagnostic report and registry families\n'),
                           (POD, '=head2 Diagnostic report and registry families\n')):
        saved = packet['documents'][path]
        require(sha(saved['text'].encode()) == saved['sha256'], 'document snapshot digest')
        if current:
            require((ROOT / path).read_bytes() == saved['text'].encode(), 'current document stale')
        require(heading in saved['text'], 'missing family guide: ' + path)
        guide = saved['text'].split(heading, 1)[1].split('\n### ' if path == BOOK else '\n=head', 1)[0]
        for phrase in ('source_optional_fields', 'matched_success_support_accounting_presence_keys',
                       'matched_failure_diagnostic_support_accounting_presence_keys', 'nested_presence_key_map',
                       'bounded_value_family_map', 'stable_codes', 'null', 'not a closed schema'):
            require(phrase in guide, 'missing documented distinction: ' + phrase)
        if path == BOOK:
            require(all('`' + key + '`' in guide for key in expected.keys() | registry.keys()
                        if not key.endswith('_contract_source')), 'family field documentation coverage')
    return {'records': len(rows), 'qualified_family_fields': len(expected) + len(registry),
            'semantic_sources': len(source_paths)}


def controls(packet, capture):
    result = {}
    for label in ('missing_record', 'duplicate_record', 'missing_family', 'wrong_subject', 'wrong_condition',
                  'keys_are_values', 'changed_native_type', 'optional_map_is_list', 'lost_delegation',
                  'wrong_deeper_owner', 'changed_source', 'missing_guide', 'stale_document', 'stale_builder'):
        bad = copy.deepcopy(packet)
        check = next(r for r in bad['records'] if r['pointer'].endswith('/check_json'))
        reg = next(r for r in bad['records'] if r['pointer'].endswith('/stable_code_registry'))
        if label == 'missing_record':
            bad['records'].pop()
        elif label == 'duplicate_record':
            bad['records'].append(copy.deepcopy(check))
        elif label == 'missing_family':
            check['fields'].pop('source_optional_fields')
        elif label in ('wrong_subject', 'wrong_condition'):
            key = 'subject' if label == 'wrong_subject' else 'rule'
            check['fields']['matched_failure_diagnostic_presence_keys'][key] = 'check_report' if key == 'subject' else 'required_both_outcomes'
        elif label == 'keys_are_values':
            reg['fields']['bounded_family_values']['subject'] = 'manifest.diagnostics'
        elif label == 'changed_native_type':
            reg['fields']['bounded_severity_values']['value'] = 'error'
        elif label == 'optional_map_is_list':
            check['fields']['source_optional_fields']['value'] = list(check['fields']['source_optional_fields']['value'])
        elif label == 'lost_delegation':
            check['delegated_fields'].pop(next(iter(check['delegated_fields'])))
        elif label == 'wrong_deeper_owner':
            reg['delegated_fields']['registry_returns_defensive_copies'] = [OWNER]
        elif label in ('changed_source', 'missing_guide', 'stale_document', 'stale_builder'):
            saved = (bad['sources']['perl/FSM/Support/CheckDiagnosticsContract.pm'] if label == 'changed_source'
                     else bad['builder'] if label == 'stale_builder' else bad['documents'][BOOK])
            saved['text'] = saved['text'].replace('### Diagnostic report and registry families\n', '') if label == 'missing_guide' else saved['text'] + '\n# altered\n'
            saved['sha256'] = sha(saved['text'].encode())
        try:
            verify(bad, capture, current=label in ('stale_document', 'stale_builder'))
        except (ValueError, KeyError) as error:
            result[label] = str(error)
        else:
            raise ValueError('Adverse control accepted: ' + label)
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('packet', type=Path)
    parser.add_argument('--current', action='store_true')
    args = parser.parse_args()
    capture = read(BASE / 'model-roots-qualified.json.gz')
    capture_check(capture)  # Saved reader only; never restart the metadata collector.
    packet = read(args.packet)
    result = verify(packet, capture, args.current)
    result['rejected_controls'] = controls(packet, capture)
    result['reader_source_text'] = Path(__file__).read_text()
    result['reader_source_sha256'] = sha(Path(__file__).read_bytes())
    print(json.dumps(result, sort_keys=True))


if __name__ == '__main__':
    main()

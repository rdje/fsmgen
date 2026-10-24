#!/usr/bin/env python3
"""Independently join normalized-envelope subjects and source-derived root shapes."""
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
OWNER = 'PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.1'
BOOK = 'docs/book/src/11-extensions-and-embedding.md'
POD = 'perl/FSM/Support/CapabilityManifest.pm'
BUILDER = 'docs/audits/mcp-api-reference-20261023/build_normalized_envelope.py'


def require(ok, why):
    if not ok:
        raise ValueError(why)


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def exact(value):
    return json.dumps(value, sort_keys=True, ensure_ascii=True, separators=(',', ':'))


def read(name):
    return json.loads(gzip.decompress((BASE / name).read_bytes()))


def keys_from_factory(text, name):
    """Selected literal root hashes only; reject grammar drift rather than guess."""
    body = text.split('\nsub ' + name + ' {', 1)[1].split('\nsub ', 1)[0]
    literal = body.split('return {', 1)[1]
    return set(re.findall(r'^        ([a-z_][a-z0-9_]*)\s*=>', literal, re.M)), body


def verify(packet, capture, current=False):
    path = '/semantic_exports/normalized_semantic_json'
    require(packet['schema'] == 'fsmgen.normalized_envelope_families.v1' and packet['owner'] == OWNER and packet['pointer'] == path, 'packet identity')
    require(packet['capture_sha256'] == sha((BASE / 'model-roots-qualified.json.gz').read_bytes()) and packet['capture_head'] == capture['head'], 'capture identity')
    identity = read('enriched-identity-final.json.gz')
    prior = next(r['deferred_fields'] for r in identity['records'] if r['pointer'] == path)
    require(packet['identity_sha256'] == sha((BASE / 'enriched-identity-final.json.gz').read_bytes()) and packet['prior_fields'] == prior, 'prior exact delegation')
    native = capture['native_api']['manifest']['semantic_exports']['normalized_semantic_json']
    expected = {
        'public_top_level_presence_keys': ('normalized_report', 'both_outcomes'),
        'success_only_top_level_keys': ('normalized_report', 'success_only'),
        'source_optional_fields': ('normalized_report.source', 'optional_success_declarations'),
        'producer_extra_presence_keys': ('normalized_report.producer', 'additive_both_outcomes'),
        'support_accounting_presence_keys': ('normalized_report.support_accounting', 'both_outcomes'),
        'matched_success_support_accounting_presence_keys': ('normalized_report.support_accounting', 'matched_success_additions'),
        'matched_failure_support_accounting_presence_keys': ('normalized_report.support_accounting', 'matched_failure_additions'),
        'failure_diagnostic_presence_keys': ('normalized_report.diagnostics[]', 'failure_element'),
        'matched_failure_diagnostic_presence_keys': ('normalized_report.diagnostics[]', 'matched_failure_additions'),
        'failure_diagnostic_optional_artifact_keys': ('normalized_report.diagnostics[]', 'optional_artifact'),
        'failure_diagnostic_support_accounting_presence_keys': ('normalized_report.diagnostics[].support_accounting', 'failure_element'),
        'matched_failure_diagnostic_support_accounting_presence_keys': ('normalized_report.diagnostics[].support_accounting', 'matched_failure_additions'),
    }
    for name in ('command', 'producer', 'source', 'generated_output'):
        expected[name + '_presence_keys'] = ('normalized_report.' + name, 'both_outcomes')
    owners = {'command': 'ReportCommandContract', 'producer': 'ReportProducerContract',
              'source': 'ReportSourceContract', 'generated_output': 'ReportGeneratedOutputContract',
              'support_accounting': 'SupportAccountingMatchContract', 'failure_diagnostic': 'CheckFailureDiagnosticContract',
              'diagnostic_summary': 'SerializableDiagnosticSummary', 'generation_result_snapshot': 'SerializableGenerationResultSnapshot'}
    for name in owners:
        expected[name + '_contract_source'] = ('nested_owner:' + name, 'dedicated_owner_identity')
    require(set(packet['fields']) == set(expected), 'complete selected field population')
    for name, (subject, condition) in expected.items():
        row = packet['fields'][name]
        require(set(row) == {'value', 'subject', 'condition'}, 'field shape')
        require(row['subject'] == subject and row['condition'] == condition, 'subject/condition: ' + name)
        require(exact(row['value']) == exact(native[name]), 'complete native value/type/order: ' + name)
    remaining = set(prior) - set(expected)
    targets = [OWNER.rsplit('.', 1)[0] + '.8', 'PERL-POD-API-REFERENCE.6.1.2.3.2.3',
               'PERL-POD-API-REFERENCE.6.1.2.3.3', 'PERL-POD-API-REFERENCE.6.4']
    require(packet['remaining_fields'] == {key: targets for key in remaining}, 'complete remaining field/deeper ownership')
    paths = {POD, 'perl/FSM/Support/NormalizedSemanticReportContract.pm',
             'perl/FSM/Support/NormalizedSemanticReport.pm', 'perl/FSM/Support/CheckDiagnostics.pm'}
    for name, owner in owners.items():
        require(native[name + '_contract_source'] == 'FSM::Support::' + owner, 'dedicated shared owner')
        paths.add('perl/FSM/Support/' + owner + '.pm')
    require(set(packet['sources']) == paths, 'complete semantic source membership')
    for filename, saved in packet['sources'].items():
        raw = saved['text'].encode()
        require(sha(raw) == saved['sha256'], 'source snapshot digest')
        original = source(capture, filename)
        require(raw.split(b'\n__END__\n', 1)[0] == original.split(b'\n__END__\n', 1)[0], 'source runtime conservation: ' + filename)
        if filename != POD:
            require(raw == original, 'dedicated source identity')
        if current:
            require((ROOT / filename).read_bytes() == raw, 'current source stale')
    text = packet['sources']['perl/FSM/Support/NormalizedSemanticReport.pm']['text']
    success, success_body = keys_from_factory(text, 'build_normalized_semantic_success_report')
    failure, failure_body = keys_from_factory(text, 'build_normalized_semantic_failure_report')
    require(failure == set(native['public_top_level_presence_keys']), 'source-derived failure root')
    require(success == failure | set(native['success_only_top_level_keys']), 'source-derived success additions')
    require(set(native['success_only_top_level_keys']) == {'semantic', 'generation_result_snapshot'}, 'success-only subject, not check result')
    producer, _ = keys_from_factory(text, '_producer_contract')
    require(producer == set(native['producer_presence_keys']) | set(native['producer_extra_presence_keys']), 'source-derived producer keys')
    command, _ = keys_from_factory(text, '_command_contract')
    require(command == set(native['command_presence_keys']), 'source-derived command keys')
    base_source, _ = keys_from_factory(text, '_source_contract')
    require(base_source == set(native['source_presence_keys']), 'source-derived base source keys')
    require('include_isf_declarations => 1' in success_body and 'include_isf_declarations => 1' not in failure_body, 'optional source success condition')
    require('support_accounting => $support_accounting' in failure_body and '$diagnostics->[0]{support_accounting}' in failure_body, 'source-derived report/diagnostic failure bridge')
    require(native['support_accounting_presence_keys'] == ['matched'] and native['producer_extra_presence_keys'] == ['semantic_layers'], 'shared base/producer extension')
    require(native['matched_failure_support_accounting_presence_keys'] == native['matched_failure_diagnostic_support_accounting_presence_keys'], 'matched failure family mirror')
    require(type(native['source_optional_fields']) is dict, 'optional declarations are an object')
    builder = packet['builder']
    require(builder['path'] == BUILDER and sha(builder['text'].encode()) == builder['sha256'], 'builder identity')
    helper = 'docs/audits/mcp-api-reference-20261023/build_diagnostic_families.py'
    require(set(packet['helpers']) == {helper}, 'producer helper closure')
    require(packet['helpers'][helper] == {key: read('diagnostic-families-qualified.json.gz')['builder'][key] for key in ('text', 'sha256')}, 'qualified helper identity')
    if current:
        require((ROOT / BUILDER).read_text() == builder['text'] and (ROOT / helper).read_text() == packet['helpers'][helper]['text'], 'current producer stale')
        require(packet['python'] == {'implementation': sys.implementation.name, 'version': list(sys.version_info)}, 'current runtime stale')
    require(set(packet['documents']) == {BOOK, POD} and packet['documents'][POD] == packet['sources'][POD], 'document/POD membership')
    for filename, marker in ((BOOK, '### Normalized report-envelope families\n'), (POD, '=head2 Normalized report-envelope families\n')):
        saved = packet['documents'][filename]
        require(sha(saved['text'].encode()) == saved['sha256'], 'document digest')
        if current:
            require((ROOT / filename).read_text() == saved['text'], 'current document stale')
        require(marker in saved['text'], 'missing normalized envelope guide')
        guide = saved['text'].split(marker, 1)[1].split('\n### ' if filename == BOOK else '\n=head', 1)[0]
        for phrase in ('generation_result_snapshot', 'semantic_layers', 'matched_failure_support_accounting_presence_keys',
                       'source_optional_fields', 'report-level', 'success-only', 'not a closed schema'):
            require(phrase.casefold() in guide.casefold(), 'missing documented distinction: ' + phrase)
        if filename == BOOK:
            require(all('`' + name + '`' in guide for name in expected if not name.endswith('_contract_source')), 'family documentation coverage')
    return {'selected_fields': len(expected), 'remaining_fields': len(remaining),
            'source_derived_success_keys': sorted(success), 'source_derived_failure_keys': sorted(failure)}


def controls(packet, capture):
    results = {}
    for label in ('missing_field', 'wrong_subject', 'success_fields_on_failure', 'check_result_borrowed',
                  'wrong_failure_match', 'optional_array', 'lost_remaining', 'wrong_owner',
                  'changed_source', 'changed_helper', 'missing_guide', 'stale_document'):
        bad = copy.deepcopy(packet)
        if label == 'missing_field':
            bad['fields'].pop('producer_extra_presence_keys')
        elif label == 'wrong_subject':
            bad['fields']['matched_failure_support_accounting_presence_keys']['subject'] = 'normalized_report.diagnostics[]'
        elif label == 'success_fields_on_failure':
            bad['fields']['success_only_top_level_keys']['condition'] = 'both_outcomes'
        elif label == 'check_result_borrowed':
            bad['fields']['success_only_top_level_keys']['value'] = ['result', 'support_accounting']
        elif label == 'wrong_failure_match':
            bad['fields']['matched_failure_support_accounting_presence_keys']['value'] = bad['fields']['matched_success_support_accounting_presence_keys']['value']
        elif label == 'optional_array':
            bad['fields']['source_optional_fields']['value'] = list(bad['fields']['source_optional_fields']['value'])
        elif label == 'lost_remaining':
            bad['remaining_fields'].pop(next(iter(bad['remaining_fields'])))
        elif label == 'wrong_owner':
            bad['fields']['generation_result_snapshot_contract_source']['value'] = 'FSM::Support::CheckResultContract'
        else:
            saved = (bad['sources']['perl/FSM/Support/NormalizedSemanticReport.pm'] if label == 'changed_source' else
                     next(iter(bad['helpers'].values())) if label == 'changed_helper' else bad['documents'][BOOK])
            saved['text'] = saved['text'].replace('### Normalized report-envelope families\n', '') if label == 'missing_guide' else saved['text'] + '\n# changed\n'
            saved['sha256'] = sha(saved['text'].encode())
        try:
            verify(bad, capture, current=label == 'stale_document')
        except (ValueError, KeyError) as error:
            results[label] = str(error)
        else:
            raise ValueError('Adverse control accepted: ' + label)
    return results


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('packet', type=Path)
    parser.add_argument('--current', action='store_true')
    args = parser.parse_args()
    capture = read('model-roots-qualified.json.gz')
    capture_check(capture)
    packet = json.loads(gzip.decompress(args.packet.read_bytes()))
    result = verify(packet, capture, args.current)
    result['rejected_controls'] = controls(packet, capture)
    result['reader_source'] = Path(__file__).read_text()
    result['reader_sha256'] = sha(Path(__file__).read_bytes())
    print(json.dumps(result, sort_keys=True))


if __name__ == '__main__':
    main()

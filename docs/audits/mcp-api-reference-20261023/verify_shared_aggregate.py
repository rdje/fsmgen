#!/usr/bin/env python3
"""Independently qualify aggregate-enable and distinct assertion subjects."""
import argparse
import copy
import gzip
import json
from pathlib import Path
import re
import sys

from verify_shared_drive import verify as verify_drive
from verify_composition_shallow import TableView, literal
from verify_composition_dt import code
from verify_error_context import source
from verify_model_roots import capture_check
from verify_normalized_symbols import body, returns
from verify_normalized_envelope import exact, require, sha

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
OWNER = 'PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.5.4'
BOOK = 'docs/book/src/11a-perl-api-reference.md'
POD = 'perl/FSM/Support/CapabilityManifest.pm'
MARKER = 'Normalized shared-datapath aggregate and assertion subjects'
CONTEXTS = {
    'composition_shared_datapath_': 'semantic.composition.shared_datapath_candidates[]',
    'success_forward_ir_lowered_rtl_ir_composition_shared_datapath_': 'semantic.forward_ir.lowered_rtl_ir.composition_shared_datapath_candidates[]'}
ORACLE = {
    'aggregate_enable_family_entry_keys': (['.aggregate_enable_families[]'], 'array_element',
        ['rhs_value', 'aggregate_enable_signal', 'same_value_conflict_signal', 'same_value_assertion', 'contributor_count', 'contributors']),
    'aggregate_enable_contributor_entry_keys': (['.aggregate_enable_families[].contributors[]'], 'array_element',
        ['endpoint', 'family_enable_signal', 'source_enable_signal', 'driver_blocks', 'driver_enable_signals']),
    'assertion_keys': (['.multi_value_assertion', '.aggregate_enable_families[].same_value_assertion'], 'object',
        ['input_count', 'input_enable_signals', 'kind', 'result_signal'])}


def read(name):
    return json.loads(gzip.decompress((BASE / name).read_bytes()))


def verify(packet, capture, current=False, contracts_current=False):
    require(packet['schema'] == 'fsmgen.shared_aggregate.v1' and packet['owner'] == OWNER, 'aggregate identity')
    previous = read('shared-drive-final-qualified.json.gz')
    verify_drive(previous, capture)  # Dated predecessor; no false current-guide claim.
    partition = read('shared-datapath-partition.json.gz')
    require(packet['inputs'] == {name: sha((BASE / name).read_bytes()) for name in
        ('shared-datapath-partition.json.gz', 'shared-drive-final-qualified.json.gz')}, 'aggregate input identities')
    selected = {prefix + suffix for prefix in CONTEXTS for suffix in ORACLE}
    require(set(packet['fields']) == selected == set(partition['cohorts'][OWNER])
            == set(previous['remaining_shared']), 'all and only final shared fields')
    require(packet['remaining_shared'] == {}, 'no omitted final shared field')
    require(exact(packet['remaining_fields']) == exact(previous['remaining_fields']), 'all deeper owners conserved')
    paths = set(previous['sources']) | {'perl/FSM/Composition/SharedDatapathSupport.pm'}
    require(set(packet['sources']) == paths, 'complete aggregate source population')
    texts = {}
    for path, saved in packet['sources'].items():
        raw = saved['text'].encode()
        require(sha(raw) == saved['sha256'], 'aggregate source digest')
        require(code(raw) == code(source(capture, path)), 'original aggregate runtime source')
        if path != POD:
            require(raw == source(capture, path), 'exact dedicated aggregate source')
        if current:
            require((ROOT / path).read_bytes() == raw, 'current aggregate source stale')
        elif contracts_current:
            require(code((ROOT / path).read_bytes()) == code(raw), 'current aggregate contract/builder stale')
        texts[Path(path).stem] = saved['text']
    native = capture['native_api']['manifest']['semantic_exports']['normalized_semantic_json']
    for prefix, root in CONTEXTS.items():
        for suffix, (relatives, rule, keys) in ORACLE.items():
            key = prefix + suffix
            row = packet['fields'][key]
            require(set(row) == {'subjects', 'rule', 'value', 'value_owner', 'alias_owner'}, 'exact aggregate record shape')
            require(row['subjects'] == [root + relative for relative in relatives] and row['rule'] == rule, 'exact aggregate/assertion subjects and containers')
            alias = 'LoweredRTLIRContract' if prefix.startswith('success_') else 'CompositionContract'
            require(row['value_owner'] == 'FSM::Support::NormalizedSemanticLoweredRTLIRContract'
                    and row['alias_owner'] == 'FSM::Support::NormalizedSemantic' + alias, 'exact aggregate owners')
            require(exact(row['value']) == exact(native[key]) == exact(keys), 'aggregate native value/type/order')
            lower = 'normalized_semantic_lowered_rtl_ir_composition_shared_datapath_' + suffix
            require(literal(texts['NormalizedSemanticLoweredRTLIRContract'], lower) == keys, 'aggregate dedicated literal')
            report = 'normalized_semantic_' + key.removeprefix('success_')
            payload = 'normalized_semantic_payload_' + key.removeprefix('success_')
            returns(texts['NormalizedSemanticReportContract'], report, payload)
            returns(texts['NormalizedSemanticPayloadContract'], payload, report)
            returns(texts['NormalizedSemanticForwardIRContract' if prefix.startswith('success_') else 'NormalizedSemanticCompositionContract'], report, lower)
            factory = body(texts['NormalizedSemanticReportContract'], 'build_normalized_semantic_report_contract')
            require(re.search(r'\b' + re.escape(key) + r'\s*=>\s*' + re.escape(report) + r'\(\)', factory), 'aggregate report allocation')
    require('%{build_normalized_semantic_report_contract()}' in texts['SemanticExportsSection'], 'aggregate manifest republishing')
    builder = texts['SharedDatapathCandidateBuilder']
    require('next unless ref($rhs_family) eq \'HASH\';' in builder
            and 'next unless defined $rhs_value;' in builder
            and '} sort keys %aggregate_families_by_rhs;' in builder, 'conditional aggregate families and deterministic RHS order')
    same = re.search(r'same_value_assertion\s*=>\s*FSM::Composition::SharedDatapathSupport->assertion_metadata\(\s*\$same_value_conflict_signal,\s*\[\s*map\s*\{\s*\$_->\{source_enable_signal\}\s*\}\s*@\{\$family->\{contributors\} \|\| \[\]\}', builder)
    multi = re.search(r'multi_value_assertion\s*=>\s*FSM::Composition::SharedDatapathSupport->assertion_metadata\(\s*\$multi_value_conflict_signal,\s*\[\s*map\s*\{\s*\$_->\{aggregate_enable_signal\}\s*\}\s*@aggregate_enable_families', builder)
    require(same is not None and multi is not None, 'distinct source-enable versus aggregate-enable assertion inputs')
    support = texts['SharedDatapathSupport'].split('\nsub assertion_metadata ', 1)[1].split('\nsub ', 1)[0]
    require("kind => 'onehot0'" in support and 'defined($_) && length($_)' in support
            and 'input_count => scalar(@inputs)' in support and 'input_enable_signals => \\@inputs' in support
            and 'result_signal => $result_signal' in support, 'bounded onehot0 metadata and filtered input construction')
    for text in ('aggregate_enable_family_count => scalar(@aggregate_enable_families)',
                 'aggregate_enable_families => \\@aggregate_enable_families',
                 'contributor_count => scalar(@{$family->{contributors} || []})',
                 'contributors => $family->{contributors}'):
        require(text in builder, 'aggregate array/count projection')
    require(set(packet['documents']) == {BOOK, POD} and packet['documents'][POD] == packet['sources'][POD], 'aggregate document population')
    for path, saved in packet['documents'].items():
        require(sha(saved['text'].encode()) == saved['sha256'], 'aggregate document digest')
        if current:
            require((ROOT / path).read_text() == saved['text'], 'current aggregate document stale')
        marker = ('### ' if path == BOOK else '=head2 ') + MARKER + '\n'
        require(marker in saved['text'], 'missing aggregate/assertion guide')
        guide = saved['text'].split(marker, 1)[1].split('\n### ' if path == BOOK else '\n=head', 1)[0]
        for phrase in ('multi_value_assertion', 'same_value_assertion', 'source_enable_signal',
                       'aggregate_enable_signal', 'onehot0', 'input_enable_signals',
                       'empty', 'deeper', 'source availability', 'execution', 'arbitration'):
            require(phrase in guide, 'missing aggregate interpretation: ' + phrase)
        if path == BOOK:
            for prefix, root in CONTEXTS.items():
                require('| `' + prefix + '` | `' + root + '` |' in guide, 'documented aggregate root/lowered context')
            for suffix, (relatives, rule, keys) in ORACLE.items():
                subjects = '; '.join('`' + relative[1:] + '`' for relative in relatives)
                require('| `' + suffix + '` | ' + subjects + ' | `' + rule + '` | '
                        + ', '.join('`' + key + '`' for key in keys) + ' |' in guide, 'documented aggregate subject/type/value')
    expected = {BASE.relative_to(ROOT).as_posix() + '/' + name for name in
                ('build_shared_aggregate.py', 'verify_shared_aggregate.py')}
    require(set(packet['instruments']) == expected, 'aggregate instrument population')
    for path, saved in packet['instruments'].items():
        require(sha(saved['text'].encode()) == saved['sha256'] and (ROOT / path).read_text() == saved['text'], 'aggregate instrument identity')
    if current:
        require(packet['python'] == {'implementation': sys.implementation.name, 'version': list(sys.version_info)}, 'aggregate current runtime stale')
    return {'selected_fields': len(selected), 'remaining_shared': 0,
            'remaining_fields': len(packet['remaining_fields']), 'limits': packet['limits']}


def controls(packet, capture):
    results = {}
    key = 'composition_shared_datapath_assertion_keys'
    for label in ('omission', 'extra', 'wrong_tier', 'lost_assertion_context', 'assertion_array',
                  'family_object', 'wrong_owner', 'wrong_value_order', 'lost_deeper',
                  'wrong_same_value_inputs', 'wrong_kind', 'missing_guide', 'stale_document', 'instrument_change'):
        bad = copy.deepcopy(packet)
        if label == 'omission': bad['fields'].pop(key)
        elif label == 'extra': bad['fields']['invented'] = bad['fields'][key]
        elif label == 'wrong_tier': bad['fields'][key]['subjects'][0] = 'semantic.forward_ir.intent_hir.multi_value_assertion'
        elif label == 'lost_assertion_context': bad['fields'][key]['subjects'].pop()
        elif label == 'assertion_array': bad['fields'][key]['rule'] = 'array_element'
        elif label == 'family_object': bad['fields']['composition_shared_datapath_aggregate_enable_family_entry_keys']['rule'] = 'object'
        elif label == 'wrong_owner': bad['fields'][key]['value_owner'] = 'FSM::Support::NormalizedSemanticIntentHIRContract'
        elif label == 'wrong_value_order': bad['fields'][key]['value'].reverse()
        elif label == 'lost_deeper': bad['remaining_fields'].pop(next(iter(bad['remaining_fields'])))
        else:
            if label in ('wrong_same_value_inputs', 'wrong_kind'):
                path = 'perl/FSM/Composition/' + ('SharedDatapathCandidateBuilder.pm' if label == 'wrong_same_value_inputs' else 'SharedDatapathSupport.pm')
                saved = bad['sources'][path]
                saved['text'] = saved['text'].replace('$_->{source_enable_signal}', '$_->{aggregate_enable_signal}', 1) if label == 'wrong_same_value_inputs' else saved['text'].replace("kind => 'onehot0'", "kind => 'compatible_fanin'", 1)
            elif label == 'instrument_change':
                saved = next(iter(bad['instruments'].values())); saved['text'] += '\n# changed\n'
            else:
                saved = bad['documents'][BOOK]
                saved['text'] = saved['text'].replace('### ' + MARKER + '\n', '', 1) if label == 'missing_guide' else saved['text'] + '\nchanged\n'
            saved['sha256'] = sha(saved['text'].encode())
        try:
            verify(bad, capture, current=label == 'stale_document')
        except ValueError as error:
            results[label] = str(error)
        else:
            raise ValueError('Accepted aggregate counterfeit: ' + label)
    return results


class AggregateView(TableView):
    def handle_starttag(self, tag, attrs):
        if tag in ('h2', 'h3'):
            self.active = dict(attrs).get('id') == 'normalized-shared-datapath-aggregate-and-assertion-subjects'
        else:
            super().handle_starttag(tag, attrs)


def rendered(build):
    book = (build / '11a-perl-api-reference.html').read_bytes()
    pod = (build / 'perl-api/FSM/Support/CapabilityManifest.html').read_bytes()
    view = AggregateView(); view.feed(book.decode())
    require(view.rows[1:3] == [[prefix, root] for prefix, root in CONTEXTS.items()], 'native aggregate contexts')
    require(view.rows[4:] == [[suffix, '; '.join(relative[1:] for relative in relatives), rule, ', '.join(keys)]
                            for suffix, (relatives, rule, keys) in ORACLE.items()], 'native complete aggregate subject/value table')
    require(MARKER.encode() in pod and b'onehot0' in pod and b'source_enable_signal' in pod, 'native aggregate POD guide')
    return {'book_sha256': sha(book), 'pod_sha256': sha(pod), 'rows': view.rows,
            'scope': 'Selected actual canonical table/POD content only; broad visual signoff remains owned.'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('packet', type=Path)
    modes = parser.add_mutually_exclusive_group()
    modes.add_argument('--current', action='store_true')
    modes.add_argument('--current-contracts', action='store_true')
    parser.add_argument('--build', type=Path)
    args = parser.parse_args()
    capture = read('model-roots-qualified.json.gz'); capture_check(capture)
    packet = json.loads(gzip.decompress(args.packet.read_bytes()))
    result = verify(packet, capture, args.current, args.current_contracts)
    result['rejected_controls'] = controls(packet, capture)
    if args.build:
        result['rendered'] = rendered(args.build)
    print(json.dumps(result, sort_keys=True))


if __name__ == '__main__':
    main()

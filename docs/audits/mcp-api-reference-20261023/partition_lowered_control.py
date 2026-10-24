#!/usr/bin/env python3
"""Allocate retained lowered drive/control fields without a new source epoch."""
import argparse
import copy
import gzip
import json
from pathlib import Path

from verify_shared_closure import verify as verify_predecessor
from verify_model_roots import capture_check
from verify_error_context import source
from verify_composition_shallow import literal
from verify_normalized_envelope import exact, require, sha

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
OWNER = 'PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.6'
PREFIX = 'success_forward_ir_lowered_rtl_ir_'
INPUTS = ('shared-closure-qualified.json.gz', 'model-roots-qualified.json.gz')
TARGET = BASE / 'lowered-control-partition.json.gz'


def read(name):
    return json.loads(gzip.decompress((BASE / name).read_bytes()))


def cohorts():
    # Explicit reviewed suffixes are independent of the remaining prefix census.
    groups = {
        '.2': ('output_drive_family_entry_keys', 'output_drive_rhs_enable_family_entry_keys'),
        '.3': ('selector_conflict_target_entry_keys', 'selector_conflict_rhs_enable_family_entry_keys',
               'selector_conflict_multi_value_assertion_keys', 'selector_conflict_same_value_assertion_keys'),
        '.4': ('standalone_dt_multi_drive_target_entry_keys', 'standalone_dt_multi_drive_assertion_keys')}
    return {OWNER + child: sorted(PREFIX + suffix for suffix in suffixes) for child, suffixes in groups.items()}


def verify(packet):
    require(packet['schema'] == 'fsmgen.lowered_control_partition.v1' and packet['owner'] == OWNER + '.1', 'partition identity')
    require(packet['inputs'] == {name: sha((BASE / name).read_bytes()) for name in INPUTS}, 'partition input identity')
    previous, capture = (read(name) for name in INPUTS)
    verify_predecessor(previous, capture)  # Dated source/doc qualification, never current-guide relabeling.
    selected = {key for key in previous['remaining_fields'] if key.startswith(PREFIX)}
    expected = cohorts()
    members = [key for values in expected.values() for key in values]
    require(packet['cohorts'] == expected, 'exact independent guide allocation')
    require(len(members) == len(set(members)) and set(members) == selected, 'complete disjoint lowered population')
    native = capture['native_api']['manifest']['semantic_exports']['normalized_semantic_json']
    require(exact(packet['selected_values']) == exact({key: native[key] for key in selected}), 'original native value/type/order conservation')
    lower = source(capture, 'perl/FSM/Support/NormalizedSemanticLoweredRTLIRContract.pm').decode()
    for key in selected:
        function = 'normalized_semantic_lowered_rtl_ir_' + key.removeprefix(PREFIX)
        require(literal(lower, function) == packet['selected_values'][key], 'dedicated original literal join')
    require(exact(packet['remaining_fields']) == exact({key: value for key, value in previous['remaining_fields'].items() if key not in selected}), 'complete unselected/deeper delegation')
    require(packet['join_owner'] == OWNER + '.5', 'final current-source guide join owner')
    require(packet['instrument'] == {'path': Path(__file__).relative_to(ROOT).as_posix(),
        'text': Path(__file__).read_text(), 'sha256': sha(Path(__file__).read_bytes())}, 'partition instrument identity')
    return {'selected_fields': len(selected), 'cohort_fields': {key: len(value) for key, value in expected.items()},
        'remaining_fields': len(packet['remaining_fields']), 'limits': packet['limits']}


def controls(packet):
    refusals = {}
    for label in ('omission', 'duplicate', 'misallocation', 'wrong_value_order',
                  'lost_deeper', 'wrong_join_owner', 'input_identity', 'instrument_change'):
        bad = copy.deepcopy(packet)
        if label == 'omission': bad['cohorts'][OWNER + '.2'].pop()
        elif label == 'duplicate': bad['cohorts'][OWNER + '.3'].append(bad['cohorts'][OWNER + '.2'][0])
        elif label == 'misallocation': bad['cohorts'][OWNER + '.3'].append(bad['cohorts'][OWNER + '.2'].pop())
        elif label == 'wrong_value_order': bad['selected_values'][PREFIX + 'output_drive_family_entry_keys'].reverse()
        elif label == 'lost_deeper': bad['remaining_fields'].pop(next(iter(bad['remaining_fields'])))
        elif label == 'wrong_join_owner': bad['join_owner'] = OWNER + '.4'
        elif label == 'input_identity': bad['inputs'][INPUTS[0]] = '0' * 64
        else:
            bad['instrument']['text'] += '\n# changed\n'
            bad['instrument']['sha256'] = sha(bad['instrument']['text'].encode())
        try:
            verify(bad)
        except ValueError as error:
            refusals[label] = str(error)
        else:
            raise ValueError('Accepted lowered partition counterfeit: ' + label)
    return refusals


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    capture_check(read(INPUTS[1]))
    if args.write:
        require(not TARGET.exists(), 'Refusing to overwrite retained lowered partition')
        previous = read(INPUTS[0])
        native = read(INPUTS[1])['native_api']['manifest']['semantic_exports']['normalized_semantic_json']
        groups = cohorts()
        selected = {key for values in groups.values() for key in values}
        packet = {'schema': 'fsmgen.lowered_control_partition.v1', 'owner': OWNER + '.1',
            'inputs': {name: sha((BASE / name).read_bytes()) for name in INPUTS},
            'cohorts': groups, 'selected_values': {key: native[key] for key in sorted(selected)},
            'remaining_fields': {key: value for key, value in previous['remaining_fields'].items() if key not in selected},
            'join_owner': OWNER + '.5',
            'instrument': {'path': Path(__file__).relative_to(ROOT).as_posix(),
                'text': Path(__file__).read_text(), 'sha256': sha(Path(__file__).read_bytes())},
            'evidence_legs': {
                'rederive': 'Complete original remaining-field prefix census, native values and dedicated literal-source join.',
                'falsify': 'Independently enumerated suffix allocation plus omission/duplication/misallocation/value/deeper/owner/input/instrument refusals.',
                'durability': 'Original input identities, complete selected/remaining values, exact instrument and reproducible saved-only predecessor qualification.'},
            'limits': 'Task/metadata allocation only. Output pulse cases, selector policy, standalone-DT assertions, optional/deeper models, source availability and hardware execution remain with their guide/model/runtime owners.'}
        verify(packet)
        TARGET.write_bytes(gzip.compress((json.dumps(packet, sort_keys=True, indent=2) + '\n').encode(), mtime=0))
    packet = read(TARGET.name)
    result = verify(packet)
    result['rejected_controls'] = controls(packet)
    print(json.dumps(result, sort_keys=True))


if __name__ == '__main__':
    main()

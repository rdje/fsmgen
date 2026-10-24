#!/usr/bin/env python3
"""Partition retained shared-datapath fields without running original producers."""
import argparse
import copy
import gzip
import json
from pathlib import Path

from verify_composition_closure import verify as verify_predecessor
from verify_model_roots import capture_check
from verify_normalized_envelope import exact, require, sha

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
OWNER = 'PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.5'
INPUTS = ('composition-final-qualified.json.gz', 'model-roots-qualified.json.gz')
TARGET = BASE / 'shared-datapath-partition.json.gz'
PREFIXES = ('composition_shared_datapath_', 'success_forward_ir_lowered_rtl_ir_composition_shared_datapath_')


def read(name):
    return json.loads(gzip.decompress((BASE / name).read_bytes()))


def cohorts():
    # This explicit allocation is reviewed separately from the prefix census.
    groups = {
        '.2': ('candidate_entry_keys', 'candidate_declared_type_extension_keys',
               'candidate_contributor_entry_keys', 'candidate_contributor_declared_type_extension_keys'),
        '.3': ('bound_connection_expr_keys', 'candidate_contributor_drive_intent_entry_keys',
               'candidate_contributor_drive_intent_rhs_enable_family_entry_keys'),
        '.4': ('aggregate_enable_family_entry_keys', 'aggregate_enable_contributor_entry_keys', 'assertion_keys')}
    return {OWNER + child: sorted(prefix + suffix for prefix in PREFIXES for suffix in suffixes)
            for child, suffixes in groups.items()}


def verify(packet):
    require(packet['schema'] == 'fsmgen.shared_datapath_partition.v1' and packet['owner'] == OWNER + '.1', 'partition identity')
    require(packet['inputs'] == {name: sha((BASE / name).read_bytes()) for name in INPUTS}, 'input identity')
    previous = read(INPUTS[0])
    capture = read(INPUTS[1])
    verify_predecessor(previous, capture)
    native = capture['native_api']['manifest']['semantic_exports']['normalized_semantic_json']
    selected = {key for key in previous['remaining_fields'] if key.startswith(PREFIXES)}
    expected = cohorts()
    members = [key for values in expected.values() for key in values]
    require(packet['cohorts'] == expected, 'exact separate cohort allocation')
    require(len(members) == len(set(members)) and set(members) == selected, 'disjoint complete shared population')
    require(exact(packet['selected_values']) == exact({key: native[key] for key in selected}), 'complete native value/type/order')
    require(exact(packet['remaining_fields']) == exact({key: value for key, value in previous['remaining_fields'].items() if key not in selected}), 'remaining delegation conservation')
    require(packet['join_owner'] == OWNER + '.5', 'final current-source join owner')
    require(packet['instrument'] == {'path': Path(__file__).relative_to(ROOT).as_posix(),
        'text': Path(__file__).read_text(), 'sha256': sha(Path(__file__).read_bytes())}, 'instrument identity')
    return {'cohort_fields': {key: len(value) for key, value in expected.items()},
            'selected_fields': len(selected), 'remaining_fields': len(packet['remaining_fields']), 'limits': packet['limits']}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    capture_check(read(INPUTS[1]))
    if args.write:
        require(not TARGET.exists(), 'Refusing to overwrite retained partition')
        previous = read(INPUTS[0])
        native = read(INPUTS[1])['native_api']['manifest']['semantic_exports']['normalized_semantic_json']
        groups = cohorts()
        selected = {key for values in groups.values() for key in values}
        packet = {'schema': 'fsmgen.shared_datapath_partition.v1', 'owner': OWNER + '.1',
            'inputs': {name: sha((BASE / name).read_bytes()) for name in INPUTS},
            'cohorts': groups, 'selected_values': {key: native[key] for key in sorted(selected)},
            'remaining_fields': {key: value for key, value in previous['remaining_fields'].items() if key not in selected},
            'join_owner': OWNER + '.5',
            'instrument': {'path': Path(__file__).relative_to(ROOT).as_posix(),
                'text': Path(__file__).read_text(), 'sha256': sha(Path(__file__).read_bytes())},
            'evidence_legs': {
                'rederive': 'Project original native values and unselected delegations from the complete qualified composition predecessor.',
                'falsify': 'Compare independently enumerated suffix cohorts with a complete prefix census; reject omitted/misallocated fields, wrong values/order, lost delegation and wrong closure ownership.',
                'durability': 'Track original input hashes, complete selected/remaining values, exact instrument source and replayable controls.'},
            'limits': 'Task partition only; no shared-datapath subject/model/source/execution qualification closes here.'}
        verify(packet)
        TARGET.write_bytes(gzip.compress((json.dumps(packet, sort_keys=True, indent=2) + '\n').encode(), mtime=0))
    packet = read(TARGET.name)
    result = verify(packet)
    controls = {}
    for label in ('missing_field', 'misallocated_field', 'wrong_value_order', 'lost_remaining', 'wrong_join_owner'):
        bad = copy.deepcopy(packet)
        if label == 'missing_field':
            bad['cohorts'][OWNER + '.2'].pop()
        elif label == 'misallocated_field':
            bad['cohorts'][OWNER + '.3'].append(bad['cohorts'][OWNER + '.2'].pop())
        elif label == 'wrong_value_order':
            bad['selected_values']['composition_shared_datapath_candidate_entry_keys'].reverse()
        elif label == 'lost_remaining':
            bad['remaining_fields'].pop(next(iter(bad['remaining_fields'])))
        else:
            bad['join_owner'] = OWNER + '.4'
        try:
            verify(bad)
        except ValueError as error:
            controls[label] = str(error)
        else:
            raise ValueError('Accepted counterfeit: ' + label)
    result['rejected_controls'] = controls
    print(json.dumps(result, sort_keys=True))


if __name__ == '__main__':
    main()

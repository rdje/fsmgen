#!/usr/bin/env python3
"""Prove exact composition cohorts before implementing their separate guides."""
import argparse
import copy
import gzip
import hashlib
import json
from pathlib import Path

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
OWNER = 'PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.4'
SOURCE = BASE / 'normalized-symbols-final-qualified.json.gz'
NATIVE = BASE / 'model-roots-qualified.json.gz'
TARGET = BASE / 'normalized-composition-partition.json.gz'
PREFIXES = ('composition_', 'success_forward_ir_intent_hir_composition_')


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def read(path):
    return json.loads(gzip.decompress(path.read_bytes()))


def expected():
    # Explicit suffix allocation is independent of the prefix search below.
    shallow = {'composition_presence_keys'} | {p + suffix for p in PREFIXES
        for suffix in ('child_entry_keys', 'generated_child_entry_keys')}
    overrides = {p + kind + '_parameter_override_' + shape for p in PREFIXES
        for kind in ('child', 'generated_child')
        for shape in ('entry_keys', 'raw_value_extension_keys', 'value_metadata_extension_keys')}
    dt = {p + 'standalone_dt_' + suffix for p in PREFIXES for suffix in (
        'child_entry_keys', 'enable_family_entry_keys', 'module_enable_family_keys',
        'multi_drive_target_entry_keys', 'multi_drive_assertion_keys')}
    return {OWNER + '.1': sorted(shallow), OWNER + '.2': sorted(overrides),
            OWNER + '.3': sorted(dt)}


def verify(packet):
    if packet['schema'] != 'fsmgen.normalized_composition_partition.v1' or packet['owner'] != OWNER:
        raise ValueError('partition identity')
    if packet['inputs'] != {p.name: sha(p.read_bytes()) for p in (SOURCE, NATIVE)}:
        raise ValueError('input identity')
    predecessor = read(SOURCE)
    native = read(NATIVE)['native_api']['manifest']['semantic_exports']['normalized_semantic_json']
    selected = {key for key in predecessor['remaining_fields'] if
        (key.startswith('composition_') and not key.startswith('composition_shared_datapath_'))
        or key.startswith('success_forward_ir_intent_hir_composition_')}
    groups = expected()
    if packet['cohorts'] != groups:
        raise ValueError('exact cohort allocation')
    members = [key for values in groups.values() for key in values]
    if len(members) != len(set(members)) or set(members) != selected:
        raise ValueError('disjoint complete composition population')
    if packet['selected_values'] != {key: native[key] for key in selected}:
        raise ValueError('complete original native values')
    if packet['remaining_fields'] != {k: v for k, v in predecessor['remaining_fields'].items() if k not in selected}:
        raise ValueError('unchanged remaining deeper delegations')
    if packet['join_owner'] != OWNER + '.4':
        raise ValueError('final current-source join owner')
    if packet['instrument'] != {'path': Path(__file__).relative_to(ROOT).as_posix(),
                               'text': Path(__file__).read_text(), 'sha256': sha(Path(__file__).read_bytes())}:
        raise ValueError('instrument identity')
    return {'cohort_fields': {k: len(v) for k, v in groups.items()},
            'selected_fields': len(selected), 'remaining_fields': len(packet['remaining_fields'])}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    if args.write:
        if TARGET.exists():
            raise SystemExit('Refusing to overwrite retained partition')
        predecessor = read(SOURCE)
        native = read(NATIVE)['native_api']['manifest']['semantic_exports']['normalized_semantic_json']
        groups = expected()
        members = {key for values in groups.values() for key in values}
        packet = {'schema': 'fsmgen.normalized_composition_partition.v1', 'owner': OWNER,
            'inputs': {p.name: sha(p.read_bytes()) for p in (SOURCE, NATIVE)},
            'cohorts': groups, 'selected_values': {k: native[k] for k in sorted(members)},
            'remaining_fields': {k: v for k, v in predecessor['remaining_fields'].items() if k not in members},
            'join_owner': OWNER + '.4',
            'instrument': {'path': Path(__file__).relative_to(ROOT).as_posix(),
                           'text': Path(__file__).read_text(), 'sha256': sha(Path(__file__).read_bytes())},
            'evidence_legs': {
                'rederive': 'Project exact selected fields/values and deeper delegations from retained original native metadata and qualified symbol predecessor.',
                'falsify': 'Compare a prefix-derived population with explicit independently reviewed suffix cohorts; reject omitted/misallocated fields and lost deeper ownership.',
                'durability': 'Track exact input digests, source-bearing instrument, complete field/value allocation and replay controls.'},
            'limits': 'Task partition only; no family meaning, runtime payload, source availability or compiler/backend qualification is closed.'}
        verify(packet)
        TARGET.write_bytes(gzip.compress((json.dumps(packet, sort_keys=True, indent=2) + '\n').encode(), mtime=0))
    packet = read(TARGET)
    result = verify(packet)
    controls = {}
    for label in ('missing_field', 'misallocated_field', 'lost_remaining', 'wrong_join_owner'):
        bad = copy.deepcopy(packet)
        if label == 'missing_field':
            bad['cohorts'][OWNER + '.1'].pop()
        elif label == 'misallocated_field':
            bad['cohorts'][OWNER + '.2'].append(bad['cohorts'][OWNER + '.1'].pop())
        elif label == 'lost_remaining':
            bad['remaining_fields'].pop(next(iter(bad['remaining_fields'])))
        else:
            bad['join_owner'] = OWNER + '.3'
        try:
            verify(bad)
        except ValueError as error:
            controls[label] = str(error)
        else:
            raise ValueError('Accepted partition counterfeit: ' + label)
    result['rejected_controls'] = controls
    result['limits'] = packet['limits']
    print(json.dumps(result, sort_keys=True))


if __name__ == '__main__':
    main()

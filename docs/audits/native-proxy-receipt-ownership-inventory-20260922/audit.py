"""Re-derive and falsify the receipt-ownership inventory without execution."""
import argparse
import copy
import hashlib
import json
from pathlib import Path
import inventory

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]


def read(name):
    return json.loads((BASE / name).read_bytes())


def require(condition, message):
    if not condition:
        raise ValueError(message)


def verify():
    scope = read('scope.json')
    require(scope == inventory.SCOPE, 'inventory scope drifted from its selected contract')
    pins, texts = inventory.load()
    require(pins == read('source-pins.json'), 'selected source pins changed')
    result = inventory.derive(texts)
    require(result == read('review.json'), 'saved inventory no longer reconstructs')
    require(result['public_result_carries_process_identity'] is False, 'public identity gap disappeared')
    require(result['private_supervisor_state_records_pid'] is True, 'private supervisor identity disappeared')
    require(result['cleanup_predicate_authenticates_owner'] is False, 'cleanup authority was promoted')
    require(result['launch_frontier_closed'] is False and result['adapter_implemented'] is False,
            'inventory promoted an unbuilt adapter or frontier')
    require(result['process_or_compiler_executed'] is False, 'inventory claims execution')
    require(len(result['retained_compiler_receipts']) == 2, 'retained compiler receipt count changed')
    require(all(row['public_result_has_pid'] is False and row['private_pid'] > 0
                for row in result['retained_compiler_receipts']),
            'retained compiler identity boundary changed')
    mutations = (
        ('public_pid_promoted', lambda value: value.update(public_result_carries_process_identity=True)),
        ('private_pid_hidden', lambda value: value.update(private_supervisor_state_records_pid=False)),
        ('cleanup_array_authorized', lambda value: value.update(cleanup_predicate_authenticates_owner=True)),
        ('synthetic_tuple_promoted', lambda value: value['populated_worker_evidence'].update(
            synthetic_retirement_and_work_records=False)),
        ('launch_frontier_closed', lambda value: value.update(launch_frontier_closed=True)),
        ('adapter_promoted', lambda value: value.update(adapter_implemented=True)),
        ('execution_promoted', lambda value: value.update(process_or_compiler_executed=True)),
        ('compiler_receipt_omitted', lambda value: value['retained_compiler_receipts'].pop()),
        ('public_compiler_pid_invented', lambda value: value['retained_compiler_receipts'][0].update(
            public_result_has_pid=True)),
        ('ownership_scope_widened', lambda value: value['retained_compiler_receipts'][0].update(
            ownership_scope='loaded-image attestation')),
    )
    rejected = []
    for name, mutate in mutations:
        trial = copy.deepcopy(result)
        mutate(trial)
        try:
            require(trial == result, name)
        except ValueError:
            rejected.append(name)
    require(rejected == [name for name, _mutate in mutations], 'an altered inventory was accepted')
    require(scope['source_revision'] == inventory.SCOPE['source_revision'],
            'inventory revision drifted from the selected contract')
    return dict(schema=result['schema'], owner=result['owner'], source_revision=result['source_revision'],
                selected_inputs=len(pins), selected_bytes=sum(row['size_bytes'] for row in pins),
                rejected_controls=len(rejected), public_process_identity=False,
                private_process_identity=True, cleanup_array_authenticates_owner=False,
                launch_frontier_closed=False, adapter_implemented=False,
                process_or_compiler_executed=False, next_owner=result['next_owner'])


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--save', action='store_true')
    group.add_argument('--verify-saved', action='store_true')
    args = parser.parse_args()
    if args.save:
        pins, texts = inventory.load()
        result = inventory.derive(texts)
        for name, value in (('source-pins.json', pins), ('review.json', result)):
            with (BASE / name).open('x') as stream:
                json.dump(value, stream, indent=2, sort_keys=True)
                stream.write('\n')
        print(json.dumps(dict(selected_inputs=len(pins), retained_compiler_receipts=len(
            result['retained_compiler_receipts'])), sort_keys=True))
    else:
        print(json.dumps(verify(), sort_keys=True))

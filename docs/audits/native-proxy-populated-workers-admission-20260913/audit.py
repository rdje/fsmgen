"""Verify the selected populated-worker inventory and retained recovery diagnosis."""
import argparse
import copy
import hashlib
import json
from pathlib import Path
import re
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
SCOPE = json.loads((BASE / 'scope.json').read_bytes())
REVISION = SCOPE['source_revision']


def read(name):
    return json.loads((BASE / name).read_bytes())


def pin(path):
    raw = path.read_bytes()
    return dict(path=str(path.relative_to(ROOT)), size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def old(path):
    return subprocess.check_output(['/usr/bin/git', '-c', 'core.excludesFile=.gitignore',
        'show', REVISION + ':' + path], cwd=ROOT,
        env=dict(PATH='/usr/bin:/bin', LC_ALL='C', LANG='C', TMPDIR=str(ROOT / '.artifacts/tmp')))


def validate(view):
    inventory, proposal, first, controls, finding = (view[n] for n in ['inventory', 'proposal', 'first', 'controls', 'finding'])
    assert inventory['owner'] == proposal['owner'] == finding['owner'] == SCOPE['owner']
    assert inventory['source_revision'] == finding['source_revision'] == REVISION
    assert inventory['repair_owner'] == finding['repair_owner'] == SCOPE['controller_owner']
    assert inventory['execution_authorized'] is False and proposal['execution_authorized'] is False
    assert proposal['proposal_only'] and proposal['inert_images_only']
    assert inventory['worker_language'] == 'perl' and inventory['controller_language'] == 'python'
    expected = {
        'coordination': ['inspect_store'], 'runtime_acquisition': ['acquire_runtime_reference'],
        'observation_acquisition': ['acquire_observation_reference', 'reuse_observation_reference'],
        'runtime_retirement': ['retire_runtime_reference'], 'archive': ['archive_retained_sources'],
        'work_records': ['work_selection', 'work_settlement', 'validate_work_settlement'],
        'observation_release': ['release_observation_reference'], 'maintenance': ['remove_unreferenced_image']}
    assert len(inventory['interfaces']) == len(expected)
    assert {r['role']: [f['name'] for f in r['public_functions']] for r in inventory['interfaces']} == expected
    for interface in inventory['interfaces']:
        assert pin(ROOT / interface['path']) == {k: interface[k] for k in ['path', 'size_bytes', 'sha256']}
        lines = (ROOT / interface['path']).read_text().splitlines()
        for function in interface['public_functions']:
            found = [i + 1 for i, line in enumerate(lines) if re.match(r'^sub ' + re.escape(function['name']) + r'\s*\{', line)]
            assert found == [function['line']]
    names = ['equal_publication', 'different_publication', 'observation_across_retirement',
             'equal_references_with_observer', 'cancelled_runtime_owner', 'cancelled_observer_owner']
    assert [c['name'] for c in proposal['cases']] == names
    assert [len(c['workers']) for c in proposal['cases']] == [2, 2, 3, 3, 2, 3]
    assert proposal['maximum_simultaneous_workers'] == max(len(c['workers']) for c in proposal['cases'])
    assert proposal['planned_worker_instances'] == sum(len(c['workers']) for c in proposal['cases'])
    assert proposal['compiler_proxy_original_collector_invocations'] == 0
    assert proposal['final_bounds_and_protocol_owner'] == SCOPE['final_admission_owner']
    for case in proposal['cases']:
        assert len(set(case['workers'])) == len(case['workers']) and case['obligations']
    assert first['outputs']['exit'] == controls['outputs']['exit'] == '0\n'
    result = first['result']
    assert json.loads(first['outputs']['stdout']) == result
    assert result['defect_reproduced'] and result['terminal_model_child']
    assert not result['native_identity_admitted'] and not result['recovery_complete']
    assert result['failure'] == 'refusing to signal a worker without admitted native ownership'
    assert result['actual_os_operations'] == [] and result['worker_invocations'] == result['fixture_allocations'] == result['compiler_invocations'] == 0
    assert not result['historical_actual_runs_reclassified']
    assert [(f['function'], f['line']) for f in result['frames'][1:]] == [('recover', 282), ('signal', 223)]
    for source in result['sources']:
        assert pin(ROOT / source['path']) == source
    assert pin(ROOT / first['reproducer']['path']) == first['reproducer']
    adjacent = controls['result']
    assert json.loads(controls['outputs']['stdout']) == adjacent
    assert adjacent['original_defect_retained'] and adjacent['worker_invocations'] == adjacent['fixture_allocations'] == 0
    assert [(c['initial_streams_drained'], c['native_admission_modeled']) for c in adjacent['controls']] == [(True, False), (False, True)]
    assert all(c['recovered'] and c['terminal_result_consumed'] and c['signal_operations'] == 0 for c in adjacent['controls'])
    assert finding['runtime_effect_observed'] is finding['actual_worker_launched'] is finding['existing_actual_qualification_reclassified'] is False
    assert finding['status'] == 'reproduced; repair required before populated-worker admission'
    return dict(api_roles=len(expected), public_functions=sum(map(len, expected.values())),
                proposed_cases=len(names), planned_worker_instances=proposal['planned_worker_instances'],
                recovery_defect_reproduced=True, adjacent_state_controls=len(adjacent['controls']),
                repair_owner=SCOPE['controller_owner'], operational_admission_qualified=False)


def verify():
    pins = read('input-pins.json')
    for row in pins:
        assert pin(ROOT / row['path']) == row and old(row['path']) == (ROOT / row['path']).read_bytes()
    view = {key: read(name) for key, name in [('inventory', 'api-inventory.json'), ('proposal', 'scenario-proposal.json'),
        ('first', 'recovery-first.json'), ('controls', 'recovery-controls.json'), ('finding', 'recovery-finding.json')]}
    result = validate(view)
    mutations = {
        'stale_source_epoch': lambda v: v['inventory'].update(source_revision='0' * 40),
        'lost_public_api': lambda v: v['inventory']['interfaces'].pop(),
        'moved_api_coordinate': lambda v: v['inventory']['interfaces'][0]['public_functions'][0].update(line=1),
        'unowned_case': lambda v: v['proposal']['cases'][0].update(name='unowned'),
        'worker_count_changed': lambda v: v['proposal'].update(planned_worker_instances=1),
        'proposal_promoted': lambda v: v['proposal'].update(execution_authorized=True),
        'defect_hidden': lambda v: v['first']['result'].update(recovery_complete=True),
        'repair_owner_lost': lambda v: v['finding'].update(repair_owner='unowned'),
        'actual_failure_invented': lambda v: v['finding'].update(runtime_effect_observed=True),
        'adjacent_control_lost': lambda v: v['controls']['result']['controls'].pop(),
    }
    rejected = []
    for name, change in mutations.items():
        altered = copy.deepcopy(view)
        change(altered)
        try:
            validate(altered)
        except (AssertionError, ValueError, KeyError, IndexError):
            rejected.append(name)
        else:
            raise AssertionError('accepted altered inventory or diagnosis: ' + name)
    return dict(owner=SCOPE['owner'], source_revision=REVISION, selected_inputs=len(pins),
                result=result, rejected_controls=rejected, worker_invocations=0, fixture_allocations=0,
                claim_legs=dict(rederive='Pinned public source coordinates and exact first recovery-model source/result.',
                                falsify='Adjacent terminal states and altered inventory, source, ownership, counts and execution claims.',
                                durability='Tracked source inventory, proposal, first reproducer/output, controls and owned next repair.'),
                next_action='Repair and qualify the fresh controller before any populated-worker operational admission.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--verify-saved', required=True, action='store_true')
    parser.parse_args()
    print(json.dumps(verify(), sort_keys=True))

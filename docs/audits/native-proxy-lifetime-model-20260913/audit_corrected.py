"""Independent prefix-set/state oracle and unchanged Perl record cross-check."""
from __future__ import annotations

import argparse
import copy
import hashlib
import itertools
import json

from common import BASE, ROOT, CONTRACT, WORK, archive, authenticate, digest, document, raw, work, write


def baseline(seed):
    # Do not call the transition implementation or its initializer.
    state = {name: {} for name in ('images', 'references', 'workspaces', 'private', 'archives')}
    state['images'] = copy.deepcopy(seed['images'])
    for label, runtime in seed['runtimes'].items():
        state['references'][label] = copy.deepcopy({name: runtime[name] for name in ('record', 'source')})
        state['workspaces'][label] = copy.deepcopy(runtime['directory'])
        state['private'][label] = copy.deepcopy(runtime['private'])
    for label, value in seed['observers'].items():
        state['references'][label] = copy.deepcopy(value['acquired']['observation_reference'])
    return state


def state_for(seed, completed):
    # Expected state is a projection of a SET of completed events, independent
    # of the iterative transition algorithm and independent of event order.
    state = baseline(seed)
    state['archives'] = {name: copy.deepcopy(seed['observers'][name]['archive']) for name in ('a', 'b')
                         if 'archive_' + name in completed}
    for name in ('target', 'other'):
        if 'retire_' + name in completed:
            for field in ('references', 'workspaces', 'private'):
                del state[field][name]
    for name in ('a', 'b'):
        if 'release_' + name in completed:
            del state['references'][name]
    if 'maintain_target' in completed:
        del state['images'][seed['target_image']]
    return state


def expected_view(seed, state):
    current = {source['identity']['path']: source for pair in state['images'].values() for source in pair}
    current.update({hold['source']['identity']['path']: hold['source'] for hold in state['references'].values()
                    if 'source' in hold})
    current.update({source['identity']['path']: source for pair in state['private'].values() for source in pair})
    live = {}
    for name, value in seed['observers'].items():
        available = state['workspaces'].get('target') == value['request']['workspace_identity'] and all(
            current.get(source['identity']['path']) == source for source in value['acquired']['target_sources'])
        live[name] = dict(fresh=available, repeat=available and
                         state['references'].get(name) == value['acquired']['observation_reference'])
    return dict(state_sha256=hashlib.sha256(raw(state)).hexdigest(),
                **{field: sorted(state[field]) for field in ('references', 'images', 'workspaces', 'archives')},
                live=live, retained={name: digest(value['acquired']['target_sources']) for name, value in seed['observers'].items()})


def seeds_check(prepared, bridge):
    old_sources = document(ROOT / WORK / 'plan.json')['contexts'][0]['acquired']['target_sources']
    payload = [bytes.fromhex(x['bytes_hex']) for x in old_sources]
    for profile, seed in prepared['seeds'].items():
        assert seed['identity_origin'] == 'synthetic_model_only' and seed['profile'] == profile
        case = seed['observers']['a']['case']
        assert case.endswith('/fsmgen-LifetimeModel')
        for key, pair in seed['images'].items():
            c, image = [archive.snapshot(x) for x in pair]
            assert c == payload[3] and image in (payload[4], payload[4] + b'\0lifetime-other')
            framed = b'fsmgen.rust_proxy_image.v1\0' + len(c).to_bytes(8, 'big') + c + len(image).to_bytes(8, 'big') + image
            assert hashlib.sha256(framed).hexdigest() == key
        assert len(seed['images']) == (1 if profile == 'same_image' else 2)
        assert (seed['target_image'] == seed['other_image']) == (profile == 'same_image')
        native = {}
        for group in [source for pair in seed['images'].values() for source in pair]:
            ident = group['identity']; assert ident['device'] == 1
            assert ident['inode'] not in native
            native[ident['inode']] = ident['path']
        for name, runtime in seed['runtimes'].items():
            rec = runtime['record']
            expected_key = hashlib.sha256(b'fsmgen.rust_proxy_reference.runtime.v1\0' + rec['workspace'].encode()).hexdigest()
            assert rec['reference_key'] == expected_key
            assert rec['selected_sources'] == [x['identity'] for x in seed['images'][rec['image_key']]]
            assert archive.snapshot(runtime['source']) == archive.snapshot(runtime['private'][1]) == raw(rec)
            assert archive.snapshot(runtime['private'][0]) == payload[0]
            assert bridge['seeds'][profile]['runtime_bytes'][name] == raw(rec).hex()
            for ident in [runtime['directory'], runtime['source']['identity'], *[x['identity'] for x in runtime['private']]]:
                assert ident['device'] == 1 and ident['inode'] not in native
                native[ident['inode']] = ident['path']
        a, b = seed['observers']['a'], seed['observers']['b']
        assert a['acquired']['target_sources'] == b['acquired']['target_sources']
        assert a['request']['target_birth'] == b['request']['target_birth']
        assert a['request']['observer_birth'] != b['request']['observer_birth']
        assert a['selection']['observation_reference_key'] != b['selection']['observation_reference_key']
        for name, value in seed['observers'].items():
            result = bridge['seeds'][profile]['observations'][name]
            assert result == dict(previous=value['acquired'], specification=archive.specification(value),
                                  archive=archive.from_snapshots(value), selection=work.create_selection(value),
                                  settlement=work.create_settlement(value))
            # Byte-equal private/global records share one archive file, while
            # retaining distinct original source identities in both receipts.
            bindings = value['archive']['source_bindings']
            assert bindings[1]['source'] != bindings[2]['source']
            assert bindings[1]['archive'] == bindings[2]['archive']
        assert a['archive']['source_bindings'] == b['archive']['source_bindings']
    assert bridge['process_attempts'] == bridge['fixture_lookup_attempts'] == 0 and bridge['input_unchanged'] is True


def control_expected(value):
    control, seed, state = value['control'], value['seed'], copy.deepcopy(value['state'])
    before = expected_view(seed, state)
    if control['returned'] or control.get('fault') == 'after_unlink':
        event = control['event']
        if event.startswith('archive_'):
            name = event[-1]; state['archives'][name] = copy.deepcopy(seed['observers'][name]['archive'])
        elif event.startswith('release_'):
            del state['references'][event[-1]]
        elif event.startswith('retire_'):
            name = event.removeprefix('retire_')
            for field in ('references', 'workspaces', 'private'):
                del state[field][name]
        else:
            assert event == 'maintain_target'; del state['images'][seed['target_image']]
    after = expected_view(seed, state)
    return dict(name=control['name'], before=before, result=dict(returned=control['returned'],
                modeled_effect=before['state_sha256'] != after['state_sha256'], view=after))


def verify(result, prepared, plan, bridge):
    seeds_check(prepared, bridge)
    contract = document(ROOT / CONTRACT / 'corrected-plan.json')
    expected_orders = []
    for profile in contract['profiles']:
        edges = contract['common_edges'] + profile['additional_edges']
        # This auditor enumerates permutations against explicit precedences;
        # the preceding contract also retains a distinct topological oracle.
        for order in itertools.permutations(contract['events']):
            if all(order.index(a) < order.index(b) for a, b in edges):
                expected_orders.append(dict(profile=profile['name'], order=list(order)))
    assert prepared['schedules'] == expected_orders
    assert len(result['traces']) == len(expected_orders)
    prefixes = 0
    for trace, schedule in zip(result['traces'], expected_orders, strict=True):
        seed = prepared['seeds'][schedule['profile']]
        assert trace['profile'] == schedule['profile'] and trace['events'] == schedule['order']
        assert trace['initial'] == expected_view(seed, state_for(seed, set()))
        assert len(trace['steps']) == len(schedule['order'])
        done = set(); prefixes += 1
        for event, step in zip(schedule['order'], trace['steps'], strict=True):
            before = state_for(seed, done); done.add(event); after = state_for(seed, done)
            assert step == dict(returned=True, modeled_effect=before != after, view=expected_view(seed, after))
            prefixes += 1
    assert [x['control'] for x in prepared['controls']] == plan['controls']
    expected_controls = [control_expected(value) for value in prepared['controls']]
    assert result['controls'] == expected_controls
    # Reconstruct control pre-states independently; do not trust preparation's
    # model-generated prefixes or producer-supplied before fingerprints.
    for value in prepared['controls']:
        control = value['control']
        selected = prepared['seeds'][control['profile']]
        initial = dict(seed=copy.deepcopy(selected), state=state_for(selected, set(control['prefix'])))
        for change in control['changes']:
            parent = initial
            for key in change['path'][:-1]: parent = parent[key]
            key = change['path'][-1]
            if change['op'] == 'set': parent[key] = copy.deepcopy(change['value'])
            elif change['op'] == 'delete': del parent[key]
            else: assert change['op'] == 'increment'; parent[key] += 1
        assert initial == {key: value[key] for key in ('seed', 'state')}
    expected_bridge_controls = [row for row in plan['controls'] if 'oracle' in row]
    assert len(bridge['controls']) == len(expected_bridge_controls)
    for actual, control in zip(bridge['controls'], expected_bridge_controls, strict=True):
        assert actual['name'] == control['name'] and actual['accepted'] == int(control['oracle_accept'])
        assert bool(actual['error']) != control['oracle_accept']
    assert len(result['mutants']) == len(plan['mutants'])
    for mutant, declaration in zip(result['mutants'], plan['mutants'], strict=True):
        assert mutant['name'] == declaration['name'] and mutant['witness'] == declaration['witness']
        healthy = next(row['result'] for row in expected_controls if row['name'] == mutant['witness'])
        assert mutant['result'] != healthy, mutant['name']
    assert result['runtime_qualification'] is False and result['actual_filesystem_effects'] is False
    return dict(serial_orders=len(expected_orders), prefix_states=prefixes, controls=len(expected_controls),
                record_controls=len(expected_bridge_controls), omitted_guard_witnesses=len(result['mutants']),
                profiles={profile: sum(x['profile'] == profile for x in expected_orders) for profile in plan['profiles']},
                domain_sha256=digest(expected_orders), actual_filesystem_effects=False, runtime_qualification=False)


def falsify(result, prepared, plan, bridge):
    names = ('missing_trace', 'changed_event_order', 'wrong_prefix_state', 'rejected_healthy',
             'lost_partial_effect', 'changed_bridge_record', 'promoted_runtime_authority')
    for name in names:
        changed, altered = copy.deepcopy(result), copy.deepcopy(bridge)
        if name == 'missing_trace': changed['traces'].pop()
        elif name == 'changed_event_order': changed['traces'][0]['events'].reverse()
        elif name == 'wrong_prefix_state': changed['traces'][0]['steps'][0]['view']['state_sha256'] = '0' * 64
        elif name == 'rejected_healthy': changed['traces'][0]['steps'][0]['returned'] = False
        elif name == 'lost_partial_effect':
            next(x for x in changed['controls'] if x['name'] == 'post_unlink_failure')['result']['modeled_effect'] = False
        elif name == 'changed_bridge_record': altered['seeds']['same_image']['runtime_bytes']['target'] += '00'
        else: changed['runtime_qualification'] = True
        try:
            verify(changed, prepared, plan, altered)
        except (AssertionError, KeyError):
            continue
        raise AssertionError('accepted falsifier ' + name)
    return list(names)


def main():
    parser = argparse.ArgumentParser(); parser.add_argument('--verify-saved', action='store_true'); args = parser.parse_args()
    plan = document(BASE / 'plan.json')
    authenticate(plan, document(BASE / 'corrected-pins.json'))
    prepared, result, bridge = [document(BASE / name) for name in ('prepared.json', 'qualification.json', 'bridge.json')]
    counts = verify(result, prepared, plan, bridge)
    report = dict(schema='fsmgen.inactive_lifetime_model_audit.v1', **counts,
                  falsifiers=falsify(result, prepared, plan, bridge))
    if args.verify_saved:
        assert document(BASE / 'corrected-audit.json') == report
    else:
        write(BASE / 'corrected-audit.json', report)
    print(json.dumps(report, sort_keys=True))


if __name__ == '__main__':
    main()

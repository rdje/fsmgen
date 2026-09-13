"""In-memory complete-operation model. No filesystem or execution authority."""
from __future__ import annotations

import copy
from common import archive, digest, work


def initial(seed):
    return dict(images=copy.deepcopy(seed['images']),
                references={**{label: dict(record=copy.deepcopy(value['record']), source=copy.deepcopy(value['source']))
                               for label, value in seed['runtimes'].items()},
                            **{label: copy.deepcopy(value['acquired']['observation_reference'])
                               for label, value in seed['observers'].items()}},
                workspaces={label: copy.deepcopy(value['directory']) for label, value in seed['runtimes'].items()},
                private={label: copy.deepcopy(value['private']) for label, value in seed['runtimes'].items()}, archives={})


def owner_settled(owner):
    if type(owner) is not dict or type(owner.get('cleanup')) is not dict:
        return False
    flags = [owner['cleanup'].get(name) for name in ('leader_started', 'leader_reaped', 'group_gone')]
    if any(type(value) not in (str, int) or value not in (0, 1, '0', '1') for value in flags):
        return False
    started, reaped, gone = [value in (1, '1') for value in flags]
    return gone and (not started or reaped)


def cleanup_settled(owners):
    if type(owners) is not list or len(owners) != 3:
        return False
    compiler, outer, stages = owners
    return type(stages) is list and bool(stages) and all(owner_settled(x) for x in [compiler, outer] + stages)


def live_matches(seed, state, observer, repeat):
    value = seed['observers'][observer]
    if state['workspaces'].get('target') != value['request']['workspace_identity']:
        return False
    runtime = state['references'].get('target')
    pair = state['images'].get(seed['target_image'])
    if runtime is None or pair is None or 'target' not in state['private']:
        return False
    sources = state['private']['target'] + [runtime['source']] + pair
    if sources != value['acquired']['target_sources']:
        return False
    return not repeat or state['references'].get(observer) == value['acquired']['observation_reference']


def view(seed, state):
    return dict(state_sha256=digest(state), references=sorted(state['references']), images=sorted(state['images']),
                workspaces=sorted(state['workspaces']), archives=sorted(state['archives']),
                live={name: dict(fresh=live_matches(seed, state, name, False), repeat=live_matches(seed, state, name, True))
                      for name in ('a', 'b')},
                retained={name: digest(value['acquired']['target_sources']) for name, value in seed['observers'].items()})


def transition(seed, state, event, fault=None, mutant=None):
    """Failures preserve modeled effects already performed; never infer rollback."""
    before = digest(state)
    try:
        if event.startswith('archive_'):
            name = event[-1]
            value = seed['observers'][name]
            if mutant == 'archive_requires_live':
                assert live_matches(seed, state, name, False), 'live source absent'
            archive.validate(value, value['archive'])
            # Only retained bytes feed this operation; source paths need not exist.
            assert archive.from_snapshots(value) == value['archive'], 'archive bytes differ'
            state['archives'][name] = copy.deepcopy(value['archive'])
        elif event.startswith('retire_'):
            name = event.removeprefix('retire_')
            runtime = seed['runtimes'][name]
            assert cleanup_settled(runtime['cleanup']), 'unsettled runtime'
            if mutant == 'retire_requires_success':
                assert runtime['cleanup'][0]['outcome'] == 'completed', 'command failed'
            assert state['workspaces'].get(name) == runtime['directory'], 'workspace absent or changed'
            assert state['private'].get(name) == runtime['private'], 'private snapshot changed'
            assert state['references'].get(name) == dict(record=runtime['record'], source=runtime['source']), 'runtime hold changed'
            del state['private'][name]
            del state['workspaces'][name]
            del state['references'][name]
        elif event.startswith('release_'):
            name = event[-1]
            value = seed['observers'][name]
            if mutant != 'release_without_archive':
                assert name in state['archives'], 'archive absent'
                archive.validate(value, state['archives'][name])
            if mutant != 'release_without_settlement':
                work.settlement(value, value['settlement'])
            assert state['references'].get(name) == value['acquired']['observation_reference'], 'observation hold absent or changed'
            assert state['images'].get(seed['target_image']) == seed['images'][seed['target_image']], 'selected image changed'
            del state['references'][name]
            if fault == 'after_unlink':
                if mutant == 'failure_rolls_back':
                    state['references'][name] = copy.deepcopy(value['acquired']['observation_reference'])
                raise AssertionError('modeled post-unlink failure')
        elif event == 'maintain_target':
            baseline = initial(seed)
            assert all(key in baseline['images'] and pair == baseline['images'][key]
                       for key, pair in state['images'].items()), 'partial or changed image'
            assert all(key in baseline['references'] and hold == baseline['references'][key]
                       for key, hold in state['references'].items()), 'unknown or changed reference'
            target = seed['target_image']
            assert target in state['images'], 'selected image absent'
            ignored = {'ignore_observation_b': 'b', 'ignore_other_runtime': 'other'}.get(mutant)
            assert not any(hold['record']['image_key'] == target for name, hold in state['references'].items()
                           if name != ignored), 'selected image referenced'
            del state['images'][target]
            if mutant == 'remove_other_image':
                state['images'].clear()
        else:
            raise ValueError('event outside declared domain')
        returned = True
    except (AssertionError, KeyError, TypeError, ValueError):
        returned = False
    return dict(returned=returned, modeled_effect=digest(state) != before, view=view(seed, state))

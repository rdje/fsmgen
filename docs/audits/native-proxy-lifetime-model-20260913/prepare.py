"""Prepare new inert records and control values from prospectively pinned inputs."""
from __future__ import annotations

import copy
from common import BASE, ROOT, CONTRACT, authenticate, document, seed, write
import model


def patch(root, change):
    parent = root
    for key in change['path'][:-1]:
        parent = parent[key]
    key = change['path'][-1]
    if change['op'] == 'set':
        parent[key] = copy.deepcopy(change['value'])
    elif change['op'] == 'delete':
        del parent[key]
    elif change['op'] == 'increment':
        parent[key] += 1
    else:
        raise AssertionError(change['op'])


def control_value(seeds, control):
    value = copy.deepcopy(seeds[control['profile']])
    state = model.initial(value)
    for event in control['prefix']:
        assert model.transition(value, state, event)['returned'], control['name']
    inputs = dict(seed=value, state=state)
    for change in control['changes']:
        patch(inputs, change)
    return inputs


def build(plan):
    seeds = {profile: seed(profile) for profile in plan['profiles']}
    contracts = document(ROOT / CONTRACT / 'corrected-contracts.json')
    return dict(schema='fsmgen.inactive_lifetime_model_inputs.v1', seeds=seeds,
                schedules=contracts['schedules'],
                controls=[dict(control=control, **control_value(seeds, control)) for control in plan['controls']])


def main():
    plan = document(BASE / 'plan.json')
    authenticate(plan, document(BASE / 'prepare-pins.json'))
    prepared = build(plan)
    write(BASE / 'prepared.json', prepared)
    print('prepared inert lifetime inputs; no fixture paths allocated')


if __name__ == '__main__':
    main()

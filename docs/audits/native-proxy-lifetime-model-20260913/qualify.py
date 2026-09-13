"""Execute only the new in-memory model over the pinned complete domain."""
from __future__ import annotations

import copy
from common import BASE, authenticate, document, write
import model


def run(prepared, plan):
    traces = []
    for schedule in prepared['schedules']:
        seed = prepared['seeds'][schedule['profile']]
        state = model.initial(seed)
        trace = dict(profile=schedule['profile'], events=schedule['order'], initial=model.view(seed, state), steps=[])
        for event in schedule['order']:
            trace['steps'].append(model.transition(seed, state, event))
        traces.append(trace)
    controls = []
    for value in prepared['controls']:
        control = value['control']
        seed, state = copy.deepcopy(value['seed']), copy.deepcopy(value['state'])
        before = model.view(seed, state)
        result = model.transition(seed, state, control['event'], fault=control.get('fault'))
        controls.append(dict(name=control['name'], before=before, result=result))
    mutants = []
    for mutant in plan['mutants']:
        value = next(x for x in prepared['controls'] if x['control']['name'] == mutant['witness'])
        control = value['control']
        result = model.transition(value['seed'], copy.deepcopy(value['state']), control['event'],
                                  fault=control.get('fault'), mutant=mutant['name'])
        mutants.append(dict(name=mutant['name'], witness=mutant['witness'], result=result))
    return dict(schema='fsmgen.inactive_lifetime_model_qualification.v1', traces=traces, controls=controls,
                mutants=mutants, runtime_qualification=False, actual_filesystem_effects=False)


def main():
    plan = document(BASE / 'plan.json')
    authenticate(plan, document(BASE / 'preflight-pins.json'))
    result = run(document(BASE / 'prepared.json'), plan)
    write(BASE / 'qualification.json', result)
    print('qualified model traces and controls; returned verdicts retain modeled effects separately')


if __name__ == '__main__':
    main()

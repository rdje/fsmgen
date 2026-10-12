"""Develop intended first library refusals; formal native cases remain required."""
import copy
from acceptance_common import *
import controls
import parent_model
import reader

if __name__ == '__main__':
    good = parent_model.propose(parent_model.inputs(development=True))
    rows = []
    for label, mutate, status, cause in controls.CASES:
        value = copy.deepcopy(good)
        if mutate:
            mutate(value)
        try:
            result = reader.check(value, development=True)
        except ValueError as error:
            need(cause is not None and str(error) == cause, 'development intended first refusal: ' + label + ': ' + str(error))
            rows.append(dict(label=label, candidate=pin(canonical(value)), library_error=str(error)))
        else:
            need(cause is None and result['phase'] == 'development-only; no formal acceptance',
                 'development positive scope only')
            rows.append(dict(label=label, candidate=pin(canonical(value)), positive=pin(canonical(result))))
    save('development-refusals.json', dict(owner=PLAN['owner'], cases=rows,
        condition='Development-only in-process positive/intended-error probe. Errors are library refusals caught inside native status 0, not actual native status 1 controls. Complete formal native cases, source/contract/delivery and parent acceptance remain required.'))
    print('PASS development-only complete positive and every intended library refusal; formal native cases remain required.')

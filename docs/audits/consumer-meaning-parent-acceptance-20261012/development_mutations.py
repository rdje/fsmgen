"""Develop complete positive meaning admission and all mutation construction."""
import copy
from acceptance_common import *
import controls
import parent_model
import reader

if __name__ == '__main__':
    good = parent_model.propose(parent_model.inputs(development=True))
    admitted = reader.check(good, development=True)
    need(admitted['phase'] == 'development-only; no formal acceptance', 'explicit positive development scope')
    constructed = []
    for label, mutate, status, cause in controls.CASES:
        value = copy.deepcopy(good)
        if mutate:
            mutate(value)
            need(not same(value, good), 'genuine complete constructed parent mutation: ' + label)
        constructed.append(dict(label=label, candidate=pin(canonical(value)), status=status, cause=cause))
    save('development-mutations.json', dict(owner=PLAN['owner'], positive=pin(canonical(good)),
        admission=admitted, constructed=constructed,
        condition='Development-only positive independent interface and complete mutation-construction probe. Mutated candidates have not yet executed as actual native reader cases. Formal native separating controls and full unchanged parent acceptance remain required.'))
    print('PASS development-only complete positive meaning interface and every genuine mutation construction; no formal acceptance.')

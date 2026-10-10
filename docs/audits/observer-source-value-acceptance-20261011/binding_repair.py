"""Prove the entire first accepted product fails the repaired actual native binding."""
from common import BASE, SCOPE, canonical, load, need, pin, save
import verify


if __name__=='__main__':
    first=load('product.json')
    prior=load('actual-independent-products-1.json')
    need(type(prior['status']) is int and prior['status']==0 and prior['stderr']=='',
         'retain actual initial incomplete-reader acceptance as an unqualified first result')
    expected='actual whole native plan/driver binding: predicate'
    try:
        verify.validate(first,load('contracts.json'))
    except ValueError as error:
        need(str(error)==expected,'complete first accepted product now fails at the actual binding defect')
    else:
        raise ValueError('first accepted wrong-plan epoch remains accepted')
    fixed=verify.validate(load('product-qualified.json'),load('contracts.json'))
    save('binding-repair-proof.json',dict(first_product=pin(canonical(first)),
        actual_initial_acceptance=pin(canonical(prior)),corrected=fixed,first_rejection=expected,scope=SCOPE))
    print('PASS entire initially accepted wrong-plan product now rejects at actual whole native plan/driver binding: predicate; corrected full parent product passes.')

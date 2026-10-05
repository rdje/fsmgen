"""Reproduce first self-consistent false acceptance and independently refuse it."""
import copy
import importlib.util
import json
import types
from pathlib import Path

BASE = Path('docs/audits/record-value-own-boundary-publication-20261005')


def retained(name):
    path = BASE / name
    namespace = {'__name__': 'retained_initial_programme'}
    exec(compile(path.read_bytes(), str(path), 'exec'), namespace)
    return namespace


def main():
    spec = importlib.util.spec_from_file_location('independent_source_fidelity_reader', BASE / 'verify.py')
    reader = importlib.util.module_from_spec(spec); spec.loader.exec_module(reader)
    reader.authenticate()
    initial = json.loads((BASE / 'initial-publication.json').read_text())
    inputs = json.loads((BASE / 'initial-current-queries.json').read_text())
    first = retained('initial-verifier.py.txt')
    first['publisher'] = types.SimpleNamespace(**retained('initial-publisher.py.txt'))
    first['historical'](initial)
    first['check_live'](initial, inputs['cards'], inputs['queries'], inputs['chapter'], inputs['tooling_chapter'], inputs['declaration'])
    literal = './t/1986-isf-record-port-value-gates.t'
    reader.require(literal not in initial['own_block'] and 'record-port-\nvalue-gates.t' in initial['own_block'],
                   'actual first accepted broken literal')
    try:
        reader.check_source_fidelity(initial)
    except ValueError as error:
        reader.require(str(error) == 'independent qualified source literal/token fidelity', 'intended original false-acceptance refusal')
        refused = str(error)
    else:
        raise ValueError('false-green retained atomic-source defect')
    repaired = json.loads((BASE / 'publication.json').read_text())
    reader.check_source_fidelity(repaired)
    reader.require(literal in repaired['own_block'], 'exact repaired original file identifier')
    controls = []
    for name, old, new in [('changed-do-operator', 'an explicit do', 'an explicit require'),
                           ('changed-callback-identity', 'does not establish actual callback identity', 'establishes actual callback identity')]:
        changed = copy.deepcopy(repaired)
        reader.require(old in changed['own_block'], 'genuine source-fidelity mutation token')
        changed['own_block'] = changed['own_block'].replace(old, new)
        changed['after'][reader.publisher.HELPER] = changed['after'][reader.publisher.HELPER].replace(old, new)
        try:
            reader.check_source_fidelity(changed)
        except ValueError as error:
            reader.require(str(error) == refused, 'intended coordinated source-fidelity control cause')
            controls.append({'control': name, 'status': 1, 'cause': str(error)})
        else:
            raise ValueError('false-green coordinated qualified source mutation')
    typed = copy.deepcopy(inputs)
    typed['queries']['direct']['status'] = False
    reader.require(typed == inputs and not reader.same(typed, inputs), 'actual initial Python-equality kind mask')
    try:
        reader.check_live(repaired, {path: repaired['after'][path] for path in inputs['cards']}, typed['queries'],
                          inputs['chapter'], inputs['tooling_chapter'], inputs['declaration'])
    except ValueError as error:
        reader.require(str(error) == 'actual current query integer status kind/value', 'intended genuine Boolean query control')
        controls.append({'control': 'Boolean-kind-reaches-current-oracle', 'status': 1, 'cause': str(error)})
    else:
        raise ValueError('false-green current Boolean kind')
    proof = {'original_actual_predicate_status': 0, 'independent_original_refusal': refused, 'controls': controls,
             'repaired_literal': literal, 'scope': 'Exact initial historical/current predicates accept the actual broken atomic identifier; independent committed source rejects it. Typed JSON distinguishes the genuine Boolean mutation masked by the initial precheck.'}
    target = BASE / 'fidelity-proofs.json'
    if target.exists():
        reader.require(reader.same(json.loads(target.read_text()), proof), 'whole saved atomic-source fidelity proof')
    else:
        reader.require(not (BASE / 'manifest.json').exists(), 'sealed fidelity reader cannot publish')
        target.write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    print('PASS exact retained first false acceptance, independent source-literal/token refusal and coordinated operator/identity/kind controls; repaired literal stays exact.')


if __name__ == '__main__':
    main()

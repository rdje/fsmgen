"""Retain complete hostile candidates and actual independent native outcomes."""
import copy
import subprocess

from cause_common import *


def cases(candidate):
    modes = candidate['modes']
    failed = modes[0]['domains']['api']['nonempty']
    first, second = failed[:2]
    nested = next(row['record'] for row in modes[0]['domains']['api']['records'] if row['semantic'] and row['semantic']['forwarding'])

    def api(value, index=first):
        return value['modes'][0]['domains']['api']['records'][index]

    def group(value):
        return value['modes'][0]['domains']['api']

    allocation = 'whole ordered nonempty and empty operation allocation'
    source = 'whole own source argument/helper/parser/caller association'
    raw = 'whole own raw body context segments and address lexemes'
    semantic = 'whole own semantic record cause and raw context'
    qualified = 'whole qualified ordered class frame coordinate address and opaque role join'
    helper = 'whole own helper source membership and first failed operation'
    return [
        ('unknown-field', lambda value: value.update(native_identity='measured'), 'closed owned cause product schema'),
        ('native-promotion', lambda value: value['boundary'].update(scope='Original native class measured'), 'whole inherited native and scope boundary'),
        ('borrow-input-role', lambda value: value['inputs'][INPUTS['primary']].update(sha256='0' * 64), 'whole original qualified cause input custody'),
        ('omit-api', lambda value: group(value)['records'].pop(), allocation),
        ('omit-empty', lambda value: group(value)['empty'].pop(), allocation),
        ('omit-nonempty', lambda value: group(value)['nonempty'].pop(), allocation),
        ('reverse-order', lambda value: group(value)['records'].reverse(), allocation),
        ('boolean-population', lambda value: group(value).update(population=True), allocation),
        ('borrow-helper', lambda value: api(value)['source'].update(helper=1), source),
        ('borrow-parser', lambda value: api(value, 0)['source'].update(parse=1), source),
        ('wrong-parser-source', lambda value: value['modes'][0]['domains']['parses']['records'][2]['source']['source_input'].update(sha256='0' * 64), source),
        ('wrong-first-cause', lambda value: api(value).update(primary='Unrelated source cause'), 'whole independently derived own first cause'),
        ('boolean-acceptance', lambda value: api(value, 0)['status'].update(value=True), 'typed own source-derived acceptance or retained observation'),
        ('borrow-native', lambda value: api(value, 0).update(native=api(value, first)['native']), 'whole own original native and product association'),
        ('wrong-product', lambda value: api(value, 0)['product'].update(sha256='0' * 64), 'whole own original native and product association'),
        ('borrow-raw', lambda value: api(value).update(raw=api(value, second)['raw']), raw),
        ('omit-raw', lambda value: api(value).update(raw=None), raw),
        ('empty-borrows-raw', lambda value: api(value, 0).update(raw=api(value)['raw']), 'complete empty error has no borrowed raw or semantic member'),
        ('borrow-api-cause', lambda value: api(value)['semantic']['first_cause'].update(index=second), semantic),
        ('wrong-coordinate', lambda value: api(value)['semantic']['phases'][0]['callers'][0]['source_binding'].update(callee='Unrelated::caller'), qualified),
        ('wrong-address-role', lambda value: api(value)['semantic']['phases'][0]['address']['whole_source'].update(sha256='0' * 64), qualified),
        ('truncate-inner-cause', lambda value: api(value, nested[2])['semantic']['forwarding'].update(whole_inner_body=api(value, nested[2])['semantic']['forwarding']['whole_inner_body'][:-1]), 'whole nested own inner operand outer prefix and new trace'),
        ('reverse-nested-phases', lambda value: api(value, nested[2])['semantic']['phases'].reverse(), qualified),
        ('borrow-helper-first', lambda value: value['modes'][0]['helpers'][0]['first_record'].__setitem__(2, second), helper),
        ('omit-helper', lambda value: value['modes'][0]['helpers'].pop(), 'complete source helper population'),
        ('reverse-helpers', lambda value: value['modes'][0]['helpers'].reverse(), helper),
    ]


def run(label, candidate, expected, cause):
    path = BASE / (label + '.json.gz')
    if label != 'candidate':
        save_product(path.name, candidate)
    command = ['python3', '-B', str(BASE / 'reader.py'), '--candidate', str(path)]
    programme = {str(name): dict(body=name.read_text(), identity=pin(name.read_bytes()))
                 for name in sorted(BASE.glob('*.py'))}
    started = dict(command=command, expected_status=expected, intended_cause=cause,
                   candidate=dict(path=str(path), identity=pin(path.read_bytes())), programmes=programme)
    save('control-' + label + '-started.json', started)
    result = subprocess.run(command, capture_output=True, text=True)
    actual = dict(**started, status=result.returncode, stdout=result.stdout, stderr=result.stderr,
                  programmes_after={name: dict(body=Path(name).read_text(), identity=pin(Path(name).read_bytes())) for name in programme})
    save('control-' + label + '-actual.json', actual)
    # The complete unexpected outcome has already been preserved before judging.
    need(type(result.returncode) is int and result.returncode == expected and actual['programmes_after'] == programme,
         'intended native association outcome: ' + label)
    if expected:
        need(result.stdout == '' and result.stderr.endswith('ValueError: ' + cause + '\n'), 'exact native first refusal: ' + label)
    else:
        need(result.stdout == 'PASS independent complete original primary/raw cause association; every prior scope and native/private unknown retains.\n'
             and result.stderr == '', 'whole positive native association output')
    return pin(canonical(actual))


if __name__ == '__main__':
    candidate = product(BASE / 'candidate.json.gz')
    actuals = {'candidate': run('candidate', candidate, 0, None)}
    for label, mutate, cause in cases(candidate):
        changed = copy.deepcopy(candidate)
        mutate(changed)
        need(canonical(changed) != canonical(candidate), 'genuine changed association candidate')
        actuals[label] = run(label, changed, 1, cause)
    save('controls.json', dict(owner=PLAN['owner'], actuals=actuals,
        condition='Each whole candidate conserves the independently authenticated underlying original input files. Only the new association changes; every actual direct native reader result retains under this unchanged enclosing guard. Expected hostile status1 is a refusal, never a successful positive replay.'))
    print('PASS complete positive and genuine prior-preserving primary/raw association controls.')

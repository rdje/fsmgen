"""Complete native separating controls for the original source-to-meaning join."""
import copy
import subprocess
from join_common import *


def row(candidate, index, mode=0):
    return candidate['modes'][mode]['consumers'][index]


def set_native(index, key, value):
    return lambda candidate: row(candidate, index)['native'].__setitem__(key, value)


def borrowed(candidate):
    row(candidate, 10)['meaning'] = copy.deepcopy(row(candidate, 12)['meaning'])


def wrong_api(candidate):
    row(candidate, 6)['meaning']['origin']['api'] += 1


def wrong_helper(candidate):
    row(candidate, 10)['meaning']['source_helper']['index'] += 1


def wrong_primary(candidate):
    row(candidate, 10)['meaning']['primary'] = 'Unrelated primary diagnostic'


def wrong_source(candidate):
    row(candidate, 10)['source_contract']['source_scope']['body'] += ' '


def same_wrong_structure(candidate):
    for key in ('actual', 'expected'):
        row(candidate, 47)['native'][key][1]['low'] = 2


def raw_kind(candidate):
    row(candidate, 47)['native']['actual'][1]['type_spec'][1]['signed'] = 1


def storable_kind(candidate):
    value = row(candidate, 16, 1)['native']['expected'][1]['storage'][1][0][1]['signals'][1][0][1]['type_spec'][1]['members'][1]['data'][1]
    need(type(value['width']) is int, 'genuine original qualified Storable copy kind')
    value['width'] = str(value['width'])


def wrong_header(candidate):
    candidate['inputs'][next(iter(candidate['inputs']))]['sha256'] = '0' * 64


H_TRUTH = 'independently derived helper comparison truth contradicts native passed flag'
R_TRUTH = 'independently derived remaining comparison truth contradicts native passed flag'
MEANING = 'whole independently rederived own consumer meaning join'
OPERAND = 'whole own source-derived typed consumer operand join'
SOURCE = 'whole own original source assertion and role allocation'
CASES = (
    ('positive', None, 0, None),
    ('false-green-helper-boolean', set_native(9, 'actual', 0), 1, H_TRUTH),
    ('false-green-helper-regex', set_native(10, 'actual', 'Unrelated diagnostic'), 1, H_TRUTH),
    ('false-green-scalar', set_native(17, 'actual', 99), 1, R_TRUTH),
    ('false-green-deep', lambda c: row(c, 47)['native']['actual'][1].__setitem__('low', 2), 1, R_TRUTH),
    ('false-green-boolean', set_native(6, 'actual', 0), 1, R_TRUTH),
    ('false-green-like', set_native(3, 'actual', 'Deliberately wrong diagnostic'), 1, R_TRUTH),
    ('false-green-unlike', set_native(5, 'actual', 'expected_cause_only_in_argument'), 1, R_TRUTH),
    ('false-red', set_native(10, 'passed', 0), 1, H_TRUTH),
    ('boolean-flag', set_native(9, 'passed', True), 1, 'typed original helper consumer passed observation'),
    ('boolean-operand', set_native(6, 'actual', True), 1, 'typed observer-projected remaining Boolean operand'),
    ('wrong-own-source', wrong_source, 1, SOURCE),
    ('wrong-role', lambda c: row(c, 10).__setitem__('role', 'remaining'), 1, SOURCE),
    ('borrowed-meaning', borrowed, 1, MEANING),
    ('wrong-helper', wrong_helper, 1, MEANING),
    ('wrong-api', wrong_api, 1, MEANING),
    ('wrong-primary', wrong_primary, 1, MEANING),
    ('raw-kind', raw_kind, 1, OPERAND),
    ('storable-copy-kind', storable_kind, 1, OPERAND),
    ('same-wrong-structure', same_wrong_structure, 1, OPERAND),
    ('synthetic-promotion', lambda c: row(c, 3)['meaning']['origin'].__setitem__('native_construction_proven', True), 1, MEANING),
    ('boolean-outcome', lambda c: row(c, 9).__setitem__('outcome', True), 1, 'whole own consumer source and comparison outcome join'),
    ('omit-meaning', lambda c: row(c, 9).__setitem__('meaning', None), 1, MEANING),
    ('wrong-source-custody', wrong_header, 1, 'complete original consumer join source and boundary custody'),
    ('omit-consumer', lambda c: c['modes'][2]['consumers'].pop(), 1, 'complete original source consumer join population'),
    ('omit-mode', lambda c: c['modes'].pop(), 1, 'complete original consumer join mode domain'),
)


if __name__ == '__main__':
    good = load_product('candidate.json.gz')
    rows = []
    for label, mutate, status, cause in CASES:
        candidate = copy.deepcopy(good)
        if mutate:
            mutate(candidate)
            need(not same(candidate, good), 'genuine changed complete consumer-join candidate')
        name = 'control-' + label + '.json.gz'
        save_product(name, candidate)
        command = ['python3', '-B', str(BASE / 'reader.py'), '--candidate', name]
        outer = ['python3', '-B', str(BASE / 'capture.py'), '--expect', str(status), 'control-' + label, *command]
        result = subprocess.run(outer, capture_output=True, text=True)
        actual = json.loads((BASE / ('control-' + label + '-actual.json')).read_bytes())
        need(result.returncode == 0 and type(actual['status']) is int and actual['status'] == status,
             'actual intended independent native consumer-join control status')
        need(actual['programmes'] == actual['programmes_after']
             and actual['command'] == ['scripts/run_with_ram_guard.sh', '--', *command],
             'whole unchanged actual consumer-join control command/programmes')
        if cause:
            need(actual['stdout'] == '' and actual['stderr'].endswith('ValueError: ' + cause + '\n'),
                 'first intended native consumer-join control refusal')
        else:
            from reader import SUCCESS
            need(actual['stdout'] == SUCCESS and actual['stderr'].count('\n') == 1, 'whole positive consumer-join native result')
        need(same(candidate, load_product(name)), 'whole native consumer-join candidate conserves')
        rows.append(dict(label=label, candidate=name, identity=pin(canonical(candidate)), command=actual['command'],
            status=status, cause=cause, native=pin(canonical(actual)),
            outer=dict(command=outer, status=result.returncode, stdout=result.stdout, stderr=result.stderr)))
    save('controls.json', rows)
    print('PASS complete genuine source/meaning/operand/truth join native controls.')

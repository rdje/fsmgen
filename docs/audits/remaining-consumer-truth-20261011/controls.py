"""Complete genuine native remaining-truth controls preserve all other observations."""
import copy
import subprocess
from remaining_common import *


def row(candidate, index):
    return candidate['modes'][0]['consumers'][index]


def mutate_native(candidate, index, **fields):
    row(candidate, index)['native'].update(fields)


def false_deep(candidate):
    row(candidate, 47)['native']['actual'][1]['high'] = 9


def same_false_deep(candidate):
    false_deep(candidate)
    row(candidate, 47)['native']['expected'][1]['high'] = 9


def string_kind(candidate):
    row(candidate, 49)['native']['actual'] = 1


def numeric_json(candidate):
    target = row(candidate, 0)
    value = json.loads(target['native']['actual'])
    value['packet']['type_spec']['width'] = 8
    changed = json.dumps(value, sort_keys=True, separators=(',', ':'))
    target['native'].update(actual=changed, expected=changed)


def source_api(candidate):
    row(candidate, 67)['meaning']['origin']['api'] = 6484


def source_property(candidate):
    row(candidate, 67)['meaning']['origin']['selected'] = ['width']


def actor_property(candidate):
    row(candidate, 16)['meaning']['origin']['source_actor']['watchdog'] = 65535


def source_structure(candidate):
    row(candidate, 47)['meaning']['operand']['actual'][1].pop('low')


def source_outcome(candidate):
    row(candidate, 6)['meaning']['outcome'] = True


def wrong_source(candidate):
    candidate['inputs'][next(iter(candidate['inputs']))]['sha256'] = '0' * 64


def synthetic_trace(candidate):
    row(candidate, 3)['native']['actual'] += 'additional expected_cause_only_in_argument\n'


def synthetic_primary(candidate):
    row(candidate, 4)['native'].update(actual='Changed primary', expected='Changed primary')


def storable_copy_kind(candidate):
    target = candidate['modes'][1]['consumers'][16]['native']['expected']
    target[1]['storage'][1][0][1]['signals'][1][0][1]['type_spec'][1]['members'][1]['data'][1]['width'] = 7


TRUTH = 'independently derived remaining comparison truth contradicts native passed flag'
SOURCE = 'whole independently derived own remaining source operands and outcome'
OPERAND = 'whole source-derived remaining typed consumer operand and truth'
CASES = (
    ('positive', None, 0, None),
    ('false-green-scalar', lambda c: mutate_native(c, 17, actual=9), 1, TRUTH),
    ('false-green-structure', false_deep, 1, TRUTH),
    ('false-green-boolean', lambda c: mutate_native(c, 6, actual=0), 1, TRUTH),
    ('false-green-regex', lambda c: mutate_native(c, 3, actual='Unrelated trace'), 1, TRUTH),
    ('false-green-unlike', lambda c: mutate_native(c, 5, actual='expected_cause_only_in_argument'), 1, TRUTH),
    ('false-red-flag', lambda c: mutate_native(c, 17, passed=0), 1, TRUTH),
    ('boolean-flag', lambda c: mutate_native(c, 17, passed=True), 1, 'typed original remaining consumer passed observation'),
    ('boolean-operand', lambda c: mutate_native(c, 6, actual=True), 1, 'typed observer-projected remaining Boolean operand'),
    ('numeric-kind-only', string_kind, 1, OPERAND),
    ('numeric-json-kind', numeric_json, 1, OPERAND),
    ('same-wrong-structure', same_false_deep, 1, OPERAND),
    ('wrong-storable-copy-kind', storable_copy_kind, 1, OPERAND),
    ('wrong-source-api', source_api, 1, SOURCE),
    ('wrong-source-property', source_property, 1, SOURCE),
    ('wrong-actor-kind', actor_property, 1, SOURCE),
    ('omit-source-property', source_structure, 1, SOURCE),
    ('boolean-source-outcome', source_outcome, 1, SOURCE),
    ('omit-meaning', lambda c: row(c, 6).update(meaning=None), 1, SOURCE),
    ('changed-whole-synthetic-trace', synthetic_trace, 1, OPERAND),
    ('same-wrong-synthetic-primary', synthetic_primary, 1, OPERAND),
    ('promote-synthetic-native', lambda c: c.update(assumptions='Original synthetic native trace construction and identity measured.'), 1,
     'complete original remaining source/native/product/contract boundary custody'),
    ('promote-helper', lambda c: row(c, 9).update(meaning=dict(outcome=1)), 1,
     'whole helper observation retains without truth promotion'),
    ('wrong-source', wrong_source, 1, 'complete original remaining source/native/product/contract boundary custody'),
    ('omit-consumer', lambda c: c['modes'][2]['consumers'].pop(), 1,
     'complete original remaining consumer population including helper observations'),
    ('omit-mode', lambda c: c['modes'].pop(), 1, 'complete remaining original consumer mode domain'),
)


if __name__ == '__main__':
    good = load_product('candidate-v2.json.gz')
    rows = []
    for label, mutate, status, cause in CASES:
        candidate = copy.deepcopy(good)
        if mutate:
            mutate(candidate)
            need(not same(candidate, good), 'genuine changed complete remaining-consumer candidate')
        name = 'control-' + label + '.json.gz'
        save_product(name, candidate)
        command = ['python3', '-B', str(BASE / 'reader.py'), '--candidate', name]
        outer = ['python3', '-B', str(BASE / 'capture.py'), '--expect', str(status), 'control-' + label, *command]
        result = subprocess.run(outer, capture_output=True, text=True)
        actual = json.loads((BASE / ('control-' + label + '-actual.json')).read_bytes())
        need(result.returncode == 0 and type(actual['status']) is int and actual['status'] == status,
             'actual intended independent native remaining-consumer control status')
        need(actual['programmes'] == actual['programmes_after']
             and actual['command'] == ['scripts/run_with_ram_guard.sh', '--', *command],
             'whole unchanged actual remaining-consumer control command/programmes')
        if cause:
            need(actual['stdout'] == '' and actual['stderr'].endswith('ValueError: ' + cause + '\n'),
                 'first intended native remaining-consumer control refusal')
        else:
            from reader import SUCCESS
            need(actual['stdout'] == SUCCESS and actual['stderr'].count('\n') == 1, 'whole positive remaining-consumer native result')
        need(same(candidate, load_product(name)), 'whole native remaining-consumer candidate conserves')
        rows.append(dict(label=label, candidate=name, identity=pin(canonical(candidate)), command=actual['command'],
            status=status, cause=cause, native=pin(canonical(actual)),
            outer=dict(command=outer, status=result.returncode, stdout=result.stdout, stderr=result.stderr)))
    save('controls.json', rows)
    print('PASS complete genuine false-green/false-red/source/API/property/structure/kind/omission/synthetic remaining-consumer native controls.')

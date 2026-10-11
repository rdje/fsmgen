"""Complete native helper-truth controls preserve the other original observations."""
import copy
import subprocess
from helper_common import *


def row(candidate, index):
    return candidate['modes'][0]['consumers'][index]


def flag(candidate):
    row(candidate, 9)['native']['actual'] = 0


def diagnostic(candidate):
    row(candidate, 10)['native']['actual'] = 'Unrelated source failure'


def false_red(candidate):
    row(candidate, 10)['native']['passed'] = 0


def boolean_flag(candidate):
    row(candidate, 9)['native']['passed'] = True


def boolean_operand(candidate):
    row(candidate, 9)['native']['actual'] = True


def pattern(candidate):
    row(candidate, 10)['native']['expected'] = '(?^:absent intended primary)'


def full_stack(candidate):
    target = row(candidate, 10)
    _, domain, index = target['meaning']['first_record']
    name = PLAN['association'] + '/candidate.json.gz'
    source = json.loads(gzip.decompress(fixed([name])[name]))
    actual = source['modes'][0]['domains'][domain]['records'][index]
    need(actual['record'] == target['meaning']['first_record'] and actual['raw'] is not None,
         'whole own original raw stack control operand')
    target['native']['actual'] = actual['raw']['body']


def stack_echo(candidate):
    full_stack(candidate)
    target = row(candidate, 10)
    target['native']['actual'] = 'Unrelated primary diagnostic\n' + target['native']['actual']


def helper(candidate):
    row(candidate, 10)['meaning']['source_helper'] = row(candidate, 12)['meaning']['source_helper']


def first_record(candidate):
    row(candidate, 10)['meaning']['first_record'][2] += 1


def first_primary(candidate):
    row(candidate, 10)['meaning']['primary'] = 'Invalid ISF record value: unrelated primary'


def boolean_outcome(candidate):
    row(candidate, 9)['meaning']['outcome'] = True


def omit_meaning(candidate):
    row(candidate, 9)['meaning'] = None


def nonhelper(candidate):
    row(candidate, 0)['meaning'] = dict(outcome=1)


def wrong_source(candidate):
    candidate['inputs'][next(iter(candidate['inputs']))]['sha256'] = '0' * 64


TRUTH = 'independently derived helper comparison truth contradicts native passed flag'
SOURCE = 'whole independently derived own helper source operands and outcome'
OPERAND = 'whole source-derived helper consumer operand and truth'
CASES = (
    ('positive', None, 0, None),
    ('false-green-negation', flag, 1, TRUTH),
    ('false-green-diagnostic', diagnostic, 1, TRUTH),
    ('false-red-flag', false_red, 1, TRUTH),
    ('boolean-flag', boolean_flag, 1, 'typed original helper consumer passed observation'),
    ('boolean-operand', boolean_operand, 1, 'typed observer-projected helper Boolean operand'),
    ('wrong-native-pattern', pattern, 1, TRUTH),
    ('whole-stack-operand', full_stack, 1, OPERAND),
    ('stack-echo-wrong-primary', stack_echo, 1, OPERAND),
    ('borrow-helper-source', helper, 1, SOURCE),
    ('wrong-first-record', first_record, 1, SOURCE),
    ('wrong-source-primary', first_primary, 1, SOURCE),
    ('boolean-source-outcome', boolean_outcome, 1, SOURCE),
    ('omit-helper-meaning', omit_meaning, 1, SOURCE),
    ('promote-nonhelper', nonhelper, 1, 'whole nonhelper observation retains without truth promotion'),
    ('wrong-source', wrong_source, 1, 'complete original helper source/native/product/contract boundary custody'),
    ('omit-consumer', lambda candidate: candidate['modes'][2]['consumers'].pop(), 1,
     'complete original consumer population including nonhelper observations'),
    ('omit-mode', lambda candidate: candidate['modes'].pop(), 1, 'complete original helper consumer mode domain'),
)


if __name__ == '__main__':
    good = load_product('candidate.json.gz')
    rows = []
    for label, mutate, status, cause in CASES:
        candidate = copy.deepcopy(good)
        if mutate:
            mutate(candidate)
            need(not same(candidate, good), 'genuine changed complete helper-consumer candidate')
        name = 'control-' + label + '.json.gz'
        save_product(name, candidate)
        command = ['python3', '-B', str(BASE / 'reader.py'), '--candidate', name]
        outer = ['python3', '-B', str(BASE / 'capture.py'), '--expect', str(status), 'control-' + label, *command]
        result = subprocess.run(outer, capture_output=True, text=True)
        actual = json.loads((BASE / ('control-' + label + '-actual.json')).read_bytes())
        need(result.returncode == 0 and type(actual['status']) is int and actual['status'] == status,
             'actual intended independent native helper-consumer control status')
        need(actual['programmes'] == actual['programmes_after']
             and actual['command'] == ['scripts/run_with_ram_guard.sh', '--', *command],
             'whole unchanged actual helper-consumer control command/programmes')
        if cause:
            need(actual['stdout'] == '' and actual['stderr'].endswith('ValueError: ' + cause + '\n'),
                 'first intended native helper-consumer control refusal')
        else:
            from reader import SUCCESS
            need(actual['stdout'] == SUCCESS and actual['stderr'].count('\n') == 1, 'whole positive helper-consumer native result')
        need(same(candidate, load_product(name)), 'whole native helper-consumer candidate conserves')
        rows.append(dict(label=label, candidate=name, identity=pin(canonical(candidate)), command=actual['command'],
            status=status, cause=cause, native=pin(canonical(actual)),
            outer=dict(command=outer, status=result.returncode, stdout=result.stdout, stderr=result.stderr)))
    save('controls.json', rows)
    print('PASS complete genuine false-green/false-red/source/helper/primary/stack/pattern/typed/omission helper-consumer native controls.')

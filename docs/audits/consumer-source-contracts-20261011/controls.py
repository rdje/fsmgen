"""Execute whole positive/hostile source contracts with native receipt custody."""
import copy
import subprocess
from consumer_common import *


def omit(candidate):
    candidate['assertions'].pop()


def change(candidate, index, key, value):
    candidate['assertions'][index][key] = value


def expression(candidate):
    candidate['assertions'][0]['assertion']['arguments'][0]['body'] = '$before'


def span(candidate):
    candidate['assertions'][0]['assertion']['start'] += 1


def boolean(candidate):
    candidate['assertions'][0]['assertion']['arguments'][0]['start'] = True


def helper(candidate):
    candidate['assertions'][9]['helper'] = candidate['assertions'][11]['helper']


def source(candidate):
    path = next(iter(candidate['inputs']))
    candidate['inputs'][path]['sha256'] = '0' * 64


def native(candidate):
    candidate['boundary'] = 'Native passed flags establish all consumer operand/outcome truth.'


def context(candidate):
    candidate['assertions'][17]['context']['label'] = candidate['assertions'][20]['context']['label']


CASES = (
    ('positive', None, 0, None),
    ('omit-assertion', omit, 1, 'complete source consumer assertion population'),
    ('wrong-expression', expression, 1, 'whole own exact source assertion and argument expressions'),
    ('wrong-span', span, 1, 'whole own exact source assertion and argument expressions'),
    ('boolean-coordinate', boolean, 1, 'whole own exact source assertion and argument expressions'),
    ('borrow-helper', helper, 1, 'whole own source helper statement declaration and operation membership'),
    ('borrow-loop-context', context, 1, 'exact own expanded consumer kind label caller helper source context'),
    ('wrong-operand-role', lambda value: change(value, 0, 'operand_role', 'own_value_api_result_or_exact_selected_scalar'),
     1, 'own required source operand interpretation role'),
    ('borrow-dataflow-scope', lambda value: change(value, 0, 'source_scope', value['assertions'][17]['source_scope']),
     1, 'whole own authored actor type path API and mutation dataflow scope'),
    ('wrong-source', source, 1, 'whole original consumer input/source/task/native boundary custody'),
    ('native-promotion', native, 1, 'whole original consumer input/source/task/native boundary custody'),
)


if __name__ == '__main__':
    good = load_product('candidate.json.gz')
    rows = []
    for label, mutate, status, cause in CASES:
        candidate = copy.deepcopy(good)
        if mutate:
            mutate(candidate)
            need(not same(candidate, good), 'genuine changed complete source-contract candidate')
        name = 'control-' + label + '.json.gz'
        save_product(name, candidate)
        command = ['python3', '-B', str(BASE / 'reader.py'), '--candidate', name]
        outer = ['python3', '-B', str(BASE / 'capture.py'), '--expect', str(status), 'control-' + label, *command]
        result = subprocess.run(outer, capture_output=True, text=True)
        row = json.loads((BASE / ('control-' + label + '-actual.json')).read_bytes())
        need(result.returncode == 0 and type(row['status']) is int and row['status'] == status,
             'actual independent native source-contract control result')
        need(row['programmes'] == row['programmes_after'] and row['command'] == ['scripts/run_with_ram_guard.sh', '--', *command],
             'complete unchanged native source-contract command/programme epoch')
        if cause:
            need(row['stdout'] == '' and row['stderr'].endswith('ValueError: ' + cause + '\n'),
                 'actual first intended source-contract refusal')
        else:
            from reader import SUCCESS
            need(row['stdout'] == SUCCESS and row['stderr'].count('\n') == 1, 'actual whole positive source-contract terminal')
        need(same(candidate, load_product(name)), 'whole control candidate conserves around native execution')
        rows.append(dict(label=label, candidate=name, identity=pin(canonical(candidate)),
                         command=row['command'], status=status, cause=cause,
                         native=pin(canonical(row)), outer=dict(command=outer, status=result.returncode,
                                                               stdout=result.stdout, stderr=result.stderr)))
    save('controls.json', rows)
    print('PASS complete positive and genuine native source-expression/context/helper/typed-coordinate/source/boundary controls.')

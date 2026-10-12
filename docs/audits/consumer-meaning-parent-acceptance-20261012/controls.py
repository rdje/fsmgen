"""Genuine complete parent controls, including every qualified join mutation."""
import importlib
from acceptance_common import *
import meaning_readers


def join_case(label):
    def mutate(candidate):
        with meaning_readers.isolated('join'):
            controls = importlib.import_module('controls_v2')
            matches = [row for row in controls.CASES if row[0] == label]
            need(len(matches) == 1 and matches[0][1] is not None, 'whole qualified original join mutation source')
            matches[0][1](candidate['children']['join'])
    return mutate


def parent_goal(candidate):
    candidate['contracts']['parent'] = candidate['contracts']['parent'].replace(
        'Independently derive complete original consumer operands and truth.',
        'Accept only successful native flags.', 1)


def borrowed(candidate):
    candidate['children']['join'] = candidate['children']['helper']


def helper_flag(candidate):
    candidate['children']['helper']['modes'][0]['consumers'][9]['native']['actual'] = 0


def remaining_kind(candidate):
    candidate['children']['remaining']['modes'][0]['consumers'][47]['native']['actual'][1]['type_spec'][1]['signed'] = 1


# The complete qualified join mutation declarations retain their original
# source and expected first causes. Every one executes anew through this
# parent's complete independent reader, rather than borrowing prior statuses.
prior = json.loads(fixed([PLAN['join'] + '/controls-v2.json'])[PLAN['join'] + '/controls-v2.json'])
need(len(prior) == 26 and prior[0]['label'] == 'positive' and prior[0]['cause'] is None,
     'complete committed original join control declarations')
CASES = [('positive', None, 0, None)]
CASES.extend(('join-' + row['label'], join_case(row['label']), 1, row['cause']) for row in prior[1:])
CASES.extend((
    ('weaken-parent-goal', parent_goal, 1, 'whole unchanged parent/descendant/source/boundary contract custody'),
    ('borrow-successful-helper-as-join', borrowed, 1, 'complete original consumer join source and boundary custody'),
    ('false-green-helper-child', helper_flag, 1, 'independently derived helper comparison truth contradicts native passed flag'),
    ('wrong-kind-remaining-child', remaining_kind, 1, 'whole source-derived remaining typed consumer operand and truth'),
    ('omit-child', lambda value: value['children'].pop('remaining'), 1, 'complete independent meaning child domain'),
    ('boolean-schema', lambda value: value.__setitem__('schema_version', True), 1, 'closed complete original meaning-parent schema'),
))
CASES = tuple(CASES)

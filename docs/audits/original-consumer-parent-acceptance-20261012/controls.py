"""Genuine complete original source, meaning and parent-link separating controls."""
from parent_common import *
import interfaces


def original_cases(role):
    root = PLAN['source_contract' if role == 'source' else 'meaning']
    name = root + '/controls.json'
    rows = json.loads(fixed([name])[name])
    result = [(row['label'], row['status'], row['cause']) for row in rows]
    need(result[0] == ('positive', 0, None) and all(type(status) is int and status == 1 and type(cause) is str
         for _, status, cause in result[1:]), 'whole qualified original native control declarations')
    return tuple(result)


def apply_original(role, label, candidate):
    context = interfaces.isolated_source if role == 'source' else interfaces.isolated_meaning
    with context() as (reader, controls):
        if role == 'meaning':
            for name in ('helper', 'remaining', 'join'):
                interfaces.namespace(controls.meaning_readers.ROLES[name][0])
        matches = [row for row in controls.CASES if row[0] == label]
        need(len(matches) == 1, 'unique complete qualified original native mutation')
        if matches[0][1] is not None:
            matches[0][1](candidate)


def weaken_parent(candidate):
    old = 'Independently qualify every original consumer operand and outcome.'
    body = candidate['contracts']['parent']
    need(body.count(old) == 1, 'whole unique unchanged original consumer Goal')
    candidate['contracts']['parent'] = body.replace(old, 'Accept only original native passed flags.', 1)


def omit_mode(candidate):
    candidate['links'] = [row for row in candidate['links'] if row['mode'] != 'controls']


PARENT = (
    ('positive', None, 0, None),
    ('boolean-schema', lambda c: c.update(schema_version=True), 1, 'closed complete original-consumer schema'),
    ('weaken-parent-goal', weaken_parent, 1, 'whole unchanged original consumer source descendant and boundary contract custody'),
    ('omit-source-descendant', lambda c: c['contracts']['descendants'].pop(PLAN['parent'] + '.1'), 1,
     'whole unchanged original consumer source descendant and boundary contract custody'),
    ('omit-canonical-grandchild', lambda c: c['contracts']['descendants'].pop(PLAN['parent'] + '.3.3'), 1,
     'whole unchanged original consumer source descendant and boundary contract custody'),
    ('full-alias-promotion', lambda c: c.update(boundary='All full alias downstream mutations and abort are complete.'), 1,
     'whole unchanged original consumer source descendant and boundary contract custody'),
    ('omit-link', lambda c: c['links'].pop(), 1, 'complete original source operand truth link domain'),
    ('omit-mode', omit_mode, 1, 'complete original source operand truth link domain'),
    ('borrow-source-binding', lambda c: c['links'][0].update(source=c['links'][1]['source']), 1,
     'whole independently rederived source-derived original consumer link'),
    ('borrow-operand', lambda c: c['links'][0].update(operand=c['links'][20]['operand']), 1,
     'whole independently rederived source-derived original consumer link'),
    ('boolean-outcome', lambda c: c['links'][0].update(outcome=True), 1, 'closed typed complete original consumer link'),
    ('false-green-link', lambda c: c['links'][0].update(outcome=0), 1,
     'whole independently rederived source-derived original consumer link'),
    ('duplicate-mode-binding', lambda c: c['links'][0].update(mode='storable'), 1,
     'unique original mode source assertion link'),
    ('borrow-native-binding', lambda c: c['links'][0].update(native=c['links'][1]['native']), 1,
     'whole independently rederived source-derived original consumer link'),
    ('omit-meaning-child', lambda c: c['meanings']['children'].pop('remaining'), 1, 'complete independent meaning child domain'),
    ('false-green-meaning', lambda c: apply_original('meaning', 'false-green-helper-child', c['meanings']), 1,
     'independently derived helper comparison truth contradicts native passed flag'),
    ('native-promotion', lambda c: c['admission']['scope'].update(native_identity=True), 1,
     'whole admitted consumer source native private boundary'),
    ('borrow-success-for-failure', lambda c: c['failures']['canonical-development-preflight'].update(status=0), 1,
     'whole original first failures retain distinct actual and declared statuses'),
    ('boolean-original-declaration', lambda c: c['failures']['preparation-size'].update(expected_status=False), 1,
     'typed original unexpected consumer size refusal'),
)
SOURCE = original_cases('source')
MEANING = original_cases('meaning')


def declarations():
    return [('parent', label, status, cause) for label, mutate, status, cause in PARENT] + [
        ('source', label, status, cause) for label, status, cause in SOURCE] + [
        ('meaning', label, status, cause) for label, status, cause in MEANING]


def mutate(role, label, candidate):
    if role != 'parent':
        apply_original(role, label, candidate)
    else:
        matches = [row for row in PARENT if row[0] == label]
        need(len(matches) == 1, 'unique complete original-parent link mutation')
        if matches[0][1] is not None:
            matches[0][1](candidate)

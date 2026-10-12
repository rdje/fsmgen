"""Genuine original meaning and complete canonical-parent separating controls."""
from parent_common import *
import interfaces


def original_cases():
    name = PLAN['meaning'] + '/controls.json'
    rows = json.loads(fixed([name])[name])
    result = [(row['label'], row['status'], row['cause']) for row in rows]
    need(result[0] == ('positive', 0, None) and all(type(status) is int and status == 1 and type(cause) is str
         for _, status, cause in result[1:]), 'complete qualified original meaning control declarations')
    return tuple(result)


def apply_meaning(candidate, label):
    with interfaces.isolated_meaning() as (reader, controls):
        for role in ('helper', 'remaining', 'join'):
            interfaces.namespace(controls.meaning_readers.ROLES[role][0])
        matches = [row for row in controls.CASES if row[0] == label]
        need(len(matches) == 1, 'unique qualified original meaning mutation source')
        if matches[0][1] is not None:
            matches[0][1](candidate)


def weaken_parent(candidate):
    old = 'Publish only admitted source-bound consumer canonical meanings.'
    body = candidate['contracts']['parent']
    need(body.count(old) == 1, 'unique unchanged full canonical Goal')
    candidate['contracts']['parent'] = body.replace(old, 'Accept only successful native flags.', 1)


def lose_question(candidate):
    card = PLAN['target']
    question = '  - "what qualifies finite original exception classes?"\n'
    need(candidate['current']['cards'][card].count(question) == 1, 'unique retained original canonical question')
    candidate['current']['cards'][card] = candidate['current']['cards'][card].replace(question, '', 1)


CANONICAL = (
    ('positive', None, 0, None),
    ('boolean-schema', lambda c: c.update(schema_version=True), 1, 'closed complete canonical-parent schema'),
    ('weaken-parent-goal', weaken_parent, 1, 'whole unchanged canonical source descendant and boundary contract custody'),
    ('omit-descendant', lambda c: c['contracts']['descendants'].pop(PLAN['parent'] + '.2'), 1,
     'whole unchanged canonical source descendant and boundary contract custody'),
    ('native-promotion', lambda c: c['admission']['scope'].update(native_identity=True), 1,
     'whole admitted consumer source native private boundary'),
    ('lose-question', lose_question, 1, 'complete current target meanings questions metadata and replay routes'),
    ('boolean-query-status', lambda c: c['current']['queries']['direct'].update(status=False), 1,
     'actual current query integer success'),
    ('borrow-query-command', lambda c: c['current']['queries']['direct'].update(command=c['current']['queries']['cached']['command']), 1,
     'distinct actual current query command and streams'),
    ('omit-meaning-child', lambda c: c['meanings']['children'].pop('remaining'), 1, 'complete independent meaning child domain'),
    ('false-green-meaning', lambda c: apply_meaning(c['meanings'], 'false-green-helper-child'), 1,
     'independently derived helper comparison truth contradicts native passed flag'),
    ('boolean-original-declaration', lambda c: c['failures']['preparation-size'].update(expected_status=False), 1,
     'typed original unexpected consumer size refusal'),
    ('borrow-success-for-staging', lambda c: c['failures']['publication-staging'].update(status=0), 1,
     'whole original first failures retain distinct actual and declared statuses'),
    ('omit-staging-failure', lambda c: c['failures'].pop('publication-staging'), 1,
     'whole original first failures retain distinct actual and declared statuses'),
)
MEANING = original_cases()


def declarations():
    return [('canonical', label, status, cause) for label, mutate, status, cause in CANONICAL] + [
        ('meaning', label, status, cause) for label, status, cause in MEANING]


def mutate(role, label, candidate):
    if role == 'meaning':
        apply_meaning(candidate, label)
    else:
        matches = [row for row in CANONICAL if row[0] == label]
        need(len(matches) == 1, 'unique complete canonical-parent mutation')
        if matches[0][1] is not None:
            matches[0][1](candidate)

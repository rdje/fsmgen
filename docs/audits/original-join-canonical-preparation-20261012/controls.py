"""Genuine complete canonical proposals separating each declared authority boundary."""
import copy
from preparation_inputs import *


def declarations(candidate):
    rows = [dict(label='positive', path=[], action='retain', cause=None, status=0)]

    def add(label, path, action, cause, value=None):
        rows.append(dict(label=label, path=path, action=action, value=value, cause=cause, status=1))

    schema = 'closed typed complete original-join canonical schema'
    source = 'complete own committed association input identities'
    boundary = 'complete original assumptions failures native private and scope boundaries'
    member = next(iter(candidate['input_identities']))
    contract = next(iter(candidate['contracts']))
    canonical_member = next(iter(candidate['canonical_members']))
    add('schema-boolean', ['schema_version'], 'set', schema, True)
    add('wrong-revision', ['revision'], 'set', schema, '0' * 40)
    add('borrowed-source', ['input_identities', member, 'sha256'], 'set', source, '0' * 64)
    add('float-source-bytes', ['input_identities', member, 'bytes'], 'float', source)
    add('omitted-source', ['input_identities', member], 'delete', source)
    add('original-contract', ['contracts', contract], 'truncate', 'every unchanged original parent and descendant contract')
    add('omitted-contract', ['contracts', contract], 'delete', 'every unchanged original parent and descendant contract')
    for key in sorted(candidate['scope']['assurance']):
        add('promotion-' + key.replace('_', '-'), ['scope', 'assurance', key], 'set', boundary, True)
    add('borrowed-cause', ['scope', 'original', 'qualification', 'sha256'], 'set', boundary, '0' * 64)
    add('observed-flag-truth', ['scope', 'original', 'truth_authority'], 'set', boundary, 'native passed flag')
    failure = next(iter(candidate['scope']['original']['failures']['reproductions']))
    add('first-false-green', ['scope', 'original', 'failures', 'reproductions', failure, 'first', 'sha256'],
        'set', boundary, candidate['scope']['original']['failures']['reproductions'][failure]['corrected']['sha256'])
    add('omitted-prior-control', ['scope', 'original', 'controls'], 'pop', boundary)
    add('borrowed-canonical', ['canonical_members', canonical_member, 'sha256'], 'set',
        'every own canonical source membership and whole body', '0' * 64)
    add('omitted-canonical', ['canonical_members', canonical_member], 'delete',
        'every own canonical source membership and whole body')
    add('original-question', ['before'], 'truncate', 'whole own original target beforeimage')
    add('omitted-meaning', ['after'], 'truncate', 'whole independently allocated joined meanings and retained facts')
    add('borrowed-target-body', ['after'], 'set', 'whole independently allocated joined meanings and retained facts', candidate['before'])
    add('growing-target', ['after'], 'set', 'whole independently allocated joined meanings and retained facts', candidate['after'] + 'Extra unqualified fact.\n')
    add('float-target-bytes', ['after_identity', 'bytes'], 'float', 'whole independently allocated joined meanings and retained facts')
    add('omitted-paragraph', ['correspondence'], 'pop', 'complete original paragraph population')
    add('boolean-paragraph-index', ['correspondence', 0, 'index'], 'set',
        'whole typed ordered original paragraph and reviewed meaning correspondence', False)
    add('wrong-paragraph', ['correspondence', 0, 'after'], 'truncate',
        'whole typed ordered original paragraph and reviewed meaning correspondence')
    add('wrong-review', ['review', 'meanings'], 'truncate', 'every reviewed change consumed once and complete review retains')
    add('float-capacity', ['proposed', 'bytes_total'], 'float', 'complete typed independently measured non-growing capacity')
    add('wrong-capacity', ['proposed', 'bytes_total'], 'increment', 'complete typed independently measured non-growing capacity')
    add('widened-allowance', ['authority', 'enforcement_ceilings', 'bytes_total'], 'increment',
        'unchanged whole collection and card capacity authority')
    add('omitted-query', ['queries', 'direct'], 'delete', 'whole actual distinct direct and cached canonical question allocation')
    add('false-query-success', ['queries', 'direct', 'status'], 'set',
        'whole actual distinct direct and cached canonical question allocation', False)
    need(len({row['label'] for row in rows}) == len(rows), 'unique complete canonical separating declarations')
    return rows


def get(value, path):
    for key in path:
        value = value[key]
    return value


def mutate(candidate, row):
    action, path = row['action'], row['path']
    if action == 'retain':
        return
    parent, key = get(candidate, path[:-1]), path[-1]
    old = parent[key]
    if action == 'set':
        parent[key] = copy.deepcopy(row['value'])
    elif action == 'delete':
        del parent[key]
    elif action == 'pop':
        need(type(old) is list and bool(old), 'genuine nonempty omission target')
        old.pop()
    elif action == 'truncate':
        need(type(old) is str and bool(old), 'whole nonempty string mutation target')
        parent[key] = old[:-1]
    elif action in ('float', 'increment'):
        need(type(old) is int, 'typed integer mutation target')
        parent[key] = float(old) if action == 'float' else old + 1
    else:
        raise ValueError('undeclared canonical mutation')

"""Independently qualify complete finite assertion source contracts."""
import argparse
import re
from consumer_common import *
import contract_inputs as inputs

SUCCESS = 'PASS complete original consumer source expressions, helper/loop allocation and typed operand roles; operand/outcome truth remains open.\n'


def expression(source, context):
    # This independent reader uses the finite statement terminator and a
    # quote-masked delimiter census. It does not call the proposal extractor.
    offsets = [0]
    for line in source.splitlines(keepends=True):
        offsets.append(offsets[-1] + len(line))
    line = context['caller'][2]
    left, right = offsets[line - 1:line + 1]
    token = context['kind'] + '('
    need(source[left:right].count(token) == 1, 'own exact finite source assertion location')
    start = source.index(token, left, right)
    end = source.index(');', start) + 2
    opening = start + len(token)
    body = source[opening:end - 2]
    quoted = r'''qr/(?:\\.|[^/\\])*/|'(?:\\.|[^'\\])*'|"(?:\\.|[^"\\])*"'''
    masked = re.sub(quoted, lambda match: ' ' * len(match[0]), body)
    depth = {'(': 0, '[': 0, '{': 0}
    closing = {')': '(', ']': '[', '}': '{'}
    cuts = [-1]
    for index, char in enumerate(masked):
        if char in depth:
            depth[char] += 1
        elif char in closing:
            depth[closing[char]] -= 1
            need(min(depth.values()) >= 0, 'independent finite source delimiter domain')
        elif char == ',' and not any(depth.values()):
            cuts.append(index)
    need(not any(depth.values()), 'whole independent source argument delimiter conservation')
    cuts.append(len(body))
    arguments = []
    for first, last in zip(cuts, cuts[1:]):
        raw = body[first + 1:last]
        begin = opening + first + 1 + len(raw) - len(raw.lstrip())
        finish = opening + last - len(raw) + len(raw.rstrip())
        arguments.append(dict(start=begin, end=finish, body=source[begin:finish]))
    return dict(start=start, end=end, body=source[start:end], arguments=arguments)


def check(candidate):
    data = inputs.inputs()
    header = inputs.candidate_header(data)
    need(type(candidate) is dict and set(candidate) == set(header) | {'assertions'}
         and type(candidate['schema_version']) is int, 'closed whole consumer source-contract schema')
    need(same({key: candidate[key] for key in header}, header), 'whole original consumer input/source/task/native boundary custody')
    rows = candidate['assertions']
    need(type(rows) is list and len(rows) == len(data['consumers']) == 125,
         'complete source consumer assertion population')
    unique, helpers = set(), set()
    for index, (row, context) in enumerate(zip(rows, data['consumers'], strict=True)):
        need(set(row) == {'context', 'assertion', 'operand_role', 'helper', 'source_scope'}
             and same(row['context'], context) and context['index'] == index,
             'exact own expanded consumer kind label caller helper source context')
        expected = expression(data['source'], context)
        need(same(row['assertion'], expected), 'whole own exact source assertion and argument expressions')
        arity = 2 if context['kind'] == 'ok' else 3
        need(len(expected['arguments']) == arity
             and all(type(item['start']) is int and type(item['end']) is int for item in expected['arguments']),
             'complete typed source operand label argument allocation')
        need(row['operand_role'] == inputs.role(context), 'own required source operand interpretation role')
        helper = None if context['helper'] is None else data['helpers'][context['helper']]
        need(same(row['helper'], helper), 'whole own source helper statement declaration and operation membership')
        operation = expected['start'] if helper is None else data['source'].index(helper['source_statement'])
        bounds = [match.start() for match in re.finditer(r"^subtest '", data['source'], re.M)]
        bounds.append(data['source'].index('done_testing;') - 1)
        positions = [(left, right) for left, right in zip(bounds, bounds[1:]) if left <= operation < right]
        need(len(positions) == 1, 'unique complete source consumer dataflow allocation')
        begin, finish = positions[0]
        # Consecutive subtests are separated by a newline; retain the exact
        # preceding whole body while excluding the next statement's newline.
        if data['source'][finish:finish + 1] != '\n':
            finish -= 1
        need(same(row['source_scope'], dict(start=begin, end=finish, body=data['source'][begin:finish])),
             'whole own authored actor type path API and mutation dataflow scope')
        for mode in inputs.MODES:
            native = data['native'][mode]
            need(len(native) == len(rows) and same({key: native[index][key] for key in ('kind', 'label', 'helper', 'caller')},
                 {key: context[key] for key in ('kind', 'label', 'helper', 'caller')}),
                 'complete own original mode consumer source context allocation')
        if helper is not None:
            helpers.add(helper['index'])
            need(index in helper['consumer_members'], 'complete own source helper consumer span')
        unique.add((expected['start'], expected['end']))
    need(helpers == set(range(43)), 'every source helper expansion is consumed')
    return dict(owner=PLAN['owner'], revision=PLAN['revision'], candidate=pin(canonical(candidate)),
        inputs=data['identities'], source_roles=data['source_roles'], assertions=len(rows),
        physical_source_assertions=len(unique), helpers=len(helpers),
        contexts=pin(canonical(data['consumers'])), native=header['native'],
        condition=PLAN['condition'],
        assumptions='Qualified original source contexts, actor/type/API/product/cause inputs remain shared assumptions. This independent source-expression admission does not derive consumer operands or truth, including synthetic trace/private/native meanings.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--candidate', default='candidate.json.gz')
    parser.add_argument('--save', action='store_true')
    args = parser.parse_args()
    need(Path(args.candidate).name == args.candidate and args.candidate.endswith('.json.gz'), 'ordinary own source-contract candidate route')
    result = check(load_product(args.candidate))
    if args.save:
        need(args.candidate == 'candidate.json.gz', 'only positive source-contract admission publishes')
        save('qualification.json', result)
    print(SUCCESS, end='')

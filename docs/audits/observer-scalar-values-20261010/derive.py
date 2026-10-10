"""Derive whole scalar membership and finite recipes before native observation."""
from pathlib import Path
from common import BASE, CENSUS, SCOPE, canonical, module, need, pin, read, save


def source():
    classes = module(Path('docs/audits/record-value-original-class-20261005/verify.py'))
    public = module(Path('docs/audits/record-value-public-boundary-join-20261006/verify.py'))
    builder = module(Path('docs/audits/record-value-class-frame-join-20261006/model.py'))
    actual = builder['derive'](classes, public, classes['require'], classes['same'])
    need(canonical(actual) == canonical(read(CENSUS / 'source-models.json')),
         'complete qualified own-source model rederived before scalar selection')
    return actual


def collect(census):
    values, members = {}, []
    for row in census['operands']:
        if row['schema'] not in ('scalar', 'context_scalar') or row['input']['role'] == 'guard predicate':
            continue
        operand = row['input']
        value = operand['value' if row['schema'] == 'scalar' else 'source_value']
        need(value is None or type(value) in (str, int), 'complete typed source scalar')
        identifier = pin(canonical(value))['sha256']
        values[identifier] = dict(value=value, constructor=('undef' if value is None else
            'numeric literal' if type(value) is int else 'complete codepoint string'))
        members.append(dict(path=row['path'], schema=row['schema'], operand=operand, value=identifier,
            evidence_role=('inherited serialized evidence' if operand['role'] == 'entire_context_and_inner_error'
                           else 'qualified own-source value')))
    return dict(scope=SCOPE, values=values, members=members)


def display(value, limit):
    if value is None:
        return dict(token='undef', complete=True, prefix=None)
    if type(value) is int:
        return dict(token=str(value), complete=True, prefix=str(value))
    # The complete current corpus contains only these finite numeric-looking
    # string forms. No general numeric conversion contract is inferred.
    numeric = value in ('0', '1', '2')
    shortened = not numeric and limit >= 3 and len(value) > limit
    prefix = value[:limit - 3] if shortened else value
    escaped = ''.join('\\x{' + format(ord(c), 'x') + '}' if ord(c) < 32 or ord(c) >= 127
                      else '\\' + c if c in '\\"$@' else c for c in prefix)
    token = prefix if numeric else '"' + escaped + '"' + ('...' if shortened else '')
    return dict(token=token, complete=not shortened, prefix=prefix)


def plan(product):
    cases = []
    for identifier, item in sorted(product['values'].items()):
        for limit in (64, 0):
            cases.append(dict(id=identifier + ':' + str(limit), value_id=identifier,
                value=item['value'], constructor=item['constructor'], limit=limit,
                display=display(item['value'], limit)))
    return dict(scope=SCOPE, profile=dict(MaxArgNums=0, MaxEvalLen=0, RefArgFormatter=None), cases=cases)


def main():
    source()
    product = collect(read(CENSUS / 'census.json'))
    save('scalars.json', product)
    save('plan.json', plan(product))
    save('pre-observation.json', dict(inputs={str(p):pin(p.read_bytes()) for p in
         [CENSUS / 'census.json', CENSUS / 'source-models.json', *sorted(BASE.glob('*.py')),
          BASE / 'native.pl', BASE / 'scalars.json', BASE / 'plan.json']},
         scope=SCOPE, native_present=(BASE / 'native.json').exists()))
    need(not (BASE / 'native.json').exists(), 'source selection precedes native observation')
    print('PASS complete source scalar selection and current display hypotheses before native capture.')


if __name__ == '__main__':
    main()

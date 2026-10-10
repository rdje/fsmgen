"""Independent finite source/display oracle; imports no producer or its renderer."""
import json
from pathlib import Path

BASE = Path('docs/audits/observer-display-contract-20261010')
CATALOGUE_ROLE = 'Complete source-neutral finite qualifying corpus selected before native capture; no original header intake.'
WIRE_ROLE = 'Own current public display fixtures; original formatter/settings/provider identity is unmeasured.'
PRODUCT_SCOPE = 'Own current public source/holder/display contract only; no original formatter/settings or cross-call identity inference.'


def identical(a, b):
    return json.dumps(a, sort_keys=True, ensure_ascii=True, allow_nan=False) == json.dumps(b, sort_keys=True, ensure_ascii=True, allow_nan=False)


def must(condition, cause):
    if not condition:
        raise ValueError(cause)


def selected():
    """Reconstruct the entire declared matrix independently of select_cases.py."""
    result = []
    def s(value, flag=False):
        return dict(kind='string', codepoints=[ord(c) for c in value], utf8=flag)
    def c(name, args, length=64, number=8, formatter=False):
        result.append(dict(id=name, arguments=args, profile=dict(arg_len=length, arg_nums=number, formatter=formatter)))
    for n in range(256):
        c('byte-' + str(n), [s('V' + chr(n) + 'W')])
    upgraded = [0, 9, 10, 13, 31, 32, 34, 65, 92, 126, 127, 128, 233, 255, 256, 9731, 128578]
    for n in upgraded:
        c('upgraded-' + str(n), [s('U' + chr(n) + 'Z', True)])
    sizes = list(range(9)) + [15, 16, 63, 64, 65, 66]
    for limit in [-1, 0, 1, 2, 3, 4, 5, 8, 16, 64]:
        for size in sizes:
            c('boundary-' + str(limit) + '-' + str(size), [s(('A' + '"' + '\\' + '\n' + chr(9731)) * 20)], limit)
            result[-1]['arguments'][0]['codepoints'] = result[-1]['arguments'][0]['codepoints'][:size]
    values = ['', '0', '007', '-9', '1.5', '3.', '.75', '-.75', '4e+2', '5E-2', '+8', ' 14 ',
              'NaN', 'Inf', '.', '9' * 65, '8' * 66, '7' * 64, '1..2', 'a"\\b']
    for n, value in enumerate(values):
        c('scalar-' + str(n), [s(value)])
    c('undefined', [dict(kind='undef')])
    for value in ['0', '12', '-7', '1.5']:
        c('numeric-constructor-' + value, [dict(kind='number', value=value)])
    c('dual-constructor', [dict(kind='dual', number=42, codepoints=[ord(c) for c in 'qualified-dual'], utf8=False)])
    patterns = ['qualified[a-z]+', '\\d+\\s?', 'R' * 64, 'S' * 65, 'a"b', 'a\nb', 'a' + chr(9731) + 'b']
    for formatter in [False, True]:
        for kind in ['HASH', 'ARRAY', 'CODE', 'plain', 'traced', 'overloaded']:
            c('reference-' + kind + '-' + str(formatter), [dict(kind=kind, id='held')], formatter=formatter)
        for n, value in enumerate(patterns):
            c('regex-' + str(n) + '-' + str(formatter), [dict(kind='REGEXP', id='held',
                codepoints=[ord(ch) for ch in value], utf8=False)], formatter=formatter)
    c('held-alias-and-distinction', [dict(kind='HASH', id='left'), dict(kind='HASH', id='right'),
                                  dict(kind='alias', target='left'), dict(kind='alias', target='right')])
    for number in [-1, 0, 1, 2, 8]:
        for size in [0, 1, 2, 3, 7, 8, 9, 10]:
            c('arity-' + str(number) + '-' + str(size), [s('argument-' + str(n)) for n in range(size)], number=number)
    for flag in [False, True]:
        for formatter in [False, True]:
            for name, value in [('ascii', 'abc'), ('latin', 'a' + chr(233) + 'b'), ('wide', 'a' + chr(9731) + 'b'), ('syntax', 'a$@\\"b')]:
                c('repaired-probe-' + name + '-' + str(flag) + '-' + str(formatter),
                  [dict(kind='REGEXP', id='held', codepoints=[ord(ch) for ch in value], utf8=flag)], formatter=formatter)
    values = ['4' * 65, '4' * 65 + 'X', '4' * 61 + 'X' * 4, 'X' + '4' * 65,
              '-9' * 40, '1' * 63 + '.5', '1' * 61 + 'e+77']
    for n, value in enumerate(values):
        c('repaired-probe-numeric-order-' + str(n), [s(value)])
    for limit in [0, 3, 4, 64]:
        for flag in [False, True]:
            c('repaired-suffix-wide-truncation-' + str(limit) + '-' + str(flag),
              [dict(kind='REGEXP', id='held', codepoints=[ord(ch) for ch in 'T' * 64 + chr(9731)], utf8=flag)], limit)
    return dict(role=CATALOGUE_ROLE, cases=result)


def digits(value):
    return bool(value) and all('0' <= c <= '9' for c in value)


def numeric(value):
    """Recognize the finite numeric spelling using components, without regex."""
    parts = value.lower().split('e')
    if len(parts) > 2:
        return False
    if len(parts) == 2:
        exponent = parts[1]
        if exponent.startswith(('+', '-')):
            exponent = exponent[1:]
        if not digits(exponent):
            return False
    mantissa = parts[0]
    if mantissa.startswith('-'):
        mantissa = mantissa[1:]
    fraction = mantissa.split('.')
    return len(fraction) <= 2 and digits(fraction[0]) and (len(fraction) == 1 or fraction[1] == '' or digits(fraction[1]))


def spelling(recipe):
    return recipe['value'] if recipe['kind'] == 'number' else ''.join(map(chr, recipe['codepoints']))


def display(value, limit, regexp=False, flags=""):
    bare = not regexp and numeric(value)
    shortened = not bare and limit > 2 and len(value) > limit
    prefix = ''.join(value[n] for n in range(limit - 3)) if shortened else value
    units = []
    for code in map(ord, prefix):
        if code not in range(32, 127):
            units.append('\\x{' + hex(code)[2:] + '}')
        elif not regexp and code in (34, 36, 64, 92):
            units.append('\\' + chr(code))
        else:
            units.append(chr(code))
    visible = shortened and not bare
    if bare:
        token = prefix
    elif regexp:
        token = 'qr(' + ''.join(units) + ')' + ('...' if visible else '') + flags
    else:
        token = '"' + ''.join(units) + '"' + ('...' if visible else '')
    return dict(token=token, source=value, display_prefix=prefix, truncated=shortened,
                visible_ellipsis=visible, numeric_display=bare, token_is_complete_source_value=not shortened)


def plans(catalogue):
    result = []
    classes = dict(plain='ObserverDisplayFixture::Plain', traced='ObserverDisplayFixture::Traced',
                   overloaded='ObserverDisplayFixture::Overloaded', REGEXP='Regexp')
    for case in catalogue['cases']:
        p = case['profile']
        profile = dict(arg_len=p['arg_len'], arg_nums=p['arg_nums'], eval_len=0,
                       formatter='defined' if p['formatter'] else 'undef')
        rows, held = [], {}
        for n, authored in enumerate(case['arguments']):
            origin = held[authored['target']] if authored['kind'] == 'alias' else n
            recipe = case['arguments'][origin]
            kind = recipe['kind']
            row = dict(index=n, recipe=recipe, source_slot=origin)
            if kind == 'undef':
                row['display'] = dict(token='undef', truncated=False, token_is_complete_source_value=True)
            elif kind in ['number', 'dual', 'string']:
                row['display'] = display(spelling(recipe), p['arg_len'])
            else:
                held[recipe['id']] = origin
                row['reference'] = dict(type=kind if kind in ['HASH', 'ARRAY', 'CODE', 'REGEXP'] else 'HASH',
                                        **{'class': classes.get(kind)}, source_slot=origin)
                if kind == 'traced' or (p['formatter'] and kind != 'REGEXP'):
                    row['display'] = dict(token='own-trace-token' if kind == 'traced' else 'own-reference-formatter-token',
                                          truncated=False, token_is_complete_source_value=False)
                elif kind == 'REGEXP':
                    row['display'] = display(spelling(recipe), p['arg_len'], True, 'u' if recipe['utf8'] or any(n > 255 for n in recipe['codepoints']) else '')
                else:
                    row['display'] = dict(address_from_source_slot=origin, truncated=False, token_is_complete_source_value=False)
            rows.append(row)
        ceiling = len(rows) if p['arg_nums'] == 0 else max(p['arg_nums'], 0)
        visible = [n for n in range(len(rows)) if n < ceiling]
        result.append(dict(id=case['id'], profile=profile, slots=rows, visible_slots=visible,
                           hidden_slots=list(range(len(visible), len(rows))),
                           remaining_arguments=p['arg_nums'] < 0 or len(visible) < len(rows)))
    return result


def views(plan, observed):
    values = observed['before']
    must(identical(values, observed['after']) and len(values) == len(plan['slots']), 'source argument conservation')
    for n, slot in enumerate(plan['slots']):
        source, got = slot['recipe'], values[n]
        kind = source['kind']
        if kind == 'undef':
            must(identical(got, dict(kind='undef')), 'source undefined argument')
        elif kind in ['string', 'number', 'dual']:
            text = spelling(source)
            must(identical(got, dict(kind='scalar', codepoints=[ord(c) for c in text],
                                     utf8=bool(source.get('utf8', False)) or any(ord(c) > 255 for c in text))), 'complete source scalar')
        else:
            ref = slot['reference']
            must(set(got) == {'kind', 'type', 'class', 'address_hex', 'fallback', 'text'}, 'closed source reference schema')
            address = got['address_hex']
            must(type(address) is str and address.startswith('0x') and len(address) > 2
                 and all(ch in '0123456789abcdef' for ch in address[2:]), 'public reference address syntax')
            fallback = (ref['class'] + '=' if ref['class'] else '') + ref['type'] + '(' + address + ')'
            expected = dict(kind='reference', type=ref['type'], **{'class': ref['class']}, address_hex=address,
                            fallback=fallback, text=got['text'])
            must(identical(got, expected), 'complete source reference kind and fallback')
            if kind == 'overloaded':
                must(got['text'] == 'own-overloaded-token', 'source overload token')
            elif kind == 'REGEXP':
                must(got['text'] == '(?^' + ('u' if source['utf8'] or any(n > 255 for n in source['codepoints']) else '') + ':' + spelling(source) + ')', 'finite source regex pattern and constructor flags')
            else:
                must(got['text'] == fallback, 'source plain reference token')
            must(identical(got, values[slot['source_slot']]), 'explicit source reference alias')
    pairs = [(n, row) for n, row in enumerate(plan['slots']) if 'reference' in row]
    for n, left in pairs:
        for m, right in pairs:
            if n < m and left['source_slot'] != right['source_slot'] and not (left['reference']['type'] == right['reference']['type'] == 'CODE'):
                must(values[n]['address_hex'] != values[m]['address_hex'], 'distinct live public source holders')


def reconstruct(catalogue, hypotheses, wire):
    must(identical(catalogue, selected()), 'whole selected catalogue')
    expected = plans(catalogue)
    must(identical(hypotheses, expected), 'complete pre-observation hypotheses')
    must(set(wire) == {'role', 'versions', 'initial', 'observations'} and wire['role'] == WIRE_ROLE, 'closed current public wire scope')
    must(set(wire['versions']) == {'perl', 'Carp', 'JSON_PP', 'Scalar_Util', 'overload'}
         and all(type(v) is str and v for v in wire['versions'].values()), 'closed measured metadata only')
    must(identical(wire['initial'], dict(arg_len=64, arg_nums=8, eval_len=0, formatter='undef')), 'declared initial public profile')
    must([r['id'] for r in wire['observations']] == [r['id'] for r in expected], 'complete ordered observations')
    lines = (BASE / 'fixtures.pl').read_text().splitlines()
    boundary_line = lines.index('sub boundary { return emitter(@_) }') + 1
    invoke_line = lines.index('    my $text = ObserverDisplayFixture::boundary(@args);') + 1
    before_text = 'observer-display-message\n at ' + str(BASE / 'fixtures.pl') + ' line ' + str(boundary_line) + '.\n\t'
    after_text = ' called at ' + str(BASE / 'fixtures.pl') + ' line ' + str(invoke_line) + '\n'
    products = []
    for plan, got in zip(expected, wire['observations'], strict=True):
        must(set(got) == {'id', 'profile', 'before', 'after', 'text'}, 'closed public observation schema')
        must(identical(got['profile'], plan['profile']), 'declared public profile')
        views(plan, got)
        tokens = []
        for n in plan['visible_slots']:
            slot = plan['slots'][n]
            rendered = slot['display']
            if 'token' in rendered:
                tokens.append(rendered['token'])
            else:
                ref = slot['reference']
                address = got['before'][slot['source_slot']]['address_hex']
                tokens.append((ref['class'] + '=' if ref['class'] else '') + ref['type'] + '(' + address + ')')
        if plan['remaining_arguments']:
            tokens.append('...')
        header = 'ObserverDisplayFixture::boundary(' + ', '.join(tokens) + ')'
        must(got['text'] == before_text + header + after_text, 'whole source-generated public body and header')
        products.append(dict(id=plan['id'], source=plan, tokens=tokens, header=header,
                             body_prefix=before_text, body_suffix=after_text, whole_body=got['text'],
                             source_before=got['before'], source_after=got['after'], scope=PRODUCT_SCOPE))
    return products


def validate(catalogue, hypotheses, wire, products):
    expected = reconstruct(catalogue, hypotheses, wire)
    must(identical(products, expected), 'whole independent public products and loss metadata')
    return expected

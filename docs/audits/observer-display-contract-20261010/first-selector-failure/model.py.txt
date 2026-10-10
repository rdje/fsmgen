"""Source-selected finite display hypotheses; never read a qualifying trace."""
import json
import re

NUMERIC = re.compile(r'-?[0-9]+(?:\.[0-9]*)?(?:[eE][+-]?[0-9]+)?\Z')
CLASSES = {'plain': 'ObserverDisplayFixture::Plain', 'traced': 'ObserverDisplayFixture::Traced',
           'overloaded': 'ObserverDisplayFixture::Overloaded', 'REGEXP': 'Regexp'}


def same(a, b):
    return json.dumps(a, sort_keys=True, allow_nan=False) == json.dumps(b, sort_keys=True, allow_nan=False)


def require(ok, cause):
    if not ok:
        raise ValueError(cause)


def text(recipe):
    if recipe['kind'] == 'number':
        # Selected numeric constructors are exact integers or the exact binary
        # half 1.5; this finite recipe claims no general Perl number conversion.
        return recipe['value']
    return ''.join(chr(n) for n in recipe['codepoints'])


def escaped(value, quotes):
    out = []
    for char in value:
        code = ord(char)
        if code < 32 or code >= 127:
            out.append('\\x{' + format(code, 'x') + '}')
        elif quotes and char in ('"', '\\'):
            out.append('\\' + char)
        else:
            out.append(char)
    return ''.join(out)


def scalar(value, limit, regex=False):
    cut = limit >= 3 and len(value) > limit
    shown = value[:limit - 3] if cut else value
    numeric = not regex and NUMERIC.fullmatch(shown) is not None
    marker = cut and not numeric
    if regex:
        token = 'qr(' + escaped(shown, False) + ')' + ('...' if marker else '')
    elif numeric:
        token = shown
    else:
        token = '"' + escaped(shown, True) + '"' + ('...' if marker else '')
    return {'token': token, 'source': value, 'display_prefix': shown,
            'truncated': cut, 'visible_ellipsis': marker,
            'numeric_display': numeric, 'token_is_complete_source_value': not cut}


def plan(catalogue):
    result = []
    require(len({c['id'] for c in catalogue['cases']}) == len(catalogue['cases']), 'unique selected display cases')
    for case in catalogue['cases']:
        p = case['profile']
        profile = {'arg_len': 64 if p['arg_len'] is None else p['arg_len'],
                   'arg_nums': 8 if p['arg_nums'] is None else p['arg_nums'], 'eval_len': 0,
                   'formatter': 'defined' if p['formatter'] else 'undef'}
        holders, slots = {}, []
        for index, recipe in enumerate(case['arguments']):
            kind = recipe['kind']
            original = index
            if kind == 'alias':
                original = holders[recipe['target']]
                recipe = case['arguments'][original]
                kind = recipe['kind']
            row = {'index': index, 'recipe': recipe, 'source_slot': original}
            if kind == 'undef':
                row['display'] = {'token': 'undef', 'truncated': False, 'token_is_complete_source_value': True}
            elif kind in ('string', 'number', 'dual'):
                row['display'] = scalar(text(recipe), profile['arg_len'])
            else:
                if original == index:
                    holders[recipe['id']] = index
                row['reference'] = {'type': kind if kind in ('HASH', 'ARRAY', 'CODE', 'REGEXP') else 'HASH',
                                    'class': CLASSES.get(kind), 'source_slot': original}
                if kind == 'traced':
                    row['display'] = {'token': 'own-trace-token', 'truncated': False, 'token_is_complete_source_value': False}
                elif p['formatter']:
                    row['display'] = {'token': 'own-reference-formatter-token', 'truncated': False, 'token_is_complete_source_value': False}
                elif kind == 'REGEXP':
                    row['display'] = scalar(text(recipe), profile['arg_len'], True)
                else:
                    row['display'] = {'address_from_source_slot': original,
                                      'truncated': False, 'token_is_complete_source_value': False}
            slots.append(row)
        count = profile['arg_nums']
        visible = [] if count < 0 else list(range(len(slots) if count == 0 else min(count, len(slots))))
        result.append({'id': case['id'], 'profile': profile, 'slots': slots,
                       'visible_slots': visible, 'hidden_slots': [i for i in range(len(slots)) if i not in visible],
                       'remaining_arguments': count < 0 or (count > 0 and len(slots) > count)})
    return result


def source_views(case, observation):
    before = observation['before']
    require(same(before, observation['after']), 'complete public source holders and values conserve')
    require(len(before) == len(case['slots']), 'complete selected source argument population')
    for slot, got in zip(case['slots'], before, strict=True):
        recipe = slot['recipe']
        kind = recipe['kind']
        if kind == 'undef':
            require(got == {'kind': 'undef'}, 'source undefined argument')
        elif kind in ('string', 'number', 'dual'):
            value = text(recipe)
            upgraded = bool(recipe.get('utf8')) or any(ord(c) > 255 for c in value)
            require(same(got, {'kind': 'scalar', 'codepoints': list(map(ord, value)), 'utf8': upgraded}),
                    'complete source scalar characters and selected UTF8 flag')
        else:
            wanted = slot['reference']
            require(set(got) == {'kind', 'type', 'class', 'address_hex', 'fallback', 'text'}
                    and got['kind'] == 'reference' and got['type'] == wanted['type'] and got['class'] == wanted['class']
                    and type(got['address_hex']) is str and re.fullmatch(r'0x[0-9a-f]+', got['address_hex']),
                    'source reference kind class and public address')
            fallback = (wanted['class'] + '=' if wanted['class'] else '') + wanted['type'] + '(' + got['address_hex'] + ')'
            require(got['fallback'] == fallback, 'source public fallback stringification')
            if kind == 'overloaded':
                require(got['text'] == 'own-overloaded-token', 'source selected overload body')
            elif kind == 'REGEXP':
                require(got['text'].startswith('(?^') and got['text'].endswith(':' + text(recipe) + ')'),
                        'whole public regex source pattern; engine flags remain opaque')
            else:
                require(got['text'] == fallback, 'source plain reference stringification')
            require(same(got, before[slot['source_slot']]), 'source explicit reference alias and lifetime')
    for left, a in enumerate(case['slots']):
        if 'reference' not in a:
            continue
        for right, b in enumerate(case['slots'][left + 1:], left + 1):
            if 'reference' not in b or a['source_slot'] == b['source_slot']:
                continue
            if a['reference']['type'] == b['reference']['type'] == 'CODE':
                continue
            require(before[left]['address_hex'] != before[right]['address_hex'], 'distinct simultaneous public source holders')


def join(hypotheses, native):
    require(native['role'] == 'Own current public display fixtures; original formatter/settings/provider identity is unmeasured.',
            'current public fixture versus original formatter scope')
    require(native['initial'] == {'arg_len': 64, 'arg_nums': 8, 'eval_len': 0, 'formatter': 'undef'},
            'source-selected documented initial public profile')
    require([r['id'] for r in native['observations']] == [r['id'] for r in hypotheses], 'complete ordered public display corpus')
    products = []
    for case, observation in zip(hypotheses, native['observations'], strict=True):
        require(same(observation['profile'], case['profile']), 'source-selected public display profile')
        source_views(case, observation)
        tokens = []
        for index in case['visible_slots']:
            slot = case['slots'][index]
            display = slot['display']
            if 'token' in display:
                tokens.append(display['token'])
            else:
                ref = slot['reference']
                address = observation['before'][display['address_from_source_slot']]['address_hex']
                tokens.append((ref['class'] + '=' if ref['class'] else '') + ref['type'] + '(' + address + ')')
        if case['remaining_arguments']:
            tokens.append('...')
        header = 'ObserverDisplayFixture::boundary(' + ', '.join(tokens) + ')'
        pattern = re.compile(r'^\tObserverDisplayFixture::boundary\(.*\) called at [^\n]+ line [0-9]+\n', re.M)
        frames = list(pattern.finditer(observation['text']))
        require(len(frames) == 1, 'unique complete source-selected public frame')
        frame = frames[0]
        raw = frame.group()
        actual = raw[1:raw.rindex(' called at ')]
        require(actual == header, 'complete source-generated public argument header and format')
        start = frame.start() + 1
        prefix, suffix = observation['text'][:start], observation['text'][start + len(actual):]
        require(prefix + header + suffix == observation['text'], 'whole public body byte-preserving reassembly')
        products.append({'id': case['id'], 'source': case, 'tokens': tokens, 'header': header,
                         'body_prefix': prefix, 'body_suffix': suffix, 'whole_body': observation['text'],
                         'source_before': observation['before'], 'source_after': observation['after'],
                         'scope': 'Own current public source/holder/display contract only; no original formatter/settings or cross-call identity inference.'})
    return products

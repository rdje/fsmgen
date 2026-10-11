"""Independent finite comparison rules; operand kinds remain a separate contract."""
from remaining_common import need


def regex(pattern, text):
    need(type(pattern) is str and pattern.startswith('(?^:') and pattern.endswith(')')
         and type(text) is str and pattern[4:-1].isascii(), 'finite ASCII source regex operands')
    # Remaining source regexes contain only this literal ASCII identifier.
    body = pattern[4:-1]
    need(body and all(c.isalnum() or c == '_' for c in body), 'finite literal remaining regex grammar')
    return any(text[start:start + len(body)] == body for start in range(len(text) + 1))


def scalar(value):
    need(value is None or type(value) in (str, int), 'finite typed remaining scalar operand')
    return None if value is None else str(value)


def deep(left, right):
    # Tagged HASH/ARRAY structures preserve complete order/membership. This
    # finite original population contains no reference/cycle/native-object tag.
    if type(left) is list or type(right) is list:
        if not (type(left) is list and type(right) is list):
            return False
        need(len(left) == len(right) == 2 and left[0] in ('hash', 'array')
             and right[0] in ('hash', 'array'), 'finite original remaining graph kinds')
        if left[0] != right[0]:
            return False
        if left[0] == 'hash':
            need(type(left[1]) is dict and type(right[1]) is dict, 'whole remaining graph hash containers')
            return left[1].keys() == right[1].keys() and all(deep(left[1][key], right[1][key]) for key in left[1])
        need(type(left[1]) is list and type(right[1]) is list, 'whole remaining graph array containers')
        return len(left[1]) == len(right[1]) and all(deep(a, b) for a, b in zip(left[1], right[1]))
    return scalar(left) == scalar(right)


def observed(native):
    need(type(native.get('passed')) is int and native['passed'] in (0, 1),
         'typed original remaining consumer passed observation')
    kind = native['kind']
    if kind == 'ok':
        need(type(native.get('actual')) is int and native['actual'] in (0, 1) and 'expected' not in native,
             'typed observer-projected remaining Boolean operand')
        outcome = native['actual']
    elif kind == 'is':
        outcome = int(scalar(native['actual']) == scalar(native['expected']))
    elif kind == 'is_deeply':
        outcome = int(deep(native['actual'], native['expected']))
    elif kind in ('like', 'unlike'):
        outcome = int(regex(native['expected'], native['actual']) == (kind == 'like'))
    else:
        raise ValueError('finite remaining original assertion kind')
    need(outcome == native['passed'], 'independently derived remaining comparison truth contradicts native passed flag')
    return outcome

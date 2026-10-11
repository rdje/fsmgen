"""Extract balanced calls from the exact finite authored assertion workload."""
import re


def call(source, context):
    lines = source.splitlines(keepends=True)
    line = context['caller'][2]
    offset = sum(map(len, lines[:line - 1]))
    matches = list(re.finditer(r'(?<!\w)' + context['kind'] + r'\(', lines[line - 1]))
    if len(matches) != 1:
        raise ValueError('unique own assertion call on declared source line')
    start = offset + matches[0].start()
    opening = offset + matches[0].end() - 1
    stack, quote, escaped = [], None, False
    arguments, left = [], opening + 1
    for index in range(opening, len(source)):
        char = source[index]
        if quote:
            if escaped:
                escaped = False
            elif char == '\\':
                escaped = True
            elif char == quote:
                quote = None
            continue
        if char in "'\"":
            quote = char
        elif char in '([{':
            stack.append(char)
        elif char in ')]}':
            if not stack or stack.pop() != {')': '(', ']': '[', '}': '{'}[char]:
                raise ValueError('balanced complete finite assertion source')
            if not stack:
                if char != ')' or source[index + 1:index + 2] != ';':
                    raise ValueError('complete finite assertion statement terminator')
                arguments.append((left, index))
                end = index + 2
                break
        elif char == ',' and stack == ['(']:
            arguments.append((left, index))
            left = index + 1
    else:
        raise ValueError('finite assertion source has closing statement')
    pieces = []
    for begin, finish in arguments:
        while source[begin:finish] and source[begin].isspace():
            begin += 1
        while source[begin:finish] and source[finish - 1].isspace():
            finish -= 1
        pieces.append(dict(start=begin, end=finish, body=source[begin:finish]))
    return dict(start=start, end=end, body=source[start:end], arguments=pieces)

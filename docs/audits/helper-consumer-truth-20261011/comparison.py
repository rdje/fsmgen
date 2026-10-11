"""Direct finite ASCII regex interpreter, independent of the proposal regex engine."""


def need(condition, cause):
    if not condition:
        raise ValueError(cause)


def regex_search(display, text):
    need(type(display) is str and display.startswith('(?^:') and display.endswith(')')
         and display.isascii() and type(text) is str and text.isascii(), 'finite ASCII helper comparison operands')
    pattern = display[4:-1]
    atoms = []
    for char in pattern:
        if char == '*':
            need(bool(atoms) and atoms[-1] == ('.', False), 'finite helper regex star applies only to dot')
            atoms[-1] = ('.', True)
        else:
            need(char.isalnum() or char in " _.'-:", 'finite source helper regex character domain')
            atoms.append((char, False))

    def closure(states):
        result = set(states)
        for index in sorted(states):
            while index < len(atoms) and atoms[index][1]:
                index += 1
                result.add(index)
        return result

    for start in range(len(text) + 1):
        states = closure({0})
        if len(atoms) in states:
            return True
        for char in text[start:]:
            following = set()
            for index in states:
                if index == len(atoms):
                    continue
                atom, repeat = atoms[index]
                if (atom == '.' and char != '\n') or atom == char:
                    following.add(index if repeat else index + 1)
            states = closure(following)
            if len(atoms) in states:
                return True
            if not states:
                break
    return False


def observed(native):
    need(type(native) is dict and type(native.get('passed')) is int and native['passed'] in (0, 1),
         'typed original helper consumer passed observation')
    if native.get('kind') == 'ok':
        need(type(native.get('actual')) is int and native['actual'] in (0, 1) and 'expected' not in native,
             'typed observer-projected helper Boolean operand')
        truth = native['actual']
    else:
        need(native.get('kind') == 'like' and 'expected' in native, 'finite helper consumer comparison kind')
        truth = int(regex_search(native['expected'], native['actual']))
    need(native['passed'] == truth, 'independently derived helper comparison truth contradicts native passed flag')
    return truth

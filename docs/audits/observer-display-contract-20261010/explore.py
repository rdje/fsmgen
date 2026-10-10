"""Select neutral exploratory inputs; no original trace is read or qualified."""
import json
from pathlib import Path

BASE = Path('docs/audits/observer-display-contract-20261010')


def string(value, utf8=False):
    return {'kind': 'string', 'codepoints': list(map(ord, value)), 'utf8': utf8}


def cases():
    rows = []
    def add(name, args, **profile):
        rows.append({'id': name, 'arguments': args,
                     'profile': {'arg_len': profile.get('arg_len'), 'arg_nums': profile.get('arg_nums'),
                                 'formatter': profile.get('formatter', False)}})
    for name, text in [('empty', ''), ('plain', 'alpha beta'), ('integer-string', '12'),
                       ('leading-zero', '012'), ('negative-string', '-7'), ('decimal-string', '1.5'),
                       ('exponent-string', '1e3'), ('quote', 'a"b'), ('slash', 'a\\b'),
                       ('newline', 'a\nb'), ('tab', 'a\tb'), ('return', 'a\rb'), ('nul', 'a\0b'),
                       ('delete', 'a\x7fb'), ('latin', 'a\xe9b'), ('wide', 'a\u2603b')]:
        add(name, [string(text)])
    for size in (0, 1, 63, 64, 65, 66):
        add('length-' + str(size), [string('x' * size)])
    for name, text in [('escaped-boundary', '\\' * 65), ('wide-boundary', '\u2603' * 65),
                       ('upgraded-ascii', 'abc'), ('upgraded-latin', '\xe9')]:
        add(name, [string(text, True)])
    add('undef', [{'kind': 'undef'}])
    for value in ('0', '12', '-7', '1.5'):
        add('number-' + value, [{'kind': 'number', 'value': value}])
    add('dual', [{'kind': 'dual', 'number': 42, 'codepoints': list(map(ord, 'dual-text')), 'utf8': False}])
    for kind in ('HASH', 'ARRAY', 'CODE', 'plain', 'traced', 'overloaded'):
        add('reference-' + kind, [{'kind': kind, 'id': 'held'}])
    add('regex', [{'kind': 'REGEXP', 'id': 'held', 'codepoints': list(map(ord, 'alpha+')), 'utf8': False}])
    add('aliases', [{'kind': 'HASH', 'id': 'held'}, {'kind': 'alias', 'target': 'held'}])
    for count in (0, 1, 7, 8, 9, 10):
        add('count-' + str(count), [string('slot-' + str(i)) for i in range(count)])
    add('length-unlimited', [string('z' * 70)], arg_len=0)
    add('length-one', [string('abcdef')], arg_len=1)
    add('count-unlimited', [string('slot-' + str(i)) for i in range(10)], arg_nums=0)
    add('count-one', [string('one'), string('two')], arg_nums=1)
    add('count-suppressed', [string('one'), string('two')], arg_nums=-1)
    add('reference-formatter', [{'kind': 'HASH', 'id': 'held'}], formatter=True)
    return rows


def main():
    destination = BASE / 'explore-catalogue.json'
    assert not destination.exists(), 'retain first selected exploratory catalogue'
    destination.write_text(json.dumps({'role': 'Source-neutral public exploration only; no semantic qualification.',
                                       'cases': cases()}, sort_keys=True, indent=2) + '\n')
    print('PASS exploratory public cases selected before native capture; no original or semantic qualification claimed.')


if __name__ == '__main__':
    main()

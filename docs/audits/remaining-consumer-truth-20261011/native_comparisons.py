"""Calibrate finite comparison rules through the installed public Test::More API."""
import subprocess
from remaining_common import *
import comparison

CASES = (
    ('scalar-number-string', "is('1', 1)", dict(kind='is', actual='1', expected=1), 1),
    ('scalar-different', 'is(8, 9)', dict(kind='is', actual=8, expected=9), 0),
    ('scalar-undefined', 'is(undef, undef)', dict(kind='is', actual=None, expected=None), 1),
    ('undefined-empty', "is(undef, '')", dict(kind='is', actual=None, expected=''), 0),
    ('deep-number-string', "is_deeply({width => '3'}, {width => 3})",
        dict(kind='is_deeply', actual=['hash', {'width': '3'}], expected=['hash', {'width': 3}]), 1),
    ('deep-missing-property', 'is_deeply({width => 3}, {width => 3, signed => 1})',
        dict(kind='is_deeply', actual=['hash', {'width': 3}], expected=['hash', {'width': 3, 'signed': 1}]), 0),
    ('deep-array-order', 'is_deeply([1, 2], [2, 1])',
        dict(kind='is_deeply', actual=['array', [1, 2]], expected=['array', [2, 1]]), 0),
    ('deep-hash-order', 'is_deeply({a => 1, b => 2}, {b => 2, a => 1})',
        dict(kind='is_deeply', actual=['hash', {'a': 1, 'b': 2}], expected=['hash', {'b': 2, 'a': 1}]), 1),
    ('projected-false', 'ok(0)', dict(kind='ok', actual=0), 0),
    ('whole-trace-regex', 'like("wrong\\nexpected_cause_only_in_argument", qr/expected_cause_only_in_argument/)',
        dict(kind='like', actual='wrong\nexpected_cause_only_in_argument', expected='(?^:expected_cause_only_in_argument)'), 1),
    ('first-line-unlike', 'unlike("Deliberately wrong diagnostic", qr/expected_cause_only_in_argument/)',
        dict(kind='unlike', actual='Deliberately wrong diagnostic', expected='(?^:expected_cause_only_in_argument)'), 1),
)


def command(expression):
    return ['perl', '-MTest::More', '-e', 'plan tests => 1; ' + expression + ';']


def qualify(gate, *, current=False):
    rows = json.loads((BASE / 'native-comparisons.json').read_bytes())
    need(len(rows) == len(CASES), 'complete public native comparison calibration population')
    for row, (label, expression, operands, truth) in zip(rows, CASES, strict=True):
        need(comparison.observed(dict(**operands, passed=truth)) == truth,
             'finite independent comparison calibration truth')
        status = 0 if truth else 1
        receipt = gate('comparison-' + label, command(expression), status, current=current)
        actual = json.loads((BASE / ('comparison-' + label + '-actual.json')).read_bytes())
        need(actual['stdout'].startswith('1..1\n' + ('ok 1' if truth else 'not ok 1'))
             and row == dict(label=label, expression=expression, operands=operands, truth=truth, native=receipt),
             'whole native public comparison truth and source calibration custody')
    return rows


if __name__ == '__main__':
    rows = []
    for label, expression, operands, truth in CASES:
        need(comparison.observed(dict(**operands, passed=truth)) == truth, 'independent public comparison precondition')
        status = 0 if truth else 1
        result = subprocess.run(['python3', '-B', str(BASE / 'capture.py'), '--expect', str(status),
                                 'comparison-' + label, *command(expression)], capture_output=True, text=True)
        actual = json.loads((BASE / ('comparison-' + label + '-actual.json')).read_bytes())
        need(result.returncode == 0 and actual['status'] == status, 'actual public native comparison result')
        rows.append(dict(label=label, expression=expression, operands=operands, truth=truth,
                         native=pin(canonical(actual))))
    save('native-comparisons.json', rows)
    print('PASS independently interpreted finite scalar/structural/regex comparisons against public native Test::More cases.')

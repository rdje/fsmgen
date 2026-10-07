"""Consume complete pre-native source/POD/actual evidence without coordinates."""
import copy
import json
import os
import re
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-coordinate-public-hypotheses-20261007')
CHECKS = Path('docs/audits/coordinate-public-hypotheses-checks-20261007')


def module(path):
    namespace = {'__name__': 'pre_native_independent_consumer'}
    exec(compile(path.read_bytes(), str(path), 'exec'), namespace)
    return namespace


reader = module(BASE / 'verify.py')
require, same, load, pin = (reader[k] for k in ('require', 'same', 'load', 'pin'))


def actual(record, command, stdout, instruments):
    require(record['command'] == ['scripts/run_with_ram_guard.sh', '--', *command]
            and type(record['status']) is int and record['status'] == 0,
            'actual pre-native complete command and integer success')
    require(record['stdout'] == stdout and re.fullmatch(
        r'ram-guard: PID [0-9]+; host [0-9]+\.[0-9]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n',
        record['stderr']) is not None, 'actual pre-native whole success and guard streams')
    require(set(record['instruments']) == set(instruments)
            and all(same(value, pin(Path(path).read_bytes())) for path, value in record['instruments'].items()),
            'actual pre-native whole executed instrument identities')


def spans(source, hypotheses):
    selected = [(row['unit'], row['source']) for row in hypotheses['calls']]
    selected += [('fixture.pl', row['source']) for row in hypotheses['boundaries'].values()]
    selected += [('fixture.pl', row) for row in hypotheses['trace_origin_sources'].values()]
    for unit, row in selected:
        raw = source[unit].encode(); offset = row['offset_bytes']; text = row['text'].encode()
        require(type(offset) is int and offset >= 0 and raw[offset:offset + len(text)] == text
                and same(row['identity'], pin(text)), 'independent complete own fixture UTF-8 span')
        require(type(row['first_line']) is int and type(row['closing_line']) is int
                and row['first_line'] == len(raw[:offset].split(b'\n'))
                and row['closing_line'] == len(raw[:offset + len(text)].split(b'\n')),
                'independent genuine integer first/closing source lines')
    require(all(row['selected_line'] is None and row['selected_filename'] is None
                for row in hypotheses['calls']), 'no premature public native coordinate selection')


def main():
    before = reader['members']()
    require(same(load(BASE / 'manifest.json'), before), 'whole immutable pre-native member seal')
    require(same(load(BASE / 'binding.json'), reader['binding']()), 'whole committed own/public source binding')
    inputs = reader['source_inputs'](); expected = reader['derive'](inputs)
    require(same(load(BASE / 'inputs.json'), inputs) and same(load(BASE / 'hypotheses.json'), expected),
            'whole independent pre-native source/POD/hypothesis reconstruction')
    spans(inputs['source'], expected)
    require(same(load(BASE / 'controls.json'), reader['controls'](inputs, expected)),
            'every genuine source/POD/hypothesis control retained')
    command = ['python3', '-B', str(BASE / 'verify.py'), '--seal']
    actual(load(CHECKS / 'seal.json'), command, reader['SUCCESS'],
           [str(BASE / 'verify.py'), str(CHECKS / 'run.py'), 'scripts/run_with_ram_guard.sh'])
    docs_command = ['python3', '-B', str(BASE / 'capture_docs.py')]
    actual(load(CHECKS / 'docs.json'), docs_command,
           'PASS complete necessary public filename/remapping/load documentation captured; public coordinate fixtures remain unexecuted.\n',
           [str(BASE / 'capture_docs.py'), str(CHECKS / 'run.py'), 'scripts/run_with_ram_guard.sh'])
    syntax = load(CHECKS / 'syntax-actual.json')
    require(syntax['command'] == ['perl', '-c', 'fixture.pl']
            and syntax['cwd'] == '.artifacts/public-coordinate-hypotheses/syntax'
            and type(syntax['status']) is int and syntax['status'] == 0
            and syntax['stdout'] == '' and syntax['stderr'] == 'fixture.pl syntax OK\n'
            and same(syntax['before'], inputs['source_pins']) and same(syntax['after'], syntax['before']),
            'complete syntax-only actual result and every own source before/after byte')
    # Independent binary public-POD replay qualifies the full captured bodies.
    capture = module(BASE / 'capture_docs.py'); work = capture['WORK']
    require(work.resolve().is_relative_to(Path.cwd()) and work.stat().st_dev == Path('.').stat().st_dev,
            'same-volume contained public-documentation replay workspace')
    env = {**os.environ, 'TMPDIR': str(work.resolve()), 'TMP': str(work.resolve()),
           'TEMP': str(work.resolve()), 'PERLDOC_PAGER': 'cat', 'PAGER': 'cat'}
    wire = {}
    for name, cmd in capture['COMMANDS'].items():
        run = subprocess.run(cmd, env=env, capture_output=True)
        row = inputs['public_docs']['commands'][name]
        require(run.returncode == row['status'] == 0 and run.stdout == row['stdout'].encode()
                and run.stderr == row['stderr'].encode(), 'independent full public POD binary replay')
        wire[name] = dict(command=cmd, status=run.returncode, stdout=pin(run.stdout), stderr=pin(run.stderr))
    defect = load(CHECKS / 'doc-control-root-cause.json')
    old = module(BASE / 'pre-doc-validation-programme.py.txt')
    old['check'](expected, defect['whole_bad_input'], expected)
    try:
        reader['check'](expected, defect['whole_bad_input'], expected)
    except ValueError as error:
        require(str(error) == defect['after_cause'], 'independent genuine missing-clause repair decision')
    else:
        raise ValueError('false-green missing-clause repair')
    record = load(CHECKS / 'seal.json'); refusals = []
    for value in (True, 0.0, 1):
        changed = copy.deepcopy(record); changed['status'] = value
        try:
            actual(changed, command, reader['SUCCESS'], record['instruments'])
        except ValueError as error:
            require(str(error) == 'actual pre-native complete command and integer success', 'intended typed actual refusal')
            refusals.append(dict(status=value, cause=str(error)))
        else:
            raise ValueError('false-green typed pre-native actual')
    require(same(before, reader['members']()), 'every sealed pre-native member conserves')
    print(json.dumps(dict(role=reader['ROLE'], members=len(before), calls=len(expected['calls']),
        boundaries=len(expected['boundaries']), full_public_wire=wire, actual_controls=refusals), sort_keys=True))


if __name__ == '__main__':
    main()

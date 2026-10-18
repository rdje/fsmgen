"""Retain every native preparation outcome without spending an acceptance slot."""
import argparse
import subprocess

import execute
import prepare


def sources():
    names = sorted(execute.safe(execute.AUDIT).glob('*.py'))
    names.append(execute.safe(execute.AUDIT / 'selected-intake.json.gz'))
    return {str(path.relative_to(execute.ROOT)): prepare.blob(execute.read(path)) for path in names}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('attempt', choices=('first', 'final'))
    args = parser.parse_args()
    stem = 'selected-intake-qualification-' + args.attempt
    command = ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B',
               str(execute.AUDIT / 'selected_preflight.py'), '--record', '--attempt', args.attempt]
    started = dict(command=command, sources=sources(), tools=execute.tools(), primary=execute.git_state(),
                   scope='Inert closed intake qualification only; no semantic cohort, original producer, '
                         'spent capture or unused slot executes. External tools/counters are read-only dependencies.')
    execute.save(execute.AUDIT / (stem + '-started.json.gz'), started)
    native = subprocess.run(command, cwd=execute.ROOT, capture_output=True)
    actual = dict(started, status=native.returncode, stdout=prepare.blob(native.stdout),
                  stderr=prepare.blob(native.stderr), source_after=execute.observe(sources),
                  tools_after=execute.observe(execute.tools), primary_after=execute.observe(execute.git_state))
    execute.save(execute.AUDIT / (stem + '-actual.json.gz'), actual)
    assert type(native.returncode) is int and native.returncode == 0
    assert native.stdout == (b'Selected-checkout closed source/cwd/command/contract/custody/stop/resource/book '
                             b'controls pass; no semantic reader or acceptance cohort executes.\n')
    assert native.stderr.startswith(b'ram-guard: PID ') and b'ram-guard: terminating PID tree' not in native.stderr
    assert actual['source_after'] == dict(value=started['sources'], error=None)
    assert actual['tools_after'] == dict(value=started['tools'], error=None)
    assert actual['primary_after']['error'] is None
    assert all(actual['primary_after']['value'][key] == started['primary'][key] for key in ('head', 'entries'))
    print('Selected intake inert qualification retains native0, complete source/tool/index custody and every old slot.')

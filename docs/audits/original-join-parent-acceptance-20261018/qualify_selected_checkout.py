"""Record independent physical and inert-guard qualification with full custody."""
import subprocess

import execute
import prepare

NAMES = ('selected_checkout.py', 'selected_checkout_preflight.py', 'qualify_selected_checkout.py',
         'selected_index_portability.py', 'epoch_constraints.py', 'execute.py', 'prepare.py',
         'conjunctive-epoch-constraints-qualified.json.gz', 'selected-checkout-manifest.json.gz',
         'selected-checkout-prepared.json.gz', 'selected-checkout-inert-controls.json.gz',
         'selected-index-portability-inputs.json.gz')
COMMANDS = [
    ('physical', ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B',
                  str(execute.AUDIT / 'selected_checkout.py')],
     b'Complete selected checkout physical source/member/mode/link/index custody passes with declared empty locality directories; no semantic reader executes.\n'),
    ('guards', ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B',
                str(execute.AUDIT / 'selected_checkout_preflight.py')],
     b'Selected checkout physical controls and requested original inert guards pass; no semantic delegation executes.\n'),
    ('portable_index', ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B',
                        str(execute.AUDIT / 'selected_index_portability.py')],
     b'Portable selected index observations pass public Git validation; malformed index, wrong entries, source and runtime controls refuse.\n'),
]


def sources():
    return {str(execute.AUDIT / name): prepare.blob(execute.read(execute.AUDIT / name)) for name in NAMES}


if __name__ == '__main__':
    before, tools, primary = sources(), execute.tools(), execute.git_state()
    started = dict(commands={label: command for label, command, _ in COMMANDS},
                   source_before=before, tools_before=tools, primary_before=primary,
                   scope='Whole selected physical source/member/mode/link/index and real-file original '
                         'inert guard qualification only. No semantic reader, producer, intake or '
                         'original native/private qualification executes; every earlier failure retains.')
    execute.save(execute.AUDIT / 'selected-checkout-portable-qualification-started.json.gz', started)
    results = []
    for label, command, expected_stdout in COMMANDS:
        native = subprocess.run(command, cwd=execute.ROOT, capture_output=True)
        results.append(dict(label=label, command=command, status=native.returncode,
                            stdout=prepare.blob(native.stdout), stderr=prepare.blob(native.stderr)))
        # Retain even the first unexpected result before asserting or repairing.
        if type(native.returncode) is not int or native.returncode != 0 or native.stdout != expected_stdout:
            break
    actual = dict(started, results=results, source_after=execute.observe(sources),
                  tools_after=execute.observe(execute.tools), primary_after=execute.observe(execute.git_state))
    execute.save(execute.AUDIT / 'selected-checkout-portable-qualification-actual.json.gz', actual)
    assert len(results) == len(COMMANDS)
    for row, (label, command, stdout) in zip(results, COMMANDS, strict=True):
        assert row['label'] == label and row['command'] == command
        assert type(row['status']) is int and row['status'] == 0
        assert prepare.unblob(row['stdout']) == stdout
        stderr = prepare.unblob(row['stderr'])
        assert stderr.startswith(b'ram-guard: PID ') and b'ram-guard: terminating PID tree' not in stderr
    assert actual['source_after'] == dict(value=before, error=None)
    assert actual['tools_after'] == dict(value=tools, error=None)
    assert actual['primary_after']['error'] is None
    assert all(actual['primary_after']['value'][key] == primary[key] for key in ('head', 'entries'))
    print('Selected whole checkout and original inert guards retain native0 with complete programme/input/tool/index custody; semantic intake stays pending.')

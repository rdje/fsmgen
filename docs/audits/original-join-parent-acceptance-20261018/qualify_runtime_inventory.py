"""Retain complete static-inventory qualification outcomes; no semantic replay."""
import argparse
import subprocess

import execute
import prepare

NAMES = ('runtime_inventory.py', 'qualify_runtime_inventory.py', 'epoch_constraints.py',
         'selected_checkout.py', 'execute.py', 'prepare.py',
         'conjunctive-epoch-constraints-qualified.json.gz')


def sources():
    return {name: prepare.blob(execute.read(execute.AUDIT / name)) for name in NAMES}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('attempt', choices=('first', 'final'))
    args = parser.parse_args()
    command = ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B',
               str(execute.AUDIT / 'runtime_inventory.py'), '--write']
    stem = 'runtime-inventory-' + args.attempt
    started = dict(command=command, sources=sources(), tools=execute.tools(), primary=execute.git_state(),
                   scope='Static fixed-source/candidate census and refusal controls only; no semantic cohort, '
                         'fresh checkout, spent-fixture mutation or original native/private producer.')
    execute.save(execute.AUDIT / (stem + '-started.json.gz'), started)
    native = subprocess.run(command, cwd=execute.ROOT, capture_output=True)
    actual = dict(started, status=native.returncode, stdout=prepare.blob(native.stdout), stderr=prepare.blob(native.stderr),
                  sources_after=execute.observe(sources), tools_after=execute.observe(execute.tools),
                  primary_after=execute.observe(execute.git_state))
    execute.save(execute.AUDIT / (stem + '-actual.json.gz'), actual)
    assert type(native.returncode) is int and native.returncode == 0
    assert native.stdout == (b'Complete fixed source/static-site candidate inventory and genuine refusal controls pass; '
                             b'runtime execution/data roles remain unresolved.\n')
    assert native.stderr.startswith(b'ram-guard: PID ') and b'ram-guard: terminating PID tree' not in native.stderr
    assert actual['sources_after'] == dict(value=started['sources'], error=None)
    assert actual['tools_after'] == dict(value=started['tools'], error=None)
    assert actual['primary_after']['error'] is None
    assert all(actual['primary_after']['value'][key] == started['primary'][key] for key in ('head', 'entries'))
    print('Static inventory native0 and complete source/tool/index custody retained; execution/data roles stay unresolved.')

"""Capture original-prototype phase observations with complete before/after custody."""
import subprocess

import execute
import prepare
import qualify_runtime_inventory as first

NAMES = (*first.NAMES, 'profile_runtime_inventory.py', 'capture_runtime_profile.py')


def sources():
    return {name: prepare.blob(execute.read(execute.AUDIT / name)) for name in NAMES}


if __name__ == '__main__':
    command = ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B',
               str(execute.AUDIT / 'profile_runtime_inventory.py')]
    started = dict(command=command, sources=sources(), tools=execute.tools(), primary=execute.git_state(),
                   scope='Separate phase diagnostic of unchanged prototype and complete fixed inputs. '
                         'No completed inventory, prior-process allocation attribution or semantic execution.')
    execute.save(execute.AUDIT / 'runtime-inventory-profile-started.json.gz', started)
    native = subprocess.run(command, cwd=execute.ROOT, capture_output=True)
    actual = dict(started, status=native.returncode, stdout=prepare.blob(native.stdout),
                  stderr=prepare.blob(native.stderr), sources_after=execute.observe(sources),
                  tools_after=execute.observe(execute.tools), primary_after=execute.observe(execute.git_state))
    execute.save(execute.AUDIT / 'runtime-inventory-profile-actual.json.gz', actual)
    assert actual['sources_after'] == dict(value=started['sources'], error=None)
    assert actual['tools_after'] == dict(value=started['tools'], error=None)
    assert actual['primary_after']['error'] is None
    assert all(actual['primary_after']['value'][key] == started['primary'][key] for key in ('head', 'entries'))
    print('Original-prototype phase diagnostic native result and complete custody retained; inventory remains unqualified.')

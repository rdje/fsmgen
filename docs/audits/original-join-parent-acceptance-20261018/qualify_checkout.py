"""Retain final read-only checkout qualification with exact programme/tool custody."""
import subprocess

import execute
import prepare

NAMES = ('historical_checkout.py', 'checkout_preflight.py', 'qualify_checkout.py',
         'execute.py', 'prepare.py', 'historical_factory.py')


def sources():
    return {str(execute.AUDIT / name): prepare.blob(execute.read(execute.AUDIT / name)) for name in NAMES}


if __name__ == '__main__':
    command = ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B',
               str(execute.AUDIT / 'historical_checkout.py')]
    before, tools = sources(), execute.tools()
    started = dict(command=command, source_before=before, tools_before=tools,
                   scope='Read-only independent complete physical/source/index/relative-Git qualification. No semantic replay.')
    execute.save(execute.AUDIT / 'historical-checkout-qualification-started.json.gz', started)
    result = subprocess.run(command, cwd=execute.ROOT, capture_output=True)
    actual = dict(started, status=result.returncode, stdout=prepare.blob(result.stdout),
                  stderr=prepare.blob(result.stderr), source_after=execute.observe(sources),
                  tools_after=execute.observe(execute.tools))
    execute.save(execute.AUDIT / 'historical-checkout-qualification-actual.json.gz', actual)
    assert type(result.returncode) is int and result.returncode == 0
    assert actual['source_after'] == dict(value=before, error=None)
    assert actual['tools_after'] == dict(value=tools, error=None)
    assert result.stdout == b'Complete dated Git/runtime checkout and independent whole physical source/mode/member/index qualification pass; no semantic reader executes.\n'
    assert result.stderr.startswith(b'ram-guard: PID ') and b'ram-guard: terminating PID tree' not in result.stderr
    print('Final complete checkout qualification retains native0 and exact programme/tool custody; no semantic reader executes.')

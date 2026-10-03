import subprocess
subprocess.run(['python3', '-B', 'docs/audits/reservation-coverage-copy-repair-20261003/verify.py'], check=True)
subprocess.run([
    'python3', '-B', 'docs/audits/reservation-coverage-historical-context-20261003/run_context.py',
    '--binding', 'docs/audits/reservation-coverage-historical-context-20261003/bindings.json',
    '--output', '.artifacts/reservation-coverage-copy-repair-reverify-20261003',
], check=True)
print('PASS current repaired coverage kinds/sharing/isolation, complete causes and native identity controls; original full qualification replays at its pinned revision; retained evidence unchanged.')

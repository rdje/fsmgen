import subprocess
for reader in (
    'docs/audits/reservation-coverage-cause-repair-checks-20261003/verify.py',
    'docs/audits/reservation-coverage-source-copies-20261003/verify.py',
    'docs/audits/reservation-coverage-module-capture-20261003/verify.py',
):
    subprocess.run(['python3', '-B', reader], check=True)
print('PASS current coverage cause, actor-copy and complete module-capture qualification; all readers leave retained evidence unchanged.')

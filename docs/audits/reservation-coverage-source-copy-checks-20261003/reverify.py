import subprocess
for reader in (
    'docs/audits/reservation-coverage-cause-repair-checks-20261003/verify.py',
    'docs/audits/reservation-coverage-module-join-20261003/verify.py',
):
    subprocess.run(['python3', '-B', reader], check=True)
print('PASS current coverage cause and complete actor/module field join; all readers leave retained evidence unchanged.')

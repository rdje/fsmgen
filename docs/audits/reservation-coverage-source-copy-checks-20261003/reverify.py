import subprocess
for reader in (
    'docs/audits/reservation-coverage-cause-repair-checks-20261003/verify.py',
    'docs/audits/reservation-coverage-qualification-join-20261003/verify.py',
    'docs/audits/reservation-coverage-historical-context-20261003/verify.py',
):
    subprocess.run(['python3', '-B', reader], check=True)
print('PASS complete current coverage cause/copy-site/field/source/product qualification with real kind, plain topology and native controls; pinned historical replay qualified; immediate live test repair remains owned; all readers leave retained evidence unchanged.')

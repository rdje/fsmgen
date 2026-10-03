import subprocess
for reader in (
    'docs/audits/reservation-coverage-cause-repair-checks-20261003/verify.py',
    'docs/audits/reservation-coverage-snapshot-native-join-20261003/verify.py',
):
    subprocess.run(['python3', '-B', reader], check=True)
print('PASS current coverage cause and complete actor/module/snapshot qualification with real value-only, plain topology and native identity controls; all readers leave retained evidence unchanged.')

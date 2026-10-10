"""Retain each actual source-only phase before proceeding to its successor."""
import subprocess
from common import BASE, need, pin, save

for programme in ('derive.py','produce.py','check_oracle.py','falsify.py'):
    command = ['python3','-B',str(BASE / programme)]
    instruments = {p.name:pin(p.read_bytes()) for p in BASE.glob('*.py')}
    result = subprocess.run(command,capture_output=True,text=True)
    save('phase-' + programme + '.json',dict(command=command,status=result.returncode,
         stdout=result.stdout,stderr=result.stderr,instruments=instruments))
    print(programme,result.returncode,result.stdout[-500:],result.stderr[-800:],flush=True)
    if result.returncode:
        failure = BASE / ('failure-' + programme)
        failure.mkdir()
        for source in BASE.glob('*.py'):
            (failure / (source.name + '.txt')).write_bytes(source.read_bytes())
    need(type(result.returncode) is int and result.returncode == 0 and not result.stderr,
         'actual source-only pipeline phase: ' + programme)

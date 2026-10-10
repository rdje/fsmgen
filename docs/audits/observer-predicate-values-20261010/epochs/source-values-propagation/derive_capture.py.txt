"""Retain actual source derivation while prerequisite replay independently runs."""
import subprocess
from common import BASE, need, pin, save

command = ['python3','-B',str(BASE / 'source.py')]
inputs = {n:pin((BASE / n).read_bytes()) for n in ('common.py','source.py','derive_capture.py')}
r = subprocess.run(command,capture_output=True,text=True)
save('source-derivation.json',dict(command=command,status=r.returncode,stdout=r.stdout,stderr=r.stderr,inputs=inputs))
print(r.stdout,r.stderr,flush=True)
need(type(r.returncode) is int and r.returncode == 0 and not r.stderr,'actual whole source derivation success')

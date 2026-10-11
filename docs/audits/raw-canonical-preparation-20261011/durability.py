"""Exercise reconstruction with the qualified ignored checkpoint absent."""
import json
from pathlib import Path
import subprocess
from capture import BASE, save
import checkpoint

source = json.loads((BASE / 'source-v3.json').read_bytes())
original = checkpoint.VIEW
held = original.with_name(original.name + '-held-for-restoration')
checkpoint.need(not checkpoint.boundary.local(held).exists(), 'fresh ordinary retained checkpoint route')
before = checkpoint.census(source)
original.rename(held)
command = ['python3', '-B', str(BASE / 'restore.py')]
result = subprocess.run(command, capture_output=True, text=True)
actual = dict(command=command, status=result.returncode, stdout=result.stdout, stderr=result.stderr,
              original=str(original), held=str(held), before=before,
              source='Complete source-v3.json committed Git objects only; first ignored view is retained separately.')
# Save the native terminal before deciding whether reconstruction succeeded.
save('restoration-actual.json', actual)
checkpoint.need(type(result.returncode) is int and result.returncode == 0
                and result.stdout == checkpoint.SUCCESS and result.stderr == '',
                'actual fresh committed-only checkpoint reconstruction and unchanged reader success')
after = checkpoint.census(source)
checkpoint.VIEW = held
retained = checkpoint.census(source)
checkpoint.need(before == after == retained, 'complete restored and retained source graphs conserve')
save('restoration-census.json', dict(before=before, restored=after, retained=retained))
print('PASS actual Git-only reconstruction with the earlier ignored view absent; complete source populations conserve.')

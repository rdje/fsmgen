"""Locate the exact live-publication predecessor through actual Git history."""
import subprocess
from common import save

command=['git','--no-replace-objects','log','--format=%H %s','-S',
         'identity/full formatting stay','--','docs/knowledge/record-value-original-observer-helper-paths.md']
actual=subprocess.run(command,capture_output=True,text=True)
save('root-cause.json',dict(command=command,status=actual.returncode,stdout=actual.stdout,stderr=actual.stderr))
if type(actual.returncode) is not int or actual.returncode!=0 or actual.stderr or not actual.stdout:
    raise ValueError('actual publication root-cause history qualification')
print('PASS actual git log -S publication predecessor retained with complete streams.')

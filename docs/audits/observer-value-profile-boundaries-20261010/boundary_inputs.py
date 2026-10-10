"""Bind whole already qualified original opaque intervals and raw body custody."""
import subprocess
from common import PUBLIC,RAW,REVISION,SCOPE,need,pin,save

result={}
for path in (PUBLIC,RAW):
    command=['git','--no-replace-objects','show',REVISION+':'+str(path)]
    actual=subprocess.run(command,capture_output=True)
    need(actual.returncode==0 and actual.stderr==b'' and actual.stdout==path.read_bytes(),
         'whole fixed/current original public/raw evidence')
    result[str(path)]=dict(command=command,status=actual.returncode,identity=pin(actual.stdout))
save('boundary-inputs.json',dict(revision=REVISION,inputs=result,scope=SCOPE,
    meaning='Complete already qualified original body/public-boundary custody only. No original display token supplies a new source-constructor or historical profile oracle.'))
print('PASS whole fixed/current original body and public-boundary evidence custody; all private/native meanings remain unmeasured.')

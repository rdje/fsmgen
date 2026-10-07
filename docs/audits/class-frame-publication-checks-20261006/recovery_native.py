"""Execute and retain every actual local source/native/current-guide phase."""
import hashlib
import json
import subprocess
from pathlib import Path

CHECKS = Path('docs/audits/class-frame-publication-checks-20261006')
DESTINATION = '.artifacts/class-frame-publication-book'
phases = [
    ['python3','-B','scripts/book_source_references.py','--write'],
    ['mdbook','build','docs/book','-d',DESTINATION],
    ['python3','-B','scripts/book_source_references.py','--check','--verify-build',DESTINATION],
    ['python3','-B','scripts/check_book_source_index.py'],
    ['python3','-B',str(CHECKS / 'native_guide.py')]]
records = []
for command in phases:
    instruments = {}
    for item in command:
        p = Path(item)
        if item.endswith('.py') and p.is_file():
            raw = p.read_bytes(); instruments[item] = dict(bytes=len(raw),sha256=hashlib.sha256(raw).hexdigest())
    result = subprocess.run(command,capture_output=True)
    records.append(dict(command=command,status=result.returncode,stdout=result.stdout.decode(),stderr=result.stderr.decode(),instruments=instruments))
    print(records[-1]['stdout'],end=''); print(records[-1]['stderr'],end='')
    if result.returncode: break
p = CHECKS / 'recovery-native-phases.json'; assert not p.exists()
p.write_text(json.dumps(dict(destination=DESTINATION,phases=records,
    role='Actual complete repository-local canonical/current/copied-source/index/native-guide phases; original raw/native captures retained and visual QA pending.'),sort_keys=True,indent=2) + '\n')
assert len(records) == len(phases) and all(type(r['status']) is int and r['status'] == 0 for r in records)
print('PASS actual complete local source/native class/frame publication phases.')

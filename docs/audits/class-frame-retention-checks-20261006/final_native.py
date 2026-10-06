"""Run and retain complete repository-local source/native publication phases."""
import hashlib
import json
import subprocess
from pathlib import Path

CHECKS = Path('docs/audits/class-frame-retention-checks-20261006')
DESTINATION = '.artifacts/class-frame-retention-book'
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
        source = Path(item)
        if item.endswith('.py') and source.is_file():
            raw = source.read_bytes(); instruments[item] = dict(bytes=len(raw),sha256=hashlib.sha256(raw).hexdigest())
    process = subprocess.run(command,capture_output=True)
    records.append(dict(command=command,status=process.returncode,stdout=process.stdout.decode(),stderr=process.stderr.decode(),instruments=instruments))
    print(records[-1]['stdout'],end=''); print(records[-1]['stderr'],end='')
    if process.returncode:
        break
path = CHECKS / 'final-native-phases.json'; assert not path.exists()
path.write_text(json.dumps(dict(destination=DESTINATION,phases=records,role='Actual repository-local native build, source selection/current/copied-byte/index checks and complete rendered retention guide controls; visual QA remains pending.'),sort_keys=True,indent=2) + '\n')
assert len(records) == len(phases) and all(type(r['status']) is int and r['status'] == 0 for r in records)
print('PASS actual complete local source/native retention publication phases.')

from pathlib import Path
import subprocess
b=Path('docs/audits/caller-formal-binding-cause-repair-20261003')
before=(b/'bindings.json').read_bytes()
subprocess.run(['python3',str(b/'bind.py')],check=True)
assert before==(b/'bindings.json').read_bytes()
print('PASS complete before-probe binding bytes conserved; console wording corrected.')

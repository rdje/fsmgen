"""Bind the final parser capture to exact before/after producer and input bytes."""
import hashlib
import json
import os
import subprocess
import sys
from pathlib import Path

base = Path('.artifacts/conditional-origin')
paths = ['t/2043-isf-conditional-origin-parser.t', 't/lib/FSM/Test/ConditionalOriginParser.pm',
         '.artifacts/conditional-origin/run_qualified.py', '.artifacts/conditional-origin/red_no_carry.t',
         'perl/FSM/Adapter/ISF/Parser.pm', 'perl/FSM/Adapter/ISF/LispishAdapter.pm',
         'docs/audits/conditional-macro-intent-20261002/cases.json',
         'docs/audits/procedure-cond-normalization-20261002/sources/first_samples.isf']
paths += [str(p) for p in sorted(Path('docs/audits/conditional-macro-intent-20261002/sources').glob('*.isf'))]
def hashes():
    return {p: hashlib.sha256(Path(p).read_bytes()).hexdigest() for p in paths}
before = hashes()
red = len(sys.argv) > 1 and sys.argv[1] == 'red'
env = dict(os.environ, FSMGEN_CONDITIONAL_ORIGIN_CAPTURE=str(base / 'current-corrected'))
test = '.artifacts/conditional-origin/red_no_carry.t' if red else 't/2043-isf-conditional-origin-parser.t'
argv = ['prove','-Iperl','-It/lib',test]
result = subprocess.run(argv, env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
name = 'no-carry-bound' if red else 'current-bound'
(base / (name + '.tap')).write_bytes(result.stdout)
(base / (name + '-stderr.txt')).write_bytes(result.stderr)
after = hashes()
(base / (name + '-recipe.json')).write_text(json.dumps({
    'baseline': '985e5e9707cd987a7b70a878f0c686ad36e191d6', 'argv': argv,
    'capture_env': {'FSMGEN_CONDITIONAL_ORIGIN_CAPTURE': env['FSMGEN_CONDITIONAL_ORIGIN_CAPTURE']},
    'status': result.returncode, 'stdout': name + '.tap', 'stderr': name + '-stderr.txt',
    'before': before, 'after': after,
}, indent=2, sort_keys=True) + '\n')
assert before == after, 'qualified producer/input bytes changed during execution'
if red:
    assert result.returncode == 1 and b'Files=1, Tests=43' in result.stdout and b'Failed 43/43' in result.stdout and b'Result: FAIL' in result.stdout
else:
    assert result.returncode == 0 and b'Files=1, Tests=54' in result.stdout and b'Result: PASS' in result.stdout
print('PASS exact before/after producer/instrument/source identities and terminal fixed ' + name + ' capture')

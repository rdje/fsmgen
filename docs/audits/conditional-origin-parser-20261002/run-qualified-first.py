"""Bind the final parser capture to exact before/after producer and input bytes."""
import hashlib
import json
import os
import subprocess
from pathlib import Path

base = Path('.artifacts/conditional-origin')
paths = ['t/2043-isf-conditional-origin-parser.t', 't/lib/FSM/Test/ConditionalOriginParser.pm',
         'perl/FSM/Adapter/ISF/Parser.pm', 'perl/FSM/Adapter/ISF/LispishAdapter.pm',
         'docs/audits/conditional-macro-intent-20261002/cases.json',
         'docs/audits/procedure-cond-normalization-20261002/sources/first_samples.isf']
paths += [str(p) for p in sorted(Path('docs/audits/conditional-macro-intent-20261002/sources').glob('*.isf'))]
def hashes():
    return {p: hashlib.sha256(Path(p).read_bytes()).hexdigest() for p in paths}
before = hashes()
env = dict(os.environ, FSMGEN_CONDITIONAL_ORIGIN_CAPTURE=str(base / 'current-corrected'))
argv = ['prove','-Iperl','-It/lib','t/2043-isf-conditional-origin-parser.t']
result = subprocess.run(argv, env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
(base / 'current-bound.tap').write_bytes(result.stdout)
(base / 'current-bound-stderr.txt').write_bytes(result.stderr)
after = hashes()
(base / 'qualified-recipe.json').write_text(json.dumps({
    'baseline': '985e5e9707cd987a7b70a878f0c686ad36e191d6', 'argv': argv,
    'capture_env': {'FSMGEN_CONDITIONAL_ORIGIN_CAPTURE': env['FSMGEN_CONDITIONAL_ORIGIN_CAPTURE']},
    'status': result.returncode, 'stdout': 'current-bound.tap', 'stderr': 'current-bound-stderr.txt',
    'before': before, 'after': after,
}, indent=2, sort_keys=True) + '\n')
assert before == after, 'qualified producer/input bytes changed during execution'
assert result.returncode == 0 and b'Files=1, Tests=54' in result.stdout and b'Result: PASS' in result.stdout
print('PASS exact before/after producer/source identities and terminal fixed parser capture')

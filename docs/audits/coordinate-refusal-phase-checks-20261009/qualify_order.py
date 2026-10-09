"""Reproduce the preserved unordered refusal predicate and qualify its repair."""
import hashlib
import json
import os
import subprocess
from pathlib import Path

BASE = Path('docs/audits/coordinate-refusal-phase-checks-20261009')
FIRST = BASE / 'first-verify.py.txt'
CURRENT = Path('docs/audits/coordinate-refusal-phases-20261009/verify.py')
SCRIPT = '''import copy,json,runpy,sys
from pathlib import Path
r=runpy.run_path(sys.argv[1])
p=json.loads(Path('docs/audits/coordinate-refusal-phases-20261009/phases.json').read_bytes())
bad=copy.deepcopy(p)
next(row for row in bad['refusals'] if len(row['phases'])==2)['phases'].reverse()
try:
    r['check'](bad,p)
except ValueError as error:
    print(str(error))
else:
    raise ValueError('false green reversed phase')
'''


def main():
    outputs = {}
    for path in (FIRST, CURRENT):
        results = []
        for seed in range(8):
            env = dict(os.environ, PYTHONHASHSEED=str(seed))
            run = subprocess.run(['python3', '-B', '-c', SCRIPT, str(path)], env=env, capture_output=True, text=True)
            if run.returncode or run.stderr or not run.stdout.startswith('phase field: '):
                raise ValueError('complete pure source ordering probe')
            results.append({'seed': seed, 'status': run.returncode, 'stdout': run.stdout, 'stderr': run.stderr})
        outputs[str(path)] = {'sha256': hashlib.sha256(path.read_bytes()).hexdigest(), 'results': results}
    before = {r['stdout'] for r in outputs[str(FIRST)]['results']}
    after = {r['stdout'] for r in outputs[str(CURRENT)]['results']}
    if len(before) < 2 or after != {'phase field: phase\n'}:
        raise ValueError('genuine hash-order dependency and deterministic corrected predicate')
    print(json.dumps({'result': 'PASS preserved first unordered predicate and deterministic repair', 'outputs': outputs}, sort_keys=True))


if __name__ == '__main__':
    main()

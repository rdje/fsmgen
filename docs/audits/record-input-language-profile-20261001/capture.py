"""Capture FSMGen text only; never invoke an HDL tool or replay a native run."""
import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
DEST = Path(__file__).resolve().parent
CASES = {
    'direct': 't/data/isf_record_input_runtime.isf',
    'domains': 't/data/isf_record_input_generated_domains_runtime.isf',
    'blocking': 't/data/isf_record_input_generated_blocking_runtime.isf',
}
work = '.artifacts/record-input-language-profile'
rows = []
for name, source in CASES.items():
    for target in ('systemverilog', 'verilog'):
        output = f'{work}/{name}_{target}.sv'
        argv = ['perl', 'bin/fsmgen', '--quiet', '--strict', '--language', target,
                '--output', output, source]
        result = subprocess.run(argv, cwd=ROOT, capture_output=True, timeout=120)
        row = {'case': name, 'source': source, 'target': target, 'argv': argv,
               'exit_code': result.returncode,
               'stdout': result.stdout.decode(), 'stderr': result.stderr.decode()}
        rows.append(row)
        (DEST / 'emissions.json').write_text(json.dumps(rows, indent=2, sort_keys=True) + '\n')
        assert result.returncode == 0, row
        (DEST / f'{name}_{target}.hdl.source').write_bytes((ROOT / output).read_bytes())
result = subprocess.run(['git', 'diff', '--exit-code', '40a51936ed3424acccd65d9812cbc0c1e892da5b',
                         '--', 'bin', 'perl', 't', 'isf'], cwd=ROOT, capture_output=True)
(DEST / 'source-equivalence.json').write_text(json.dumps({
    'argv': result.args, 'exit_code': result.returncode,
    'stdout': result.stdout.decode(), 'stderr': result.stderr.decode()}, indent=2, sort_keys=True) + '\n')
assert result.returncode == 0
print('All six FSMGen-only emissions succeed; no HDL compiler or simulator invoked.')

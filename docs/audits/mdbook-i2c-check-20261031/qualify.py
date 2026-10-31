#!/usr/bin/env python3
"""Keep complete focused results and exact native producer identities locally."""
import gzip
import hashlib
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[3]
OUT = Path(__file__).resolve().parent
paths = [
    'perl/FSM/SourceLiteralWidthAllocationSupport.pm',
    'perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/SourceLiteralWidthSupport.pm',
    'perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm',
    'perl/FSM/Adapter/FSMGenFull/Parser.pm',
    'perl/FSM/Adapter/FSMGenFull/SignalAnalyzer.pm',
    'isf/i2c_master.isf', 't/1309-isf-i2c-fixture-coverage.t',
    't/2296-inline-shift-literal-emission.t',
    'docs/audits/mdbook-i2c-check-20261031/bad-width-projection.pl',
]
tests = [
    't/1309-isf-i2c-fixture-coverage.t', 't/2296-inline-shift-literal-emission.t',
    't/2251-source-literal-width-holder.t', 't/2252-source-literal-width-birth.t',
    't/2253-source-literal-width-transitions.t', 't/2254-source-literal-width-publication.t',
    't/2268-target-source-literal-emission.t', 't/2274-shift-width-transfer.t',
]
paths += tests
paths.append(Path(__file__).relative_to(ROOT).as_posix())
def seal():
    return {p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in sorted(set(paths))}
receipt = {'head': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
           'before': seal(), 'commands': [], 'scope': 'Focused restoration; full CI and hosted publication remain pending.'}
commands = [(['prove', '-Iperl', '-v', *tests], 0),
            (['perl', 'docs/audits/mdbook-i2c-check-20261031/bad-width-projection.pl'], 3),
            (['./bin/fsmgen', '--quiet', '--strict', '--check', '--json', 'isf/i2c_master.isf'], 0),
            (['perl', 'docs/audits/mdbook-i2c-check-20261031/probe.pl'], 0)]
for command, expected in commands:
    result = subprocess.run(command, cwd=ROOT, text=True, capture_output=True)
    receipt['commands'].append({'argv': command, 'expected_status': expected,
                                'status': result.returncode, 'stdout': result.stdout, 'stderr': result.stderr})
    print(json.dumps({'command': command[:3], 'status': result.returncode}), flush=True)
receipt['after'] = seal()
receipt['unchanged'] = receipt['before'] == receipt['after']
receipt['passed'] = receipt['unchanged'] and all(r['status'] == r['expected_status'] for r in receipt['commands'])
card = 'docs/knowledge/direct-declared-width-consumers.md'
original = subprocess.check_output(['git', 'show', 'HEAD:' + card], cwd=ROOT)
receipt['routed_prior_card'] = {'path': card, 'source': original.decode(),
                              'sha256': hashlib.sha256(original).hexdigest(),
                              'routing': 'Original binary-allocation paragraph routes to current canonical API/POD and task; preserve every existing answer question and keep card byte growth nonpositive.'}
with gzip.open(OUT / 'qualification.json.gz', 'wt') as stream:
    json.dump(receipt, stream, sort_keys=True)
assert receipt['passed'], 'focused qualification refused; inspect complete retained receipt'
print('focused I2C qualification passed')

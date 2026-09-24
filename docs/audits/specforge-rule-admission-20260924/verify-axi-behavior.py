"""Run existing independent AXI SV oracles in isolated Verilator workspaces."""
from pathlib import Path
import hashlib
import json
import os
import re
import subprocess
import sys

root = Path(__file__).resolve().parents[3]
os.chdir(root)
work = Path(sys.argv[1])
assert work.is_dir() and work.resolve().is_relative_to(root / '.artifacts')
assert work.stat().st_dev == root.stat().st_dev
temp = work / 'tmp'
temp.mkdir(exist_ok=True)
env = dict(os.environ, TMPDIR=str(temp.resolve()), TMP=str(temp.resolve()), TEMP=str(temp.resolve()))
cases = {
    'axi_aw_driver': 't/1499-ial2-axi-aw-driver.t',
    'axi_w_driver': 't/1500-ial2-axi-w-driver.t',
    'axi_b_response_acceptor': 't/1501-ial2-axi-b-response-acceptor.t',
    'axi_ar_driver': 't/1504-ial2-axi-ar-driver.t',
    'axi_r_beat_acceptor': 't/1505-ial2-axi-r-beat-acceptor.t',
    'axi_w_burst4_driver': 't/data/axi_w_burst4_driver_tb.svt',
}
compositions = len(sys.argv) == 3 and sys.argv[2] == '--compositions'
assert len(sys.argv) == 2 or compositions
if compositions:
    cases = {
        'axi_write_request_composition': 't/1502-ial2-axi-write-request-composition.t',
        'axi_write_transaction_composition': 't/1503-ial2-axi-write-transaction-composition.t',
        'axi_write_burst4_request_composition': 't/data/axi_write_burst4_request_composition_tb.svt',
        'axi_read_transaction_composition': 't/data/axi_read_transaction_composition_tb.svt',
        'axi_read_burst4_transaction_composition': 't/data/axi_read_burst4_transaction_composition_tb.svt',
    }
receipts = []
for name, oracle in cases.items():
    case = work / name if compositions else work
    report = json.loads((case / (name + '.json')).read_bytes())
    entry = report['report']['generated_artifacts']['hdl_entry']['entry_artifact']
    assert re.fullmatch(r'[A-Za-z0-9_]+\.fsm', entry), entry
    source = Path(oracle).read_text()
    if oracle.endswith('.t'):
        matches = re.findall(r"write_file\(\$testbench, <<'SV'\);\n(.*?)\nSV\n", source, re.S)
        assert len(matches) == 1, oracle
        source = matches[0] + '\n'
    top = re.search(r'^module ([A-Za-z0-9_]+);', source).group(1)
    tb = case / (name + '-tb.sv')
    tb.write_text(source)
    hdl = case / (name + '.sv')
    obj = case / (name + '-obj')
    binary = obj / ('V' + top)
    # Composition oracles deliberately drive malformed addresses/IDs to check
    # physical admission and captured error status. Preserve their published
    # --no-assert profile; endpoint oracles use --assert.
    assertion_mode = '--no-assert' if compositions else '--assert'
    row = dict(source=name, oracle=oracle, oracle_sha256=hashlib.sha256(source.encode()).hexdigest(),
               assertion_mode=assertion_mode, stages=[])
    for stage, argv in [
        ('generate', ['./bin/fsmgen', '--strict', '--quiet', '--output', str(hdl), str(case / entry)]),
        ('compile', ['verilator', '--binary', '--timing', assertion_mode, '-Wno-fatal', '-j', '1',
                     '--top-module', top, '--Mdir', str(obj), str(hdl), str(tb)]),
        ('simulate', [str(binary)]),
    ]:
        result = subprocess.run(argv, env=env, capture_output=True, timeout=120)
        for stream in ('stdout', 'stderr'):
            (case / (name + '-' + stage + '.' + stream)).write_bytes(getattr(result, stream))
        row['stages'].append(dict(stage=stage, argv=argv, exit=result.returncode,
                                 stdout=result.stdout.decode(errors='replace')))
        if result.returncode or stage == 'simulate' and b'PASS ' not in result.stdout:
            receipts.append(row)
            (work / 'behavior-receipt.json').write_text(json.dumps(receipts, sort_keys=True, indent=2) + '\n')
            raise RuntimeError(f'{name} {stage} failed; see retained stage logs')
    row['hdl_sha256'] = hashlib.sha256(hdl.read_bytes()).hexdigest()
    receipts.append(row)
    (work / 'behavior-receipt.json').write_text(json.dumps(receipts, sort_keys=True, indent=2) + '\n')
    print(name, row['stages'][-1]['stdout'].strip(), flush=True)

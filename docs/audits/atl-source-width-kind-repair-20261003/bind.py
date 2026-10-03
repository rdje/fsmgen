import hashlib
import json
import subprocess
from pathlib import Path
B = Path(__file__).parent
rev = subprocess.check_output(['git', 'rev-parse', 'HEAD']).decode().strip()
assert rev == 'b30ed324e63549180f50c3d624d386258fba7405'
paths = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', rev, '--',
    'bin', 'perl', 't', 'scripts', 'isf']).decode().splitlines()
paths.append('t/2059-isf-atl-source-width-kind-preservation.t')
selected = ['perl/FSM/Scheduler/ISF/LoweringIR.pm',
    't/2059-isf-atl-source-width-kind-preservation.t',
    'isf/atl_resolved_child_pin_egress_vector_multi_pipeline.isf',
    'isf/atl_two_child_vector_data_pipeline.isf']
(B / 'after-bindings.json').write_text(json.dumps({
    'baseline': rev, 'metadata': {p: {'bytes': len(Path(p).read_bytes()),
        'sha256': hashlib.sha256(Path(p).read_bytes()).hexdigest()} for p in paths},
    'sources': {p: Path(p).read_text() for p in selected}}, sort_keys=True, indent=2) + '\n')
print('Bound complete source closure after the detached-scalar repair.')

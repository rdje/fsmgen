"""Bind exact T1983 source contracts; no runtime or cause-safety inference."""
import hashlib
import json
import re
import subprocess
from pathlib import Path

BASE = Path(__file__).parent
REVISION = '29bb555ab51615f038bd2ce228de230f8efc0305'
paths = (
    't/1983-isf-interface-port-metadata.t',
    'perl/FSM/Support/ISFInterfacePortMetadata.pm',
    'perl/FSM/Adapter/ISF.pm', 'perl/FSM/Adapter/ISF/Parser.pm',
    'perl/FSM/Package/AggregatePathSupport.pm',
    'perl/FSM/Package/ImportResolver.pm', 'perl/FSM/Package/Parser.pm',
    'perl/FSM/Pipeline/SourceFrontend.pm',
    't/lib/FSM/Test/ProjectDataLocality.pm',
)
assert subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip() == REVISION
sources = {}
for path in paths:
    raw = subprocess.check_output(['git', 'show', REVISION + ':' + path])
    assert raw == Path(path).read_bytes()
    sources[path] = {'body': raw.decode(), 'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}
source = sources[paths[0]]['body']
start = source.index('sub rejects {'); end = source.index('sub write_file {', start)
tokens = []
roles = {109: 'string_label', 196: 'snapshot_helper_call', 200: 'string_label',
    219: 'capture_helper_call', 225: 'definition'}
for match in re.finditer(r'\brejects\b', source):
    line = source[:match.start()].count('\n') + 1
    tokens.append({'line': line, 'offset': match.start(), 'role': roles[line],
        'whole_line': source.splitlines()[line - 1]})
copies = [{'line': source[:m.start()].count('\n') + 1, 'offset': m.start(),
    'whole_line': source.splitlines()[source[:m.start()].count('\n')]}
    for m in re.finditer(r'\bdclone\(', source)]
plan = {'revision': REVISION, 'sources': sources, 'helper': source[start:end],
    'tokens': tokens, 'copies': copies,
    'adjacent_assertions': [
        {'line': 110, 'kind': 'first-line generic metadata context', 'route': 'capture and snapshot stringified valid-prefix/bad-suffix loop'},
        {'line': 128, 'kind': 'full-error output-member refusal fragment', 'route': 'actual public parser output-member writer'},
    ],
    'probe_plan': {'actual_helper_routes': ['capture_interface_port_metadata', 'snapshot_interface_port_metadata'],
        'host_routes': ['Carp', 'Storable', 'Scalar::Util', 'Lispish public parse API', 'project-local temporary package reads'],
        'excluded_execution': ['HDL compiler/simulator', 'native proxy/controller runtime', 'macro transport', 'submodule implementation'],
        'required_observation': ['whole inputs/results and primitive kinds/sharing', 'actual saved errors and warnings',
            'every helper/adjacent assertion', 'all original/copy graphs', 'independent intended complete causes',
            'real earlier/caller/primary controls and exact prior safety outcomes'],
        'later_obligations': ['source/product/private projection semantics', 'plain/native/cycle/copy assurance',
            'freeze preceding complete coverage source qualification before hot public-source changes',
            'own observed defects before bounded repairs']}}
(BASE / 'contracts.json').write_text(json.dumps(plan, sort_keys=True, indent=2) + '\n')
print('PASS complete selected current Git contracts: T1983 has five same-file name tokens (one definition/two calls/two strings) and eight source copy sites; these are syntax units, not runtime call/copy counts. Actual source-owned metadata probes remain pending.')

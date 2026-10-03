import difflib
import hashlib
import json
import subprocess
from pathlib import Path

base = Path(__file__).parent
revision = 'edb671c716b987414f81cb367605b9aa54841f10'
assert subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip() == revision
changed = 't/1960-isf-formal-reservation-coverage.t'
added = 't/2063-isf-coverage-diagnostic-causes.t'
members = {}
for entry in subprocess.check_output(['git', 'ls-tree', '-r', '-z', revision, '--',
                                     'bin', 'perl', 't', 'scripts', 'isf']).split(b'\0'):
    if entry:
        header, name = entry.split(b'\t', 1)
        mode, kind, oid = header.decode().split()
        assert kind == 'blob' and mode in ('100644', '100755')
        members[name.decode()] = oid
assert added not in members
metadata = {}
for name in sorted(set(members) | {added}):
    raw = Path(name).read_bytes()
    actual = hashlib.sha1(b'blob ' + str(len(raw)).encode() + b'\0' + raw).hexdigest()
    if name != changed and name != added:
        assert actual == members[name], name
    metadata[name] = {'baseline_blob': members.get(name), 'current_blob': actual,
                      'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}
selected = [changed, added, 't/lib/FSM/Test/DiagnosticCause.pm',
            'perl/FSM/Scheduler/ISF/FormalReservationCoverage.pm',
            'perl/FSM/Scheduler/ISF/FormalReservationInventory.pm',
            'perl/FSM/Scheduler/ISF/PreparedFormalReservations.pm',
            'perl/FSM/Scheduler/ISF/FormalIdentityPlan.pm',
            'perl/FSM/Scheduler/ISF/FormalClauseResolver.pm',
            'perl/FSM/Scheduler/ISF/LoweringIR.pm']
sources = {}
for name in selected:
    prior = subprocess.check_output(['git', 'show', revision + ':' + name], text=True) if name in members else None
    sources[name] = {'before': prior, 'after': Path(name).read_text()}
delta = subprocess.check_output(['git', 'diff', revision, '--', changed], text=True)
delta += ''.join(difflib.unified_diff([], sources[added]['after'].splitlines(keepends=True),
                                    fromfile='absent', tofile=added))
(base / 'source-delta.patch').write_text(delta)
instruments = {}
checks = Path('docs/audits/reservation-coverage-cause-repair-checks-20261003')
for filename in ('prior-source.t', 'prior-desired.pl', 'produce.sh', 'portable.py'):
    path = checks / filename
    raw = path.read_bytes()
    instruments[str(path)] = {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest(),
                              'body': raw.decode()}
(base / 'bindings.json').write_text(json.dumps({'baseline': revision, 'metadata': metadata,
                                               'sources': sources, 'instruments': instruments}, sort_keys=True, indent=2) + '\n')
print('PASS whole immutable Git/current byte closure permits only T1960 and new T2063; complete selected source/delta retained.')

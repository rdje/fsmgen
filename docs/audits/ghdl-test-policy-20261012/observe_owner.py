"""Bind the complete selected ownership-watcher input domain and native result."""
from pathlib import Path
import argparse
import base64
import gzip
import hashlib
import json
import stat
import subprocess

BASE = Path('docs/audits/ghdl-test-policy-20261012')
SELECTOR = Path('.artifacts/ghdl-test-policy-20261012/owner-watch-only.pl')

def save(name, value):
    with (BASE / name).open('x') as stream:
        json.dump(value, stream, sort_keys=True, separators=(',', ':'))
        stream.write('\n')

def epoch(label):
    names = {path.as_posix() for pattern in ('t/*.t', 't/lib/FSM/Test/**/*.pm',
                                           'perl/FSM/Support/**/*.pm')
             for path in Path('.').glob(pattern) if path.is_file()}
    names.update({'.proverc', 'perl/FSM/ProjectDataLocality.pm', 'scripts/run_with_ram_guard.sh',
                  __file__ if not Path(__file__).is_absolute()
                  else Path(__file__).relative_to(Path.cwd()).as_posix(), str(SELECTOR)})
    names.update(path.as_posix() for path in BASE.glob('*.py'))
    names.update(path.as_posix() for path in BASE.rglob('*.pm'))
    rows = {}
    for name in sorted(names):
        path = Path(name)
        assert not path.is_symlink() and path.resolve().is_relative_to(Path.cwd())
        body = path.read_bytes()
        rows[name] = dict(bytes=len(body), sha256=hashlib.sha256(body).hexdigest(),
                          mode=stat.S_IMODE(path.stat().st_mode),
                          body_base64=base64.b64encode(body).decode())
    payload = gzip.compress(json.dumps(rows, sort_keys=True,
                                      separators=(',', ':')).encode(), mtime=0)
    name = label + '.json.gz'
    with (BASE / name).open('xb') as stream:
        stream.write(payload)
    return dict(path=(BASE / name).as_posix(), files=len(rows),
                bytes=sum(row['bytes'] for row in rows.values()),
                sha256=hashlib.sha256(payload).hexdigest()), rows

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('label')
    parser.add_argument('--expect', type=int, choices=(0, 1), required=True)
    args = parser.parse_args()
    assert args.label and all(c in 'abcdefghijklmnopqrstuvwxyz0123456789-' for c in args.label)
    if not SELECTOR.exists():
        SELECTOR.parent.mkdir(parents=True, exist_ok=True)
        SELECTOR.write_bytes(Path('.artifacts/task-acceptance-audit-source-coverage-20261012/owner-watch-only.pl').read_bytes())
    before, inputs = epoch(args.label + '-before')
    command = ['scripts/run_with_ram_guard.sh', '--', 'prove', '-v', '-Iperl', '-It/lib', str(SELECTOR)]
    start = dict(owner='TASK-ACCEPTANCE-AUDIT-SOURCE-COVERAGE.1.1.2', command=command,
                 expected_status=args.expect, source_before=before,
                 scope='Only the unchanged policy-adapter ownership subtest; no whole T1669 or HDL-runtime claim.')
    save(args.label + '-started.json', start)
    result = subprocess.run(command, capture_output=True, text=True)
    after, final = epoch(args.label + '-after')
    history_command = ['git', 'log', '-p', '-S', "stage=>'verilator_lint'", '--',
                       't/1952-isf-storage-keyword-identifiers.t']
    history = subprocess.run(history_command, capture_output=True, text=True)
    save(args.label + '-actual.json', dict(**start, status=result.returncode,
         stdout=result.stdout, stderr=result.stderr, source_after=after,
         source_conserved=inputs == final,
         lint_introducing_history=dict(command=history_command, status=history.returncode,
                                      stdout=history.stdout, stderr=history.stderr)))
    print(args.label, 'native', result.returncode, 'expected', args.expect,
          'complete source conserved', inputs == final, flush=True)
    assert result.returncode == args.expect and inputs == final and history.returncode == 0

if __name__ == '__main__':
    main()

"""Capture HDL policy gates with complete ownership-input source epochs."""
from pathlib import Path
import argparse
import base64
import gzip
import hashlib
import json
import subprocess
from observe_owner import BASE, epoch, save

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('label')
    parser.add_argument('command', nargs=argparse.REMAINDER)
    args = parser.parse_args()
    assert args.command and args.label
    assert all(c in 'abcdefghijklmnopqrstuvwxyz0123456789-' for c in args.label)
    folder = Path('.artifacts/ghdl-test-policy-20261012/checks') / args.label
    folder.mkdir(parents=True, exist_ok=False)
    before, inputs = epoch(args.label + '-before')
    command = ['scripts/run_with_ram_guard.sh', '--', *args.command]
    start = dict(owner='TASK-ACCEPTANCE-AUDIT-SOURCE-COVERAGE.1.1.2', command=command,
                 expected_status=0, source_before=before,
                 condition='Complete ownership-input and audit-programme epochs; '
                           'native commands and raw streams retain. Fake-provider '
                           'controls do not qualify actual HDL semantics.')
    save(args.label + '-started.json', start)
    with (folder / 'stdout').open('xb') as out, (folder / 'stderr').open('xb') as err:
        result = subprocess.run(command, stdout=out, stderr=err)
    after, final = epoch(args.label + '-after')
    streams = {}
    for name in ('stdout', 'stderr'):
        body = (folder / name).read_bytes()
        streams[name] = dict(bytes=len(body), sha256=hashlib.sha256(body).hexdigest(),
            body_base64=base64.b64encode(body).decode(),
            text=body.decode('utf-8', errors='backslashreplace'),
            text_encoding='utf-8/backslashreplace; raw base64 bytes are authoritative')
    actual = dict(**start, status=result.returncode, streams=streams,
                  source_after=after, source_conserved=inputs == final)
    with (BASE / (args.label + '-actual.json.gz')).open('xb') as out:
        out.write(gzip.compress(json.dumps(actual, sort_keys=True).encode(), mtime=0))
    print(args.label, 'native', result.returncode, 'complete source conserved', inputs == final, flush=True)
    if result.returncode or inputs != final:
        raise SystemExit(1)

if __name__ == '__main__':
    main()

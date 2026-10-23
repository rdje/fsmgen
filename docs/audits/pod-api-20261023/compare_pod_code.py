#!/usr/bin/env python3
"""Compare all changed Perl source code outside POD at two explicit boundaries."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys

assert len(sys.argv) in (2, 3), 'Usage: compare_pod_code.py BASE [AFTER]; AFTER defaults to worktree'
base = sys.argv[1]
after = sys.argv[2] if len(sys.argv) == 3 else None


def git(*args):
    return subprocess.check_output(['git', *args])


def code(raw):
    lines = []
    pod = False
    for line in raw.decode().splitlines(keepends=True):
        if not pod and line.rstrip('\r\n') in ('__END__', '__DATA__'):
            break
        if line.startswith('=') and len(line) > 1 and line[1].isalpha():
            pod = True
        if not pod:
            lines.append(line)
        if line.startswith('=cut'):
            pod = False
    return ''.join(lines).rstrip().encode()


paths = git('diff', '--name-only', base, *([after] if after else []), '--', 'perl/FSM').decode().splitlines()
assert paths, 'No changed Perl sources at these boundaries'
rows = []
for path in paths:
    assert path.endswith('.pm'), path
    before = git('show', base + ':' + path)
    current = git('show', after + ':' + path) if after else Path(path).read_bytes()
    assert code(before) == code(current), 'Runtime code changed: ' + path
    rows.append({'source': path, 'before_sha256': hashlib.sha256(before).hexdigest(),
                 'after_sha256': hashlib.sha256(current).hexdigest(),
                 'code_sha256': hashlib.sha256(code(current)).hexdigest()})
print(json.dumps({'base': git('rev-parse', base).decode().strip(),
                  'after': git('rev-parse', after).decode().strip() if after else 'worktree',
                  'changed_sources': rows}, indent=2, sort_keys=True))

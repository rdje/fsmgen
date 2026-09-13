"""Retain the sole admitted result and observe original owner absence once."""

import errno
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
ADMISSION = BASE.parent / 'native-proxy-language-coordination-admission-20260913'
sys.path.insert(0, str(ADMISSION))
from local_files import direct, pin, read_bytes
from runtime import process_reader

REVISION = '295130388c20c6ee94650c610c2df6d597eeffa7'
TASK = 'docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md'


def retain(name, value):
    with (BASE / name).open('x') as stream:
        json.dump(value, stream, sort_keys=True, indent=2)
        stream.write('\n')


def main():
    assert subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT).decode().strip() == REVISION
    plan = json.loads((ADMISSION / 'plan.json').read_bytes())
    output = '.artifacts/logs/' + BASE.name
    permit = json.loads(read_bytes(output + '/execution-admission.json', 4096))
    task = read_bytes(TASK, 2 * 1024 * 1024)
    assert permit['admission_commit'] == REVISION
    assert permit['execution_owner'] == plan['execution_owner']
    assert hashlib.sha256(task).hexdigest() == permit['task_sha256']
    with (BASE / 'execution-task.md.source').open('xb') as stream:
        stream.write(task)

    sources = json.loads((ADMISSION / 'preflight-pins.json').read_bytes())
    sources += [pin((ADMISSION / name).relative_to(ROOT).as_posix())
                for name in ('preflight-pins.json', 'staged-gate.json')]
    assert len({row['path'] for row in sources}) == len(sources)
    for row in sources:
        assert pin(row['path']) == row
        body = subprocess.check_output(['git', 'show', REVISION + ':' + row['path']], cwd=ROOT)
        assert len(body) == row['size_bytes'] and hashlib.sha256(body).hexdigest() == row['sha256']
    retain('inputs.json', sources)

    journal = read_bytes(output + '/journal.jsonl', plan['bounds']['journal_bytes'])
    rows = [json.loads(line) for line in journal.splitlines()]
    paths = set(plan['prospective_outputs']) | {output + '/execution-admission.json'}
    log = '.artifacts/logs/' + ADMISSION.name
    for stage in ('commit', 'execution-permit', 'actual-execution'):
        assert read_bytes(log + '/' + stage + '.exit', 32) == b'0\n'
        paths.update(log + '/' + stage + '.' + suffix for suffix in ('stdout', 'stderr', 'exit'))
    files = []
    for relative in sorted(paths):
        body = read_bytes(relative, 4 * 1024 * 1024)
        files.append(dict(**pin(relative), bytes_hex=body.hex()))
    retain('first-run.json', dict(schema='fsmgen.language_coordination_retained_run.v1',
        owner=plan['execution_owner'], admission_commit=REVISION, files=files))

    identities = [rows[0]['controller']] + [row['identity'] for row in rows
        if row['event'] in ('native_spawned', 'probe_native_admitted')]
    reader = process_reader()
    absent = []
    birth = lambda value: tuple(value[key] for key in ('pid', 'start_sec', 'start_usec'))
    for identity in identities:
        try:
            current = reader.identity(identity['pid'])
        except OSError as failure:
            assert failure.errno == errno.ESRCH
            absent.append(dict(original=identity, disposition='native_esrch', errno=failure.errno))
        else:
            assert birth(current) != birth(identity), ('original owner remains', identity)
            absent.append(dict(original=identity, disposition='pid_reused_by_different_birth', current=current))
    groups = []
    for row in rows:
        if row['event'] != 'native_spawned':
            continue
        try:
            os.killpg(row['pgid'], 0)
        except ProcessLookupError:
            groups.append(dict(pgid=row['pgid'], disposition='numeric_group_absent'))
        else:
            # A new group using the same number requires explicit review, never a signal.
            raise ValueError('numeric group exists at independent post-run census')
    absent_objects = []
    for relative in plan['prospective_objects']:
        assert direct(relative, absent_ok=True) is None
        absent_objects.append(relative)
    retain('post-run-census.json', dict(owner=plan['execution_owner'],
        observation='Read-only native identity and signal-zero group existence; no termination signal.',
        external_read_only_dependency='/usr/lib/libproc.dylib',
        original_births_absent=absent, groups=groups, absent_objects=absent_objects,
        original_producer_replayed=False, native_proxy_execution=False))
    print(json.dumps(dict(retained_files=len(files), journal_records=len(rows),
        native_owners_absent=len(absent), groups_absent=len(groups),
        fixture_roots_absent=len(absent_objects), original_producer_replayed=False), sort_keys=True))


if __name__ == '__main__':
    main()

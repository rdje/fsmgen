"""Retain exact rollover preparation stdout/stderr and programme/task custody."""
import gzip
import subprocess
from pathlib import Path
import sys

sys.path.insert(0, 'docs/audits/task-terminal-rollover-20261011')
import common

BASE = Path('docs/audits/inventory-task-rollover-20261019')
NAMES = (str(BASE / 'rollover.py'), str(BASE / 'capture.py'),
         'docs/audits/task-terminal-rollover-20261011/common.py',
         'docs/audits/task-terminal-rollover-20261011/verify.py')


def programmes():
    return {name: common.local(name).read_text() for name in NAMES}


if __name__ == '__main__':
    command = ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', str(BASE / 'rollover.py'), '--prepare']
    start = dict(command=command, programmes=programmes(), task_before=common.local(common.TASK).read_text(),
                 head=common.git('rev-parse', 'HEAD').decode().strip(), index=common.git('ls-files', '--stage', '-z').decode())
    common.save(BASE / 'prepare-started.json.gz', gzip.compress(common.canonical(start), mtime=0))
    result = subprocess.run(command, capture_output=True)
    actual = dict(start, status=result.returncode, stdout=result.stdout.decode(), stderr=result.stderr.decode(),
                  programmes_after=programmes(), task_after=common.local(common.TASK).read_text(),
                  head_after=common.git('rev-parse', 'HEAD').decode().strip(), index_after=common.git('ls-files', '--stage', '-z').decode())
    common.save(BASE / 'prepare-actual.json.gz', gzip.compress(common.canonical(actual), mtime=0))
    assert type(result.returncode) is int and result.returncode == 0
    assert actual['programmes_after'] == start['programmes']
    assert actual['head_after'] == start['head'] and actual['index_after'] == start['index']
    print('Whole rollover preparation source/task/native custody retained.')

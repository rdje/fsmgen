"""Retain every actual command, stream and complete program epoch, including failures."""
import subprocess
import sys
from common import BASE, canonical, need, pin, save


def execute(label, command):
    previous = list(BASE.glob('actual-' + label + '-*.json'))
    name = 'actual-' + label + '-' + str(len(previous) + 1) + '.json'
    programs = {str(p):dict(identity=pin(p.read_bytes()), body=p.read_text())
                for p in sorted(BASE.iterdir()) if p.suffix in ('.py', '.pl')}
    result = subprocess.run(command, capture_output=True, text=True)
    record = dict(command=command, status=result.returncode, stdout=result.stdout,
                  stderr=result.stderr, programs=programs)
    save(name, record)
    print(name, result.returncode, result.stdout[-500:], result.stderr[-1000:], flush=True)
    need(type(result.returncode) is int and result.returncode == 0 and not result.stderr,
         'actual complete successful step: ' + name)
    return record


if __name__ == '__main__':
    need(len(sys.argv) >= 3, 'label and explicit command required')
    execute(sys.argv[1], sys.argv[2:])

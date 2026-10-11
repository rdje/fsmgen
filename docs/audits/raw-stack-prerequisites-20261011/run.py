"""Retain every actual command, stream and complete program epoch, including failures."""
import subprocess
import sys
from common import BASE, canonical, need, pin, save


def execute(label, command):
    previous = list(BASE.glob('actual-' + label + '-*.json'))+list(BASE.glob('started-'+label+'-*.json'))
    number=max((int(path.stem.rsplit('-',1)[1]) for path in previous),default=0)+1
    name = 'actual-' + label + '-' + str(number) + '.json'
    programs = {str(p):dict(identity=pin(p.read_bytes()), body=p.read_text())
                for p in sorted(BASE.iterdir()) if p.suffix in ('.py', '.pl')}
    # A guard may terminate the entire process tree. Persist the exact
    # command and complete programme epoch before starting any child.
    save('started-'+label+'-'+str(number)+'.json',dict(command=command,programs=programs,
        scope='Pre-execution source and command admission only; no outcome is asserted.'))
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

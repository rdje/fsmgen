"""Authenticate entire fixed inputs, then execute completed saved readers only."""
import subprocess
from common import BASE, DISPLAY, PRIOR, REVISION, ROLE, READERS, load, module, need, pin, save


def roots():
    command = ['git', '--no-replace-objects', 'show', REVISION + ':' + str(PRIOR / 'custody.json')]
    selected = set(__import__('json').loads(subprocess.check_output(command))['roots'])
    selected.add(str(PRIOR))
    return sorted(p for p in selected if not any(p.startswith(q + '/') for q in selected if p != q))


def main():
    admission = module(__import__('pathlib').Path('docs/audits/address-raw-admission-20261010/admit.py'))
    admission['custody'].__globals__.update(REVISION=REVISION, roots=roots)
    save('custody.json', admission['custody']())
    for name, args in READERS.items():
        command = ['python3', '-B', *args]
        programme = __import__('pathlib').Path(args[0])
        result = subprocess.run(command, capture_output=True, text=True)
        save('reader-' + name + '.json', dict(command=command, status=result.returncode,
             stdout=result.stdout, stderr=result.stderr, programme=pin(programme.read_bytes()), role=ROLE))
        print(name, result.returncode, result.stdout[-500:], result.stderr[-500:], flush=True)
        need(type(result.returncode) is int and result.returncode == 0 and not result.stderr,
             'actual complete prerequisite reader: ' + name)
    print('PASS complete fixed source custody and saved prerequisite executions; no original recapture.')


if __name__ == '__main__':
    main()

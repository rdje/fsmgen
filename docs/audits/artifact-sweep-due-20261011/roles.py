"""Exercise saved and current publication roles against real later pointer bytes."""
from pathlib import Path
import subprocess

from capture import BASE, pin, save


def main():
    memory = Path('MEMORY.md')
    before = memory.read_bytes()
    changed = before + b'\n<!-- owned later-pointer intervention -->\n'
    programmes = {str(BASE / name): (BASE / name).read_text() for name in ('verify.py', 'publish.py')}
    results = {}
    memory.write_bytes(changed)
    try:
        for role in ('saved', 'current'):
            code = ("import sys; sys.path.insert(0, 'docs/audits/artifact-sweep-due-20261011'); "
                    "import verify; verify.publication(current=" + str(role == 'current') + "); print('PASS " + role + " publication role')")
            command = ['python3', '-B', '-c', code]
            actual = subprocess.run(command, capture_output=True, text=True)
            results[role] = dict(command=command, status=actual.returncode, stdout=actual.stdout, stderr=actual.stderr)
    finally:
        memory.write_bytes(before)
    save('saved-role-controls.json', dict(before=before.decode(), changed=changed.decode(),
        restored=memory.read_text(), programmes=programmes, results=results,
        condition='Actual saved/current reader invocations against real changed pointer bytes; exact original pointer restores even on refusal. No deletion runs.'))
    assert results['saved']['status'] == 0 and results['saved']['stdout'] == 'PASS saved publication role\n' and results['saved']['stderr'] == ''
    assert results['current']['status'] == 1 and 'ValueError: whole current cleanup publication source\n' in results['current']['stderr']
    assert memory.read_bytes() == before
    assert all(Path(name).read_text() == body for name, body in programmes.items())
    print('PASS actual saved reader accepts later pointer while current selector refuses; exact original bytes restore.')


if __name__ == '__main__':
    main()

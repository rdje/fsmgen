"""Replay exact first-admission reader input with one genuine unknown native field."""
import contextlib
import io
import json
from pathlib import Path
from unittest import mock

BASE = Path('docs/audits/address-publication-preparation-20261010')
CASE = BASE / 'schema-first-admission'


def main():
    programme = BASE / 'first-qualified-verify.py.txt'
    namespace = {'__name__': 'first_admission_reader', '__file__': str(BASE / 'verify.py')}
    exec(compile(programme.read_bytes(), str(programme), 'exec'), namespace)
    candidate = (CASE / 'candidate.json').read_bytes()
    normal = json.loads((BASE / 'proposal.json').read_bytes()); changed = json.loads(candidate)
    assert changed.pop('original_native_identity') == 'unsubstantiated first-admission claim'
    assert changed == normal
    original_read, original_exists, original_write = Path.read_bytes, Path.exists, Path.write_text
    proposal, proof = BASE / 'proposal.json', BASE / 'proof.json'

    def read(path):
        if path == proposal:
            return candidate
        if path == BASE / 'verify.py':
            return original_read(programme)
        return original_read(path)

    def exists(path):
        # A first admission has no earlier qualification seal. No predicate,
        # programme, source, status or other input is substituted.
        return False if path == proof else original_exists(path)

    def write(path, text, *args, **kwargs):
        assert path == proof, 'first reader may write only its new proof'
        target = CASE / 'produced-proof.json'
        if original_exists(target):
            assert original_read(target) == text.encode(), 'retain exact original false-green proof'
            return len(text)
        return original_write(target, text, *args, **kwargs)

    output = io.StringIO()
    with mock.patch.object(Path, 'read_bytes', read), mock.patch.object(Path, 'exists', exists), mock.patch.object(Path, 'write_text', write), contextlib.redirect_stdout(output):
        namespace['main']()
    assert output.getvalue() == namespace['SUCCESS']
    result = {'scope': 'Exact saved reader first-admission input interception only; original project inputs and proposal never change.',
              'candidate': namespace['pin'](candidate), 'programme': namespace['pin'](programme.read_bytes()),
              'actual_status': 0, 'actual_stdout': output.getvalue(), 'actual_stderr': '',
              'cause': 'qualify compares root/card schemas, scope and other declared values to the same unqualified input, allowing an unknown original_native_identity field before any prior seal exists.'}
    target = CASE / 'reproduction.json'
    rendered = json.dumps(result, sort_keys=True, indent=2) + '\n'
    if target.exists():
        assert target.read_bytes() == rendered.encode(), 'retain exact first reproduction result'
    else:
        target.write_text(rendered)
    print('REPRODUCED actual first-admission success with an unknown native-identity field; no original input was changed.')


if __name__ == '__main__':
    main()

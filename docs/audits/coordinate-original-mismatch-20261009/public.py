"""Retain finite public caller/compiler controls; never run original captures."""
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/coordinate-original-mismatch-20261009')


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def main():
    if (BASE / 'public.json').exists():
        raise ValueError('public attribution evidence never rewrites')
    source = (BASE / 'caller-fixture.pl').read_bytes()
    needle = b"$case = 'multiline-callback';\ncallsite(sub {\n    callbacksite();\n}, qr/marker/,\n    'label');"
    if source.count(needle) != 1:
        raise ValueError('unique controlled first fixture call')
    variants = {'caller-fixture.pl': source,
                'caller-pattern-shift.pl': source.replace(needle, needle.replace(b'}, qr/', b'},\n    qr/')),
                'caller-label-shift.pl': source.replace(needle, needle.replace(b"\n    'label');", b"\n\n    'label');"))}
    guard = (BASE / 'guard-fixture.pl').read_bytes()
    guard_needle = b"guard(!identity(\n    0),\n    \"$context interpolated message\");"
    if guard.count(guard_needle) != 1:
        raise ValueError('unique controlled nested argument')
    variants.update({'guard-fixture.pl': guard,
        'guard-expression-shift.pl': guard.replace(guard_needle, guard_needle.replace(b'\n    0)', b'\n\n    0)')),
        'guard-message-shift.pl': guard.replace(guard_needle, guard_needle.replace(b'\n    "$context', b'\n\n    "$context'))})
    results = []
    for name, body in variants.items():
        path = BASE / name
        if path.exists() and path.read_bytes() != body:
            raise ValueError('unchanged complete public fixture')
        if not path.exists():
            path.write_bytes(body)
        actual = []
        for command in (['perl', str(path)], ['perl', '-MO=Concise,-exec', str(path)]):
            run = subprocess.run(command, capture_output=True, text=True)
            if run.returncode != 0:
                raise ValueError('complete actual public caller/compiler result')
            actual.append({'command': command, 'status': run.returncode, 'stdout': run.stdout, 'stderr': run.stderr})
        results.append({'path': str(path), 'source': pin(body), 'actual': actual})
    product = {'owner': (BASE / 'scope.txt').read_text().strip(), 'fixtures': results,
        'role': 'Finite current public caller/compiler attribution only; original private runtime/toolchain meanings remain unmeasured.',
        'programme': pin(Path(__file__).read_bytes())}
    (BASE / 'public.json').write_text(json.dumps(product, sort_keys=True, indent=2) + '\n')
    print('PASS complete public attribution runtime/compiler results and source-only counterfactuals retained.')


if __name__ == '__main__':
    main()

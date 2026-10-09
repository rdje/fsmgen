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
    needle = b"}, qr/marker/,\n    'label');"
    if source.count(needle) != 1:
        raise ValueError('unique controlled first fixture call')
    variants = {'caller-fixture.pl': source,
                'caller-pattern-shift.pl': source.replace(needle, b"},\n    qr/marker/,\n    'label');"),
                'caller-label-shift.pl': source.replace(needle, b"}, qr/marker/,\n\n    'label');")}
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

"""Retain live-operand guard attribution and exact source counterfactuals."""
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/coordinate-original-mismatch-20261009')


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def main():
    if (BASE / 'guard-live.json').exists():
        raise ValueError('live-operand guard evidence never rewrites')
    source = (BASE / 'guard-live-fixture.pl').read_bytes()
    needle = b'    $source->{value}, $target->{value}),\n    "$context interpolated message");'
    if source.count(needle) != 1:
        raise ValueError('unique controlled live-operand guard')
    variants = {'guard-live-fixture.pl': source,
                'guard-live-operand-shift.pl': source.replace(needle, b'\n' + needle),
                'guard-live-message-shift.pl': source.replace(needle, needle.replace(b'\n    "$context', b'\n\n    "$context'))}
    results = []
    for name, body in variants.items():
        path = BASE / name
        if path.exists() and path.read_bytes() != body:
            raise ValueError('unchanged complete live guard fixture')
        if not path.exists():
            path.write_bytes(body)
        actual = []
        for command in (['perl', str(path)], ['perl', '-MO=Concise,-exec', str(path)]):
            run = subprocess.run(command, capture_output=True, text=True)
            if run.returncode != 0:
                raise ValueError('complete actual live guard result')
            actual.append({'command': command, 'status': run.returncode, 'stdout': run.stdout, 'stderr': run.stderr})
        results.append({'path': str(path), 'source': pin(body), 'actual': actual})
    (BASE / 'guard-live.json').write_text(json.dumps({'fixtures': results,
        'owner': (BASE / 'scope.txt').read_text().strip(), 'programme': pin(Path(__file__).read_bytes()),
        'role': 'Finite current public live-operand guard/compiler attribution only; no original private/toolchain promotion.'}, sort_keys=True, indent=2) + '\n')
    print('PASS complete live-operand public guard attribution and source counterfactuals retained.')


if __name__ == '__main__':
    main()

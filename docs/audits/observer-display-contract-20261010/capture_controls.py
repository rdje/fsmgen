"""Run genuine complete public corpora with one declared profile change each."""
import copy
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/observer-display-contract-20261010')


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def main():
    output = BASE / 'native-controls.json'
    assert not output.exists()
    source = json.loads((BASE / 'repaired-catalogue.json').read_bytes())
    variants = [('length', 'boundary-64-65', 'arg_len', 63),
                ('count', 'arity-8-9', 'arg_nums', 7),
                ('formatter', 'reference-plain-False', 'formatter', True)]
    results = {}
    for name, identifier, key, replacement in variants:
        variant = copy.deepcopy(source)
        row = next(c for c in variant['cases'] if c['id'] == identifier)
        row['profile'][key] = replacement
        catalogue = BASE / ('control-' + name + '-catalogue.json')
        assert not catalogue.exists()
        catalogue.write_text(json.dumps(variant, sort_keys=True, indent=2) + '\n')
        sources = [catalogue, BASE / 'repaired-catalogue.json', BASE / 'fixtures.pl', BASE / 'capture_controls.py']
        before = {str(p): pin(p.read_bytes()) for p in sources}
        command = ['perl', '-Iperl', str(BASE / 'fixtures.pl'), str(catalogue)]
        r = subprocess.run(command, capture_output=True)
        assert before == {str(p): pin(p.read_bytes()) for p in sources}
        results[name] = dict(case=identifier, changed_key=key, replacement=replacement,
                             command=command, status=r.returncode, stdout=r.stdout.decode(), stderr=r.stderr.decode(),
                             stdout_identity=pin(r.stdout), stderr_identity=pin(r.stderr), inputs=before)
    output.write_text(json.dumps(results, sort_keys=True, indent=2) + '\n')
    assert all(type(r['status']) is int and r['status'] == 0 and not r['stderr'] for r in results.values())
    print('PASS actual complete length/count/formatter profile variants captured with full sources and streams.')


if __name__ == '__main__':
    main()

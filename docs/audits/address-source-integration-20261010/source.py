"""Whole corrected source frontier and complete fixed-Git integration inputs."""
import contextlib
import hashlib
import io
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/address-source-integration-20261010')
PRIOR = Path('docs/audits/address-observer-holders-20261010')
REVISION = 'a4435e0a45e318e0fda0a829cad90af3f1df1cdd'
SUCCESS = 'PASS complete observer caller source membership; full graph/role integration and original native identity remain open.\n'
REGISTRY = {'operation': 'address-source-boundaries', 'private': 'address-private-topology',
            'value': 'address-value-core', 'metadata': 'address-metadata-core',
            'nested': 'address-nested-lifetimes', 'helper': 'address-helper-bindings',
            'entry': 'address-parser-entry', 'actor': 'address-actor-construction',
            'contexts': 'address-parser-contexts', 'parser': 'address-parser-context-closure',
            'holders': 'address-observer-holders'}


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def module(path):
    ns = {'__name__': 'source_integration_prerequisite'}
    exec(compile(path.read_bytes(), str(path), 'exec'), ns)
    return ns


def load(path):
    return json.loads(path.read_bytes())


def data(spec):
    return {name: {kind: load(Path(row[kind]['path'])) for kind in ('inputs', 'hypotheses')}
            for name, row in spec['models'].items()}


def rebuild():
    old_bytes, old_text, reads = Path.read_bytes, Path.read_text, {}
    def retain(path):
        relative = path.resolve().relative_to(Path.cwd())
        if not relative.is_relative_to(BASE):
            reads[str(relative)] = pin(old_bytes(path))
    def read_bytes(path):
        value = old_bytes(path); retain(path); return value
    def read_text(path, *args, **kwargs):
        value = old_text(path, *args, **kwargs); retain(path); return value
    try:
        Path.read_bytes, Path.read_text = read_bytes, read_text
        transcript = io.StringIO()
        with contextlib.redirect_stdout(transcript):
            module(PRIOR / 'verify.py')['main']()
        if transcript.getvalue() != SUCCESS:
            raise ValueError('complete corrected source frontier independent qualification')
        proof = load(PRIOR / 'proof.json')
        for name, identity in proof['programmes'].items():
            if pin((PRIOR / name).read_bytes()) != identity:
                raise ValueError('whole corrected source frontier programme custody')
        outcome = load(PRIOR / 'checks.json')['independent']
        if type(outcome['status']) is not int or outcome['status'] != 0 or outcome['stdout'] != SUCCESS:
            raise ValueError('actual source frontier independent result')
        models = {}
        for name, directory in REGISTRY.items():
            root = Path('docs/audits') / (directory + '-20261010')
            models[name] = {kind: {'path': str(root / (kind + '.json')),
                                  'identity': pin((root / (kind + '.json')).read_bytes())}
                            for kind in ('inputs', 'hypotheses')}
        spec = {'models': models,
                'source_contracts': ['perl/FSM/Support/ISFRecordPortValues.pm',
                    'docs/audits/record-value-original-candidate-20261004/observe.pl',
                    't/1986-isf-record-port-value-gates.t']}
        for path in spec['source_contracts']:
            Path(path).read_bytes()
    finally:
        Path.read_bytes, Path.read_text = old_bytes, old_text
    if any(path.endswith('/raw-product.json') for path in reads):
        raise ValueError('new original raw-address intake forbidden')
    for path, identity in reads.items():
        raw = subprocess.check_output(['git', 'show', REVISION + ':' + path])
        if pin(raw) != identity or old_bytes(Path(path)) != raw:
            raise ValueError('whole fixed Git source frontier input: ' + path)
    return spec, {'revision': REVISION, 'inputs': dict(sorted(reads.items())),
                  'fresh_corrected_frontier_stdout': transcript.getvalue()}


def main():
    spec, binding = rebuild()
    for name, value in (('inputs.json', spec), ('binding.json', binding)):
        path = BASE / name
        if path.exists():
            raise ValueError('retain first complete integration intake')
        path.write_text(json.dumps(value, sort_keys=True, indent=2) + '\n')
    print('PASS complete corrected source frontier and whole fixed-Git models; integration awaits independent qualification.')


if __name__ == '__main__':
    main()

"""Whole corrected context boundary, all original APIs and fixed-Git custody."""
import contextlib
import hashlib
import io
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/address-parser-context-closure-20261010')
BOUNDARY = Path('docs/audits/address-parser-contexts-20261010')
HELPER = Path('docs/audits/address-helper-bindings-20261010')
ORIGINAL = Path('docs/audits/record-value-original-candidate-20261004')
REVISION = 'e3bdc085a052daf323956a5200e5825dd724e66a'
SUCCESS = ('PASS complete fresh context construction and exact typed public observations; '
           'original context-slot closure and native flags remain open.\n')


def identity(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def load(path):
    return json.loads(path.read_bytes())


def same(left, right):
    return json.dumps(left, sort_keys=True) == json.dumps(right, sort_keys=True)


def module(path):
    namespace = {'__name__': 'original_context_closure_prerequisite'}
    exec(compile(path.read_bytes(), str(path), 'exec'), namespace)
    return namespace


def rebuild():
    original_bytes, original_text, reads = Path.read_bytes, Path.read_text, {}
    def retain(path):
        relative = path.resolve().relative_to(Path.cwd())
        if not relative.is_relative_to(BASE):
            reads[str(relative)] = identity(original_bytes(path))
    def read_bytes(path):
        result = original_bytes(path); retain(path); return result
    def read_text(path, *args, **kwargs):
        result = original_text(path, *args, **kwargs); retain(path); return result
    try:
        Path.read_bytes, Path.read_text = read_bytes, read_text
        transcript = io.StringIO()
        with contextlib.redirect_stdout(transcript):
            module(BOUNDARY / 'verify.py')['main']()
        if transcript.getvalue() != SUCCESS:
            raise ValueError('fresh complete context boundary qualification')
        proof = load(BOUNDARY / 'proof.json')
        for name, pin in proof['programmes'].items():
            if identity((BOUNDARY / name).read_bytes()) != pin:
                raise ValueError('whole corrected context boundary programme custody')
        outcome = load(BOUNDARY / 'checks.json')['independent']
        if type(outcome['status']) is not int or outcome['status'] != 0 or outcome['stdout'] != SUCCESS:
            raise ValueError('actual corrected boundary outcome')
        inputs, model = load(BOUNDARY / 'inputs.json'), load(BOUNDARY / 'hypotheses.json')
        helper_inputs, helper_model = load(HELPER / 'inputs.json'), load(HELPER / 'hypotheses.json')
        protocols = []
        for old in inputs['original_context_protocols']:
            captured = load(ORIGINAL / (old['mode'] + '.json'))
            selected = [{'index': i, **{key: row[key] for key in (
                'kind', 'caller', 'before', 'after', 'result', 'accepted', 'primary', 'warnings')}}
                for i, row in enumerate(captured['api']) if row['parse'] == 2]
            if [r['index'] for r in selected] != [r['index'] for r in old['retained_api_callers']]:
                raise ValueError('every original context API and retained caller exactly once')
            if any(type(r['accepted']) is not int or r['accepted'] != 1 or r['primary'] or r['warnings'] for r in selected):
                raise ValueError('whole successful original context API population')
            protocols.append({**old, 'all_apis': selected})
        result = {'boundary_inputs': inputs, 'boundary_model': model,
                  'helper_inputs': helper_inputs, 'helper_model': helper_model, 'protocols': protocols}
    finally:
        Path.read_bytes, Path.read_text = original_bytes, original_text
    if any(path.endswith('/raw-product.json') for path in reads):
        raise ValueError('new raw-address intake prohibited')
    for path, pin in reads.items():
        raw = subprocess.check_output(['git', 'show', REVISION + ':' + path])
        if identity(raw) != pin or original_bytes(Path(path)) != raw:
            raise ValueError('whole fixed Git original context closure input: ' + path)
    return result, {'revision': REVISION, 'inputs': dict(sorted(reads.items())),
        'fresh_corrected_boundary_stdout': transcript.getvalue(),
        'scope': 'Complete corrected context boundary and all original typed API/private protocols conserve. New joins qualify source semantics, not original native flags, payload or identity.'}


def main():
    inputs, binding = rebuild()
    for name, value in (('inputs.json', inputs), ('binding.json', binding)):
        target = BASE / name
        if target.exists():
            raise ValueError('retain each complete first original context intake')
        target.write_text(json.dumps(value, sort_keys=True, indent=2) + '\n')
    print('PASS whole corrected boundary and every original context API/private protocol conserved; full source joins await independent qualification.')


if __name__ == '__main__':
    main()

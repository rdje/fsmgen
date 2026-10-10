"""Complete dated direct Value source cohort and qualified copy/operation custody."""
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/address-value-core-20261010')
REVISION = '229c2410ac5416decf342bc06e03ee006231e9a7'


def identity(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def module(path):
    ns = {'__name__': 'value_core_source_prerequisite'}
    exec(compile(path.read_bytes(), str(path), 'exec'), ns)
    return ns


def rebuild():
    original_bytes, original_text, reads = Path.read_bytes, Path.read_text, {}
    def keep(path):
        relative = path.resolve().relative_to(Path.cwd())
        if not relative.is_relative_to(BASE):
            reads[str(relative)] = identity(original_bytes(path))
    def read_bytes(path):
        value = original_bytes(path)
        keep(path)
        return value
    def read_text(path, *args, **kwargs):
        value = original_text(path, *args, **kwargs)
        keep(path)
        return value
    try:
        Path.read_bytes, Path.read_text = read_bytes, read_text
        private_base = Path('docs/audits/address-private-topology-20261010')
        prior = module(private_base / 'source.py')
        private_inputs, private_binding = prior['rebuild']()
        private_hypotheses = module(private_base / 'model.py')['derive'](private_inputs)
        if private_hypotheses != json.loads((private_base / 'hypotheses.json').read_bytes()):
            raise ValueError('complete unchanged private-copy source hypotheses')
        proof = json.loads((private_base / 'proof.json').read_bytes())
        if proof['binding'] != private_binding:
            raise ValueError('whole completed private source custody')
        for name, pin in proof['programmes'].items():
            if identity((private_base / name).read_bytes()) != pin:
                raise ValueError('whole completed private source programme')
        outcome = json.loads((private_base / 'checks.json').read_bytes())['first-independent']
        if type(outcome['status']) is not int or outcome['status'] != 0 or not outcome['stdout'].endswith(
                'PASS complete private source topology, actual qualified joint detachment and independent separating controls; numeric and post-return identities remain open.\n'):
            raise ValueError('actual completed private independent outcome')
        operation_base = Path('docs/audits/address-source-boundaries-20261010')
        operations = json.loads((operation_base / 'inputs.json').read_bytes())
        operation_hypotheses = module(operation_base / 'model.py')['derive'](operations)
        if operation_hypotheses != json.loads((operation_base / 'hypotheses.json').read_bytes()):
            raise ValueError('complete unchanged operation-boundary source hypotheses')
        direct = module(Path('docs/audits/record-value-original-value-frames-20261005/verify.py'))
        sources = direct['source_contracts']()
        expected = direct['expected_models'](sources)
        if expected != json.loads((direct['BASE'] / 'proofs.json').read_bytes())['models']:
            raise ValueError('whole independently rederived original direct Value source path cohort')
        for statement in ('my %args = @_;', '$source = dclone($source) if ref($source) eq \'HASH\';',
                          '$target = dclone($target) if ref($target) eq \'HASH\';', '$root = dclone($root);'):
            if statement not in sources['value']:
                raise ValueError('whole original Value local clone/named-argument source contract')
        scopes = {r['index']: r for r in json.loads(Path('docs/audits/record-value-scopes-20261004/scope-products.json').read_bytes())['rows']}
        by_key = {(r['mode'], r['domain'], r['index']): r for r in operations}
        rows = []
        for mode in expected:
            for case in mode['cases']:
                op = by_key[mode['mode'], 'api', case['index']]
                private = [r for r in private_inputs if r['domain'][0] == mode['mode']
                           and r['api'] == case['index'] and r['kind'] == 'value-private']
                stages = [{key: stage[key] for key in ('copy_index', 'layer', 'name')}
                          for stage in scopes[case['index']]['stages']] if case['kind'] == 'scope' else []
                rows.append({'mode': mode['mode'], **case, 'arguments': op['source_input_graph'],
                             'private': private, 'scope_stages': stages})
        inputs = {'sources': sources, 'cases': rows,
                  'scope': 'Complete original direct Value refusal cohort, qualified source operation arguments and private copy allocations; no raw numeric-address input.'}
    finally:
        Path.read_bytes, Path.read_text = original_bytes, original_text
    if any(path.endswith('/raw-product.json') for path in reads):
        raise ValueError('raw-address input prohibited in direct source model')
    for path, pin in reads.items():
        raw = subprocess.check_output(['git', 'show', REVISION + ':' + path])
        if identity(raw) != pin or original_bytes(Path(path)) != raw:
            raise ValueError('whole fixed Git Value core source input: ' + path)
    return inputs, {'revision': REVISION, 'inputs': dict(sorted(reads.items())),
                    'scope': 'Whole source-only direct Value cohort and complete operation/private source prerequisites; original numeric addresses and native provider identities unmeasured.'}


def main():
    inputs, binding = rebuild()
    direct = module(Path('docs/audits/record-value-original-value-frames-20261005/verify.py'))
    hypotheses = module(BASE / 'model.py')['derive'](inputs, direct['frame_model'], direct['primary']['graph']['thaw'])
    for name, value in [('inputs.json', inputs), ('binding.json', binding), ('hypotheses.json', hypotheses)]:
        path = BASE / name
        if path.exists():
            raise ValueError('retain first complete Value core source product: ' + name)
        path.write_text(json.dumps(value, sort_keys=True, indent=2) + '\n')
    print('PASS complete direct Value core source referent and active-lifetime hypotheses retained before raw-address intake.')


if __name__ == '__main__':
    main()

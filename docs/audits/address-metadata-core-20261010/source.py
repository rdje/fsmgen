"""Complete dated Metadata source inputs and conserved prerequisite custody."""
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/address-metadata-core-20261010')
VALUE = Path('docs/audits/address-value-core-20261010')
PRIVATE = Path('docs/audits/address-private-topology-20261010')
METADATA = Path('docs/audits/record-value-original-metadata-frames-20261005')
NESTED = Path('docs/audits/record-value-original-nested-inputs-20261005')
REVISION = 'a0cd672c0db2ea843e13b7e87cf29d91f248edc3'


def identity(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def module(path):
    namespace = {'__name__': 'metadata_core_prerequisite'}
    exec(compile(path.read_bytes(), str(path), 'exec'), namespace)
    return namespace


def load(path):
    return json.loads(path.read_bytes())


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
        value_source = module(VALUE / 'source.py')
        value_inputs, value_binding = value_source['rebuild']()
        value_proof = load(VALUE / 'proof.json')
        if value_binding != value_proof['binding'] or value_inputs != load(VALUE / 'inputs.json'):
            raise ValueError('complete completed Value source custody and input cohort')
        direct = value_source['module'](Path('docs/audits/record-value-original-value-frames-20261005/verify.py'))
        value_hypotheses = module(VALUE / 'model.py')['derive'](
            value_inputs, direct['frame_model'], direct['primary']['graph']['thaw'])
        if value_hypotheses != load(VALUE / 'hypotheses.json'):
            raise ValueError('complete unchanged direct Value source hypotheses')
        for name, pin in value_proof['programmes'].items():
            if identity((VALUE / name).read_bytes()) != pin:
                raise ValueError('whole completed Value programme')
        outcome = load(VALUE / 'checks.json')['independent']
        if type(outcome['status']) is not int or outcome['status'] != 0 or outcome['stdout'] != (
                'PASS complete direct Value core source bindings, independent source-expression/closed-type oracle and separating controls; original numeric/native identity remains open.\n'):
            raise ValueError('actual completed Value independent qualification')
        private_inputs, private_binding = module(PRIVATE / 'source.py')['rebuild']()
        if private_inputs != load(PRIVATE / 'inputs.json') or private_binding != load(PRIVATE / 'binding.json'):
            raise ValueError('complete unchanged private graph source inputs and custody')
        metadata = module(METADATA / 'verify.py')
        sources = metadata['source_contracts']()
        cases = metadata['expected_models'](sources)
        if cases != load(METADATA / 'proofs.json')['models']:
            raise ValueError('complete independently rederived Metadata source cases')
        nested = module(NESTED / 'verify.py')
        nested_sources = nested['sources']()
        pairs = nested['expected_models'](nested_sources)
        if pairs != load(NESTED / 'proofs.json')['models']:
            raise ValueError('complete independently rederived nested source input pairs')
        for statement in ('my ($interface, $default_domain) = @_;', '$interface = dclone($interface);',
                          'my @paths;', "_collect_scalar_paths($spec, '', \\@paths, {});",
                          'local $active->{$address} = 1;'):
            if statement not in sources['metadata']:
                raise ValueError('whole Metadata source clone/shared-local contract')
        rows = []
        for mode, paired in zip(cases, pairs, strict=True):
            if mode['mode'] != paired['mode']:
                raise ValueError('whole Metadata source mode allocation')
            by_index = {case['index']: case for case in mode['cases']}
            if {i for pair in paired['pairs'] for i in (pair['scope_api'], pair['capture_api'])} != set(by_index):
                raise ValueError('complete Metadata live-capture and embedded-outer partition')
            for pair in paired['pairs']:
                capture, outer = by_index[pair['capture_api']], by_index[pair['scope_api']]
                if (capture['kind'] != 'capture' or outer['kind'] != 'scope'
                        or capture['frames'] != outer['frames'] or capture['guard'] != pair['guard']):
                    raise ValueError('whole Metadata source pair frame/phase allocation')
                copies = [row for row in private_inputs if row['domain'][0] == mode['mode']
                          and row['api'] == pair['capture_api'] and row['kind'] == 'metadata-private']
                if len(copies) != 1:
                    raise ValueError('one complete Metadata interface clone per finite failing capture')
                rows.append({'mode': mode['mode'], 'capture': capture, 'outer': outer,
                             'pair': pair, 'private': copies[0]})
        inputs = {'sources': sources, 'nested_sources': nested_sources, 'cases': rows,
                  'scope': 'Complete finite Metadata source cases and nested input pairs; actual inner captures only, caught outer trace frames explicitly inactive. Numeric/provider identity and cross-operation Value joins remain open.'}
    finally:
        Path.read_bytes, Path.read_text = original_bytes, original_text
    if any(path.endswith('/raw-product.json') for path in reads):
        raise ValueError('new raw-address intake prohibited in Metadata source model')
    for path, pin in reads.items():
        raw = subprocess.check_output(['git', 'show', REVISION + ':' + path])
        if identity(raw) != pin or original_bytes(Path(path)) != raw:
            raise ValueError('whole fixed Git Metadata source input: ' + path)
    return inputs, {'revision': REVISION, 'inputs': dict(sorted(reads.items())),
                    'scope': 'Complete source-only Metadata inputs, all prior Value/operation/private hypotheses and whole fixed Git prerequisite custody; no numeric/provider identity inference.'}


def main():
    inputs, custody = rebuild()
    factory = module(METADATA / 'frame_model.py')
    thaw = module(VALUE / 'source.py')['module'](
        Path('docs/audits/record-value-original-value-frames-20261005/verify.py'))['primary']['graph']['thaw']
    hypotheses = module(BASE / 'model.py')['derive'](inputs, factory, thaw)
    for name, value in [('inputs.json', inputs), ('binding.json', custody), ('hypotheses.json', hypotheses)]:
        target = BASE / name
        if target.exists():
            raise ValueError('retain first complete Metadata source product: ' + name)
        target.write_text(json.dumps(value, sort_keys=True, indent=2) + '\n')
    print('PASS complete Metadata core source referents and shared recursion-local hypotheses; numeric and nested Value joins remain open.')


if __name__ == '__main__':
    main()

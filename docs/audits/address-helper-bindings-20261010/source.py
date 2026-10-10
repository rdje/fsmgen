"""Whole helper/subtest source intake, conserving fresh complete predecessors."""
import contextlib
import hashlib
import io
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/address-helper-bindings-20261010')
NESTED = Path('docs/audits/address-nested-lifetimes-20261010')
HELPER = Path('docs/audits/record-value-original-helper-join-20261005')
SUBTEST = Path('docs/audits/record-value-own-subtest-boundaries-20261005')
OPERATION = Path('docs/audits/address-source-boundaries-20261010')
REVISION = 'aa6f6881262a49e6c01746e97cb4fdd9b9a540e7'
SUCCESS = ('PASS complete nested source aliases, all throw views, retained snapshots '
           'and resolved operation roles; numeric/native identities remain open.\n')


def identity(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def module(path):
    namespace = {'__name__': 'helper_source_prerequisite'}
    exec(compile(path.read_bytes(), str(path), 'exec'), namespace)
    return namespace


def load(path):
    return json.loads(path.read_bytes())


def same(left, right):
    return json.dumps(left, sort_keys=True) == json.dumps(right, sort_keys=True)


def rebuild():
    original_bytes, original_text, reads = Path.read_bytes, Path.read_text, {}
    def retain(path):
        relative = path.resolve().relative_to(Path.cwd())
        if not relative.is_relative_to(BASE):
            reads[str(relative)] = identity(original_bytes(path))
    def read_bytes(path):
        result = original_bytes(path)
        retain(path)
        return result
    def read_text(path, *args, **kwargs):
        result = original_text(path, *args, **kwargs)
        retain(path)
        return result
    try:
        Path.read_bytes, Path.read_text = read_bytes, read_text
        transcript = io.StringIO()
        with contextlib.redirect_stdout(transcript):
            module(NESTED / 'verify.py')['main']()
        if transcript.getvalue() != SUCCESS:
            raise ValueError('fresh complete nested/core/private/operation qualification')
        proof = load(NESTED / 'proof.json')
        for name, pin in proof['programmes'].items():
            if identity((NESTED / name).read_bytes()) != pin:
                raise ValueError('whole completed nested qualification programme')
        outcome = load(NESTED / 'checks.json')['independent']
        if type(outcome['status']) is not int or outcome['status'] != 0 or outcome['stdout'] != SUCCESS:
            raise ValueError('actual completed corrected nested qualification outcome')
        helper, subtest = module(HELPER / 'verify.py'), module(SUBTEST / 'verify.py')
        source = helper['prior']['sources']()
        helper_models = helper['expected_models'](source)
        subtest_models = subtest['expected_models'](source)
        if not same(helper_models, load(HELPER / 'proofs.json')['models']):
            raise ValueError('whole qualified helper source recipes and throw paths')
        if not same(subtest_models, load(SUBTEST / 'proofs.json')['models']):
            raise ValueError('whole qualified own subtest source bodies and boundaries')
        contracts = {
            'helper_caller_holder': 'push @helpers, {label => $label, pattern => "$pattern", caller => [caller],',
            'helper_forwarding': 'my $returned = $helper->(@_);',
            'helper_callback': 'my $ok = eval { $run->(); 1 };',
            'wrapped_public_callback': 'return $subtest->($name, sub {',
            'authored_body_forwarding': 'return $body->(@_);',
            'scalar_source': "my $scalar = {kind => 'bits', width => 7, signed => 0};",
        }
        for key, statement in contracts.items():
            body = source['test'] if key in ('helper_callback', 'scalar_source') else source['observer']
            if body.count(statement) != 1:
                raise ValueError('whole helper retained/forwarded/construction source: ' + key)
        nested = load(NESTED / 'hypotheses.json')
        inputs = {'source': source, 'contracts': contracts, 'helper_modes': helper_models,
                  'subtests': subtest_models, 'operation_inputs': load(OPERATION / 'inputs.json'),
                  'nested_pairs': [{key: row[key] for key in ('mode', 'scope_api', 'capture_api')}
                                   for row in nested['cases']]}
    finally:
        Path.read_bytes, Path.read_text = original_bytes, original_text
    if any(path.endswith('/raw-product.json') for path in reads):
        raise ValueError('numeric-address intake forbidden in helper source qualification')
    for path, pin in reads.items():
        raw = subprocess.check_output(['git', 'show', REVISION + ':' + path])
        if identity(raw) != pin or original_bytes(Path(path)) != raw:
            raise ValueError('whole fixed Git helper source input: ' + path)
    return inputs, {'revision': REVISION, 'inputs': dict(sorted(reads.items())),
                    'fresh_nested_reader_stdout': transcript.getvalue(),
                    'scope': 'Whole fixed Git source and complete fresh prior source qualification; no numeric address operands interpreted.'}


def main():
    inputs, custody = rebuild()
    thaw = module(Path('docs/audits/record-value-original-value-frames-20261005/verify.py'))['primary']['graph']['thaw']
    encode = module(NESTED / 'model.py')['encode']
    hypotheses = module(BASE / 'model.py')['derive'](inputs, thaw, encode)
    for name, result in (('inputs.json', inputs), ('binding.json', custody), ('hypotheses.json', hypotheses)):
        target = BASE / name
        if target.exists():
            raise ValueError('retain first complete helper source product: ' + name)
        target.write_text(json.dumps(result, sort_keys=True, indent=2) + '\n')
    print('PASS complete helper/callback/subtest source hypotheses; native and parser identities remain open.')


if __name__ == '__main__':
    main()

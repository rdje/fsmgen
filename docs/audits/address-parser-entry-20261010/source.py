"""Complete original parser-entry source intake and fresh public normalization."""
import base64
import contextlib
import hashlib
import io
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/address-parser-entry-20261010')
HELPER = Path('docs/audits/address-helper-bindings-20261010')
PATHS = Path('docs/audits/record-value-parser-path-models-20261006')
ARGUMENT = Path('docs/audits/record-value-parser-argument-roles-20261006')
REVISION = '551b659fb9196ae8bf5dceca599114624f9a63e2'
SUCCESS = ('PASS complete helper/callback/subtest source bindings, retained holders '
           'and genuine controls; native/parser identities remain open.\n')


def identity(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def module(path):
    namespace = {'__name__': 'parser_entry_prerequisite'}
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
            module(HELPER / 'verify.py')['main']()
        if transcript.getvalue() != SUCCESS:
            raise ValueError('fresh complete helper/nested/core/private/operation qualification')
        proof = load(HELPER / 'proof.json')
        for name, pin in proof['programmes'].items():
            if identity((HELPER / name).read_bytes()) != pin:
                raise ValueError('whole completed helper qualification programme')
        outcome = load(HELPER / 'checks.json')['independent']
        if type(outcome['status']) is not int or outcome['status'] != 0 or outcome['stdout'] != SUCCESS:
            raise ValueError('actual complete corrected helper qualification outcome')
        path_reader = module(PATHS / 'verify.py')
        inventory, authored, _ = path_reader['inputs']()
        paths = path_reader['model']['derive'](inventory, authored, path_reader['require'], path_reader['identity'])
        old = load(PATHS / 'proofs.json')
        if not same(paths, old['paths']) or not same(path_reader['guard_truth'](inventory), old['guard_truth']):
            raise ValueError('whole original parser source paths and fresh original guard truth')
        arguments = module(ARGUMENT / 'verify.py')['models']()
        if not same(arguments, load(ARGUMENT / 'proofs.json')['models']):
            raise ValueError('whole original parser source argument roles')
        units = {'facade': 'perl/FSM/Adapter/ISF.pm', 'parser': 'perl/FSM/Adapter/ISF/Parser.pm',
                 'contexts': 'perl/FSM/Support/ISFRecordPortContexts.pm'}
        for unit, path in units.items():
            if Path(path).read_bytes() != inventory['source_units'][unit]['body'].encode():
                raise ValueError('original own parser source epoch: ' + unit)
        normalizer_path = 'perl/FSM/Adapter/ISF/LispishAdapter.pm'
        original = load(Path('docs/audits/record-value-original-candidate-20261004/binding.json'))
        pin = original['runtime'][normalizer_path]
        normalizer = base64.b64decode(pin['body_b64'], validate=True)
        if identity(normalizer) != {key: pin[key] for key in ('bytes', 'sha256')} or Path(normalizer_path).read_bytes() != normalizer:
            raise ValueError('whole original own normalizer source epoch')
        source = inventory['source_units']['parser']['body']
        start = source.index('sub _forms_by_head(')
        end = source.index('\n}\n', start) + 3
        selector = source[start:end]
        test = load(HELPER / 'inputs.json')['source']['test']
        if test.count('my $parser = FSM::Adapter::ISF->new;') != 1:
            raise ValueError('single original source facade construction')
        command = ['perl', '-Iperl', str(BASE / 'public_normalization.pl')]
        result = subprocess.run(command, input=json.dumps(authored), capture_output=True, text=True)
        if type(result.returncode) is not int or result.returncode != 0 or result.stderr:
            raise ValueError('actual fresh public constructor/normalization outcome: ' + result.stderr)
        public = json.loads(result.stdout)
        operations = load(Path('docs/audits/address-source-boundaries-20261010/inputs.json'))
        hypotheses = load(Path('docs/audits/address-source-boundaries-20261010/hypotheses.json'))
        inputs = {'inventory': inventory, 'authored': authored, 'paths': paths, 'arguments': arguments,
                  'normalizer': normalizer.decode(), 'selector': selector, 'public': public,
                  'operation_inputs': [row for row in operations if row['domain'] == 'parses'],
                  'operation_hypotheses': [row for row in hypotheses['cases'] if row['domain'] == 'parses']}
        replay = {'command': command, 'status': result.returncode, 'stdout': result.stdout, 'stderr': result.stderr,
                  'programme': identity((BASE / 'public_normalization.pl').read_bytes()),
                  'scope': 'Fresh public source-boundary replay, not original native receiver/AST capture or Lispish implementation reconstruction.'}
    finally:
        Path.read_bytes, Path.read_text = original_bytes, original_text
    if any(path.endswith('/raw-product.json') for path in reads):
        raise ValueError('new original numeric address intake prohibited')
    for path, pin in reads.items():
        raw = subprocess.check_output(['git', 'show', REVISION + ':' + path])
        if identity(raw) != pin or original_bytes(Path(path)) != raw:
            raise ValueError('whole fixed Git parser entry source input: ' + path)
    return inputs, {'revision': REVISION, 'inputs': dict(sorted(reads.items())),
                    'fresh_helper_reader_stdout': transcript.getvalue(), 'public_replay': replay,
                    'scope': 'Whole original own source epochs, complete fresh prior source qualification and public boundary; original receiver/AST heap contents and native identity remain unmeasured.'}


def main():
    inputs, custody = rebuild()
    for name, value in (('inputs.json', inputs), ('binding.json', custody)):
        target = BASE / name
        if target.exists():
            raise ValueError('retain first complete parser entry source product: ' + name)
        target.write_text(json.dumps(value, sort_keys=True, indent=2) + '\n')
    print('PASS complete original parser entry source intake and fresh public normalization; original native payload remains open.')


if __name__ == '__main__':
    main()

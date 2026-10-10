"""Whole corrected entry qualification, source epochs and own construction replay."""
import base64
import contextlib
import hashlib
import io
import json
import re
import subprocess
from pathlib import Path

BASE = Path('docs/audits/address-actor-construction-20261010')
ENTRY = Path('docs/audits/address-parser-entry-20261010')
REVISION = '993b9bf4a2e6d7f50380fc9c8922ec8dff345109'
SUCCESS = ('PASS complete parser-entry receiver/delegate/caller source bindings and independent '
           'normalization graphs; partial actor/context and native identity remain open.\n')


def identity(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def load(path):
    return json.loads(path.read_bytes())


def same(left, right):
    return json.dumps(left, sort_keys=True) == json.dumps(right, sort_keys=True)


def module(path):
    namespace = {'__name__': 'actor_construction_prerequisite'}
    exec(compile(path.read_bytes(), str(path), 'exec'), namespace)
    return namespace


def function(body, name):
    match = re.search(r'^sub ' + re.escape(name) + r'\b', body, re.M)
    if not match:
        raise ValueError('complete original own function: ' + name)
    return body[match.start():body.index('\n}\n', match.start()) + 3]


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
            module(ENTRY / 'verify.py')['main']()
        if transcript.getvalue() != SUCCESS:
            raise ValueError('fresh whole corrected parser entry qualification')
        proof = load(ENTRY / 'proof.json')
        for name, pin in proof['programmes'].items():
            if identity((ENTRY / name).read_bytes()) != pin:
                raise ValueError('complete corrected entry programme custody')
        outcome = load(ENTRY / 'checks.json')['guarded-retry-independent']
        if type(outcome['status']) is not int or outcome['status'] != 0 or outcome['stdout'] != SUCCESS:
            raise ValueError('actual final corrected entry outcome')
        entry_inputs, entry_model = load(ENTRY / 'inputs.json'), load(ENTRY / 'hypotheses.json')
        parser_source = entry_inputs['inventory']['source_units']['parser']['body']
        build = function(parser_source, '_build_actor')
        start, end = build.index('    # ISF-COND:'), build.index('    validate_actor_record_contexts(')
        passes = re.findall(r'\$self->(_\w+)\(\$result', build[start:end])
        passes.remove('_finalize_actor_watchdog_limit') # Both original sources omit watchdog.
        if len(passes) != len(set(passes)):
            raise ValueError('complete distinct original reached pass order')
        command = ['perl', '-Iperl', str(BASE / 'public_construction.pl')]
        request = {'sources': entry_inputs['authored'], 'passes': passes}
        result = subprocess.run(command, input=json.dumps(request), capture_output=True, text=True)
        if result.returncode != 0 or result.stderr:
            raise ValueError('actual complete own construction probe outcome: ' + result.stderr)
        public = json.loads(result.stdout)
        original = load(Path('docs/audits/record-value-original-candidate-20261004/binding.json'))
        epochs = {}
        for path in public['own_loaded_modules']:
            if not path.startswith('perl/FSM/') or path not in original['runtime']:
                raise ValueError('original own public construction dependency epoch: ' + path)
            row = original['runtime'][path]
            raw = base64.b64decode(row['body_b64'], validate=True)
            if identity(raw) != {key: row[key] for key in ('bytes', 'sha256')} or Path(path).read_bytes() != raw:
                raise ValueError('whole original own dependency source epoch: ' + path)
            epochs[path] = identity(raw)
        inputs = {'entry_inputs': entry_inputs, 'entry_model': entry_model, 'passes': passes,
                  'parser_source': parser_source, 'public': public, 'own_source_epochs': epochs}
        replay = {'command': command, 'status': result.returncode, 'stdout': result.stdout, 'stderr': result.stderr,
                  'programme': identity((BASE / 'public_construction.pl').read_bytes()),
                  'scope': 'Fresh own-source instrumentation and primary-line-only refusal boundary, not original heap/stack capture or provider reconstruction.'}
    finally:
        Path.read_bytes, Path.read_text = original_bytes, original_text
    if any(path.endswith('/raw-product.json') for path in reads):
        raise ValueError('new original numeric address intake prohibited')
    for path, pin in reads.items():
        raw = subprocess.check_output(['git', 'show', REVISION + ':' + path])
        if identity(raw) != pin or original_bytes(Path(path)) != raw:
            raise ValueError('whole fixed Git actor construction input: ' + path)
    return inputs, {'revision': REVISION, 'inputs': dict(sorted(reads.items())),
                    'fresh_corrected_entry_stdout': transcript.getvalue(), 'public_replay': replay,
                    'scope': 'Complete prior source models and original own epochs conserve; construction is a fresh source hypothesis, not original native payload or flags.'}


def main():
    inputs, custody = rebuild()
    for name, value in (('inputs.json', inputs), ('binding.json', custody)):
        target = BASE / name
        if target.exists():
            raise ValueError('retain first complete actor construction product: ' + name)
        target.write_text(json.dumps(value, sort_keys=True, indent=2) + '\n')
    print('PASS complete corrected entry/source epoch intake and fresh own actor construction; independent actor/context qualification remains open.')


if __name__ == '__main__':
    main()

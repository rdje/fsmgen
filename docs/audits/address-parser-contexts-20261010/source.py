"""Whole corrected construction custody, original private protocols and contexts."""
import contextlib
import hashlib
import io
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/address-parser-contexts-20261010')
ACTOR = Path('docs/audits/address-actor-construction-20261010')
PRIVATE = Path('docs/audits/address-private-topology-20261010')
ORIGINAL = Path('docs/audits/record-value-original-candidate-20261004')
REVISION = 'e2a32e625b11a643bdb454ff6a5984b1f9b0ae76'
SUCCESS = ('PASS complete partial actor construction, independent reached-pass graphs and original '
           'source bindings; local contexts and native identity remain open.\n')


def identity(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def load(path):
    return json.loads(path.read_bytes())


def same(left, right):
    return json.dumps(left, sort_keys=True) == json.dumps(right, sort_keys=True)


def module(path):
    namespace = {'__name__': 'parser_context_prerequisite'}
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
            module(ACTOR / 'verify.py')['main']()
        if transcript.getvalue() != SUCCESS:
            raise ValueError('fresh complete corrected construction qualification')
        proof = load(ACTOR / 'proof.json')
        for name, pin in proof['programmes'].items():
            if identity((ACTOR / name).read_bytes()) != pin:
                raise ValueError('whole corrected construction programme custody')
        outcome = load(ACTOR / 'checks.json')['final-independent']
        if type(outcome['status']) is not int or outcome['status'] != 0 or outcome['stdout'] != SUCCESS:
            raise ValueError('actual final corrected construction outcome')
        actor_inputs, actor_model = load(ACTOR / 'inputs.json'), load(ACTOR / 'hypotheses.json')
        own_sources = {}
        for path, pin in actor_inputs['own_source_epochs'].items():
            raw = Path(path).read_bytes()
            if identity(raw) != pin:
                raise ValueError('whole original own context dependency epoch: ' + path)
        for path in ('perl/FSM/Support/ISFRecordPortContexts.pm', 'perl/FSM/Support/ISFRecordPortScopes.pm',
                     'perl/FSM/Support/ISFRecordPortSamples.pm', 'perl/FSM/Support/ISFRecordPortValues.pm',
                     'perl/FSM/Support/ISFInterfacePortMetadata.pm', 'perl/FSM/Package/AggregatePathSupport.pm'):
            own_sources[path] = Path(path).read_text()
        private = {(row['domain'][0], row['domain'][1]): row for row in load(PRIVATE / 'inputs.json')}
        protocols = []
        for mode in actor_model['modes']:
            name = mode['mode']
            captured = load(ORIGINAL / (name + '.json'))
            source_apis = [(i, row) for i, row in enumerate(captured['api']) if row['parse'] == 2]
            source_copies = [(i, row) for i, row in enumerate(captured['copies']) if row['parse'] == 2]
            if any(type(row['accepted']) is not int or row['accepted'] != 1 for _, row in source_apis + source_copies):
                raise ValueError('complete successful original context protocol boundary')
            if captured['parses'][3]['api_start'] != captured['parses'][3]['api_end']:
                raise ValueError('list refusal precedes record context operations')
            selected = [{'index': i, **{key: row[key] for key in
                ('kind', 'caller', 'before', 'after', 'result', 'accepted', 'primary')}}
                for i, row in source_apis if row['kind'] in ('scope', 'reference')]
            copies = []
            for i, row in source_copies:
                qualified = private[name, i]
                if not same(qualified['qualified_original_joint'], row['joint_input_result']):
                    raise ValueError('whole original qualified context private joint graph')
                copies.append({'index': i, 'kind': row['kind'], 'caller': row['caller'], 'qualified': qualified})
            protocols.append({'mode': name, 'parse_index': 2, 'selected_apis': selected, 'copies': copies,
                'retained_api_callers': [{'index': i, 'kind': row['kind'], 'caller': row['caller']} for i, row in source_apis],
                'retained_private_callers': [{'index': i, 'kind': row['kind'], 'caller': row['caller']} for i, row in source_copies],
                'scope': 'Previously qualified original source graphs and successful context protocol caller allocations only; no new numeric address/stack interpretation.'})
        command = ['perl', '-Iperl', str(BASE / 'public_contexts.pl')]
        result = subprocess.run(command, input=json.dumps({'source': actor_inputs['entry_inputs']['authored'][0]}),
                                capture_output=True, text=True)
        if result.returncode != 0 or result.stderr:
            raise ValueError('actual whole context construction probe: ' + result.stderr)
        public = json.loads(result.stdout)
        inputs = {'construction_inputs': actor_inputs, 'construction_model': actor_model,
                  'own_sources': own_sources, 'original_context_protocols': protocols, 'public': public}
        replay = {'command': command, 'status': result.returncode, 'stdout': result.stdout, 'stderr': result.stderr,
                  'programme': identity((BASE / 'public_contexts.pl').read_bytes()),
                  'scope': 'Fresh public facade and own source instrumentation; imported provider is called only through its published API.'}
    finally:
        Path.read_bytes, Path.read_text = original_bytes, original_text
    if any(path.endswith('/raw-product.json') for path in reads):
        raise ValueError('new raw-address intake prohibited')
    for path, pin in reads.items():
        raw = subprocess.check_output(['git', 'show', REVISION + ':' + path])
        if identity(raw) != pin or original_bytes(Path(path)) != raw:
            raise ValueError('whole fixed Git parser context input: ' + path)
    return inputs, {'revision': REVISION, 'inputs': dict(sorted(reads.items())),
                    'fresh_corrected_construction_stdout': transcript.getvalue(), 'public_replay': replay,
                    'scope': 'Complete prior source qualification and original private protocols conserve. Context graphs are fresh source hypotheses, not original native payload/flags/identity or a global object census.'}


def main():
    inputs, custody = rebuild()
    for name, value in (('inputs.json', inputs), ('binding.json', custody)):
        target = BASE / name
        if target.exists():
            raise ValueError('retain first complete parser context product: ' + name)
        target.write_text(json.dumps(value, sort_keys=True, indent=2) + '\n')
    print('PASS complete corrected construction and original private context protocols; fresh context graphs await independent qualification.')


if __name__ == '__main__':
    main()

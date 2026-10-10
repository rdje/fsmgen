"""Complete prerequisite qualification, original headers and fixed Git custody."""
import contextlib
import hashlib
import io
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/address-observer-holders-20261010')
PRIOR = Path('docs/audits/address-parser-context-closure-20261010')
ORIGINAL = Path('docs/audits/record-value-original-candidate-20261004')
REVISION = 'db3712f8a8f01219b256f07741afcfdfc83bdb2b'
TABLES = ('api', 'copies', 'helpers', 'parses', 'consumers')
FIELDS = ('kind', 'caller', 'helper', 'parse', 'api', 'api_start', 'api_end',
          'parse_start', 'parse_end', 'consumer_start', 'consumer_end', 'accepted')
SUCCESS = ('PASS complete original parser/context and helper source closure; '
           'full source integration and original native identity remain open.\n')


def identity(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def module(path):
    namespace = {'__name__': 'observer_holder_prerequisite'}
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
        raw = original_bytes(path); retain(path); return raw
    def read_text(path, *args, **kwargs):
        value = original_text(path, *args, **kwargs); retain(path); return value
    try:
        Path.read_bytes, Path.read_text = read_bytes, read_text
        transcript = io.StringIO()
        with contextlib.redirect_stdout(transcript):
            module(PRIOR / 'verify.py')['main']()
        if transcript.getvalue() != SUCCESS:
            raise ValueError('complete corrected predecessor qualification')
        prior_proof = load(PRIOR / 'proof.json')
        for name, pin in prior_proof['programmes'].items():
            if identity((PRIOR / name).read_bytes()) != pin:
                raise ValueError('complete predecessor programme custody')
        outcome = load(PRIOR / 'checks.json')['final-independent']
        if type(outcome['status']) is not int or outcome['status'] != 0 or outcome['stdout'] != SUCCESS:
            raise ValueError('actual corrected predecessor independent outcome')
        helper = load(Path('docs/audits/address-helper-bindings-20261010/hypotheses.json'))
        modes = []
        for mode in ('ordinary', 'storable', 'controls'):
            original = load(ORIGINAL / (mode + '.json'))
            headers = {table: [{key: row[key] for key in FIELDS if key in row}
                               for row in original[table]] for table in TABLES}
            views = [view for group in next(m for m in helper['modes'] if m['mode'] == mode)['cases']
                     for view in group['views']]
            modes.append({'mode': mode, 'headers': headers,
                          'views': [{'domain': view['domain'], 'event': view['event']}
                                    for view in views]})
        conserved = {}
        for directory in ('address-source-boundaries', 'address-private-topology', 'address-value-core',
                          'address-metadata-core', 'address-nested-lifetimes', 'address-helper-bindings',
                          'address-parser-entry', 'address-actor-construction', 'address-parser-contexts',
                          'address-parser-context-closure'):
            path = Path('docs/audits') / (directory + '-20261010') / 'hypotheses.json'
            conserved[str(path)] = identity(path.read_bytes())
        result = {'modes': modes, 'conserved_models': conserved,
                  'observer_source': (ORIGINAL / 'observe.pl').read_text(),
                  'test_source': Path('t/1986-isf-record-port-value-gates.t').read_text()}
    finally:
        Path.read_bytes, Path.read_text = original_bytes, original_text
    if any(path.endswith('/raw-product.json') for path in reads):
        raise ValueError('new original raw-address intake forbidden')
    for path, pin in reads.items():
        raw = subprocess.check_output(['git', 'show', REVISION + ':' + path])
        if identity(raw) != pin or original_bytes(Path(path)) != raw:
            raise ValueError('whole fixed Git prerequisite/source bytes: ' + path)
    return result, {'revision': REVISION, 'inputs': dict(sorted(reads.items())),
                    'fresh_predecessor_stdout': transcript.getvalue()}


def main():
    inputs, binding = rebuild()
    for name, value in (('inputs.json', inputs), ('binding.json', binding)):
        path = BASE / name
        if path.exists():
            raise ValueError('retain first complete source intake')
        path.write_text(json.dumps(value, sort_keys=True, indent=2) + '\n')
    print('PASS complete corrected source models and original caller headers conserved; holder prefixes await independent qualification.')


if __name__ == '__main__':
    main()

"""Rebuild the finite source inputs; record every inherited file read unchanged."""
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/address-source-boundaries-20261010')
REVISION = '143f60cc08894ae9fed164140aa918ee0bdec8f0'


def identity(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def module(path):
    namespace = {'__name__': 'address_source_prerequisite'}
    exec(compile(path.read_bytes(), str(path), 'exec'), namespace)
    return namespace


def rebuild():
    read_bytes, read_text, reads = Path.read_bytes, Path.read_text, {}
    def remember(path, value):
        relative = path.resolve().relative_to(Path.cwd())
        if not relative.is_relative_to(BASE):
            reads[str(relative)] = identity(value)
    def bytes_read(path):
        value = read_bytes(path); remember(path, value); return value
    def text_read(path, *args, **kwargs):
        value = read_text(path, *args, **kwargs)
        remember(path, read_bytes(path)); return value
    try:
        Path.read_bytes, Path.read_text = bytes_read, text_read
        joint = module(Path('docs/audits/record-value-class-frame-join-20261006/verify.py'))
        contracts = joint['source_models']()
        named = module(Path('docs/audits/record-value-original-named-helpers-20261005/verify.py'))
        primary = named['primary']
        _, _, _, products = primary['context']['source_models']()
        interventions, _, _ = primary['graph']['source_interventions']()
        observer = Path('docs/audits/record-value-original-candidate-20261004/observe.pl').read_text()
        frame = named['prior']['frame_model']
        for statement in (frame['PARAMETERS'], frame['API_EVAL'], frame['PARSER_EVAL'], frame['PARSER_INPUTS']):
            if statement not in observer:
                raise ValueError('whole original observer lifetime/call contract')
        for kind, (_, lookup) in frame['API_WRAPPERS'].items():
            if "return call_api('" + kind + "', " + lookup + ', [caller], @_);' not in observer:
                raise ValueError('fresh caller and whole supplied argument forwarding')
        rows = []
        for mode in contracts['modes']:
            for case in mode['cases']:
                index = case['index']; parser = case['domain'] == 'parses'
                if not parser and mode['mode'] != 'storable' and index in interventions:
                    encoded = module(BASE / 'model.py')['graph'](interventions[index])
                    authority = 'independently authored source intervention'
                else:
                    product = products['actors' if parser else 'apis'][index]
                    encoded = product['whole_native']['before']
                    authority = 'complete previously source-qualified original typed input graph'
                rows.append({'mode': mode['mode'], 'domain': case['domain'], 'index': index, 'kind': case['kind'],
                             'source_input_graph': encoded, 'input_authority': authority,
                             'phases': [{'phase': phase['phase'], 'operations': phase['own']['operations']}
                                        for phase in case['phases']]})
    finally:
        Path.read_bytes, Path.read_text = read_bytes, read_text
    if any(path.endswith('/raw-product.json') for path in reads):
        raise ValueError('raw-address intake prohibited in source hypothesis derivation')
    for path, pin in reads.items():
        raw = subprocess.check_output(['git', 'show', REVISION + ':' + path])
        if identity(raw) != pin or read_bytes(Path(path)) != raw:
            raise ValueError('whole fixed Git source input custody: ' + path)
    return rows, {'revision': REVISION, 'inputs': dict(sorted(reads.items())),
                  'observer_source': identity(observer.encode()),
                  'scope': 'Read-only source model and previously independently qualified graph authority; no raw-address intake.'}


def main():
    rows, custody = rebuild()
    wanted = module(BASE / 'model.py')['derive'](rows)
    for name, value in [('inputs.json', rows), ('binding.json', custody), ('hypotheses.json', wanted)]:
        path = BASE / name
        if path.exists():
            raise ValueError('retain first produced source inputs; never overwrite ' + str(path))
        path.write_text(json.dumps(value, sort_keys=True, indent=2) + '\n')
    print('PASS complete source operation-boundary hypotheses retained before raw-address intake.')


if __name__ == '__main__':
    main()

"""Join complete qualified prerequisites into a finite parent acceptance witness."""
import hashlib
import json
import runpy
from pathlib import Path

BASE = Path('docs/audits/address-parent-acceptance-20261010')
SCOPE = ('Complete unchanged finite raw-address and numerical/source parent acceptance. Whole original bodies, '
         'lossless operands, source/class/frame/coordinate prerequisites, corrected holders and simultaneous '
         'source-number relations conserve. No numerical reuse across calls/captures establishes identity. '
         'Address container and governed canonical publication remain open.')
OPEN = ['native identity/payload/flags', 'provider/formatter identity', 'CODE/CODE and Regexp identity',
        'cross-call/capture numerical reuse', 'global heap census', 'cold replay', 'visual book QA',
        'governed canonical publication', 'address/lifetime container', 'HIAL/full-CI/push qualification']


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def structured(value):
    return pin(json.dumps(value, sort_keys=True).encode())


def produce(data, registry, binding, actual):
    source = {tuple(v['domain']): v for m in data['source']['modes'] for v in m['views']}
    holders = {tuple(v['domain']): v for m in data['holders']['modes'] for v in m['views']}
    joined = {tuple(v['domain']): v for v in data['numerical']['views']}
    records, views = [], []
    for mode in data['operands']['modes']:
        domains = {}
        for name, domain in mode['domains'].items():
            nonempty = []
            for record in domain['records']:
                nonempty.append({'index': record['index'], 'body': record['body_identity'],
                                 'whole_parsed_record': structured(record), 'forwarded': record['forwarded'],
                                 'source_domains': [p['domain'] for p in record['phases']]})
                for phase in record['phases']:
                    key = tuple(phase['domain']); numerical = joined[key]
                    views.append({'domain': list(key), 'whole_original_body': record['body_identity'],
                                  'whole_source': structured(source[key]), 'whole_holders': structured(holders[key]),
                                  'whole_phase': structured(phase), 'whole_numerical': structured(numerical),
                                  'source_operands': numerical['references'],
                                  'unaddressed': numerical['unaddressed_source_operands'],
                                  'hidden': numerical['hidden_arguments']})
            domains[name] = {'population': domain['population'], 'empty': domain['empty'], 'nonempty': nonempty}
        records.append({'mode': mode['mode'], 'domains': domains})
    return {'owner': (BASE / 'scope.txt').read_text().strip(), 'scope': SCOPE, 'open': OPEN,
            'inputs': registry, 'binding': pin((BASE / 'binding.json').read_bytes()),
            'contracts': binding['contracts'], 'completed': binding['completed'], 'original_allocation': records,
            'views': views, 'controls': {name: data[name + '_proof']['controls'] for name in ('admission', 'operand', 'holder', 'numerical')},
            'actual_readers': {name: actual[name] for name in ('admission', 'operands', 'holders', 'numerical')}}


def main():
    intake = runpy.run_path(str(BASE / 'source.py')); registry, binding = intake['rebuild']()
    intake['need'](registry == json.loads((BASE / 'inputs.json').read_bytes())
                   and binding == json.loads((BASE / 'binding.json').read_bytes()), 'whole parent input binding')
    data = {n: json.loads(Path(s['path']).read_bytes()) for n, s in registry.items() if s['path'].endswith('.json')}
    product = produce(data, registry, binding, json.loads((BASE / 'checks.json').read_bytes()))
    target = BASE / 'acceptance.json'; intake['need'](not target.exists(), 'retain first complete parent witness')
    target.write_text(json.dumps(product, sort_keys=True, indent=2) + '\n')
    print('PASS complete finite raw-parent acceptance witness produced; independent unchanged-contract qualification remains required.')


if __name__ == '__main__':
    main()

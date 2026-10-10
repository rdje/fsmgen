"""Join the complete finite original display numbers to simultaneous source roles."""
import collections
import hashlib
import itertools
import json
import runpy
from pathlib import Path

BASE = Path('docs/audits/address-numeric-join-20261010')
SCOPE = ('Complete finite original visible reference-number agreement with qualified simultaneous source '
         'roles and corrected holders, one source throw domain at a time. Source aliases agree numerically '
         'and qualified source distinctions have different displays. CODE/CODE identities, opaque external '
         'operands, provider/formatter/native identity/payload/flags, cross-call/capture reuse, heap census '
         'and cold replay remain unqualified; no original object identity is inferred from a number.')


def need(condition, cause):
    if not condition:
        raise ValueError(cause)


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def structured(value):
    return pin(json.dumps(value, sort_keys=True).encode())


def held(view, supplement, key):
    if key in supplement['held_source_bindings']:
        return True
    if key.startswith('caller:'):
        _, table, number = key.split(':')
        return any(p['table'] == table and p['first'] <= int(number) < p['end'] for p in view['retained_caller_prefixes'])
    return False


def produce(data, registry):
    source = {tuple(v['domain']): v for m in data['source']['modes'] for v in m['views']}
    supplements = {tuple(v['domain']): v for m in data['holders']['modes'] for v in m['views']}
    views, allocation = [], []
    for mode in data['operands']['modes']:
        domains = {}
        for name, domain in mode['domains'].items():
            records = []
            for record in domain['records']:
                frames = {f['frame_index']: f for f in record['segments'] if f['kind'] == 'frame'}
                own_positions = {f['frame_index'] for p in record['phases'] for f in p['frames']}
                opaque = [{'frame_index': i, 'argument': ai, 'token': token} for i, frame in frames.items()
                          if i not in own_positions for ai, token in enumerate(frame['arguments']) if token['kind'] == 'reference']
                domains_here = []
                for phase in record['phases']:
                    key = tuple(phase['domain']); view, supplement = source[key], supplements[key]
                    need(supplement['whole_prior_view'] == phase['whole_source_view'] == structured(view), 'whole numerical source/holder/parsed phase')
                    mappings = {m['source_frame']: m for m in phase['frames']}
                    rows, unaddressed, hidden = [], [], []
                    for occurrence in view['occurrences']:
                        sf, ai = occurrence['frame'], occurrence['argument']; mapping = mappings[sf]
                        if ai >= mapping['visible_arguments']:
                            unaddressed.append({'source': occurrence, 'frame_index': mapping['frame_index'], 'category': 'hidden_reference', 'token': None})
                            continue
                        token = frames[mapping['frame_index']]['arguments'][ai]
                        if token['kind'] == 'regex_display':
                            unaddressed.append({'source': occurrence, 'frame_index': mapping['frame_index'], 'category': 'regex_display', 'token': token})
                            continue
                        need(token['kind'] == 'reference' and held(view, supplement, occurrence['binding']), 'every visible numerical source operand has a simultaneous holder')
                        rows.append({'source': occurrence, 'frame_index': mapping['frame_index'],
                                     'reference_kind': token['reference_kind'], 'display_class': token['display_class'],
                                     'raw': token['raw'], 'span': [token['start'], token['end']],
                                     'hex': token['hex'], 'hex_span': token['hex_span'],
                                     'numeric_key': hex(int(token['hex'], 16))})
                    for mapping in phase['frames']:
                        interval = mapping['hidden_arguments']
                        if interval:
                            omitted = view['frames'][mapping['source_frame']]['arguments'][interval[0]:interval[1]]
                            hidden.append({'source_frame': mapping['source_frame'], 'frame_index': mapping['frame_index'],
                                           'interval': interval, 'whole_hidden_source_arguments': structured(omitted)})
                    aliases = collections.defaultdict(list)
                    for index, row in enumerate(rows):
                        aliases[row['source']['binding']].append(index)
                    groups = [{'binding': binding, 'members': members, 'numeric_key': rows[members[0]]['numeric_key']}
                              for binding, members in sorted(aliases.items())]
                    pairs = []
                    for left, right in itertools.combinations(range(len(rows)), 2):
                        a, b = rows[left], rows[right]
                        same_source = a['source']['binding'] == b['source']['binding']
                        relation = 'equal' if same_source else 'opaque_CODE' if a['reference_kind'] == b['reference_kind'] == 'CODE' else 'distinct'
                        same_number = a['numeric_key'] == b['numeric_key']
                        need(relation != 'equal' or same_number, 'original numeric agreement for explicit source aliases')
                        need(relation != 'distinct' or not same_number, 'original numeric separation for simultaneous source distinctions')
                        pairs.append({'left': left, 'right': right, 'source_relation': relation, 'numeric_equal': same_number})
                    views.append({'domain': list(key), 'event': view['event'], 'whole_source_view': structured(view),
                                  'whole_holder_view': structured(supplement), 'whole_parsed_phase': structured(phase),
                                  'references': rows, 'unaddressed_source_operands': unaddressed,
                                  'hidden_arguments': hidden, 'source_alias_classes': groups, 'pairs': pairs})
                    domains_here.append(list(key))
                records.append({'index': record['index'], 'body_identity': record['body_identity'],
                                'whole_parsed_record': structured(record), 'source_domains': domains_here,
                                'forwarded': record['forwarded'], 'opaque_reference_operands': opaque})
            domains[name] = {'population': domain['population'], 'empty': domain['empty'], 'records': records}
        allocation.append({'mode': mode['mode'], 'domains': domains})
    return {'owner': (BASE / 'scope.txt').read_text().strip(), 'scope': SCOPE, 'inputs': registry,
            'binding': pin((BASE / 'binding.json').read_bytes()), 'allocation': allocation, 'views': views}


def main():
    intake = runpy.run_path(str(BASE / 'source.py'))
    registry, binding = intake['rebuild']()
    need(registry == json.loads((BASE / 'inputs.json').read_bytes()) and binding == json.loads((BASE / 'binding.json').read_bytes()),
         'whole numerical input binding')
    data = {name: json.loads(Path(spec['path']).read_bytes()) for name, spec in registry.items() if spec['path'].endswith('.json')}
    product = produce(data, registry)
    target = BASE / 'joining.json'
    need(not target.exists(), 'retain first complete original numerical join')
    target.write_text(json.dumps(product, sort_keys=True, indent=2) + '\n')
    print('PASS complete finite original source/numerical join produced; independent qualification and full parent acceptance remain required.')


if __name__ == '__main__':
    main()

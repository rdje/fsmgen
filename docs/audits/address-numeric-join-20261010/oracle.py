"""Independent original-byte/source-slot reader and bipartite numerical checks."""
import collections
import hashlib
import json
import re
import subprocess
from pathlib import Path

BASE = Path('docs/audits/address-numeric-join-20261010')
REVISION = 'd63e5ca0f763302668d12ac90b5c07c9c9caa872'
SCOPE = ('Complete finite original visible reference-number agreement with qualified simultaneous source '
         'roles and corrected holders, one source throw domain at a time. Source aliases agree numerically '
         'and qualified source distinctions have different displays. CODE/CODE identities, opaque external '
         'operands, provider/formatter/native identity/payload/flags, cross-call/capture reuse, heap census '
         'and cold replay remain unqualified; no original object identity is inferred from a number.')
REFERENCE = re.compile(rb'(?:(?P<class>[A-Za-z_][A-Za-z_0-9:]*)=)?(?P<kind>HASH|ARRAY|CODE)\((?P<hex>0x[0-9a-fA-F]+)\)\Z')


def need(condition, cause):
    if not condition:
        raise ValueError(cause)


def same(a, b):
    return json.dumps(a, sort_keys=True) == json.dumps(b, sort_keys=True)


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def structured(value):
    return pin(json.dumps(value, sort_keys=True).encode())


def number(lexeme):
    need(isinstance(lexeme, str) and re.fullmatch('0x[0-9a-fA-F]+', lexeme), 'complete numerical hexadecimal grammar')
    value = 0
    for char in lexeme[2:].lower():
        value = value * 16 + '0123456789abcdef'.index(char)
    return '0x' + format(value, 'x')


def fixed_inputs():
    registry = json.loads((BASE / 'inputs.json').read_bytes())
    binding = json.loads((BASE / 'binding.json').read_bytes())
    need(binding['revision'] == REVISION, 'fixed numerical original/source revision')
    for path, identity in binding['members'].items():
        raw = subprocess.check_output(['git', '--no-replace-objects', 'cat-file', 'blob', REVISION + ':' + path])
        need(raw == Path(path).read_bytes() and pin(raw) == identity, 'whole independent numerical input bytes')
    for spec in registry.values():
        need(spec['identity'] == binding['members'][spec['path']], 'complete numerical input member identity')
    return registry, {name: json.loads(Path(spec['path']).read_bytes()) for name, spec in registry.items()
                      if spec['path'].endswith('.json')}


def read_reference(body, token):
    start, end = token['start'], token['end']
    raw = body[start:end]; match = REFERENCE.fullmatch(raw)
    need(match is not None, 'whole original reference display bytes')
    result = {'start': start, 'end': end, 'raw': raw.decode(), 'kind': 'reference',
              'display_class': match['class'].decode() if match['class'] else None,
              'reference_kind': match['kind'].decode(), 'hex': match['hex'].decode(),
              'hex_span': [start + match.start('hex'), start + match.end('hex')]}
    need(same(result, token), 'complete prior reference token conservation')
    return result


def reconstruct(data):
    originals = {mode: data['original_' + mode] for mode in ('ordinary', 'storable', 'controls')}
    sources = {tuple(v['domain']): v for m in data['source']['modes'] for v in m['views']}
    held_views = {tuple(v['domain']): v for m in data['holders']['modes'] for v in m['views']}
    coordinates = {(c['mode'], c['domain'], c['index']): c for c in data['coordinates']['matches']}
    allocation, views, counts = [], [], collections.Counter()
    for mode in data['operands']['modes']:
        original = originals[mode['mode']]; domains = {}
        for name in ('api', 'copies', 'parses', 'test_run'):
            events = [original[name]] if name == 'test_run' else original[name]
            empty = [i for i, e in enumerate(events) if e['error'] == '']
            domain = mode['domains'][name]
            need(domain['population'] == len(events) and domain['empty'] == empty
                 and [r['index'] for r in domain['records']] == [i for i, e in enumerate(events) if e['error'] != ''],
                 'whole original empty/nonempty numerical allocation')
            records = []; counts['empty_records'] += len(empty)
            for record in domain['records']:
                body = events[record['index']]['error'].encode()
                need(pin(body) == record['body_identity'] and body == ''.join(s['raw'] for s in record['segments']).encode(),
                     'whole original numerical body conservation')
                frames = {s['frame_index']: s for s in record['segments'] if s['kind'] == 'frame'}
                source_domains, own_positions = [], set()
                for phase in record['phases']:
                    key = tuple(phase['domain']); source, supplement = sources[key], held_views[key]
                    own = coordinates[key[:3]]['phases'][key[3]]['callers_inner_to_outer']
                    physical = {i: c['frame_index'] for i, c in enumerate(own)}
                    need(len(physical) == len(source['frames']) and phase['whole_source_view'] == supplement['whole_prior_view'] == structured(source),
                         'complete numerical source/coordinate/holder domain')
                    own_positions.update(physical.values()); source_domains.append(list(key))
                    callers = {'caller:' + p['table'] + ':' + str(i) for p in source['retained_caller_prefixes'] for i in range(p['first'], p['end'])}
                    held = set(supplement['held_source_bindings']) | callers
                    rows, unaddressed, hidden = [], [], []
                    visible_counts = {}
                    for sf, frame in enumerate(source['frames']):
                        observed = frames[physical[sf]]
                        need(observed['function'] == frame['function'], 'whole original numerical own frame function')
                        args = observed['arguments']; remaining = bool(args and args[-1]['kind'] == 'remaining_arguments')
                        n = len(args) - int(remaining); visible_counts[sf] = n
                        need(n < len(frame['arguments']) if remaining else n == len(frame['arguments']), 'complete numerical visible/hidden argument allocation')
                        if remaining:
                            omitted = frame['arguments'][n:]
                            hidden.append({'source_frame': sf, 'frame_index': physical[sf], 'interval': [n, len(frame['arguments'])],
                                           'whole_hidden_source_arguments': structured(omitted)})
                            counts['hidden_source_arguments'] += len(omitted)
                    for occurrence in source['occurrences']:
                        sf, ai = occurrence['frame'], occurrence['argument']; pos = physical[sf]
                        if ai >= visible_counts[sf]:
                            unaddressed.append({'source': occurrence, 'frame_index': pos, 'category': 'hidden_reference', 'token': None})
                            counts['hidden_reference_operands'] += 1; continue
                        token = frames[pos]['arguments'][ai]
                        if token['kind'] == 'regex_display':
                            need(body[token['start']:token['end']].decode() == token['raw']
                                 and token['raw'] == 'qr(' + token['value'] + ')', 'whole original regex display conservation')
                            unaddressed.append({'source': occurrence, 'frame_index': pos, 'category': 'regex_display', 'token': token})
                            counts['regex_display_operands'] += 1; continue
                        actual = read_reference(body, token)
                        declared = source['bindings'][occurrence['binding']]['reference_kind']
                        display_class, separator, kind = declared.rpartition('=')
                        need(actual['reference_kind'] == kind and actual['display_class'] == (display_class if separator else None)
                             and occurrence['binding'] in held, 'qualified simultaneous numerical source kind and holder')
                        rows.append({'source': occurrence, 'frame_index': pos, 'reference_kind': actual['reference_kind'],
                                     'display_class': actual['display_class'], 'raw': actual['raw'], 'span': [actual['start'], actual['end']],
                                     'hex': actual['hex'], 'hex_span': actual['hex_span'], 'numeric_key': number(actual['hex'])})
                    grouped = collections.defaultdict(list)
                    for index, row in enumerate(rows):
                        grouped[row['source']['binding']].append(index)
                    classes = [{'binding': b, 'members': members, 'numeric_key': rows[members[0]]['numeric_key']}
                               for b, members in sorted(grouped.items())]
                    pairs = []
                    for left in range(len(rows)):
                        for right in range(left + 1, len(rows)):
                            a, b = rows[left], rows[right]
                            relation = ('equal' if a['source']['binding'] == b['source']['binding'] else
                                        'opaque_CODE' if a['reference_kind'] == b['reference_kind'] == 'CODE' else 'distinct')
                            pairs.append({'left': left, 'right': right, 'source_relation': relation,
                                          'numeric_equal': a['numeric_key'] == b['numeric_key']})
                            counts['pair_' + relation] += 1
                    views.append({'domain': list(key), 'event': source['event'], 'whole_source_view': structured(source),
                                  'whole_holder_view': structured(supplement), 'whole_parsed_phase': structured(phase),
                                  'references': rows, 'unaddressed_source_operands': unaddressed, 'hidden_arguments': hidden,
                                  'source_alias_classes': classes, 'pairs': pairs})
                    counts['views'] += 1; counts['visible_reference_operands'] += len(rows); counts['source_alias_classes'] += len(classes)
                opaque = []
                for pos, frame in frames.items():
                    if pos not in own_positions:
                        for ai, token in enumerate(frame['arguments']):
                            if token['kind'] == 'reference':
                                opaque.append({'frame_index': pos, 'argument': ai, 'token': read_reference(body, token)})
                counts['opaque_reference_operands'] += len(opaque); counts['nonempty_records'] += 1; counts['body_bytes'] += len(body)
                counts['forwarding_pairs'] += record['forwarded'] is not None
                records.append({'index': record['index'], 'body_identity': pin(body), 'whole_parsed_record': structured(record),
                                'source_domains': source_domains, 'forwarded': record['forwarded'], 'opaque_reference_operands': opaque})
            domains[name] = {'population': len(events), 'empty': empty, 'records': records}
        allocation.append({'mode': mode['mode'], 'domains': domains})
    need({tuple(v['domain']) for v in views} == set(sources) == set(held_views), 'complete unique numerical source domain population')
    return allocation, views, dict(counts)


def qualify(candidate, registry, allocation, views):
    need(set(candidate) == {'owner', 'scope', 'inputs', 'binding', 'allocation', 'views'}, 'closed complete numerical join')
    need(candidate['owner'] == (BASE / 'scope.txt').read_text().strip() and candidate['scope'] == SCOPE, 'exact numerical owner and native/reuse scope')
    need(same(candidate['inputs'], registry) and candidate['binding'] == pin((BASE / 'binding.json').read_bytes()), 'whole fixed numerical input identity')
    need(same(candidate['allocation'], allocation), 'complete original parsed allocation and opaque operand conservation')
    need(len(candidate['views']) == len(views), 'complete numerical view population')
    for actual, expected in zip(candidate['views'], views):
        need(set(actual) == set(expected), 'closed complete numerical source view')
        stamps = ('domain', 'event', 'whole_source_view', 'whole_holder_view', 'whole_parsed_phase')
        need(same({k: actual[k] for k in stamps}, {k: expected[k] for k in stamps}), 'exact original simultaneous numerical source domain')
        need(len(actual['references']) == len(expected['references']), 'complete own numerical reference slot population')
        by_binding, by_number = collections.defaultdict(set), collections.defaultdict(dict)
        for row, wanted in zip(actual['references'], expected['references']):
            need(set(row) == set(wanted), 'closed original numerical reference operand')
            need(same(row['source'], wanted['source']) and same(row['frame_index'], wanted['frame_index']), 'exact original source slot binding and provenance')
            need(row['reference_kind'] == wanted['reference_kind'] and row['display_class'] == wanted['display_class'], 'exact original source numerical reference kind')
            key = number(row['hex'])
            need(row['numeric_key'] == key, 'exact numerical hexadecimal interpretation')
            binding = row['source']['binding']; by_binding[binding].add(key); by_number[key][binding] = row['reference_kind']
        # Separate bipartite checks, rather than trusting producer pair labels.
        need(all(len(values) == 1 for values in by_binding.values()), 'numerical agreement for explicit source aliases')
        need(all(len(bindings) == 1 or all(kind == 'CODE' for kind in bindings.values()) for bindings in by_number.values()),
             'numerical separation for simultaneous source distinctions')
        for row, wanted in zip(actual['references'], expected['references']):
            need(same(row, wanted), 'complete original reference operand byte and number association')
        need(same(actual['unaddressed_source_operands'], expected['unaddressed_source_operands'])
             and same(actual['hidden_arguments'], expected['hidden_arguments']), 'complete unaddressed regex and hidden source conservation')
        need(same(actual['source_alias_classes'], expected['source_alias_classes']), 'complete source alias class allocation')
        need(same(actual['pairs'], expected['pairs']), 'complete numerical pair relation and opaque CODE partition')
    return True

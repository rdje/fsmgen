"""Independent whole-source/argument holder and complete relation reconstruction."""
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/address-raw-join-20261010')
REVISION = 'ac21c39a4d85ba6af8ae68bec65ab20927abbe81'
SCOPE = ('Complete dated own source holder relation with active saved-operation CODE parameter retention. '
         'Earlier graph/role/caller/inactive meanings conserve. This is source retention and allocation '
         'hypothesis only; original numerical joins, native identity/payload/flags, CODE/CODE identity, '
         'provider/formatter identity, cross-call reuse, global heap census and cold replay remain open.')


def need(condition, cause):
    if not condition:
        raise ValueError(cause)


def same(a, b):
    return json.dumps(a, sort_keys=True) == json.dumps(b, sort_keys=True)


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def structured(value):
    return pin(json.dumps(value, sort_keys=True).encode())


def fixed_inputs():
    registry = json.loads((BASE / 'inputs.json').read_bytes())
    binding = json.loads((BASE / 'binding.json').read_bytes())
    need(binding['revision'] == REVISION, 'fixed original holder source revision')
    for path, identity in binding['members'].items():
        old = subprocess.check_output(['git', '--no-replace-objects', 'cat-file', 'blob', REVISION + ':' + path])
        need(old == Path(path).read_bytes() and pin(old) == identity, 'whole independent fixed holder input')
    for spec in registry.values():
        need(spec['identity'] == binding['members'][spec['path']], 'complete holder registry member identity')
    original_path = 'docs/audits/record-value-original-candidate-20261004/observe.pl'
    need(registry['observer_source']['path'] == original_path, 'original whole holder observer source')
    raw = subprocess.check_output(['git', '--no-replace-objects', 'cat-file', 'blob', REVISION + ':' + original_path])
    return registry, {name: json.loads(Path(spec['path']).read_bytes()) for name, spec in registry.items()
                      if spec['path'].endswith('.json')}, raw


def retention(raw):
    lines = raw.splitlines(keepends=True)
    begin = next(i for i, line in enumerate(lines) if line == b'sub call_api {\n')
    finish = next(i for i in range(begin + 1, len(lines)) if lines[i].startswith(b'sub '))
    start = sum(map(len, lines[:begin])); body = b''.join(lines[begin:finish])
    # The blank separator belongs to neither function in the byte producer.
    need(body.endswith(b'\n\n'), 'whole original call_api function boundary')
    body = body[:-1]; end = start + len(body)
    assignment = next(line for line in lines[begin:finish] if b'my ($kind, $operation, $caller, @args)' in line)
    invocation = next(line for line in lines[begin:finish] if b'$operation->' in line)
    need(assignment == b'    my ($kind, $operation, $caller, @args) = @_;\n'
         and invocation == b'        $ok = eval {$result = $operation->(@args); 1}; $error = $@;\n'
         and len(body.split(b'$operation')) == 3 and body.index(assignment) < body.index(invocation)
         and body[:body.index(assignment)] == b'sub call_api {\n', 'independent lexical parameter retained in active eval')
    return {'path': 'docs/audits/record-value-original-candidate-20261004/observe.pl', 'whole_source': pin(raw),
            'function_span': [start, end], 'function': body.decode(), 'holder': '$operation',
            'declaration_span': [start + body.index(assignment), start + body.index(assignment) + len(assignment)],
            'invocation_span': [start + body.index(invocation), start + body.index(invocation) + len(invocation)],
            'meaning': 'Lexical parameter in the active call_api frame retains the explicitly forwarded saved CODE handle at the source throw; native CODE identity remains unmeasured.'}


def reconstruct(data, source_witness):
    parsed = {tuple(p['domain']): (r, p) for mode in data['operands']['modes'] for d in mode['domains'].values()
              for r in d['records'] for p in r['phases']}
    source_domains = {tuple(v['domain']) for m in data['source']['modes'] for v in m['views']}
    need(set(parsed) == source_domains, 'complete original parsed source phase allocation')
    modes, counts = [], {'views': 0, 'additional_holders': 0, 'additional_visible_arguments': 0,
                         'prior_held_population': 0, 'held_population': 0, 'prior_distinction_pairs': 0,
                         'distinction_pairs': 0, 'additional_distinction_pairs': 0, 'unchanged_views': 0}
    for mode in data['source']['modes']:
        views = []
        for view in mode['views']:
            callers = set()
            for prefix in view['retained_caller_prefixes']:
                part = {'caller:' + prefix['table'] + ':' + str(i) for i in range(prefix['first'], prefix['end'])}
                need(not (part & callers), 'independent complete disjoint caller source population')
                callers |= part
            old_held = set(view['held_source_bindings'])
            old_codes = sorted(key for key in old_held if view['bindings'][key]['reference_kind'] == 'CODE')
            old_population = len(old_held | callers)
            prior = {'relation': 'all distinct held member pairs except CODE/CODE', 'population': old_population,
                     'pairs': sum(range(old_population)) - sum(range(len(old_codes))), 'opaque_CODE_members': old_codes}
            need(same(prior, view['source_distinctions']) and not (old_held & callers), 'independent whole prior source distinction relation')
            record, phase = parsed[tuple(view['domain'])]
            need(phase['whole_source_view'] == structured(view), 'whole parsed source view conservation')
            frame_map = {m['source_frame']: m['frame_index'] for m in phase['frames']}
            frames = {s['frame_index']: s for s in record['segments'] if s['kind'] == 'frame'}
            missing_keys = {o['binding'] for o in view['occurrences']} - old_held - callers
            additions = []
            for key in sorted(missing_keys):
                descriptor = view['bindings'][key]
                occurrences = [o for o in view['occurrences'] if o['binding'] == key]
                need(descriptor['reference_kind'] == 'CODE' and key not in view['no_active_own_holder']
                     and view['category'] == 'direct' and view['domain'][2] in view['lifetime']['active_api_invocations']
                     and descriptor['origins'], 'independent active operation holder domain and kind')
                for origin in descriptor['origins']:
                    need(origin['component'].startswith('operation:') and origin['source']['kind'] == 'saved_lookup'
                         and key == 'saved:' + origin['source']['expression'], 'independent saved-operation explicit forwarding origin')
                slots = []
                for occurrence in occurrences:
                    fi, ai = occurrence['frame'], occurrence['argument']
                    source_frame = view['frames'][fi]
                    token = frames[frame_map[fi]]['arguments'][ai]
                    need(source_frame['function'] == 'main::call_api' and ai == 1
                         and source_frame['arguments'][ai]['role'] == occurrence['role'] == 'original_operation'
                         and token['kind'] == 'reference' and token['reference_kind'] == 'CODE' and token['display_class'] is None,
                         'independent original visible active operation parameter')
                    slots.append([fi, ai]); counts['additional_visible_arguments'] += 1
                additions.append({'binding': key, 'reference_kind': 'CODE', 'holder': source_witness['holder'],
                                  'source_origins': descriptor['origins'], 'source_slots': slots})
            complete = sorted(old_held | missing_keys)
            code_members = sorted(old_codes + list(missing_keys))
            population = len(callers) + len(complete)
            distinctions = {'relation': prior['relation'], 'population': population,
                            'pairs': sum(range(population)) - sum(range(len(code_members))), 'opaque_CODE_members': code_members}
            delta = distinctions['pairs'] - prior['pairs']
            views.append({'domain': view['domain'], 'whole_prior_view': structured(view),
                          'prior_held_source_bindings': view['held_source_bindings'], 'retained_caller_prefixes': view['retained_caller_prefixes'],
                          'no_active_own_holder': view['no_active_own_holder'], 'prior_distinctions': prior,
                          'additional_active_argument_holders': additions, 'held_source_bindings': complete,
                          'source_distinctions': distinctions, 'additional_distinction_pairs': delta})
            counts['views'] += 1; counts['additional_holders'] += len(additions)
            counts['prior_held_population'] += old_population; counts['held_population'] += population
            counts['prior_distinction_pairs'] += prior['pairs']; counts['distinction_pairs'] += distinctions['pairs']
            counts['additional_distinction_pairs'] += delta; counts['unchanged_views'] += not additions
        modes.append({'mode': mode['mode'], 'views': views})
    return modes, counts


def qualify(candidate, registry, source_witness, expected):
    need(set(candidate) == {'owner', 'scope', 'inputs', 'binding', 'retention_source', 'modes'}, 'closed complete holder supplement')
    need(candidate['owner'] == (BASE / 'scope.txt').read_text().strip() and candidate['scope'] == SCOPE, 'exact source holder owner and native scope')
    need(same(candidate['inputs'], registry) and candidate['binding'] == pin((BASE / 'binding.json').read_bytes()), 'whole holder input identity')
    need(same(candidate['retention_source'], source_witness), 'complete original lexical operation retention witness')
    need(len(candidate['modes']) == len(expected), 'complete holder mode population')
    for mode, original_mode in zip(candidate['modes'], expected):
        need(set(mode) == {'mode', 'views'} and mode['mode'] == original_mode['mode']
             and len(mode['views']) == len(original_mode['views']), 'complete holder view allocation')
        for actual, wanted in zip(mode['views'], original_mode['views']):
            need(set(actual) == set(wanted), 'closed complete holder view')
            need(same(actual['domain'], wanted['domain']) and actual['whole_prior_view'] == wanted['whole_prior_view'], 'whole original holder source phase')
            fields = ('prior_held_source_bindings', 'retained_caller_prefixes', 'no_active_own_holder', 'prior_distinctions')
            need(same({k: actual[k] for k in fields}, {k: wanted[k] for k in fields}), 'complete prior source holder relation conservation')
            need(same(actual['additional_active_argument_holders'], wanted['additional_active_argument_holders']), 'complete active saved-operation argument holders')
            need(same(actual['held_source_bindings'], wanted['held_source_bindings']), 'complete supplemented source held members')
            need(same(actual['source_distinctions'], wanted['source_distinctions'])
                 and same(actual['additional_distinction_pairs'], wanted['additional_distinction_pairs']), 'complete supplemented source distinction and opaque CODE relation')

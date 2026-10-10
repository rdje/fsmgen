"""Complete active source holders with original operation parameter retention."""
import hashlib
import json
import runpy
from pathlib import Path

BASE = Path('docs/audits/address-raw-join-20261010')
SCOPE = ('Complete dated own source holder relation with active saved-operation CODE parameter retention. '
         'Earlier graph/role/caller/inactive meanings conserve. This is source retention and allocation '
         'hypothesis only; original numerical joins, native identity/payload/flags, CODE/CODE identity, '
         'provider/formatter identity, cross-call reuse, global heap census and cold replay remain open.')


def need(condition, cause):
    if not condition:
        raise ValueError(cause)


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def structured(value):
    return pin(json.dumps(value, sort_keys=True).encode())


def witness(raw):
    start = raw.index(b'sub call_api {\n')
    end = raw.index(b'\nsub copy_value {', start)
    body = raw[start:end]
    declaration = b'    my ($kind, $operation, $caller, @args) = @_;\n'
    invocation = b'        $ok = eval {$result = $operation->(@args); 1}; $error = $@;\n'
    need(body.count(declaration) == body.count(invocation) == 1 and body.count(b'$operation') == 2,
         'whole original operation parameter retention source')
    return {'path': 'docs/audits/record-value-original-candidate-20261004/observe.pl',
            'whole_source': pin(raw), 'function_span': [start, end], 'function': body.decode(),
            'declaration_span': [start + body.index(declaration), start + body.index(declaration) + len(declaration)],
            'invocation_span': [start + body.index(invocation), start + body.index(invocation) + len(invocation)],
            'holder': '$operation', 'meaning': 'Lexical parameter in the active call_api frame retains the explicitly forwarded saved CODE handle at the source throw; native CODE identity remains unmeasured.'}


def held(view, key):
    if key in view['held_source_bindings']:
        return True
    if not key.startswith('caller:'):
        return False
    _, table, number = key.split(':')
    return any(p['table'] == table and p['first'] <= int(number) < p['end'] for p in view['retained_caller_prefixes'])


def produce(source, retention, registry):
    modes = []
    for mode in source['modes']:
        views = []
        for view in mode['views']:
            missing = {}
            for occurrence in view['occurrences']:
                key = occurrence['binding']
                if held(view, key):
                    continue
                descriptor = view['bindings'][key]
                frame = view['frames'][occurrence['frame']]
                need(descriptor['reference_kind'] == 'CODE' and frame['function'] == 'main::call_api'
                     and occurrence['argument'] == 1 and occurrence['role'] == 'original_operation'
                     and view['category'] == 'direct' and view['domain'][2] in view['lifetime']['active_api_invocations']
                     and key not in view['no_active_own_holder'] and descriptor['origins']
                     and all(o['component'].startswith('operation:') and o['source']['kind'] == 'saved_lookup'
                             for o in descriptor['origins']), 'only active source operation CODE arguments supplement holders')
                row = missing.setdefault(key, {'binding': key, 'reference_kind': 'CODE', 'holder': retention['holder'],
                                              'source_origins': descriptor['origins'], 'source_slots': []})
                row['source_slots'].append([occurrence['frame'], occurrence['argument']])
            prior = view['source_distinctions']
            codes = sorted(prior['opaque_CODE_members'] + list(missing))
            population = prior['population'] + len(missing)
            relation = {'relation': prior['relation'], 'population': population,
                        'pairs': population * (population - 1) // 2 - len(codes) * (len(codes) - 1) // 2,
                        'opaque_CODE_members': codes}
            views.append({'domain': view['domain'], 'whole_prior_view': structured(view),
                          'prior_held_source_bindings': view['held_source_bindings'],
                          'retained_caller_prefixes': view['retained_caller_prefixes'],
                          'no_active_own_holder': view['no_active_own_holder'], 'prior_distinctions': prior,
                          'additional_active_argument_holders': [missing[k] for k in sorted(missing)],
                          'held_source_bindings': sorted(view['held_source_bindings'] + list(missing)),
                          'source_distinctions': relation, 'additional_distinction_pairs': relation['pairs'] - prior['pairs']})
        modes.append({'mode': mode['mode'], 'views': views})
    return {'owner': (BASE / 'scope.txt').read_text().strip(), 'scope': SCOPE,
            'inputs': registry, 'binding': pin((BASE / 'binding.json').read_bytes()),
            'retention_source': retention, 'modes': modes}


def main():
    intake = runpy.run_path(str(BASE / 'source.py'))
    registry, binding = intake['rebuild']()
    need(registry == json.loads((BASE / 'inputs.json').read_bytes()) and binding == json.loads((BASE / 'binding.json').read_bytes()),
         'whole holder input custody')
    source = json.loads(Path(registry['source']['path']).read_bytes())
    retention = witness(Path(registry['observer_source']['path']).read_bytes())
    product = produce(source, retention, registry)
    target = BASE / 'holders.json'
    need(not target.exists(), 'retain first complete active-operation holder supplement')
    target.write_text(json.dumps(product, sort_keys=True, indent=2) + '\n')
    print('PASS complete active-operation source holder supplement produced; independent qualification and numerical joins remain required.')


if __name__ == '__main__':
    main()

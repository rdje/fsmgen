"""Independent fixed-Git source/path allocation, never a runtime-stack oracle.

Construct outward caller segments first, then weave them into the reversed
qualified core topology. Do not import the producer or select argument/error,
public-trace or original caller-coordinate fields. Predecessor finite callee
semantics remain trusted; binary statement construction is separately verified.
"""
import copy
import hashlib
import json
import runpy
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
BASE = Path('docs/audits/coordinate-refusal-phases-20261009')
REVISION = '485275db33d4fe96576b1782f44708be66963fc1'
R = Path('docs/audits/coordinate-statement-recipes-20261009')
P = Path('docs/audits/coordinate-refusal-path-inputs-20261009')
S = Path('docs/audits/record-value-class-frame-join-20261006/source-models.json')


def need(ok, cause):
    if not ok:
        raise ValueError(cause)


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def identity(value):
    return pin(json.dumps(value, sort_keys=True).encode())


def same(a, b):
    return json.dumps(a, sort_keys=True) == json.dumps(b, sort_keys=True)


def git(path):
    run = subprocess.run(['git', '--no-replace-objects', 'show', REVISION + ':' + str(path)],
                         cwd=ROOT, capture_output=True)
    need(run.returncode == 0 and not run.stderr, 'independent complete fixed Git input')
    local = ROOT / path
    need(local.resolve() == local and local.is_file() and local.stat().st_dev == ROOT.stat().st_dev
         and local.read_bytes() == run.stdout, 'independent unchanged own same-volume input')
    need(all(not (parent / '.git').exists() for parent in local.parents if parent != ROOT
             and ROOT in parent.parents), 'independent own repository boundary')
    return run.stdout


def projection(source):
    modes = []
    for m in source['modes']:
        rows = []
        for c in m['cases']:
            row = {key: c[key] for key in ('domain', 'index', 'helper', 'kind', 'subtest')}
            row['phases'] = []
            for p in c['phases']:
                item = {key: copy.deepcopy(p[key]) for key in ('phase', 'family', 'inferred_class', 'guard_source')}
                for group in ('core', 'helper', 'body', 'entry'):
                    item[group] = [{key: f[key] for key in f if key in ('function', 'role', 'call_site')}
                                   for f in p['own'][group]]
                item['operations'] = []
                for op in p['own']['operations']:
                    item['operations'].append({'kind': op['kind'], 'operation_lookup': op['operation_lookup'],
                        'frames': [{key: f[key] for key in f if key in ('function', 'call_site', 'role')}
                                   for f in op['frames']]})
                item['load_marker'] = p['own']['load']
                row['phases'].append(item)
            rows.append(row)
        modes.append({'mode': m['mode'], 'cases': rows})
    return modes


def expectation():
    authorities = {}
    for directory in (P, R):
        raw = git(directory / 'seal.json')
        members = json.loads(raw)
        need({p.name for p in directory.iterdir()} == set(members) | {'seal.json'}, 'independent complete input namespace')
        authorities[str(directory / 'seal.json')] = pin(raw)
        for name, expected in members.items():
            need(pin(git(directory / name)) == expected, 'independent fixed sealed input identity')
    raw = git(S)
    authorities[str(S)] = pin(raw)
    modes = projection(json.loads(raw))
    # Both predecessor readers are source-only. Their producers remain sealed.
    runpy.run_path('docs/audits/coordinate-statement-recipe-checks-20261009/verify_recipes.py')['main']()
    runpy.run_path(str(P / 'verify.py'))['main']()
    recipes = json.loads(git(R / 'recipes.json'))
    paths = json.loads(git(P / 'paths.json'))
    table = {row['id']: row for row in recipes['statements']}
    source_cases = {(m['mode'], c['domain'], c['index']): c for m in modes for c in m['cases']}
    need(len(source_cases) == sum(len(m['cases']) for m in modes), 'independent distinct source refusal keys')
    owner = recipes['unresolved']['statement_hypotheses']
    need((BASE / 'scope.txt').read_text().strip() == owner, 'independent exact phase scope')
    used = set()

    def location(key):
        need(key in table, 'independent qualified statement reference')
        used.add(key)
        return {'kind': 'own_statement', 'recipe_id': key, 'original_selection': None}

    def frame(function, role, links, site, kind):
        caller = location(site) if site else {
            'kind': 'opaque_external_framework_interval', 'original_selection': None,
            'owner': recipes['unresolved']['original_coordinates']}
        return {'callee': function, 'role': role, 'model_links': links, 'call_kind': kind, 'caller': caller}

    # Reviewed finite caller declarations. Callee/body ownership never supplies
    # the call-site line; the statement belongs to the outward caller instead.
    parser_callers = {
        'FSM::Support::ISFRecordPortContexts::_require': 'context-write-guard',
        'FSM::Support::ISFRecordPortContexts::_reference': 'context-reference',
        'FSM::Support::ISFRecordPortContexts::_assignment': 'context-assignment',
        'FSM::Support::ISFRecordPortContexts::_clauses': 'context-clauses',
        'FSM::Support::ISFRecordPortContexts::validate_actor_record_contexts': 'parser-context',
        'FSM::Adapter::ISF::Parser::_resolve_typed_width_entry': 'parser-port',
        'FSM::Adapter::ISF::Parser::_finalize_actor_type_references': 'parser-finalize',
        'FSM::Adapter::ISF::Parser::_build_actor': 'parser-build',
        'FSM::Adapter::ISF::Parser::parse_source': 'facade-parse'}
    refusals = []
    for admitted in paths['allocations']:
        key = admitted['mode'], admitted['domain'], admitted['index']
        c = source_cases.pop(key)
        need(c['helper'] == admitted['helper']['index'] and c['subtest'] == admitted['subtest']['name']
             and len(c['phases']) == admitted['helper_case']['phases'], 'independent whole helper/subtest phase join')
        helper = str(c['helper'])
        phases = []
        for p in c['phases']:
            need(p['phase'] == len(phases) and type(p['phase']) is int, 'independent ordered source phase domain')
            upstream = admitted['helper_case']['paths'][p['phase']]
            need(same(p['helper'], [{k: f[k] for k in ('function', 'call_site') if k in f} for f in upstream]),
                 'independent complete helper source path')
            outward = []
            for i, f in reversed(list(enumerate(p['entry']))):
                saved = f['role'] == 'saved_public_delegate'
                outward.append(frame(f['function'], 'entry', [['entry', i]],
                    'saved-subtest-delegate' if saved else 'subtest-invocation/' + c['subtest'],
                    'saved_public_delegate' if saved else 'direct'))
            for i, f in reversed(list(enumerate(p['body']))):
                authored = f['role'] == 'authored_body'
                outward.append(frame(f['function'], 'body', [['body', i]],
                    'admitted/qualified/91' if authored else None, 'dynamic_code' if authored else 'opaque_external'))
            for i, f in reversed(list(enumerate(p['helper']))):
                tag = f['call_site']
                if tag == 'installed_observer_helper_wrapper':
                    site, kind = 'helper-invocation/' + helper, 'direct'
                elif tag == 'compiled_original_helper':
                    site, kind = 'admitted/qualified/92', 'dynamic_code'
                elif tag in ('original_refuses_callback_eval', 'compiled_original_parameterless_callback'):
                    site = 'admitted/qualified/95'
                    kind = 'eval' if tag == 'original_refuses_callback_eval' else 'dynamic_code'
                else:
                    need(tag == 'original_compiled_callback', 'independent finite test-helper caller tag')
                    site, kind = 'callback/' + helper, 'direct'
                outward.append(frame(f['function'], 'helper', [['helper', i]], site, kind))
            named = [f['function'].removeprefix('main::') for f in p['helper']
                     if f['call_site'] == 'original_compiled_callback']
            need(len(named) <= 1, 'independent named helper path')
            api_caller = 'helper-return/' + named[0] if named else 'callback/' + helper
            operations = list(enumerate(p['operations']))
            for ci, f in reversed(list(enumerate(p['core']))):
                matches = [(oi, op) for oi, op in operations if op['frames'][0]['function'] == f['function']]
                need(len(matches) <= 1, 'independent unique core/operation overlap')
                if matches:
                    oi, op = matches[0]
                    operations.remove((oi, op))
                    if op['kind'] == 'capture':
                        outward.append(frame('eval {...}', 'nested_capture_eval', [], 'value-capture-eval', 'eval'))
                    prefix = 'parse' if op['kind'] == 'source' else 'call_api'
                    callsites = ('observer-operation/' + prefix, 'observer-eval/' + prefix,
                                 'wrapper-delegate/' + f['function'] + '/0',
                                 'value-capture' if op['kind'] == 'capture' else api_caller)
                    need(len(op['frames']) == 4, 'independent complete observer boundary')
                    for fi in range(3, -1, -1):
                        links = [['operations', oi, 'frames', fi]]
                        if fi == 0:
                            links = [['core', ci]] + links
                        outward.append(frame(op['frames'][fi]['function'], 'core_operation' if fi == 0 else 'observer',
                            links, callsites[fi], ('dynamic_code', 'eval', 'direct', 'direct')[fi]))
                else:
                    function = f['function']
                    if function in parser_callers:
                        site = parser_callers[function]
                    else:
                        label = f['call_site']
                        if label == 'failed_Value_capture_eval_guard':
                            site = 'value-capture-guard'
                        else:
                            unit = 'metadata' if 'ISFInterfacePortMetadata::' in function else 'value'
                            token = 'GUARDS.' if function.endswith('::_require') else 'CALLS.'
                            if label == 'scope_private_root_type':
                                label = 'scope_type'
                            site = 'admitted/guard-call/' + unit + '/' + token + label
                    # Literal direct call and containing caller are separately
                    # represented in the fixed recipe, not inferred from a line.
                    need(function.rsplit('::', 1)[-1] + '(' in table[site]['text'],
                         'independent callee occurs in caller statement')
                    outward.append(frame(function, 'core', [['core', ci]], site, 'direct'))
            need(not operations, 'independent complete observer phase partition')
            active = list(reversed(outward))
            origins = {'metadata': 'admitted/qualified/1', 'value': 'admitted/qualified/0',
                       'context': 'admitted/qualified/2', 'parser': 'parser-confess-statement'}
            origin = origins[p['family']]
            need(p['guard_source']['path'] == table[origin]['source_path']
                 and p['guard_source']['literal'] in table[origin]['text'], 'independent exact source throw origin')
            phases.append({'phase': p['phase'], 'family': p['family'], 'source_topology_identity': identity(p),
                'origin': {'thrower': p['core'][0]['function'], 'caller': location(origin)},
                'active_path_inner_to_outer': active,
                'load': {'source_operator': 'do', 'caller': location('admitted/qualified/99'),
                         'model_marker': p['load_marker'],
                         'marker_role': 'qualified source model label; distinct from lexical do operator'}})
        refusals.append({'mode': key[0], 'domain': key[1], 'index': key[2], 'helper': c['helper'], 'subtest': c['subtest'],
                         'admitted_allocation_identity': identity(admitted), 'phases': phases, 'original_selection': None})
    need(not source_cases, 'independent complete source/admitted refusal population')
    unresolved = {k: v for k, v in recipes['unresolved'].items() if k != 'statement_hypotheses'}
    unresolved['whole_source_publication'] = (
        'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.2.2.3.2.2.3.3')
    return {'role': 'Ordered own-source refusal-phase statement hypotheses; original coordinates, private runtime meanings and alias downstream remain unmeasured.',
            'revision': REVISION, 'owner': owner, 'authorities': authorities, 'source_topology_identity': identity(modes),
            'refusals': refusals, 'statements': [copy.deepcopy(table[key]) for key in sorted(used)],
            'generation_custody': recipes['generation_custody'], 'invocation_custody': recipes['invocation_custody'],
            'public_examples': recipes['public_examples'], 'unresolved': unresolved}


def check(actual, wanted):
    need(set(actual) == set(wanted), 'complete phase product schema')
    for key in sorted(set(wanted) - {'refusals', 'statements'}):
        need(same(actual[key], wanted[key]), 'whole phase metadata: ' + key)
    need([s['id'] for s in actual['statements']] == [s['id'] for s in wanted['statements']], 'complete used statement domain')
    for candidate, expected in zip(actual['statements'], wanted['statements'], strict=True):
        need(set(candidate) == set(expected), 'complete bound statement schema')
        for key in expected:
            need(same(candidate[key], expected[key]), 'bound statement field: ' + key)
    need(len(actual['refusals']) == len(wanted['refusals']), 'complete phase refusal population')
    for candidate, expected in zip(actual['refusals'], wanted['refusals'], strict=True):
        need(set(candidate) == set(expected), 'complete refusal schema')
        for key in sorted(set(expected) - {'phases'}):
            need(same(candidate[key], expected[key]), 'refusal field: ' + key)
        need(len(candidate['phases']) == len(expected['phases']), 'complete refusal throw phases')
        for p, q in zip(candidate['phases'], expected['phases'], strict=True):
            need(set(p) == set(q), 'complete phase schema')
            for key in ('phase', 'family', 'source_topology_identity', 'origin', 'load'):
                need(same(p[key], q[key]), 'phase field: ' + key)
            need(len(p['active_path_inner_to_outer']) == len(q['active_path_inner_to_outer']), 'complete active caller path')
            for f, g in zip(p['active_path_inner_to_outer'], q['active_path_inner_to_outer'], strict=True):
                need(set(f) == set(g), 'complete caller frame schema')
                for key in g:
                    need(same(f[key], g[key]), 'caller frame field: ' + key)


def controls(wanted):
    outcomes = {}

    def hostile(name, mutate, cause):
        bad = copy.deepcopy(wanted)
        mutate(bad)
        try:
            check(bad, wanted)
        except ValueError as error:
            need(str(error) == cause, 'intended hostile phase predicate: ' + name + ': ' + str(error))
            outcomes[name] = cause
        else:
            raise ValueError('false-green phase control: ' + name)

    first = lambda x: x['refusals'][0]
    phase = lambda x: first(x)['phases'][0]
    call = lambda x: phase(x)['active_path_inner_to_outer'][0]
    nested = next(i for i, r in enumerate(wanted['refusals']) if len(r['phases']) == 2)
    hostile('omitted-refusal', lambda x:x['refusals'].pop(), 'complete phase refusal population')
    hostile('borrowed-mode', lambda x:first(x).update(mode='alias'), 'refusal field: mode')
    hostile('Boolean-index', lambda x:first(x).update(index=True), 'refusal field: index')
    hostile('borrowed-helper', lambda x:first(x).update(helper=999), 'refusal field: helper')
    hostile('borrowed-subtest', lambda x:first(x).update(subtest='borrowed'), 'refusal field: subtest')
    hostile('omitted-throw-phase', lambda x:x['refusals'][nested]['phases'].pop(), 'complete refusal throw phases')
    hostile('reversed-throw-phases', lambda x:x['refusals'][nested]['phases'].reverse(), 'phase field: phase')
    hostile('wrong-origin-guard', lambda x:phase(x)['origin']['caller'].update(recipe_id='admitted/qualified/1'), 'phase field: origin')
    hostile('wrong-family', lambda x:phase(x).update(family='parser'), 'phase field: family')
    hostile('omitted-caller', lambda x:phase(x)['active_path_inner_to_outer'].pop(), 'complete active caller path')
    hostile('wrong-callee', lambda x:call(x).update(callee='borrowed'), 'caller frame field: callee')
    hostile('wrong-role', lambda x:call(x).update(role='observer'), 'caller frame field: role')
    hostile('wrong-caller', lambda x:call(x)['caller'].update(recipe_id='value-capture'), 'caller frame field: caller')
    hostile('wrong-call-kind', lambda x:call(x).update(call_kind='eval'), 'caller frame field: call_kind')
    hostile('wrong-model-link', lambda x:call(x).update(model_links=[['core', 1]]), 'caller frame field: model_links')
    hostile('original-selection-promotion', lambda x:call(x)['caller'].update(original_selection='closing'), 'caller frame field: caller')
    hostile('lexical-load-operator', lambda x:phase(x)['load'].update(source_operator='require'), 'phase field: load')
    hostile('borrowed-root', lambda x:x.update(revision='0'*40), 'whole phase metadata: revision')
    hostile('source-topology-borrow', lambda x:x['source_topology_identity'].update(bytes=0), 'whole phase metadata: source_topology_identity')
    hostile('alias-owner-promotion', lambda x:x['unresolved'].pop('alias_downstream'), 'whole phase metadata: unresolved')
    hostile('generation-borrow', lambda x:x['generation_custody'].update(bytes=0), 'whole phase metadata: generation_custody')
    hostile('invocation-borrow', lambda x:x['invocation_custody'].update(bytes=0), 'whole phase metadata: invocation_custody')
    hostile('public-borrow', lambda x:x['public_examples'].update(bytes=0), 'whole phase metadata: public_examples')
    for key, value in (('source_path', 'borrowed.pm'), ('text', 'borrowed;'), ('lexical_owner', {'kind':'file','name':'borrowed'}),
                       ('line_alternatives', {'first': True, 'closing': 1}), ('filename_alternatives', ['borrowed.pm']),
                       ('equivalent_line_labels', [['invented']]), ('kind', 'named_extent'), ('original_selection', 'first')):
        hostile('statement-' + key, lambda x,k=key,v=value:x['statements'][0].update({k:v}), 'bound statement field: ' + key)
    bridge = next(i for i, f in enumerate(wanted['refusals'][nested]['phases'][0]['active_path_inner_to_outer'])
                  if f['role'] == 'nested_capture_eval')
    hostile('nested-capture-eval-omitted', lambda x:x['refusals'][nested]['phases'][0]['active_path_inner_to_outer'].pop(bridge),
            'complete active caller path')
    external = next(i for i, f in enumerate(phase(wanted)['active_path_inner_to_outer']) if f['call_kind'] == 'opaque_external')
    hostile('external-caller-invented', lambda x:phase(x)['active_path_inner_to_outer'][external]['caller'].update(recipe_id='callback/0'),
            'caller frame field: caller')
    return outcomes


def main():
    need(Path.cwd().resolve() == ROOT, 'invoke phase qualifier from repository root')
    wanted = expectation()
    check(json.loads((BASE / 'phases.json').read_bytes()), wanted)
    print(json.dumps({'result': 'PASS complete independent source-only phase allocation', 'controls': controls(wanted)}, sort_keys=True))


if __name__ == '__main__':
    main()

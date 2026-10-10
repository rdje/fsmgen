"""Whole independent construction qualification and genuine separating controls."""
import copy
import json
from pathlib import Path

BASE = Path('docs/audits/address-actor-construction-20261010')
SUCCESS = ('PASS complete partial actor construction, independent reached-pass graphs and original '
           'source bindings; local contexts and native identity remain open.\n')


def module(name):
    path = BASE / name
    namespace = {'__name__': 'actor_construction_qualification'}
    exec(compile(path.read_bytes(), str(path), 'exec'), namespace)
    return namespace


def load(name):
    return json.loads((BASE / name).read_bytes())


def main():
    source = module('source.py')
    inputs = load('inputs.json')
    actual = module('model.py')['derive'](inputs)
    retained = BASE / 'hypotheses.json'
    if retained.exists():
        if not source['same'](actual, load('hypotheses.json')):
            raise ValueError('whole retained deterministic actor construction hypotheses')
    else:
        retained.write_text(json.dumps(actual, sort_keys=True, indent=2) + '\n')
    # Qualify the serialized contract, so Python container aliases cannot couple controls.
    actual = load('hypotheses.json')
    qualify = module('oracle.py')['qualify']
    measured = qualify(actual, inputs)
    first = load('checks.json')['first-independent']
    require_first = (type(first['status']) is int and first['status'] == 1
        and first['instruments'][str(BASE / 'verify.py')]
            == source['identity']((BASE / 'first-verify.py.txt').read_bytes())
        and 'ValueError: complete original reached construction pass sequence' in first['stderr'])
    if not require_first:
        raise ValueError('whole actual first construction source-signature refusal')
    first_proof = load('first-complete-proof.json.txt')
    first_product = load('first-complete-hypotheses.json.txt')
    old_namespace = {'__name__': 'first_complete_construction_oracle'}
    old_path = BASE / 'first-complete-oracle.py.txt'
    exec(compile(old_path.read_bytes(), str(old_path), 'exec'), old_namespace)
    if not source['same'](old_namespace['qualify'](first_product, inputs), first_proof['measured']):
        raise ValueError('whole first complete construction oracle admission conservation')
    for name, pin in first_proof['programmes'].items():
        path = BASE / ('first-complete-' + name + '.txt') if name in ('model.py', 'oracle.py', 'verify.py') else BASE / name
        if source['identity'](path.read_bytes()) != pin:
            raise ValueError('whole first complete construction programme custody')
    prior = load('checks.json')['independent']
    if (type(prior['status']) is not int or prior['status'] != 0 or prior['stdout'] != SUCCESS
            or prior['instruments'][str(BASE / 'verify.py')] != first_proof['programmes']['verify.py']):
        raise ValueError('actual first complete construction qualification outcome')
    controls = []
    def rejects(name, mutate, expected):
        candidate = copy.deepcopy(actual)
        mutate(candidate)
        if source['same'](candidate, actual):
            raise ValueError('genuine actor construction candidate setup: ' + name)
        try:
            qualify(candidate, inputs)
        except ValueError as error:
            if str(error) != expected:
                raise ValueError('unintended actor control refusal: ' + name + ': ' + str(error)) from error
            controls.append({'name': name, 'refusal': str(error),
                'whole_candidate_identity': source['identity'](json.dumps(candidate, sort_keys=True).encode())})
        else:
            raise ValueError('genuine actor construction control admitted: ' + name)
    def profile(p, index=0):
        return p['profiles'][index]
    def case(p, index=0):
        return p['modes'][0]['cases'][index]
    def actor(p, index=0):
        return profile(p, index)['final']['graph'][1][2][1]
    graph_error = 'whole nested source graph topology/value/alias'
    holder_error = 'complete actor holders, returned delegates and entry bridge'
    rejects('lost-original-construction-profile', lambda p: p['profiles'].pop(),
            'complete actor construction profile population')
    rejects('lost-original-mode', lambda p: p['modes'].pop(), 'complete actor source mode population')
    rejects('lost-original-refusal', lambda p: p['modes'][0]['cases'].pop(),
            'complete original actor refusal population')
    rejects('lost-reached-pass-return', lambda p: profile(p)['events'].pop(),
            'complete reached pass entry/return membership')
    rejects('borrowed-actual-other-pass-stage', lambda p: profile(p)['events'].__setitem__(0,
            copy.deepcopy(profile(p)['events'][2])), 'complete reached pass entry/return order')
    rejects('borrowed-actual-other-parse-final', lambda p: profile(p)['final'].update(
            graph=copy.deepcopy(profile(p, 1)['final']['graph'])), graph_error)
    rejects('borrowed-actual-earlier-construction-graph', lambda p: profile(p)['final'].update(
            graph=copy.deepcopy(profile(p)['events'][0]['graph'])), graph_error)
    rejects('borrowed-actual-other-type-checkpoint', lambda p: profile(p)['type_checks'].__setitem__(0,
            copy.deepcopy(profile(p, 1)['type_checks'][0])), graph_error)
    rejects('borrowed-actual-other-parse-AST-only', lambda p: profile(p)['final']['graph'][1].__setitem__(
            1, copy.deepcopy(profile(p, 1)['final']['graph'][1][1])), graph_error)
    rejects('lost-admission-checkpoint', lambda p: profile(p)['type_checks'].pop(),
            'complete type admission checkpoint population')
    rejects('borrowed-actual-refusal-stage', lambda p: profile(p)['final'].update(
            point=profile(p, 1)['final']['point']), 'exact source refusal construction stage')
    rejects('lost-complete-actor-member', lambda p: actor(p).pop('clock_domains'), graph_error)
    rejects('wrong-complete-actor-value', lambda p: actor(p).update(actor_network={}),
            'nested qualified graph grammar')
    rejects('equal-payload-type-declaration-alias-merge', lambda p:
            actor(p)['type_declarations'][1].__setitem__(0, ['reference', '/1/2/1']), graph_error)
    def lose_let_clone(p):
        event = next(row for row in profile(p)['events']
                     if row['pass'] == '_expand_let_bindings' and row['boundary'] == 'return')
        event['graph'][1][2][1]['transactions'][1][0][1]['clauses'][1][0] = ['reference', '/1/4/2']
    rejects('equal-payload-let-clause-copy-erased', lose_let_clone, graph_error)
    def split_procedure_alias(p):
        event = next(row for row in profile(p)['events']
                     if row['pass'] == '_expand_procedure_calls' and row['boundary'] == 'return')
        event['graph'][1][3] = copy.deepcopy(event['graph'][1][2][1]['transactions'][1][0][1]['clauses'])
    rejects('equal-payload-procedure-noop-clause-alias-split', split_procedure_alias, graph_error)
    rejects('equal-payload-record-port-symbol-alias-merge', lambda p:
            actor(p)['type_symbols'][1]['local'][1].update(frame=['reference', '/2/interface/outputs/0/type_spec']),
            graph_error)
    rejects('equal-payload-list-admission-clone-erased', lambda p: profile(p, 1)['final']['graph'][1].__setitem__(
            3, ['reference', '/2/type_symbols/local/lanes']), graph_error)
    rejects('equal-payload-distinct-list-bit-members-merged', lambda p:
            actor(p)['type_symbols'][1]['local'][1]['lanes'][1]['items'][1].__setitem__(
                1, ['reference', '/2/type_symbols/local/lanes/items/0']), graph_error)
    rejects('rejected-list-width-prematurely-published', lambda p:
            actor(p, 1)['interface'][1]['inputs'][1][0][1].update(width=2), graph_error)
    rejects('rejected-list-type-prematurely-published', lambda p:
            actor(p, 1)['interface'][1]['inputs'][1][0][1].update(type_spec=copy.deepcopy(
                actor(p, 1)['type_symbols'][1]['local'][1]['lanes'])), graph_error)
    rejects('lost-complete-receiver-field', lambda p:
            profile(p)['final']['graph'][1][0][1]['parser'][1].pop('debug'), graph_error)
    rejects('wrong-contained-receiver-class', lambda p: profile(p)['final']['classes'].update(
            {'/0/parser/adapter': profile(p)['final']['classes']['/0/parser']}),
            'whole own construction receiver class fields')
    rejects('lost-original-actor-slot', lambda p: case(p)['occurrences'].pop(),
            'every original actor/entry/clause source slot exactly once')
    rejects('borrowed-existing-other-parse-actor-binding', lambda p: case(p)['occurrences'][0].update(
            binding=case(p, 1)['occurrences'][0]['binding']),
            'every original actor/entry/clause source slot exactly once')
    rejects('borrowed-existing-interface-entry-for-actor', lambda p: case(p, 1)['occurrences'][0].update(
            binding=case(p, 1)['occurrences'][1]['binding']),
            'every original actor/entry/clause source slot exactly once')
    rejects('lost-explicit-local-context-slot', lambda p: case(p)['pending'].pop(),
            'complete explicitly pending local context membership')
    rejects('lost-inherited-entry-slot', lambda p: case(p)['inherited_occurrences'].pop(),
            'complete inherited original parser frames and slots')
    rejects('Boolean-original-phase', lambda p: case(p)['domain'].__setitem__(3, False),
            'exact original actor record/phase domain')
    rejects('borrowed-existing-other-mode-binding-origin', lambda p: p['modes'][0]['bindings'].update({
            'parse:2:node:/2': copy.deepcopy(p['modes'][1]['bindings']['parse:2:node:/2'])}),
            'complete actor binding origins/kinds and membership')
    rejects('wrong-actor-reference-kind', lambda p: p['modes'][0]['bindings']['parse:2:node:/2'].update(
            reference_kind='ARRAY'), 'complete actor binding origins/kinds and membership')
    rejects('lost-complete-actor-graph-binding', lambda p: case(p)['final_graph_bindings'].pop('/2'),
            'complete actor joint graph binding bridge')
    rejects('previous-refusal-caller-holder-lost', lambda p: case(p, 1)['held'].remove('parse:2:caller'), holder_error)
    rejects('hidden-active-resolved-list-clone-holder-lost', lambda p:
            case(p, 1)['held'].remove('parse:3:node:/3'), holder_error)
    rejects('lost-held-source-distinction', lambda p: case(p)['simultaneously_held_distinct'].pop(), holder_error)
    rejects('returned-construction-pass-reactivated', lambda p: case(p)['active_own_calls'].append(
            '_expand_let_bindings'), holder_error)
    rejects('borrowed-actual-other-refusal-type-phase-bridge', lambda p: case(p)['type_checkpoint_bridge'].update(
            refusal=case(p, 1)['type_checkpoint_bridge']['refusal']), holder_error)
    rejects('pure-predicate-reactivated-at-original-refusal', lambda p: case(p)['active_own_calls'].append(
            '_is_aggregate_type_spec'), holder_error)
    rejects('observer-retention-promoted-to-original-holder', lambda p: case(p)['held'].append(
            'fresh-observer-old-clauses'), holder_error)
    rejects('lost-entry-source-holder-bridge', lambda p: case(p)['entry_bridge'].pop('adapter'), holder_error)
    rejects('partial-entry-conservation', lambda p: p['preserved_entry']['modes'][0]['cases'].pop(),
            'whole corrected entry model conservation')
    rejects('unqualified-original-native-promotion', lambda p: p.update(scope='Original native identities measured'),
            'actor construction source-only scope')
    fresh, custody = source['rebuild']()
    if not source['same'](fresh, inputs) or not source['same'](custody, load('binding.json')):
        raise ValueError('whole fresh corrected prerequisite, original source epochs and construction custody')
    proof = {'binding': custody, 'measured': measured, 'controls': controls,
        'first_complete_qualification': {'proof': source['identity']((BASE / 'first-complete-proof.json.txt').read_bytes()),
            'product': source['identity']((BASE / 'first-complete-hypotheses.json.txt').read_bytes()),
            'scope': 'Whole first complete admission and programmes retain. Final qualification makes the pure-predicate probe-to-refusal bridge explicit and adds borrowed AST and phase controls.'},
        'first_refusal': {'oracle': source['identity']((BASE / 'first-oracle.py.txt').read_bytes()),
            'verifier': source['identity']((BASE / 'first-verify.py.txt').read_bytes()),
            'cause': 'The first source check expected a positional call; the original context validator takes named actor and whole_output_writes_only arguments.',
            'repair': 'Check the exact original named-argument call; retain the failed programme and actual nonzero outcome.'},
        'actual_borrowed_witnesses': {'other_parse': case(actual, 1)['domain'], 'other_mode': actual['modes'][1]['mode'],
            'earlier_pass': profile(actual)['events'][0]['pass'],
            'other_admission_kind': profile(actual, 1)['type_checks'][0]['graph'][1][3][1]['kind']},
        'programmes': {name: source['identity']((BASE / name).read_bytes())
            for name in ('source.py', 'model.py', 'oracle.py', 'verify.py', 'public_construction.pl')}}
    target = BASE / 'proof.json'
    if target.exists() and not source['same'](proof, load('proof.json')):
        raise ValueError('whole actor construction source proof; never overwrite')
    if not target.exists():
        target.write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    print(SUCCESS, end='')


if __name__ == '__main__':
    main()

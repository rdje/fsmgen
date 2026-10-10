"""Whole original source joins, independent hostile controls and fresh custody."""
import copy
import json
from pathlib import Path

BASE = Path('docs/audits/address-parser-context-closure-20261010')
SUCCESS = ('PASS complete original parser/context and helper source closure; '
           'full source integration and original native identity remain open.\n')


def module(name):
    path = BASE / name
    ns = {'__name__': 'original_context_closure_qualification'}
    exec(compile(path.read_bytes(), str(path), 'exec'), ns)
    return ns


def load(name):
    return json.loads((BASE / name).read_bytes())


def main():
    source, oracle = module('source.py'), module('oracle.py')
    inputs = load('inputs.json')
    product = module('model.py')['derive'](inputs)
    target = BASE / 'hypotheses.json'
    if target.exists() and not oracle['exact'](product, load('hypotheses.json')):
        raise ValueError('whole retained deterministic original context source product')
    if not target.exists():
        target.write_text(json.dumps(product,sort_keys=True,indent=2)+'\n')
    product = load('hypotheses.json')
    qualify = oracle['qualify']
    measured = qualify(product, inputs)
    first = load('first-join-proof.json.txt')
    for name, pin in first['programmes'].items():
        frozen = BASE / ('first-join-'+name+'.txt')
        if source['identity'](frozen.read_bytes()) != pin:
            raise ValueError('whole first complete original join programme custody')
    old_ns = {'__name__': 'first_complete_original_context_join'}
    old_path = BASE / 'first-join-oracle.py.txt'
    exec(compile(old_path.read_bytes(),str(old_path),'exec'),old_ns)
    if not oracle['exact'](old_ns['qualify'](load('first-join-hypotheses.json.txt'),inputs),first['measured']):
        raise ValueError('complete first original join admission conservation')
    outcome = load('checks.json')['first-join']
    if (type(outcome['status']) is not int or outcome['status'] != 0
            or outcome['stdout'] != 'PASS complete first original parser/context source join; independent separating controls remain required.\n'
            or outcome['instruments'][str(BASE/'qualify.py')] != first['programmes']['qualify.py']):
        raise ValueError('actual complete first original context join outcome')
    first_full = load('first-complete-proof.json.txt')
    if not oracle['exact'](old_ns['qualify'](load('first-complete-hypotheses.json.txt'),inputs),first_full['measured']):
        raise ValueError('whole first complete source closure admission conservation')
    for name, pin in first_full['programmes'].items():
        path = BASE / ('first-verify.py.txt' if name=='verify.py' else 'first-join-'+name+'.txt')
        if source['identity'](path.read_bytes()) != pin:
            raise ValueError('whole first complete source closure programme custody')
    first_outcome = load('checks.json')['independent']
    if (type(first_outcome['status']) is not int or first_outcome['status'] != 0 or first_outcome['stdout'] != SUCCESS
            or first_outcome['instruments'][str(BASE/'verify.py')] != first_full['programmes']['verify.py']):
        raise ValueError('actual first complete source closure admission outcome')
    gap = load('returned-delegate-gap.json')
    old_case = load('first-complete-hypotheses.json.txt')['modes'][0]['cases'][0]
    if ('clone_structured_value' in old_case['returned_context_delegates']
            or first_full['measured']['api_kinds']['structured-clone'] != 240
            or gap['missing'] != 'clone_structured_value' or gap['first_join_status'] != 0):
        raise ValueError('genuine first complete returned clone delegate omission')
    syntax = load('first-syntax-failure.json')
    if (type(syntax['status']) is not int or syntax['status'] != 1
            or syntax['programme'] != source['identity']((BASE/'first-oracle.py.txt').read_bytes())
            or 'SyntaxError: invalid syntax' not in syntax['stderr']):
        raise ValueError('actual first unqualified source-string syntax failure custody')
    controls = []
    def rejects(name, mutate, expected):
        candidate = copy.deepcopy(product)
        mutate(candidate)
        if oracle['exact'](candidate, product):
            raise ValueError('genuine original context candidate setup: '+name)
        try:
            qualify(candidate, inputs)
        except ValueError as error:
            if str(error) != expected:
                raise ValueError('unintended original context refusal: '+name+': '+str(error)) from error
            controls.append({'name':name,'refusal':str(error),
                'whole_candidate':source['identity'](json.dumps(candidate,sort_keys=True).encode())})
        else:
            raise ValueError('original context control admitted: '+name)
    def case(p, mode=0, index=0):
        return p['modes'][mode]['cases'][index]
    def api(p, kind, occurrence=0):
        return [r for r in case(p)['api_witnesses'] if r['kind']==kind][occurrence]
    def emit(node):
        seen = {}
        def visit(item,path):
            if not isinstance(item,oracle['Node']):
                return item
            if item in seen:
                return ['reference',seen[item]]
            seen[item] = path
            def at(key):
                return visit(item.edges[key],path+'/'+key.replace('~','~0').replace('/','~1'))
            if item.kind=='HASH':
                return ['hash',{k:at(k) for k in sorted(item.edges)}]
            return ['array',[at(str(i)) for i in range(len(item.edges))]]
        return visit(node,'')
    def witness_edit(p, kind, part, mutate, occurrence=0):
        row = api(p,kind,occurrence)
        root = oracle['graph'](row[part]);mutate(root);row[part] = emit(root)
    holder = 'complete context holders, lifecycle and original-source bridges'
    slots = 'every original parser source reference exactly once'
    topology = 'whole original protocol source topology/value/alias'
    numeric = 'whole original protocol numeric source meaning'
    allocation = 'exact original context API witness allocation'
    order = 'whole original context API source order/kind/site/status'
    rejects('lost-original-mode',lambda p:p['modes'].pop(),'complete parser context mode population')
    rejects('borrowed-actual-other-mode',lambda p:p['modes'].__setitem__(0,copy.deepcopy(p['modes'][1])),
            'exact original context mode allocation')
    rejects('lost-original-refusal',lambda p:p['modes'][0]['cases'].pop(),'complete original parser case population')
    rejects('borrowed-actual-other-refusal-domain',lambda p:case(p).update(domain=copy.deepcopy(case(p,index=1)['domain'])),
            'exact original parser context record/phase domain')
    rejects('Boolean-original-phase',lambda p:case(p)['domain'].__setitem__(3,False),
            'exact original parser context record/phase domain')
    rejects('lost-original-context-slot',lambda p:case(p)['occurrences'].pop(),slots)
    rejects('lost-inherited-parser-slot',lambda p:case(p)['occurrences'].pop(0),slots)
    rejects('duplicate-original-context-slot',lambda p:case(p)['occurrences'].append(copy.deepcopy(case(p)['occurrences'][-1])),slots)
    rejects('borrowed-actual-actor-for-context-slot',lambda p:case(p)['occurrences'][-1].update(
            binding=case(p)['final_graph_bindings']['/2']),slots)
    rejects('borrowed-actual-other-mode-context-binding',lambda p:p['modes'][0]['bindings'].update({
            case(p)['occurrences'][-1]['binding']:copy.deepcopy(p['modes'][1]['bindings'][case(p)['occurrences'][-1]['binding']])}),
            'complete parser context binding origins/kinds/membership')
    rejects('unresolved-original-context-slot-returned',lambda p:case(p)['pending'].append(
            copy.deepcopy(inputs['boundary_inputs']['construction_model']['modes'][0]['cases'][0]['pending'][0])),slots)
    rejects('lost-context-API-witness',lambda p:case(p)['api_witnesses'].pop(),
            'every original context API witness exactly once')
    rejects('borrowed-actual-other-API-witness',lambda p:case(p)['api_witnesses'].__setitem__(0,
            copy.deepcopy(case(p)['api_witnesses'][1])),allocation)
    rejects('Boolean-original-API-index',lambda p:case(p)['api_witnesses'][0].update(index=True),allocation)
    rejects('wrong-original-API-kind',lambda p:api(p,'scope').update(kind='capture'),order)
    rejects('borrowed-actual-other-call-site',lambda p:api(p,'scope').update(caller=copy.deepcopy(api(p,'capture')['caller'])),order)
    rejects('Boolean-original-API-success',lambda p:api(p,'scope').update(accepted=True),order)
    rejects('original-API-warning-erased',lambda p:api(p,'scope').update(warnings=['unexpected warning']),order)
    rejects('lost-complete-capture-input-member',lambda p:witness_edit(p,'capture','before',lambda r:
            r.edges['0'].edges.pop('outputs')),topology)
    rejects('wrong-complete-capture-width',lambda p:witness_edit(p,'capture','before',lambda r:
            r.edges['0'].edges['inputs'].edges['0'].edges.update(width=2)),numeric)
    rejects('noncanonical-capture-width',lambda p:witness_edit(p,'capture','before',lambda r:
            r.edges['0'].edges['inputs'].edges['0'].edges.update(width='01')),numeric)
    rejects('Boolean-capture-width',lambda p:witness_edit(p,'capture','before',lambda r:
            r.edges['0'].edges['inputs'].edges['0'].edges.update(width=True)), 'nested qualified graph grammar')
    rejects('lost-snapshot-result-member',lambda p:witness_edit(p,'snapshot','result',lambda r:
            r.edges['0'].edges.pop('type_kind')),topology)
    rejects('wrong-packed-range-width',lambda p:witness_edit(p,'range','result',lambda r:r.edges.update(width=2)),numeric)
    def scalar_clone(p):
        return next(r for r in case(p)['api_witnesses'] if r['kind']=='structured-clone'
                    and r['before'][1][1] in (0,1,'0','1'))
    rejects('wrong-recursive-numeric-clone-leaf',lambda p:scalar_clone(p).update(result=2),numeric)
    def text_clone(p):
        return next(r for r in case(p)['api_witnesses'] if r['kind']=='structured-clone'
                    and r['before'][1][1]=='bits')
    rejects('recursive-text-clone-normalized',lambda p:text_clone(p).update(result=1),topology)
    rejects('lost-original-API-bridge',lambda p:case(p)['original_api_bridge'].pop(),holder)
    rejects('borrowed-actual-other-API-source-event',lambda p:case(p)['original_api_bridge'][0].update(
            source_event=case(p)['original_api_bridge'][1]['source_event']),holder)
    rejects('lost-original-private-copy-bridge',lambda p:case(p)['original_private_bridge'].pop(),holder)
    rejects('borrowed-actual-other-private-copy',lambda p:case(p)['original_private_bridge'][0].update(
            probe_copy=case(p)['original_private_bridge'][1]['probe_copy']),holder)
    caller = next(k for k in case(product)['held'] if ':api-caller:' in k)
    private_caller = next(k for k in case(product)['held'] if ':private-caller:' in k)
    rejects('later-refusal-previous-context-caller-lost',lambda p:case(p,index=1)['held'].remove(caller),holder)
    rejects('active-refusal-private-caller-lost',lambda p:case(p)['held'].remove(private_caller),holder)
    rejects('lost-retained-context-caller-list-member',lambda p:case(p)['retained_context_callers'].pop(),holder)
    rejects('lost-complete-source-distinction',lambda p:case(p)['source_distinctions'].update(
            count=case(p)['source_distinctions']['count']-1),holder)
    rejects('Boolean-source-distinction-count',lambda p:case(p)['source_distinctions'].update(count=True),holder)
    rejects('lost-compact-relation-member',lambda p:case(p)['source_distinctions']['members'].pop(),holder)
    rejects('sample-result-promoted-to-active-holder',lambda p:case(p)['active_roots'].append('/5/0'),holder)
    rejects('returned-context-delegate-reactivated',lambda p:case(p)['inactive_intermediates']['contexts'].clear(),holder)
    rejects('lost-actual-recursive-clone-returned-delegate',lambda p:case(p)['returned_context_delegates'].remove('clone_structured_value'),holder)
    rejects('lost-resolve-returned-delegate',lambda p:case(p)['returned_context_delegates'].remove('resolve'),holder)
    rejects('lost-successful-returned-API-event',lambda p:case(p)['returned_api_events']['original_apis'].pop(),holder)
    rejects('lost-returned-context-delegate',lambda p:case(p)['returned_context_delegates'].pop(),holder)
    rejects('lost-previous-parser-holder-bridge',lambda p:case(p)['construction_bridge'].pop('saved-parse-source'),holder)
    key = case(product)['occurrences'][-1]['binding']
    rejects('wrong-context-reference-kind',lambda p:p['modes'][0]['bindings'][key].update(reference_kind='ARRAY'),
            'complete parser context binding origins/kinds/membership')
    rejects('partial-corrected-boundary-conservation',lambda p:p['preserved_boundary']['public']['steps'].pop(),
            'whole corrected construction conservation')
    rejects('partial-helper-population-conservation',lambda p:p['preserved_helper']['modes'].pop(),
            'whole corrected helper population conservation')
    rejects('premature-whole-integration-closure',lambda p:p['closure'].update(open='all original native identity proved'),
            'complete helper/parser source closure and explicit open scopes')
    rejects('borrowed-existing-sample-context-for-original-slot',lambda p:case(p)['occurrences'][-1].update(binding=case(p)['final_graph_bindings']['/3/2']),slots)
    rejects('observer-call-argument-promoted-to-source-holder',lambda p:case(p)['held'].append('/9/0/arguments'),holder)
    rejects('original-native-scope-promotion',lambda p:p.update(scope='Original native addresses measured'),
            'parser context source-only scope')
    fresh,binding = source['rebuild']()
    if not oracle['exact'](fresh,inputs) or not oracle['exact'](binding,load('binding.json')):
        raise ValueError('whole fresh original context source/custody conservation')
    proof={'binding':binding,'measured':measured,'controls':controls,
        'first_complete_join':{'proof':source['identity']((BASE/'first-join-proof.json.txt').read_bytes()),
                              'product':source['identity']((BASE/'first-join-hypotheses.json.txt').read_bytes())},
        'first_syntax_failure':syntax,
        'first_complete_qualification': {'proof':source['identity']((BASE/'first-complete-proof.json.txt').read_bytes()),
            'product':source['identity']((BASE/'first-complete-hypotheses.json.txt').read_bytes()),
            'gap':gap,'repair':'Derive API delegate names from the independently verified API event kinds and retain every successful returned API event; clone/removal controls reject.'},
        'programmes':{name:source['identity']((BASE/name).read_bytes()) for name in (
            'source.py','model.py','oracle.py','runtime.py','qualify.py','verify.py')},
        'scope':'Complete original parser/helper source closure; all API numeric permissions follow own numeric fields, including scalar recursive clone leaves. Exact original typed witnesses conserve. Full source/raw integration, native identity/flags, cold replay and canonical publication remain open.'}
    target=BASE/'proof.json'
    if target.exists() and not oracle['exact'](proof,load('proof.json')):
        raise ValueError('whole retained original context source proof; never overwrite')
    if not target.exists():
        target.write_text(json.dumps(proof,sort_keys=True,indent=2)+'\n')
    print(SUCCESS,end='')


if __name__=='__main__':
    main()

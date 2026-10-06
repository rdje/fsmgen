"""Select the complete joint source contract before original trace intake."""
import copy
FAMILIES = {
    'value': 'FSM::Support::ISFRecordPortValues::',
    'metadata': 'FSM::Support::ISFInterfacePortMetadata::',
    'context': 'FSM::Support::ISFRecordPortContexts::',
    'parser': 'FSM::Adapter::ISF::Parser::',
}


def family(function, require):
    matches = [name for name, prefix in FAMILIES.items() if function.startswith(prefix)]
    require(len(matches) == 1, 'unique independently declared source guard namespace')
    return matches[0]


def derive(classes, public, require, same):
    # Topology/class associations derive from qualified source/input models.
    # A qualified inherited model retains the whole serialized inner operand;
    # it is opaque evidence, not an independently generated formatter oracle.
    # Current public fixtures select public-interface hypotheses separately.
    source = classes['source_contracts'](); classes['check_sources'](source)
    class_modes = classes['expected_models']()
    frame_model = public['model']['derive'](public['context'], public['fixture'], public['profile'], require, same)
    modes = []
    for class_mode, owned, published in zip(class_modes, frame_model['own']['modes'], frame_model['public_modes'], strict=True):
        require(class_mode['mode'] == owned['mode'] == published['mode'], 'complete independent class/frame source mode join')
        classes_by_key = {(r['domain'], r['index']):r for r in class_mode['cases']}
        public_by_key = {(r['domain'], r['index']):r for r in published['cases']}
        require(len(classes_by_key) == len(class_mode['cases']) and set(classes_by_key) == set(public_by_key)
            == {(r['domain'], r['index']) for r in owned['cases']}, 'complete independent class/frame source refusal partition')
        cases = []
        for case in owned['cases']:
            key = case['domain'], case['index']; exception = classes_by_key[key]; boundary = public_by_key[key]
            phases = []
            for path, interface in zip(case['phases'], boundary['phases'], strict=True):
                name = family(path['core'][0]['function'], require)
                declaration = classes['GUARDS'][name]
                phases.append(dict(phase=path['phase'], family=name, inferred_class=classes['CLASS'],
                    guard_source=dict(path=declaration[0], prefix=declaration[1], literal=declaration[2]),
                    own=copy.deepcopy(path), public=copy.deepcopy(interface),
                    native_class='source/publisher inference only; original pre-serialization class and hooks unmeasured'))
            require([r['phase'] for r in phases] == list(range(len(phases))), 'complete ordered source throw-phase domain')
            cases.append(dict(domain=case['domain'], index=case['index'], helper=case['helper'], caller=case['caller'],
                kind=case['kind'], subtest=case['subtest'], exception=copy.deepcopy(exception), phases=phases))
        modes.append(dict(mode=owned['mode'], cases=cases))
    return dict(class_sources=source, class_modes=class_modes, frame_model=frame_model, modes=modes,
        scope='Independent finite source class/guard/phase/path/argument associations from qualified models; inherited serialized inner operands and current public fixtures retain their explicit evidence roles. Original pre-serialization class, hooks, formatter, coordinates and referent identities are unmeasured.')

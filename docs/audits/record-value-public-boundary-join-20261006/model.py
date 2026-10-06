"""Fix public hypotheses from own source and independent current fixtures."""
PUBLIC = ['Test::Builder::subtest', 'Test::More::subtest']


def derive(context, fixture, profile, require, same):
    # This function never consumes the original raw frame population.
    own = context['models']()
    published = profile['model']['derive'](profile['load'](profile['BASE'] / 'public-profile.json'), require)
    require(all(key in published for key in ('caller_block_eval', 'caller_require_use',
        'more_subtest', 'more_arguments', 'builder_subtest', 'builder_arguments')),
        'complete selected public boundary contracts')
    current = fixture['load'](fixture['BASE'] / 'native.json')
    fixture['check'](current)
    import json
    callbacks = [r for r in json.loads(current['stdout'])['observations'] if r['role'] in ('more-empty', 'more-extra')]
    paths = [[f[3] for f in row['frames'] if f[3] in PUBLIC] for row in callbacks]
    require(paths == [PUBLIC, PUBLIC], 'independent current public named callback boundary path')
    modes = []
    for mode in own['modes']:
        cases = []
        for case in mode['cases']:
            phases = []
            for phase in case['phases']:
                phases.append(dict(phase=phase['phase'], public_path=PUBLIC,
                    public_name=dict(kind='scalar', role='authored_subtest_name', value=case['subtest']),
                    callback=dict(kind='reference', role='callback_kind_only', reference_kind='CODE'),
                    receiver='whole visible token retained; contents/class/identity unmeasured',
                    own_eval_boundaries=[op['frames'] for op in phase['operations']],
                    body=phase['body'], entry=phase['entry'], load=phase['load'],
                    source_operator='do', historical_profile='unmeasured',
                    relationship='finite original header/source agreement with independently exercised current public interfaces; private delegation semantics unmeasured'))
            cases.append(dict(domain=case['domain'], index=case['index'], helper=case['helper'],
                subtest=case['subtest'], phases=phases))
        modes.append(dict(mode=mode['mode'], cases=cases))
    return dict(own=own, public_modes=modes, current_public_paths=paths, contracts=published,
                historical='No current-profile identity or private framework/eval purpose is attributed to the original capture.')

"""Compose qualified source roles before selecting any recorded frame."""


def derive(readers, require, same):
    argument, observer, helper, subtest = (readers[k] for k in ('argument', 'observer', 'helper', 'subtest'))
    api = observer['api']
    sources = {'api': api['sources'](), 'observer': observer['sources'](),
               'helper': helper['prior']['sources']()}
    require(all(sources['observer'][key] == sources['helper'][key]
                for key in ('observer', 'test', 'facade')), 'whole common source cohort')
    parser = argument['models']()
    order = argument['prior']['source_models']()
    api_modes = api['expected_models'](sources['api'])
    observer_modes = observer['expected_models'](sources['observer'])
    helper_modes = helper['expected_models'](sources['helper'])
    subtest_models = subtest['expected_models'](sources['helper'])
    inherited_modes = api['inherited']['expected_models'](sources['api']['inherited'])
    parser_source = argument['prior']['module'](argument['prior']['MODELS'] / 'verify.py')
    nested = parser_source['nested_allocations']()
    products_reader = argument['prior']['module'](
        argument['prior']['MODELS'].parent / 'record-value-original-products-20261005/verify.py')
    products = products_reader['load'](products_reader['PRODUCTS'] / 'products.json')
    for allocation in nested:
        actor = products['actors'][allocation['parse_index']]
        allocation['dated_bounds'] = [actor['whole_native'][key] for key in ('api_start', 'api_end')]
        allocation['bounds_role'] = 'Conserve qualified dated operation allocation; not raw source coordinates.'
        require([row['index'] for row in allocation['source_API_members']]
                == list(range(*allocation['dated_bounds'])), 'complete source nested operation bounds')
    modes = []
    for owned_api, observed, helpers, subtests, inherited in zip(
            api_modes, observer_modes, helper_modes, subtest_models['modes'], inherited_modes, strict=True):
        require(len({row['mode'] for row in (owned_api, observed, helpers, subtests, inherited)}) == 1,
                'complete source composite mode join')
        api_cases = {row['index']: row for row in owned_api['cases']}
        helper_cases = {(row['domain'], row['index']): row for row in helpers['cases']}
        subtest_cases = {(row['domain'], row['index']): row for row in subtests['cases']}
        pairs = {pair['scope_api']: pair for pair in inherited['pairs']}
        cases = []
        for domain in ('api', 'parses'):
            for operation in observed[domain]:
                key = domain, operation['index']
                helper_case, subtest_case = helper_cases[key], subtest_cases[key]
                require(operation['helper'] == helper_case['helper'] == subtest_case['helper']
                        and helper_case['phases'] == subtest_case['phases'],
                        'source composite helper/subtest allocation and phases')
                boundaries = operation['boundaries']
                if domain == 'parses':
                    core = next(path['frames'] for path in parser if path['parse_index'] == operation['index'])
                    require(helper_case['phases'] == len(boundaries) == 1
                            and core[-1]['function'] == boundaries[0]['frames'][0]['function'],
                            'source parser facade/observer overlap')
                    core_phases, boundary_phases = [core], [boundaries]
                else:
                    case = api_cases[operation['index']]
                    core = case['frames']
                    if 'Value.failed_capture_eval' in case['guards']:
                        pair = pairs[case['index']]
                        outer = api['own'](pair['new_outer_path'])
                        outer_operations = sum(frame['function'] == 'main::call_api'
                                               for frame in pair['new_outer_path'])
                        require(helper_case['phases'] == 2 and outer and outer_operations == 1
                                and same(core[-len(outer):], outer) and len(boundaries) > outer_operations,
                                'source inherited new-throw phase partition')
                        core_phases = [core[:-len(outer)], outer]
                        boundary_phases = [boundaries[:-outer_operations], boundaries[-outer_operations:]]
                    else:
                        require(helper_case['phases'] == 1, 'source single-throw phase partition')
                        core_phases, boundary_phases = [core], [boundaries]
                phases = []
                for number, (frames, operations, helper_path) in enumerate(zip(
                        core_phases, boundary_phases, helper_case['paths'], strict=True)):
                    require(frames and operations, 'complete source composite phase')
                    phases.append({'phase': number, 'core': frames, 'operations': operations,
                                   'helper': helper_path, 'body': subtest_case['body_frames'],
                                   'entry': subtest_case['entry_frames'], 'load': subtest_case['load_marker']})
                cases.append({'domain': domain, 'index': operation['index'], 'kind': operation['kind'],
                              'helper': helper_case['helper'], 'caller': operation['caller_context'],
                              'subtest': subtest_case['name'], 'phases': phases})
        require(set(helper_cases) == set(subtest_cases)
                == {(row['domain'], row['index']) for row in cases}, 'complete source composite refusal partition')
        modes.append({'mode': owned_api['mode'], 'cases': cases})
    return {'sources': sources, 'parser': parser, 'order': order, 'api': api_modes,
            'observer': observer_modes, 'helper': helper_modes, 'subtest': subtest_models,
            'nested': nested, 'modes': modes}

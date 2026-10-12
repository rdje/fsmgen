"""Independently consume every source-first context/cause/consumer relationship."""
import argparse
from association_inputs import *

SUCCESS = 'PASS independent complete original context/cause/coordinate/consumer associations; original native/private limits and higher owners retain.\n'
OP_KEYS = {'record', 'native', 'cause', 'source', 'context', 'helper_context', 'parser_context',
           'api_record', 'primary', 'status', 'product', 'raw', 'semantic'}


def legacy(value):
    return pin(json.dumps(value, sort_keys=True, separators=(',', ':')).encode())


def memberships(contexts, key, population):
    result = {}
    for index, helper in enumerate(contexts['source_helpers']):
        need(type(helper['index']) is int and helper['index'] == index, 'ordered qualified source helper allocation')
        for member in helper[key]:
            need(type(member) is int and 0 <= member < population and member not in result,
                 'unique complete source-context operation ownership')
            result[member] = index
    return result


def parser_memberships(contexts, population):
    result = {}
    for index, parser in enumerate(contexts['parsers']):
        need(type(parser['index']) is int and parser['index'] == index, 'ordered qualified source parser allocation')
        for member in parser['api_members']:
            need(type(member) is int and 0 <= member < population and member not in result,
                 'unique complete source-parser API ownership')
            result[member] = index
    return result


def raw_roles(proposed, qualified, native, mode, domain, index, data):
    error = native['error']
    need(type(error) is str, 'whole original error wire string')
    if error == '':
        need(proposed['raw'] is None and proposed['semantic'] is None
             and qualified['raw'] is None and qualified['semantic'] is None,
             'empty own operation cannot borrow nonempty raw or coordinate roles')
        return
    raw, semantic = proposed['raw'], proposed['semantic']
    expected_raw, expected_semantic = qualified['raw'], qualified['semantic']
    need(type(raw) is dict and set(raw) == set(expected_raw) and type(raw['body']) is str
         and type(raw['segments']) is list
         and all(type(segment) is dict and type(segment.get('raw')) is str for segment in raw['segments']),
         'closed complete original raw association shape')
    need(raw['body'] == error and same(raw['body_identity'], pin(error.encode()))
         and same(raw['context'], context(native))
         and ''.join(segment['raw'] for segment in raw['segments']) == error,
         'whole lossless own raw body context and physical segments')
    need(same(raw, expected_raw), 'whole own raw wire and opaque address lexemes')
    need(type(semantic) is dict and set(semantic) == set(expected_semantic)
         and type(semantic['first_cause']) is dict
         and type(semantic['first_cause'].get('index')) is int
         and same(semantic['record'], [mode, domain, index])
         and semantic['first_cause'].get('domain') == domain
         and semantic['first_cause']['index'] == index
         and same(semantic['first_cause'].get('primary'), qualified['primary'])
         and same(semantic['context'], context(native)), 'own source-first nonempty cause and context')
    need(same(semantic['first_cause'], expected_semantic['first_cause'])
         and same(semantic['phases'], expected_semantic['phases']),
         'whole qualified ordered source phase class and coordinate roles')
    need(same(semantic['stack'], expected_semantic['stack'])
         and same(semantic['stack']['body'], pin(error.encode())), 'whole qualified stack and physical coordinates')
    need(same(semantic['opaque'], expected_semantic['opaque'])
         and same(semantic['observer'], expected_semantic['observer']),
         'whole own qualified address allocation opaque and observer roles')
    forwarding = semantic['forwarding']
    if expected_semantic['forwarding'] is None:
        need(forwarding is None, 'absent nested association cannot borrow forwarding')
    else:
        need(type(forwarding) is dict and set(forwarding) == set(expected_semantic['forwarding']),
             'closed complete nested association')
        inner = forwarding['inner_record']
        need(type(inner) is list and len(inner) == 3 and inner[0] == mode and inner[1] == 'api'
             and type(inner[2]) is int and 0 <= inner[2] < len(data[mode]['api']),
             'own mode and source API nested operand allocation')
        body = data[mode]['api'][inner[2]]['error']
        need(same(forwarding['outer_record'], [mode, domain, index])
             and forwarding['whole_inner_body'] == body
             and same(forwarding['source_relation']['inner_body'], pin(body.encode()))
             and forwarding['whole_outer_prefix'] + forwarding['whole_new_outer_trace'] == error
             and same(forwarding, expected_semantic['forwarding']),
             'whole own nested source operand prefix and new outer trace')
    need(same(semantic, expected_semantic), 'complete own raw coordinate address and nested semantic association')


def operation_link(proposed, qualified, native, ctx, helper, parser, mode, domain, index, data):
    need(type(proposed) is dict and set(proposed) == OP_KEYS
         and type(proposed['record']) is list and len(proposed['record']) == 3
         and type(proposed['record'][2]) is int and same(proposed['record'], [mode, domain, index]),
         'closed typed own mode domain and ordered operation association')
    need(same(proposed['native'], pin(canonical(native))) and same(proposed['cause'], pin(canonical(qualified))),
         'whole own native operation and qualified cause source custody')
    need(same(proposed['source'], qualified['source']) and same(proposed['context'], context(native)),
         'whole own operation source arguments kind and caller association')
    need(native.get('helper') == helper
         and same(proposed['helper_context'], None if helper is None else pin(canonical(ctx['source_helpers'][helper]))),
         'whole independently inverted source helper operation ownership')
    if parser is not None:
        need(type(parser) is int and 0 <= parser < len(ctx['parsers']), 'qualified own parser allocation range')
    need(same(proposed['parser_context'], None if parser is None else pin(canonical(ctx['parsers'][parser]))),
         'whole own parser operation source context association')
    if domain == 'api':
        source = qualified['source']
        need(source['helper'] == helper and source['parse'] == parser
             and native['parse'] == parser and same(source['caller'], native['caller'])
             and source['kind'] == native['kind'] and type(source['index']) is int and source['index'] == index,
             'complete independently inverted API source caller helper and parser relationships')
    elif domain == 'parses':
        need(same(qualified['source'], ctx['parsers'][index])
             and legacy(native['before']) == ctx['parsers'][index]['whole_before'],
             'whole own parser source input filename and before-graph relationship')
    else:
        need(qualified['source'] is None, 'private and test-run observations do not acquire source first-cause authority')
    api = native['api'] if domain == 'copies' else None
    if api is not None:
        need(type(api) is int and 0 <= api < len(data[mode]['api']), 'qualified own private-copy API allocation range')
    need(same(proposed['api_record'], None if api is None else [mode, 'api', api]),
         'whole own private-copy recorded API relationship')
    authority = 'source_first_cause' if domain in ('api', 'parses') else 'qualified_prior_observation'
    field_name = 'completed' if domain == 'test_run' else 'accepted'
    expected_status = dict(field=field_name, value=native[field_name], authority=authority)
    need(type(native[field_name]) is int and same(proposed['status'], expected_status)
         and same(proposed['primary'], qualified['primary'])
         and same(proposed['product'], pin(canonical(native.get('result')))),
         'whole typed source-first or explicitly observational acceptance and product roles')
    if authority == 'source_first_cause':
        need(native[field_name] == int(qualified['primary'] is None), 'source-derived acceptance retains intended first-cause truth')
    raw_roles(proposed, qualified, native, mode, domain, index, data)
    return dict(record=[mode, domain, index], source=pin(canonical(proposed['source'])),
                relation=pin(canonical(proposed)), native=proposed['native'], authority=authority)


def origin_relation(data, mode, row, ctx):
    """Select source origin families independently of producer traversal."""
    value, source = row['meaning'], row['source_contract']
    helper = source['context']['helper']
    causes = cause_mode(data, mode)
    if helper is not None:
        model = ctx['source_helpers'][helper]
        failed_api = [index for index in model['api_members'] if causes['domains']['api']['records'][index]['primary'] is not None]
        failed_parse = [index for index in model['parse_members'] if causes['domains']['parses']['records'][index]['primary'] is not None]
        need(bool(failed_api) != bool(failed_parse), 'source helper has exactly one intended failing operation family')
        domain, index = ('api', min(failed_api)) if failed_api else ('parses', min(failed_parse))
        cause = causes['domains'][domain]['records'][index]
        first_source = cause['source'] if domain == 'api' else dict(context=ctx['parsers'][index], primary=cause['primary'])
        need(value['first_record'] == [mode, domain, index] and same(value['first_source'], first_source)
             and same(value['source_helper'], model) and value['primary'] == cause['primary'],
             'whole independently selected source helper first failure and consumer meaning')
        return dict(kind='source-helper-first-failure', helper=helper, first_record=[mode, domain, index],
                    first_source=first_source, cause=pin(canonical(cause)), primary=cause['primary'], source_helper=model)
    origin = value['origin']
    kind = origin['kind']
    if kind == 'whole-authored-type-width':
        name = origin['name']
        need(name in data['authored']['types'] and same(origin['source_type'], data['authored']['types'][name]),
             'whole independently admitted authored type and width source origin')
        return dict(kind=kind, model=origin, name=name, authored_type=pin(canonical(data['authored']['types'][name])))
    if kind == 'synthetic-authored-first-line-and-opaque-original-trace':
        trace = data[mode]['consumers'][3]['actual']
        need(type(trace) is str and origin['whole_native_trace'] == pin(trace.encode())
             and trace.startswith(origin['message'] + '\n'), 'complete own opaque synthetic trace and authored first line')
        return dict(kind=kind, model=origin, opaque_trace=trace, source_scope=pin(canonical(source['source_scope'])))
    if kind == 'whole-authored-actor-detached-copy':
        actor, witness_index = origin['actor'], origin['qualified_test_copy']['index']
        need(type(actor) is int and actor == 0 and same(origin['source_actor'], data['actors']['actors']['local'])
             and ctx['parsers'][actor]['source_input'] == pin(data['actors']['sources']['local'].encode()),
             'whole authored actor and own parser source input origin')
        witnesses = [item for item in data['copy_inputs']['rows'] if item['index'] == witness_index]
        proofs = [item for item in data['copy_proofs']['proofs']
                  if item['mode'] == mode and item['kind'] == 'returned' and item['original_index'] == witness_index]
        need(type(witness_index) is int and 0 <= witness_index < len(data[mode]['copies'])
             and len(witnesses) == len(proofs) == 1, 'unique complete own actor-copy witness and provider allocation')
        witness, proof = witnesses[0], proofs[0]
        provider = 'storable' if mode == 'storable' else 'ordinary'
        need(origin['qualified_test_copy']['witness'] == pin(canonical(witness))
             and origin['qualified_test_copy']['provider'] == proof['provider'] == provider
             and same(witness['native']['before'], data[mode]['copies'][witness_index]['before']),
             'whole qualified actor-copy input primitive kinds and dated provider witness')
        return dict(kind=kind, model=origin, actor=actor, parser_record=[mode, 'parses', actor],
            copy_record=[mode, 'copies', witness_index], source_actor=pin(canonical(data['actors']['actors']['local'])),
            copy_input=pin(canonical(witness)), provider_proof=pin(canonical(proof)))
    need(kind in ('readonly-authored-json', 'qualified-own-source-api'), 'complete source-derived consumer origin family')
    api = origin['api']
    need(type(api) is int and 0 <= api < len(data[mode]['api']), 'own source-derived consumer API origin allocation')
    product = data['products']['apis'][api]
    need(type(product['source_index']) is int and product['source_index'] == api
         and origin['whole_source_product'] == pin(canonical(product)), 'whole own consumer source API product association')
    return dict(kind=kind, model=origin, record=[mode, 'api', api],
        cause=pin(canonical(causes['domains']['api']['records'][api])), source_product=pin(canonical(product)))


def check(candidate):
    data = inputs()
    wanted = header(data)
    need(type(candidate) is dict and set(candidate) == set(wanted) | {'modes'}
         and type(candidate['schema_version']) is int, 'closed typed complete association schema')
    need(same({key: candidate[key] for key in wanted}, wanted), 'whole original source contract and native/private boundary custody')
    need(type(candidate['modes']) is list and len(candidate['modes']) == len(MODES)
         and all(type(mode) is dict and set(mode) == {'mode', 'operations', 'helpers', 'parsers', 'consumers'} for mode in candidate['modes'])
         and [mode['mode'] for mode in candidate['modes']] == list(MODES), 'complete ordered original association modes')
    proposed_modes = {mode['mode']: mode for mode in candidate['modes']}
    consumed, bindings = set(), []
    for ctx in data['contexts']['proofs']:
        mode = ctx['mode']
        proposed, causes, native = proposed_modes[mode], cause_mode(data, mode), data[mode]
        need(legacy(native['helpers']) == ctx['raw_helpers'] and legacy(native['consumers']) == ctx['raw_consumers']
             and legacy(native['parses']) == ctx['raw_parsers'], 'complete own original source-context native populations')
        need(type(proposed['operations']) is dict and set(proposed['operations']) == set(DOMAINS)
             and all(type(proposed['operations'][domain]) is list
                     and len(proposed['operations'][domain]) == len(records(native, domain)) for domain in DOMAINS),
             'complete original operation association populations')
        helper_maps = {domain: memberships(ctx, key, len(records(native, domain)))
                       for domain, key in (('api', 'api_members'), ('copies', 'copy_members'), ('parses', 'parse_members'))}
        api_parsers = parser_memberships(ctx, len(native['api']))
        need(type(proposed['helpers']) is list and len(proposed['helpers']) == len(ctx['source_helpers']),
             'complete source helper associations')
        for index, source in enumerate(ctx['source_helpers']):
            helper = proposed['helpers'][index]
            cause = causes['helpers'][index]
            need(type(helper) is dict and set(helper) == {'index', 'source', 'cause', 'first_record', 'primary', 'operations', 'consumers'}
                 and type(helper['index']) is int and helper['index'] == index and same(helper['source'], source)
                 and same(cause['source'], source) and same(helper['cause'], pin(canonical(cause))),
                 'whole own source helper label pattern caller and cause association')
            expected = {domain: [[mode, domain, member] for member in source[key]]
                        for domain, key in (('api', 'api_members'), ('copies', 'copy_members'), ('parses', 'parse_members'))}
            need(same(helper['operations'], expected)
                 and same(helper['consumers'], [[mode, 'consumers', member] for member in source['consumer_members']]),
                 'whole ordered source helper API copy parser and consumer memberships')
            failed = [(domain, member) for domain in ('api', 'parses') for _, _, member in expected[domain]
                      if causes['domains'][domain]['records'][member]['primary'] is not None]
            need(failed and len({domain for domain, _ in failed}) == 1, 'one own source helper failing operation family')
            domain, member = min(failed, key=lambda item: item[1])
            need(same(helper['first_record'], [mode, domain, member])
                 and same(helper['primary'], causes['domains'][domain]['records'][member]['primary']),
                 'independently selected own source helper first failed operation')
            consumed.add((mode, 'helper', index))
        need(type(proposed['parsers']) is list and len(proposed['parsers']) == len(ctx['parsers']),
             'complete original parser source associations')
        for index, source in enumerate(ctx['parsers']):
            parser = proposed['parsers'][index]
            need(type(parser) is dict and set(parser) == {'index', 'source', 'operation', 'api_operations'}
                 and type(parser['index']) is int and parser['index'] == index and same(parser['source'], source)
                 and same(parser['operation'], pin(canonical(proposed['operations']['parses'][index])))
                 and same(parser['api_operations'], [[mode, 'api', member] for member in source['api_members']]),
                 'whole own parser source text filename caller and complete API span association')
            consumed.add((mode, 'parser', index))
        for domain in ('parses', 'api', 'copies', 'test_run'):
            for index, original in enumerate(records(native, domain)):
                helper = helper_maps.get(domain, {}).get(index)
                parser = index if domain == 'parses' else api_parsers.get(index) if domain == 'api' else original.get('parse')
                link = operation_link(proposed['operations'][domain][index], causes['domains'][domain]['records'][index],
                                      original, ctx, helper, parser, mode, domain, index, data)
                key = mode, domain, index
                need(key not in consumed, 'unique original operation association consumption')
                consumed.add(key)
                bindings.append(link)
        need(type(proposed['consumers']) is list and len(proposed['consumers']) == len(ctx['source_consumers']),
             'complete source-derived consumer association population')
        consumers = consumer_mode(data, mode)['consumers']
        consumer_helpers = memberships(ctx, 'consumer_members', len(consumers))
        for index, source in enumerate(ctx['source_consumers']):
            link, qualified = proposed['consumers'][index], consumers[index]
            value, original = qualified['meaning'], native['consumers'][index]
            need(type(link) is dict and set(link) == {'index', 'source_context', 'source_contract', 'native', 'meaning',
                 'role', 'operand', 'outcome', 'truth_authority', 'origin'} and type(link['index']) is int and link['index'] == index,
                 'closed typed ordered source consumer association')
            need(source['helper'] == consumer_helpers.get(index) and same(link['source_context'], source)
                 and same(qualified['source_contract']['context'], source)
                 and same(value['source_assertion'], qualified['source_contract'])
                 and same(link['source_contract'], pin(canonical(qualified['source_contract']))),
                 'whole own consumer source assertion helper and caller context')
            need(same(link['native'], pin(canonical(original))) and same(qualified['native'], original)
                 and same(link['meaning'], pin(canonical(value))), 'whole own consumer native body and qualified source meaning')
            role = 'remaining' if source['helper'] is None else 'helper'
            need(link['role'] == qualified['role'] == role and link['truth_authority'] == 'admitted source-derived typed comparison',
                 'source-derived consumer role and truth authority')
            need(type(link['outcome']) is int and link['outcome'] in (0, 1) and link['outcome'] == value['outcome']
                 and same(link['operand'], value['operand'])
                 and same({key: original[key] for key in value['operand']}, value['operand']),
                 'complete independently admitted typed consumer operand and comparison truth')
            need(same(link['origin'], origin_relation(data, mode, qualified, ctx)),
                 'whole own source consumer API type actor copy synthetic or helper-cause origin association')
            consumed.add((mode, 'consumer', index))
            bindings.append(dict(record=[mode, 'consumer', index], relation=pin(canonical(link)), source=link['source_contract'],
                                 native=link['native'], operand=pin(canonical(link['operand'])), outcome=link['outcome']))
    expected = {(mode, domain, index) for mode in MODES for domain in DOMAINS
                for index in range(len(records(data[mode], domain)))}
    expected |= {(mode, role, index) for mode in MODES for role, count in
                 (('helper', len(context_mode(data, mode)['source_helpers'])),
                  ('parser', len(context_mode(data, mode)['parsers'])),
                  ('consumer', len(context_mode(data, mode)['source_consumers']))) for index in range(count)}
    need(consumed == expected, 'every complete original association consumed exactly once')
    return dict(owner=PLAN['owner'], revision=PLAN['revision'], candidate=pin(canonical(candidate)),
                inputs=data['identities'], contracts=wanted['contracts'], original_conditions=wanted['original_conditions'],
                bindings=bindings, consumed=[list(key) for key in sorted(consumed)], condition=PLAN['condition'])


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--candidate', default='candidate.json.gz')
    parser.add_argument('--save', action='store_true')
    args = parser.parse_args()
    path = BASE / args.candidate
    need(Path(args.candidate).name == args.candidate and args.candidate.endswith('.json.gz')
         and stat.S_ISREG(path.lstat().st_mode) and path.stat().st_dev == Path.cwd().stat().st_dev,
         'ordinary own same-volume complete association candidate')
    result = check(load_product(args.candidate))
    if args.save:
        need(args.candidate == 'candidate.json.gz', 'only whole positive association publishes qualification')
        save('qualification.json', result)
    print(SUCCESS, end='')

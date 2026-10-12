"""Propose complete mode-first associations from the admitted original products."""
from association_inputs import *


def operation(data, mode, domain, index):
    native = records(data[mode], domain)[index]
    cause = cause_mode(data, mode)['domains'][domain]['records'][index]
    contexts = context_mode(data, mode)
    helper = native.get('helper')
    parser = index if domain == 'parses' else native.get('parse')
    return dict(record=[mode, domain, index], native=pin(canonical(native)),
        cause=pin(canonical(cause)), source=cause['source'], context=context(native),
        helper_context=None if helper is None else pin(canonical(contexts['source_helpers'][helper])),
        parser_context=None if parser is None else pin(canonical(contexts['parsers'][parser])),
        api_record=[mode, 'api', native['api']] if domain == 'copies' and native['api'] is not None else None,
        primary=cause['primary'], status=cause['status'], product=cause['product'],
        raw=cause['raw'], semantic=cause['semantic'])


def origin(data, mode, row):
    meaning, index = row['meaning'], row['index']
    helper = row['source_contract']['context']['helper']
    qualified = cause_mode(data, mode)
    if helper is not None:
        first = qualified['helpers'][helper]['first_record']
        cause = qualified['domains'][first[1]]['records'][first[2]]
        return dict(kind='source-helper-first-failure', helper=helper, first_record=first,
                    first_source=meaning['first_source'], cause=pin(canonical(cause)),
                    primary=meaning['primary'], source_helper=meaning['source_helper'])
    source = meaning['origin']
    kind = source['kind']
    if kind in ('readonly-authored-json', 'qualified-own-source-api'):
        api = source['api']
        return dict(kind=kind, model=source, record=[mode, 'api', api],
            cause=pin(canonical(qualified['domains']['api']['records'][api])),
            source_product=pin(canonical(data['products']['apis'][api])))
    if kind == 'whole-authored-actor-detached-copy':
        copy_index = source['qualified_test_copy']['index']
        witness = next(value for value in data['copy_inputs']['rows'] if value['index'] == copy_index)
        proof = next(value for value in data['copy_proofs']['proofs']
                     if value['mode'] == mode and value['kind'] == 'returned' and value['original_index'] == copy_index)
        return dict(kind=kind, model=source, actor=source['actor'],
            parser_record=[mode, 'parses', source['actor']], copy_record=[mode, 'copies', copy_index],
            source_actor=pin(canonical(data['actors']['actors']['local'])),
            copy_input=pin(canonical(witness)), provider_proof=pin(canonical(proof)))
    if kind == 'whole-authored-type-width':
        return dict(kind=kind, model=source, name=source['name'],
                    authored_type=pin(canonical(data['authored']['types'][source['name']])))
    need(kind == 'synthetic-authored-first-line-and-opaque-original-trace', 'complete producer consumer origin cases')
    return dict(kind=kind, model=source, opaque_trace=data[mode]['consumers'][3]['actual'],
                source_scope=pin(canonical(row['source_contract']['source_scope'])))


def propose(data):
    modes = []
    for mode in MODES:
        ctx, causes = context_mode(data, mode), cause_mode(data, mode)
        operations = {domain: [operation(data, mode, domain, index)
                              for index in range(len(records(data[mode], domain)))] for domain in DOMAINS}
        helpers = []
        for helper in causes['helpers']:
            source = helper['source']
            helpers.append(dict(index=source['index'], source=source, cause=pin(canonical(helper)),
                first_record=helper['first_record'], primary=helper['primary'],
                operations={domain: [[mode, domain, index] for index in source[key]]
                            for domain, key in (('api', 'api_members'), ('copies', 'copy_members'), ('parses', 'parse_members'))},
                consumers=[[mode, 'consumers', index] for index in source['consumer_members']]))
        parsers = []
        for parser in ctx['parsers']:
            index = parser['index']
            parsers.append(dict(index=index, source=parser,
                operation=pin(canonical(operations['parses'][index])),
                api_operations=[[mode, 'api', index] for index in parser['api_members']]))
        consumers = []
        for row in consumer_mode(data, mode)['consumers']:
            index, value = row['index'], row['meaning']
            consumers.append(dict(index=index, source_context=ctx['source_consumers'][index],
                source_contract=pin(canonical(row['source_contract'])), native=pin(canonical(row['native'])),
                meaning=pin(canonical(value)), role=row['role'], operand=value['operand'], outcome=value['outcome'],
                truth_authority='admitted source-derived typed comparison', origin=origin(data, mode, row)))
        modes.append(dict(mode=mode, operations=operations, helpers=helpers, parsers=parsers, consumers=consumers))
    return dict(header(data), modes=modes)

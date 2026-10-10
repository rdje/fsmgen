"""Independent original-event ordering, source custody and prefix membership oracle.

Never imports the producer. All expected bounds derive from the original entry
and return tables; fresh snapshots are an independent falsification witness.
"""
import json

TABLES = ('api', 'copies', 'helpers', 'parses', 'consumers')


def exact(a, b):
    return json.dumps(a, sort_keys=True) == json.dumps(b, sort_keys=True)


def require(condition, message):
    if not condition:
        raise ValueError(message)


def event_checkpoint(event):
    if event[0] in ('inner-Metadata', 'new-Value'):
        return ['api', event[1]]
    require(event[0] == 'own-source-throw', 'complete inherited source throw event')
    return ['parses' if event[1] == 'parse' else event[1], event[2]]


def bounds(headers, checkpoint):
    domain, index = checkpoint
    row = headers[domain][index]
    helper = headers['helpers'][row['helper']]
    # Each own refuses callback evaluates once, then only runs its two assertions.
    # API indices reserve at entry. Private copies append only after returning.
    api_end = helper['api_end']
    private_ends = [i + 1 for i, copy in enumerate(headers['copies'])
                    if copy['api'] is not None and copy['api'] < api_end]
    copies = max(private_ends, default=0)
    return {'api': api_end, 'copies': copies, 'helpers': row['helper'] + 1,
            'parses': helper['parse_start'] + int(domain == 'parses'),
            'consumers': helper['consumer_start']}


def source_contracts(inputs):
    text = inputs['observer_source']
    fragments = [
        'local $active_api = scalar @api;\n    push @api,',
        'local $active_parse = scalar @parses;\n    push @parses,',
        'local $active_helper = scalar @helpers;\n                push @helpers,',
        'my @caller = caller;', "return copy_value('test', \\@caller, @_);",
        "return copy_value('metadata-private', [caller], @_);",
        "return copy_value('value-private', [caller], @_);",
        'push @copies, {kind => $kind, caller => $caller, api => $active_api,',
        'assertion_start => $assertion_start, assertion_end => scalar @copy_assertions,',
        'push @trials, {copy => $active_test_copy, provider => $provider, caller => $caller,',
        'my ($operation, $pattern, $label) = @_;',
    ]
    require(all(text.count(part) == 1 for part in fragments), 'complete observer append/allocation source contracts')
    require('pop @api' not in text and 'shift @copies' not in text and 'splice @consumers' not in text,
            'retained observer caller prefixes cannot shrink')
    test = inputs['test_source']
    require('my $ok = eval { $run->(); 1 };' in test
            and 'ok(!$ok, "$name refuses");' in test
            and 'like($diagnostic, $pattern, "$name names the cause in its diagnostic line");' in test,
            'one evaluated callback precedes both consumer assertions')


def qualify(product, inputs, witnesses, supplement, prior_callers):
    source_contracts(inputs)
    scope = ('Complete observer-retained source caller arrays at every qualified original refusal view. '
             'Fresh prefix witnesses and original caller headers qualify allocation/retention contracts only. '
             'Whole source graph/role integration, original native address/identity/flags/payload, opaque '
             'provider/framework/formatter/CODE identity, global heap census and canonical publication remain open.')
    require(product.get('scope') == scope, 'observer caller source-only scope')
    require(exact(product.get('excluded'), ['encoded source graph carriers', 'fresh probe snapshots and header collections',
            'original payload nodes represented only by encoded graphs', 'discarded non-main assertion caller arrays',
            'test-copy assertion caller arrays not stored in consumers']), 'observer carriers and inactive payload exclusion')
    require(exact(product.get('conserved_models'), inputs['conserved_models']), 'every complete predecessor source model conserved')
    require(exact(list(witnesses), [r['mode'] for r in inputs['modes']]), 'every fresh source witness mode')
    require(len(product.get('modes', [])) == len(inputs['modes']), 'complete retained caller mode population')
    measured = {'source_views': 0, 'caller_records': {}, 'holder_occurrences': 0,
                'source_distinctions': 0, 'trial_alias_occurrences': 0, 'inherited_bridges': 0}
    for result, source in zip(product['modes'], inputs['modes'], strict=True):
        mode, headers = source['mode'], source['headers']
        require(result.get('mode') == mode, 'exact retained caller capture domain')
        witness = witnesses[mode]
        require(witness.get('mode') == mode and type(witness.get('completed')) is int and witness['completed'] == 1,
                'complete fresh observer test execution')
        require(exact(witness.get('headers'), headers), 'every original caller-bearing header joins the fresh source execution')
        failed = {(table, i) for table in ('api', 'parses') for i, r in enumerate(headers[table])
                  if type(r['accepted']) is int and r['accepted'] == 0}
        snapshots = witness['snapshots']
        require(len(snapshots) == len(failed) and len({(s['domain'], s['index']) for s in snapshots}) == len(failed)
                and {(s['domain'], s['index']) for s in snapshots} == failed, 'every failed original catcher snapshot exactly once')
        fresh_bounds = {}
        for snap in snapshots:
            require(type(snap['index']) is int, 'typed original snapshot index')
            checkpoint = [snap['domain'], snap['index']]
            expected = bounds(headers, checkpoint)
            require(exact(snap['prefixes'], expected), 'independent original ordering and fresh prefix witness agree')
            require(all(type(n) is int and 0 <= n <= len(headers[t]) for t, n in expected.items()),
                    'typed complete retained prefix bounds')
            fresh_bounds[tuple(checkpoint)] = expected
        declarations = result['declarations']
        require(set(declarations) == set(TABLES), 'complete caller allocation family population')
        for table in TABLES:
            declaration = declarations[table]
            expected = {'reference_kind': 'ARRAY', 'holder': '@' + table,
                'allocation': 'fresh [caller]; test copies use fresh lexical @caller' if table == 'copies' else 'fresh [caller]',
                'lexical_caller_indices': [i for i, r in enumerate(headers[table]) if table == 'copies' and r['kind'] == 'test'],
                'domain': [mode, table, 'entry index'], 'callers': [r['caller'] for r in headers[table]]}
            require(exact(declaration, expected), 'whole caller family origins/kinds/values and capture membership')
        measured['caller_records'][mode] = {t: len(headers[t]) for t in TABLES}
        require(exact(result['inherited_caller_bridges'], supplement['bridges'][mode])
                and exact(result['inherited_caller_bridges'], prior_callers[mode]), 'complete inherited caller origin bridge population')
        for bridge in result['inherited_caller_bridges']:
            require(type(bridge['index']) is int and bridge['index'] < len(headers[bridge['table']]),
                    'inherited caller bridge resolves to one source allocation')
        measured['inherited_bridges'] += len(result['inherited_caller_bridges'])
        require(len(result['views']) == len(source['views']), 'complete retained caller source-view population')
        for view, original_view in zip(result['views'], source['views'], strict=True):
            require(exact(view['domain'], original_view['domain']), 'exact retained caller throw/capture/phase domain')
            checkpoint = event_checkpoint(original_view['event'])
            require(exact(view['checkpoint'], checkpoint), 'complete inner caught and outer source checkpoint bridge')
            expected = fresh_bounds[tuple(checkpoint)]
            prefixes = [{'table': t, 'first': 0, 'end': expected[t]} for t in TABLES]
            require(exact(view['held_prefixes'], prefixes), 'complete simultaneous retained caller membership')
            members = [(t, i) for t in TABLES for i in range(expected[t])]
            require(type(view['population']) is int and view['population'] == len(members), 'exact retained caller population')
            # Sum independently by row against every earlier member; never materialize the quadratic relation.
            pairs = sum(range(len(members)))
            require(exact(view['source_distinct'], {'relation': 'all unordered pairs of distinct prefix members', 'pairs': pairs}),
                    'complete simultaneous fresh caller source distinction relation')
            member_set = set(members)
            aliases = [{'trial': i, 'member': [mode, 'copies', trial['copy']]}
                       for i, trial in enumerate(supplement['trials'][mode]) if ('copies', trial['copy']) in member_set]
            require(exact(view['trial_aliases'], aliases), 'trial records reuse test-copy caller arrays without fresh allocation')
            for alias in aliases:
                trial = supplement['trials'][mode][alias['trial']]
                require(exact(trial['caller'], headers['copies'][trial['copy']]['caller']), 'whole trial caller forwarding source values')
            require(view['bridge_scope'] == 'Source catcher snapshots bridge the throw because unwinding reaches only observer catch/record/rethrow; no caller-bearing append intervenes.',
                    'source catcher-to-throw lifetime scope')
            measured['source_views'] += 1
            measured['holder_occurrences'] += len(members)
            measured['source_distinctions'] += pairs
            measured['trial_alias_occurrences'] += len(aliases)
    return measured

"""Source allocation families and complete retained caller prefixes."""

TABLES = ('api', 'copies', 'helpers', 'parses', 'consumers')
SCOPE = ('Complete observer-retained source caller arrays at every qualified original refusal view. '
         'Fresh prefix witnesses and original caller headers qualify allocation/retention contracts only. '
         'Whole source graph/role integration, original native address/identity/flags/payload, opaque '
         'provider/framework/formatter/CODE identity, global heap census and canonical publication remain open.')
EXCLUDED = ['encoded source graph carriers', 'fresh probe snapshots and header collections',
            'original payload nodes represented only by encoded graphs',
            'discarded non-main assertion caller arrays', 'test-copy assertion caller arrays not stored in consumers']


def derive(inputs, witnesses, supplement):
    modes = []
    for source in inputs['modes']:
        mode = source['mode']
        declarations = {}
        for table in TABLES:
            declarations[table] = {
                'reference_kind': 'ARRAY', 'holder': '@' + table,
                'allocation': 'fresh [caller]; test copies use fresh lexical @caller' if table == 'copies' else 'fresh [caller]',
                'lexical_caller_indices': [i for i, r in enumerate(source['headers'][table])
                                           if table == 'copies' and r['kind'] == 'test'],
                'domain': [mode, table, 'entry index'],
                'callers': [row['caller'] for row in source['headers'][table]]}
        snapshots = {(s['domain'], s['index']): s['prefixes'] for s in witnesses[mode]['snapshots']}
        views = []
        for row in source['views']:
            event = row['event']
            if event[0] == 'inner-Metadata':
                checkpoint = ['api', event[1]]
            elif event[0] == 'new-Value':
                checkpoint = ['api', event[1]]
            else:
                checkpoint = ['parses' if event[1] == 'parses' else event[1], event[2]]
            # The helper view spelling for parser domains is inherited as 'parse'.
            if checkpoint[0] == 'parse':
                checkpoint[0] = 'parses'
            counts = snapshots[tuple(checkpoint)]
            segments = [{'table': table, 'first': 0, 'end': counts[table]} for table in TABLES]
            population = sum(counts.values())
            aliases = [{'trial': i, 'member': [mode, 'copies', trial['copy']]}
                       for i, trial in enumerate(supplement['trials'][mode]) if trial['copy'] < counts['copies']]
            views.append({'domain': row['domain'], 'checkpoint': checkpoint,
                          'held_prefixes': segments, 'population': population,
                          'source_distinct': {'relation': 'all unordered pairs of distinct prefix members',
                                              'pairs': population * (population - 1) // 2},
                          'trial_aliases': aliases,
                          'bridge_scope': 'Source catcher snapshots bridge the throw because unwinding reaches only observer catch/record/rethrow; no caller-bearing append intervenes.'})
        modes.append({'mode': mode, 'declarations': declarations, 'views': views,
                      'inherited_caller_bridges': supplement['bridges'][mode]})
    return {'scope': SCOPE, 'excluded': EXCLUDED, 'modes': modes,
            'conserved_models': inputs['conserved_models']}

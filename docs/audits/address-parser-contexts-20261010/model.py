"""Publish complete fresh observations and an explicit bounded source hypothesis."""
SCOPE = ('Complete fresh context source construction under own numeric-field semantics, with exact typed public observations retained. '
         'Original scalar flags/native payload/identity, original context-slot/source closure, provider implementation, '
         'global object census, source/raw integration, cold replay and canonical publication remain open.')
PHASE = {
    'active_roots': ['/0', '/1', '/2', '/3/0', '/3/1', '/6/0'],
    'inactive_contexts': [2], 'inactive_scopes': [1, 2, 3, 4, 5, 6], 'inactive_samples': [0],
    'sample_lifetime': 'The sample lexical block ends before _clauses; the final overlay argument aliases its former bindings, but sample output is not an active original source holder.',
    'observer_carriers': 'Final carrier, result collections, copy rows, active-argument arrays and construction-argument rows/arrays are probe allocations. Their presence does not establish original retention or object death.',
    'numeric_boundary': 'Only declared finite numeric properties outside the conserved facade/AST/actor accept canonical nonnegative integer JSON strings with the same numeric meaning. Exact original and fresh typed observations are never normalized; original native scalar flags remain unmeasured.'}


def derive(inputs):
    return {'scope': SCOPE, 'preserved_construction': inputs['construction_model'],
            'public': inputs['public'], 'phase': PHASE}

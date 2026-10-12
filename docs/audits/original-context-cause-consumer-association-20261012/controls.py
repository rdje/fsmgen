"""Declare genuine changed complete associations and intended first refusals."""
import copy
from association_inputs import *


def get(value, path):
    for key in path:
        value = value[key]
    return value


def declarations(candidate):
    mode = candidate['modes'][0]
    api = mode['operations']['api']
    nonempty = next(i for i, row in enumerate(api) if row['raw'] is not None)
    empty = next(i for i, row in enumerate(api) if row['raw'] is None)
    nested = next(i for i, row in enumerate(api)
                  if row['semantic'] is not None and row['semantic']['forwarding'] is not None)
    copy_index = next(i for i, row in enumerate(mode['operations']['copies']) if row['api_record'] is not None)
    consumer = mode['consumers']
    type_index = next(i for i, row in enumerate(consumer) if row['origin']['kind'] == 'whole-authored-type-width')
    actor_index = next(i for i, row in enumerate(consumer) if row['origin']['kind'] == 'whole-authored-actor-detached-copy')
    synthetic = next(i for i, row in enumerate(consumer)
                     if row['origin']['kind'] == 'synthetic-authored-first-line-and-opaque-original-trace')
    helper_index = next(i for i, row in enumerate(api) if row['helper_context'] is not None)
    rows = [dict(label='positive', path=[], action='retain', cause=None, status=0)]

    def add(label, path, action, cause, value=None):
        rows.append(dict(label=label, path=path, action=action, value=value, cause=cause, status=1))

    schema = 'closed typed complete association schema'
    boundary = 'whole original source contract and native/private boundary custody'
    modes = 'complete ordered original association modes'
    helper_source = 'whole own source helper label pattern caller and cause association'
    helper_members = 'whole ordered source helper API copy parser and consumer memberships'
    helper_first = 'independently selected own source helper first failed operation'
    parser = 'whole own parser source text filename caller and complete API span association'
    custody = 'whole own native operation and qualified cause source custody'
    source = 'whole own operation source arguments kind and caller association'
    typed = 'whole typed source-first or explicitly observational acceptance and product roles'
    truth = 'complete independently admitted typed consumer operand and comparison truth'
    origin = 'whole own source consumer API type actor copy synthetic or helper-cause origin association'
    root = ['modes', 0]
    op = root + ['operations', 'api']
    hs, ps, cs = root + ['helpers', 0], root + ['parsers', 0], root + ['consumers']
    error = op + [nonempty]
    sem = error + ['semantic']
    add('schema-boolean', ['schema_version'], 'set', schema, True)
    add('native-promotion', ['assurance', 'original_native_private'], 'set', boundary, True)
    add('historical-currency', ['assurance', 'later_historical_execution_currency'], 'set', boundary, True)
    add('borrowed-source-input', ['inputs', PATHS['contexts'], 'sha256'], 'set', boundary, '0' * 64)
    add('omitted-mode', ['modes'], 'pop', modes)
    add('reordered-modes', ['modes'], 'reverse', modes)
    add('omitted-api', op, 'pop', 'complete original operation association populations')
    add('omitted-helper', root + ['helpers'], 'pop', 'complete source helper associations')
    add('helper-label', hs + ['source', 'label'], 'set', helper_source, 'borrowed label')
    add('helper-pattern', hs + ['source', 'pattern'], 'set', helper_source, '.*')
    add('helper-caller', hs + ['source', 'caller', 2], 'increment', helper_source)
    add('helper-cause-kind', hs + ['cause', 'bytes'], 'float', helper_source)
    add('ordered-helper-apis', hs + ['operations', 'api'], 'reverse', helper_members)
    add('omitted-helper-copy', hs + ['operations', 'copies'], 'pop', helper_members)
    add('ordered-helper-consumers', hs + ['consumers'], 'reverse', helper_members)
    add('borrowed-helper-first', hs + ['first_record'], 'set', helper_first, mode['helpers'][1]['first_record'])
    add('helper-primary', hs + ['primary'], 'set', helper_first, 'borrowed primary')
    add('omitted-parser', root + ['parsers'], 'pop', 'complete original parser source associations')
    add('parser-filename', ps + ['source', 'raw_filename'], 'set', parser, 'borrowed.isf')
    add('parser-source-input', ps + ['source', 'source_input', 'sha256'], 'set', parser, '0' * 64)
    add('parser-caller', ps + ['source', 'caller', 2], 'increment', parser)
    add('omitted-parser-api', ps + ['api_operations'], 'pop', parser)
    add('ordered-parser-apis', ps + ['api_operations'], 'reverse', parser)
    add('parser-boolean-index', ps + ['api_operations', 0, 2], 'set', parser, False)
    add('operation-boolean-index', op + [0, 'record', 2], 'set',
        'closed typed own mode domain and ordered operation association', False)
    add('native-float-bytes', op + [0, 'native', 'bytes'], 'float', custody)
    add('borrowed-native', op + [0, 'native'], 'set', custody, api[1]['native'])
    add('borrowed-mode-cause', op + [0, 'cause'], 'set', custody,
        candidate['modes'][1]['operations']['api'][0]['cause'])
    add('source-caller', op + [0, 'source', 'caller', 2], 'increment', source)
    add('context-kind', op + [0, 'context', 'kind'], 'set', source, 'borrowed-kind')
    add('borrowed-helper-context', op + [helper_index, 'helper_context'], 'set',
        'whole independently inverted source helper operation ownership')
    add('borrowed-parser-context', op + [0, 'parser_context'], 'set',
        'whole own parser operation source context association')
    add('borrowed-copy-api', root + ['operations', 'copies', copy_index, 'api_record', 2], 'increment',
        'whole own private-copy recorded API relationship')
    add('source-primary', op + [0, 'primary'], 'set', typed, 'borrowed primary')
    add('observed-flag-authority', op + [0, 'status', 'authority'], 'set', typed, 'native passed flag')
    add('acceptance-boolean', op + [0, 'status', 'value'], 'set', typed, True)
    add('product-float-bytes', op + [0, 'product', 'bytes'], 'float', typed)
    add('empty-borrows-raw', op + [empty, 'raw'], 'set',
        'empty own operation cannot borrow nonempty raw or coordinate roles', api[nonempty]['raw'])
    add('truncated-raw-body', error + ['raw', 'body'], 'truncate',
        'whole lossless own raw body context and physical segments')
    add('wrong-first-cause', sem + ['first_cause', 'primary'], 'set',
        'own source-first nonempty cause and context', 'borrowed primary')
    add('source-coordinate', sem + ['phases', 0, 'callers'], 'pop',
        'whole qualified ordered source phase class and coordinate roles')
    add('source-class', sem + ['phases', 0, 'classification'], 'set',
        'whole qualified ordered source phase class and coordinate roles', {})
    add('truncated-stack', sem + ['stack', 'frames'], 'pop', 'whole qualified stack and physical coordinates')
    add('address-allocation', sem + ['opaque', 'allocation', 'record', 0], 'set',
        'whole own qualified address allocation opaque and observer roles', 'storable')
    add('observer-coordinate', sem + ['observer', 'frame_index'], 'increment',
        'whole own qualified address allocation opaque and observer roles')
    forwarding = op + [nested, 'semantic', 'forwarding']
    add('nested-other-mode', forwarding + ['inner_record', 0], 'set',
        'own mode and source API nested operand allocation', 'storable')
    add('truncated-inner-body', forwarding + ['whole_inner_body'], 'truncate',
        'whole own nested source operand prefix and new outer trace')
    add('truncated-outer-prefix', forwarding + ['whole_outer_prefix'], 'truncate',
        'whole own nested source operand prefix and new outer trace')
    add('omitted-consumer', cs, 'pop', 'complete source-derived consumer association population')
    add('consumer-boolean-index', cs + [0, 'index'], 'set', 'closed typed ordered source consumer association', False)
    add('consumer-caller', cs + [0, 'source_context', 'caller', 2], 'increment',
        'whole own consumer source assertion helper and caller context')
    add('consumer-native-kind', cs + [0, 'native', 'bytes'], 'float',
        'whole own consumer native body and qualified source meaning')
    add('borrowed-consumer-meaning', cs + [0, 'meaning'], 'set',
        'whole own consumer native body and qualified source meaning', consumer[1]['meaning'])
    add('consumer-observed-authority', cs + [0, 'truth_authority'], 'set',
        'source-derived consumer role and truth authority', 'native passed flag')
    add('consumer-outcome-boolean', cs + [0, 'outcome'], 'set', truth, True)
    add('consumer-primitive-kind', cs + [type_index, 'operand', 'actual'], 'string', truth)
    add('storable-primitive-kind', ['modes', 1, 'consumers', type_index, 'operand', 'actual'], 'string', truth)
    add('consumer-false-green', cs + [type_index, 'operand', 'actual'], 'increment', truth)
    add('consumer-source-api', cs + [0, 'origin', 'record', 2], 'increment', origin)
    add('consumer-type-source', cs + [type_index, 'origin', 'authored_type', 'sha256'], 'set', origin, '0' * 64)
    add('consumer-copy-witness', cs + [actor_index, 'origin', 'copy_input', 'sha256'], 'set', origin, '0' * 64)
    add('consumer-copy-provider', cs + [actor_index, 'origin', 'provider_proof', 'sha256'], 'set', origin, '0' * 64)
    add('consumer-synthetic-trace', cs + [synthetic, 'origin', 'opaque_trace'], 'truncate', origin)
    labels = [row['label'] for row in rows]
    need(len(labels) == len(set(labels)), 'unique complete separating control declarations')
    return rows


def mutate(candidate, row):
    action, path = row['action'], row['path']
    if action == 'retain':
        return
    parent, key = get(candidate, path[:-1]), path[-1]
    old = parent[key]
    if action == 'set':
        parent[key] = copy.deepcopy(row['value'])
    elif action == 'pop':
        need(type(old) is list and old, 'genuine nonempty omission target')
        old.pop()
    elif action == 'reverse':
        need(type(old) is list and len(old) > 1, 'genuine ordered separating target')
        old.reverse()
    elif action == 'increment':
        need(type(old) is int, 'typed integer separating target')
        parent[key] = old + 1
    elif action == 'float':
        need(type(old) is int, 'typed integer identity separating target')
        parent[key] = float(old)
    elif action == 'string':
        need(type(old) is int, 'typed integer operand separating target')
        parent[key] = str(old)
    elif action == 'truncate':
        need(type(old) is str and old, 'whole nonempty string separating target')
        parent[key] = old[:-1]
    else:
        raise ValueError('undeclared separating operation')

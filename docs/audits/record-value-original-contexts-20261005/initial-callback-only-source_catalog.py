"""Finite source-authored contexts, independent of native labels and flags.

This is a model of the exact pinned T1986 source, not a general Perl parser.
"""
import re


def catalog(source):
    helpers, consumers = [], []

    def require(condition, message):
        if not condition:
            raise ValueError(message)

    def location(marker, at_start=False):
        require(source.count(marker) == 1, 'unique complete source context marker: ' + marker)
        offset = source.index(marker) + (0 if at_start else len(marker))
        return ['main', './t/1986-isf-record-port-value-gates.t', source[:offset].count('\n') + 1]

    def consume(label, marker=None, kind=None, helper=None):
        marker = marker or "'" + label + "');"
        caller = location(marker)
        if kind is None:
            calls = list(re.finditer(r'(?<!\w)(is_deeply|is|ok|like|unlike)\(', source[:source.index(marker)]))
            require(calls, 'source assertion call exists')
            kind = calls[-1][1]
        consumers.append(dict(index=len(consumers), kind=kind, label=label, helper=helper, caller=caller))

    def helper(label, marker=None, pattern=None, declaration=None):
        marker = marker or "'" + label + "');"
        caller = location(marker)
        end = source.index(marker) + len(marker)
        start = source.rfind('refuses(', 0, end)
        require(start >= 0, 'source refusal call exists')
        statement = source[start:end]
        # The pinned Perl call COP retains the completed anonymous callback
        # location; the following label argument does not install a new COP.
        closure_end = start + statement.rindex('}')
        caller = ['main', './t/1986-isf-record-port-value-gates.t', source[:closure_end].count('\n') + 1]
        if pattern is None:
            patterns = re.findall(r'qr/((?:\\.|[^/])*)/', statement)
            require(len(patterns) == 1, 'unique source literal helper pattern')
            pattern = patterns[0]
        else:
            require(declaration is not None and source.count(declaration) == 1,
                    'complete own source loop pattern declaration')
            require('qr/' + pattern + '/' in declaration, 'own source helper pattern literal')
        index = len(helpers)
        helpers.append(dict(index=index, label=label, pattern='(?^:' + pattern + ')', caller=caller,
                            source_statement=statement, source_declaration=declaration))
        consume(label + ' refuses', 'ok(!$ok, "$name refuses");', 'ok', index)
        consume(label + ' names the cause in its diagnostic line',
                'like($diagnostic, $pattern, "$name names the cause in its diagnostic line");', 'like', index)

    for label in ('scope validation retains original typed JSON', 'reference validation retains original typed JSON',
                  'copy validation retains original typed JSON', 'known bad full trace contains the caller pattern',
                  'oracle selects the actual message', 'the same false cause cannot satisfy the diagnostic oracle',
                  'input to owner storage accepts resolved alias equivalence',
                  'prepared storage to output contract accepts identity', 'prepared input to output contract accepts identity'):
        consume(label)
    for label in ('copy independently enforces target role', 'whole input target', 'scalar input target'):
        helper(label)
    consume('prepared scalar output target retains allowed role')
    consume('prepared scope does not share parser types')
    names = ('renamed', 'reordered', 'signed_data', 'four', 'two', 'bit_kind')
    require('for my $name (qw(' + ' '.join(names) + ')) {' in source, 'complete equal-width source iteration')
    declaration = "refuses(sub { copy($scope, 'packet', 'held') }, qr/requires the same resolved record type/,\n            \"$name copy identity\");"
    for name in names:
        consume(name + ' has independently expected equal packed width', '"$name has independently expected equal packed width");', 'is')
        helper(name + ' copy identity', '"$name copy identity");', 'requires the same resolved record type', declaration)
    helper('explicit state-model difference')
    names = ('signed_data', 'four', 'two', 'bit_kind')
    require('for my $name (qw(' + ' '.join(names) + ')) {' in source, 'complete payload source iteration')
    for name in names:
        consume(name + ' retains the established payload compatibility contract',
                '"$name retains the established payload compatibility contract");', 'ok')
    consume('independent nested packed width'); consume('independent flattened packed width')
    helper('nested shape cannot be flattened for copy identity'); helper('nested list item order retains type identity')
    for label in ('independent nested signed/four-state leaf range', 'independent nested list-item leaf range',
                  'leaf results do not share scope facts'):
        consume(label)
    paths = [('packet', 'requires a scalar value'), ('packet.body', 'requires a scalar leaf'),
             ('packet.body.lanes', 'requires a scalar leaf'), ('packet.unknown', 'invalid declared path.*unknown_member'),
             ('packet.body.lanes[2]', 'invalid declared path.*list_index_out_of_range'),
             ('packet.body.count[3]', 'invalid declared path.*scalar_index_out_of_range'),
             ('packet..count', 'invalid declared path.*parse_error')]
    for name, pattern in paths:
        declaration = "['" + name + "', qr/" + pattern + '/]'
        helper(name, 'refuses(sub { reference($scope, $pair->[0]) }, $pair->[1], $pair->[0]);', pattern, declaration)
    helper('whole-value permission does not allow subaggregate writes')
    for label in ('unresolved local masks the outer record type', 'nearest formal output is writable despite outer input name',
                  'formal type owns local path width'):
        consume(label)
    helper('formal does not borrow an outer member')
    consume('scalar local retains its width and writable role'); helper('scalar local cannot borrow an outer record')
    consume('scalar local slice retains core range and writable local role'); consume('scalar local bit index stays scalar')
    helper('an unresolved type cannot erase a known input role')
    for label in ('unrelated enum roots stay with existing enum validation', 'unrelated package roots stay with package validation',
                  'different storage-only types use the prior assignment contract', 'scalar ports introduce no record copy obligation',
                  'unrelated literal/expression handling remains with caller'):
        consume(label)
    helper('equal/unequal scalar carrier is not a record copy'); helper('record target cannot treat an expression as a same-type root')
    consume('existing list storage scalar leaves remain resolvable'); helper('root list is not a same-type record copy')
    consume('package spelling does not affect resolved identity')
    malformed = [('unknown key', 'unknown facts'), ('bad root width', 'width disagrees'),
                 ('bad scalar signed', 'signed property'), ('missing signed', 'lacks required facts'),
                 ('aggregate signed', 'scalar signed overlay'), ('aggregate state', 'unknown facts'),
                 ('bad state', 'state model'), ('duplicate order', 'duplicate record member'),
                 ('unlisted member', 'inventory disagrees'), ('cyclic member', 'cyclic resolved type'),
                 ('deferred kind', 'unsupported resolved type kind')]
    for name, pattern in malformed:
        matches = re.findall(r"\['" + re.escape(name) + r"', sub \{[^\n]+\}, qr/" + re.escape(pattern) + r'/\]', source)
        require(len(matches) == 1, 'complete own malformed source context')
        helper(name, 'refuses(sub { scope_for($spec, $types{frame}) }, $pair->[2], $pair->[0]);', pattern, matches[0])
    for label in ('unknown role', 'unknown scope argument', 'nonbinary whole-value permission', 'contradictory copy descriptor'):
        helper(label)
    for direction, type_name, clause, pattern in (
        ('output', 'frame', '(set value.flag 1)', 'record output field writes are not yet admitted'),
        ('input', 'lanes', '(complete done)', "interface port 'value' references aggregate type")):
        declaration = "['" + direction + "', '" + type_name + "', '" + clause + "', qr/" + pattern + '/]'
        helper(direction + ' ' + type_name + ' source', '"$direction $type source");', pattern, declaration)
    require(len(helpers) == 43 and len(consumers) == 125, 'complete finite source helper/consumer context domain')
    return helpers, consumers

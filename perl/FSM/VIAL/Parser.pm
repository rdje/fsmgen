package FSM::VIAL::Parser;

use strict;
use warnings;

use Digest::SHA qw(sha256_hex);
use Encode qw(decode encode FB_CROAK);
use JSON::PP ();
use Scalar::Util qw(blessed);

use constant {
    MAX_SOURCE_BYTES   => 1_048_576,
    MAX_COMBINED_BYTES => 16_777_216,
    MAX_IMPORTS        => 64,
    MAX_TOKENS         => 1_000_000,
    MAX_LIST_DEPTH     => 128,
};

sub check_source {
    my ($class, @call_args) = @_;
    my $args = $call_args[0];

    my ($ir, $diagnostics);
    my $ok = eval {
        _throw(
            'VIAL_SEMANTIC_ERROR', 'semantic',
            'check_source accepts exactly one invocation hash',
            _zero_location(_safe_diagnostic_source_name(ref($args) eq 'HASH' ? $args->{source_name} : undef)), '/',
        ) unless @call_args == 1;
        $ir = $class->_build_ir($args);
        1;
    };
    if (!$ok) {
        $diagnostics = _diagnostics_from_exception($@, $args);
    }

    if ($diagnostics) {
        return {
            ok => 0,
            diagnostics => _clone($diagnostics),
            semantic_report => undef,
        };
    }

    require FSM::VIAL::SemanticReport;
    return {
        ok => 1,
        diagnostics => [],
        semantic_report => FSM::VIAL::SemanticReport->build($ir),
    };
}

sub parse_source {
    my ($class, @call_args) = @_;
    my $args = $call_args[0];

    my $ir;
    my $ok = eval {
        _throw(
            'VIAL_SEMANTIC_ERROR', 'semantic',
            'parse_source accepts exactly one invocation hash',
            _zero_location(_safe_diagnostic_source_name(ref($args) eq 'HASH' ? $args->{source_name} : undef)), '/',
        ) unless @call_args == 1;
        $ir = $class->_build_ir($args);
        1;
    };
    return $ir if $ok;

    my $diagnostics = _diagnostics_from_exception($@, $args);
    die _format_diagnostic($diagnostics->[0]);
}

sub _build_ir {
    my ($class, $args) = @_;
    my $input = _validate_invocation($args);

    my $state = {
        catalog => $input->{source_catalog},
        forms => {},
        source_records => [],
        source_text => {},
        visiting => [],
        visited => {},
        combined_bytes => 0,
        import_count => 0,
        token_count => 0,
    };
    _visit_source($state, $input->{source_name}, $input->{text}, undef);

    require FSM::VIAL::SemanticBuilder;
    return FSM::VIAL::SemanticBuilder->build({
        root_source_name => $input->{source_name},
        forms => $state->{forms},
        sources => $state->{source_records},
    });
}

sub _validate_invocation {
    my ($args) = @_;
    if (ref($args) ne 'HASH' || blessed($args)) {
        _throw(
            'VIAL_SEMANTIC_ERROR', 'semantic',
            'invocation must be one unblessed hash',
            _zero_location('vial/input.vial'), '/',
        );
    }

    my %allowed = map { $_ => 1 } qw(text source_name source_catalog);
    my @unknown = sort grep { !$allowed{$_} } keys %{$args};
    if (@unknown) {
        my $source_name = _safe_diagnostic_source_name($args->{source_name});
        _throw(
            'VIAL_SEMANTIC_ERROR', 'semantic',
            "unknown invocation key '$unknown[0]'",
            _zero_location($source_name), '/',
        );
    }

    for my $required (qw(text source_name)) {
        if (!exists($args->{$required}) || !defined($args->{$required}) || ref($args->{$required})) {
            my $source_name = _safe_diagnostic_source_name($args->{source_name});
            _throw(
                'VIAL_SEMANTIC_ERROR', 'semantic',
                "invocation key '$required' must be a scalar",
                _zero_location($source_name), '/',
            );
        }
    }

    _validate_source_name($args->{source_name}, _zero_location(_safe_diagnostic_source_name($args->{source_name})));

    my $catalog = exists($args->{source_catalog}) ? $args->{source_catalog} : {};
    if (ref($catalog) ne 'HASH' || blessed($catalog)) {
        _throw(
            'VIAL_SEMANTIC_ERROR', 'semantic',
            "invocation key 'source_catalog' must be an unblessed hash",
            _zero_location($args->{source_name}), '/',
        );
    }

    my %catalog_copy;
    for my $source_name (sort keys %{$catalog}) {
        _validate_source_name($source_name, _zero_location($args->{source_name}));
        if (!defined($catalog->{$source_name}) || ref($catalog->{$source_name})) {
            _throw(
                'VIAL_SEMANTIC_ERROR', 'semantic',
                "source catalog value for '$source_name' must be a scalar",
                _zero_location($args->{source_name}), '/',
            );
        }
        $catalog_copy{$source_name} = $catalog->{$source_name};
    }

    return {
        text => $args->{text},
        source_name => $args->{source_name},
        source_catalog => \%catalog_copy,
    };
}

sub _visit_source {
    my ($state, $source_name, $text, $import_span) = @_;
    return if $state->{visited}{$source_name};

    my %visiting = map { $_ => 1 } @{$state->{visiting}};
    if ($visiting{$source_name}) {
        my @notes = map {
            {
                message => "import edge through '$_'",
                source_location => undef,
            }
        } (@{$state->{visiting}}, $source_name);
        _throw(
            'VIAL_IMPORT_ERROR', 'import',
            "import cycle reaches '$source_name'",
            $import_span || _zero_location($source_name), '/packages/0/imports', \@notes,
        );
    }

    my $bytes = _as_utf8_bytes($text, $source_name);
    my $byte_length = length($bytes);
    if ($byte_length > MAX_SOURCE_BYTES) {
        _throw(
            'VIAL_LIMIT_ERROR', 'limit',
            "source exceeds the 1048576-byte limit",
            _zero_location($source_name), '/',
        );
    }
    $state->{combined_bytes} += $byte_length;
    if ($state->{combined_bytes} > MAX_COMBINED_BYTES) {
        _throw(
            'VIAL_LIMIT_ERROR', 'limit',
            'combined imported source bytes exceed the 16777216-byte limit',
            $import_span || _zero_location($source_name), '/packages/0/imports',
        );
    }

    push @{$state->{visiting}}, $source_name;
    my ($parsed_form, $token_count) = _lex_and_parse($bytes, $source_name);
    $state->{token_count} += $token_count;
    if ($state->{token_count} > MAX_TOKENS) {
        _throw(
            'VIAL_LIMIT_ERROR', 'limit',
            'tokens across imported sources exceed the 1000000-token limit',
            $parsed_form->{span}, '/',
        );
    }

    require FSM::VIAL::SourceProjection;
    my ($form) = FSM::VIAL::SourceProjection->_normalize_parsed_form({
        form => $parsed_form,
        source_name => $source_name,
    });

    $state->{forms}{$source_name} = $form;
    $state->{source_text}{$source_name} = $bytes;
    push @{$state->{source_records}}, {
        source_name => $source_name,
        content_sha256 => sha256_hex($bytes),
        byte_length => $byte_length,
        line_ending => _line_ending($bytes),
    };

    for my $import (_imports_from_form($form)) {
        my ($alias, $path, $span) = @{$import};
        _validate_source_name($path, $span, 'VIAL_IMPORT_ERROR');
        ++$state->{import_count};
        if ($state->{import_count} > MAX_IMPORTS) {
            _throw(
                'VIAL_LIMIT_ERROR', 'limit',
                'imported sources exceed the 64-source limit',
                $span, '/packages/0/imports',
            );
        }
        if (!exists $state->{catalog}{$path}) {
            _throw(
                'VIAL_IMPORT_ERROR', 'import',
                "import '$alias' requires missing catalog source '$path'",
                $span, '/packages/0/imports',
            );
        }
        _visit_source($state, $path, $state->{catalog}{$path}, $span);
    }

    pop @{$state->{visiting}};
    $state->{visited}{$source_name} = 1;
}

sub _parse_source_form_for_projection {
    my ($class, $args) = @_;
    die "VIAL source-form parsing is private to FSM::VIAL::SourceProjection\n"
        unless caller eq 'FSM::VIAL::SourceProjection';
    die "VIAL source-form parsing requires one unblessed hash\n"
        unless ref($args) eq 'HASH' && !blessed($args);
    my %allowed = map { $_ => 1 } qw(text source_name);
    my @unknown = sort grep { !$allowed{$_} } keys %{$args};
    die "VIAL source-form parsing received unknown key '$unknown[0]'\n" if @unknown;
    for my $required (qw(text source_name)) {
        die "VIAL source-form parsing requires scalar '$required'\n"
            unless exists($args->{$required}) && defined($args->{$required}) && !ref($args->{$required});
    }
    _validate_source_name($args->{source_name}, _zero_location(_safe_diagnostic_source_name($args->{source_name})));
    my $bytes = _as_utf8_bytes($args->{text}, $args->{source_name});
    _throw(
        'VIAL_LIMIT_ERROR', 'limit', 'source exceeds the 1048576-byte limit',
        _zero_location($args->{source_name}), '/',
    ) if length($bytes) > MAX_SOURCE_BYTES;
    my ($form, $token_count) = _lex_and_parse($bytes, $args->{source_name});
    return (_clone($form), $token_count);
}

sub _imports_from_form {
    my ($root) = @_;
    return () unless _is_list($root) && @{$root->{items}} == 3;
    return () unless _atom_value($root->{items}[0]) eq 'vial';
    my $package = $root->{items}[2];
    return () unless _is_list($package) && @{$package->{items}} >= 3;
    return () unless _atom_value($package->{items}[0]) eq 'package';
    my $imports = $package->{items}[2];
    return () unless _is_list($imports) && @{$imports->{items}} >= 1;
    return () unless _atom_value($imports->{items}[0]) eq 'imports';

    my @result;
    for my $import (@{$imports->{items}}[1 .. $#{$imports->{items}}]) {
        next unless _is_list($import) && @{$import->{items}} == 3;
        next unless _atom_value($import->{items}[0]) eq 'import';
        next unless ($import->{items}[1]{atom_kind} || '') eq 'identifier';
        next unless ($import->{items}[2]{atom_kind} || '') eq 'string';
        push @result, [
            $import->{items}[1]{value},
            $import->{items}[2]{value},
            $import->{items}[2]{span},
        ];
    }
    return @result;
}

sub _lex_and_parse {
    my ($bytes, $source_name) = @_;
    my $decoded;
    eval { $decoded = decode('UTF-8', $bytes, FB_CROAK); 1 }
        or _throw(
            'VIAL_LEX_ERROR', 'lex', 'source is not valid UTF-8',
            _zero_location($source_name), '/',
        );

    if ($decoded =~ /\x00/) {
        my $prefix = substr($decoded, 0, $-[0]);
        _throw(
            'VIAL_LEX_ERROR', 'lex', 'NUL is not allowed in VIAL source',
            _location_after_prefix($source_name, $prefix, "\x00"), '/',
        );
    }
    if ($decoded =~ /\r(?!\n)/) {
        my $prefix = substr($decoded, 0, $-[0]);
        _throw(
            'VIAL_LEX_ERROR', 'lex', 'bare CR line ending is not allowed',
            _location_after_prefix($source_name, $prefix, "\r"), '/',
        );
    }

    my @chars = split //, $decoded;
    my @tokens;
    my ($index, $byte, $line, $column) = (0, 0, 1, 1);

    while ($index < @chars) {
        my $char = $chars[$index];
        if ($char eq ' ' || $char eq "\t" || $char eq "\f") {
            _advance(\@chars, \$index, \$byte, \$line, \$column);
            next;
        }
        if ($char eq "\n" || $char eq "\r") {
            _advance_newline(\@chars, \$index, \$byte, \$line, \$column);
            next;
        }
        if ($char eq ';') {
            while ($index < @chars && $chars[$index] ne "\n" && $chars[$index] ne "\r") {
                _advance(\@chars, \$index, \$byte, \$line, \$column);
            }
            next;
        }

        my ($start_byte, $start_line, $start_column) = ($byte, $line, $column);
        if ($char eq '(' || $char eq ')') {
            _advance(\@chars, \$index, \$byte, \$line, \$column);
            push @tokens, {
                kind => $char eq '(' ? 'open' : 'close',
                value => $char,
                span => _span(
                    $source_name, $start_byte, $byte,
                    $start_line, $start_column, $start_line, $start_column,
                ),
            };
            next;
        }

        if ($char eq '"') {
            my $raw = '"';
            _advance(\@chars, \$index, \$byte, \$line, \$column);
            my $closed = 0;
            while ($index < @chars) {
                my $current = $chars[$index];
                if ($current eq "\n" || $current eq "\r") {
                    _throw(
                        'VIAL_LEX_ERROR', 'lex', 'string literal crosses a line ending',
                        _span($source_name, $start_byte, $byte, $start_line, $start_column, $line, $column), '/',
                    );
                }
                $raw .= $current;
                _advance(\@chars, \$index, \$byte, \$line, \$column);
                if ($current eq '"') {
                    $closed = 1;
                    last;
                }
                if ($current eq '\\') {
                    if ($index >= @chars) {
                        last;
                    }
                    my $escaped = $chars[$index];
                    $raw .= $escaped;
                    _advance(\@chars, \$index, \$byte, \$line, \$column);
                    if ($escaped eq 'u') {
                        for (1 .. 4) {
                            last if $index >= @chars;
                            $raw .= $chars[$index];
                            _advance(\@chars, \$index, \$byte, \$line, \$column);
                        }
                    }
                }
            }
            my $span = _span(
                $source_name, $start_byte, $byte, $start_line, $start_column,
                $line, $column - 1,
            );
            if (!$closed) {
                _throw('VIAL_LEX_ERROR', 'lex', 'unterminated string literal', $span, '/');
            }
            my $value;
            eval { $value = JSON::PP->new->utf8(0)->decode($raw); 1 }
                or _throw('VIAL_LEX_ERROR', 'lex', 'invalid JSON string escape or surrogate pair', $span, '/');
            if ($value =~ /\x00/) {
                _throw('VIAL_LEX_ERROR', 'lex', 'decoded string may not contain NUL', $span, '/');
            }
            push @tokens, { kind => 'atom', atom_kind => 'string', value => $value, raw => $raw, span => $span };
            next;
        }

        my $raw = '';
        while ($index < @chars) {
            my $current = $chars[$index];
            last if $current eq '(' || $current eq ')' || $current eq ';';
            last if $current eq ' ' || $current eq "\t" || $current eq "\f"
                || $current eq "\n" || $current eq "\r";
            $raw .= $current;
            _advance(\@chars, \$index, \$byte, \$line, \$column);
        }
        my $span = _span(
            $source_name, $start_byte, $byte, $start_line, $start_column,
            $line, $column - 1,
        );
        my ($atom_kind, $value) = _classify_atom($raw, $span);
        push @tokens, {
            kind => 'atom', atom_kind => $atom_kind,
            value => $value, raw => $raw, span => $span,
        };
    }

    if (!@tokens) {
        _throw('VIAL_PARSE_ERROR', 'parse', 'source contains no root form', _zero_location($source_name), '/');
    }
    my $cursor = 0;
    my $root = _parse_node(\@tokens, \$cursor, 0);
    if ($cursor != @tokens) {
        _throw('VIAL_PARSE_ERROR', 'parse', 'source contains trailing tokens after the root form', $tokens[$cursor]{span}, '/');
    }
    return ($root, scalar @tokens);
}

sub _classify_atom {
    my ($raw, $span) = @_;
    if ($raw eq 'true' || $raw eq 'false') {
        return ('boolean', $raw eq 'true' ? 1 : 0);
    }
    if ($raw =~ /\A#b[01xXzZ](?:_?[01xXzZ])*\z/) {
        my $value = lc($raw);
        $value =~ s/_//g;
        return ('four_state', $value);
    }
    if ($raw =~ /\A(?:0|[1-9][0-9]*(?:_?[0-9])*)\z/
        || $raw =~ /\A-(?:0|[1-9][0-9]*(?:_?[0-9])*)\z/
        || $raw =~ /\A0b[01](?:_?[01])*\z/
        || $raw =~ /\A0x[0-9A-Fa-f](?:_?[0-9A-Fa-f])*\z/) {
        (my $value = $raw) =~ s/_//g;
        return ('integer', $value);
    }
    if ($raw =~ /\A[A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)*\z/) {
        for my $component (split /\./, $raw) {
            if (length(encode('UTF-8', $component)) > 128) {
                _throw('VIAL_LIMIT_ERROR', 'limit', 'identifier component exceeds 128 bytes', $span, '/');
            }
        }
        return ('identifier', $raw);
    }
    if ($raw =~ /\A(?:\+|-|<|<=|>|>=|=>)\z/) {
        return ('operator', $raw);
    }
    _throw('VIAL_LEX_ERROR', 'lex', "invalid token '$raw'", $span, '/');
}

sub _parse_node {
    no warnings 'recursion';
    my ($tokens, $cursor_ref, $depth) = @_;
    my $token = $tokens->[$$cursor_ref]
        or _throw('VIAL_PARSE_ERROR', 'parse', 'unexpected end of source', _zero_location('vial/input.vial'), '/');

    if ($token->{kind} eq 'close') {
        _throw('VIAL_PARSE_ERROR', 'parse', "unexpected ')'", $token->{span}, '/');
    }
    if ($token->{kind} eq 'atom') {
        ++$$cursor_ref;
        return {
            node_kind => 'atom', atom_kind => $token->{atom_kind},
            value => $token->{value}, raw => $token->{raw}, span => _clone($token->{span}),
        };
    }
    if ($depth >= MAX_LIST_DEPTH) {
        _throw('VIAL_LIMIT_ERROR', 'limit', 'list nesting exceeds the 128-level limit', $token->{span}, '/');
    }

    my $open = $token;
    ++$$cursor_ref;
    my @items;
    while ($$cursor_ref < @{$tokens} && $tokens->[$$cursor_ref]{kind} ne 'close') {
        push @items, _parse_node($tokens, $cursor_ref, $depth + 1);
    }
    if ($$cursor_ref >= @{$tokens}) {
        _throw('VIAL_PARSE_ERROR', 'parse', "unterminated '(' list", $open->{span}, '/');
    }
    my $close = $tokens->[$$cursor_ref];
    ++$$cursor_ref;
    return {
        node_kind => 'list',
        items => \@items,
        span => _span(
            $open->{span}{source_name},
            $open->{span}{start_byte}, $close->{span}{end_byte_exclusive},
            $open->{span}{start_line}, $open->{span}{start_column},
            $close->{span}{end_line}, $close->{span}{end_column},
        ),
    };
}

sub _as_utf8_bytes {
    my ($text, $source_name) = @_;
    return encode('UTF-8', $text) if utf8::is_utf8($text);
    return $text;
}

sub _line_ending {
    my ($bytes) = @_;
    my $has_crlf = $bytes =~ /\r\n/ ? 1 : 0;
    (my $without_crlf = $bytes) =~ s/\r\n//g;
    my $has_lf = $without_crlf =~ /\n/ ? 1 : 0;
    return 'mixed' if $has_crlf && $has_lf;
    return 'crlf' if $has_crlf;
    return 'lf';
}

sub _validate_source_name {
    my ($source_name, $span, $code) = @_;
    $code ||= 'VIAL_SEMANTIC_ERROR';
    my $phase = $code eq 'VIAL_IMPORT_ERROR' ? 'import' : 'semantic';
    my $valid = defined($source_name)
        && !ref($source_name)
        && length($source_name)
        && $source_name =~ /\.vial\z/
        && $source_name !~ m{(?:\A/|\\|\A~|\A[A-Za-z]:|://|\x00)};
    if ($valid) {
        my @segments = split m{/}, $source_name, -1;
        $valid = !grep { $_ eq '' || $_ eq '.' || $_ eq '..' } @segments;
    }
    _throw($code, $phase, "unsafe VIAL source name", $span, '/') unless $valid;
}

sub _safe_diagnostic_source_name {
    my ($candidate) = @_;
    return 'vial/input.vial' if !defined($candidate) || ref($candidate);
    return $candidate if $candidate =~ /\A[A-Za-z0-9_][A-Za-z0-9_.\/-]*\.vial\z/;
    return 'vial/input.vial';
}

sub _advance {
    my ($chars, $index_ref, $byte_ref, $line_ref, $column_ref) = @_;
    my $char = $chars->[$$index_ref];
    $$byte_ref += length(encode('UTF-8', $char));
    ++$$index_ref;
    ++$$column_ref;
}

sub _advance_newline {
    my ($chars, $index_ref, $byte_ref, $line_ref, $column_ref) = @_;
    if ($chars->[$$index_ref] eq "\r") {
        $$byte_ref += 1;
        ++$$index_ref;
    }
    if ($$index_ref < @{$chars} && $chars->[$$index_ref] eq "\n") {
        $$byte_ref += 1;
        ++$$index_ref;
    }
    ++$$line_ref;
    $$column_ref = 1;
}

sub _location_after_prefix {
    my ($source_name, $prefix, $char) = @_;
    my $bytes = length(encode('UTF-8', $prefix));
    my @lines = split /\r\n|\n/, $prefix, -1;
    @lines = ('') unless @lines;
    my $line = scalar @lines;
    my $column = length($lines[-1]) + 1;
    return _span($source_name, $bytes, $bytes + length(encode('UTF-8', $char)), $line, $column, $line, $column);
}

sub _span {
    my ($source_name, $start_byte, $end_byte, $start_line, $start_column, $end_line, $end_column) = @_;
    return {
        source_name => $source_name,
        start_byte => 0 + $start_byte,
        end_byte_exclusive => 0 + $end_byte,
        start_line => 0 + $start_line,
        start_column => 0 + $start_column,
        end_line => 0 + $end_line,
        end_column => 0 + $end_column,
    };
}

sub _zero_location {
    my ($source_name) = @_;
    return _span($source_name, 0, 0, 1, 1, 1, 1);
}

sub _throw {
    my ($code, $phase, $message, $location, $semantic_path, $notes) = @_;
    $message =~ s/[\r\n]+/ /g;
    die bless({
        schema_version => 1,
        severity => 'error',
        code => $code,
        phase => $phase,
        message => $message,
        semantic_path => defined($semantic_path) ? $semantic_path : '/',
        source_location => _clone($location),
        notes => _clone($notes || []),
    }, 'FSM::VIAL::Diagnostic');
}

sub _diagnostics_from_exception {
    my ($exception, $args) = @_;
    if (blessed($exception) && $exception->isa('FSM::VIAL::DiagnosticBundle')) {
        return _clone($exception->{diagnostics});
    }
    if (blessed($exception) && $exception->isa('FSM::VIAL::Diagnostic')) {
        return [_clone($exception)];
    }
    my $source_name = ref($args) eq 'HASH'
        ? _safe_diagnostic_source_name($args->{source_name})
        : 'vial/input.vial';
    return [{
        schema_version => 1,
        severity => 'error',
        code => 'VIAL_SEMANTIC_ERROR',
        phase => 'semantic',
        message => 'internal semantic validation failed closed',
        semantic_path => '/',
        source_location => _zero_location($source_name),
        notes => [],
    }];
}

sub _format_diagnostic {
    my ($diagnostic) = @_;
    my $location = $diagnostic->{source_location};
    return sprintf(
        "Error [%s] %s:%d:%d %s: %s\n",
        $diagnostic->{code}, $location->{source_name},
        $location->{start_line}, $location->{start_column},
        $diagnostic->{semantic_path}, $diagnostic->{message},
    );
}

sub _is_list {
    my ($node) = @_;
    return ref($node) eq 'HASH' && ($node->{node_kind} || '') eq 'list';
}

sub _atom_value {
    my ($node) = @_;
    return '' unless ref($node) eq 'HASH' && ($node->{node_kind} || '') eq 'atom';
    return defined($node->{value}) ? $node->{value} : '';
}

sub _clone {
    my ($value) = @_;
    return undef unless defined $value;
    return { map { $_ => _clone($value->{$_}) } sort keys %{$value} } if ref($value) eq 'HASH' || blessed($value);
    return [map { _clone($_) } @{$value}] if ref($value) eq 'ARRAY';
    return $value;
}

1;

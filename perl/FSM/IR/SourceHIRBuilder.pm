package FSM::IR::SourceHIRBuilder;

=head1 NAME

FSM::IR::SourceHIRBuilder - Validate and build private SourceHIR v1 objects

=cut

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::IR::SourceHIR;

my @TOP_KEYS = qw(
    schema_version root_kind intent_name profile source_object
    valid_ready_channel provenance
);
my @SOURCE_KEYS = qw(id anchors);
my @ANCHOR_KEYS = qw(document section page);
my @CHANNEL_KEYS = qw(name channel role clock reset valid ready payload);
my @RESET_KEYS = qw(signal active_level kind);
my @PAYLOAD_KEYS = qw(name width);
my @PROVENANCE_KEYS = qw(source_name spans);
my @SPAN_KEYS = qw(start_line start_column end_line end_column);

sub validate_valid_ready ($class, @args) {
    _validate_class_call($class, 'validate_valid_ready', \@args);
    my ($diagnostics) = _validate_and_normalize($args[0]);
    return _clone($diagnostics);
}

sub build_valid_ready ($class, @args) {
    _validate_class_call($class, 'build_valid_ready', \@args);
    my ($diagnostics, $normalized) = _validate_and_normalize($args[0]);
    confess _format_diagnostic($diagnostics->[0]) if @$diagnostics;
    return FSM::IR::SourceHIR->_new_validated($normalized);
}

sub _validate_class_call ($class, $method, $args) {
    confess "FSM::IR::SourceHIRBuilder->$method must be called with the FSM::IR::SourceHIRBuilder class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    confess "FSM::IR::SourceHIRBuilder->$method expects exactly one input hash reference\n"
        unless @$args == 1;
}

sub _validate_and_normalize ($raw_input) {
    my @diagnostics;

    unless (ref($raw_input) eq 'HASH') {
        _add_diagnostic(\@diagnostics, $raw_input, '/', 'input must be a hash reference');
        return (\@diagnostics, undef);
    }

    my $input = _clone($raw_input);
    _validate_unknown_keys(\@diagnostics, $input, \@TOP_KEYS, '/', $input);
    _validate_exact_integer(\@diagnostics, $input, '/schema_version', 'schema_version', 1, 1);
    _validate_exact_scalar(\@diagnostics, $input, '/root_kind', 'root_kind', 'protocol_platform_intent');
    _validate_identifier_field(\@diagnostics, $input, '/intent_name', 'intent_name');
    _validate_exact_scalar(\@diagnostics, $input, '/profile', 'profile', 'valid-ready');

    _validate_source_object(\@diagnostics, $input);
    _validate_channel(\@diagnostics, $input);
    _validate_interface_uniqueness(\@diagnostics, $input);
    _validate_provenance(\@diagnostics, $input);

    return (\@diagnostics, undef) if @diagnostics;

    my $normalized = _clone($input);
    $normalized->{schema_version} = int($normalized->{schema_version});
    $normalized->{valid_ready_channel}{reset}{active_level}
        = int($normalized->{valid_ready_channel}{reset}{active_level});
    for my $payload (@{$normalized->{valid_ready_channel}{payload}}) {
        $payload->{width} = int($payload->{width});
    }
    for my $span (values %{$normalized->{provenance}{spans}}) {
        $span->{$_} = int($span->{$_}) for @SPAN_KEYS;
    }

    return (\@diagnostics, $normalized);
}

sub _validate_source_object ($diagnostics, $input) {
    my $source = $input->{source_object};
    unless (ref($source) eq 'HASH') {
        _add_diagnostic($diagnostics, $input, '/source_object', "field 'source_object' must be a hash reference");
        return;
    }

    _validate_unknown_keys($diagnostics, $source, \@SOURCE_KEYS, '/source_object', $input);
    _validate_atom_field($diagnostics, $source, '/source_object/id', 'id', $input);

    my $anchors = $source->{anchors};
    unless (ref($anchors) eq 'ARRAY' && @$anchors) {
        _add_diagnostic($diagnostics, $input, '/source_object/anchors', "field 'anchors' must be a non-empty array reference");
        return;
    }

    for my $index (0 .. $#$anchors) {
        my $anchor = $anchors->[$index];
        my $base = "/source_object/anchors/$index";
        unless (ref($anchor) eq 'HASH') {
            _add_diagnostic($diagnostics, $input, $base, 'anchor must be a hash reference');
            next;
        }
        _validate_unknown_keys($diagnostics, $anchor, \@ANCHOR_KEYS, $base, $input);
        _validate_atom_field($diagnostics, $anchor, "$base/document", 'document', $input);
        _validate_atom_field($diagnostics, $anchor, "$base/section", 'section', $input);
        _validate_atom_field($diagnostics, $anchor, "$base/page", 'page', $input);
    }
}

sub _validate_channel ($diagnostics, $input) {
    my $channel = $input->{valid_ready_channel};
    unless (ref($channel) eq 'HASH') {
        _add_diagnostic($diagnostics, $input, '/valid_ready_channel', "field 'valid_ready_channel' must be a hash reference");
        return;
    }

    _validate_unknown_keys($diagnostics, $channel, \@CHANNEL_KEYS, '/valid_ready_channel', $input);
    _validate_identifier_field($diagnostics, $channel, '/valid_ready_channel/name', 'name', $input);
    _validate_identifier_field($diagnostics, $channel, '/valid_ready_channel/channel', 'channel', $input);
    _validate_enum_field(
        $diagnostics, $channel, '/valid_ready_channel/role', 'role',
        [qw(producer-to-consumer consumer-to-producer)], $input,
    );
    _validate_identifier_field($diagnostics, $channel, '/valid_ready_channel/clock', 'clock', $input);

    my $reset = $channel->{reset};
    if (ref($reset) eq 'HASH') {
        _validate_unknown_keys($diagnostics, $reset, \@RESET_KEYS, '/valid_ready_channel/reset', $input);
        _validate_identifier_field($diagnostics, $reset, '/valid_ready_channel/reset/signal', 'signal', $input);
        _validate_exact_integer(
            $diagnostics, $reset, '/valid_ready_channel/reset/active_level',
            'active_level', 0, 1, $input,
        );
        _validate_enum_field(
            $diagnostics, $reset, '/valid_ready_channel/reset/kind', 'kind',
            [qw(async sync)], $input,
        );
    } else {
        _add_diagnostic($diagnostics, $input, '/valid_ready_channel/reset', "field 'reset' must be a hash reference");
    }

    _validate_identifier_field($diagnostics, $channel, '/valid_ready_channel/valid', 'valid', $input);
    _validate_identifier_field($diagnostics, $channel, '/valid_ready_channel/ready', 'ready', $input);

    my $payload = $channel->{payload};
    unless (ref($payload) eq 'ARRAY' && @$payload) {
        _add_diagnostic($diagnostics, $input, '/valid_ready_channel/payload', "field 'payload' must be a non-empty array reference");
        return;
    }

    for my $index (0 .. $#$payload) {
        my $item = $payload->[$index];
        my $base = "/valid_ready_channel/payload/$index";
        unless (ref($item) eq 'HASH') {
            _add_diagnostic($diagnostics, $input, $base, 'payload item must be a hash reference');
            next;
        }
        _validate_unknown_keys($diagnostics, $item, \@PAYLOAD_KEYS, $base, $input);
        _validate_identifier_field($diagnostics, $item, "$base/name", 'name', $input);
        _validate_positive_integer_field($diagnostics, $item, "$base/width", 'width', $input);
    }
}

sub _validate_interface_uniqueness ($diagnostics, $input) {
    my $channel = $input->{valid_ready_channel};
    return unless ref($channel) eq 'HASH';
    return unless _is_identifier($channel->{name});

    my @entries;
    push @entries, [$channel->{valid}, '/valid_ready_channel/valid']
        if _is_identifier($channel->{valid});
    push @entries, [$channel->{ready}, '/valid_ready_channel/ready']
        if _is_identifier($channel->{ready});

    if (ref($channel->{payload}) eq 'ARRAY') {
        for my $index (0 .. $#{$channel->{payload}}) {
            my $item = $channel->{payload}[$index];
            push @entries, [$item->{name}, "/valid_ready_channel/payload/$index/name"]
                if ref($item) eq 'HASH' && _is_identifier($item->{name});
        }
    }

    push @entries, ["$channel->{name}_valid_ready_monitor_done", '/valid_ready_channel/name'];

    my %seen;
    for my $entry (@entries) {
        my ($name, $path) = @$entry;
        if ($seen{$name}++) {
            _add_diagnostic($diagnostics, $input, $path, "interface signal '$name' is duplicated");
        }
    }
}

sub _validate_provenance ($diagnostics, $input) {
    my $provenance = $input->{provenance};
    unless (ref($provenance) eq 'HASH') {
        _add_diagnostic($diagnostics, $input, '/provenance', "field 'provenance' must be a hash reference");
        return;
    }

    _validate_unknown_keys($diagnostics, $provenance, \@PROVENANCE_KEYS, '/provenance', $input);
    unless (_valid_source_name($provenance->{source_name})) {
        _add_diagnostic(
            $diagnostics, $input, '/provenance/source_name',
            "field 'source_name' must be a repository-relative or stable logical name",
        );
    }

    my $spans = $provenance->{spans};
    unless (ref($spans) eq 'HASH') {
        _add_diagnostic($diagnostics, $input, '/provenance/spans', "field 'spans' must be a hash reference");
        return;
    }

    _add_diagnostic($diagnostics, $input, '/provenance/spans', "field 'spans' must contain root path '/'")
        unless exists $spans->{'/'};

    my $recognized = _recognized_paths($input);
    for my $path (sort keys %$spans) {
        unless ($recognized->{$path}) {
            _add_diagnostic($diagnostics, $input, '/provenance/spans', "span path '$path' is not present in SourceHIR v1");
            next;
        }

        my $span = $spans->{$path};
        unless (ref($span) eq 'HASH') {
            _add_diagnostic($diagnostics, $input, '/provenance/spans', "span '$path' must be a hash reference");
            next;
        }

        _validate_unknown_keys($diagnostics, $span, \@SPAN_KEYS, '/provenance/spans', $input);
        my $valid = 1;
        for my $key (@SPAN_KEYS) {
            unless (_is_positive_integer($span->{$key})) {
                _add_diagnostic($diagnostics, $input, '/provenance/spans', "span '$path' field '$key' must be a positive integer");
                $valid = 0;
            }
        }
        next unless $valid;

        my ($sl, $sc, $el, $ec) = @{$span}{@SPAN_KEYS};
        if ($el < $sl || ($el == $sl && $ec < $sc)) {
            _add_diagnostic($diagnostics, $input, '/provenance/spans', "span '$path' end must not precede its start");
        }
    }
}

sub _recognized_paths ($input) {
    my %paths = map { $_ => 1 } qw(
        / /schema_version /root_kind /intent_name /profile
        /source_object /source_object/id /source_object/anchors
        /valid_ready_channel /valid_ready_channel/name
        /valid_ready_channel/channel /valid_ready_channel/role
        /valid_ready_channel/clock /valid_ready_channel/reset
        /valid_ready_channel/reset/signal
        /valid_ready_channel/reset/active_level
        /valid_ready_channel/reset/kind /valid_ready_channel/valid
        /valid_ready_channel/ready /valid_ready_channel/payload
        /provenance /provenance/source_name /provenance/spans
    );

    if (ref($input->{source_object}) eq 'HASH' && ref($input->{source_object}{anchors}) eq 'ARRAY') {
        for my $index (0 .. $#{$input->{source_object}{anchors}}) {
            my $base = "/source_object/anchors/$index";
            $paths{$base} = 1;
            $paths{"$base/$_"} = 1 for @ANCHOR_KEYS;
        }
    }

    if (ref($input->{valid_ready_channel}) eq 'HASH'
        && ref($input->{valid_ready_channel}{payload}) eq 'ARRAY') {
        for my $index (0 .. $#{$input->{valid_ready_channel}{payload}}) {
            my $base = "/valid_ready_channel/payload/$index";
            $paths{$base} = 1;
            $paths{"$base/$_"} = 1 for @PAYLOAD_KEYS;
        }
    }

    return \%paths;
}

sub _validate_unknown_keys ($diagnostics, $value, $allowed, $path, $input = undef) {
    my %allowed = map { $_ => 1 } @$allowed;
    for my $key (sort grep { !$allowed{$_} } keys %$value) {
        _add_diagnostic($diagnostics, $input // $value, $path, "unsupported field '$key'");
    }
}

sub _validate_exact_scalar ($diagnostics, $hash, $path, $key, $expected, $input = undef) {
    my $value = $hash->{$key};
    _add_diagnostic($diagnostics, $input // $hash, $path, "field '$key' must be '$expected'")
        unless defined($value) && !ref($value) && $value eq $expected;
}

sub _validate_exact_integer ($diagnostics, $hash, $path, $key, $minimum, $maximum, $input = undef) {
    my $value = $hash->{$key};
    _add_diagnostic($diagnostics, $input // $hash, $path, "field '$key' must be an integer from $minimum through $maximum")
        unless _is_nonnegative_integer($value) && $value >= $minimum && $value <= $maximum;
}

sub _validate_positive_integer_field ($diagnostics, $hash, $path, $key, $input) {
    _add_diagnostic($diagnostics, $input, $path, "field '$key' must be a positive integer")
        unless _is_positive_integer($hash->{$key});
}

sub _validate_identifier_field ($diagnostics, $hash, $path, $key, $input = undef) {
    _add_diagnostic($diagnostics, $input // $hash, $path, "field '$key' must be an ISF identifier")
        unless _is_identifier($hash->{$key});
}

sub _validate_atom_field ($diagnostics, $hash, $path, $key, $input) {
    my $value = $hash->{$key};
    _add_diagnostic($diagnostics, $input, $path, "field '$key' must be a PPIF atom")
        unless defined($value) && !ref($value) && $value =~ /\A[^\s()]+\z/;
}

sub _validate_enum_field ($diagnostics, $hash, $path, $key, $allowed, $input) {
    my %allowed = map { $_ => 1 } @$allowed;
    my $value = $hash->{$key};
    _add_diagnostic($diagnostics, $input, $path, "field '$key' must be one of " . join(', ', @$allowed))
        unless defined($value) && !ref($value) && $allowed{$value};
}

sub _add_diagnostic ($diagnostics, $input, $path, $message) {
    push @$diagnostics, {
        schema_version => 1,
        severity => 'error',
        code => 'FSMGEN_SOURCE_HIR_INVALID',
        phase => 'source_hir_validation',
        message => $message,
        semantic_path => $path,
        source_location => _source_location_from_raw($input, $path),
    };
}

sub _source_location_from_raw ($input, $path) {
    my $fallback_name = 'source-hir-input';
    return {source_name => $fallback_name} unless ref($input) eq 'HASH';

    my $provenance = $input->{provenance};
    return {source_name => $fallback_name} unless ref($provenance) eq 'HASH';
    my $source_name = _valid_source_name($provenance->{source_name})
        ? $provenance->{source_name}
        : $fallback_name;
    my $spans = $provenance->{spans};
    return {source_name => $source_name} unless ref($spans) eq 'HASH';

    my $candidate = $path;
    while (1) {
        my $span = $spans->{$candidate};
        if (_valid_span($span)) {
            return {
                source_name => $source_name,
                %{_clone($span)},
            };
        }
        last if $candidate eq '/';
        $candidate =~ s{/[^/]+\z}{};
        $candidate = '/' if $candidate eq '';
    }

    return {source_name => $source_name};
}

sub _format_diagnostic ($diagnostic) {
    my $location = $diagnostic->{source_location};
    my $where = $location->{source_name};
    $where .= ":$location->{start_line}:$location->{start_column}"
        if defined $location->{start_line};
    return "Error [$diagnostic->{code}] $where $diagnostic->{semantic_path}: $diagnostic->{message}\n";
}

sub _valid_span ($span) {
    return 0 unless ref($span) eq 'HASH';
    return 0 unless !grep { !_is_positive_integer($span->{$_}) } @SPAN_KEYS;
    return 0 if $span->{end_line} < $span->{start_line};
    return 0 if $span->{end_line} == $span->{start_line}
        && $span->{end_column} < $span->{start_column};
    return 1;
}

sub _valid_source_name ($value) {
    return 0 if !defined($value) || ref($value) || $value eq '';
    return 0 if $value =~ /[\0\\]/;
    return 0 if $value =~ m{\A/} || $value =~ /\A~/ || $value =~ /\A[A-Za-z]:/;
    return 0 if $value =~ m{(?:\A|/)\.\.(?:/|\z)};
    return 1;
}

sub _is_identifier ($value) {
    return defined($value) && !ref($value) && $value =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/;
}

sub _is_positive_integer ($value) {
    return defined($value) && !ref($value) && $value =~ /\A[1-9][0-9]*\z/;
}

sub _is_nonnegative_integer ($value) {
    return defined($value) && !ref($value) && $value =~ /\A(?:0|[1-9][0-9]*)\z/;
}

sub _clone ($value) {
    return undef unless defined $value;
    return {map { $_ => _clone($value->{$_}) } sort keys %$value}
        if ref($value) eq 'HASH';
    return [map { _clone($_) } @$value] if ref($value) eq 'ARRAY';
    return $value;
}

1;

__END__

=head1 METHODS

=head2 validate_valid_ready

Returns all deterministic private version-1 validation diagnostics.

=head2 build_valid_ready

Returns an immutable validated C<FSM::IR::SourceHIR> or throws the formatted
first diagnostic.

=cut

package FSM::IR::StructuralRTLIR::ConnectionExpr;

=head1 NAME

FSM::IR::StructuralRTLIR::ConnectionExpr - Backend-neutral structural binding expression helpers

=head1 DESCRIPTION

Owns the typed actual-connection expression family used by the structural RTL
IR layer. This package defines portable connection nodes, binding
normalization, signal-dependency recovery, summary projection, and the current
backend rendering helpers for those structural expressions.

=cut

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Exporter qw(import);
use feature qw(signatures);
no warnings 'experimental::signatures';

our @EXPORT_OK = qw(
    open_expr
    signal_ref_expr
    member_access_expr
    index_access_expr
    bit_select_expr
    slice_expr
    concat_expr
    repeat_expr
    bit_vector_literal_expr
    signal_ref_binding
    update_binding_signal_ref
    ensure_signal_ref_binding
    set_signal_ref_binding
    normalized_binding
    binding_expr
    expr_signal_name
    expr_signal_names
    binding_signal_summary
    binding_signal_summaries_by_port
    binding_signal_summary_metadata
    binding_signal_summary_leaf_signal
    binding_signal_summary_text
    binding_signal_name
    binding_signal_names
    render_expr
    binding_expr_text
);

sub open_expr () {
    return {
        kind => 'open',
    };
}

sub signal_ref_expr ($signal_name) {
    return undef unless defined($signal_name) && length($signal_name);
    return {
        kind => 'signal_ref',
        signal_name => $signal_name,
    };
}

sub member_access_expr ($source, $member_name) {
    confess "StructuralRTLIR member-access expressions require an identifier-like member name"
        unless defined($member_name) && !ref($member_name) && $member_name =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/;

    my $source_expr = _coerce_source_expr($source);
    return {
        kind => 'member_access',
        source_expr => $source_expr,
        member_name => $member_name,
    };
}

sub index_access_expr ($source, $index) {
    confess "StructuralRTLIR index-access expressions require a numeric index"
        unless defined($index) && !ref($index) && $index =~ /\A\d+\z/;

    my $source_expr = _coerce_source_expr($source);
    return {
        kind => 'index_access',
        source_expr => $source_expr,
        index => 0 + $index,
    };
}

sub bit_select_expr ($source, $index) {
    confess "StructuralRTLIR bit_select expressions require a numeric index"
        unless defined($index) && $index =~ /^\d+$/;

    my $source_expr = _coerce_source_expr($source);
    return {
        kind => 'bit_select',
        source_expr => $source_expr,
        index => 0 + $index,
    };
}

sub slice_expr ($source, $msb, $lsb) {
    confess "StructuralRTLIR slice expressions require numeric msb/lsb bounds"
        unless defined($msb) && defined($lsb) && $msb =~ /^\d+$/ && $lsb =~ /^\d+$/;

    my $source_expr = _coerce_source_expr($source);
    return {
        kind => 'slice',
        source_expr => $source_expr,
        msb => 0 + $msb,
        lsb => 0 + $lsb,
    };
}

sub concat_expr (@operands) {
    confess "StructuralRTLIR concat expressions require at least one operand"
        unless @operands;

    return {
        kind => 'concat',
        operands => [ map { _coerce_source_expr($_) } @operands ],
    };
}

sub repeat_expr ($repeat_count, $operand) {
    confess "StructuralRTLIR repeat expressions require a positive repeat count"
        unless defined($repeat_count) && !ref($repeat_count) && $repeat_count =~ /\A[1-9]\d*\z/;

    return {
        kind => 'repeat',
        repeat_count => 0 + $repeat_count,
        operand => _coerce_source_expr($operand),
    };
}

sub bit_vector_literal_expr ($bits) {
    confess "StructuralRTLIR bit-vector literal expressions require a non-empty binary string"
        unless defined($bits) && !ref($bits) && $bits =~ /\A[01]+\z/;

    return {
        kind => 'bit_vector_literal',
        bits => $bits,
        width => length($bits),
    };
}

sub signal_ref_binding ($port_name, $signal_name) {
    return {
        port_name => $port_name,
        signal_name => $signal_name,
        connection_expr => signal_ref_expr($signal_name),
    };
}

sub update_binding_signal_ref ($binding, $signal_name) {
    confess "StructuralRTLIR bindings must be hash entries"
        unless ref($binding) eq 'HASH';

    $binding->{signal_name} = $signal_name;
    $binding->{connection_expr} = signal_ref_expr($signal_name);
    return $binding;
}

sub ensure_signal_ref_binding ($bindings, $port_name, $signal_name) {
    confess "StructuralRTLIR binding lists must be array entries"
        unless ref($bindings) eq 'ARRAY';

    for my $binding (@$bindings) {
        next unless (($binding->{port_name} || '') eq ($port_name || ''));
        if (binding_signal_name($binding) eq ($signal_name || '')) {
            $binding->{connection_expr} ||= signal_ref_expr($signal_name);
            return $binding;
        }
    }

    my $binding = signal_ref_binding($port_name, $signal_name);
    push @$bindings, $binding;
    return $binding;
}

sub set_signal_ref_binding ($bindings, $port_name, $signal_name) {
    confess "StructuralRTLIR binding lists must be array entries"
        unless ref($bindings) eq 'ARRAY';

    for my $binding (@$bindings) {
        next unless (($binding->{port_name} || '') eq ($port_name || ''));
        return update_binding_signal_ref($binding, $signal_name);
    }

    my $binding = signal_ref_binding($port_name, $signal_name);
    push @$bindings, $binding;
    return $binding;
}

sub normalized_binding ($binding) {
    confess "StructuralRTLIR bindings must be hash entries"
        unless ref($binding) eq 'HASH';

    my $port_name = $binding->{port_name};
    my $signal_name = $binding->{signal_name};
    my $connection_expr = _clone($binding->{connection_expr});

    if (!defined($signal_name) || !length($signal_name)) {
        $signal_name = expr_signal_name($connection_expr);
    }

    if ((!ref($connection_expr) || ref($connection_expr) ne 'HASH')
        && defined($signal_name) && length($signal_name))
    {
        $connection_expr = signal_ref_expr($signal_name);
    }

    my $normalized = {
        port_name => $port_name,
        signal_name => $signal_name,
        connection_expr => $connection_expr,
    };

    $normalized->{connection_type_name} = $binding->{connection_type_name}
        if exists($binding->{connection_type_name}) && defined($binding->{connection_type_name});
    $normalized->{connection_type_spec} = _clone($binding->{connection_type_spec})
        if exists($binding->{connection_type_spec}) && defined($binding->{connection_type_spec});

    return $normalized;
}

sub binding_expr ($binding) {
    return undef unless ref($binding) eq 'HASH';
    return $binding->{connection_expr} if ref($binding->{connection_expr}) eq 'HASH';
    return signal_ref_expr($binding->{signal_name});
}

sub expr_signal_name ($expr) {
    return '' unless ref($expr) eq 'HASH';
    my $kind = $expr->{kind} || '';
    return '' unless $kind eq 'signal_ref';
    return $expr->{signal_name} || '';
}

sub expr_signal_names ($expr) {
    return [] unless ref($expr) eq 'HASH';

    my $kind = $expr->{kind} || '';
    if ($kind eq 'signal_ref') {
        my $signal_name = $expr->{signal_name} || '';
        return length($signal_name) ? [$signal_name] : [];
    }

    if ($kind eq 'open') {
        return [];
    }

    if ($kind eq 'bit_vector_literal') {
        return [];
    }

    if ($kind eq 'member_access') {
        return expr_signal_names($expr->{source_expr});
    }

    if ($kind eq 'index_access') {
        return expr_signal_names($expr->{source_expr});
    }

    if ($kind eq 'bit_select' || $kind eq 'slice') {
        return expr_signal_names($expr->{source_expr});
    }

    if ($kind eq 'concat') {
        my @signal_names;
        for my $operand (@{$expr->{operands} || []}) {
            _push_unique_signal_names(\@signal_names, @{expr_signal_names($operand)});
        }
        return \@signal_names;
    }

    if ($kind eq 'repeat') {
        return expr_signal_names($expr->{operand});
    }

    confess "StructuralRTLIR connection_expr kind '$kind' has no recursive signal-name recovery rule.\n";
}

sub binding_signal_names ($binding) {
    return [] unless ref($binding) eq 'HASH';
    return expr_signal_names(binding_expr($binding));
}

sub binding_signal_summary ($binding) {
    return {
        bound_signal => '',
        bound_signals => [],
        bound_connection_expr => undef,
        bound_connection_type_name => undef,
        bound_connection_type_spec => undef,
    } unless ref($binding) eq 'HASH';

    my $summary = {
        bound_signal => binding_signal_name($binding),
        bound_signals => [ @{binding_signal_names($binding)} ],
        bound_connection_expr => _clone(binding_expr($binding)),
    };
    $summary->{bound_connection_type_name} = $binding->{connection_type_name}
        if exists($binding->{connection_type_name}) && defined($binding->{connection_type_name});
    $summary->{bound_connection_type_spec} = _clone($binding->{connection_type_spec})
        if exists($binding->{connection_type_spec}) && defined($binding->{connection_type_spec});
    return $summary;
}

sub binding_signal_summaries_by_port ($bindings) {
    my %summaries_by_port;
    return \%summaries_by_port unless ref($bindings) eq 'ARRAY';

    for my $binding (@$bindings) {
        next unless ref($binding) eq 'HASH';
        my $port_name = $binding->{port_name} || '';
        next unless length $port_name;
        $summaries_by_port{$port_name} = binding_signal_summary_metadata($binding);
    }

    return \%summaries_by_port;
}

sub binding_signal_summary_metadata ($value) {
    return {
        bound_signal => '',
        bound_signals => [],
        bound_connection_expr => undef,
    } unless ref($value) eq 'HASH';

    my $summary = (
        exists($value->{bound_signal})
            || exists($value->{bound_signals})
            || exists($value->{bound_connection_expr})
    )
        ? $value
        : binding_signal_summary($value);

    my $metadata = {
        bound_signal => $summary->{bound_signal} || '',
        bound_signals => [@{$summary->{bound_signals} || []}],
        bound_connection_expr => _clone($summary->{bound_connection_expr}),
    };
    $metadata->{bound_connection_type_name} = $summary->{bound_connection_type_name}
        if exists($summary->{bound_connection_type_name}) && defined($summary->{bound_connection_type_name});
    $metadata->{bound_connection_type_spec} = _clone($summary->{bound_connection_type_spec})
        if exists($summary->{bound_connection_type_spec}) && defined($summary->{bound_connection_type_spec});
    return $metadata;
}

sub binding_signal_summary_leaf_signal ($summary) {
    return '' unless ref($summary) eq 'HASH';

    my $bound_connection_expr = $summary->{bound_connection_expr};
    if (ref($bound_connection_expr) eq 'HASH') {
        my $leaf_signal = expr_signal_name($bound_connection_expr);
        return $leaf_signal if defined($leaf_signal) && length($leaf_signal);
        return '';
    }

    my $bound_signal = $summary->{bound_signal} || '';
    return $bound_signal;
}

sub binding_signal_summary_text ($summary, $target_language = 'systemverilog') {
    return '' unless ref($summary) eq 'HASH';

    my $expr = $summary->{bound_connection_expr};
    if (ref($expr) eq 'HASH') {
        my $rendered = eval {
            render_expr($expr, undef, _normalize_target_language_alias($target_language));
        };
        return $rendered if defined($rendered) && length($rendered);
    }

    my $bound_signal = $summary->{bound_signal} || '';
    return $bound_signal if length $bound_signal;

    my @bound_signals = grep { defined($_) && length($_) } @{$summary->{bound_signals} || []};
    return join(', ', @bound_signals) if @bound_signals;

    return '';
}

sub binding_signal_name ($binding) {
    return expr_signal_name(binding_expr($binding));
}

sub render_expr ($expr, $port_name = undef, $target_language = 'systemverilog') {
    return '' unless ref($expr) eq 'HASH';

    my $kind = $expr->{kind} || '';
    if ($kind eq 'open') {
        return '' if _is_verilog_family($target_language);
        return 'open' if defined($target_language) && lc($target_language) eq 'vhdl';
        _confess_unsupported_target_language($target_language, $port_name, $kind);
    }

    if ($kind eq 'member_access') {
        my $language = defined($target_language) ? lc($target_language) : '';
        _confess_unsupported_target_language($target_language, $port_name, $kind)
            unless $language eq 'systemverilog' || $language eq 'vhdl';
        my $source_text = render_expr($expr->{source_expr}, $port_name, $target_language);
        my $member_name = $expr->{member_name} // '';
        confess "StructuralRTLIR member-access expressions must preserve an identifier-like member name.\n"
            unless $member_name =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/;
        return sprintf('%s.%s', $source_text, $member_name);
    }

    if ($kind eq 'index_access') {
        my $language = defined($target_language) ? lc($target_language) : '';
        _confess_unsupported_target_language($target_language, $port_name, $kind)
            unless $language eq 'systemverilog' || $language eq 'verilog' || $language eq 'vhdl';
        my $source_text = render_expr($expr->{source_expr}, $port_name, $target_language);
        my $index = $expr->{index};
        confess "StructuralRTLIR index-access expressions must preserve a numeric index.\n"
            unless defined($index) && $index =~ /\A\d+\z/;
        return $language eq 'vhdl'
            ? sprintf('%s(%d)', $source_text, $index)
            : sprintf('%s[%d]', $source_text, $index);
    }

    return $expr->{signal_name}
        if $kind eq 'signal_ref' && defined($expr->{signal_name}) && length($expr->{signal_name});

    if ($kind eq 'bit_select') {
        my $language = defined($target_language) ? lc($target_language) : '';
        _confess_unsupported_target_language($target_language, $port_name, $kind)
            unless _is_verilog_family($target_language) || $language eq 'vhdl';
        my $source_text = render_expr($expr->{source_expr}, $port_name, $target_language);
        return $language eq 'vhdl'
            ? sprintf('%s(%d)', $source_text, $expr->{index})
            : sprintf('%s[%d]', $source_text, $expr->{index});
    }

    if ($kind eq 'slice') {
        my $language = defined($target_language) ? lc($target_language) : '';
        _confess_unsupported_target_language($target_language, $port_name, $kind)
            unless _is_verilog_family($target_language) || $language eq 'vhdl';
        my $source_text = render_expr($expr->{source_expr}, $port_name, $target_language);
        return sprintf('%s[%d:%d]', $source_text, $expr->{msb}, $expr->{lsb})
            if _is_verilog_family($target_language);

        my $direction = $expr->{msb} >= $expr->{lsb} ? 'downto' : 'to';
        return sprintf('%s(%d %s %d)', $source_text, $expr->{msb}, $direction, $expr->{lsb});
    }

    if ($kind eq 'concat') {
        my $language = defined($target_language) ? lc($target_language) : '';
        _confess_unsupported_target_language($target_language, $port_name, $kind)
            unless _is_verilog_family($target_language) || $language eq 'vhdl';
        my @operand_text = map {
            render_expr($_, $port_name, $target_language)
        } @{ $expr->{operands} || [] };
        confess "StructuralRTLIR concat expressions must preserve at least one operand.\n"
            unless @operand_text;
        return join(' & ', @operand_text) if $language eq 'vhdl';
        return '{' . join(', ', @operand_text) . '}';
    }

    if ($kind eq 'repeat') {
        my $language = defined($target_language) ? lc($target_language) : '';
        _confess_unsupported_target_language($target_language, $port_name, $kind)
            unless _is_verilog_family($target_language) || $language eq 'vhdl';
        my $repeat_count = $expr->{repeat_count};
        confess "StructuralRTLIR repeat expressions must preserve a positive repeat count.\n"
            unless defined($repeat_count) && $repeat_count =~ /\A[1-9]\d*\z/;
        my $operand_text = render_expr($expr->{operand}, $port_name, $target_language);
        return join(' & ', map { $operand_text } 1 .. $repeat_count)
            if $language eq 'vhdl';
        return sprintf('{%d{%s}}', $repeat_count, $operand_text);
    }

    if ($kind eq 'bit_vector_literal') {
        my $language = defined($target_language) ? lc($target_language) : '';
        _confess_unsupported_target_language($target_language, $port_name, $kind)
            unless _is_verilog_family($target_language) || $language eq 'vhdl';
        my $bits = $expr->{bits} // '';
        my $width = $expr->{width};
        confess "StructuralRTLIR bit-vector literals must preserve non-empty binary payload.\n"
            unless defined($width) && $width =~ /^\d+$/ && $width > 0 && $bits =~ /\A[01]+\z/;
        if ($language eq 'vhdl') {
            return sprintf("'%s'", $bits) if $width == 1;
            return sprintf('"%s"', $bits);
        }
        return sprintf("%d'b%s", $width, $bits);
    }

    my $binding_label = defined($port_name) && length($port_name)
        ? " for '$port_name'"
        : '';

    confess "StructuralRTLIR port binding$binding_label uses unsupported connection_expr kind '$kind'.\n";
}

sub binding_expr_text ($binding, $target_language = 'systemverilog') {
    return '' unless ref($binding) eq 'HASH';

    my $expr = binding_expr($binding);
    return render_expr($expr, $binding->{port_name}, $target_language) if ref($expr) eq 'HASH';
    return '';
}

sub _coerce_source_expr ($source) {
    if (ref($source) eq 'HASH') {
        return _clone($source);
    }

    return signal_ref_expr($source)
        if defined($source) && !ref($source) && length($source);

    confess "StructuralRTLIR connection expressions require a source signal name or nested expression";
}

sub _is_verilog_family ($target_language) {
    my $language = defined($target_language) ? lc($target_language) : '';
    return $language eq 'systemverilog' || $language eq 'verilog';
}

sub _normalize_target_language_alias ($target_language) {
    my $language = defined($target_language) ? lc($target_language) : 'systemverilog';
    return 'systemverilog' if $language eq 'sv';
    return 'verilog' if $language eq 'v';
    return $language;
}

sub _confess_unsupported_target_language ($target_language, $port_name, $kind) {
    my $binding_label = defined($port_name) && length($port_name)
        ? " for '$port_name'"
        : '';
    my $language = defined($target_language) && length($target_language)
        ? $target_language
        : 'unknown';

    confess "StructuralRTLIR port binding$binding_label uses connection_expr kind '$kind' with unsupported target_language '$language'.\n";
}

sub _push_unique_signal_names ($signal_names, @names) {
    my %seen = map { $_ => 1 } @$signal_names;
    for my $name (@names) {
        next unless defined($name) && length($name);
        next if $seen{$name}++;
        push @$signal_names, $name;
    }
}

sub _clone ($value) {
    return undef unless defined $value;

    if (ref($value) eq 'HASH') {
        return {
            map { $_ => _clone($value->{$_}) } sort keys %$value
        };
    }

    if (ref($value) eq 'ARRAY') {
        return [ map { _clone($_) } @$value ];
    }

    return $value;
}

1;

__END__

=head1 METHODS

=head2 open_expr

Builds the backend-neutral C<open> connection expression.

=head2 signal_ref_expr

Builds a C<signal_ref> connection expression for one named signal.

=head2 member_access_expr

Builds a bounded member-access connection expression over one source
expression.

=head2 index_access_expr

Builds a bounded index-access connection expression over one source
expression.

=head2 bit_select_expr

Builds a bounded bit-select connection expression over one source expression.

=head2 slice_expr

Builds a bounded slice connection expression over one source expression.

=head2 concat_expr

Builds a bounded concatenation connection expression over one or more operand
expressions.

=head2 repeat_expr

Builds a bounded fixed-count replication connection expression over one nested
operand expression.

=head2 bit_vector_literal_expr

Builds a bounded bit-vector literal connection expression from a binary string.

=head2 signal_ref_binding

Builds a structural binding entry whose connection expression is a simple
C<signal_ref>.

=head2 update_binding_signal_ref

Mutates one binding entry so its effective connection expression becomes a
simple C<signal_ref>.

=head2 ensure_signal_ref_binding

Returns an existing binding with the requested port and flat signal when it is
already present, or appends one if it is missing.

=head2 set_signal_ref_binding

Updates an existing binding for one port to a new flat signal, or appends a new
binding if none exists.

=head2 normalized_binding

Returns the normalized structural binding shape with C<signal_name> and
C<connection_expr> kept in sync for the currently supported bounded cases.

=head2 binding_expr

Returns the effective typed connection expression carried by one binding entry.

=head2 expr_signal_name

Returns the one flat leaf signal name for an expression when the expression is
still a simple leaf carrier.

=head2 expr_signal_names

Returns the flattened dependency signal list for a connection expression.

=head2 binding_signal_name

Returns the one flat leaf signal name for a binding when its typed expression
still resolves to a single carrier.

=head2 binding_signal_names

Returns the flattened dependency signal list for a binding.

=head2 binding_signal_summary

Projects one binding into the normalized summary structure used by planning and
reporting surfaces.

=head2 binding_signal_summaries_by_port

Builds a normalized per-port summary index from a binding list.

=head2 binding_signal_summary_metadata

Projects one normalized binding summary into the cloned metadata shape used by
export surfaces.

=head2 binding_signal_summary_leaf_signal

Returns the true flat carrier name from a normalized binding summary when the
summary still represents a leaf signal.

=head2 binding_signal_summary_text

Renders a normalized binding summary into concise backend-facing text.

=head2 render_expr

Renders one typed connection expression into the requested backend syntax.

=head2 binding_expr_text

Renders the effective typed connection expression carried by a binding entry.

=head2 _coerce_source_expr

Normalizes a nested source expression or flat signal name into the internal
expression form.

=head2 _is_verilog_family

Returns whether a target-language token belongs to the current Verilog family.

=head2 _normalize_target_language_alias

Normalizes short target-language aliases such as C<sv> and C<v>.

=head2 _confess_unsupported_target_language

Raises the standardized backend-boundary diagnostic for an unsupported
expression kind and target language.

=head2 _push_unique_signal_names

Appends signal names to a dependency list while preserving uniqueness.

=head2 _clone

Recursively clones nested hashes and arrays used by expression and binding
payloads.

=cut

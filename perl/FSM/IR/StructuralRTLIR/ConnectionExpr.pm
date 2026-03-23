package FSM::IR::StructuralRTLIR::ConnectionExpr;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Exporter qw(import);
use feature qw(signatures);
no warnings 'experimental::signatures';

our @EXPORT_OK = qw(
    signal_ref_expr
    bit_select_expr
    slice_expr
    concat_expr
    bit_vector_literal_expr
    signal_ref_binding
    update_binding_signal_ref
    ensure_signal_ref_binding
    set_signal_ref_binding
    normalized_binding
    binding_expr
    expr_signal_name
    expr_signal_names
    binding_signal_name
    binding_signal_names
    render_expr
    binding_expr_text
);

sub signal_ref_expr ($signal_name) {
    return undef unless defined($signal_name) && length($signal_name);
    return {
        kind => 'signal_ref',
        signal_name => $signal_name,
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

    return {
        port_name => $port_name,
        signal_name => $signal_name,
        connection_expr => $connection_expr,
    };
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

    if ($kind eq 'bit_vector_literal') {
        return [];
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

    confess "StructuralRTLIR connection_expr kind '$kind' has no recursive signal-name recovery rule.\n";
}

sub binding_signal_names ($binding) {
    return [] unless ref($binding) eq 'HASH';
    return expr_signal_names(binding_expr($binding));
}

sub binding_signal_name ($binding) {
    return expr_signal_name(binding_expr($binding));
}

sub render_expr ($expr, $port_name = undef, $target_language = 'systemverilog') {
    return '' unless ref($expr) eq 'HASH';

    my $kind = $expr->{kind} || '';
    return $expr->{signal_name}
        if $kind eq 'signal_ref' && defined($expr->{signal_name}) && length($expr->{signal_name});

    if ($kind eq 'bit_select') {
        _confess_unsupported_target_language($target_language, $port_name, $kind)
            unless _is_verilog_family($target_language);
        my $source_text = render_expr($expr->{source_expr}, $port_name, $target_language);
        return sprintf('%s[%d]', $source_text, $expr->{index});
    }

    if ($kind eq 'slice') {
        _confess_unsupported_target_language($target_language, $port_name, $kind)
            unless _is_verilog_family($target_language);
        my $source_text = render_expr($expr->{source_expr}, $port_name, $target_language);
        return sprintf('%s[%d:%d]', $source_text, $expr->{msb}, $expr->{lsb});
    }

    if ($kind eq 'concat') {
        _confess_unsupported_target_language($target_language, $port_name, $kind)
            unless _is_verilog_family($target_language);
        my @operand_text = map {
            render_expr($_, $port_name, $target_language)
        } @{ $expr->{operands} || [] };
        confess "StructuralRTLIR concat expressions must preserve at least one operand.\n"
            unless @operand_text;
        return '{' . join(', ', @operand_text) . '}';
    }

    if ($kind eq 'bit_vector_literal') {
        _confess_unsupported_target_language($target_language, $port_name, $kind)
            unless _is_verilog_family($target_language);
        my $bits = $expr->{bits} // '';
        my $width = $expr->{width};
        confess "StructuralRTLIR bit-vector literals must preserve non-empty binary payload.\n"
            unless defined($width) && $width =~ /^\d+$/ && $width > 0 && $bits =~ /\A[01]+\z/;
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

=head1 NAME

FSM::IR::StructuralRTLIR::ConnectionExpr - Backend-neutral structural binding expression helpers

=head1 DESCRIPTION

This helper owns the first bounded typed actual-connection node family used by
the extracted Structural RTL IR layer. The current shipped shape is
intentionally small: backend-neutral `signal_ref` plus portable indexed/sliced
signal forms, along with helpers for signal-name recovery and current
Verilog-family text rendering while the emitter still supports only those
bounded structural binding forms.

=cut

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
    signal_ref_binding
    update_binding_signal_ref
    binding_expr
    expr_signal_name
    binding_signal_name
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

sub binding_signal_name ($binding) {
    return expr_signal_name(binding_expr($binding));
}

sub render_expr ($expr, $port_name = undef) {
    return '' unless ref($expr) eq 'HASH';

    my $kind = $expr->{kind} || '';
    return $expr->{signal_name}
        if $kind eq 'signal_ref' && defined($expr->{signal_name}) && length($expr->{signal_name});

    my $binding_label = defined($port_name) && length($port_name)
        ? " for '$port_name'"
        : '';

    confess "StructuralRTLIR port binding$binding_label uses unsupported connection_expr kind '$kind'.\n";
}

sub binding_expr_text ($binding) {
    return '' unless ref($binding) eq 'HASH';

    my $expr = binding_expr($binding);
    return render_expr($expr, $binding->{port_name}) if ref($expr) eq 'HASH';
    return '';
}

1;

__END__

=head1 NAME

FSM::IR::StructuralRTLIR::ConnectionExpr - Backend-neutral structural binding expression helpers

=head1 DESCRIPTION

This helper owns the first bounded typed actual-connection node family used by
the extracted Structural RTL IR layer. The current shipped shape is
intentionally small: backend-neutral `signal_ref` expressions plus helpers for
signal-name recovery and text rendering while the emitter still supports only
that portable structural binding form.

=cut

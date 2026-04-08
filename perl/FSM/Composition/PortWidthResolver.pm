package FSM::Composition::PortWidthResolver;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';

sub _is_deferred_imported_type_alias ($class, $type_spec) {
    return ref($type_spec) eq 'HASH'
        && ($type_spec->{kind} || '') eq 'deferred_imported_alias'
        && defined($type_spec->{imported_type_ref})
        && !ref($type_spec->{imported_type_ref});
}

sub is_contract_type_reference ($class, $value) {
    return defined($value)
        && !ref($value)
        && $value =~ /\A(?:[A-Za-z_]\w*)(?:\.[A-Za-z_]\w*)?\z/;
}

sub resolve_width_token ($class, %args) {
    my $top_name = $args{top_name} // 'top';
    my $token = $args{token} // '?ports';
    my $width_token = $args{width_token};
    my $top_symbols = $args{top_symbols};
    my $docs_hint = $args{docs_hint} // q{};
    my $allow_unresolved_imported_type_refs = $args{allow_unresolved_imported_type_refs} // 0;

    return 1 unless defined $width_token;
    return 0 + $width_token if $width_token =~ /\A\d+\z/ && $width_token > 0;

    if ($width_token =~ /\A\d+\z/) {
        confess "Composition top '$top_name' contains '?ports' token '$token', ".
            "but composition port sizing is blocked because it declares non-positive width '$width_token'.".
            $docs_hint;
    }

    if ($top_symbols && $class->is_contract_type_reference($width_token)) {
        my $type_spec = $top_symbols->resolve_type($width_token);
        return 0 + $type_spec->{width}
            if $type_spec && ref($type_spec) eq 'HASH' && defined $type_spec->{width} && $type_spec->{width} > 0;
        return undef
            if $allow_unresolved_imported_type_refs && $class->_is_deferred_imported_type_alias($type_spec);
    }

    if ($allow_unresolved_imported_type_refs
        && $class->is_contract_type_reference($width_token)
        && $width_token =~ /\./) {
        return undef;
    }

    confess "Composition top '$top_name' contains '?ports' token '$token', ".
        "but composition port sizing is blocked because width token '$width_token' is neither a positive integer nor a resolved scalar type alias.".
        $docs_hint;
}

sub resolve_declared_port_widths ($class, %args) {
    my $top = $args{top}
        or confess "PortWidthResolver requires a composition top";
    my $docs_hint = $args{docs_hint} // q{};
    my $top_name = $top->name // 'top';
    my $top_symbols = $top->top_symbols
        or confess "PortWidthResolver requires top symbols";

    for my $ports_block (@{ $top->ports_blocks || [] }) {
        for my $port (@{ $ports_block->ports || [] }) {
            next unless ref($port) && $port->can('width_token') && $port->can('set_width');
            next if defined $port->width;
            next unless defined $port->width_token;

            my $resolved_width = $class->resolve_width_token(
                top_name => $top_name,
                token => ($port->raw_token // '?ports'),
                width_token => $port->width_token,
                top_symbols => $top_symbols,
                docs_hint => $docs_hint,
                allow_unresolved_imported_type_refs => 0,
            );
            $port->set_width($resolved_width);
        }
    }

    return 1;
}

1;

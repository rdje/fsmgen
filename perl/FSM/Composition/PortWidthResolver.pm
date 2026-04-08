package FSM::Composition::PortWidthResolver;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Package::DeclarativeTypeSupport;

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

sub resolve_port_contract ($class, %args) {
    my $top_name = $args{top_name} // 'top';
    my $token = $args{token} // '?ports';
    my $width_token = $args{width_token};
    my $top_symbols = $args{top_symbols};
    my $docs_hint = $args{docs_hint} // q{};
    my $allow_unresolved_imported_type_refs = $args{allow_unresolved_imported_type_refs} // 0;

    return {
        width => 1,
        signed => 0,
        state_model => undef,
        declared_type_name => undef,
        declared_type_spec => undef,
    } unless defined $width_token;
    return {
        width => 0 + $width_token,
        signed => 0,
        state_model => undef,
        declared_type_name => undef,
        declared_type_spec => undef,
    } if $width_token =~ /\A\d+\z/ && $width_token > 0;

    if ($width_token =~ /\A\d+\z/) {
        confess "Composition top '$top_name' contains '?ports' token '$token', ".
            "but composition port sizing is blocked because it declares non-positive width '$width_token'.".
            $docs_hint;
    }

    if ($top_symbols && $class->is_contract_type_reference($width_token)) {
        my $type_spec = $top_symbols->resolve_type($width_token);
        return {
            width => 0 + $type_spec->{width},
            signed => ($type_spec->{signed} // 0) ? 1 : 0,
            state_model => $type_spec->{state_model},
            declared_type_name => $width_token,
            declared_type_spec => $type_spec,
        } if $type_spec && ref($type_spec) eq 'HASH' && defined $type_spec->{width} && $type_spec->{width} > 0;
        return {
            width => undef,
            signed => ($type_spec->{signed} // 0) ? 1 : 0,
            state_model => $type_spec->{state_model},
            declared_type_name => $width_token,
            declared_type_spec => $type_spec,
        } if $allow_unresolved_imported_type_refs && $class->_is_deferred_imported_type_alias($type_spec);
        return {
            width => undef,
            signed => ($type_spec->{signed} // 0) ? 1 : 0,
            state_model => $type_spec->{state_model},
            declared_type_name => $width_token,
            declared_type_spec => $type_spec,
        } if $allow_unresolved_imported_type_refs
            && FSM::Package::DeclarativeTypeSupport->has_deferred_imported_aliases($type_spec);
    }

    if ($top_symbols && $class->is_contract_type_reference($width_token)) {
        my $resolved_scalar_width = $top_symbols->resolve_positive_integer_scalar($width_token);
        return {
            width => $resolved_scalar_width,
            signed => 0,
            state_model => undef,
            declared_type_name => undef,
            declared_type_spec => undef,
        } if defined $resolved_scalar_width && $resolved_scalar_width > 0;
    }

    if ($allow_unresolved_imported_type_refs
        && $class->is_contract_type_reference($width_token)
        && $width_token =~ /\./) {
        return {
            width => undef,
            signed => 0,
            state_model => undef,
            declared_type_name => undef,
            declared_type_spec => undef,
        };
    }

    confess "Composition top '$top_name' contains '?ports' token '$token', ".
        "but composition port sizing is blocked because width token '$width_token' is neither a positive integer, a resolved type alias, nor a positive integer scalar symbol.".
        $docs_hint;
}

sub resolve_width_token ($class, %args) {
    my $resolved_contract = $class->resolve_port_contract(%args);
    return $resolved_contract->{width};
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

            my $resolved_contract = $class->resolve_port_contract(
                top_name => $top_name,
                token => ($port->raw_token // '?ports'),
                width_token => $port->width_token,
                top_symbols => $top_symbols,
                docs_hint => $docs_hint,
                allow_unresolved_imported_type_refs => 0,
            );
            $port->set_width($resolved_contract->{width});
            $port->set_signed($resolved_contract->{signed})
                if $port->can('set_signed');
            $port->set_state_model($resolved_contract->{state_model})
                if $port->can('set_state_model');
            $port->set_declared_type_name($resolved_contract->{declared_type_name})
                if $port->can('set_declared_type_name');
            $port->set_declared_type_spec($resolved_contract->{declared_type_spec})
                if $port->can('set_declared_type_spec');
        }
    }

    return 1;
}

1;

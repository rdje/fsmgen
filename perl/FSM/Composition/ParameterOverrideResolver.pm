package FSM::Composition::ParameterOverrideResolver;

=head1 NAME

FSM::Composition::ParameterOverrideResolver - Semantic composition parameter override resolution

=head1 DESCRIPTION

Resolves deferred composition parameter/generic override values after top
symbols and package imports are available, but before composition planning and
HDL emission.

=cut

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::ParameterValueSupport;

sub resolve_deferred_overrides ($class, %args) {
    my $top = $args{top}
        or confess "ParameterOverrideResolver requires a composition top";
    my $top_symbols = $args{top_symbols} || $top->top_symbols
        or confess "ParameterOverrideResolver requires top symbols";
    my $docs_hint = $args{docs_hint} // '';

    for my $instance (@{$top->instances || []}) {
        next unless @{$instance->parameter_overrides || []};

        my @resolved_overrides = map {
            $class->_resolve_override(
                top_name => $top->name,
                instance => $instance,
                override => $_,
                top_symbols => $top_symbols,
                docs_hint => $docs_hint,
            )
        } @{$instance->parameter_overrides || []};

        $instance->set_parameter_overrides(\@resolved_overrides);
    }

    return 1;
}

sub _resolve_override ($class, %args) {
    my $top_name = $args{top_name} // 'top';
    my $instance = $args{instance}
        or confess "ParameterOverrideResolver requires an instance";
    my $override = $args{override}
        or confess "ParameterOverrideResolver requires an override";
    my $top_symbols = $args{top_symbols}
        or confess "ParameterOverrideResolver requires top symbols";
    my $docs_hint = $args{docs_hint} // '';

    return _clone($override)
        unless ($override->{value_kind} // '') eq 'deferred_symbol';

    my $instance_name = $instance->name // $instance->module_name // $instance->source_name // 'unknown';
    my $child_kind_label = '?' . ($instance->kind // 'child');
    my $name = $override->{name} // 'unknown';
    my $value_ast = exists($override->{raw_value_ast})
        ? $override->{raw_value_ast}
        : $override->{raw_value};

    my $value_info = FSM::ParameterValueSupport->canonical_value(
        value_ast => $value_ast,
        context => "Composition top '$top_name' contains '$child_kind_label' child '$instance_name' parameter override '$name'",
        docs_hint => $docs_hint,
        resolve_symbol_payload => sub ($symbol_name) {
            return $top_symbols->resolve_payload($symbol_name);
        },
    );

    my $resolved = _clone($override);
    $resolved->{value_text} = $value_info->{value_text};
    $resolved->{value_kind} = $value_info->{value_kind};
    $resolved->{value_payload} = $value_info->{value_payload};
    $resolved->{origin_kind} = $override->{origin_kind} // 'child_parameter_override';
    $resolved->{value_width} = $value_info->{value_width} if defined $value_info->{value_width};
    $resolved->{value_type_spec} = $value_info->{value_type_spec} if ref($value_info->{value_type_spec}) eq 'HASH';

    delete $resolved->{deferred_reason};
    delete $resolved->{deferred_value_symbol};
    return $resolved;
}

sub _clone ($value) {
    return undef unless defined $value;
    if (ref($value) eq 'HASH') {
        return { map { $_ => _clone($value->{$_}) } keys %$value };
    }
    if (ref($value) eq 'ARRAY') {
        return [ map { _clone($_) } @$value ];
    }
    return $value;
}

1;

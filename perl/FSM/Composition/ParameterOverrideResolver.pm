package FSM::Composition::ParameterOverrideResolver;

=head1 NAME

FSM::Composition::ParameterOverrideResolver - Semantic composition parameter override resolution

=head1 DESCRIPTION

Resolves deferred composition parameter/generic override values after top
symbols, package imports and declared top defaults are available, but before
composition planning and HDL emission.

Real top parameter roots and bounded aggregate paths share declaration identity
selection with L<FSM::ParameterDeclarationSupport>. Selected roots take
precedence over static fallback; invalid paths refuse. Canonical values remain
validation caches. When actual top references occur, detached C<binding_expression>
records preserve scope/root/suffix, aliases, operators and aggregate structure.
Static/literal-only overrides keep their ordinary record shape.

Bound retries use retained authored C<raw_value_ast> or C<raw_value>, refresh
canonical values/bindings against the actual top environment, and replace
rather than retain obsolete derived width/type metadata. Missing authored
source or malformed resolved parameter records refuse without converting a
prior cache into a new literal or mutating the caller graph. Unrelated metadata
and original source remain detached through the existing instance setters.

This does not enable parameter-bearing HDL plans or finish child-declaration,
validated IR/schema, symbolic interface-width or target-emission integration.

=cut

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::ParameterValueSupport;
use FSM::ParameterDeclarationSupport;
use FSM::Composition::ParameterBindingSupport;

sub resolve_deferred_overrides ($class, %args) {
    my $top = $args{top}
        or confess "ParameterOverrideResolver requires a composition top";
    my $top_symbols = $args{top_symbols} || $top->top_symbols
        or confess "ParameterOverrideResolver requires top symbols";
    my $docs_hint = $args{docs_hint} // '';
    my $top_parameter_graph;
    if ($top->can('parameter_declarations') && @{$top->parameter_declarations}) {
        $top_parameter_graph = $top->parameter_default_graph;
        confess "Composition top '" . $top->name . "' requires resolved top parameter defaults before instance bindings\n"
            unless ref($top_parameter_graph) eq 'HASH' && ref($top_parameter_graph->{parameters}) eq 'HASH';
    }

    for my $instance (@{$top->instances || []}) {
        next unless @{$instance->parameter_overrides || []};

        my @resolved_overrides = map {
            $class->_resolve_override(
                top_name => $top->name,
                instance => $instance,
                override => $_,
                top_symbols => $top_symbols,
                top_parameter_graph => $top_parameter_graph,
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
    my $top_parameter_graph = $args{top_parameter_graph};
    my $has_binding = exists $override->{binding_expression};

    return _clone($override)
        unless ($override->{value_kind} // '') eq 'deferred_symbol' || $has_binding;
    confess "Composition bound override requires its resolved top parameter environment\n"
        if $has_binding && !defined($top_parameter_graph);
    confess "Composition override requires a resolved top parameter graph\n"
        if defined($top_parameter_graph)
            && !(ref($top_parameter_graph) eq 'HASH' && ref($top_parameter_graph->{parameters}) eq 'HASH');

    my $instance_name = $instance->name // $instance->module_name // $instance->source_name // 'unknown';
    my $child_kind_label = '?' . ($instance->kind // 'child');
    my $name = $override->{name} // 'unknown';
    my $value_ast = exists($override->{raw_value_ast})
        ? $override->{raw_value_ast}
        : $override->{raw_value};
    confess "Composition bound override '$name' requires retained authored source expression\n"
        if $has_binding && !defined($value_ast);

    my $context = "Composition top '$top_name' contains '$child_kind_label' child '$instance_name' parameter override '$name'";
    my @references;
    my $value_info = FSM::ParameterValueSupport->canonical_value(
        value_ast => $value_ast,
        context => $context,
        docs_hint => $docs_hint,
        capture_expression => defined($top_parameter_graph) ? 1 : 0,
        resolve_symbol_payload => sub ($symbol_name) {
            if ($top_parameter_graph) {
                my $parameters = $top_parameter_graph->{parameters};
                if (my $reference = FSM::ParameterDeclarationSupport->declared_reference($parameters, $symbol_name)) {
                    my $declaration = $parameters->{$reference->{parameter}};
                    confess "$context requires a resolved value record for top parameter '$reference->{parameter}'.$docs_hint\n"
                        unless ref($declaration) eq 'HASH';
                    my $payload = $declaration->{value_payload};
                    $payload = FSM::ParameterValueSupport->resolve_payload_path($payload, $reference->{suffix})
                        if length $reference->{suffix};
                    confess "$context top parameter path '$symbol_name' is blocked because its declared root has no resolved value at that path.$docs_hint\n"
                        unless defined $payload;
                    push @references, $reference;
                    return $payload;
                }
            }
            return $top_symbols->resolve_payload($symbol_name);
        },
    );
    my $expression = delete $value_info->{value_expression};

    my $resolved = _clone($override);
    delete @{$resolved}{qw(binding_expression value_width value_type_spec)};
    $resolved->{value_text} = $value_info->{value_text};
    $resolved->{value_kind} = $value_info->{value_kind};
    $resolved->{value_payload} = $value_info->{value_payload};
    $resolved->{origin_kind} = $override->{origin_kind} // 'child_parameter_override';
    $resolved->{value_width} = $value_info->{value_width} if defined $value_info->{value_width};
    $resolved->{value_type_spec} = $value_info->{value_type_spec} if ref($value_info->{value_type_spec}) eq 'HASH';
    if (@references) {
        $resolved->{binding_expression} = FSM::Composition::ParameterBindingSupport->bind_expression(
            expression => $expression, references => \@references, parameters => $top_parameter_graph->{parameters},
            static_symbols => $top_symbols, scope => {kind => 'composition_top', owner => $top_name},
        );
    }

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

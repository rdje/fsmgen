package FSM::IR::StructuralRTLIRBuilder;

=head1 NAME

FSM::IR::StructuralRTLIRBuilder - Builder and coercion helpers for forward StructuralRTLIR

=head1 DESCRIPTION

Builds and coerces the extracted forward C<StructuralRTLIR> layer. The current
shipped scope covers composition-top structural construction from
C<FSM::Composition::Plan>, bounded direct-root structural construction from
generated module analysis, and object/hash coercion for downstream pipeline and
backend consumers.

=cut

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Scalar::Util qw(blessed);
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::IR::StructuralRTLIR;
use FSM::IR::StructuralRTLIR::ConnectionExpr qw(normalized_binding);

sub build_from_generated_module_info ($class, %args) {
    my $module_info = $args{module_info}
        or confess "StructuralRTLIRBuilder requires a module_info";
    my $target_language = $args{target_language} // 'systemverilog';
    my $fsm_module = $args{fsm_module};
    my $hdl_generator = $args{hdl_generator};

    my @ports;
    my %seen_ports;
    for my $bucket (
        [ inputs => 'input' ],
        [ outputs => 'output' ],
    ) {
        my ($analysis_key, $direction) = @$bucket;
        for my $entry (@{$module_info->{signal_analysis}{$analysis_key} || []}) {
            my $signal_name = $entry->{name};
            my $signal = ref($module_info->{signals}) eq 'HASH'
                ? $module_info->{signals}{$signal_name}
                : undef;
            my $type = (ref($signal) && $signal->can('type')) ? $signal->type : undef;
            my $signed = (ref($signal) && $signal->can('signed')) ? $signal->signed : 0;
            my $state_model = (ref($signal) && $signal->can('state_model')) ? $signal->state_model : undef;
            my $declared_type_name = (ref($signal) && $signal->can('declared_type_name'))
                ? $signal->declared_type_name
                : undef;
            my $declared_type_spec = (ref($signal) && $signal->can('declared_type_spec'))
                ? $signal->declared_type_spec
                : undef;

            my $port_entry = {
                name => $signal_name,
                direction => $direction,
                width => ($entry->{width} || 1),
                signed => $signed ? 1 : 0,
                type => $type,
            };
            $port_entry->{state_model} = $state_model if defined $state_model;
            $port_entry->{declared_type_name} = $declared_type_name if defined $declared_type_name;
            $port_entry->{declared_type_spec} = $declared_type_spec if defined $declared_type_spec;
            push @ports, $port_entry;
            $seen_ports{$signal_name} = 1;
        }
    }

    my $system_contract = $module_info->{system_contract} || {};
    if (($module_info->{requires_implicit_system_ports} || $module_info->{explicit_system_contract})
        && defined($system_contract->{clock}) && length($system_contract->{clock})
        && !$seen_ports{$system_contract->{clock}}) {
        push @ports, {
            name => $system_contract->{clock},
            direction => 'input',
            width => 1,
            signed => 0,
            type => 'clock',
        };
        $seen_ports{$system_contract->{clock}} = 1;
    }

    if (($module_info->{requires_implicit_system_ports} || $module_info->{explicit_system_contract})
        && defined($system_contract->{reset}) && length($system_contract->{reset})
        && !$seen_ports{$system_contract->{reset}}) {
        push @ports, {
            name => $system_contract->{reset},
            direction => 'input',
            width => 1,
            signed => 0,
            type => 'reset',
        };
        $seen_ports{$system_contract->{reset}} = 1;
    }

    return FSM::IR::StructuralRTLIR->new(
        module_name => ($module_info->{module_name} // ''),
        source_root_kind => (
            $module_info->{source_root_kind}
                // ($fsm_module && $fsm_module->can('source_root_kind') ? $fsm_module->source_root_kind : 'fsm')
        ),
        target_language => $target_language,
        ports => \@ports,
        nets => _direct_structural_nets(
            fsm_module => $fsm_module,
            hdl_generator => $hdl_generator,
        ),
        instances => [],
        auxiliary_assignments => [],
    );
}

sub build_from_composition_plan ($class, $composition_plan, $target_language = 'systemverilog') {
    confess "StructuralRTLIRBuilder requires a composition plan"
        unless $composition_plan;

    return FSM::IR::StructuralRTLIR->new(
        module_name => ($composition_plan->top_name // ''),
        source_root_kind => 'top',
        target_language => ($target_language // 'systemverilog'),
        ports => [
            map {
                do {
                    my $port_entry = {
                    name => $_->name,
                    direction => $_->direction,
                    width => $_->width,
                    signed => ($_->can('signed') ? $_->signed : 0),
                    type => $_->type,
                    binding_mode => $_->binding_mode,
                    origin_kind => $_->origin_kind,
                    };
                    my $state_model = $_->can('state_model') ? $_->state_model : undef;
                    my $declared_type_name = $_->can('declared_type_name') ? $_->declared_type_name : undef;
                    my $declared_type_spec = $_->can('declared_type_spec') ? $_->declared_type_spec : undef;
                    $port_entry->{state_model} = $state_model if defined $state_model;
                    $port_entry->{declared_type_name} = $declared_type_name if defined $declared_type_name;
                    $port_entry->{declared_type_spec} = $declared_type_spec if defined $declared_type_spec;
                    $port_entry;
                }
            } @{$composition_plan->ports || []}
        ],
        nets => [
            map {
                do {
                    my $net_entry = {
                    name => $_->name,
                    width => $_->width,
                    source => $_->source,
                    targets => [@{$_->targets || []}],
                    };
                    my $declaration_keyword = $_->can('declaration_keyword') ? $_->declaration_keyword : undef;
                    my $signed = $_->can('signed') ? $_->signed : 0;
                    my $state_model = $_->can('state_model') ? $_->state_model : undef;
                    my $declared_type_name = $_->can('declared_type_name') ? $_->declared_type_name : undef;
                    my $declared_type_spec = $_->can('declared_type_spec') ? $_->declared_type_spec : undef;
                    $net_entry->{declaration_keyword} = $declaration_keyword if defined $declaration_keyword;
                    $net_entry->{signed} = $signed if $signed;
                    $net_entry->{state_model} = $state_model if defined $state_model;
                    $net_entry->{declared_type_name} = $declared_type_name if defined $declared_type_name;
                    $net_entry->{declared_type_spec} = $declared_type_spec if defined $declared_type_spec;
                    $net_entry;
                }
            } @{$composition_plan->nets || []}
        ],
        instances => [
            map {
                +{
                    kind => $_->kind,
                    instance_name => $_->instance_name,
                    module_name => $_->module_name,
                    source_name => $_->source_name,
                    interface_ports => [
                        map {
                            do {
                                my $interface_entry = {
                                name => $_->name,
                                direction => $_->direction,
                                width => $_->width,
                                signed => ($_->can('signed') ? $_->signed : 0),
                                type => $_->type,
                                };
                                my $state_model = $_->can('state_model') ? $_->state_model : undef;
                                my $declared_type_name = $_->can('declared_type_name') ? $_->declared_type_name : undef;
                                my $declared_type_spec = $_->can('declared_type_spec') ? $_->declared_type_spec : undef;
                                $interface_entry->{state_model} = $state_model if defined $state_model;
                                $interface_entry->{declared_type_name} = $declared_type_name if defined $declared_type_name;
                                $interface_entry->{declared_type_spec} = $declared_type_spec if defined $declared_type_spec;
                                $interface_entry;
                            }
                        } @{$_->interface_ports || []}
                    ],
                    port_bindings => [
                        map { normalized_binding($_) } @{$_->port_bindings || []}
                    ],
                    parameter_overrides => [
                        map { _clone($_) } @{$_->parameter_overrides || []}
                    ],
                }
            } @{$composition_plan->instances || []}
        ],
        declared_links => [
            map {
                +{
                    source => $_->source,
                    target => $_->target,
                    origin_kind => $_->origin_kind,
                    raw_token => $_->raw_token,
                }
            } @{$composition_plan->links || []}
        ],
        resolved_links => [
            map {
                +{
                    source => $_->source,
                    target => $_->target,
                    origin_kind => $_->origin_kind,
                    raw_token => $_->raw_token,
                }
            } @{$composition_plan->resolved_links || []}
        ],
        auxiliary_assignments => [@{$composition_plan->auxiliary_assignments || []}],
    );
}

sub coerce ($class, $structural_rtl_ir, $default_target_language = 'systemverilog') {
    return $structural_rtl_ir
        if blessed($structural_rtl_ir) && $structural_rtl_ir->can('as_hashref');

    my $structural_rtl_ir_hash = ref($structural_rtl_ir) eq 'HASH'
        ? $structural_rtl_ir
        : {};

    return FSM::IR::StructuralRTLIR->new(
        module_name => ($structural_rtl_ir_hash->{module_name} // ''),
        source_root_kind => ($structural_rtl_ir_hash->{source_root_kind} // 'fsm'),
        target_language => ($structural_rtl_ir_hash->{target_language} // ($default_target_language // 'systemverilog')),
        ports => ($structural_rtl_ir_hash->{ports} || []),
        nets => ($structural_rtl_ir_hash->{nets} || []),
        instances => ($structural_rtl_ir_hash->{instances} || []),
        declared_links => ($structural_rtl_ir_hash->{declared_links} || []),
        resolved_links => ($structural_rtl_ir_hash->{resolved_links} || []),
        auxiliary_assignments => ($structural_rtl_ir_hash->{auxiliary_assignments} || []),
    );
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

sub _direct_structural_nets (%args) {
    my @entries = (
        @{_direct_internal_declaration_nets(%args)},
        @{_direct_top_enable_nets(%args)},
    );

    my %seen;
    my @deduped;
    for my $entry (@entries) {
        next unless ref($entry) eq 'HASH';
        my $name = $entry->{name};
        next unless defined($name) && length($name);
        next if $seen{$name}++;
        push @deduped, $entry;
    }

    return \@deduped;
}

sub _direct_internal_declaration_nets (%args) {
    my $fsm_module = $args{fsm_module};
    my $hdl_generator = $args{hdl_generator};
    return [] unless $fsm_module && ref($hdl_generator);

    my $planning_support = $hdl_generator->{enable_graph_module_planning_support};
    return [] unless ref($planning_support)
        && $planning_support->can('build_module_declaration_plan')
        && $planning_support->can('build_internal_signal_declaration_plan');

    my $module_plan = $planning_support->build_module_declaration_plan($fsm_module);
    return [] unless ref($module_plan) eq 'HASH';

    my $declaration_plan = $planning_support->build_internal_signal_declaration_plan(
        $fsm_module,
        $module_plan->{declared_port_signals},
    );
    return [] unless ref($declaration_plan) eq 'HASH';

    return [
        _direct_net_entries_from_declarations(
            $declaration_plan->{signal_decls},
            $declaration_plan->{signal_signed},
            $declaration_plan->{signal_state_model},
            $declaration_plan->{signal_declared_type_name},
            $declaration_plan->{signal_declared_type_spec},
        ),
        _direct_net_entries_from_declarations(
            $declaration_plan->{aux_decls},
            $declaration_plan->{aux_signed},
            $declaration_plan->{aux_state_model},
            $declaration_plan->{aux_declared_type_name},
            $declaration_plan->{aux_declared_type_spec},
        ),
    ];
}

sub _direct_top_enable_nets (%args) {
    my $hdl_generator = $args{hdl_generator};
    return [] unless ref($hdl_generator);

    my @entries;
    for my $state_name (sort keys %{$hdl_generator->{state_enables} || {}}) {
        push @entries, _direct_one_bit_enable_net("${state_name}_en");
    }

    for my $dt_name (sort keys %{$hdl_generator->{dt_enables} || {}}) {
        my $clean_name = $dt_name;
        $clean_name =~ s/^-//;
        push @entries, _direct_one_bit_enable_net("${clean_name}_en");
    }

    return \@entries;
}

sub _direct_one_bit_enable_net ($name) {
    return {
        name => $name,
        width => 1,
        signed => 0,
        source => undef,
        targets => [],
    };
}

sub _direct_net_entries_from_declarations (
    $decls,
    $signed_map = undef,
    $state_model_map = undef,
    $declared_type_name_map = undef,
    $declared_type_spec_map = undef,
) {
    return () unless ref($decls) eq 'HASH';

    my @entries;
    for my $name (sort keys %$decls) {
        my $entry = {
            name => $name,
            width => ($decls->{$name} || 1),
            source => undef,
            targets => [],
            signed => (($signed_map || {})->{$name} // 0) ? 1 : 0,
        };

        my $state_model = ($state_model_map || {})->{$name};
        my $declared_type_name = ($declared_type_name_map || {})->{$name};
        my $declared_type_spec = ($declared_type_spec_map || {})->{$name};

        $entry->{state_model} = $state_model if defined $state_model;
        $entry->{declared_type_name} = $declared_type_name if defined $declared_type_name;
        $entry->{declared_type_spec} = _clone($declared_type_spec) if defined $declared_type_spec;

        push @entries, $entry;
    }

    return @entries;
}

1;

__END__

=head1 METHODS

=head2 build_from_generated_module_info

Builds a structural RTL IR object from generated direct-root module analysis,
preserving the module boundary ports and system-interface ports currently
materialized in the bounded direct structural slice.

=head2 build_from_composition_plan

Builds a structural RTL IR object from a realized composition plan, preserving
top ports, nets, instances, links, bindings, and auxiliary assignments.

=head2 coerce

Coerces a structural hash payload or existing structural object into a
C<FSM::IR::StructuralRTLIR> instance.

=cut

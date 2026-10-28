package FSM::HDL::FlattenedDT::Backend::SystemVerilog::InternalDeclarationEmitter;

=head1 NAME

FSM::HDL::FlattenedDT::Backend::SystemVerilog::InternalDeclarationEmitter - Render direct generated-module internal declaration blocks

=head1 DESCRIPTION

Owns the bounded SystemVerilog internal declaration family for the older direct
generated module backend. This package renders internal storage declarations
and auxiliary helper registers from the enable-graph declaration plan after
module declaration rendering has established which names already belong to the
module boundary.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Backend::VerilogFamily::TypeDeclarationSupport;

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[InternalDeclarationEmitter.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

sub generate_internal_signal_declarations ($self, $fsm_module) {
    my $ctx = $self->{flattened_dt};
    my $declaration_plan = $ctx->{enable_graph_module_planning_support}->build_internal_signal_declaration_plan(
        $fsm_module,
        $ctx->{declared_port_signals},
    );
    my %signal_decls = %{$declaration_plan->{signal_decls} || {}};
    my %aux_decls = %{$declaration_plan->{aux_decls} || {}};
    my $aux_width_origins = $declaration_plan->{aux_width_origins} || {};
    my %signal_signed = %{$declaration_plan->{signal_signed} || {}};
    my %aux_signed = %{$declaration_plan->{aux_signed} || {}};
    my %signal_state_model = %{$declaration_plan->{signal_state_model} || {}};
    my %aux_state_model = %{$declaration_plan->{aux_state_model} || {}};
    my %signal_declared_type_name = %{$declaration_plan->{signal_declared_type_name} || {}};
    my %aux_declared_type_name = %{$declaration_plan->{aux_declared_type_name} || {}};
    my %signal_declared_type_spec = %{$declaration_plan->{signal_declared_type_spec} || {}};
    my %aux_declared_type_spec = %{$declaration_plan->{aux_declared_type_spec} || {}};
    my %enable_decls = _enable_wire_declarations($ctx, \%signal_decls, \%aux_decls);
    my %width_plans;
    if (my $source_plan = $ctx->{direct_declared_width_source_plan}) {
        for my $name (sort(keys(%signal_decls), keys(%aux_decls))) {
            my $signal_plan = $source_plan->{signals}{$name};
            my $width_plan = $signal_plan ? $signal_plan->{width_plan} : undef;
            next unless $width_plan && $width_plan->{profile} eq 'symbolic';
            $width_plans{$name} = $width_plan;
            $ctx->{direct_declared_width_emitted_signals}{$name} = $width_plan;
        }
    }

    return "" unless (%signal_decls || %aux_decls || %enable_decls);
    $ctx->{verilog_family_typedef_state} //= FSM::Backend::VerilogFamily::TypeDeclarationSupport->typedef_state(
        module_name => $fsm_module->name,
    );

    my @typed_declaration_entries = (
        _typed_declaration_entries(\%signal_decls, \%signal_signed, \%signal_state_model, \%signal_declared_type_name, \%signal_declared_type_spec),
        _typed_declaration_entries(\%aux_decls, \%aux_signed, \%aux_state_model, \%aux_declared_type_name, \%aux_declared_type_spec, $aux_width_origins),
    );
    my ($typedef_lines, $aggregate_typedef_lookup) =
        FSM::Backend::VerilogFamily::TypeDeclarationSupport->collect_declared_aggregate_typedefs(
            \@typed_declaration_entries,
            $ctx->{verilog_family_typedef_state},
        );
    if (my $capture = $ctx->{declared_width_declaration_capture}) {
        $capture->record_typedefs($aggregate_typedef_lookup);
        $capture->record_declaration('signals', $_) for @typed_declaration_entries;
        $capture->record_declaration('signals', {name => $_, width => 1, signed => 0}) for sort keys %enable_decls;
    }

    my $hdl = "  // Internal signal declarations\n";
    if (@$typedef_lines) {
        $hdl .= join("\n", map { length($_) ? "  $_" : "" } @$typedef_lines) . "\n";
    }
    $hdl .= _render_reg_declarations(
        \%signal_decls,
        \%signal_signed,
        \%signal_state_model,
        \%signal_declared_type_name,
        \%signal_declared_type_spec,
        $aggregate_typedef_lookup,
        \%width_plans,
    );

    if (%aux_decls) {
        $hdl .= "  // Internal mux helper registers\n";
        $hdl .= _render_reg_declarations(
            \%aux_decls,
            \%aux_signed,
            \%aux_state_model,
            \%aux_declared_type_name,
            \%aux_declared_type_spec,
            $aggregate_typedef_lookup,
            \%width_plans,
        );
    }
    if (%enable_decls) {
        $hdl .= "  // Generated enable wires\n";
        $hdl .= _render_wire_declarations(\%enable_decls);
    }
    $hdl .= "\n";

    return $hdl;
}

sub _enable_wire_declarations ($ctx, $signal_decls, $aux_decls) {
    my %declared = map { $_ => 1 } (
        keys %{$signal_decls || {}},
        keys %{$aux_decls || {}},
        keys %{$ctx->{declared_port_signals} || {}},
    );
    my %enable_decls;

    for my $state_name (keys %{$ctx->{state_enables} || {}}) {
        _add_enable_wire(\%enable_decls, \%declared, "${state_name}_en");
    }

    for my $dt_name (keys %{$ctx->{dt_enables} || {}}) {
        my $clean_name = $dt_name;
        $clean_name =~ s/^-//;
        _add_enable_wire(\%enable_decls, \%declared, "${clean_name}_en");
    }

    for my $lhs (keys %{$ctx->{assignment_analysis} || {}}) {
        my $lhs_analysis = $ctx->{assignment_analysis}{$lhs} || {};
        for my $rhs (keys %{$lhs_analysis->{rhs_groups} || {}}) {
            my $rhs_group = $lhs_analysis->{rhs_groups}{$rhs} || {};

            for my $dt_enable_info (@{$rhs_group->{dt_specific_enables} || []}) {
                _add_enable_wire(\%enable_decls, \%declared, $dt_enable_info->{enable_name});
            }

            my $lhs_enable = $rhs_group->{lhs_level_enable} || {};
            _add_enable_wire(\%enable_decls, \%declared, $lhs_enable->{name});
        }
    }

    return %enable_decls;
}

sub _add_enable_wire ($enable_decls, $declared, $name) {
    return unless defined($name) && $name =~ /^[A-Za-z_]\w*\z/;
    return if $declared->{$name};
    $enable_decls->{$name} = 1;
}

sub _typed_declaration_entries ($decls, $signed_map, $state_model_map, $declared_type_name_map, $declared_type_spec_map, $width_origins = undef) {
    my @entries;
    for my $signal_name (sort keys %{$decls || {}}) {
        my $entry = {
            name => $signal_name,
            width => $decls->{$signal_name},
            signed => ($signed_map->{$signal_name} // 0) ? 1 : 0,
            state_model => $state_model_map->{$signal_name},
            declared_type_name => $declared_type_name_map->{$signal_name},
            declared_type_spec => $declared_type_spec_map->{$signal_name},
        };
        $entry->{width_origin} = $width_origins->{$signal_name}
            if $width_origins && exists($width_origins->{$signal_name});
        push @entries, $entry;
    }
    return @entries;
}

sub _render_reg_declarations ($decls, $signed_map = undef, $state_model_map = undef, $declared_type_name_map = undef, $declared_type_spec_map = undef, $aggregate_typedef_lookup = undef, $width_plans = undef) {
    my $hdl = "";
    for my $signal_name (sort keys %{$decls || {}}) {
        my $typedef_name = FSM::Backend::VerilogFamily::TypeDeclarationSupport->aggregate_typedef_name_for({
            name => $signal_name,
            declared_type_name => $declared_type_name_map ? $declared_type_name_map->{$signal_name} : undef,
            declared_type_spec => $declared_type_spec_map ? $declared_type_spec_map->{$signal_name} : undef,
        }, $aggregate_typedef_lookup);
        if (defined $typedef_name) {
            $hdl .= "  ${typedef_name} ${signal_name};\n";
            next;
        }

        my $width = $decls->{$signal_name} || 1;
        my $width_str = ($width > 1) ? "[" . ($width - 1) . ":0] " : "";
        $width_str = $width_plans->{$signal_name}{range_text} if $width_plans && $width_plans->{$signal_name};
        my $signed_str = ($signed_map && ($signed_map->{$signal_name} // 0)) ? "signed " : "";
        my $state_model = $state_model_map ? $state_model_map->{$signal_name} : undef;
        my $type_keyword = _state_model_keyword($state_model);
        if (defined $type_keyword) {
            $hdl .= "  ${type_keyword} ${signed_str}${width_str}${signal_name};\n";
            next;
        }
        $hdl .= "  reg ${signed_str}${width_str}${signal_name};\n";
    }
    return $hdl;
}

sub _render_wire_declarations ($decls) {
    my $hdl = "";
    for my $signal_name (sort keys %{$decls || {}}) {
        $hdl .= "  wire ${signal_name};\n";
    }
    return $hdl;
}

sub _state_model_keyword ($state_model) {
    return FSM::Backend::VerilogFamily::TypeDeclarationSupport->state_model_keyword($state_model);
}

1;

__END__

=head1 METHODS

=head2 new

Constructs one internal-declaration emitter bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=head2 generate_internal_signal_declarations

Renders the SystemVerilog internal declaration block from the enable-graph
declaration plan, including both direct internal storage declarations and the
auxiliary helper register family used by the direct generated-module backend.
Captured source-owned storage consumes its proved symbolic range, including
vector rank at a selected width of one. Backend-only helpers keep their existing
numeric shape; no width relationship is inferred from equal numeric widths.
Their captured declaration rows retain optional allocation-time C<width_origin>
metadata supplied by the module planner. It names actual register next/q parents;
pulse-delay helpers and ordinary declarations do not borrow that relationship.

=cut

package FSM::Pipeline::GeneratedModuleInfoBuilder;

=head1 NAME

FSM::Pipeline::GeneratedModuleInfoBuilder - Builder and query owner for generated module_info

=head1 DESCRIPTION

Owns the bounded generated-module C<module_info> surface that was still inline
in C<FSM::Pipeline::HDLGenerator>. This package builds the compatibility
analysis summary from one semantic FSM/DT module plus its intent HIR, enriches
that summary with lowered generated-module analysis, and exposes the small
query surface later used by direct-root and generated-child consumers.

=cut

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::IR::LoweredRTLIR;
use FSM::IR::LoweredRTLIRBuilder;

sub build_from_fsm_module ($class, %args) {
    my $fsm_module = $args{fsm_module}
        or confess "GeneratedModuleInfoBuilder requires a fsm_module";
    my $intent_hir = $args{intent_hir}
        or confess "GeneratedModuleInfoBuilder requires an intent_hir";

    my @all_states = @{$fsm_module->states};
    my %all_signals = %{$fsm_module->signals};

    my @regular_states = grep {
        $_->can('is_regular_state') ? $_->is_regular_state : $_->name !~ /^-/
    } @all_states;
    my @standalone_dts = grep {
        $_->can('is_regular_state') ? !$_->is_regular_state : $_->name =~ /^-/
    } @all_states;

    my $intent_hir_hash = ref($intent_hir) eq 'HASH'
        ? $intent_hir
        : $intent_hir->as_hashref;

    return {
        module_name => $intent_hir_hash->{module_name},
        source_root_kind => $intent_hir_hash->{source_root_kind},
        regular_states => \@regular_states,
        regular_state_count => $intent_hir_hash->{regular_state_count},
        regular_state_names => _clone_structured_value($intent_hir_hash->{regular_state_names}),
        state_count => $intent_hir_hash->{state_count},
        standalone_dts => \@standalone_dts,
        standalone_dt_count => $intent_hir_hash->{standalone_dt_count},
        standalone_dt_names => _clone_structured_value($intent_hir_hash->{standalone_dt_names}),
        signals => \%all_signals,
        signal_count => $intent_hir_hash->{signal_count},
        signal_names => _clone_structured_value($intent_hir_hash->{signal_names}),
        signal_analysis => _clone_structured_value($intent_hir_hash->{signal_analysis}),
        explicit_system_contract => _clone_structured_value($intent_hir_hash->{explicit_system_contract}),
        system_contract => _clone_structured_value($intent_hir_hash->{system_contract}),
        requires_implicit_system_ports => $intent_hir_hash->{requires_implicit_system_ports},
        standalone_dt_enable_families => _clone_structured_value($intent_hir_hash->{standalone_dt_enable_families}),
        standalone_dt_module_enable_family => _clone_structured_value($intent_hir_hash->{standalone_dt_module_enable_family}),
        parameter_count => $intent_hir_hash->{parameter_count},
        parameter_names => _clone_structured_value($intent_hir_hash->{parameter_names}),
        symbol_contract => _clone_structured_value($intent_hir_hash->{symbol_contract}),
        immediate_assertions => _immediate_assertions_from_module($fsm_module),
        intent_hir => _clone_structured_value($intent_hir_hash),
    };
}

# ISF-ASSERT: surface the parsed `+assert` invariants (on the module) into module_info as
# plain emitter-ready records — the CoreAST condition is rendered to SV text here so the
# emitter does not have to carry the blessed expression object.
sub _immediate_assertions_from_module ($fsm_module) {
    my $raw = (ref($fsm_module) && ref($fsm_module->{attributes}) eq 'HASH')
        ? $fsm_module->{attributes}{immediate_assertions} : undef;
    return [] unless ref($raw) eq 'ARRAY';
    my @out;
    for my $a (@$raw) {
        next unless ref($a) eq 'HASH' && defined $a->{name};
        my $cond_sv = eval { $a->{condition}->to_systemverilog() };
        next unless defined($cond_sv) && length($cond_sv);
        push @out, {
            name         => $a->{name},
            condition_sv => $cond_sv,
            (defined $a->{message} ? (message => $a->{message}) : ()),
        };
    }
    return \@out;
}

sub enrich_with_generated_analysis ($class, %args) {
    my $module_info = $args{module_info}
        or confess "GeneratedModuleInfoBuilder requires a module_info";
    my $fsm_module = $args{fsm_module}
        or confess "GeneratedModuleInfoBuilder requires a fsm_module";

    return $module_info unless ref($module_info) eq 'HASH';

    my $lowered_rtl_ir = FSM::IR::LoweredRTLIRBuilder->build_from_generated_module_info(
        module_info => $module_info,
        fsm_module => $fsm_module,
        target_language => ($args{target_language} // 'systemverilog'),
        hdl_generator => $args{hdl_generator},
    );
    my $lowered_rtl_ir_hash = $lowered_rtl_ir->as_hashref;

    $module_info->{output_drive_family_count} = $lowered_rtl_ir_hash->{output_drive_family_count};
    $module_info->{output_drive_families} = _clone_structured_value($lowered_rtl_ir_hash->{output_drive_families});
    $module_info->{selector_conflict_target_count} = $lowered_rtl_ir_hash->{selector_conflict_target_count};
    $module_info->{selector_conflict_targets}
        = _clone_structured_value($lowered_rtl_ir_hash->{selector_conflict_targets});
    $module_info->{standalone_dt_multi_drive_target_count} = $lowered_rtl_ir_hash->{standalone_dt_multi_drive_target_count};
    $module_info->{standalone_dt_multi_drive_targets}
        = _clone_structured_value($lowered_rtl_ir_hash->{standalone_dt_multi_drive_targets});
    $module_info->{lowered_rtl_ir} = $lowered_rtl_ir_hash;
    return $module_info;
}

sub output_drive_families_from_module_info ($class, $module_info) {
    return [] unless ref($module_info) eq 'HASH';

    my $output_drive_families = FSM::IR::LoweredRTLIR->output_drive_families_from_input(
        $module_info->{lowered_rtl_ir}
    );
    if (@$output_drive_families) {
        return $output_drive_families;
    }

    return _clone_structured_value($module_info->{output_drive_families} || []);
}

sub selector_conflict_targets_from_module_info ($class, $module_info) {
    return [] unless ref($module_info) eq 'HASH';

    my $selector_conflict_targets = FSM::IR::LoweredRTLIR->selector_conflict_targets_from_input(
        $module_info->{lowered_rtl_ir}
    );
    if (@$selector_conflict_targets) {
        return $selector_conflict_targets;
    }

    return _clone_structured_value($module_info->{selector_conflict_targets} || []);
}

sub intent_hir_from_module_info ($class, $module_info) {
    return {} unless ref($module_info) eq 'HASH';
    return _clone_structured_value($module_info->{intent_hir} || {});
}

sub lowered_rtl_ir_from_module_info ($class, $module_info) {
    return {} unless ref($module_info) eq 'HASH';
    return _clone_structured_value($module_info->{lowered_rtl_ir} || {});
}

sub structural_rtl_ir_from_module_info ($class, $module_info) {
    return {} unless ref($module_info) eq 'HASH';
    return _clone_structured_value($module_info->{structural_rtl_ir} || {});
}

sub standalone_dt_multi_drive_targets_from_module_info ($class, $module_info) {
    return [] unless ref($module_info) eq 'HASH';

    my $standalone_dt_multi_drive_targets = FSM::IR::LoweredRTLIR->standalone_dt_multi_drive_targets_from_input(
        $module_info->{lowered_rtl_ir}
    );
    if (@$standalone_dt_multi_drive_targets) {
        return $standalone_dt_multi_drive_targets;
    }

    return _clone_structured_value($module_info->{standalone_dt_multi_drive_targets} || []);
}

sub _clone_structured_value ($value) {
    return undef unless defined $value;

    if (ref($value) eq 'HASH') {
        return {
            map { $_ => _clone_structured_value($value->{$_}) } sort keys %$value
        };
    }

    if (ref($value) eq 'ARRAY') {
        return [ map { _clone_structured_value($_) } @$value ];
    }

    return $value;
}

1;

__END__

=head1 METHODS

=head2 build_from_fsm_module

Builds the generated-module C<module_info> compatibility surface from one
semantic FSM/DT module plus its intent HIR.

=head2 enrich_with_generated_analysis

Enriches one generated-module C<module_info> hash with lowered generated
analysis such as output-drive-family and standalone-DT grouped-target data.

=head2 output_drive_families_from_module_info

Returns the normalized output-drive-family view from one generated-module
C<module_info> surface.

=head2 selector_conflict_targets_from_module_info

Returns the normalized generated mux-selector conflict target view from one
generated-module C<module_info> surface.

=head2 intent_hir_from_module_info

Returns a cloned intent-HIR payload from one generated-module C<module_info>
surface.

=head2 lowered_rtl_ir_from_module_info

Returns a cloned lowered-RTL-IR payload from one generated-module C<module_info>
surface.

=head2 structural_rtl_ir_from_module_info

Returns a cloned structural-RTL-IR payload from one generated-module
C<module_info> surface.

=head2 standalone_dt_multi_drive_targets_from_module_info

Returns the normalized standalone-DT grouped multi-drive-target view from one
generated-module C<module_info> surface.

=head2 _clone_structured_value

Clones nested hash/array payloads used by the generated-module C<module_info>
query helpers.

=cut

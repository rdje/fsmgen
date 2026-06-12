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
use Scalar::Util qw(blessed);
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

# ISF-PROPERTY-IMPLICATION: render a check condition to SV. A plain boolean is a CoreAST
# expression (-> to_systemverilog); a temporal property is a tagged combinator tree over boolean
# leaves (-> SVA property operators). Returns undef if any leaf cannot render.
sub _render_check_condition_sv ($cond, $seen = undef) {
    $seen //= {};
    if (ref($cond) eq 'HASH' && $cond->{__property__}) {
        my $op = $cond->{op} // '';
        if ($op eq 'implies_overlap') {
            my $a = _render_check_condition_sv($cond->{antecedent}, $seen);
            my $b = _render_check_condition_sv($cond->{consequent}, $seen);
            return undef unless defined($a) && length($a) && defined($b) && length($b);
            return "($a) |-> ($b)";
        }
        if ($op eq 'after_event') {
            # event trigger: anchor the consequent to the rising edge of the trigger signal.
            my $t = _render_check_condition_sv($cond->{trigger}, $seen);
            my $b = _render_check_condition_sv($cond->{consequent}, $seen);
            return undef unless defined($t) && length($t) && defined($b) && length($b);
            return "\$rose($t) |-> ($b)";
        }
        if ($op eq 'next') {
            my $x = _render_check_condition_sv($cond->{operand}, $seen);
            return undef unless defined($x) && length($x);
            return "##1 ($x)";
        }
        if ($op eq 'within') {
            my $x = _render_check_condition_sv($cond->{operand}, $seen);
            return undef unless defined($x) && length($x);
            # ISF-PROPERTY-WINDOW-RANGE: explicit lower bound (defaults to 1 for `(within X N)`).
            my $lower = $cond->{lower} // 1;
            return "##[$lower:$cond->{bound}] ($x)";
        }
        if ($op eq 'sampled_value') {
            # ISF-PROPERTY-SAMPLED-VALUE: $stable/$changed/$rose/$fell(SIG). Boolean sampled-value
            # function over a leaf — not a `##` sequence, so it stays verilator-simulable.
            my $x = _render_check_condition_sv($cond->{operand}, $seen);
            return undef unless defined($x) && length($x);
            return "$cond->{fn}($x)";
        }
        return undef;
    }

    if (blessed($cond) && $cond->isa('FSM::CoreAST::SignalRef')) {
        my $signal = $cond->signal;
        if (blessed($signal) && _check_signal_ref_should_inline($signal)) {
            my $name = $signal->name;
            return $name if $seen->{$name}++;
            my $driving_ast = $signal->driving_ast;
            my $rendered = _render_check_condition_sv($driving_ast, $seen)
                if blessed($driving_ast) || ref($driving_ast);
            --$seen->{$name};
            return $rendered if defined($rendered) && length($rendered);
        }
    }

    return eval { $cond->to_systemverilog() };
}

sub _check_signal_ref_should_inline ($signal) {
    return 0 unless blessed($signal);
    return 0 unless $signal->can('driving_ast') && defined $signal->driving_ast;
    return 1 if $signal->can('get_attribute') && $signal->get_attribute('is_intermediate');
    return 1 if $signal->can('get_attribute') && (($signal->get_attribute('signal_role') // '') eq 'INTERNAL_INTERMEDIATE');
    return 1 if $signal->can('is_intermediate') && $signal->is_intermediate
        && $signal->can('name') && $signal->name =~ /\Aintermediate_/;
    return 0;
}

# A property that uses a delayed consequent (`next` -> ##1, `within` -> ##[1:N]) is formal-only:
# verilator cannot simulate an implication with a sequence (delay) consequent, so such checks are
# guarded with `ifdef FORMAL` (not `ifndef SYNTHESIS`) so verilator/yosys skip them while formal
# tools check them. Boolean and overlapping-implication checks remain verilator-simulable.
sub _property_is_formal_only ($cond) {
    return 0 unless ref($cond) eq 'HASH' && $cond->{__property__};
    my $op = $cond->{op} // '';
    return 1 if $op eq 'next' || $op eq 'within';
    # `after_event` ($rose trigger) is simulable on its own; it is formal-only only when its
    # consequent is delayed — caught by the recursive consequent check below.
    return 1 if _property_is_formal_only($cond->{antecedent});
    return 1 if _property_is_formal_only($cond->{consequent});
    return 1 if _property_is_formal_only($cond->{operand});
    return 1 if _property_is_formal_only($cond->{trigger});
    return 0;
}

# ISF-ASSERT: surface the parsed `+assert` invariants (on the module) into module_info as
# plain emitter-ready records — the condition is rendered to SV text here so the emitter does
# not have to carry the blessed expression object (or the property tree).
sub _immediate_assertions_from_module ($fsm_module) {
    my $raw = (ref($fsm_module) && ref($fsm_module->{attributes}) eq 'HASH')
        ? $fsm_module->{attributes}{immediate_assertions} : undef;
    return [] unless ref($raw) eq 'ARRAY';
    my @out;
    for my $a (@$raw) {
        next unless ref($a) eq 'HASH' && defined $a->{name};
        my $cond_sv = _render_check_condition_sv($a->{condition});
        next unless defined($cond_sv) && length($cond_sv);
        push @out, {
            name         => $a->{name},
            kind         => ($a->{kind} // 'assert'),
            condition_sv => $cond_sv,
            formal_only  => _property_is_formal_only($a->{condition}),
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

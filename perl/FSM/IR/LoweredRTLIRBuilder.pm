package FSM::IR::LoweredRTLIRBuilder;

=head1 NAME

FSM::IR::LoweredRTLIRBuilder - Builder for bounded forward LoweredRTLIR surfaces

=head1 DESCRIPTION

Owns the bounded forward Lowered RTL IR construction paths that have been
extracted out of the mixed pipeline coordinator. Right now this package builds
the composition-top lowered summary from an already-built composition plan plus
the surrounding structural, semantic, and shared-datapath inputs, and it also
owns the bounded direct-root lowered summary extracted from the direct
generation path.

=cut

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Composition::SharedDatapathCandidateBuilder;
use FSM::IR::LoweredRTLIR;
use FSM::IR::StructuralRTLIRBuilder;

sub build_from_generated_module_info ($class, %args) {
    my $module_info = $args{module_info}
        or confess "LoweredRTLIRBuilder requires a module_info";
    my $target_language = $args{target_language} // 'systemverilog';
    my $fsm_module = $args{fsm_module};

    my $output_drive_families = $class->build_output_drive_family_metadata(
        module_info => $module_info,
        hdl_generator => $args{hdl_generator},
    );
    my $selector_conflict_targets = $class->build_selector_conflict_target_metadata(
        module_info => $module_info,
        hdl_generator => $args{hdl_generator},
    );

    my @standalone_dt_multi_drive_targets = map {
        +{
            signal_name => $_->{signal_name},
            multiplexer_type => $_->{multiplexer_type},
            dt_names => [@{$_->{driver_blocks} || []}],
            rhs_values => [@{$_->{rhs_values} || []}],
            dt_enable_signals => [@{$_->{driver_enable_signals} || []}],
            lhs_enable_signals => [@{$_->{family_enable_signals} || []}],
            multi_drive_assertion => $class->standalone_dt_assertion_metadata(
                $_->{signal_name},
                $_->{driver_enable_signals},
            ),
        }
    } grep {
        ($_->{driver_count} || 0) > 1
    } @$output_drive_families;

    return FSM::IR::LoweredRTLIR->new(
        module_name => ($module_info->{module_name} // ''),
        source_root_kind => (
            $module_info->{source_root_kind}
                // ($fsm_module && $fsm_module->can('source_root_kind') ? $fsm_module->source_root_kind : 'fsm')
        ),
        target_language => $target_language,
        output_drive_families => $output_drive_families,
        selector_conflict_targets => $selector_conflict_targets,
        standalone_dt_multi_drive_targets => (
            $fsm_module && $fsm_module->can('is_dt_root') && $fsm_module->is_dt_root
                ? \@standalone_dt_multi_drive_targets
                : []
        ),
    );
}

sub build_from_composition_plan ($class, %args) {
    my $composition_plan = $args{composition_plan}
        or confess "LoweredRTLIRBuilder requires a composition_plan";
    my $target_language = $args{target_language} // 'systemverilog';

    my $structural_rtl_ir = FSM::IR::StructuralRTLIRBuilder->coerce(
        $args{structural_rtl_ir}
            // FSM::IR::StructuralRTLIRBuilder->build_from_composition_plan(
                $composition_plan,
                $target_language,
            ),
        $target_language,
    );
    my $shared_datapath_candidates = $args{shared_datapath_candidates}
        // FSM::Composition::SharedDatapathCandidateBuilder->candidates_for_plan(
            composition_plan => $composition_plan,
            structural_rtl_ir => $structural_rtl_ir,
            intent_hir => $args{intent_hir},
            target_language => $target_language,
        );
    my $structural_rtl_ir_hash = $structural_rtl_ir->as_hashref;
    my $internal_net_names = [
        map { $_->{name} }
        @{$structural_rtl_ir_hash->{nets} || []}
    ];
    my $instance_names = [
        map { $_->{instance_name} }
        @{$structural_rtl_ir_hash->{instances} || []}
    ];

    return FSM::IR::LoweredRTLIR->new(
        module_name => ($composition_plan->top_name // ''),
        source_root_kind => 'top',
        target_language => $target_language,
        output_drive_families => [],
        selector_conflict_targets => [],
        standalone_dt_multi_drive_targets => [],
        composition_shared_datapath_candidates => $shared_datapath_candidates,
        internal_net_names => $internal_net_names,
        instance_names => $instance_names,
        auxiliary_assignment_count => scalar(@{$structural_rtl_ir_hash->{auxiliary_assignments} || []}),
    );
}

sub build_output_drive_family_metadata ($class, %args) {
    my $module_info = $args{module_info};
    return [] unless ref($module_info) eq 'HASH';

    my %output_widths = map {
        (($_->{name} // '') => ($_->{width} || 1))
    } @{$module_info->{signal_analysis}{outputs} || []};

    return [] unless %output_widths;

    my $hdl_generator = $args{hdl_generator};
    my $assignment_analysis = $hdl_generator ? ($hdl_generator->{assignment_analysis} || {}) : {};
    my @drive_families;

    for my $lhs (sort keys %$assignment_analysis) {
        next unless exists $output_widths{$lhs};

        my $lhs_analysis = $assignment_analysis->{$lhs};
        next unless ref($lhs_analysis) eq 'HASH';

        my %driver_blocks;
        my %rhs_values;
        my %driver_enable_signals;
        my %family_enable_signals;
        my %rhs_enable_families;

        for my $rhs (sort keys %{ $lhs_analysis->{rhs_groups} || {} }) {
            my $rhs_group = $lhs_analysis->{rhs_groups}{$rhs};
            next unless ref($rhs_group) eq 'HASH';

            $rhs_values{$rhs} = 1;
            $rhs_enable_families{$rhs} ||= {
                rhs_value => $rhs,
                family_enable_signal => undef,
                driver_blocks => {},
                driver_enable_signals => {},
            };

            my $lhs_level_enable = $rhs_group->{lhs_level_enable};
            if (ref($lhs_level_enable) eq 'HASH' && defined $lhs_level_enable->{name}) {
                $family_enable_signals{$lhs_level_enable->{name}} = 1;
                $rhs_enable_families{$rhs}{family_enable_signal} = $lhs_level_enable->{name};
            }

            for my $dt_enable_info (@{ $rhs_group->{dt_specific_enables} || [] }) {
                next unless ref($dt_enable_info) eq 'HASH';
                $driver_blocks{$dt_enable_info->{dt}} = 1 if defined $dt_enable_info->{dt};
                $driver_enable_signals{$dt_enable_info->{enable_name}} = 1
                    if defined $dt_enable_info->{enable_name};
                $rhs_enable_families{$rhs}{driver_blocks}{$dt_enable_info->{dt}} = 1
                    if defined $dt_enable_info->{dt};
                $rhs_enable_families{$rhs}{driver_enable_signals}{$dt_enable_info->{enable_name}} = 1
                    if defined $dt_enable_info->{enable_name};
            }
        }

        my @driver_blocks = sort keys %driver_blocks;
        my @rhs_values = sort keys %rhs_values;
        next unless @driver_blocks || @rhs_values;

        my $reset_value = $hdl_generator
            ? $hdl_generator->{enable_graph_signal_support}->get_reset_value_from_ast($lhs_analysis->{lhs_ast})
            : undef;

        push @drive_families, {
            signal_name => $lhs,
            width => $output_widths{$lhs},
            multiplexer_type => ($lhs_analysis->{multiplexer}{type} // 'unknown'),
            default_value => $lhs_analysis->{multiplexer}{default_value},
            reset_value => $reset_value,
            driver_count => scalar(@driver_blocks),
            driver_blocks => \@driver_blocks,
            rhs_values => \@rhs_values,
            driver_enable_signals => [ sort keys %driver_enable_signals ],
            family_enable_signals => [ sort keys %family_enable_signals ],
            rhs_enable_families => [
                map {
                    +{
                        rhs_value => $_->{rhs_value},
                        family_enable_signal => $_->{family_enable_signal},
                        driver_blocks => [ sort keys %{$_->{driver_blocks} || {}} ],
                        driver_enable_signals => [ sort keys %{$_->{driver_enable_signals} || {}} ],
                    }
                } map {
                    $rhs_enable_families{$_}
                } sort keys %rhs_enable_families
            ],
        };
    }

    return \@drive_families;
}

sub build_selector_conflict_target_metadata ($class, %args) {
    my $hdl_generator = $args{hdl_generator};
    my $assignment_analysis = $hdl_generator ? ($hdl_generator->{assignment_analysis} || {}) : {};
    my @targets;

    for my $lhs (sort keys %$assignment_analysis) {
        my $lhs_analysis = $assignment_analysis->{$lhs};
        next unless ref($lhs_analysis) eq 'HASH';

        my @rhs_values;
        my @family_enable_signals;
        my @rhs_enable_families;

        for my $rhs (sort keys %{ $lhs_analysis->{rhs_groups} || {} }) {
            my $rhs_group = $lhs_analysis->{rhs_groups}{$rhs};
            next unless ref($rhs_group) eq 'HASH';

            my $lhs_level_enable = $rhs_group->{lhs_level_enable};
            my $family_enable_signal = (
                ref($lhs_level_enable) eq 'HASH' && defined $lhs_level_enable->{name}
                    ? $lhs_level_enable->{name}
                    : undef
            );
            my @driver_enable_signals = sort grep {
                defined($_) && length($_)
            } map {
                ref($_) eq 'HASH' ? $_->{enable_name} : undef
            } @{ $rhs_group->{dt_specific_enables} || [] };

            push @rhs_values, $rhs;
            push @family_enable_signals, $family_enable_signal
                if defined($family_enable_signal) && length($family_enable_signal);
            push @rhs_enable_families, {
                rhs_value => $rhs,
                family_enable_signal => $family_enable_signal,
                driver_enable_signals => \@driver_enable_signals,
                same_value_assertion => $class->selector_conflict_assertion_metadata(
                    target_signal => $lhs,
                    rhs_value => $rhs,
                    input_enable_signals => \@driver_enable_signals,
                ),
            };
        }

        my @same_value_families = grep {
            (($_->{same_value_assertion} || {})->{input_count} || 0) > 1
        } @rhs_enable_families;
        my $multi_value_assertion = $class->selector_conflict_assertion_metadata(
            target_signal => $lhs,
            input_enable_signals => \@family_enable_signals,
        );
        my $has_multi_value_assertion = ($multi_value_assertion->{input_count} || 0) > 1 ? 1 : 0;

        next unless @same_value_families || $has_multi_value_assertion;

        push @targets, {
            signal_name => $lhs,
            multiplexer_type => ($lhs_analysis->{multiplexer}{type} // 'unknown'),
            rhs_values => \@rhs_values,
            family_enable_signals => \@family_enable_signals,
            rhs_enable_families => \@rhs_enable_families,
            multi_value_assertion => $multi_value_assertion,
        };
    }

    return \@targets;
}

sub standalone_dt_assertion_metadata ($class, $signal_name, $input_enable_signals) {
    my @inputs = grep {
        defined($_) && length($_)
    } @{$input_enable_signals || []};

    return {
        kind => 'onehot0',
        target_signal => $signal_name,
        input_count => scalar(@inputs),
        input_enable_signals => \@inputs,
    };
}

sub selector_conflict_assertion_metadata ($class, %args) {
    my @inputs = grep {
        defined($_) && length($_)
    } @{$args{input_enable_signals} || []};

    my $metadata = {
        kind => 'onehot0',
        target_signal => ($args{target_signal} // ''),
        input_count => scalar(@inputs),
        input_enable_signals => \@inputs,
    };

    $metadata->{rhs_value} = $args{rhs_value}
        if exists $args{rhs_value};

    return $metadata;
}

1;

__END__

=head1 METHODS

=head2 build_from_generated_module_info

Builds the bounded direct-root L<FSM::IR::LoweredRTLIR> object from generated
module analysis plus the direct HDL backend analysis state.

=head2 build_from_composition_plan

Builds the bounded composition-top L<FSM::IR::LoweredRTLIR> object from an
already-built composition plan plus optional explicit structural, semantic,
and shared-datapath inputs.

=head2 build_output_drive_family_metadata

Builds the direct-root output-drive family summary from generated-module
analysis plus the active direct HDL backend analysis state.

=head2 build_selector_conflict_target_metadata

Builds the generated-module mux-selector conflict summary from backend
assignment analysis. This covers every analyzed LHS mux, not just public
outputs, and records both same-value source selectors and whole-target value
selectors.

=head2 standalone_dt_assertion_metadata

Builds the bounded onehot-style multi-drive assertion metadata attached to
direct-root standalone-DT lowered targets.

=head2 selector_conflict_assertion_metadata

Builds the bounded onehot-style runtime selector assertion metadata used by
generated-module verification-only instrumentation.

=cut

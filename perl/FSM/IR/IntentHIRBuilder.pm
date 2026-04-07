package FSM::IR::IntentHIRBuilder;

=head1 NAME

FSM::IR::IntentHIRBuilder - Builder for bounded forward Intent HIR surfaces

=head1 DESCRIPTION

Owns the bounded forward Intent HIR construction paths that have been extracted
out of the mixed pipeline coordinator. Right now this package builds the
composition-top semantic summary from an already-built composition plan plus
the surrounding structural and child-export inputs, and it also owns the
bounded direct-root semantic summary extracted from the direct pipeline path.

=cut

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Debug;
use FSM::Composition::ChildExportBuilder;
use FSM::IR::IntentHIR;
use FSM::IR::StructuralRTLIR;
use FSM::IR::StructuralRTLIRBuilder;

sub build_from_fsm_module ($class, %args) {
    my $fsm_module = $args{fsm_module}
        or confess "IntentHIRBuilder requires a fsm_module";

    fsm_trace_enter('Analyze FSM module structure and signals', 2);
    fsm_debug("Analyzing FSM module structure", 1);

    my $module_name = $fsm_module->name;
    my @all_states = @{$fsm_module->states};
    my %all_signals = %{$fsm_module->signals};

    my @regular_states = grep {
        $_->can('is_regular_state') ? $_->is_regular_state : $_->name !~ /^-/
    } @all_states;
    my @standalone_dts = grep {
        $_->can('is_regular_state') ? !$_->is_regular_state : $_->name =~ /^-/
    } @all_states;

    fsm_debug("Module analysis:", 1);
    fsm_debug("  Module name: $module_name", 1);
    fsm_debug("  Regular states: " . scalar(@regular_states), 1);
    fsm_debug("  Standalone DTs: " . scalar(@standalone_dts), 1);
    fsm_debug("  Total signals: " . scalar(keys %all_signals), 1);

    my %signal_analysis = $class->analyze_signals(\%all_signals);
    my $standalone_dt_enable_metadata = $class->build_standalone_dt_enable_metadata(\@all_states);
    my @parameter_names = sort keys %{ $fsm_module->parameters || {} };
    my $symbol_contract = $class->build_direct_root_symbol_contract($fsm_module);

    my $intent_hir = FSM::IR::IntentHIR->new(
        module_name => $module_name,
        source_root_kind => (
            $fsm_module->can('source_root_kind')
                ? $fsm_module->source_root_kind
                : 'fsm'
        ),
        regular_state_names => [ map { $_->name } @regular_states ],
        standalone_dt_names => $standalone_dt_enable_metadata->{standalone_dt_names},
        signal_names => [ sort keys %all_signals ],
        signal_analysis => \%signal_analysis,
        explicit_system_contract => (
            $fsm_module->can('explicit_system_contract')
                ? $fsm_module->explicit_system_contract
                : undef
        ),
        system_contract => (
            $fsm_module->can('effective_system_contract')
                ? $fsm_module->effective_system_contract
                : {
                    clock => 'clk',
                    reset => 'rst_n',
                    reset_keyword => 'asreset',
                    implicit => 1,
                }
        ),
        requires_implicit_system_ports => (
            $fsm_module->can('requires_implicit_system_ports')
                ? $fsm_module->requires_implicit_system_ports
                : 1
        ),
        standalone_dt_enable_families => $standalone_dt_enable_metadata->{standalone_dt_enable_families},
        standalone_dt_module_enable_family => $standalone_dt_enable_metadata->{standalone_dt_module_enable_family},
        parameter_names => \@parameter_names,
        symbol_contract => $symbol_contract,
    );

    fsm_trace_exit('FSM module analysis complete', 2);
    return $intent_hir;
}

sub build_from_composition_plan ($class, %args) {
    my $composition_plan = $args{composition_plan}
        or confess "IntentHIRBuilder requires a composition_plan";
    my $target_language = $args{target_language} // 'systemverilog';

    my $composition_child_exports = $args{composition_child_exports}
        // FSM::Composition::ChildExportBuilder->build_child_exports(
            composition_plan => $composition_plan,
            target_language => $target_language,
        );
    my $generated_child_exports = $args{generated_child_exports}
        // FSM::Composition::ChildExportBuilder->build_generated_child_exports(
            composition_child_exports => $composition_child_exports,
        );
    my $standalone_dt_child_exports = $args{standalone_dt_child_exports}
        // FSM::Composition::ChildExportBuilder->build_standalone_dt_child_exports(
            composition_child_exports => $composition_child_exports,
        );
    my $structural_rtl_ir = $args{structural_rtl_ir}
        // FSM::IR::StructuralRTLIRBuilder->build_from_composition_plan(
            $composition_plan,
            $target_language,
        );

    my $port_metadata = FSM::IR::StructuralRTLIR->port_metadata_from_input($structural_rtl_ir);
    my $structural_rtl_ir_hash = ref($structural_rtl_ir) eq 'HASH'
        ? $structural_rtl_ir
        : ref($structural_rtl_ir)
            ? $structural_rtl_ir->as_hashref
            : {};

    return FSM::IR::IntentHIR->new(
        module_name => ($structural_rtl_ir_hash->{module_name} // $composition_plan->top_name // ''),
        source_root_kind => 'top',
        regular_state_names => [],
        standalone_dt_names => [],
        signal_names => $port_metadata->{signal_names},
        signal_analysis => $port_metadata->{signal_analysis},
        explicit_system_contract => undef,
        system_contract => {},
        requires_implicit_system_ports => 0,
        standalone_dt_enable_families => [],
        standalone_dt_module_enable_family => {},
        parameter_names => [],
        symbol_contract => $class->build_composition_top_symbol_contract($composition_plan),
        composition_child_count => $composition_child_exports->{child_count},
        composition_children => $composition_child_exports->{children},
        composition_generated_child_count => $generated_child_exports->{child_count},
        composition_generated_fsm_child_count => $generated_child_exports->{fsm_child_count},
        composition_generated_dt_child_count => $generated_child_exports->{dt_child_count},
        composition_generated_children => $generated_child_exports->{children},
        composition_standalone_dt_child_count => $standalone_dt_child_exports->{child_count},
        composition_standalone_dt_block_count => $standalone_dt_child_exports->{block_count},
        composition_standalone_dt_multi_drive_target_count => $standalone_dt_child_exports->{multi_drive_target_count},
        composition_standalone_dt_children => $standalone_dt_child_exports->{children},
        composition_lane => $composition_plan->lane,
    );
}

sub build_direct_root_symbol_contract ($class, $fsm_module) {
    return undef unless $fsm_module && ref($fsm_module);

    my $direct_root_symbols = $fsm_module->can('direct_root_symbols')
        ? $fsm_module->direct_root_symbols
        : undef;
    my $package_imports = $fsm_module->can('package_imports')
        ? $fsm_module->package_imports
        : [];

    my $symbol_contract = (
        $direct_root_symbols && $direct_root_symbols->can('as_hashref')
            ? $direct_root_symbols->as_hashref
            : {}
    );

    $symbol_contract->{package_import_count} = scalar(@{$package_imports || []});
    $symbol_contract->{package_imports} = [ @{$package_imports || []} ];

    my $has_local_symbols = (
        ($symbol_contract->{constant_count} // 0) > 0
        || ($symbol_contract->{enum_count} // 0) > 0
    );
    my $has_imports = ($symbol_contract->{package_import_count} // 0) > 0;

    return undef unless $has_local_symbols || $has_imports;
    return $symbol_contract;
}

sub build_composition_top_symbol_contract ($class, $composition_plan) {
    return undef unless $composition_plan && ref($composition_plan);

    my $composition_spec = $composition_plan->can('raw_spec')
        ? $composition_plan->raw_spec
        : undef;
    my $top = $composition_spec && $composition_spec->can('top')
        ? $composition_spec->top
        : undef;

    return undef unless $top && ref($top);

    my $top_symbols = $top->can('top_symbols')
        ? $top->top_symbols
        : undef;
    my $package_imports = $top->can('package_imports')
        ? $top->package_imports
        : [];

    my $symbol_contract = (
        $top_symbols && $top_symbols->can('as_hashref')
            ? $top_symbols->as_hashref
            : {}
    );

    $symbol_contract->{package_import_count} = scalar(@{$package_imports || []});
    $symbol_contract->{package_imports} = [ @{$package_imports || []} ];

    my $has_local_symbols = (
        ($symbol_contract->{constant_count} // 0) > 0
        || ($symbol_contract->{enum_count} // 0) > 0
    );
    my $has_imports = ($symbol_contract->{package_import_count} // 0) > 0;

    return undef unless $has_local_symbols || $has_imports;
    return $symbol_contract;
}

sub build_standalone_dt_enable_metadata ($class, $all_states) {
    my @standalone_dt_blocks = sort {
        $a->name cmp $b->name
    } grep {
        ref($_) && $_->can('is_standalone_dt') && $_->is_standalone_dt
    } @{$all_states || []};

    my @enable_families = map {
        my $dt_name = $_->name;
        my $enable_signal = $dt_name;
        $enable_signal =~ s/^-//;
        $enable_signal .= '_en';

        {
            dt_name => $dt_name,
            enable_signal => $enable_signal,
        };
    } @standalone_dt_blocks;

    my @dt_names = map { $_->{dt_name} } @enable_families;
    my @enable_signals = map { $_->{enable_signal} } @enable_families;

    return {
        standalone_dt_count => scalar(@enable_families),
        standalone_dt_names => \@dt_names,
        standalone_dt_enable_families => \@enable_families,
        standalone_dt_module_enable_family => {
            dt_names => \@dt_names,
            enable_signals => \@enable_signals,
        },
    };
}

sub analyze_signals ($class, $signals) {
    fsm_trace_enter('Analyze signal roles, width, and direction', 3);
    fsm_debug("Analyzing signal properties", 2);

    my %analysis = (
        inputs => [],
        outputs => [],
        multi_bit => [],
        single_bit => [],
    );

    for my $sig_name (sort keys %{$signals || {}}) {
        my $signal = $signals->{$sig_name};
        my $width = $signal->width || 1;
        my $dir = $class->determine_signal_direction($signal, $sig_name);

        fsm_debug("Processing signal '$sig_name'", 2);
        fsm_debug("  Signal object type: " . ref($signal), 3);
        fsm_debug("  Width method available: " . ($signal->can('width') ? 'YES' : 'NO'), 3);
        if ($signal->can('width')) {
            my $raw_width = $signal->width;
            fsm_debug("  Raw width value: " . (defined($raw_width) ? $raw_width : 'UNDEF'), 3);
        }
        fsm_debug("  Final computed width: $width", 2);

        if ($dir eq 'output') {
            push @{$analysis{outputs}}, {
                name => $sig_name,
                width => $width,
                signal => $signal,
            };
        } else {
            push @{$analysis{inputs}}, {
                name => $sig_name,
                width => $width,
                signal => $signal,
            };
        }

        if ($width > 1) {
            push @{$analysis{multi_bit}}, {
                name => $sig_name,
                width => $width,
                direction => $dir,
            };
            fsm_debug("*** Multi-bit signal detected: $sig_name with width $width ***", 2);
        } else {
            push @{$analysis{single_bit}}, {
                name => $sig_name,
                direction => $dir,
            };
            fsm_debug("Single-bit signal: $sig_name", 3);
        }
    }

    fsm_debug("Signal analysis complete:", 2);
    fsm_debug("  Input signals: " . scalar(@{$analysis{inputs}}), 2);
    fsm_debug("  Output signals: " . scalar(@{$analysis{outputs}}), 2);
    fsm_debug("  Multi-bit signals: " . scalar(@{$analysis{multi_bit}}), 2);
    fsm_debug("  Single-bit signals: " . scalar(@{$analysis{single_bit}}), 2);

    fsm_trace_exit('Signal analysis complete', 3);
    return %analysis;
}

sub determine_signal_direction ($class, $signal, $sig_name) {
    fsm_trace_enter("Determine signal direction for '$sig_name'", 4);
    if ($signal->can('get_attribute')) {
        my $signal_role = $signal->get_attribute('signal_role');
        if (defined $signal_role && $signal_role eq 'OUTPUT') {
            fsm_trace_decision(1, "Signal '$sig_name' signal_role reports OUTPUT", 4);
            fsm_trace_exit("Direction resolved for '$sig_name' => output", 4);
            return 'output';
        }
        if (defined $signal_role && $signal_role eq 'INPUT') {
            fsm_trace_decision(1, "Signal '$sig_name' signal_role reports INPUT", 4);
            fsm_trace_exit("Direction resolved for '$sig_name' => input", 4);
            return 'input';
        }
    }

    if ($signal->can('is_output') && $signal->is_output) {
        fsm_trace_decision(1, "Signal '$sig_name' is_output accessor reports true", 4);
        fsm_trace_exit("Direction resolved for '$sig_name' => output", 4);
        return 'output';
    } elsif ($signal->can('attributes') && $signal->attributes && $signal->attributes->{is_output}) {
        fsm_trace_decision(1, "Signal '$sig_name' attributes->{is_output} is true", 4);
        fsm_trace_exit("Direction resolved for '$sig_name' => output", 4);
        return 'output';
    } elsif ($sig_name =~ />$/ || ($sig_name =~ /^p/ && $sig_name !~ /^p(ready|rdata)$/)) {
        fsm_trace_decision(1, "Signal '$sig_name' inferred output by naming policy", 4);
        fsm_trace_exit("Direction resolved for '$sig_name' => output", 4);
        return 'output';
    } else {
        fsm_trace_decision(1, "Signal '$sig_name' defaulted to input direction", 4);
        fsm_trace_exit("Direction resolved for '$sig_name' => input", 4);
        return 'input';
    }
}

1;

__END__

=head1 METHODS

=head2 build_from_fsm_module

Builds the bounded direct-root L<FSM::IR::IntentHIR> object from a semantic
FSM/DT module.

=head2 build_from_composition_plan

Builds the bounded composition-top L<FSM::IR::IntentHIR> object from an
already-built composition plan plus optional explicit structural and
child-export inputs.

=head2 build_standalone_dt_enable_metadata

Builds the standalone-DT enable-family semantic summary used by direct-root
intent construction.

=head2 analyze_signals

Analyzes direct-root signals into grouped input/output and width families for
the semantic intent layer.

=head2 determine_signal_direction

Determines the semantic direction of one direct-root signal using explicit
attributes first and the existing naming fallback second.

=head2 build_from_composition_plan

Builds the bounded composition-top L<FSM::IR::IntentHIR> object from an
already-built composition plan plus optional explicit structural and
child-export inputs.

=cut

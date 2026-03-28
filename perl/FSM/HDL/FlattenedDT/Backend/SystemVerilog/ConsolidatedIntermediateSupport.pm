package FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport;

=head1 NAME

FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport - Own direct consolidated intermediate collection and merge support

=head1 DESCRIPTION

This package owns the collection half of the direct consolidated
intermediate-signal flow for the older SystemVerilog backend. It centralizes:

=over 4

=item *

pre-emission tracing of available FSM-level signal inventory

=item *

collection and merge of AST-factorized, pre-scanned, and FSMGen-parsed
intermediate signals

=back

The paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateEmitter>
now keeps final HDL emission, the paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateNormalizationSupport>
now keeps runtime metadata normalization, the paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediatePlanningSupport>
keeps dependency-aware rescue/filter/order planning, the paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateBlockSupport>
now owns the collection-plus-planning handoff for one prepared block, and this
package owns collection and merge preparation before normalization.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use Data::Dumper;
use FSM::Debug;
use Scalar::Util qw(blessed);

=head2 new

Construct one consolidated-intermediate support owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=cut

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[ConsolidatedIntermediateSupport.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

=head2 trace_fsm_signal_inventory

Emit the detailed debug-only trace of the FSM module signal inventory at the
entry to consolidated intermediate preparation.

=cut

sub trace_fsm_signal_inventory ($self, $fsm_module) {
    return unless $fsm_module && $fsm_module->signals;

    my $fsm_signals = $fsm_module->signals;
    my $total_signals = scalar(keys %$fsm_signals);
    fsm_debug("SIGNAL_TRACE: FSM module has $total_signals total signals at PIPELINE_ENTRY", 3);

    my (@intermediate_signals, @regular_signals, @or_pattern_signals, @signals_with_driving_ast);

    for my $sig_name (sort keys %$fsm_signals) {
        my $signal = $fsm_signals->{$sig_name};

        my $has_driving_ast = ($signal->can('driving_ast') && $signal->driving_ast) ? 1 : 0;
        my $is_intermediate = 0;

        if ($signal->can('get_attribute')) {
            $is_intermediate = $signal->get_attribute('is_intermediate') || 0;
        } elsif ($signal->can('attributes') && $signal->attributes) {
            $is_intermediate = $signal->attributes->{is_intermediate} || 0;
        }

        my $ast_info = "NONE";
        my $expression_info = "NONE";
        my $ast_dump = "NO_AST";

        if ($has_driving_ast) {
            my $driving_ast = $signal->driving_ast;
            $ast_info = ref($driving_ast) || "UNKNOWN_TYPE";

            if ($driving_ast && $driving_ast->can('to_systemverilog')) {
                $expression_info = eval { $driving_ast->to_systemverilog() } || "[AST_TO_SV_FAILED]";
            } else {
                $expression_info = "[NO_TO_SYSTEMVERILOG_METHOD]";
            }

            $ast_dump = Data::Dumper->new([$driving_ast], ["${sig_name}_AST"])->Indent(2)->Sortkeys(1)->Dump();
        }

        if ($is_intermediate) {
            push @intermediate_signals, $sig_name;
        }
        if ($has_driving_ast) {
            push @signals_with_driving_ast, $sig_name;
        }
        if ($sig_name =~ /^or_\d+_\d+$/) {
            push @or_pattern_signals, $sig_name;
        } else {
            push @regular_signals, $sig_name;
        }

        fsm_debug("\n=== SIGNAL ANALYSIS: [$sig_name] ===", 3);
        fsm_debug("  Signal object type: " . ref($signal), 3);
        fsm_debug("  Has driving_ast: " . ($has_driving_ast ? "YES" : "NO"), 3);
        fsm_debug("  Is intermediate: " . ($is_intermediate ? "YES" : "NO"), 3);
        fsm_debug("  AST type: $ast_info", 3);
        fsm_debug("  SystemVerilog expression: $expression_info", 3);
        fsm_debug("  AST DUMP:", 3);
        my @dump_lines = split(/\n/, $ast_dump);
        for my $line (@dump_lines) {
            fsm_debug("    $line", 3);
        }
        fsm_debug("=== END SIGNAL: [$sig_name] ===\n", 3);
    }

    fsm_debug("\n*** SIGNAL_TRACE SUMMARY ***", 3);
    fsm_debug("  - Total signals: $total_signals", 3);
    fsm_debug("  - Intermediate signals: " . scalar(@intermediate_signals) . " (" . join(", ", @intermediate_signals) . ")", 3);
    fsm_debug("  - Signals with driving_ast: " . scalar(@signals_with_driving_ast) . " (" . join(", ", @signals_with_driving_ast) . ")", 3);
    fsm_debug("  - or_*_* pattern signals: " . scalar(@or_pattern_signals) . " (" . join(", ", @or_pattern_signals) . ")", 3);
    fsm_debug("  - Regular signals: " . scalar(@regular_signals), 3);
    fsm_debug("*** END SIGNAL_TRACE SUMMARY ***\n", 3);
}

=head2 merge_ast_factorization_signals

Merge first-pass AST-factorization results into one consolidated intermediate
signal set.

=cut

sub merge_ast_factorization_signals ($self, $all_intermediate_signals, $ast_intermediate_signals) {
    return unless $ast_intermediate_signals && %$ast_intermediate_signals;

    for my $signal_name (keys %$ast_intermediate_signals) {
        $all_intermediate_signals->{$signal_name} = {
            source => 'ast_factorization',
            %{$ast_intermediate_signals->{$signal_name}},
        };
    }
}

=head2 merge_prescan_intermediate_signals

Merge referenced pre-scan intermediate signals into one consolidated signal
set when they were not already produced by first-pass factorization.

=cut

sub merge_prescan_intermediate_signals ($self, $all_intermediate_signals) {
    my $ctx = $self->{flattened_dt};
    my $recovery_support = $ctx->{backend_sv_intermediate_recovery_support};
    return unless $ctx->{referenced_intermediate_signals};

    for my $signal_name (keys %{$ctx->{referenced_intermediate_signals}}) {
        next if exists $all_intermediate_signals->{$signal_name};

        my $referenced_signal_info = $ctx->{referenced_intermediate_signals}->{$signal_name} || {};
        my $runtime_ast = $recovery_support->resolve_intermediate_signal_runtime_ast($signal_name, $referenced_signal_info);
        my $expression = (!$runtime_ast || !blessed($runtime_ast))
            ? $ctx->{enable_graph_intermediate_support}->get_intermediate_signal_expression($signal_name)
            : undef;

        if (($runtime_ast && blessed($runtime_ast)) || $expression) {
            $all_intermediate_signals->{$signal_name} = {
                source => 'prescan_reference',
                %$referenced_signal_info,
                ($runtime_ast && blessed($runtime_ast) ? (ast => $runtime_ast, runtime_ast => $runtime_ast) : ()),
                (defined($expression) && $expression ne '' ? (expression => $expression) : ()),
                usage_count => 1,
            };
        }
    }
}

=head2 merge_fsmgen_parsed_intermediate_signals

Merge FSMGen-parsed intermediate signals with native driving ASTs into one
consolidated signal set.

=cut

sub merge_fsmgen_parsed_intermediate_signals ($self, $all_intermediate_signals, $fsm_module) {
    return unless $fsm_module && $fsm_module->can('signals') && $fsm_module->signals;

    fsm_debug("CONSOL_INTER_SIG: [FSMGEN_SIGNALS] Scanning FSM module for intermediate signals from parsing", 3);
    my $fsm_signals = $fsm_module->signals;
    my $fsmgen_intermediate_count = 0;

    fsm_debug("  FSMGEN_SIGNALS: FSM module has " . scalar(keys %$fsm_signals) . " total signals", 3);

    for my $signal_name (keys %$fsm_signals) {
        my $signal = $fsm_signals->{$signal_name};

        fsm_debug("  FSMGEN_SIGNAL_SCAN: '$signal_name' -> " . ref($signal), 3);

        if ($signal && $signal->can('driving_ast') && $signal->driving_ast) {
            fsm_debug("    HAS_DRIVING_AST: '$signal_name' has driving AST", 3);

            my $is_intermediate = 0;
            fsm_debug("      SIGNAL_DEBUG: Processing signal '$signal_name'", 3);
            fsm_debug("        Signal object type: " . ref($signal), 3);
            fsm_debug("        Signal blessed: " . (blessed($signal) ? 'YES' : 'NO'), 3);

            if ($signal->can('get_attribute')) {
                $is_intermediate = $signal->get_attribute('is_intermediate');
                fsm_debug("      METHOD1: get_attribute('is_intermediate') = " . (defined($is_intermediate) ? $is_intermediate : 'undef'), 3);
            }

            if (!$is_intermediate && $signal->can('attributes') && $signal->attributes) {
                $is_intermediate = $signal->attributes->{is_intermediate};
                fsm_debug("      METHOD2: attributes->{is_intermediate} = " . (defined($is_intermediate) ? $is_intermediate : 'undef'), 3);
            }

            if (!$is_intermediate && ref($signal) eq 'HASH' && exists($signal->{is_intermediate})) {
                $is_intermediate = $signal->{is_intermediate};
                fsm_debug("      METHOD3: signal->{is_intermediate} = " . (defined($is_intermediate) ? $is_intermediate : 'undef'), 3);
            }

            if (!$is_intermediate && blessed($signal) && $signal->can('is_intermediate')) {
                $is_intermediate = eval { $signal->is_intermediate } || 0;
                fsm_debug("      METHOD4: signal->is_intermediate() = " . (defined($is_intermediate) ? $is_intermediate : 'undef'), 3);
            }

            if (!$is_intermediate && blessed($signal)) {
                my $signal_hash = eval { \%{$signal} };
                if ($signal_hash && exists $signal_hash->{is_intermediate}) {
                    $is_intermediate = $signal_hash->{is_intermediate};
                    fsm_debug("      METHOD5: direct hash deref to is_intermediate = " . (defined($is_intermediate) ? $is_intermediate : 'undef'), 3);
                }
            }

            if (!$is_intermediate && blessed($signal) && $signal->isa('FSM::CoreAST::Signal')) {
                for my $key (keys %$signal) {
                    if ($key eq 'is_intermediate' && defined($signal->{$key})) {
                        $is_intermediate = $signal->{$key};
                        fsm_debug("      METHOD6: Found is_intermediate as direct key '$key' = $is_intermediate", 3);
                        last;
                    }
                }
            }

            fsm_debug("    IS_INTERMEDIATE_CHECK: '$signal_name' intermediate status: " . ($is_intermediate || 'undefined'), 3);

            if ($is_intermediate) {
                my $driving_ast = $signal->driving_ast;

                if (exists $all_intermediate_signals->{$signal_name}) {
                    fsm_debug("  FSMGEN_INTERMEDIATE: Signal '$signal_name' already exists, but UPDATING with FSMGenFull AST data", 3);
                    $all_intermediate_signals->{$signal_name} = {
                        source => 'fsmgen_parsing',
                        ast => $driving_ast,
                        width => ($signal->can('width') ? $signal->width : undef) || 1,
                        usage_count => 1,
                        driving_ast => $driving_ast,
                    };
                    $fsmgen_intermediate_count++;

                    fsm_debug("  FSMGEN_INTERMEDIATE: UPDATED signal '$signal_name' with driving AST: " . ref($driving_ast), 3);
                    my $updated_ast_sv = eval { $driving_ast->to_systemverilog() };
                    $updated_ast_sv = '[AST ERROR]' if !defined($updated_ast_sv) || $updated_ast_sv eq '' || $@;
                    fsm_debug("    AST SystemVerilog: $updated_ast_sv", 3);
                } else {
                    fsm_debug("  FSMGEN_INTERMEDIATE: Found NEW signal '$signal_name' with driving AST: " . ref($driving_ast), 3);
                    my $new_ast_sv = eval { $driving_ast->to_systemverilog() };
                    $new_ast_sv = '[AST ERROR]' if !defined($new_ast_sv) || $new_ast_sv eq '' || $@;
                    fsm_debug("    AST SystemVerilog: $new_ast_sv", 3);

                    $all_intermediate_signals->{$signal_name} = {
                        source => 'fsmgen_parsing',
                        ast => $driving_ast,
                        width => ($signal->can('width') ? $signal->width : undef) || 1,
                        usage_count => 1,
                        driving_ast => $driving_ast,
                    };
                    $fsmgen_intermediate_count++;
                }
            } else {
                fsm_debug("    NOT_INTERMEDIATE: Signal '$signal_name' has driving AST but is not marked as intermediate", 3);
            }
        } else {
            if (!$signal) {
                fsm_debug("    SKIP: '$signal_name' - signal object is null", 3);
            } elsif (!$signal->can('driving_ast')) {
                fsm_debug("    SKIP: '$signal_name' - signal has no driving_ast method", 3);
            } elsif (!$signal->driving_ast) {
                fsm_debug("    SKIP: '$signal_name' - signal has no driving_ast set", 3);
            }
        }
    }

    fsm_debug("CONSOL_INTER_SIG: [FSMGEN_SIGNALS] Found $fsmgen_intermediate_count intermediate signals from FSMGenFull parsing", 3);
}

=head2 collect_consolidated_intermediate_signals

Build the consolidated intermediate-signal set for the direct backend by
merging first-pass factorization, pre-scan references, and FSMGen-parsed
intermediate carriers, then delegating normalized metadata preparation to the
extracted normalization owner.

=cut

sub collect_consolidated_intermediate_signals ($self, $fsm_module) {
    my $ctx = $self->{flattened_dt};
    $ctx->{intermediate_signals} = {};

    fsm_debug("\n*** CONSOLIDATED INTERMEDIATE SIGNAL GENERATION ***", 3);
    fsm_debug("CONSOL_INTER_SIG: [ENTRY] FSM module: " . ($fsm_module ? $fsm_module->name : 'undefined'), 3);
    fsm_debug("CONSOL_INTER_SIG: [ENTRY] Current intermediate signals count: " . scalar(keys %{$ctx->{intermediate_signals} || {}}), 3);
    fsm_debug("CONSOL_INTER_SIG: [ENTRY] Current referenced signals count: " . scalar(keys %{$ctx->{referenced_intermediate_signals} || {}}), 3);

    if ($fsm_module && $fsm_module->signals) {
        $self->trace_fsm_signal_inventory($fsm_module);
    } else {
        fsm_debug("SIGNAL_TRACE: WARNING - No FSM module or signals available at pipeline entry!", 3);
    }

    my %all_intermediate_signals;
    my $ast_intermediate_signals = $ctx->{backend_sv_global_factorization}->run_global_ast_factorization();

    $self->merge_ast_factorization_signals(\%all_intermediate_signals, $ast_intermediate_signals);
    $self->merge_prescan_intermediate_signals(\%all_intermediate_signals);
    $self->merge_fsmgen_parsed_intermediate_signals(\%all_intermediate_signals, $fsm_module);
    $ctx->{backend_sv_consolidated_intermediate_normalization_support}
        ->normalize_consolidated_intermediate_metadata(\%all_intermediate_signals);

    return \%all_intermediate_signals;
}

1;

__END__

=head1 METHODS

=head2 new

Constructs one consolidated-intermediate support owner bound to a direct
backend context.

=head2 trace_fsm_signal_inventory

Emits the detailed debug-only trace of the live FSM module signal inventory.

=head2 merge_ast_factorization_signals

Merges first-pass AST-factorization results into the consolidated signal set.

=head2 merge_prescan_intermediate_signals

Merges referenced pre-scan intermediate carriers into the consolidated signal
set when first-pass factorization did not already produce them.

=head2 merge_fsmgen_parsed_intermediate_signals

Merges FSMGen-parsed intermediate carriers with native driving ASTs into the
consolidated signal set.

=head2 collect_consolidated_intermediate_signals

Builds the fully merged consolidated signal set, then asks the extracted
normalization owner to prepare the runtime metadata that the downstream
selection, planning, and emission owners consume.

=cut

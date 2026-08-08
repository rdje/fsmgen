#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::HDL::FlattenedDT;
use FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateAssignmentSupport;
use FSM::Pipeline::SourceFrontend;
use FSM::Debug qw(
    capture_fsm_debug_state
    restore_fsm_debug_state
    set_fsm_debug_level
);

my $saved_debug_state = capture_fsm_debug_state();
END { restore_fsm_debug_state($saved_debug_state) if $saved_debug_state }

{
    package Local::CountedExpression;
    use strict;
    use warnings;
    use overload '""' => sub {
        my ($self) = @_;
        $self->{stringify_count}++;
        return $self->{text};
    }, fallback => 1;

    sub new {
        my ($class, $text) = @_;
        return bless { text => $text, stringify_count => 0 }, $class;
    }

    sub stringify_count {
        return $_[0]->{stringify_count};
    }
}

{
    package Local::FakeRecoverySupport;
    use v5.20;
    use strict;
    use warnings;
    use feature qw(signatures);
    no warnings 'experimental::signatures';

    sub new ($class) {
        return bless {}, $class;
    }

    sub render_intermediate_signal_expression ($self, $signal_name, $signal_info) {
        return $signal_info->{rendered_expression};
    }
}

subtest 'consolidated intermediate assignment support rebuilds prepared assign emission from a prepared backend context' => sub {
    my $fsm_module = parse_fsm_module(
        'sv_consolidated_assignment_support_contract',
        <<'FSM'
(?fsm:sv_consolidated_assignment_support_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (A 1)
    (B 1)
    (C 1)
    (D 1)
    (OUT1 1)
    (OUT2 1)
  )
  (idle
    (<(| A B)
      (OUT1 <= C)
    )
    (<(| A B)
      (OUT2 <= D)
    )
  )
)
FSM
    );

    my $prepared_backend = prepare_flattened_backend($fsm_module);
    my $assignment_support = FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateAssignmentSupport->new(
        flattened_dt => $prepared_backend,
    );

    my $all_intermediate_signals = $prepared_backend->{backend_sv_consolidated_intermediate_support}
        ->collect_consolidated_intermediate_signals($fsm_module);
    my $plan = $prepared_backend->{backend_sv_consolidated_intermediate_planning_support}
        ->plan_consolidated_intermediate_signals($all_intermediate_signals);
    my $prepared_block = $prepared_backend->{backend_sv_consolidated_intermediate_prepared_block_support}
        ->build_prepared_consolidated_intermediate_block($all_intermediate_signals, $plan);
    my $assignment_block = $assignment_support->render_consolidated_intermediate_assignments($prepared_block);

    like(
        $assignment_block,
        qr/\bassign A_or_B = A \| B; \/\/ Source: ast_factorization\b/,
        'assignment support keeps the shared factorized assign statement',
    );
    unlike(
        $assignment_block,
        qr{// Consolidated intermediate signals},
        'assignment support emits assign statements only, not the consolidated block header',
    );
    unlike(
        $assignment_block,
        qr/\bwire A_or_B;/,
        'assignment support leaves wire declarations to the narrowed emitter',
    );
};

subtest 'disabled assignment tracing does not duplicate rendered expression payloads' => sub {
    set_fsm_debug_level(0);
    my $expression = Local::CountedExpression->new('A & B');
    my $support = FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateAssignmentSupport->new(
        flattened_dt => {
            backend_sv_intermediate_recovery_support => Local::FakeRecoverySupport->new(),
        },
    );

    my $assignment_block = $support->render_consolidated_intermediate_assignments({
        filtered_signals => {
            counted_signal => {
                rendered_expression => $expression,
                source => 'ast_factorization',
            },
        },
        sorted_signals => ['counted_signal'],
    });

    is(
        $assignment_block,
        "  assign counted_signal = A & B; // Source: ast_factorization\n",
        'assignment emission still contains the required rendered expression',
    );
    is(
        $expression->stringify_count,
        2,
        'disabled tracing performs only the renderability check and required HDL emission',
    );
};

restore_fsm_debug_state($saved_debug_state);
$saved_debug_state = undef;

done_testing();

sub parse_fsm_module {
    my ($basename, $fsm_text) = @_;
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, "$basename.fsm");

    write_file($fsm_path, $fsm_text);
    my $raw_ast = FSM::Pipeline::SourceFrontend->parse_fsm_file(
        fsm_file => $fsm_path,
        debug_level => 0,
    );
    return FSM::Pipeline::SourceFrontend->create_fsm_module(
        raw_ast => $raw_ast,
        debug_level => 0,
    );
}

sub prepare_flattened_backend {
    my ($fsm_module) = @_;
    my $hdl_generator = FSM::HDL::FlattenedDT->new(debug => 0);
    $hdl_generator->{orchestrator}->reset_generation_state();
    $hdl_generator->{enable_graph_signal_support}->set_fsm_module_reference($fsm_module);
    $hdl_generator->{orchestrator}->flatten_all_decision_trees($fsm_module);
    $hdl_generator->{enable_graph_enable_support}->generate_enable_conditions($fsm_module);
    $hdl_generator->{enable_graph_factorization_policy_support}->count_binary_logical_operation_occurrences();
    $hdl_generator->{enable_graph_enable_support}->prescan_wen_en_for_intermediate_signals();
    return $hdl_generator;
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

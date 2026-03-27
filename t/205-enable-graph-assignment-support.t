#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::HDL::FlattenedDT;
use FSM::Pipeline::SourceFrontend;

subtest 'enable-graph assignment support rebuilds assignment analysis, classification, and emitted assignment blocks from a prepared backend context' => sub {
    my $fsm_module = parse_fsm_module(
        'enable_graph_assignment_support_contract',
        <<'FSM'
(?fsm:enable_graph_assignment_support_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (A 8)
    (B 8)
    (C 8)
    (D 8)
    (E 1)
    (F 1)
    (I 8)
    (J 8)
    (K 8)
    (L 8)
    (P1 1)
    (P0 1)
  )
  (idle
    (A <- B)
    (C <= D)
    (E = F)
    (I <-= J)
    (K <=+ L)
    (P1 <3 1)
    (P0 <2 0)
  )
)
FSM
    );

    my $prepared_backend = prepare_flattened_backend($fsm_module);
    my $support = $prepared_backend->{enable_graph_assignment_support};

    $prepared_backend->{assignment_analysis} = {};
    $support->build_unified_assignment_analysis($fsm_module);

    ok($prepared_backend->{assignment_analysis}{A}, 'assignment support rebuilds analysis for register-out assignments');
    ok($prepared_backend->{assignment_analysis}{C}, 'assignment support rebuilds analysis for register-in assignments');
    ok($prepared_backend->{assignment_analysis}{E}, 'assignment support rebuilds analysis for combinational assignments');
    ok($prepared_backend->{assignment_analysis}{I}, 'assignment support rebuilds analysis for register-out dual assignments');
    ok($prepared_backend->{assignment_analysis}{K}, 'assignment support rebuilds analysis for register-in dual assignments');
    ok($prepared_backend->{assignment_analysis}{P1}, 'assignment support rebuilds analysis for delayed positive pulses');
    ok($prepared_backend->{assignment_analysis}{P0}, 'assignment support rebuilds analysis for delayed negative pulses');

    is(
        $support->get_signal_assignment_type('A', $prepared_backend->{assignment_analysis}{A}),
        'register_out',
        "assignment support classifies '<-' as register_out",
    );
    is(
        $support->get_signal_assignment_type('C', $prepared_backend->{assignment_analysis}{C}),
        'register_in',
        "assignment support classifies '<=' as register_in",
    );
    is(
        $support->get_signal_assignment_type('E', $prepared_backend->{assignment_analysis}{E}),
        'mux_out',
        "assignment support classifies '=' as mux_out",
    );
    is(
        $support->get_signal_assignment_type('I', $prepared_backend->{assignment_analysis}{I}),
        'register_out_dual',
        "assignment support classifies '<-=' as register_out_dual",
    );
    is(
        $support->get_signal_assignment_type('K', $prepared_backend->{assignment_analysis}{K}),
        'register_in_dual',
        "assignment support classifies '<=+' as register_in_dual",
    );
    is(
        $support->get_signal_assignment_type('P1', $prepared_backend->{assignment_analysis}{P1}),
        'pulse_delayed',
        "assignment support classifies '<N' as pulse_delayed",
    );

    is(
        $support->get_pulse_delay_cycles_for_lhs('P1', $prepared_backend->{assignment_analysis}{P1}),
        3,
        'assignment support keeps the delayed positive pulse cycle count',
    );
    is(
        $support->get_pulse_active_level_for_lhs('P1', $prepared_backend->{assignment_analysis}{P1}),
        1,
        'assignment support keeps the delayed positive pulse active level',
    );
    is(
        $support->get_pulse_delay_cycles_for_lhs('P0', $prepared_backend->{assignment_analysis}{P0}),
        2,
        'assignment support keeps the delayed negative pulse cycle count',
    );
    is(
        $support->get_pulse_active_level_for_lhs('P0', $prepared_backend->{assignment_analysis}{P0}),
        0,
        'assignment support keeps the delayed negative pulse active level',
    );
    is(
        $support->normalize_rhs_logic_level("1'b1"),
        1,
        'assignment support normalizes positive scalar logic levels',
    );
    is(
        $support->normalize_rhs_logic_level("1'b0"),
        0,
        'assignment support normalizes negative scalar logic levels',
    );

    my %driven_signals = $support->get_driven_signals();
    ok($driven_signals{A}, 'assignment support keeps the primary driven register-out signal');
    ok($driven_signals{next_I}, 'assignment support exposes next_* auxiliary outputs for <-=');
    ok($driven_signals{K_r}, 'assignment support exposes *_r auxiliary outputs for <=+');
    ok($driven_signals{P1}, 'assignment support keeps delayed pulse targets in the driven signal set');

    my $hdl_block = $support->generate_signal_assignments($fsm_module);

    like($hdl_block, qr/\bnext_I\s*=\s*I_next;/s, "assignment support emits next_I exposure for '<-='");
    like($hdl_block, qr/\bK_r\s*=\s*K_q;/s, "assignment support emits K_r exposure for '<=+'");
    like($hdl_block, qr/\bP1_pulse_delay_pipe\b/s, 'assignment support emits delayed positive pulse pipeline logic');
    like($hdl_block, qr/\bif\s*\(\s*P1_pulse_delay_pipe\[2\]\s*\)\s*begin\s*\n\s*P1\s*<=\s*1'b1;/s, 'assignment support emits delayed positive pulse output at Q+3');
    like($hdl_block, qr/\bif\s*\(\s*P0_pulse_delay_pipe\[1\]\s*\)\s*begin\s*\n\s*P0\s*<=\s*1'b0;/s, 'assignment support emits delayed negative pulse output at Q+2');
};

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
    $hdl_generator->{enable_graph}->set_fsm_module_reference($fsm_module);
    $hdl_generator->{orchestrator}->flatten_all_decision_trees($fsm_module);
    $hdl_generator->{enable_graph_enable_support}->generate_enable_conditions($fsm_module);
    return $hdl_generator;
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

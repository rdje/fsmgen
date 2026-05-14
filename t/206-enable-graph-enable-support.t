#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Scalar::Util qw(blessed);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::AST::Node;
use FSM::HDL::FlattenedDT;
use FSM::Pipeline::SourceFrontend;

subtest 'enable-graph enable support rebuilds top-level enable initialization, WEN/EN emission, and prescan tracking from a prepared backend context' => sub {
    my $fsm_module = parse_fsm_module(
        'enable_graph_enable_support_contract',
        <<'FSM'
(?fsm:enable_graph_enable_support_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (A 1)
    (EXTRA 1)
    (OUT1 1)
    (WATCH 1)
  )
  (idle <EXTRA
    (<A
      (OUT1 <= 1)
    )
  )
  (-watch <A
    (WATCH = 1)
  )
)
FSM
    );

    my $prepared_backend = prepare_flattened_backend($fsm_module);
    my $support = $prepared_backend->{enable_graph_enable_support};

    $support->initialize_state_and_dt_enable_conditions($fsm_module);

    ok(
        blessed($prepared_backend->{state_enables}{idle}),
        'enable support keeps regular-state enable conditions as AST nodes',
    );
    is(
        $prepared_backend->{state_enables}{idle}->to_systemverilog,
        '(current_state == IDLE || EXTRA != 0)',
        'enable support keeps the guarded regular-state enable AST contract',
    );
    ok(
        blessed($prepared_backend->{dt_enables}{'-watch'}),
        'enable support keeps standalone-DT enable conditions as AST nodes',
    );
    is(
        $prepared_backend->{dt_enables}{'-watch'}->to_systemverilog,
        'A != 0',
        'enable support keeps the guarded standalone-DT enable AST contract',
    );

    my $top_enable_block = $support->generate_enable_conditions($fsm_module);
    like($top_enable_block, qr/\bassign idle_en = \(current_state == IDLE \|\| EXTRA != 0\);/, 'enable support emits the guarded top-level state enable assignment');
    like($top_enable_block, qr/\bassign watch_en = A != 0;/, 'enable support emits the guarded standalone-DT top-level enable assignment');

    my $dt_block = $support->generate_dt_enables_from_analysis();
    like($dt_block, qr/\bassign idle_out1_1_en = idle_en & A;\s+\/\/ OUT1 <- 1\b/, 'enable support emits DT-specific enable wiring for regular-state assignments');
    like($dt_block, qr/\bassign watch_watch_1_en = watch_en & 1'b1;\s+\/\/ WATCH <- 1\b/, 'enable support emits DT-specific enable wiring for standalone-DT assignments');

    my $lhs_block = $support->generate_lhs_enables_from_analysis();
    like($lhs_block, qr/\bassign out1_1_en = idle_out1_1_en;/, 'enable support emits grouped LHS-level enables for regular-state assignments');
    like($lhs_block, qr/\bassign watch_1_en = watch_watch_1_en;/, 'enable support emits grouped LHS-level enables for standalone-DT assignments');

    $prepared_backend->{referenced_intermediate_signals} = {};
    $prepared_backend->{intermediate_signals}{mid_and_aux_legacy} = {
        name => 'mid_and_aux_legacy',
        source => 'legacy_string_registry',
    };
    $prepared_backend->{assignment_analysis}{OUT1}{rhs_groups}{1}{lhs_level_enable}{ast}
        = FSM::AST::SignalRef->new('mid_and_aux_legacy');

    $support->prescan_wen_en_for_intermediate_signals();
    ok(
        exists $prepared_backend->{referenced_intermediate_signals}{mid_and_aux_legacy},
        'enable support prescan records intermediate signals referenced by WEN/EN ASTs',
    );
    ok(
        $prepared_backend->{referenced_intermediate_signals}{mid_and_aux_legacy}{needs_declaration},
        'enable support prescan marks referenced WEN/EN intermediates as needing declaration',
    );

    my $wen_en_block = $support->generate_unified_wen_en_signals($fsm_module);
    like($wen_en_block, qr{// DT-Specific Enable Signals from Unified Analysis}, 'enable support keeps the unified DT-specific WEN/EN header');
    like($wen_en_block, qr{// LHS-Level Enable Signals from Unified Analysis}, 'enable support keeps the unified LHS-level WEN/EN header');
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
    $hdl_generator->{enable_graph_signal_support}->set_fsm_module_reference($fsm_module);
    $hdl_generator->{orchestrator}->flatten_all_decision_trees($fsm_module);
    return $hdl_generator;
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::HDL::FlattenedDT;
use FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationPrescanPreparationSupport;
use FSM::Pipeline::SourceFrontend;

subtest 'generation prescan preparation support owns the live logical-count and prescan sequence' => sub {
    my $fsm_module = parse_fsm_module(
        'sv_generation_prescan_preparation_support_contract',
        <<'FSM'
(?fsm:sv_generation_prescan_preparation_support_contract
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

    my $expected_backend = prepare_flattened_backend($fsm_module);
    my $actual_backend = prepare_flattened_backend($fsm_module);
    my $prescan_preparation_support = FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationPrescanPreparationSupport->new(
        flattened_dt => $actual_backend,
    );

    build_expected_prescan_preparation($expected_backend);
    $prescan_preparation_support->prepare_enable_prescan();
    $prescan_preparation_support->prepare_enable_prescan();

    is_deeply(
        $actual_backend->{binary_logical_op_counts},
        $expected_backend->{binary_logical_op_counts},
        'generation prescan preparation support preserves the same logical-operation counting state',
    );

    is_deeply(
        [sort keys %{$actual_backend->{intermediate_signals} || {}}],
        [sort keys %{$expected_backend->{intermediate_signals} || {}}],
        'generation prescan preparation support preserves the same intermediate-signal registry keys after prescan',
    );

    is_deeply(
        [sort keys %{$actual_backend->{referenced_intermediate_signals} || {}}],
        [sort keys %{$expected_backend->{referenced_intermediate_signals} || {}}],
        'generation prescan preparation support preserves the same referenced intermediate-signal keys after prescan',
    );
    ok(
        $actual_backend->{backend_sv_enable_prescan_prepared},
        'generation prescan preparation support records the per-run idempotence guard',
    );
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
    $hdl_generator->{enable_graph_enable_support}->generate_enable_conditions($fsm_module);
    return $hdl_generator;
}

sub build_expected_prescan_preparation {
    my ($prepared_backend) = @_;

    $prepared_backend->{enable_graph_factorization_policy_support}->count_binary_logical_operation_occurrences();
    $prepared_backend->{enable_graph_enable_support}->prescan_wen_en_for_intermediate_signals();
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

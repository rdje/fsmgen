#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::HDL::FlattenedDT;
use FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationPreludeSupport;
use FSM::Pipeline::SourceFrontend;

subtest 'generation prelude support remains a compatibility shell over the extracted live pre-stage owners' => sub {
    my $fsm_module = parse_fsm_module(
        'sv_generation_prelude_support_contract',
        <<'FSM'
(?fsm:sv_generation_prelude_support_contract
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
    my $prelude_support = FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationPreludeSupport->new(
        flattened_dt => $actual_backend,
    );

    my $expected_prefix = build_expected_prelude($expected_backend, $fsm_module);
    my $generated_prefix = $prelude_support->generate_systemverilog_prelude($fsm_module);

    is(
        $generated_prefix,
        $expected_prefix,
        'generation prelude support compatibility shell rebuilds the same pre-stage HDL prefix as the extracted live owners',
    );

    is_deeply(
        $actual_backend->{binary_logical_op_counts},
        $expected_backend->{binary_logical_op_counts},
        'generation prelude support preserves the same logical-operation counting state',
    );

    is_deeply(
        [sort keys %{$actual_backend->{intermediate_signals} || {}}],
        [sort keys %{$expected_backend->{intermediate_signals} || {}}],
        'generation prelude support preserves the same intermediate-signal registry keys after prescan',
    );

    is_deeply(
        [sort keys %{$actual_backend->{referenced_intermediate_signals} || {}}],
        [sort keys %{$expected_backend->{referenced_intermediate_signals} || {}}],
        'generation prelude support preserves the same referenced intermediate-signal keys after prescan',
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
    return $hdl_generator;
}

sub build_expected_prelude {
    my ($prepared_backend, $fsm_module) = @_;

    my $hdl = $prepared_backend->{backend_sv_generation_structural_prelude_support}
        ->generate_structural_prelude($fsm_module);
    $hdl .= $prepared_backend->{backend_sv_generation_enable_preparation_support}
        ->generate_enable_preparation($fsm_module);

    return $hdl;
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::HDL::FlattenedDT;
use FSM::HDL::FlattenedDT::Backend::SystemVerilog::GlobalFactorizationSupport;
use FSM::Pipeline::SourceFrontend;

subtest 'global factorization support rebuilds the direct first-pass factorization contract from a prepared backend context' => sub {
    my $fsm_module = parse_fsm_module(
        'sv_global_factorization_contract',
        <<'FSM'
(?fsm:sv_global_factorization_contract
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
    my $support = FSM::HDL::FlattenedDT::Backend::SystemVerilog::GlobalFactorizationSupport->new(
        flattened_dt => $prepared_backend,
    );

    my $intermediate_signals = $support->run_global_ast_factorization();
    my $signal_info = $intermediate_signals->{A_or_B};

    ok($signal_info, 'global factorization support keeps the shared A_or_B intermediate signal');
    is($signal_info->{usage_count}, 2, 'global factorization support keeps the shared-expression usage count');
    ok($prepared_backend->{ast_factorizer}, 'global factorization support stores the factorizer on the backend context for downstream owners');
    is(
        $prepared_backend->{enable_graph_ast_support}->ast_to_systemverilog($prepared_backend->{ast_factorizer}{intermediate_signals}{A_or_B}{ast}),
        'A | B',
        'global factorization support persists the substituted AST form for downstream lookup',
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
    $hdl_generator->{enable_graph_factorization_policy_support}->count_binary_logical_operation_occurrences();
    return $hdl_generator;
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

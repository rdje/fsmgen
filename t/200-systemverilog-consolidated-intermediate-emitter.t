#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::HDL::FlattenedDT;
use FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateEmitter;
use FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateRenderingSupport;
use FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateStagePreparationSupport;
use FSM::Pipeline::SourceFrontend;

{
    package Local::SpyRenderingSupport;
    use v5.20;
    use strict;
    use warnings;
    use feature qw(signatures);
    no warnings 'experimental::signatures';

    sub new ($class) {
        return bless { calls => [] }, $class;
    }

    sub calls ($self) {
        return $self->{calls};
    }

    sub render_prepared_consolidated_intermediate_block ($self, $prepared_block) {
        push @{$self->{calls}}, $prepared_block;
        return "rendered:$prepared_block->{name}";
    }
}

subtest 'consolidated intermediate emitter requires only the live rendering owner' => sub {
    my $prepared_block = { name => 'prepared_shell_contract' };
    my $rendering_support = Local::SpyRenderingSupport->new();
    my $consolidated_emitter = FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateEmitter->new(
        flattened_dt => {
            backend_sv_consolidated_intermediate_rendering_support => $rendering_support,
        },
    );

    my $consolidated_block = $consolidated_emitter->render_consolidated_intermediate_block($prepared_block);

    is(
        $consolidated_block,
        'rendered:prepared_shell_contract',
        'emitter shell delegates directly to the rendering owner',
    );
    is(
        scalar(@{$rendering_support->calls}),
        1,
        'emitter shell calls the rendering owner exactly once',
    );
    is(
        $rendering_support->calls->[0],
        $prepared_block,
        'emitter shell passes the prepared block through unchanged',
    );
};

subtest 'consolidated intermediate emitter survives as a compatibility shell over the live rendering owner' => sub {
    my $fsm_module = parse_fsm_module(
        'sv_consolidated_contract',
        <<'FSM'
(?fsm:sv_consolidated_contract
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
    my $stage_preparation_support = FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateStagePreparationSupport->new(
        flattened_dt => $prepared_backend,
    );
    my $rendering_support = FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateRenderingSupport->new(
        flattened_dt => $prepared_backend,
    );
    my $consolidated_emitter = FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateEmitter->new(
        flattened_dt => $prepared_backend,
    );

    my $prepared_block = $stage_preparation_support->prepare_consolidated_intermediate_block($fsm_module);
    my $expected_block = $rendering_support->render_prepared_consolidated_intermediate_block($prepared_block);
    my $consolidated_block = $consolidated_emitter->render_consolidated_intermediate_block($prepared_block);

    is(
        $consolidated_block,
        $expected_block,
        'consolidated intermediate emitter rebuilds the same block as the live rendering owner',
    );
    is(
        scalar(grep { $_ eq 'A_or_B' } @{ $prepared_block->{sorted_signals} }),
        1,
        'prepared block keeps the shared factorized carrier in the dependency-safe render order',
    );
    like(
        $consolidated_block,
        qr{// Consolidated intermediate signals \(AST factorization \+ pre-scan\)},
        'consolidated block keeps the consolidated intermediate comment header',
    );
    like(
        $consolidated_block,
        qr/\bwire A_or_B;/,
        'consolidated block keeps the shared factorized wire declaration',
    );
    like(
        $consolidated_block,
        qr/\bassign A_or_B = A \| B; \/\/ Source: ast_factorization\b/,
        'consolidated block keeps the shared factorized assign',
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
    $hdl_generator->{enable_graph_enable_support}->prescan_wen_en_for_intermediate_signals();
    return $hdl_generator;
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

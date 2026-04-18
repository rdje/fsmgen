#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::AST::Node;
use FSM::HDL::FlattenedDT;
use FSM::Pipeline::SourceFrontend;

subtest 'operand-contract validation support catches undeclared and declared-but-unassigned internal operands before emission' => sub {
    my $fsm_module = parse_fsm_module(
        'sv_operand_contract_validation_support_contract',
        <<'FSM'
(?fsm:sv_operand_contract_validation_support_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (A 1)
    (B 1)
    (OUT1 1)
    (OUT2 1)
  )
  (idle
    (<(| A B)
      (OUT1 <= 1)
    )
    (<(| A B)
      (OUT2 <= 0)
    )
  )
)
FSM
    );

    my $prepared_backend = prepare_flattened_backend($fsm_module);
    $prepared_backend->{backend_sv_generation_prescan_preparation_support}
        ->prepare_enable_prescan();
    my $prepared_block = $prepared_backend->{backend_sv_consolidated_intermediate_stage_preparation_support}
        ->prepare_consolidated_intermediate_block($fsm_module);

    $prepared_backend->{state_enables}{idle} = FSM::AST::SignalRef->new('ghost_internal');

    my $error = capture_error(sub {
        $prepared_backend->{backend_sv_operand_contract_validation_support}
            ->validate_pre_generation_operand_contract($fsm_module, $prepared_block);
    });
    like(
        $error,
        qr/undeclared internal operand 'ghost_internal'/,
        'validator rejects undeclared internal operands referenced by generation ASTs',
    );

    $prepared_backend->{state_enables}{idle} = FSM::AST::SignalRef->new('A');

    $prepared_block->{all_intermediate_signals}{ghost_helper} = {
        source => 'ast_factorization',
    };
    $prepared_block->{filtered_signals}{A_or_B}{runtime_ast} = FSM::AST::BinaryOp->new(
        '&',
        FSM::AST::SignalRef->new('A'),
        FSM::AST::SignalRef->new('ghost_helper'),
    );

    $error = capture_error(sub {
        $prepared_backend->{backend_sv_operand_contract_validation_support}
            ->validate_pre_generation_operand_contract($fsm_module, $prepared_block);
    });
    like(
        $error,
        qr/internal operand 'ghost_helper' that is declared but not backed by any internal assignment/,
        'validator rejects declared-but-unassigned internal operands referenced by prepared consolidated intermediates',
    );

    delete $prepared_block->{filtered_signals}{A_or_B};
    $prepared_backend->{lhs_assignments}{OUT1}[0]{rhs} = '!(ghost_helper)';
    $prepared_block->{all_intermediate_signals}{ghost_helper} = {
        source => 'fsmgen_parsing',
    };

    $error = capture_error(sub {
        $prepared_backend->{backend_sv_operand_contract_validation_support}
            ->validate_pre_generation_operand_contract($fsm_module, $prepared_block);
    });
    like(
        $error,
        qr/assignment RHS for 'OUT1' references internal operand 'ghost_helper' that is declared but not backed by any internal assignment/,
        'validator rejects declared-but-unassigned internal operands referenced only from assignment RHS expressions',
    );
};

subtest 'post-flattening assembly support runs operand-contract validation before final HDL emission' => sub {
    my $fsm_module = parse_fsm_module(
        'sv_operand_contract_validation_pipeline_contract',
        <<'FSM'
(?fsm:sv_operand_contract_validation_pipeline_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (A 1)
    (OUT1 1)
  )
  (idle
    (<A
      (OUT1 <= 1)
    )
  )
)
FSM
    );

    my $prepared_backend = prepare_flattened_backend($fsm_module);
    my $assembly_support = $prepared_backend->{backend_sv_post_flattening_assembly_support};

    $prepared_backend->{state_enables}{idle} = FSM::AST::SignalRef->new('ghost_internal');

    my $error = capture_error(sub {
        $assembly_support->generate_systemverilog_module($fsm_module);
    });

    like(
        $error,
        qr/Pre-generation operand contract validation failed/,
        'post-flattening assembly owner fails before emission when operand validation breaks',
    );
    like(
        $error,
        qr/ghost_internal/,
        'post-flattening assembly validation failure keeps the offending operand name in the diagnostic',
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

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

sub capture_error {
    my ($code) = @_;
    my $ok = eval {
        $code->();
        1;
    };
    return $ok ? '' : ($@ || 'unknown error');
}

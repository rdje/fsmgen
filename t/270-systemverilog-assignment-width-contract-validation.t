#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::HDL::FlattenedDT;
use FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationPipelineSupport;
use FSM::Pipeline::SourceFrontend;

subtest 'operand-contract validation rejects implicit assignment width adaptation before emission' => sub {
    my $expand_fsm_module = parse_fsm_module(
        'sv_assignment_width_expand_contract',
        <<'FSM'
(?fsm:sv_assignment_width_expand_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (A 1)
    (BUS 3)
  )
  (idle
    (<A
      (BUS = A)
    )
  )
)
FSM
    );

    my $expand_backend = prepare_flattened_backend($expand_fsm_module);
    $expand_backend->{backend_sv_generation_prescan_preparation_support}
        ->prepare_enable_prescan();
    my $expand_block = $expand_backend->{backend_sv_consolidated_intermediate_stage_preparation_support}
        ->prepare_consolidated_intermediate_block($expand_fsm_module);

    my $expand_error = capture_error(sub {
        $expand_backend->{backend_sv_operand_contract_validation_support}
            ->validate_pre_generation_operand_contract($expand_fsm_module, $expand_block);
    });

    like(
        $expand_error,
        qr/assignment to 'BUS' uses RHS 'A' with incompatible width 1 for LHS width 3; .*implicit widening/s,
        'validator rejects implicit widening from a 1-bit RHS into a 3-bit LHS',
    );

    my $truncate_fsm_module = parse_fsm_module(
        'sv_assignment_width_truncate_contract',
        <<'FSM'
(?fsm:sv_assignment_width_truncate_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (BUS 3)
    (FLAG 1)
  )
  (idle
    (<FLAG
      (FLAG = BUS)
    )
  )
)
FSM
    );

    my $truncate_backend = prepare_flattened_backend($truncate_fsm_module);
    $truncate_backend->{backend_sv_generation_prescan_preparation_support}
        ->prepare_enable_prescan();
    my $truncate_block = $truncate_backend->{backend_sv_consolidated_intermediate_stage_preparation_support}
        ->prepare_consolidated_intermediate_block($truncate_fsm_module);

    my $truncate_error = capture_error(sub {
        $truncate_backend->{backend_sv_operand_contract_validation_support}
            ->validate_pre_generation_operand_contract($truncate_fsm_module, $truncate_block);
    });

    like(
        $truncate_error,
        qr/assignment to 'FLAG' uses RHS 'BUS' with incompatible width 3 for LHS width 1; .*implicit truncation/s,
        'validator rejects implicit truncation from a 3-bit RHS into a 1-bit LHS',
    );
};

subtest 'operand-contract validation rejects width-equal whole aggregate RHS values against incompatible typed aggregate LHS contracts' => sub {
    my $fsm_module = parse_fsm_module(
        'sv_assignment_aggregate_contract',
        <<'FSM'
(?fsm:sv_assignment_aggregate_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+constants
    (FRAME ((mode 2'b10) (flag 1)))
  )
  (+types
    (type wrong_t (list bit (bits 2)))
  )
  (+size
    (OUT wrong_t)
  )
  (idle
    (OUT = FRAME)
  )
)
FSM
    );

    my $backend = prepare_flattened_backend($fsm_module);
    $backend->{backend_sv_generation_prescan_preparation_support}
        ->prepare_enable_prescan();
    my $prepared_block = $backend->{backend_sv_consolidated_intermediate_stage_preparation_support}
        ->prepare_consolidated_intermediate_block($fsm_module);

    my $error = capture_error(sub {
        $backend->{backend_sv_operand_contract_validation_support}
            ->validate_pre_generation_operand_contract($fsm_module, $prepared_block);
    });

    like(
        $error,
        qr/assignment to 'OUT' uses whole aggregate RHS 'FRAME' with contract 'record\{mode:bits\[2\], flag:bit\}' that does not match declared type 'list<bit, bits\[2\]>'/s,
        'validator rejects width-equal whole aggregate RHS values when the typed LHS keeps an incompatible aggregate contract',
    );
};

subtest 'generation pipeline support runs width-contract validation before final HDL emission' => sub {
    my $fsm_module = parse_fsm_module(
        'sv_assignment_width_pipeline_contract',
        <<'FSM'
(?fsm:sv_assignment_width_pipeline_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (A 1)
    (BUS 3)
  )
  (idle
    (<A
      (BUS = A)
    )
  )
)
FSM
    );

    my $prepared_backend = prepare_flattened_backend($fsm_module);
    my $pipeline_support = FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationPipelineSupport->new(
        flattened_dt => $prepared_backend,
    );

    my $error = capture_error(sub {
        $pipeline_support->generate_systemverilog_module($fsm_module);
    });

    like(
        $error,
        qr/Pre-generation operand contract validation failed/,
        'generation pipeline compatibility shell fails before emission when assignment width validation breaks',
    );
    like(
        $error,
        qr/assignment to 'BUS' uses RHS 'A' with incompatible width 1 for LHS width 3/s,
        'generation pipeline validation keeps assignment width context in the diagnostic',
    );

    my $typed_fsm_module = parse_fsm_module(
        'sv_assignment_aggregate_pipeline_contract',
        <<'FSM'
(?fsm:sv_assignment_aggregate_pipeline_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+constants
    (FRAME ((mode 2'b10) (flag 1)))
  )
  (+types
    (type wrong_t (list bit (bits 2)))
  )
  (+size
    (OUT wrong_t)
  )
  (idle
    (OUT = FRAME)
  )
)
FSM
    );

    my $typed_backend = prepare_flattened_backend($typed_fsm_module);
    my $typed_pipeline_support = FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationPipelineSupport->new(
        flattened_dt => $typed_backend,
    );

    my $typed_error = capture_error(sub {
        $typed_pipeline_support->generate_systemverilog_module($typed_fsm_module);
    });

    like(
        $typed_error,
        qr/Pre-generation operand contract validation failed/,
        'generation pipeline compatibility shell fails before emission when aggregate contract validation breaks',
    );
    like(
        $typed_error,
        qr/assignment to 'OUT' uses whole aggregate RHS 'FRAME' with contract 'record\{mode:bits\[2\], flag:bit\}' that does not match declared type 'list<bit, bits\[2\]>'/s,
        'generation pipeline validation keeps aggregate contract context in the diagnostic',
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

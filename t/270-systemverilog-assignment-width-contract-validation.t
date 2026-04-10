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

subtest 'operand-contract validation rejects direct RHS concat width mismatches before emission' => sub {
    my $fsm_module = parse_fsm_module(
        'sv_assignment_direct_concat_width_contract',
        <<'FSM'
(?fsm:sv_assignment_direct_concat_width_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (BUS 8)
    (HI 3)
    (LO 4)
  )
  (idle
    (BUS = (concat HI LO))
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
        qr/assignment to 'BUS' uses RHS '\{HI, LO\}' with incompatible width 7 for LHS width 8; .*implicit widening/s,
        'validator rejects direct RHS concat implicit widening before emission',
    );

    my $pipeline_backend = prepare_flattened_backend($fsm_module);
    my $pipeline_support = FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationPipelineSupport->new(
        flattened_dt => $pipeline_backend,
    );
    my $pipeline_error = capture_error(sub {
        $pipeline_support->generate_systemverilog_module($fsm_module);
    });

    like(
        $pipeline_error,
        qr/assignment to 'BUS' uses RHS '\{HI, LO\}' with incompatible width 7 for LHS width 8/s,
        'generation pipeline surfaces the direct RHS concat width mismatch',
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

subtest 'operand-contract validation preserves typed aggregate RHS signal contracts' => sub {
    my $compatible_fsm_module = parse_fsm_module(
        'sv_assignment_typed_signal_aggregate_contract',
        <<'FSM'
(?fsm:sv_assignment_typed_signal_aggregate_contract
  (+system
    (clock clk)
    (sreset rst)
  )
  (+types
    (type payload_t (list bit (bits 2)))
    (type frame_t (record (tag (bits 4)) (payload payload_t)))
  )
  (+size
    (IN_FRAME frame_t)
    (OUT frame_t)
  )
  (idle
    (OUT = IN_FRAME)
  )
)
FSM
    );

    my $compatible_backend = prepare_flattened_backend($compatible_fsm_module);
    $compatible_backend->{backend_sv_generation_prescan_preparation_support}
        ->prepare_enable_prescan();
    my $compatible_block = $compatible_backend->{backend_sv_consolidated_intermediate_stage_preparation_support}
        ->prepare_consolidated_intermediate_block($compatible_fsm_module);

    my $compatible_error = capture_error(sub {
        $compatible_backend->{backend_sv_operand_contract_validation_support}
            ->validate_pre_generation_operand_contract($compatible_fsm_module, $compatible_block);
    });

    is(
        $compatible_error,
        '',
        'validator accepts compatible typed aggregate RHS signal contracts',
    );

    my $incompatible_fsm_module = parse_fsm_module(
        'sv_assignment_bad_typed_signal_aggregate_contract',
        <<'FSM'
(?fsm:sv_assignment_bad_typed_signal_aggregate_contract
  (+system
    (clock clk)
    (sreset rst)
  )
  (+types
    (type wrong_t (list bit (bits 2)))
    (type bad_record_t (record (mode (bits 2)) (flag bit)))
  )
  (+size
    (BAD_VALUE bad_record_t)
    (OUT wrong_t)
  )
  (idle
    (OUT = BAD_VALUE)
  )
)
FSM
    );

    my $incompatible_backend = prepare_flattened_backend($incompatible_fsm_module);
    $incompatible_backend->{backend_sv_generation_prescan_preparation_support}
        ->prepare_enable_prescan();
    my $incompatible_block = $incompatible_backend->{backend_sv_consolidated_intermediate_stage_preparation_support}
        ->prepare_consolidated_intermediate_block($incompatible_fsm_module);

    my $incompatible_error = capture_error(sub {
        $incompatible_backend->{backend_sv_operand_contract_validation_support}
            ->validate_pre_generation_operand_contract($incompatible_fsm_module, $incompatible_block);
    });

    like(
        $incompatible_error,
        qr/assignment to 'OUT' uses whole aggregate RHS 'BAD_VALUE' with contract 'record\{mode:bits\[2\], flag:bit\}' that does not match declared type 'list<bit, bits\[2\]>'/s,
        'validator rejects width-equal typed aggregate RHS signals when the typed LHS keeps an incompatible aggregate contract',
    );
};

subtest 'operand-contract validation infers direct RHS concat aggregate contracts for typed targets' => sub {
    my $compatible_list_fsm_module = parse_fsm_module(
        'sv_assignment_concat_list_contract',
        <<'FSM'
(?fsm:sv_assignment_concat_list_contract
  (+system
    (clock clk)
    (sreset rst)
  )
  (+types
    (type payload_t (list bit (bits 2)))
  )
  (+size
    (FLAG 1)
    (DATA 2)
    (OUT payload_t)
  )
  (idle
    (OUT = (concat FLAG DATA))
  )
)
FSM
    );

    my $compatible_list_backend = prepare_flattened_backend($compatible_list_fsm_module);
    $compatible_list_backend->{backend_sv_generation_prescan_preparation_support}
        ->prepare_enable_prescan();
    my $compatible_list_block = $compatible_list_backend->{backend_sv_consolidated_intermediate_stage_preparation_support}
        ->prepare_consolidated_intermediate_block($compatible_list_fsm_module);

    my $compatible_list_error = capture_error(sub {
        $compatible_list_backend->{backend_sv_operand_contract_validation_support}
            ->validate_pre_generation_operand_contract($compatible_list_fsm_module, $compatible_list_block);
    });

    is(
        $compatible_list_error,
        '',
        'validator accepts direct RHS concat whose inferred list shape matches the typed list target',
    );

    my $bad_list_fsm_module = parse_fsm_module(
        'sv_assignment_bad_concat_list_contract',
        <<'FSM'
(?fsm:sv_assignment_bad_concat_list_contract
  (+system
    (clock clk)
    (sreset rst)
  )
  (+types
    (type payload_t (list bit (bits 2)))
  )
  (+size
    (FLAG 1)
    (DATA 2)
    (OUT payload_t)
  )
  (idle
    (OUT = (concat DATA FLAG))
  )
)
FSM
    );

    my $bad_list_backend = prepare_flattened_backend($bad_list_fsm_module);
    $bad_list_backend->{backend_sv_generation_prescan_preparation_support}
        ->prepare_enable_prescan();
    my $bad_list_block = $bad_list_backend->{backend_sv_consolidated_intermediate_stage_preparation_support}
        ->prepare_consolidated_intermediate_block($bad_list_fsm_module);

    my $bad_list_error = capture_error(sub {
        $bad_list_backend->{backend_sv_operand_contract_validation_support}
            ->validate_pre_generation_operand_contract($bad_list_fsm_module, $bad_list_block);
    });

    like(
        $bad_list_error,
        qr/assignment to 'OUT' uses whole aggregate RHS '\{DATA, FLAG\}' with contract 'list<bits\[2\], bit>' that does not match declared type 'list<bit, bits\[2\]>'/s,
        'validator rejects width-equal direct RHS concat when inferred list item order does not match the typed list target',
    );

    my $compatible_nested_list_fsm_module = parse_fsm_module(
        'sv_assignment_nested_concat_list_contract',
        <<'FSM'
(?fsm:sv_assignment_nested_concat_list_contract
  (+system
    (clock clk)
    (sreset rst)
  )
  (+types
    (type payload_t (list bit (bits 2)))
    (type frame_t (list payload_t (bits 4)))
  )
  (+size
    (FLAG 1)
    (DATA 2)
    (TAG 4)
    (OUT frame_t)
  )
  (idle
    (OUT = (concat (concat FLAG DATA) TAG))
  )
)
FSM
    );

    my $compatible_nested_list_backend = prepare_flattened_backend($compatible_nested_list_fsm_module);
    $compatible_nested_list_backend->{backend_sv_generation_prescan_preparation_support}
        ->prepare_enable_prescan();
    my $compatible_nested_list_block = $compatible_nested_list_backend->{backend_sv_consolidated_intermediate_stage_preparation_support}
        ->prepare_consolidated_intermediate_block($compatible_nested_list_fsm_module);

    my $compatible_nested_list_error = capture_error(sub {
        $compatible_nested_list_backend->{backend_sv_operand_contract_validation_support}
            ->validate_pre_generation_operand_contract($compatible_nested_list_fsm_module, $compatible_nested_list_block);
    });

    is(
        $compatible_nested_list_error,
        '',
        'validator accepts nested direct RHS concat whose nested list shape matches the typed list target',
    );

    my $bad_nested_list_fsm_module = parse_fsm_module(
        'sv_assignment_bad_nested_concat_list_contract',
        <<'FSM'
(?fsm:sv_assignment_bad_nested_concat_list_contract
  (+system
    (clock clk)
    (sreset rst)
  )
  (+types
    (type payload_t (list bit (bits 2)))
    (type frame_t (list payload_t (bits 4)))
  )
  (+size
    (FLAG 1)
    (DATA 2)
    (TAG 4)
    (OUT frame_t)
  )
  (idle
    (OUT = (concat (concat DATA FLAG) TAG))
  )
)
FSM
    );

    my $bad_nested_list_backend = prepare_flattened_backend($bad_nested_list_fsm_module);
    $bad_nested_list_backend->{backend_sv_generation_prescan_preparation_support}
        ->prepare_enable_prescan();
    my $bad_nested_list_block = $bad_nested_list_backend->{backend_sv_consolidated_intermediate_stage_preparation_support}
        ->prepare_consolidated_intermediate_block($bad_nested_list_fsm_module);

    my $bad_nested_list_error = capture_error(sub {
        $bad_nested_list_backend->{backend_sv_operand_contract_validation_support}
            ->validate_pre_generation_operand_contract($bad_nested_list_fsm_module, $bad_nested_list_block);
    });

    like(
        $bad_nested_list_error,
        qr/assignment to 'OUT' uses whole aggregate RHS '\{\{DATA, FLAG\}, TAG\}' with contract 'list<list<bits\[2\], bit>, bits\[4\]>' that does not match declared type 'list<list<bit, bits\[2\]>, bits\[4\]>'/s,
        'validator rejects width-equal nested direct RHS concat when inferred nested list item order does not match the typed list target',
    );

    my $compatible_record_fsm_module = parse_fsm_module(
        'sv_assignment_concat_record_contract',
        <<'FSM'
(?fsm:sv_assignment_concat_record_contract
  (+system
    (clock clk)
    (sreset rst)
  )
  (+types
    (type payload_t (list bit (bits 2)))
    (type frame_t (record (tag (bits 4)) (payload payload_t)))
  )
  (+size
    (TAG 4)
    (PAYLOAD payload_t)
    (OUT frame_t)
  )
  (idle
    (OUT = (concat TAG PAYLOAD))
  )
)
FSM
    );

    my $compatible_record_backend = prepare_flattened_backend($compatible_record_fsm_module);
    $compatible_record_backend->{backend_sv_generation_prescan_preparation_support}
        ->prepare_enable_prescan();
    my $compatible_record_block = $compatible_record_backend->{backend_sv_consolidated_intermediate_stage_preparation_support}
        ->prepare_consolidated_intermediate_block($compatible_record_fsm_module);

    my $compatible_record_error = capture_error(sub {
        $compatible_record_backend->{backend_sv_operand_contract_validation_support}
            ->validate_pre_generation_operand_contract($compatible_record_fsm_module, $compatible_record_block);
    });

    is(
        $compatible_record_error,
        '',
        'validator accepts direct RHS concat whose inferred record member order matches the typed record target',
    );

    my $bad_record_fsm_module = parse_fsm_module(
        'sv_assignment_bad_concat_record_contract',
        <<'FSM'
(?fsm:sv_assignment_bad_concat_record_contract
  (+system
    (clock clk)
    (sreset rst)
  )
  (+types
    (type payload_t (list bit (bits 2)))
    (type bad_payload_t (record (mode (bits 2)) (flag bit)))
    (type frame_t (record (tag (bits 4)) (payload payload_t)))
  )
  (+size
    (TAG 4)
    (BAD_PAYLOAD bad_payload_t)
    (OUT frame_t)
  )
  (idle
    (OUT = (concat TAG BAD_PAYLOAD))
  )
)
FSM
    );

    my $bad_record_backend = prepare_flattened_backend($bad_record_fsm_module);
    $bad_record_backend->{backend_sv_generation_prescan_preparation_support}
        ->prepare_enable_prescan();
    my $bad_record_block = $bad_record_backend->{backend_sv_consolidated_intermediate_stage_preparation_support}
        ->prepare_consolidated_intermediate_block($bad_record_fsm_module);

    my $bad_record_error = capture_error(sub {
        $bad_record_backend->{backend_sv_operand_contract_validation_support}
            ->validate_pre_generation_operand_contract($bad_record_fsm_module, $bad_record_block);
    });

    like(
        $bad_record_error,
        qr/assignment to 'OUT' uses whole aggregate RHS '\{TAG, BAD_PAYLOAD\}' with contract 'record\{tag:bits\[4\], payload:record\{mode:bits\[2\], flag:bit\}\}' that does not match declared type 'record\{tag:bits\[4\], payload:list<bit, bits\[2\]>\}'/s,
        'validator rejects width-equal direct RHS concat when an inferred record member has the wrong aggregate shape',
    );
};

subtest 'operand-contract validation uses aggregate leaf contracts for partial LHS writes' => sub {
    my $compatible_fsm_module = parse_fsm_module(
        'sv_assignment_partial_aggregate_leaf_contract',
        <<'FSM'
(?fsm:sv_assignment_partial_aggregate_leaf_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+constants
    (TAIL (1 const_2b10))
  )
  (+types
    (type tail_t (list bit (bits 2)))
    (type frame_t (record (tag (bits 3)) (payload tail_t)))
  )
  (+size
    (OUT frame_t)
  )
  (idle
    (OUT.payload = TAIL)
  )
)
FSM
    );

    my $compatible_backend = prepare_flattened_backend($compatible_fsm_module);
    $compatible_backend->{backend_sv_generation_prescan_preparation_support}
        ->prepare_enable_prescan();
    my $compatible_block = $compatible_backend->{backend_sv_consolidated_intermediate_stage_preparation_support}
        ->prepare_consolidated_intermediate_block($compatible_fsm_module);

    my $compatible_error = capture_error(sub {
        $compatible_backend->{backend_sv_operand_contract_validation_support}
            ->validate_pre_generation_operand_contract($compatible_fsm_module, $compatible_block);
    });

    is(
        $compatible_error,
        '',
        'validator accepts compatible whole aggregate RHS values assigned to aggregate leaf LHS targets',
    );

    my $incompatible_fsm_module = parse_fsm_module(
        'sv_assignment_bad_partial_aggregate_leaf_contract',
        <<'FSM'
(?fsm:sv_assignment_bad_partial_aggregate_leaf_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+constants
    (BAD ((mode const_2b10) (flag 1)))
  )
  (+types
    (type tail_t (list bit (bits 2)))
    (type frame_t (record (tag (bits 3)) (payload tail_t)))
  )
  (+size
    (OUT frame_t)
  )
  (idle
    (OUT.payload = BAD)
  )
)
FSM
    );

    my $incompatible_backend = prepare_flattened_backend($incompatible_fsm_module);
    $incompatible_backend->{backend_sv_generation_prescan_preparation_support}
        ->prepare_enable_prescan();
    my $incompatible_block = $incompatible_backend->{backend_sv_consolidated_intermediate_stage_preparation_support}
        ->prepare_consolidated_intermediate_block($incompatible_fsm_module);

    my $incompatible_error = capture_error(sub {
        $incompatible_backend->{backend_sv_operand_contract_validation_support}
            ->validate_pre_generation_operand_contract($incompatible_fsm_module, $incompatible_block);
    });

    like(
        $incompatible_error,
        qr/assignment to 'OUT\.payload' uses whole aggregate RHS 'BAD' with contract 'record\{mode:bits\[2\], flag:bit\}' that does not match declared type 'list<bit, bits\[2\]>'/s,
        'validator rejects incompatible whole aggregate RHS values against the aggregate leaf LHS contract instead of the base signal contract',
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

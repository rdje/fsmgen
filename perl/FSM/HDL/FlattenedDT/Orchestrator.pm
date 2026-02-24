package FSM::HDL::FlattenedDT::Orchestrator;

use v5.20;
use strict;
use warnings;
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::Debug;

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[FlattenedDT::Orchestrator.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

sub generate_systemverilog ($self, $fsm_module) {
    my $ctx = $self->{flattened_dt};

    fsm_debug("Starting flattened DT SystemVerilog generation for " . $fsm_module->name, 3);
    fsm_debug("\n*** PIPELINE TIMING DEBUG: HDL Generation Pipeline Start ***", 3);
    
    # Step 0: Store FSM module reference for proper signal and reset value analysis
    $ctx->set_fsm_module_reference($fsm_module);
    fsm_debug("Step 0 - FSM module reference stored", 3);
    
    # Step 1: Analyze and flatten all decision trees
    $ctx->flatten_all_decision_trees($fsm_module);
    fsm_debug("Step 1 - Decision trees flattened", 3);
    
    # Step 2: Generate SystemVerilog with enable-based methodology
    my $hdl = $ctx->generate_header($fsm_module);
    $hdl .= $ctx->generate_module_declaration($fsm_module);
    $hdl .= $ctx->generate_state_encoding($fsm_module);
    $hdl .= $ctx->generate_state_register($fsm_module);
    $hdl .= $ctx->generate_internal_signal_declarations($fsm_module);
    fsm_debug("Step 2 - Basic HDL structure generated", 3);
    
    # Step 3: Generate enable conditions FIRST (this will track intermediate signal requirements)
    $hdl .= $ctx->generate_enable_conditions($fsm_module);
    fsm_debug("Step 3 - Enable conditions generated", 3);
    
    # TIMING FIX: Count logical operations BEFORE any intermediate signal creation!
    fsm_debug("\n*** TIMING FIX: Running logical operation counting BEFORE pre-scan ***", 3);
    $ctx->count_binary_logical_operation_occurrences();
    fsm_debug("Step 4 - Logical operation counting completed (BEFORE pre-scan!)", 3);
    
    # Step 5: PRE-SCAN all WEN/EN expressions to identify needed intermediate signals (now with counts available)
    $ctx->prescan_wen_en_for_intermediate_signals();
    fsm_debug("Step 5 - PRE-SCAN completed (AFTER logical operation counting!)", 3);
    
    # Step 6: Generate consolidated intermediate signals (combining AST factorization + pre-scan)
    $hdl .= $ctx->generate_consolidated_intermediate_signals($fsm_module);
    fsm_debug("Step 6 - Consolidated intermediate signals generated", 3);
    
    # Step 7: Generate WEN/EN signals (using pre-declared intermediate signals)
    $hdl .= $ctx->generate_wen_en_signals($fsm_module);
    fsm_debug("Step 7 - WEN/EN signals generated", 3);
    
    $hdl .= $ctx->generate_signal_assignments($fsm_module);
    $hdl .= "endmodule\n";
    fsm_debug("*** PIPELINE TIMING DEBUG: HDL Generation Pipeline Complete ***\n", 3);
    
    return $hdl;
}

1;

package FSM::HDL::FlattenedDT::Backend::SystemVerilog;

use v5.20;
use strict;
use warnings;
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::Debug;
use Data::Dumper;

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[FlattenedDT::Backend::SystemVerilog.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}
sub generate_header ($self, $fsm_module) {
    my $hdl = "";
    $hdl .= "//=============================================================================\n";
    $hdl .= "// Flattened Decision Tree FSM: " . $fsm_module->name . "\n";
    $hdl .= "// Generated using Enable-based Methodology with WEN/EN Signals\n";
    $hdl .= "// Date: " . localtime() . "\n";
    $hdl .= "// \n";
    $hdl .= "// This implementation uses:\n";
    $hdl .= "// - Flattened decision tree approach\n";
    $hdl .= "// - Enable-based logic with assign statements\n";
    $hdl .= "// - Write Enable (WEN) and Enable (EN) signals for each LHS\n";
    $hdl .= "// - Flat Boolean expressions from DT traversal\n";
    $hdl .= "//=============================================================================\n\n";
    return $hdl;
}

sub generate_module_declaration ($self, $fsm_module) {
    my $ctx = $self->{flattened_dt};
    my $hdl = "module " . $fsm_module->name . " (\n";
    my @base_ports = (
        "  input  wire clk",
        "  input  wire rstn",
    );
    
    # Add all the signal ports based on the parsed FSM
    my $signals = $fsm_module->signals;
    my @inputs = ();
    my @outputs = ();
    
    fsm_debug("HDL Generation: Processing " . scalar(keys %$signals) . " signals for module declaration", 3);
    
    # Track seen signals to avoid duplicates
    my %seen_signals = ('clk' => 1, 'rstn' => 1);  # Base ports
    my %port_directions = ('clk' => 'input', 'rstn' => 'input');
    
    # Check which signals are driven (outputs) vs used (inputs)
    my %driven_signals = $ctx->get_driven_signals();
    
    for my $sig_name (sort keys %$signals) {
        # Skip duplicates
        if ($seen_signals{$sig_name}) {
            fsm_debug("HDL Signal Processing: SKIPPING duplicate signal '$sig_name'", 3);
            next;
        }
        $seen_signals{$sig_name} = 1;
        
        my $signal = $signals->{$sig_name};
        
        # Skip intermediate signals from interface - they should not be ports
        my $is_intermediate = 0;
        if ($signal->can('get_attribute')) {
            my $signal_role = $signal->get_attribute('signal_role');
            $is_intermediate = ($signal_role && $signal_role eq 'INTERNAL_INTERMEDIATE');
        } elsif ($signal->can('attributes') && $signal->attributes) {
            $is_intermediate = $signal->attributes->{is_intermediate} || 0;
        }
        
        if ($is_intermediate) {
            fsm_debug("HDL Signal Processing: SKIPPING intermediate signal '$sig_name' from interface", 3);
            next;
        }
        my $width_str = "";
        
        fsm_debug("HDL Signal Processing: $sig_name", 3);
        fsm_debug("  Signal object type: " . ref($signal), 3);
        fsm_debug("  Signal dump: " . Dumper($signal), 3);
        
        my $signal_width = 1;  # default
        if ($signal->can('width')) {
            $signal_width = $signal->width;
            # Handle case where width() returns 0 or undef - keep as 1-bit
            $signal_width = 1 unless ($signal_width && $signal_width > 0);
            fsm_debug("  Signal width from ->width(): $signal_width", 3);
        } else {
            fsm_debug("  Signal does not have width() method", 3);
        }
        
        if ($signal_width && $signal_width > 1) {
            $width_str = "[" . ($signal_width - 1) . ":0] ";
            fsm_debug("  Generated width string: '$width_str'", 3);
        } else {
            fsm_debug("  Using default 1-bit width", 3);
        }
        
        # Determine signal direction based on whether it's driven by our FSM
        my $is_output = 0;
        
        # First check if this signal is driven by the FSM logic
        if ($driven_signals{$sig_name}) {
            $is_output = 1;
            fsm_debug("  Signal '$sig_name' is DRIVEN by FSM -> OUTPUT", 3);
        } else {
            # Check explicit output attributes
            if ($signal->can('is_output')) {
                $is_output = $signal->is_output;
            } elsif ($signal->can('attributes') && $signal->attributes && $signal->attributes->{is_output}) {
                $is_output = $signal->attributes->{is_output};
            } elsif ($sig_name =~ />$/) {
                # Signals ending with > are outputs
                $is_output = 1;
            }
            
            fsm_debug("  Signal '$sig_name' direction: " . ($is_output ? "OUTPUT" : "INPUT"), 3);
        }
        
        if ($is_output) {
            push @outputs, "  output reg  ${width_str}${sig_name}";
            $port_directions{$sig_name} = 'output';
        } else {
            push @inputs, "  input  wire ${width_str}${sig_name}";
            $port_directions{$sig_name} = 'input';
        }
    }
    
    # Join all port declarations with proper ANSI-C SystemVerilog syntax
    my @all_ports = (@base_ports, @inputs, @outputs);
    for my $i (0 .. $#all_ports) {
        $hdl .= $all_ports[$i];
        if ($i < $#all_ports) {
            $hdl .= ",\n";  # Comma continuation for all but last port
        } else {
            $hdl .= "\n";   # No comma for last port
        }
    }
    $hdl .= ");\n\n";
    
    # Save port declarations for downstream internal declaration generation.
    $ctx->{declared_port_signals} = { %seen_signals };
    $ctx->{port_directions} = { %port_directions };
    
    return $hdl;
}
sub generate_state_encoding ($self, $fsm_module) {
    my @regular_states = grep { $_->name !~ /^-/ } @{$fsm_module->states};
    my $state_count = scalar(@regular_states);
    my $state_bits = $state_count > 1 ? int(log($state_count)/log(2)) + 1 : 1;
    
    my $hdl = "  // State encoding\n";
    for my $i (0 .. $#regular_states) {
        my $state_name = uc($regular_states[$i]->name);
        $hdl .= "  localparam $state_name = ${state_bits}'d$i;\n";
    }
    $hdl .= "\n";
    
    return $hdl;
}
sub generate_state_register ($self, $fsm_module) {
    my @regular_states = grep { $_->name !~ /^-/ } @{$fsm_module->states};
    my $state_count = scalar(@regular_states);
    
    # Check if this FSM has no regular states (only standalone decision trees)
    if ($state_count == 0) {
        fsm_debug("FSM has no regular states - only standalone decision trees. Skipping state register generation.", 3);
        return "  // No state registers needed - FSM contains only decision trees\n\n";
    }
    
    my $state_bits = $state_count > 1 ? int(log($state_count)/log(2)) + 1 : 1;
    
    my $hdl = "  // State registers\n";
    $hdl .= "  reg [" . ($state_bits - 1) . ":0] current_state, next_state;\n\n";
    
    $hdl .= "  // State sequential logic\n";
    $hdl .= "  always_ff @(posedge clk or negedge rstn) begin\n";
    $hdl .= "    if (!rstn) begin\n";
    $hdl .= "      current_state <= " . uc($regular_states[0]->name) . ";\n";
    $hdl .= "    end else begin\n";
    $hdl .= "      current_state <= next_state;\n";
    $hdl .= "    end\n";
    $hdl .= "  end\n\n";
    
    return $hdl;
}
sub generate_enable_conditions ($self, $fsm_module) {
    my $ctx = $self->{flattened_dt};
    my $hdl = "  // State and DT Enable Conditions\n";
    
    # Generate state enables
    for my $state_name (sort keys %{$ctx->{state_enables}}) {
        my $enable_expr = $ctx->{state_enables}->{$state_name};
        $hdl .= "  assign ${state_name}_en = $enable_expr;\n";
    }
    
    # Generate standalone DT enables
    for my $dt_name (sort keys %{$ctx->{dt_enables}}) {
        my $enable_expr = $ctx->{dt_enables}->{$dt_name};
        my $clean_name = $dt_name;
        $clean_name =~ s/^-//;  # Remove leading dash
        $hdl .= "  assign ${clean_name}_en = $enable_expr;\n";
    }
    
    $hdl .= "\n";
    return $hdl;
}
sub generate_wen_en_signals ($self, $fsm_module) {
    my $ctx = $self->{flattened_dt};
    my $hdl = "";
    
    # UNIFIED APPROACH: Generate WEN/EN signals from Phase 1 unified data
    $hdl .= $ctx->generate_unified_wen_en_signals($fsm_module);
    
    return $hdl;
}
sub generate_internal_signal_declarations ($self, $fsm_module) {
    my $ctx = $self->{flattened_dt};
    my %declared_ports = %{$ctx->{declared_port_signals} || {}};
    my %signal_decls;
    my %aux_decls;
    
    my @regular_states = grep { $_->name !~ /^-/ } @{$fsm_module->states};
    my $has_state_registers = scalar(@regular_states) > 0;
    if ($has_state_registers) {
        $declared_ports{current_state} = 1;
        $declared_ports{next_state} = 1;
    }
    
    for my $lhs (sort keys %{$ctx->{assignment_analysis} || {}}) {
        my $lhs_analysis = $ctx->{assignment_analysis}{$lhs};
        next unless $lhs_analysis;
        
        my $width = $ctx->get_lhs_width_from_analysis($lhs_analysis);
        my $assignment_type = $ctx->get_signal_assignment_type($lhs, $lhs_analysis);
        my $multiplexer_type = $lhs_analysis->{multiplexer}->{type} || 'comb';
        
        # Declare the main LHS only when it's not already a module port/state register.
        unless ($declared_ports{$lhs}) {
            $signal_decls{$lhs} = $width;
        }
        
        # Declare mux helper registers only for flop-style multiplexers that consume them.
        if ($multiplexer_type eq 'flop' && ($assignment_type eq 'register_out' || $assignment_type eq 'register_out_dual')) {
            my $next_name = "${lhs}_next";
            $aux_decls{$next_name} = $width unless $declared_ports{$next_name};
        } elsif ($multiplexer_type eq 'flop' && ($assignment_type eq 'register_in' || $assignment_type eq 'register_in_dual')) {
            my $q_name = "${lhs}_q";
            $aux_decls{$q_name} = $width unless $declared_ports{$q_name};
        } elsif ($assignment_type eq 'pulse_delayed') {
            my $delay_cycles = $ctx->get_pulse_delay_cycles_for_lhs($lhs, $lhs_analysis);
            if ($delay_cycles > 0) {
                my $pipe_name = "${lhs}_pulse_delay_pipe";
                $aux_decls{$pipe_name} = $delay_cycles unless $declared_ports{$pipe_name};
            }
        }
    }
    
    return "" unless (%signal_decls || %aux_decls);
    
    my $hdl = "  // Internal signal declarations\n";
    for my $signal_name (sort keys %signal_decls) {
        my $width = $signal_decls{$signal_name} || 1;
        my $width_str = ($width > 1) ? "[" . ($width - 1) . ":0] " : "";
        $hdl .= "  reg ${width_str}${signal_name};\n";
    }
    
    if (%aux_decls) {
        $hdl .= "  // Internal mux helper registers\n";
        for my $signal_name (sort keys %aux_decls) {
            my $width = $aux_decls{$signal_name} || 1;
            my $width_str = ($width > 1) ? "[" . ($width - 1) . ":0] " : "";
            $hdl .= "  reg ${width_str}${signal_name};\n";
        }
    }
    $hdl .= "\n";
    
    return $hdl;
}

1;

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

1;

#!/usr/bin/perl

package FSM::Debug;
use strict;
use warnings;
use v5.20;
use feature qw(signatures);
no warnings 'experimental::signatures';

use Exporter qw(import);
our @EXPORT = qw(fsm_debug set_fsm_debug_level get_fsm_debug_level debug_enabled debug_level);

# Global debug state
our $DEBUG_LEVEL = 0;
our $DEBUG_ENABLED = 0;

=head1 NAME

FSM::Debug - Global debug flag system for all FSM modules

=head1 DESCRIPTION

This module provides a centralized debug system that can be controlled
globally without modifying every function in every FSM module.

=head1 USAGE

    # In generate_fsm_hdl.pl or any top-level script
    use FSM::Debug;
    set_fsm_debug_level(1);  # Enable debug messages
    
    # In any FSM module
    use FSM::Debug;
    fsm_debug("This is a debug message", 3);
    fsm_debug("Detailed debug", 2);  # Level 2 debug

=cut

sub set_fsm_debug_level($level) {
    $DEBUG_LEVEL = $level // 0;
    $DEBUG_ENABLED = ($DEBUG_LEVEL > 0) ? 1 : 0;
    
    if ($DEBUG_ENABLED) {
        print "FSM::Debug: Debug level set to $DEBUG_LEVEL\n";
    }
}

sub get_fsm_debug_level() {
    return $DEBUG_LEVEL;
}

sub fsm_debug($message, $level = 1) {
    return unless $DEBUG_ENABLED && $level <= $DEBUG_LEVEL;
    
    # Get calling context for better debugging
    my ($package, $filename, $line, $subroutine) = caller(1);
    
    # Extract just the filename without path
    my $file_short = $filename ? (split '/', $filename)[-1] : 'N/A';
    
    # Extract just the function name without package prefix  
    my $func_short = $subroutine ? (split '::', $subroutine)[-1] : 'N/A';
    
    # Extract package name without full path
    my $pkg_short = $package ? (split '::', $package)[-1] : 'N/A';
    
    # Format with module, function context, then the message
    my $indent = '  ' x ($level - 1);
    print "[$pkg_short][$func_short()] ${indent}$message\n";
}

# Alternative interface for modules that prefer object-style debugging
sub debug_enabled() {
    return $DEBUG_ENABLED;
}

sub debug_level() {
    return $DEBUG_LEVEL;
}

1;

__END__

=head1 SYNOPSIS

This module provides a global debug system for all FSM modules that can be
controlled centrally without modifying individual functions.

=head2 Setting Debug Level

    use FSM::Debug;
    set_fsm_debug_level(0);  # No debug messages
    set_fsm_debug_level(1);  # Basic debug messages
    set_fsm_debug_level(2);  # Detailed debug messages  
    set_fsm_debug_level(3);  # Very detailed debug messages

=head2 Using Debug Messages

    use FSM::Debug;
    
    fsm_debug("Starting HDL generation", 3);                    # Level 1
    fsm_debug("Processing LHS signal: $lhs", 2);            # Level 2  
    fsm_debug("AST node details: " . ref($ast), 3);         # Level 3

=head2 Checking Debug State

    use FSM::Debug;
    
    if (debug_enabled()) {
        # Only do expensive debug operations when debugging is on
        my $complex_debug_info = generate_complex_debug_data();
        fsm_debug("Complex info: $complex_debug_info", 3);
    }

=head1 BENEFITS

1. **Centralized Control**: One place to enable/disable debug for all FSM modules
2. **No Function Modification**: Existing functions don't need to be changed
3. **Performance**: Debug checks are very fast when debugging is disabled
4. **Flexible Levels**: Support for different debug verbosity levels
5. **Context Information**: Automatically includes calling context
6. **Easy Integration**: Just add 'use FSM::Debug' and call fsm_debug()

=cut

#!/usr/bin/perl

package FSM::Debug;
use strict;
use warnings;
use v5.20;
use feature qw(signatures);
no warnings 'experimental::signatures';
use Carp qw(confess);
use IO::Handle;

use Exporter qw(import);
our @EXPORT = qw(
    fsm_debug
    fsm_trace_enter
    fsm_trace_exit
    fsm_trace_decision
    fsm_trace_topic
    set_fsm_debug_level
    get_fsm_debug_level
    set_fsm_trace_verbosity
    get_fsm_trace_verbosity
    set_fsm_trace_output_file
    clear_fsm_trace_output_file
    get_fsm_trace_output_file
    set_fsm_trace_emojis
    trace_emojis_enabled
    debug_enabled
    debug_level
    trace_enabled
);

# Global debug state
our $DEBUG_LEVEL = 0;
our $DEBUG_ENABLED = 0;
our $TRACE_INDENT_LEVEL = 0;
our $TRACE_OUTPUT_FH = undef;
our $TRACE_OUTPUT_FILE = undef;
our $TRACE_EMOJIS_ENABLED = 1;

our %VERBOSITY_TO_LEVEL = (
    none   => 0,
    low    => 1,
    medium => 2,
    high   => 3,
    debug  => 4,
);

our %LEVEL_TO_VERBOSITY = reverse %VERBOSITY_TO_LEVEL;
our %LEVEL_EMOJI = (
    0 => '⚫',
    1 => 'ℹ️',
    2 => '🔎',
    3 => '⚙️',
    4 => '🧠',
);

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

sub _normalize_trace_level($level) {
    return 0 unless defined $level;
    
    # Numeric compatibility mode
    if (!ref($level) && $level =~ /^\s*\d+\s*$/) {
        my $numeric = int($level);
        $numeric = 0 if $numeric < 0;
        $numeric = 4 if $numeric > 4;
        return $numeric;
    }
    
    # Named verbosity mode
    my $named = lc("$level");
    $named =~ s/^\s+|\s+$//g;
    return $VERBOSITY_TO_LEVEL{$named} if exists $VERBOSITY_TO_LEVEL{$named};
    return 4 if $named eq 'on';
    return 0 if $named eq 'off';
    
    confess "[Debug.pm][_normalize_trace_level()] Unsupported trace verbosity '$level'. Use one of: none, low, medium, high, debug (or 0-4).";
}

sub _short_context($depth = 1) {
    my ($package, $filename, $line, $subroutine) = caller($depth);
    my $file_short = $filename ? (split '/', $filename)[-1] : 'N/A';
    my $func_short = $subroutine ? (split '::', $subroutine)[-1] : 'N/A';
    return ($package, $file_short, $func_short, $line // 0);
}

sub _emit_trace_line($line) {
    if ($TRACE_OUTPUT_FH) {
        print {$TRACE_OUTPUT_FH} $line;
        $TRACE_OUTPUT_FH->flush() if $TRACE_OUTPUT_FH->can('flush');
        return;
    }
    print STDOUT $line;
}

sub _format_prefix($level, $kind, $file_short, $func_short, $line) {
    my $verbosity = uc($LEVEL_TO_VERBOSITY{$level} // "L$level");
    my $emoji = $TRACE_EMOJIS_ENABLED ? ($LEVEL_EMOJI{$level} // '•') : '';
    my $emoji_prefix = $emoji ? "$emoji " : '';
    my $indent = '  ' x $TRACE_INDENT_LEVEL;
    return sprintf("[TRACE][%s][%s:%s():%d][%s] %s%s",
        $verbosity,
        $file_short,
        $func_short,
        $line,
        $kind,
        $emoji_prefix,
        $indent,
    );
}

sub set_fsm_trace_verbosity($verbosity) {
    $DEBUG_LEVEL = _normalize_trace_level($verbosity);
    $DEBUG_ENABLED = ($DEBUG_LEVEL > 0) ? 1 : 0;
    return $DEBUG_LEVEL;
}

sub set_fsm_debug_level($level) {
    return set_fsm_trace_verbosity($level);
}

sub get_fsm_debug_level() {
    return $DEBUG_LEVEL;
}
sub get_fsm_trace_verbosity() {
    return $LEVEL_TO_VERBOSITY{$DEBUG_LEVEL} // 'none';
}

sub set_fsm_trace_output_file($path = 'trace.log') {
    clear_fsm_trace_output_file();
    
    open my $fh, '>', $path or confess "[Debug.pm][set_fsm_trace_output_file()] Cannot open trace file '$path': $!";
    $fh->autoflush(1);
    
    $TRACE_OUTPUT_FH = $fh;
    $TRACE_OUTPUT_FILE = $path;
    return $TRACE_OUTPUT_FILE;
}

sub clear_fsm_trace_output_file() {
    if ($TRACE_OUTPUT_FH) {
        close $TRACE_OUTPUT_FH or warn "[Debug.pm][clear_fsm_trace_output_file()] Failed to close trace output file: $!";
    }
    $TRACE_OUTPUT_FH = undef;
    $TRACE_OUTPUT_FILE = undef;
}

sub get_fsm_trace_output_file() {
    return $TRACE_OUTPUT_FILE;
}

sub set_fsm_trace_emojis($enabled) {
    $TRACE_EMOJIS_ENABLED = $enabled ? 1 : 0;
}

sub trace_emojis_enabled() {
    return $TRACE_EMOJIS_ENABLED ? 1 : 0;
}

sub fsm_debug($message, $level = 1) {
    return unless $DEBUG_ENABLED && $level <= $DEBUG_LEVEL;
    
    my (undef, $file_short, $func_short, $line) = _short_context(1);
    my $prefix = _format_prefix($level, 'INFO', $file_short, $func_short, $line);
    my @lines = split /\n/, "$message";
    for my $msg_line (@lines) {
        _emit_trace_line("$prefix$msg_line\n");
    }
}

sub fsm_trace_enter($label = '', $level = 2) {
    return unless $DEBUG_ENABLED && $level <= $DEBUG_LEVEL;
    my (undef, $file_short, $func_short, $line) = _short_context(1);
    
    my $topic = $label ne '' ? $label : $func_short;
    _emit_trace_line("\n");
    my $prefix = _format_prefix($level, 'ENTER', $file_short, $func_short, $line);
    _emit_trace_line("${prefix}➡️ $topic\n");
    $TRACE_INDENT_LEVEL++;
}

sub fsm_trace_exit($label = '', $level = 2) {
    return unless $DEBUG_ENABLED && $level <= $DEBUG_LEVEL;
    $TRACE_INDENT_LEVEL-- if $TRACE_INDENT_LEVEL > 0;
    
    my (undef, $file_short, $func_short, $line) = _short_context(1);
    my $topic = $label ne '' ? $label : $func_short;
    my $prefix = _format_prefix($level, 'EXIT', $file_short, $func_short, $line);
    _emit_trace_line("${prefix}⬅️ $topic\n");
    _emit_trace_line("\n");
}

sub fsm_trace_decision($decision, $reason = '', $level = 2) {
    return unless $DEBUG_ENABLED && $level <= $DEBUG_LEVEL;
    my (undef, $file_short, $func_short, $line) = _short_context(1);
    my $decision_text = $decision ? 'TRUE' : 'FALSE';
    my $reason_text = $reason ne '' ? " | reason: $reason" : '';
    my $prefix = _format_prefix($level, 'DECISION', $file_short, $func_short, $line);
    _emit_trace_line("${prefix}decision=$decision_text$reason_text\n");
}

sub fsm_trace_topic($topic, $level = 1) {
    return unless $DEBUG_ENABLED && $level <= $DEBUG_LEVEL;
    my (undef, $file_short, $func_short, $line) = _short_context(1);
    _emit_trace_line("\n");
    my $prefix = _format_prefix($level, 'TOPIC', $file_short, $func_short, $line);
    _emit_trace_line("${prefix}📚 $topic\n");
    _emit_trace_line("\n");
}

# Alternative interface for modules that prefer object-style debugging
sub debug_enabled() {
    return $DEBUG_ENABLED;
}

sub debug_level() {
    return $DEBUG_LEVEL;
}
sub trace_enabled() {
    return $DEBUG_ENABLED;
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

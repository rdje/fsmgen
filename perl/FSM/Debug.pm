#!/usr/bin/perl

package FSM::Debug;
use strict;
use warnings;
use v5.20;
use feature qw(signatures);
no warnings 'experimental::signatures';
use Carp qw(confess);
use IO::Handle;
use Scalar::Util qw(refaddr);

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
    capture_fsm_debug_state
    restore_fsm_debug_state
    with_fsm_debug_state
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

my @DEBUG_STATE_SNAPSHOT_KEYS = qw(
    schema_version
    debug_level
    debug_enabled
    trace_indent_level
    trace_output_fh
    trace_output_file
    trace_emojis_enabled
);
my %DEBUG_STATE_SNAPSHOT_KEY = map { $_ => 1 } @DEBUG_STATE_SNAPSHOT_KEYS;

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

sub _open_trace_output_handle($path, %opts) {
    my $mode = $opts{append} ? '>>' : '>';
    open my $fh, $mode, $path
        or confess "[Debug.pm][_open_trace_output_handle()] Cannot open trace file '$path': $!";
    $fh->autoflush(1);
    return $fh;
}

sub _trace_handle_is_live($fh) {
    return 0 unless defined $fh;
    return defined eval { fileno($fh) } ? 1 : 0;
}

sub _trace_handle_refaddr($fh) {
    return undef unless defined $fh;
    return refaddr($fh);
}

sub _close_trace_handle($fh, $context) {
    return unless defined $fh;
    return unless _trace_handle_is_live($fh);
    close $fh or warn "[Debug.pm][$context] Failed to close trace output file: $!";
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

    my $fh = _open_trace_output_handle($path);
    $TRACE_OUTPUT_FH = $fh;
    $TRACE_OUTPUT_FILE = $path;
    return $TRACE_OUTPUT_FILE;
}

sub clear_fsm_trace_output_file() {
    _close_trace_handle($TRACE_OUTPUT_FH, 'clear_fsm_trace_output_file()');
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

sub capture_fsm_debug_state() {
    return {
        schema_version => 1,
        debug_level => $DEBUG_LEVEL,
        debug_enabled => $DEBUG_ENABLED ? 1 : 0,
        trace_indent_level => $TRACE_INDENT_LEVEL,
        trace_output_fh => $TRACE_OUTPUT_FH,
        trace_output_file => $TRACE_OUTPUT_FILE,
        trace_emojis_enabled => $TRACE_EMOJIS_ENABLED ? 1 : 0,
    };
}

sub restore_fsm_debug_state($state) {
    _validate_debug_state_snapshot($state);

    my $saved_fh = $state->{trace_output_fh};
    my $saved_path = $state->{trace_output_file};
    my $target_fh = undef;

    if (_trace_handle_is_live($saved_fh)) {
        $target_fh = $saved_fh;
    } elsif (defined $saved_path) {
        $target_fh = _open_trace_output_handle($saved_path, append => 1);
    }

    my $current_fh = $TRACE_OUTPUT_FH;
    my $current_id = _trace_handle_refaddr($current_fh);
    my $target_id = _trace_handle_refaddr($target_fh);
    my $same_handle = defined($current_id) && defined($target_id) && $current_id == $target_id;
    _close_trace_handle($current_fh, 'restore_fsm_debug_state()')
        if defined($current_fh) && !$same_handle;

    $DEBUG_LEVEL = $state->{debug_level} // 0;
    $DEBUG_ENABLED = $state->{debug_enabled}
        ? 1
        : (($DEBUG_LEVEL > 0) ? 1 : 0);
    $TRACE_INDENT_LEVEL = $state->{trace_indent_level} // 0;
    $TRACE_OUTPUT_FH = $target_fh;
    $TRACE_OUTPUT_FILE = $saved_path;
    $TRACE_EMOJIS_ENABLED = $state->{trace_emojis_enabled} ? 1 : 0;

    return $DEBUG_LEVEL;
}

sub _validate_debug_state_snapshot($state) {
    confess "[Debug.pm][restore_fsm_debug_state()] Expected a hashref state snapshot"
        unless ref($state) eq 'HASH';

    my %missing_keys = map { $_ => 1 } @DEBUG_STATE_SNAPSHOT_KEYS;
    my %unsupported_keys;
    for my $key (keys %{$state}) {
        if ($DEBUG_STATE_SNAPSHOT_KEY{$key}) {
            delete $missing_keys{$key};
            next;
        }
        $unsupported_keys{$key} = 1;
    }

    confess "[Debug.pm][restore_fsm_debug_state()] Missing debug-state snapshot key(s): "
        . join(', ', sort keys %missing_keys)
        if %missing_keys;
    confess "[Debug.pm][restore_fsm_debug_state()] Unsupported debug-state snapshot key(s): "
        . join(', ', sort keys %unsupported_keys)
        if %unsupported_keys;
    confess "[Debug.pm][restore_fsm_debug_state()] Unsupported debug-state schema version"
        unless _is_integer_scalar($state->{schema_version})
            && $state->{schema_version} == 1;
    confess "[Debug.pm][restore_fsm_debug_state()] Expected debug_level to be an integer trace level from 0 through 4"
        unless _is_integer_scalar($state->{debug_level})
            && $state->{debug_level} >= 0
            && $state->{debug_level} <= 4;
    confess "[Debug.pm][restore_fsm_debug_state()] Expected debug_enabled to be boolean 0 or 1"
        unless _is_boolean_scalar($state->{debug_enabled});
    confess "[Debug.pm][restore_fsm_debug_state()] Expected trace_indent_level to be a non-negative integer"
        unless _is_integer_scalar($state->{trace_indent_level})
            && $state->{trace_indent_level} >= 0;
    confess "[Debug.pm][restore_fsm_debug_state()] Expected trace_output_file to be undef or a scalar non-empty path"
        unless !defined($state->{trace_output_file})
            || (!ref($state->{trace_output_file}) && $state->{trace_output_file} ne '');
    confess "[Debug.pm][restore_fsm_debug_state()] Expected trace_output_fh to be undef or a filehandle snapshot"
        unless _is_filehandle_snapshot($state->{trace_output_fh});
    confess "[Debug.pm][restore_fsm_debug_state()] Expected trace_output_file when trace_output_fh is defined"
        if defined($state->{trace_output_fh}) && !defined($state->{trace_output_file});
    confess "[Debug.pm][restore_fsm_debug_state()] Expected trace_emojis_enabled to be boolean 0 or 1"
        unless _is_boolean_scalar($state->{trace_emojis_enabled});

    return;
}

sub _is_integer_scalar($value) {
    return defined($value) && !ref($value) && $value =~ /\A[0-9]+\z/;
}

sub _is_boolean_scalar($value) {
    return defined($value) && !ref($value) && $value =~ /\A[01]\z/;
}

sub _is_filehandle_snapshot($fh) {
    return 1 unless defined $fh;
    return 0 unless ref($fh);
    return 1 if ref($fh) eq 'GLOB';
    return eval { $fh->can('fileno') } ? 1 : 0;
}

sub with_fsm_debug_state($overrides, $code) {
    confess "[Debug.pm][with_fsm_debug_state()] Expected an override hashref"
        unless ref($overrides) eq 'HASH';
    confess "[Debug.pm][with_fsm_debug_state()] Expected a CODE reference"
        unless ref($code) eq 'CODE';

    my $saved_state = capture_fsm_debug_state();

    if (exists $overrides->{debug_level}) {
        set_fsm_trace_verbosity($overrides->{debug_level});
    }
    if (exists $overrides->{trace_emojis_enabled}) {
        set_fsm_trace_emojis($overrides->{trace_emojis_enabled});
    }

    my $wantarray = wantarray;
    my (@result, $result, $ok);
    my $error;

    if (!defined $wantarray) {
        $ok = eval {
            $code->();
            1;
        };
        $error = $@ unless $ok;
    } elsif ($wantarray) {
        $ok = eval {
            @result = $code->();
            1;
        };
        $error = $@ unless $ok;
    } else {
        $ok = eval {
            $result = $code->();
            1;
        };
        $error = $@ unless $ok;
    }

    my $restore_ok = eval {
        restore_fsm_debug_state($saved_state);
        1;
    };
    my $restore_error = $@ unless $restore_ok;

    die $error if !$ok;
    die $restore_error if !$restore_ok;

    return if !defined $wantarray;
    return @result if $wantarray;
    return $result;
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

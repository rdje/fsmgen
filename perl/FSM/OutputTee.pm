#!/usr/bin/perl

package FSM::OutputTee;
use strict;
use warnings;
use v5.20;
use feature qw(signatures);
no warnings 'experimental::signatures';

=head1 NAME

FSM::OutputTee - Dual output handler for console and log file

=head1 DESCRIPTION

This module provides a tied filehandle that duplicates all output to both
the console (STDOUT) and a log file simultaneously. It's designed for use
with debug logging in FSM generation tools.

=head1 USAGE

    use FSM::OutputTee;
    
    # Set up dual output
    open my $log_fh, '>', 'debug.log';
    open my $orig_stdout, '>&', \*STDOUT;
    
    my $tee_output = sub {
        my $text = shift;
        print $orig_stdout $text;  # Console
        print $log_fh $text;       # Log file
        $log_fh->flush();
    };
    
    tie *STDOUT, 'FSM::OutputTee', $tee_output;
    
    print "This goes to both console and log file\n";
    
    # Cleanup
    untie *STDOUT;
    open STDOUT, '>&', $orig_stdout;
    close $orig_stdout;
    close $log_fh;

=cut

sub TIEHANDLE($class, $output_sub) {
    return bless { 
        output_sub => $output_sub,
        buffer => ''
    }, $class;
}

sub PRINT($self, @args) {
    my $text = join('', @args);
    $self->{output_sub}->($text);
    return 1;
}

sub PRINTF($self, $format, @args) {
    my $text = sprintf($format, @args);
    $self->{output_sub}->($text);
    return 1;
}

sub WRITE($self, $scalar, $length, $offset = 0) {
    my $text = substr($scalar, $offset, $length);
    $self->{output_sub}->($text);
    return $length;
}

sub CLOSE($self) {
    # Flush any remaining buffer content
    if ($self->{buffer}) {
        $self->{output_sub}->($self->{buffer});
        $self->{buffer} = '';
    }
    return 1;
}

# Handle other filehandle operations that might be needed
sub FILENO($self) {
    # Return fake fileno to indicate this is a valid filehandle
    return -1;
}

sub FLUSH($self) {
    # Flush any buffered content
    if ($self->{buffer}) {
        $self->{output_sub}->($self->{buffer});
        $self->{buffer} = '';
    }
    return 1;
}

1;

__END__

=head1 SYNOPSIS

FSM::OutputTee provides a tied filehandle implementation that allows you to
duplicate output to multiple destinations simultaneously. This is particularly
useful for debug logging where you want to see output on the console while
also capturing it to a log file.

=head2 Features

=over 4

=item * Supports all standard print operations (print, printf, write)

=item * Customizable output handler via callback function

=item * Automatic flushing to ensure log file is written immediately

=item * Proper cleanup and buffer management

=back

=head2 Methods

=over 4

=item TIEHANDLE($class, $output_sub)

Creates a new tied filehandle. The $output_sub callback is called for each
piece of text that needs to be output.

=item PRINT($self, @args)

Handles print() calls by joining arguments and passing to output callback.

=item PRINTF($self, $format, @args)

Handles printf() calls by formatting and passing to output callback.

=item WRITE($self, $scalar, $length, $offset)

Handles syswrite() calls by extracting substring and passing to output callback.

=item CLOSE($self)

Handles close() calls by flushing any buffered content.

=back

=head1 BENEFITS

1. **Dual Output**: See debug output on console while capturing to log
2. **Simple Integration**: Just tie STDOUT and use normal print statements
3. **Automatic Logging**: No need to modify existing print statements
4. **Immediate Flush**: Log file is updated in real-time
5. **Clean Restoration**: Easy to restore original STDOUT when done

=cut

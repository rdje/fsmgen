#!/usr/bin/env perl
use strict;
use warnings;
use Errno qw(EBADF);
use JSON::PP ();

my $JSON = JSON::PP->new->canonical->ascii;
sub emit {
    my ($event, %fields) = @_;
    my $bytes = $JSON->encode({event => $event, pid => $$, %fields}) . "\n";
    die "probe event exceeds bound\n" if length($bytes) > 4096;
    my $offset = 0;
    while ($offset < length($bytes)) {
        my $count = syswrite(STDOUT, $bytes, length($bytes) - $offset, $offset);
        die "probe event write failed: $!\n" unless defined($count) && $count > 0;
        $offset += $count;
    }
}

die "expected descriptor, device and inode\n" unless @ARGV == 3
    && !grep { !/\A[0-9]+\z/ } @ARGV;
my ($descriptor, $device, $inode) = map { 0 + $_ } @ARGV;
die "invalid descriptor identity\n" unless $descriptor > 2 && $inode > 0;
alarm(15);
emit('probe_ready', ppid => getppid(), pgid => getpgrp(0), uid => 0 + $<, euid => 0 + $>);
my $command = '';
while (length($command) < 32) {
    my $count = sysread(STDIN, my $byte, 1);
    die "probe command pipe failed: $!\n" unless defined($count) && $count == 1;
    $command .= $byte;
    last if $byte eq "\n";
}
die "unexpected probe command\n" unless $command eq "scan\n";
if (!open(my $handle, '<&=', $descriptor)) {
    die "descriptor observation failed: $!\n" unless $! == EBADF;
    emit('probe_result', descriptor => $descriptor, closed => JSON::PP::true, inherited => JSON::PP::false);
    exit 0;
} else {
    my @observed = stat($handle);
    die "descriptor stat failed: $!\n" unless @observed;
    emit('probe_result', descriptor => $descriptor, closed => JSON::PP::false,
        inherited => $observed[0] == $device && $observed[1] == $inode ? JSON::PP::true : JSON::PP::false,
        device => $observed[0], inode => $observed[1]);
    close($handle) or die "probe descriptor close failed: $!\n";
    exit 23;
}

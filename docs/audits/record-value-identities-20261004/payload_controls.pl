#!/usr/bin/env perl
use v5.20;
use strict;
use warnings;
use JSON::PP;
use FSM::Package::PayloadTypeSupport;

my ($input, $output) = @ARGV;
die "two repository-relative paths required\n" unless defined($input) && defined($output)
    && $input !~ m{\A/} && $output !~ m{\A/};
my $json = JSON::PP->new->canonical->utf8;
open my $fh, '<:raw', $input or die "$input: $!";
local $/;
my $cases = $json->decode(<$fh>);
close $fh;
my @rows;
for my $case (@$cases) {
    my @arguments = @{$case->{arguments}};
    my $before = $json->encode(\@arguments);
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    my $value;
    my $ok = eval {
        my ($class, $source, $target) = @arguments;
        $value = $class->payload_compatible_with_type_spec($source, $target);
        1;
    };
    my $error = $@;
    push @rows, {label => $case->{label}, before => $before,
        after => $json->encode(\@arguments), accepted => $ok ? 1 : 0,
        result => $value, error => $error, warnings => \@warnings};
}
open my $out, '>:raw', $output or die "$output: $!";
print {$out} $json->encode(\@rows), "\n";
close $out;

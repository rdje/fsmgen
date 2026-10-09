use strict;
use warnings;
use JSON::PP;
my @observations;
my $case;
my $context = 'finite public guard';
sub guard {
    my @site = caller;
    push @observations, {case => $case, kind => 'guard', package => $site[0], file => $site[1], line => $site[2]};
}
sub identity { return $_[0]; }
$case = 'nested-first-argument';
guard(!identity(
    0),

    "$context interpolated message");
$case = 'nested-short-circuit-argument';
guard(!(1
    && 1
    && identity(0)),
    "$context first fragment"
        . "$context second fragment");
print JSON::PP->new->canonical->encode({perl_version => "$^V", observations => \@observations}), "\n";

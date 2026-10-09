use strict;
use warnings;
use JSON::PP;
my @observations;
my $case;
my $context = 'finite public guard';
my $source = {value => 0, whole => 1, role => 'output', path => 'field', name => 'root'};
my $target = {value => 0};
my $roots = {root => 1};
sub guard {
    my @site = caller;
    push @observations, {case => $case, kind => 'guard', package => $site[0], file => $site[1], line => $site[2]};
}
sub conflicts { return $_[0] != $_[1]; }
sub root { return $_[0]; }
$case = 'nested-live-first-argument';
guard(!conflicts(

    $source->{value}, $target->{value}),
    "$context interpolated message");
$case = 'nested-live-short-circuit';
guard(!($source->{whole} && $source
    && $source->{role} eq 'output' && length($source->{path})
    && root($roots->{$source->{name}})),
    "$context first fragment"
        . "$context second fragment");
print JSON::PP->new->canonical->encode({perl_version => "$^V", observations => \@observations}), "\n";

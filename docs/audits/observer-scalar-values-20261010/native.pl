use v5.20;
use strict;
use warnings;
use Carp ();
use JSON::PP ();
local $Carp::MaxArgNums = 0;
local $Carp::MaxEvalLen = 0;
local $Carp::RefArgFormatter = undef;
sub emitter { return Carp::longmess('scalar source fixture') }
sub boundary {
    my ($value) = @_;
    my $trace = emitter();
    return {trace => $trace, value => {defined => defined($value) ? JSON::PP::true : JSON::PP::false,
        codepoints => defined($value) ? [unpack 'U*', "$value"] : []}};
}
open my $input, '<', 'docs/audits/observer-scalar-values-20261010/plan.json' or die $!;
local $/;
my $plan = JSON::PP->new->decode(<$input>);
close $input or die $!;
my @rows;
for my $case (@{$plan->{cases}}) {
    local $Carp::MaxArgLen = $case->{limit};
    my $value = !defined($case->{value}) ? undef : $case->{constructor} eq 'numeric literal' ? 0 + $case->{value}
        : pack 'U*', map {ord} split //, $case->{value};
    my $row = boundary($value);
    $row->{id} = $case->{id};
    $row->{profile} = {MaxArgLen => $Carp::MaxArgLen, MaxArgNums => $Carp::MaxArgNums,
        MaxEvalLen => $Carp::MaxEvalLen, RefArgFormatter => undef};
    push @rows, $row;
}
print JSON::PP->new->canonical->encode({rows => \@rows,
    runtime => {perl => "$^V", carp => "$Carp::VERSION", json_pp => "$JSON::PP::VERSION"}}), "\n";

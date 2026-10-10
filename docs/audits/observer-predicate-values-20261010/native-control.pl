use v5.20;
use strict;
use warnings;
use Carp ();
use JSON::PP ();
local $Carp::MaxArgLen = 64;
local $Carp::MaxArgNums = 8;
local $Carp::RefArgFormatter = undef;
sub normalized { $_[0] ? 1 : 0 }
sub emitter { return Carp::longmess('predicate source fixture') }
sub boundary {
    my ($name, $value) = @_;
    my $trace = emitter();
    # Public observation precedes all explicit value coercion in this driver.
    return {name => $name, trace => $trace, string => "$value",
        number => 0 + $value, defined => defined($value) ? JSON::PP::true : JSON::PP::false};
}
my $empty = {};
my $present = {value => 1};
my $seen = {value => 1};
my $failure = {ok => 0, code => 'source_neutral'};
my @rows;
push @rows, boundary("numeric_zero", scalar(0));
push @rows, boundary("helper_zero", scalar(normalized(0)));
push @rows, boundary("numeric_comparison", scalar(normalized(1 == 2)));
push @rows, boundary("string_comparison", scalar("x" ne "x"));
push @rows, boundary("not_true", scalar(!1));
push @rows, boundary("missing_exists", scalar(exists($empty->{missing})));
push @rows, boundary("grep_negation", scalar(!grep($_, (1))));
push @rows, boundary("or_normalized", scalar(!exists($present->{value}) || normalized(0)));
push @rows, boundary("or_comparison", scalar(0 || "x" ne "x"));
push @rows, boundary("or_negation", scalar(0 || !1));
push @rows, boundary("and_helper_first", scalar(normalized(0) && 1 == 2));
push @rows, boundary("and_helper_second", scalar(normalized(1) && normalized(0)));
push @rows, boundary("and_comparison", scalar(normalized(1) && 1 == 2));
push @rows, boundary("and_duplicate", scalar(normalized(1) && !$seen->{value}++ && exists($present->{value})));
push @rows, boundary("and_missing_member", scalar(normalized(1) && !0 && exists($empty->{missing})));
push @rows, boundary("resolver_zero", scalar($failure->{ok}));
print JSON::PP->new->canonical->encode({rows => \@rows,
    profile => {MaxArgLen => $Carp::MaxArgLen, MaxArgNums => $Carp::MaxArgNums,
        RefArgFormatter => undef},
    runtime => {perl => "$^V", carp => "$Carp::VERSION", json_pp => "$JSON::PP::VERSION"}}), "\n";

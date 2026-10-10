use strict;
use warnings;
use Carp ();
use JSON::PP ();
use re qw(regexp_pattern);
local $Carp::MaxArgNums = 0;
local $Carp::MaxEvalLen = 0;
local $Carp::RefArgFormatter = undef;
sub emitter { return Carp::longmess('regex source fixture') }
sub displayed {
    my ($regex) = @_;
    my $trace = emitter();
    my ($pattern, $modifiers) = regexp_pattern($regex);
    return {trace => $trace, value => {kind => ref($regex),
        codepoints => [unpack 'U*', $pattern], modifiers => $modifiers,
        pattern_utf8 => utf8::is_utf8($pattern) ? JSON::PP::true : JSON::PP::false,
        normalized => scalar regexp_pattern($regex)}};
}
open my $input, '<', 'docs/audits/observer-regex-values-20261010/plan.json' or die $!;
local $/;
my $plan = JSON::PP->new->decode(<$input>);
close $input or die $!;
my @rows;
for my $case (@{$plan->{cases}}) {
    local $Carp::MaxArgLen = $case->{limit};
    my $pattern = pack 'U*', map {ord} split //, $case->{body};
    utf8::downgrade($pattern) or die 'non-byte finite authored pattern';
    utf8::upgrade($pattern) if $case->{constructor} eq 'upgraded-string';
    my $expression = $case->{expression};
    utf8::downgrade($expression) or die 'non-byte finite source literal';
    my $regex = $case->{constructor} eq 'literal' ? eval $expression : qr/$pattern/;
    die $@ if $@;
    my $row = displayed($regex);
    $row->{id} = $case->{id};
    $row->{source_utf8} = utf8::is_utf8($pattern) ? JSON::PP::true : JSON::PP::false;
    $row->{profile} = {MaxArgLen => $Carp::MaxArgLen, MaxArgNums => $Carp::MaxArgNums,
        MaxEvalLen => $Carp::MaxEvalLen, RefArgFormatter => undef};
    push @rows, $row;
}
print JSON::PP->new->canonical->encode({rows => \@rows,
    runtime => {perl => "$^V", carp => "$Carp::VERSION", json_pp => "$JSON::PP::VERSION"}}), "\n";

use strict;
use warnings;
use JSON::PP;
my @observations;
my $case;
sub callsite {
    my @site = caller;
    push @observations, {case => $case, kind => 'helper', package => $site[0], file => $site[1], line => $site[2]};
    $_[0]->();
}
sub callbacksite {
    my @site = caller;
    push @observations, {case => $case, kind => 'callback', package => $site[0], file => $site[1], line => $site[2]};
}
$case = 'multiline-callback';
callsite(sub {
    callbacksite();
},
    qr/marker/,
    'label');
$case = 'single-line-callback';
callsite(sub { callbacksite(); }, qr/marker/,
    'label');
$case = 'separate-callback-close';
callsite(sub {
    callbacksite();
},
    qr/marker/,
    'label');
$case = 'named-code-reference';
my $callback = sub { callbacksite(); };
callsite($callback,
    qr/marker/,
    'label');
print JSON::PP->new->canonical->encode({perl_version => "$^V", observations => \@observations}), "\n";

use strict;
use warnings;
use JSON::PP ();
our @observations;
package Observer;
sub operation {
    my ($kind, $body) = @_;
    my @caller = caller;
    push @main::observations, {kind => $kind, package => $caller[0], file => $caller[1], line => $caller[2]};
    return $body->();
}
package Caller::Value;
sub scope {

    Observer::operation('capture', sub {return 1});
}
package main;
Observer::operation('scope', sub {Caller::Value::scope()});
print JSON::PP->new->canonical->encode(\@observations), "\n";

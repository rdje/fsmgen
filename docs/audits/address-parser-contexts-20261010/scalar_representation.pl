use strict;
use warnings;
use Storable qw(dclone);
use JSON::PP;

# Fresh public API observation only. No provider implementation or original
# native heap/flags are inspected.
my $json = JSON::PP->new->canonical;
my ($plain, $validated) = (1, 1);
die 'own positive-width validation failed'
    unless $validated =~ /\A[1-9][0-9]*\z/ && $validated > 0;
my $left = {width => $plain};
my $right = {width => $validated};
my $before = $json->decode($json->encode({left => {width => $left->{width}}, right => {width => $right->{width}}}));
my $left_copy = dclone($left);
my $right_copy = dclone($right);
print $json->encode({before => $before, copies => {left => $left_copy, right => $right_copy},
    public_runtime => {perl => "$^V", storable => $Storable::VERSION, json_pp => $JSON::PP::VERSION},
    scope => 'Fresh published-copy/JSON observations after own width validation. No original scalar flags, native identity or provider implementation is measured.'}), "\n";

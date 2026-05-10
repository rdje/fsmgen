#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
my $sentinel = '__capability_manifest_full_surface_mutation__';

subtest 'capability manifest full surface rebuilds cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    mutate_structure($first);

    my $second = build_capability_manifest();
    my $expected = build_capability_manifest();
    is_deeply($second, $expected, 'fresh capability manifest rebuilds clean full surface');
};

done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}

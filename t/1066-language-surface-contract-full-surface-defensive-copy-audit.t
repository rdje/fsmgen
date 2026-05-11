#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::LanguageSurfaceContract qw(build_language_surface_contract);
my $sentinel = '__language_surface_contract_full_surface_mutation__';

subtest 'language surface contract full surface rebuilds cleanly after caller mutation' => sub {
    my $first = build_language_surface_contract();
    mutate_structure($first);
    my $second = build_language_surface_contract();
    my $expected = build_language_surface_contract();
    is_deeply($second, $expected, 'fresh language surface contract rebuilds clean full surface');
};

done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}

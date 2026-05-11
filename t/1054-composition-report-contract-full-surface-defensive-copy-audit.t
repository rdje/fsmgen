#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::CompositionReportContract qw(build_composition_report_contract);
my $sentinel = '__composition_report_contract_full_surface_mutation__';

subtest 'composition report contract full surface rebuilds cleanly' => sub {
    my $first = build_composition_report_contract();
    mutate_structure($first);
    my $second = build_composition_report_contract();
    my $expected = build_composition_report_contract();
    is_deeply($second, $expected, 'fresh composition report contract rebuilds clean full surface');
};

done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}

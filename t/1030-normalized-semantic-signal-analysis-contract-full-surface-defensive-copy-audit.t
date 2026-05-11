#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::NormalizedSemanticSignalAnalysisContract qw(build_normalized_semantic_signal_analysis_contract);
my $sentinel = '__signal_analysis_contract_full_surface_mutation__';

subtest 'signal analysis contract full surface rebuilds cleanly' => sub {
    my $first = build_normalized_semantic_signal_analysis_contract();
    mutate_structure($first);
    my $second = build_normalized_semantic_signal_analysis_contract();
    my $expected = build_normalized_semantic_signal_analysis_contract();
    is_deeply($second, $expected, 'fresh signal analysis contract rebuilds clean full surface');
};

done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}

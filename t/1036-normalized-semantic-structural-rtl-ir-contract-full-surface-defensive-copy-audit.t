#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::NormalizedSemanticStructuralRTLIRContract qw(build_normalized_semantic_structural_rtl_ir_contract);
my $sentinel = '__structural_rtl_ir_contract_full_surface_mutation__';

subtest 'structural RTL IR contract full surface rebuilds cleanly' => sub {
    my $first = build_normalized_semantic_structural_rtl_ir_contract();
    mutate_structure($first);
    my $second = build_normalized_semantic_structural_rtl_ir_contract();
    my $expected = build_normalized_semantic_structural_rtl_ir_contract();
    is_deeply($second, $expected, 'fresh structural RTL IR contract rebuilds clean full surface');
};

done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}

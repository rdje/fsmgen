#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::SupportAccountingContract qw(build_support_accounting_contract);
my $sentinel = '__manifest_support_accounting_mutation__';

subtest 'manifest support accounting contract derived catalog flags rebuilds cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{support_accounting}{section_contract};
    $mutated->{'sanitized_catalog_entries'} = $mutated->{'sanitized_catalog_entries'} ? 0 : 1;
    $mutated->{'derived_from_regression_corpus'} = $mutated->{'derived_from_regression_corpus'} ? 0 : 1;

    my $second = build_capability_manifest();
    my $contract = $second->{support_accounting}{section_contract};
    my $expected = build_support_accounting_contract();
    is($contract->{'sanitized_catalog_entries'} ? 1 : 0, $expected->{'sanitized_catalog_entries'} ? 1 : 0, 'fresh manifest support accounting contract rebuilds clean sanitized_catalog_entries');
    is($contract->{'derived_from_regression_corpus'} ? 1 : 0, $expected->{'derived_from_regression_corpus'} ? 1 : 0, 'fresh manifest support accounting contract rebuilds clean derived_from_regression_corpus');
};
done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}

#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::DiagnosticsContract qw(build_diagnostics_contract);
my $sentinel = '__manifest_section_contract_mutation__';

subtest 'manifest diagnostics section contract identity metadata rebuilds cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{'diagnostics'}{section_contract};
    $mutated->{'status'} = $sentinel;
    $mutated->{'contract_source'} = $sentinel;
    $mutated->{'report_source'} = $sentinel;

    my $second = build_capability_manifest();
    my $contract = $second->{'diagnostics'}{section_contract};
    my $expected = build_diagnostics_contract();
    is($contract->{'status'}, $expected->{'status'}, 'fresh manifest diagnostics contract rebuilds clean status');
    is($contract->{'contract_source'}, $expected->{'contract_source'}, 'fresh manifest diagnostics contract rebuilds clean contract_source');
    is($contract->{'report_source'}, $expected->{'report_source'}, 'fresh manifest diagnostics contract rebuilds clean report_source');
    is($contract->{schema_version}, $expected->{schema_version}, 'fresh manifest section contract rebuilds clean schema_version');
};
done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}

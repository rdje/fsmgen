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

subtest 'manifest diagnostics section contract public scalar list and nested key families rebuilds cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{'diagnostics'}{section_contract};
    mutate_structure($mutated->{'public_top_level_presence_keys'});
    mutate_structure($mutated->{'scalar_string_keys'});
    mutate_structure($mutated->{'list_keys'});
    mutate_structure($mutated->{'nested_contract_keys'});

    my $second = build_capability_manifest();
    my $contract = $second->{'diagnostics'}{section_contract};
    my $expected = build_diagnostics_contract();
    is_deeply($contract->{'public_top_level_presence_keys'}, $expected->{'public_top_level_presence_keys'}, 'fresh manifest diagnostics contract rebuilds clean public_top_level_presence_keys');
    is_deeply($contract->{'scalar_string_keys'}, $expected->{'scalar_string_keys'}, 'fresh manifest diagnostics contract rebuilds clean scalar_string_keys');
    is_deeply($contract->{'list_keys'}, $expected->{'list_keys'}, 'fresh manifest diagnostics contract rebuilds clean list_keys');
    is_deeply($contract->{'nested_contract_keys'}, $expected->{'nested_contract_keys'}, 'fresh manifest diagnostics contract rebuilds clean nested_contract_keys');
};
done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}

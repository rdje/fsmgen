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

subtest 'manifest diagnostics section contract stable-code metadata rebuilds cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{'diagnostics'}{section_contract};
    mutate_structure($mutated->{'stable_code_entry_presence_keys'});
    mutate_structure($mutated->{'presence_key_family_map'});
    mutate_structure($mutated->{'stable_code_family_values'});

    my $second = build_capability_manifest();
    my $contract = $second->{'diagnostics'}{section_contract};
    my $expected = build_diagnostics_contract();
    is_deeply($contract->{'stable_code_entry_presence_keys'}, $expected->{'stable_code_entry_presence_keys'}, 'fresh manifest diagnostics contract rebuilds clean stable_code_entry_presence_keys');
    is_deeply($contract->{'presence_key_family_map'}, $expected->{'presence_key_family_map'}, 'fresh manifest diagnostics contract rebuilds clean presence_key_family_map');
    is_deeply($contract->{'stable_code_family_values'}, $expected->{'stable_code_family_values'}, 'fresh manifest diagnostics contract rebuilds clean stable_code_family_values');
};
done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}

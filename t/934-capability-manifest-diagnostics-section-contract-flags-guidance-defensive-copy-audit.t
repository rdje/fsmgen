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

subtest 'manifest diagnostics section contract advertisement flags and guidance rebuilds cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{'diagnostics'}{section_contract};
    $mutated->{'stable_code_registry_contract_advertised'} = $mutated->{'stable_code_registry_contract_advertised'} ? 0 : 1;
    $mutated->{'check_json_contract_advertised'} = $mutated->{'check_json_contract_advertised'} ? 0 : 1;
    $mutated->{'full_diagnostics_section_stable'} = $mutated->{'full_diagnostics_section_stable'} ? 0 : 1;
    mutate_structure($mutated->{'guidance'});

    my $second = build_capability_manifest();
    my $contract = $second->{'diagnostics'}{section_contract};
    my $expected = build_diagnostics_contract();
    is($contract->{'stable_code_registry_contract_advertised'} ? 1 : 0, $expected->{'stable_code_registry_contract_advertised'} ? 1 : 0, 'fresh manifest diagnostics contract rebuilds clean stable_code_registry_contract_advertised');
    is($contract->{'check_json_contract_advertised'} ? 1 : 0, $expected->{'check_json_contract_advertised'} ? 1 : 0, 'fresh manifest diagnostics contract rebuilds clean check_json_contract_advertised');
    is($contract->{'full_diagnostics_section_stable'} ? 1 : 0, $expected->{'full_diagnostics_section_stable'} ? 1 : 0, 'fresh manifest diagnostics contract rebuilds clean full_diagnostics_section_stable');
    is_deeply($contract->{'guidance'}, $expected->{'guidance'}, 'fresh manifest diagnostics contract rebuilds clean guidance');
};
done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}

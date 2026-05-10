#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::BackendValidationContract qw(build_backend_validation_contract);
my $sentinel = '__manifest_section_contract_mutation__';

subtest 'manifest backend-validation contract advertisement flags and guidance rebuilds cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{'backend_validation'}{'section_contract'};
    $mutated->{'systemverilog_external_contract_advertised'} = $mutated->{'systemverilog_external_contract_advertised'} ? 0 : 1;
    $mutated->{'full_backend_validation_section_stable'} = $mutated->{'full_backend_validation_section_stable'} ? 0 : 1;
    mutate_structure($mutated->{'guidance'});

    my $second = build_capability_manifest();
    my $contract = $second->{'backend_validation'}{'section_contract'};
    my $expected = build_backend_validation_contract();
    is($contract->{'systemverilog_external_contract_advertised'} ? 1 : 0, $expected->{'systemverilog_external_contract_advertised'} ? 1 : 0, 'fresh manifest backend-validation contract rebuilds clean systemverilog_external_contract_advertised');
    is($contract->{'full_backend_validation_section_stable'} ? 1 : 0, $expected->{'full_backend_validation_section_stable'} ? 1 : 0, 'fresh manifest backend-validation contract rebuilds clean full_backend_validation_section_stable');
    is_deeply($contract->{'guidance'}, $expected->{'guidance'}, 'fresh manifest backend-validation contract rebuilds clean guidance');
};
done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}

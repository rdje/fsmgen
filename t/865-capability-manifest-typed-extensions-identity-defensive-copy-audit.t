#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::ExtensionContract qw(build_extension_contract);
my $sentinel = '__manifest_typed_extension_mutation__';

subtest 'manifest-embedded typed extensions identity metadata rebuilds cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{embedding}{typed_extensions};
    $mutated->{'status'} = $sentinel;
    $mutated->{'contract_source'} = $sentinel;
    mutate_structure($mutated->{'implementation_owners'});

    my $second = build_capability_manifest();
    my $contract = $second->{embedding}{typed_extensions};
    my $expected = build_extension_contract();
    is($contract->{'status'}, $expected->{'status'}, 'fresh manifest typed extension contract rebuilds clean status');
    is($contract->{'contract_source'}, $expected->{'contract_source'}, 'fresh manifest typed extension contract rebuilds clean contract_source');
    is_deeply($contract->{'implementation_owners'}, $expected->{'implementation_owners'}, 'fresh manifest typed extension contract rebuilds clean implementation_owners');
    is($contract->{schema_version}, $expected->{schema_version}, 'fresh manifest typed extension contract rebuilds clean schema_version');
};
done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}

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

subtest 'manifest-embedded typed extensions stability and closure flags rebuilds cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{embedding}{typed_extensions};
    $mutated->{'stable_context_accessor_names'} = $mutated->{'stable_context_accessor_names'} ? 0 : 1;
    $mutated->{'hook_set_closed_for_schema_version'} = $mutated->{'hook_set_closed_for_schema_version'} ? 0 : 1;
    $mutated->{'full_extension_api_frozen'} = $mutated->{'full_extension_api_frozen'} ? 0 : 1;

    my $second = build_capability_manifest();
    my $contract = $second->{embedding}{typed_extensions};
    my $expected = build_extension_contract();
    is($contract->{'stable_context_accessor_names'} ? 1 : 0, $expected->{'stable_context_accessor_names'} ? 1 : 0, 'fresh manifest typed extension contract rebuilds clean stable_context_accessor_names');
    is($contract->{'hook_set_closed_for_schema_version'} ? 1 : 0, $expected->{'hook_set_closed_for_schema_version'} ? 1 : 0, 'fresh manifest typed extension contract rebuilds clean hook_set_closed_for_schema_version');
    is($contract->{'full_extension_api_frozen'} ? 1 : 0, $expected->{'full_extension_api_frozen'} ? 1 : 0, 'fresh manifest typed extension contract rebuilds clean full_extension_api_frozen');
};
done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}

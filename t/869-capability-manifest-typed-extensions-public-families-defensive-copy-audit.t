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

subtest 'manifest-embedded typed extensions public key and name families rebuilds cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{embedding}{typed_extensions};
    mutate_structure($mutated->{'public_top_level_presence_keys'});
    mutate_structure($mutated->{'hook_names'});
    mutate_structure($mutated->{'context_accessors'});
    mutate_structure($mutated->{'name_family_map'});
    mutate_structure($mutated->{'supported_source_kinds'});

    my $second = build_capability_manifest();
    my $contract = $second->{embedding}{typed_extensions};
    my $expected = build_extension_contract();
    is_deeply($contract->{'public_top_level_presence_keys'}, $expected->{'public_top_level_presence_keys'}, 'fresh manifest typed extension contract rebuilds clean public_top_level_presence_keys');
    is_deeply($contract->{'hook_names'}, $expected->{'hook_names'}, 'fresh manifest typed extension contract rebuilds clean hook_names');
    is_deeply($contract->{'context_accessors'}, $expected->{'context_accessors'}, 'fresh manifest typed extension contract rebuilds clean context_accessors');
    is_deeply($contract->{'name_family_map'}, $expected->{'name_family_map'}, 'fresh manifest typed extension contract rebuilds clean name_family_map');
    is_deeply($contract->{'supported_source_kinds'}, $expected->{'supported_source_kinds'}, 'fresh manifest typed extension contract rebuilds clean supported_source_kinds');
};
done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}

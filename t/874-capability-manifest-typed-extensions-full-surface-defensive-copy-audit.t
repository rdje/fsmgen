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

subtest 'manifest-embedded typed extensions full embedded typed-extension contract rebuilds cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{embedding}{typed_extensions};
    mutate_structure($mutated->{'extension_object_contract'});
    mutate_structure($mutated->{'context_contract'});
    mutate_structure($mutated->{'hooks'});
    mutate_structure($mutated->{'name_family_map'});
    mutate_structure($mutated->{'guidance'});

    my $second = build_capability_manifest();
    my $contract = $second->{embedding}{typed_extensions};
    my $expected = build_extension_contract();
    is_deeply($contract->{'extension_object_contract'}, $expected->{'extension_object_contract'}, 'fresh manifest typed extension contract rebuilds clean extension_object_contract');
    is_deeply($contract->{'context_contract'}, $expected->{'context_contract'}, 'fresh manifest typed extension contract rebuilds clean context_contract');
    is_deeply($contract->{'hooks'}, $expected->{'hooks'}, 'fresh manifest typed extension contract rebuilds clean hooks');
    is_deeply($contract->{'name_family_map'}, $expected->{'name_family_map'}, 'fresh manifest typed extension contract rebuilds clean name_family_map');
    is_deeply($contract->{'guidance'}, $expected->{'guidance'}, 'fresh manifest typed extension contract rebuilds clean guidance');
};
done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}

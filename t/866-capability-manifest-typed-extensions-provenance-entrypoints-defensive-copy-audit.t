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

subtest 'manifest-embedded typed extensions tested_by and entrypoint metadata rebuilds cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{embedding}{typed_extensions};
    mutate_structure($mutated->{'tested_by'});
    mutate_structure($mutated->{'entrypoints'});

    my $second = build_capability_manifest();
    my $contract = $second->{embedding}{typed_extensions};
    my $expected = build_extension_contract();
    is_deeply($contract->{'tested_by'}, $expected->{'tested_by'}, 'fresh manifest typed extension contract rebuilds clean tested_by');
    is_deeply($contract->{'entrypoints'}, $expected->{'entrypoints'}, 'fresh manifest typed extension contract rebuilds clean entrypoints');
};
done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}

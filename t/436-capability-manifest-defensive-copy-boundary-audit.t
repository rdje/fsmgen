#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::CapabilityManifestContract qw(
    capability_manifest_public_top_level_keys
);
use FSM::Support::ExtensionContract qw(build_extension_contract);

my $sentinel = '__mutated_by_t436__';

subtest 'capability manifest builder returns fresh nested structures' => sub {
    my $first = build_capability_manifest();
    mutate_structure($first);

    my $second = build_capability_manifest();
    ok(!contains_sentinel($second), 'fresh build_capability_manifest result is not affected by prior caller mutation');
    is_deeply(
        sorted([keys %{$second}]),
        sorted(capability_manifest_public_top_level_keys()),
        'fresh manifest still has exactly the public top-level keys after prior mutation',
    );
    is_deeply(
        sorted($second->{manifest_contract}{public_top_level_presence_keys}),
        sorted(capability_manifest_public_top_level_keys()),
        'fresh manifest contract still advertises the public top-level keys after prior mutation',
    );
    is_deeply(
        $second->{embedding}{typed_extensions},
        build_extension_contract(),
        'fresh manifest still embeds a clean typed-extension contract after prior mutation',
    );
};

subtest 'capability manifest section maps keep fresh nested lists' => sub {
    my $first = build_capability_manifest();
    $first->{manifest_contract}{top_level_section_presence_key_map}{embedding}[0] = $sentinel;
    push @{$first->{manifest_contract}{presence_key_family_map}{documentation_presence_keys}}, $sentinel;

    my $second = build_capability_manifest();
    ok(
        !contains_sentinel($second->{manifest_contract}{top_level_section_presence_key_map}),
        'fresh top_level_section_presence_key_map is not polluted by prior caller mutation',
    );
    ok(
        !contains_sentinel($second->{manifest_contract}{presence_key_family_map}),
        'fresh presence_key_family_map is not polluted by prior caller mutation',
    );
    is_deeply(
        sorted($second->{manifest_contract}{top_level_section_presence_key_map}{embedding}),
        sorted($second->{manifest_contract}{embedding_presence_keys}),
        'fresh embedding section key map still matches embedding_presence_keys',
    );
    is_deeply(
        sorted($second->{manifest_contract}{presence_key_family_map}{documentation_presence_keys}),
        sorted($second->{manifest_contract}{documentation_presence_keys}),
        'fresh documentation presence family still matches documentation_presence_keys',
    );
};

done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);

    if (ref($value) eq 'ARRAY') {
        push @{$value}, $sentinel;
        mutate_structure($_) for @{$value};
        return;
    }

    if (ref($value) eq 'HASH') {
        $value->{$sentinel} = $sentinel;
        mutate_structure($_) for values %{$value};
        return;
    }
}

sub contains_sentinel {
    my ($value) = @_;
    return 1 if defined($value) && !ref($value) && $value eq $sentinel;
    return 0 unless ref($value);

    if (ref($value) eq 'ARRAY') {
        for my $entry (@{$value}) {
            return 1 if contains_sentinel($entry);
        }
        return 0;
    }

    if (ref($value) eq 'HASH') {
        return 1 if exists($value->{$sentinel});
        for my $entry (values %{$value}) {
            return 1 if contains_sentinel($entry);
        }
        return 0;
    }

    return 0;
}

sub sorted {
    my ($values) = @_;
    return [sort @{$values || []}];
}

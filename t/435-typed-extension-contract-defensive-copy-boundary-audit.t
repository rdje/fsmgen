#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::ExtensionContract qw(
    build_extension_contract
    extension_contract_context_accessors
    extension_contract_hook_names
    extension_contract_loader_constructor_option_names
    extension_contract_loader_method_names
    extension_contract_name_family_map
    extension_contract_public_top_level_keys
    extension_contract_registry_constructor_option_names
    extension_contract_registry_method_names
    extension_contract_supported_source_kinds
);

my $sentinel = '__mutated_by_t435__';
my $audit_test = 't/435-typed-extension-contract-defensive-copy-boundary-audit.t';

subtest 'typed-extension list helpers return fresh arrays' => sub {
    for my $case (
        {
            label => 'public top-level keys',
            build => \&extension_contract_public_top_level_keys,
        },
        {
            label => 'hook names',
            build => \&extension_contract_hook_names,
        },
        {
            label => 'context accessors',
            build => \&extension_contract_context_accessors,
        },
        {
            label => 'loader constructor option names',
            build => \&extension_contract_loader_constructor_option_names,
        },
        {
            label => 'loader method names',
            build => \&extension_contract_loader_method_names,
        },
        {
            label => 'registry constructor option names',
            build => \&extension_contract_registry_constructor_option_names,
        },
        {
            label => 'registry method names',
            build => \&extension_contract_registry_method_names,
        },
        {
            label => 'supported source kinds',
            build => \&extension_contract_supported_source_kinds,
        },
    ) {
        my $first = $case->{build}->();
        push @{$first}, $sentinel;

        my $second = $case->{build}->();
        ok(!contains_scalar($second, $sentinel), "$case->{label} helper returns a fresh list");
    }
};

subtest 'typed-extension name-family map returns fresh nested arrays' => sub {
    my $first = extension_contract_name_family_map();
    $first->{hook_names}[0] = $sentinel;
    push @{$first->{context_accessors}}, $sentinel;
    $first->{$sentinel} = [$sentinel];

    my $second = extension_contract_name_family_map();
    ok(!contains_sentinel($second), 'name_family_map returns a fresh map with fresh nested lists');
    is_deeply(
        sorted($second->{hook_names}),
        sorted(extension_contract_hook_names()),
        'fresh name_family_map hook_names still matches the hook helper',
    );
    is_deeply(
        sorted($second->{context_accessors}),
        sorted(extension_contract_context_accessors()),
        'fresh name_family_map context_accessors still matches the accessor helper',
    );
    is_deeply(
        sorted($second->{supported_source_kinds}),
        sorted(extension_contract_supported_source_kinds()),
        'fresh name_family_map supported_source_kinds still matches the source-kind helper',
    );
};

subtest 'build_extension_contract returns fresh nested structures' => sub {
    my $first = build_extension_contract();
    mutate_structure($first);

    my $second = build_extension_contract();
    ok(!contains_sentinel($second), 'fresh build_extension_contract result is not affected by prior caller mutation');
    ok(contains_scalar($second->{tested_by}, $audit_test), 'contract provenance lists this defensive-copy audit');
    is_deeply(
        sorted($second->{public_top_level_presence_keys}),
        sorted([keys %{$second}]),
        'fresh contract still self-describes its top-level keys after prior mutation',
    );
    is_deeply(
        sorted($second->{hook_names}),
        sorted(extension_contract_hook_names()),
        'fresh contract hook_names still matches the hook helper after prior mutation',
    );
    is_deeply(
        sorted($second->{context_accessors}),
        sorted(extension_contract_context_accessors()),
        'fresh contract context_accessors still matches the accessor helper after prior mutation',
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

sub contains_scalar {
    my ($values, $wanted) = @_;
    return 0 unless ref($values) eq 'ARRAY';

    for my $value (@{$values}) {
        return 1 if defined($value) && !ref($value) && $value eq $wanted;
    }

    return 0;
}

sub sorted {
    my ($values) = @_;
    return [sort @{$values || []}];
}

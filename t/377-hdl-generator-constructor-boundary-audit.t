#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::HDLGeneratorFacadeContract qw(
    build_hdl_generator_facade_contract
    hdl_generator_facade_public_constructor_option_names
);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');

my @public_facade_args = qw(
    debug_level
    target_language
    quiet
    strict_mode
    source_search_paths
    extensions
);

my @non_public_owner_injection_args = qw(
    source_path_resolver
    extension_loader
    extension_registry
    rtl_interface_loader
);

my @non_public_extension_loading_args = qw(
    extension_config_files
    extension_modules
);
my @non_public_legacy_compatibility_args = qw(
    debug
);

my @classified_constructor_args = (
    @public_facade_args,
    @non_public_owner_injection_args,
    @non_public_extension_loading_args,
    @non_public_legacy_compatibility_args,
);

subtest 'HDLGenerator constructor args stay deliberately classified' => sub {
    my $accepted_args = constructor_args_from_source();

    is_deeply(
        sorted_unique(@{$accepted_args}),
        sorted_unique(@classified_constructor_args),
        'every current $args{...} constructor key is classified as public or intentionally non-public',
    );

    my %accepted = map { $_ => 1 } @{$accepted_args};
    for my $arg (@public_facade_args) {
        ok($accepted{$arg}, "source still accepts public facade constructor arg $arg");
    }
    for my $arg (@non_public_owner_injection_args) {
        ok($accepted{$arg}, "source still accepts internal owner-injection arg $arg");
    }
    for my $arg (@non_public_extension_loading_args) {
        ok($accepted{$arg}, "source still accepts non-public extension-loading arg $arg");
    }
    for my $arg (@non_public_legacy_compatibility_args) {
        ok($accepted{$arg}, "source still accepts non-public legacy compatibility arg $arg");
    }
};

subtest 'facade contract keeps owner-injection args out of the public constructor surface' => sub {
    my $contract = build_hdl_generator_facade_contract();

    is_deeply(
        $contract->{public_constructor_option_names},
        hdl_generator_facade_public_constructor_option_names(),
        'contract keeps the public constructor option list builder-owned',
    );
    is_deeply(
        sorted_unique(@{$contract->{public_constructor_option_names}}),
        sorted_unique(@public_facade_args),
        'contract public constructor option list is exactly the bounded facade surface',
    );
    ok(
        !$contract->{object_injection_args_public},
        'contract explicitly says owner-injection args are not public',
    );
    assert_non_public_args_absent_from_facade_contract(
        $contract,
        \@non_public_owner_injection_args,
        'owner-injection args',
    );
    assert_non_public_args_absent_from_facade_contract(
        $contract,
        \@non_public_extension_loading_args,
        'module/config extension-loading args',
    );
    assert_non_public_args_absent_from_facade_contract(
        $contract,
        \@non_public_legacy_compatibility_args,
        'legacy compatibility args',
    );
};

subtest 'live manifest keeps the same constructor boundary' => sub {
    my @manifest_views = (
        {
            label => 'in-process capability manifest',
            manifest => build_capability_manifest(),
        },
        {
            label => 'CLI capability manifest',
            manifest => run_capability_manifest('--capability-manifest'),
        },
        {
            label => 'CLI alias capability manifest',
            manifest => run_capability_manifest('--emit-capability-manifest'),
        },
    );

    for my $view (@manifest_views) {
        my $facade = $view->{manifest}{embedding}{hdl_generator_facade};
        my $label = $view->{label};

        is_deeply(
            sorted_unique(@{$facade->{public_constructor_option_names}}),
            sorted_unique(@public_facade_args),
            "$label keeps the bounded public constructor option list",
        );
        ok(
            !$facade->{object_injection_args_public},
            "$label does not publish owner-injection args as public",
        );
        assert_non_public_args_absent_from_facade_contract(
            $facade,
            \@non_public_owner_injection_args,
            "$label owner-injection args",
        );
        assert_non_public_args_absent_from_facade_contract(
            $facade,
            \@non_public_extension_loading_args,
            "$label module/config extension-loading args",
        );
        assert_non_public_args_absent_from_facade_contract(
            $facade,
            \@non_public_legacy_compatibility_args,
            "$label legacy compatibility args",
        );
    }
};

done_testing();

sub constructor_args_from_source {
    my $path = File::Spec->catfile(
        $repo_root,
        qw(perl FSM Pipeline HDLGenerator.pm),
    );
    open my $fh, '<', $path or die "Cannot open $path: $!";
    my $source = do { local $/; <$fh> };
    close $fh or die "Cannot close $path: $!";

    my @args = ($source =~ /\$args\{([A-Za-z_][A-Za-z0-9_]*)\}/g);
    return sorted_unique(@args);
}

sub assert_non_public_args_absent_from_facade_contract {
    my ($facade, $non_public_args, $label) = @_;

    my @advertised_constructor_args = advertised_constructor_args($facade);
    my %advertised = map { $_ => 1 } @advertised_constructor_args;

    for my $arg (@{$non_public_args}) {
        ok(
            !$advertised{$arg},
            "$label: $arg is not advertised as a public constructor option",
        );
    }
}

sub advertised_constructor_args {
    my ($facade) = @_;
    my @args = (
        @{$facade->{public_constructor_option_names} || []},
        @{$facade->{core_constructor_option_names} || []},
        @{$facade->{direct_extension_option_names} || []},
    );

    my $family_map = $facade->{constructor_option_family_map} || {};
    for my $family (sort keys %{$family_map}) {
        push @args, @{$family_map->{$family} || []};
    }

    return @{sorted_unique(@args)};
}

sub run_capability_manifest {
    my ($mode) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', $mode],
    );

    ok($success, "$mode succeeds");
    is(join('', @{$stderr_buf || []}), '', "$mode keeps stderr clean");

    return decode_json(join('', @{$stdout_buf || []}));
}

sub sorted_unique {
    my (@values) = @_;
    my %seen;
    return [sort grep { !$seen{$_}++ } @values];
}

#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::ISFPublicInterfaceContract qw(
    build_isf_public_interface_contract
    isf_public_interface_library_catalog_entry_keys
    isf_public_interface_library_catalog_paths
    isf_public_interface_shipped_library_definitions
);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');

subtest 'ISF public contract advertises the shipped library catalog metadata' => sub {
    my @views = (
        {
            label => 'direct ISF public-interface contract',
            contract => build_isf_public_interface_contract(),
        },
        {
            label => 'capability manifest ISF public-interface contract',
            contract => build_capability_manifest()->{embedding}{isf_public_interface},
        },
    );

    for my $view (@views) {
        my $contract = $view->{contract};
        my $label = $view->{label};

        is_deeply(
            $contract->{library_catalog_paths},
            isf_public_interface_library_catalog_paths(),
            "$label exposes the owner catalog path list",
        );
        is_deeply(
            $contract->{library_catalog_entry_keys},
            isf_public_interface_library_catalog_entry_keys(),
            "$label exposes the owner catalog entry key list",
        );
        is_deeply(
            $contract->{shipped_library_definitions},
            isf_public_interface_shipped_library_definitions(),
            "$label exposes the owner shipped-definition list",
        );
    }
};

subtest 'catalog paths and shipped definition paths are repo-local and present' => sub {
    my $contract = build_isf_public_interface_contract();

    assert_repo_relative_existing_file($_, 'catalog path')
        for @{$contract->{library_catalog_paths}};

    for my $definition (@{$contract->{shipped_library_definitions}}) {
        assert_exact_keys($definition, $contract->{library_catalog_entry_keys}, $definition->{qualified_name});
        assert_repo_relative_existing_file($definition->{source}, "$definition->{qualified_name} source");
        assert_repo_relative_existing_file($definition->{import_fixture}, "$definition->{qualified_name} import fixture");
        assert_unique_scalar_list($definition->{semantics}, "$definition->{qualified_name} semantics");
        assert_unique_scalar_list($definition->{limitations}, "$definition->{qualified_name} limitations");
        assert_repo_relative_existing_file($_, "$definition->{qualified_name} test")
            for @{$definition->{tests}};
    }
};

subtest 'catalog document records the shipped FIFO definition' => sub {
    my $catalog = slurp(repo_file('docs/ISF_LIBRARY_CATALOG.md'));

    like($catalog, qr/\bcommon\.fifo\.fifo\b/, 'catalog names the shipped FIFO definition');
    like($catalog, qr/\bisf\/common\/fifo\.isf\b/, 'catalog links the FIFO source');
    like($catalog, qr/\bisf\/fifo_library_use\.isf\b/, 'catalog links the FIFO import fixture');
    like($catalog, qr/\bDATA_WIDTH\b[\s\S]*?\b8\b/, 'catalog records DATA_WIDTH=8');
    like($catalog, qr/\bDEPTH\b[\s\S]*?\b4\b/, 'catalog records DEPTH=4');
    like($catalog, qr/\bPTR_WIDTH\b[\s\S]*?\b2\b/, 'catalog records PTR_WIDTH=2');
    like($catalog, qr/\bOCC_WIDTH\b[\s\S]*?\b3\b/, 'catalog records OCC_WIDTH=3');
    like($catalog, qr/\bwrite_req\b[\s\S]*?\bdata_in\b[\s\S]*?\bread_req\b/, 'catalog records FIFO inputs');
    like($catalog, qr/\bfull\b[\s\S]*?\bempty\b[\s\S]*?\bdata_out\b/, 'catalog records FIFO outputs');
    like($catalog, qr/\bwr_ptr\b[\s\S]*?\brd_ptr\b[\s\S]*?\boccupancy\b[\s\S]*?\bdata\b/, 'catalog records FIFO storage');
    like($catalog, qr/read-before-write/, 'catalog records bank access policy');
    like($catalog, qr/Parameter-driven interface and storage elaboration is not shipped yet/, 'catalog records key limitation');
};

done_testing();

sub assert_repo_relative_existing_file {
    my ($path, $label) = @_;

    ok(!ref($path), "$label is scalar");
    ok(length($path || ''), "$label is non-empty");
    ok(!File::Spec->file_name_is_absolute($path), "$label is repo-relative");
    unlike($path, qr{(?:\A|/)\.\.(?:/|\z)}, "$label does not escape the repo");
    ok(-f repo_file($path), "$label exists on disk");
}

sub assert_exact_keys {
    my ($hash, $expected_keys, $label) = @_;
    my @actual = sort keys %{$hash};
    my @expected = sort @{$expected_keys || []};
    is_deeply(\@actual, \@expected, "$label has exactly the advertised catalog entry keys");
}

sub assert_unique_scalar_list {
    my ($values, $label) = @_;
    my %seen;

    ok(ref($values) eq 'ARRAY', "$label is an array");
    for my $value (@{$values || []}) {
        ok(!ref($value), "$label entry '$value' is scalar");
        next if ref($value);
        ok(length($value), "$label entry '$value' is non-empty");
        ok(!$seen{$value}++, "$label does not duplicate '$value'");
    }
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "cannot read $path: $!";
    my $text = do { local $/; <$fh> };
    close $fh or die "cannot close $path: $!";
    return $text;
}

sub repo_file {
    my ($path) = @_;
    return File::Spec->catfile($repo_root, split m{/}, $path);
}

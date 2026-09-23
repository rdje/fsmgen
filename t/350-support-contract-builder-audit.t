#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Basename qw(dirname);
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

my $support_dir = File::Spec->catdir($FindBin::Bin, '..', 'perl', 'FSM', 'Support');
my @contract_files = sort glob(File::Spec->catfile($support_dir, '*Contract.pm'));

ok(@contract_files, 'support contract audit found contract modules to inspect');

my %allowed_status = map { $_ => 1 } qw(
    bounded_public
    bounded_public_json_fragment
    bounded_top_level_presence
    optional_when_tools_installed
    shipped_private_in_process
    shipped_private_target_neutral_no_backend
    shipped_private_execution_and_portable_sv_emission
    shipped_private_emission_foundation_and_review_gallery
    shipped_private_selected_matrix_and_review_workflow
    shipped_private_structurally_reviewed_unqualified_portable_profile
    shipped_private_portable_and_osvvm_qualified_profiles
    shipped_public_source_tooling_and_atomic_planning
    shipped_public_verilator_execution_and_result
    shipped_public_verilator_execution_result_and_ahb_parity
    shipped_bounded_regression_gate
);

# The semantic-family envelope names support_classification as an explicit
# nonclaim and omits guidance from its own key list. It is a private phase
# envelope, not a support-classification record, so the guidance assertion
# does not apply. Its status is still admitted.
my %guidance_exempt = map { $_ => 1 } qw(
    FSM::Support::VIALSemanticFamilyContract
);
my %exempt_status = (
    'FSM::Support::VIALSemanticFamilyContract' =>
        'private_v2_common_envelope_with_lifecycle_compiler',
);

for my $file (@contract_files) {
    my $module = _module_name_from_file($file);

    subtest $module => sub {
        require_ok($module);

        no strict 'refs';
        my @exports = @{"${module}::EXPORT_OK"};
        my @builders = grep { /^build_.*_contract$/ } @exports;
        use strict 'refs';

        is(
            scalar(@builders),
            1,
            "$module exports exactly one build_*_contract helper",
        );

        my $builder_name = $builders[0];
        ok(defined($builder_name), "$module exposes a build_*_contract helper")
            or return;

        no strict 'refs';
        my $builder = \&{"${module}::$builder_name"};
        use strict 'refs';

        my $contract = $builder->();
        is(ref($contract), 'HASH', "$module builder returns a hashref");
        is($contract->{schema_version}, 1, "$module contract keeps schema_version at 1");
        my $status_allowed = $guidance_exempt{$module}
            ? defined($contract->{status})
                && $contract->{status} eq $exempt_status{$module}
            : defined($contract->{status}) && $allowed_status{$contract->{status}};
        ok($status_allowed, "$module contract uses an allowed status value");
        is(
            $contract->{contract_source},
            $module,
            "$module contract_source points back to its canonical owner",
        );
        if ($guidance_exempt{$module}) {
            ok(
                !exists($contract->{guidance}),
                "$module stays outside the guidance assertion because its own nonclaims exclude support_classification",
            );
            ok(
                ref($contract->{explicit_nonclaims}) eq 'ARRAY'
                    && grep { $_ eq 'support_classification' } @{$contract->{explicit_nonclaims}},
                "$module records support_classification as an explicit nonclaim",
            );
        }
        else {
            ok(
                ref($contract->{guidance}) eq 'ARRAY' && @{$contract->{guidance}},
                "$module contract keeps non-empty guidance",
            );
        }
    };
}

done_testing();

sub _module_name_from_file {
    my ($file) = @_;
    my $base = File::Spec->abs2rel($file, File::Spec->catdir($FindBin::Bin, '..', 'perl'));
    $base =~ s{\.pm$}{};
    $base =~ s{[/\\]}{::}g;
    return $base;
}

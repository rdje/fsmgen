#!/usr/bin/env perl

use v5.20;
use strict;
use warnings;

use File::Spec;
use FindBin;
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::VIALNativeUVMEmissionContract qw(
    build_vial_native_uvm_emission_contract
);
use FSM::Support::VIALToolingContract qw(build_vial_tooling_contract);
use FSM::Support::VIALVHDLEmissionContract qw(
    build_vial_vhdl_emission_contract
);

my $repo_root = File::Spec->rel2abs(
    File::Spec->catdir($FindBin::Bin, '..'),
);
my $book_root = File::Spec->catdir($repo_root, qw(docs book src));
my $readme = slurp(File::Spec->catfile($repo_root, 'README.md'));
my $summary = slurp(File::Spec->catfile($book_root, 'SUMMARY.md'));
my $backlog = slurp(File::Spec->catfile(
    $book_root, '14e-hial-vial-verification.md',
));
my $overview = slurp(File::Spec->catfile(
    $book_root, '16d-hial-vial-verification-architecture.md',
));

my $tooling = build_vial_tooling_contract();
my $vhdl = build_vial_vhdl_emission_contract();
my $uvm = build_vial_native_uvm_emission_contract();

subtest 'README and SUMMARY provide one bounded reader entry path' => sub {
    like(
        $readme,
        qr{\[HIAL/VIAL Verification\]\(docs/book/src/16d-hial-vial-verification-architecture[.]md\)},
        'README routes HIAL/VIAL readers to the stable overview',
    );
    unlike(
        $readme,
        qr{\[HIAL/VIAL Verification\]\(docs/book/src/14e-hial-vial-verification[.]md\)},
        'README does not present the future backlog as current behavior',
    );

    my $cluster = <<'MARKDOWN';
  - [HIAL/VIAL Verification: Start Here](16d-hial-vial-verification-architecture.md)
    - [Public VIAL Lifecycle Reference](16dg-vial-public-lifecycle-reference.md)
    - [End-to-End AHB HIAL/VIAL Tutorial](16dh-vial-ahb-end-to-end-tutorial.md)
    - [Migrating Legacy Verification to VIAL](16di-vial-legacy-migration.md)
    - [VIAL Capability, Support, Parity, and Troubleshooting Reference](16dj-vial-capability-support-reference.md)
    - [Balanced Portable Composition](16da-vial-balanced-portable-composition.md)
    - [Structural Backend-Emission Matrix](16db-vial-structural-backend-emission-matrix.md)
    - [Portable Verilator Runtime Measurement](16dc-vial-portable-verilator-runtime-measurement.md)
    - [Portable VHDL Runtime Measurement](16dd-vial-portable-vhdl-runtime-measurement.md)
    - [OSVVM Runtime Execution Plan](16de-vial-osvvm-runtime-execution-plan.md)
    - [Architecture-Scale Cap Closeout](16df-vial-architecture-scale-cap-closeout.md)
MARKDOWN
    like(
        $summary,
        qr/\Q$cluster\E/,
        'SUMMARY nests specialist evidence beneath the stable overview',
    );
    like(
        $summary,
        qr{\[Backlog: Future HIAL/VIAL Verification\]\(14e-hial-vial-verification[.]md\)},
        'SUMMARY labels the backlog as future work',
    );

    for my $path (qw(
        14e-hial-vial-verification.md
        16d-hial-vial-verification-architecture.md
        16dg-vial-public-lifecycle-reference.md
        16dh-vial-ahb-end-to-end-tutorial.md
        16di-vial-legacy-migration.md
        16dj-vial-capability-support-reference.md
        16da-vial-balanced-portable-composition.md
        16db-vial-structural-backend-emission-matrix.md
        16dc-vial-portable-verilator-runtime-measurement.md
        16dd-vial-portable-vhdl-runtime-measurement.md
        16de-vial-osvvm-runtime-execution-plan.md
        16df-vial-architecture-scale-cap-closeout.md
    )) {
        ok(-f File::Spec->catfile($book_root, $path), "$path exists");
    }
};

subtest 'backlog contains future work rather than implementation history' => sub {
    like(
        $backlog,
        qr/^This page contains future work only[.]/m,
        'backlog declares its future-only role',
    );
    unlike(
        $backlog,
        qr/\b(?:Completed|Implementation parent|Clean [^\n]* commit|Status:)\b/,
        'backlog contains no implementation-progress narration',
    );
    for my $direction (
        'Native-UVM product runtime',
        'Additional VHDL profiles',
        'Mixed-language execution',
        'Broader result parity',
        'Capacity or support promotion',
        'Expressive VIAL families',
        'Native intent simulation',
    ) {
        like($backlog, qr/\Q$direction\E/, "$direction remains explicit");
    }
    like(
        $backlog,
        qr{\Q./bin/fsmgen vial capabilities --json\E},
        'backlog routes mutable status to public machine truth',
    );
};

subtest 'overview separates public, private, review, unavailable, and evidence' => sub {
    is(
        $tooling->{status},
        'shipped_public_verilator_execution_result_and_ahb_parity',
        'public tooling authority reports shipped execution/result/parity',
    );
    is(
        $vhdl->{status},
        'shipped_private_portable_and_osvvm_qualified_profiles',
        'VHDL authority reports qualified private profiles',
    );
    is(
        $vhdl->{backend_stage_status}{product_support},
        'qualified_private_fixture_profile_not_public_api',
        'VHDL qualification is not misreported as a public API',
    );
    is(
        $uvm->{status},
        'shipped_private_selected_matrix_and_review_workflow',
        'native-UVM authority reports review emission',
    );
    is(
        $uvm->{backend_stage_status}{runtime},
        'not_run',
        'native-UVM product runtime remains unqualified',
    );
    ok(
        !$uvm->{experimental_probe}{product_support},
        'native-UVM experimental probe carries no product support',
    );
    ok(
        !$tooling->{architecture_scale_regression}{supported_claim}
            {capacity_claim},
        'bounded regression authority carries no capacity claim',
    );
    ok(
        scalar(grep { $_ eq 'mixed_language' }
            @{$tooling->{explicit_nonclaims}}),
        'public authority keeps mixed-language execution a nonclaim',
    );

    my @errors = availability_errors($overview, $tooling);
    is_deeply(
        \@errors,
        [],
        'human entry table agrees with the machine-owned boundaries',
    );
};

subtest 'entry-path category mutations fail closed' => sub {
    for my $category (
        '**Public and shipped**',
        '**Qualified, private**',
        '**Review or experiment evidence**',
        '**Unavailable**',
        '**Regression evidence, not support**',
    ) {
        my $mutated = $overview;
        $mutated =~ s/\Q$category\E/removed-category/
            or die "cannot mutate $category\n";
        ok(
            scalar(availability_errors($mutated, $tooling)),
            "$category removal is rejected",
        );
    }
};

done_testing;

sub availability_errors {
    my ($text, $public) = @_;
    my @errors;

    for my $token (
        '**Public and shipped**',
        '**Qualified, private**',
        '**Review or experiment evidence**',
        '**Unavailable**',
        '**Regression evidence, not support**',
        '`sv_portable_verilator`',
        'not accepted by public `vial run`',
        'Native-UVM deterministic emission is review-only',
        'supported native-UVM product runtime and mixed-language HIAL/VIAL execution are not available',
        'does not establish product capacity or widen backend support',
    ) {
        push @errors, "missing $token" if index($text, $token) < 0;
    }

    for my $action (@{$public->{supported_actions}}) {
        push @errors, "missing action $action"
            if index($text, $action) < 0;
    }
    push @errors, 'stale VHDL parent status'
        if index($text, 'Implementation parent `.15` is active') >= 0;
    for my $stale_progress (
        'owned by later slices of the active generator task',
        'Backend-emission hardening is now active',
        'Active `.17.4.8`',
        'Cap hardening is now active under `.17.4`',
        'backend-emission cap hardening is now active',
        'Measurement is active under `.17.3`',
    ) {
        push @errors, "stale progress narration $stale_progress"
            if index($text, $stale_progress) >= 0;
    }

    return @errors;
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read '$path': $!";
    local $/;
    my $text = <$fh>;
    close $fh or die "cannot close '$path': $!";
    return $text;
}

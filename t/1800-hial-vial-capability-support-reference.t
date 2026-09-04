#!/usr/bin/env perl

use v5.20;
use strict;
use warnings;

use Digest::SHA qw(sha256_hex);
use File::Spec;
use FindBin;
use IPC::Open3 qw(open3);
use JSON::PP ();
use Symbol qw(gensym);
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
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
my $fsmgen = repo_path(qw(bin fsmgen));
my $ci = repo_path(qw(bin ci-regression));
my $chapter = slurp(repo_path(qw(
    docs book src 16dj-vial-capability-support-reference.md
)));
my $summary = slurp(repo_path(qw(docs book src SUMMARY.md)));
my @route_sources = map { [$_->[0], slurp(repo_path(@{$_->[1]}))] } (
    ['architecture overview', [qw(
        docs book src 16d-hial-vial-verification-architecture.md
    )]],
    ['public lifecycle', [qw(
        docs book src 16dg-vial-public-lifecycle-reference.md
    )]],
    ['AHB tutorial', [qw(
        docs book src 16dh-vial-ahb-end-to-end-tutorial.md
    )]],
    ['migration guide', [qw(
        docs book src 16di-vial-legacy-migration.md
    )]],
);
my $tooling = build_vial_tooling_contract();
my $native_uvm = build_vial_native_uvm_emission_contract();
my $vhdl = build_vial_vhdl_emission_contract();
my $manifest = build_capability_manifest();

subtest 'public commands and in-process contracts publish one machine truth' => sub {
    my ($vial_status, $vial_out, $vial_err) = run_command(
        $^X, $fsmgen, qw(vial capabilities --json),
    );
    is($vial_status, 0, 'VIAL-only capability command succeeds');
    is($vial_err, '', 'VIAL-only capability command is quiet on stderr');
    my $vial_result = JSON::PP->new->decode($vial_out);
    for my $key (sort keys %{$vial_result->{capability_evidence}}) {
        is_deeply(
            $vial_result->{capability_evidence}{$key},
            $tooling->{$key},
            "VIAL-only $key equals the complete tooling contract field",
        );
    }

    my ($manifest_status, $manifest_out, $manifest_err) = run_command(
        $^X, $fsmgen, '--capability-manifest',
    );
    is($manifest_status, 0, 'complete capability command succeeds');
    is($manifest_err, '', 'complete capability command is quiet on stderr');
    my $cli_manifest = JSON::PP->new->decode($manifest_out);
    is_deeply($cli_manifest, $manifest,
        'complete CLI manifest equals the in-process authority');
    is_deeply($cli_manifest->{language_surface}{vial_tooling}, $tooling,
        'complete manifest embeds the full public tooling contract');
    is_deeply(
        $cli_manifest->{language_surface}{vial_native_uvm_emission},
        $native_uvm,
        'complete manifest embeds canonical native-UVM evidence',
    );
    is_deeply(
        $cli_manifest->{language_surface}{vial_vhdl_emission},
        $vhdl,
        'complete manifest embeds canonical portable-VHDL/OSVVM evidence',
    );
    is_deeply($tooling->{supported_actions},
        [qw(capabilities check format plan run)],
        'public action set is exact');
};

subtest 'reader routes and exact profile matrix agree with machine stages' => sub {
    like(
        $summary,
        qr{^    - \[VIAL Capability, Support, Parity, and Troubleshooting Reference\]\(16dj-vial-capability-support-reference[.]md\)$}m,
        'SUMMARY exposes the selected reference',
    );
    for my $source (@route_sources) {
        like(
            $source->[1],
            qr{\[capability and support reference\]\(16dj-vial-capability-support-reference[.]md\)},
            "$source->[0] routes the selected reference",
        );
    }

    my $experiment = $native_uvm->{experimental_probe};
    my $advanced = $vhdl->{methodology_identity}{advanced_profile};
    is($tooling->{status},
        'shipped_public_verilator_execution_result_and_ahb_parity',
        'public tooling is shipped through result and selected parity');
    is($native_uvm->{backend_stage_status}{runtime}, 'not_run',
        'ordinary native-UVM runtime remains not run');
    is($native_uvm->{backend_stage_status}{manual_review},
        'workflow_available_review_pending',
        'native-UVM manual review remains pending');
    ok(!$experiment->{product_support},
        'experimental UVM observation carries no product support');
    is($experiment->{stage_status}{generated_fixture_parse},
        'unsupported_tool_limitation',
        'experimental generated fixture records the tool parse limitation');
    is($experiment->{stage_status}{generated_fixture_runtime}, 'not_run',
        'experimental generated fixture runtime remains absent');
    is($vhdl->{backend_stage_status}{product_support},
        'qualified_private_fixture_profile_not_public_api',
        'VHDL qualification remains private');
    is($vhdl->{backend_stage_status}{runtime},
        'passed_bounded_selected_fixture',
        'portable VHDL retains its bounded runtime qualification');
    is($vhdl->{backend_stage_status}{osvvm_combined_qualification},
        'passed_exact_osvvm_2026_05_ghdl_6_0_0_bounded_profile',
        'OSVVM retains its exact combined qualification');

    my @expected_profiles = (
        ['sv_portable_verilator', 'public and shipped'],
        [$native_uvm->{profile}, 'shipped private review emission'],
        [$experiment->{profile}, 'unqualified experimental evidence'],
        ['sv_uvm_qualified', 'unavailable'],
        [$vhdl->{profile}, 'qualified private fixture profile'],
        [$advanced, 'qualified private fixture profile'],
        ['mixed_language_qualified', 'unavailable'],
    );
    is_deeply(
        [profile_rows($chapter)],
        \@expected_profiles,
        'human profile rows and availability are exact and ordered',
    );
    is_deeply([reference_errors($chapter)], [],
        'the reference retains every selected boundary');
};

subtest 'support accounting and diagnostics are complete machine projections' => sub {
    my @machine_support = map {
        [@{$_}{qw(id classification coverage)}]
    } grep {
        ($_->{source_kind} // '') eq 'vial'
    } @{$manifest->{support_accounting}{catalog_entries}};
    is_deeply(
        [support_rows($chapter)],
        \@machine_support,
        'all VIAL support-accounting rows match the manifest exactly',
    );
    ok(!(grep { $_->[1] ne 'supported_smoke' } @machine_support),
        'each current VIAL accounting row has the exercised smoke class');
    like($chapter,
        qr{`supported_smoke` describes the repository's exercised evidence class},
        'guide does not equate accounting class with backend availability');

    my @documented = public_diagnostics($chapter, $tooling->{diagnostics});
    is_deeply(
        [sort @documented],
        [sort @{$tooling->{diagnostics}}],
        'diagnostic table contains every and only public VIAL code',
    );
    like($chapter, qr{`VIAL_UVM_BACKEND_UNSUPPORTED` is private},
        'private UVM negotiation remains separate from the public code');
};

subtest 'documented checks preserve provider, scale, and cleanup boundaries' => sub {
    my @gallery_checks = (
        [
            [qw(scripts refresh_vial_native_uvm_gallery.pl)],
            qr{^native UVM gallery current:},
        ],
        [
            [qw(scripts refresh_vial_vhdl_portable_gallery.pl)],
            qr{^portable VHDL semantics gallery current:},
        ],
        [
            [qw(scripts refresh_vial_vhdl_osvvm_gallery.pl)],
            qr{^OSVVM 2026[.]05 VHDL gallery current:},
        ],
    );
    for my $check (@gallery_checks) {
        my ($status, $out, $err) = run_command(
            $^X, repo_path(@{$check->[0]}), '--check',
        );
        is($status, 0, "$check->[0][-1] succeeds");
        like($out, $check->[1], "$check->[0][-1] reports current evidence");
        is($err, '', "$check->[0][-1] is quiet on stderr");
    }

    my $uvm_source = repo_path(qw(
        .artifacts cache uvm-verilator
        656f20d087370a7c742e00188d20bbf30fa95339 source
    ));
    my ($probe_status, $probe_out, $probe_err) = run_command(
        $^X, repo_path(qw(scripts run_vial_native_uvm_experimental_probe.pl)),
        '--check',
    );
    if (-d $uvm_source && !-l $uvm_source) {
        is($probe_status, 0, 'provider-present experimental recheck succeeds');
        like($probe_out, qr{^native UVM experimental report current:},
            'provider-present recheck reports current evidence');
        is($probe_err, '', 'provider-present recheck is quiet on stderr');
    }
    else {
        is($probe_status, 2,
            'provider-absent experimental recheck reports unavailable input');
        is($probe_out, '', 'provider-absent recheck writes no stdout');
        like($probe_err, qr{VIAL_UVM_PROBE_PATH_ERROR},
            'provider-absent recheck retains its exact diagnostic');
    }

    my $scale = $tooling->{architecture_scale_regression};
    ok(!$scale->{supported_claim}{capacity_claim},
        'public regression contract carries no capacity claim');
    ok(!$scale->{supported_claim}{support_promotion},
        'public regression contract carries no support promotion');
    my $latest = repo_path(split m{/},
        $scale->{latest_result}{publication_relative_path});
    my $before = file_state($latest);
    my ($dry_status, $dry_out, $dry_err) = run_command(
        $ci, qw(vial-gate --dry-run --no-book),
    );
    is($dry_status, 0, 'documented scale dry run succeeds');
    is($dry_err, '', 'scale dry run is quiet on stderr');
    for my $step (qw(
        materialize_vial_regression_promotion_gate_evidence.pl
        verify_vial_regression_promotion_current_corpus.pl
        verify_vial_regression_promotion_budget_qualification.pl
        run_vial_regression_promotion_gate.pl
    )) {
        like($dry_out, qr{\Q$step\E}, "dry run includes $step");
    }
    is_deeply(file_state($latest), $before,
        'dry run does not mutate the latest observation');

    for my $token (
        $vhdl->{tool_selection}{exact_version},
        $vhdl->{methodology_identity}{advanced_provider},
        $scale->{capability},
        $scale->{latest_result}{publication_relative_path},
        'unavailable`, never pass',
        'performance override.',
        'never broadly',
    ) {
        like($chapter, qr{\Q$token\E}, "guide retains $token");
    }
};

subtest 'hostile status, support, scale, diagnostic, and cleanup edits fail' => sub {
    my @cases = (
        ['public/private inversion', sub {
            my ($text) = @_;
            $text =~ s/Only the first row is a public `vial run` backend/Every row is a public `vial run` backend/
                or die "public/private mutation did not match\n";
            return $text;
        }],
        ['experimental support promotion', sub {
            my ($text) = @_;
            $text =~ s/`product_support=false`/`product_support=true`/
                or die "experiment mutation did not match\n";
            return $text;
        }],
        ['qualified UVM promotion', sub {
            my ($text) = @_;
            $text =~ s/(`sv_uvm_qualified` \| )unavailable/$1public and shipped/
                or die "qualified UVM mutation did not match\n";
            return $text;
        }],
        ['mixed-language promotion', sub {
            my ($text) = @_;
            $text =~ s/(`mixed_language_qualified` \| )unavailable/$1qualified/
                or die "mixed-language mutation did not match\n";
            return $text;
        }],
        ['capacity promotion', sub {
            my ($text) = @_;
            $text =~ s/The gate does not prove architecture-scale capacity/The gate proves architecture-scale capacity/
                or die "capacity mutation did not match\n";
            return $text;
        }],
        ['missing public diagnostic', sub {
            my ($text) = @_;
            $text =~ s/`VIAL_RUN_RESULT_ERROR`, //
                or die "diagnostic mutation did not match\n";
            return $text;
        }],
        ['broad cleanup permission', sub {
            my ($text) = @_;
            $text =~ s/never broadly/freely/
                or die "cleanup mutation did not match\n";
            return $text;
        }],
    );

    for my $case (@cases) {
        my ($name, $mutate) = @{$case};
        ok(scalar(reference_errors($mutate->($chapter))),
            "$name is rejected");
    }
};

done_testing;

sub reference_errors {
    my ($text) = @_;
    my @errors;
    my @expected_profiles = (
        ['sv_portable_verilator', 'public and shipped'],
        [$native_uvm->{profile}, 'shipped private review emission'],
        [$native_uvm->{experimental_probe}{profile},
            'unqualified experimental evidence'],
        ['sv_uvm_qualified', 'unavailable'],
        [$vhdl->{profile}, 'qualified private fixture profile'],
        [$vhdl->{methodology_identity}{advanced_profile},
            'qualified private fixture profile'],
        ['mixed_language_qualified', 'unavailable'],
    );
    push @errors, 'profile matrix differs'
        unless rows_equal([profile_rows($text)], \@expected_profiles);

    my @expected_support = map {
        [@{$_}{qw(id classification coverage)}]
    } grep {
        ($_->{source_kind} // '') eq 'vial'
    } @{$manifest->{support_accounting}{catalog_entries}};
    push @errors, 'support table differs'
        unless rows_equal([support_rows($text)], \@expected_support);

    my @documented = public_diagnostics($text, $tooling->{diagnostics});
    push @errors, 'public diagnostics differ'
        unless join("\0", sort @documented)
            eq join("\0", sort @{$tooling->{diagnostics}});

    for my $token (
        './bin/fsmgen vial capabilities --json',
        './bin/fsmgen --capability-manifest',
        'Only the first row is a public `vial run` backend',
        'VIAL_BACKEND_UNSUPPORTED',
        '`supported_smoke` describes the repository\'s exercised evidence class',
        'product_support=false',
        'There is no corresponding command for `sv_uvm_qualified`',
        'not general cross-backend parity',
        'The gate does not prove architecture-scale capacity',
        'performance override.',
        'VIAL_UVM_PROBE_PATH_ERROR',
        'never broadly',
        '.artifacts/manual/vial-capability-reference-run',
        't/1800-hial-vial-capability-support-reference.t',
    ) {
        push @errors, "missing token $token" if index($text, $token) < 0;
    }
    for my $command (
        'perl scripts/refresh_vial_native_uvm_gallery.pl --check',
        'perl scripts/run_vial_native_uvm_experimental_probe.pl --check',
        'perl scripts/refresh_vial_vhdl_portable_gallery.pl --check',
        'perl scripts/refresh_vial_vhdl_osvvm_gallery.pl --check',
        'perl scripts/run_vial_vhdl_portable_ghdl_qualification.pl --check',
        'perl scripts/run_vial_vhdl_osvvm_ghdl_qualification.pl --check',
        './bin/ci-regression vial-gate --dry-run --no-book',
    ) {
        my $flat = $text;
        $flat =~ s/\\\n\s*/ /g;
        push @errors, "missing command $command"
            if index($flat, $command) < 0;
    }
    return @errors;
}

sub profile_rows {
    my ($text) = @_;
    my ($section) = $text =~ /## Exact profile matrix\n(.*?)(?=\n## Support accounting)/s;
    return () unless defined $section;
    my @rows;
    while ($section =~ /^\| `([^`]+)` \| ([^|]+?) \|/mg) {
        push @rows, [$1, trim($2)];
    }
    return @rows;
}

sub support_rows {
    my ($text) = @_;
    my ($section) = $text =~ /## Support accounting is not backend availability\n(.*?)(?=\n## Recheck)/s;
    return () unless defined $section;
    my @rows;
    while ($section =~ /^\| `([^`]+)` \| `([^`]+)` \| `([^`]+)` \|$/mg) {
        push @rows, [$1, $2, $3];
    }
    return @rows;
}

sub public_diagnostics {
    my ($text, $public) = @_;
    my ($section) = $text =~ /## Interpret diagnostics by phase\n(.*?)(?=\n## Artifact and cleanup rules)/s;
    return () unless defined $section;
    my %wanted = map { $_ => 1 } @{$public};
    my %seen;
    for my $code ($section =~ /`(VIAL_[A-Z0-9_]+)`/g) {
        $seen{$code} = 1 if $wanted{$code};
    }
    return sort keys %seen;
}

sub rows_equal {
    my ($actual, $expected) = @_;
    return 0 unless @{$actual} == @{$expected};
    for my $index (0 .. $#{$actual}) {
        return 0 unless join("\0", @{$actual->[$index]})
            eq join("\0", @{$expected->[$index]});
    }
    return 1;
}

sub run_command {
    my (@command) = @_;
    my $stderr = gensym;
    my $pid = open3(my $stdin, my $stdout, $stderr, @command);
    close $stdin;
    local $/;
    my $out = <$stdout> // '';
    my $err = <$stderr> // '';
    waitpid($pid, 0);
    return ($? >> 8, $out, $err);
}

sub file_state {
    my ($path) = @_;
    return {exists => JSON::PP::false} unless -e $path;
    my $bytes = slurp($path);
    return {
        exists => JSON::PP::true,
        bytes => length($bytes),
        sha256 => sha256_hex($bytes),
    };
}

sub trim {
    my ($text) = @_;
    $text =~ s/^\s+|\s+$//g;
    return $text;
}

sub repo_path {
    return File::Spec->catfile($repo_root, @_);
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read '$path': $!";
    local $/;
    my $text = <$fh>;
    close $fh or die "cannot close '$path': $!";
    return $text;
}

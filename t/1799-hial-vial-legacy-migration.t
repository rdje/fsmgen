#!/usr/bin/env perl

use v5.20;
use strict;
use warnings;

use Digest::SHA qw(sha256_hex);
use File::Path qw(make_path remove_tree);
use File::Spec;
use FindBin;
use IPC::Open3 qw(open3);
use JSON::PP ();
use Symbol qw(gensym);
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::VIALExecutionContract qw(build_vial_execution_contract);
use FSM::Support::VIALToolingContract qw(build_vial_tooling_contract);
use FSM::VIAL::Tool qw(execute_vial_tool_request);

my $repo_root = File::Spec->rel2abs(
    File::Spec->catdir($FindBin::Bin, '..'),
);
my $chapter = slurp(repo_path(qw(
    docs book src 16di-vial-legacy-migration.md
)));
my $summary = slurp(repo_path(qw(docs book src SUMMARY.md)));
my $overview = slurp(repo_path(qw(
    docs book src 16d-hial-vial-verification-architecture.md
)));
my $lifecycle = slurp(repo_path(qw(
    docs book src 16dg-vial-public-lifecycle-reference.md
)));
my $tutorial = slurp(repo_path(qw(
    docs book src 16dh-vial-ahb-end-to-end-tutorial.md
)));
my $knowledge = slurp(repo_path(qw(
    docs knowledge hial-vial-verification-fixture-architecture.md
)));
my $observation_source_id = 'isf/verification_observation_metadata.isf';
my $vial_id = 'vial/ahb_subordinate_base_output_arbitration.vial';
my $hial_id = 'ppif/ahb_lite_subordinate.ppif';
my $baseline_id =
    't/data/ahb_generated_subordinate_base_output_arbitration_tb.svt';
my $observation_source = slurp(repo_path(split m{/}, $observation_source_id));
my $vial_source = slurp(repo_path(split m{/}, $vial_id));
my $hial_source = slurp(repo_path(split m{/}, $hial_id));
my $baseline = slurp(repo_path(split m{/}, $baseline_id));
my $observation_test = slurp(repo_path(qw(
    t 1260-isf-verification-observation-metadata.t
)));
my $uvm_test = slurp(repo_path(qw(
    t 1464-isf-verification-output-uvm-passive-monitor.t
)));
my $vhdl_test = slurp(repo_path(qw(
    t 1465-isf-verification-output-vhdl-observation-package.t
)));
my $parity_test = slurp(repo_path(qw(t 1559-vial-ahb-runtime-parity.t)));
my $parity_module = slurp(repo_path(qw(
    perl FSM VIAL Parity AHBBaseOutput.pm
)));
my $native_gallery = slurp(repo_path(qw(
    vial review_gallery sv_uvm_emit.accellera_2020_3_1
    ahb_base_output_foundation README.md
)));
my $vhdl_migration = decode_file(repo_path(qw(
    vial review_gallery vhdl_portable_ghdl
    ahb_base_output_portable_semantics evidence migration-proof.json
)));
my $osvvm_preservation = decode_file(repo_path(qw(
    vial review_gallery vhdl_osvvm_qualified
    ahb_base_output_advanced_services evidence semantic-preservation.json
)));
my $capability_manifest = build_capability_manifest();
my $tooling = build_vial_tooling_contract();
my $execution = build_vial_execution_contract();
my $json = JSON::PP->new->canonical;
my $test_root_rel = ".artifacts/test/hial-vial-legacy-migration-$$";
my $test_root = repo_path(split m{/}, $test_root_rel);

END {
    remove_tree($test_root)
        if defined($test_root) && -d $test_root && !-l $test_root;
}

subtest 'book and Knowledge Map publish one explicit migration route' => sub {
    like(
        $summary,
        qr{^    - \[Migrating Legacy Verification to VIAL\]\(16di-vial-legacy-migration[.]md\)$}m,
        'SUMMARY nests the migration guide in the selected reader path',
    );
    for my $pair (
        [$overview, 'architecture overview'],
        [$lifecycle, 'public lifecycle'],
        [$tutorial, 'AHB tutorial'],
    ) {
        like(
            $pair->[0],
            qr{\[legacy migration guide\]\(16di-vial-legacy-migration[.]md\)},
            "$pair->[1] routes the selected migration guide",
        );
    }
    like(
        $knowledge,
        qr{docs/book/src/16di-vial-legacy-migration[.]md},
        'the canonical Knowledge Card routes the migration guide',
    );
    like(
        $knowledge,
        qr{t/1799-hial-vial-legacy-migration[.]t},
        'the canonical Knowledge Card retains this watcher',
    );
    is_deeply(
        [migration_errors($chapter)],
        [],
        'guide carries every selected state, command, boundary, and nonclaim',
    );
};

subtest 'retained observation metadata and both inert outputs execute exactly' => sub {
    make_path($test_root);
    my $source_sha = sha256_hex($observation_source);

    my ($schedule_status, $schedule_out, $schedule_err) = run_fsmgen(
        '--emit-schedule-json', $observation_source_id,
    );
    is($schedule_status, 0, 'documented schedule projection exits zero');
    is($schedule_err, '', 'schedule projection emits no diagnostic');
    my $schedule = $json->decode($schedule_out);
    is($schedule->{verification_bridge}, undef,
        'ordinary retained IAL1 report has a null bridge annotation');
    is_deeply(
        $schedule->{verification_observations},
        [{
            name => 'link_rx',
            role => 'passive_monitor',
            clock => 'clk',
            reset => {
                name => 'rst_n',
                kind => 'async',
                polarity => 'active_low',
            },
            signals => [
                {name => 'valid', direction => 'input', width => 1},
                {name => 'ready', direction => 'output', width => 1},
                {name => 'data', direction => 'input', width => 8},
            ],
        }],
        'schedule report preserves the exact source-ordered observation',
    );
    like(
        $observation_test,
        qr{observe metadata does not create scheduled [. ]fsm content},
        'independent observation test preserves the report-only boundary',
    );

    my $uvm_rel = "$test_root_rel/uvm";
    my ($uvm_status, $uvm_out, $uvm_err) = run_fsmgen(
        '--quiet', '--emit-verification-output', 'uvm-passive-monitor',
        '--verification-outdir', $uvm_rel, $observation_source_id,
    );
    is($uvm_status, 0, 'retained UVM skeleton command exits zero');
    is($uvm_out . $uvm_err, '', 'quiet UVM skeleton command is silent');
    is_deeply(
        [tree_files(repo_path(split m{/}, $uvm_rel))],
        [
            'uvm/verification_observation_metadata_observation_uvm_pkg.sv',
            'verification-output-manifest.json',
        ],
        'UVM compatibility output has the documented two-file tree',
    );
    my $uvm_manifest = decode_file(repo_path(
        split(m{/}, "$uvm_rel/verification-output-manifest.json"),
    ));
    my $uvm_package = slurp(repo_path(split m{/},
        "$uvm_rel/uvm/verification_observation_metadata_observation_uvm_pkg.sv",
    ));
    assert_manifest_matches_public_target(
        $uvm_manifest,
        'uvm_passive_monitor_skeleton',
        'uvm-passive-monitor',
    );
    is($uvm_manifest->{artifacts}[0]{uvm_version}, '1.2',
        'retained UVM revision remains exact');
    ok(!$uvm_manifest->{validation}{claimed_uvm_compile_support},
        'retained manifest claims no UVM compile support');
    is($uvm_manifest->{validation}{uvm_compile_validator}, 'none',
        'retained manifest records no UVM compiler');
    like($uvm_package, qr{class link_rx_snapshot extends uvm_sequence_item;},
        'snapshot declaration remains present');
    like($uvm_package, qr{class link_rx_monitor extends uvm_monitor;},
        'monitor declaration remains present');
    for my $forbidden (
        qr{run_phase}, qr{virtual\s+interface}, qr{uvm_config_db},
        qr{observed_ap[.]write}, qr{scoreboard}i, qr{coverage}i,
    ) {
        unlike($uvm_package, $forbidden, 'UVM compatibility package stays inert');
    }
    like($uvm_test, qr{claimed_uvm_compile_support},
        'independent UVM regression owns the compile nonclaim');

    my $vhdl_rel = "$test_root_rel/vhdl";
    my ($vhdl_status, $vhdl_out, $vhdl_err) = run_fsmgen(
        '--quiet', '--emit-verification-output', 'vhdl-observation-package',
        '--verification-outdir', $vhdl_rel, $observation_source_id,
    );
    is($vhdl_status, 0, 'retained VHDL skeleton command exits zero');
    is($vhdl_out . $vhdl_err, '', 'quiet VHDL skeleton command is silent');
    is_deeply(
        [tree_files(repo_path(split m{/}, $vhdl_rel))],
        [
            'verification-output-manifest.json',
            'vhdl/verification_observation_metadata_observation_vhdl_pkg.vhd',
        ],
        'VHDL compatibility output has the documented two-file tree',
    );
    my $vhdl_manifest = decode_file(repo_path(
        split(m{/}, "$vhdl_rel/verification-output-manifest.json"),
    ));
    my $vhdl_package = slurp(repo_path(split m{/},
        "$vhdl_rel/vhdl/verification_observation_metadata_observation_vhdl_pkg.vhd",
    ));
    assert_manifest_matches_public_target(
        $vhdl_manifest,
        'vhdl_observation_package_skeleton',
        'vhdl-observation-package',
    );
    ok(!$vhdl_manifest->{validation}{claimed_vhdl_compile_support},
        'retained VHDL manifest claims no compile support');
    ok(!$vhdl_manifest->{validation}{claimed_psl_support},
        'retained VHDL manifest claims no PSL support');
    is($vhdl_manifest->{validation}{vhdl_syntax_validator}, 'none',
        'retained VHDL manifest records no syntax validator');
    like($vhdl_package, qr{LINK_RX_OBSERVATION_NAME : string := "link_rx";},
        'VHDL observation metadata remains present');
    for my $forbidden (
        qr{\bentity\b}i, qr{\barchitecture\b}i, qr{\bprocess\b}i,
        qr{\bassert\b}i, qr{\bpsl\b}i, qr{scoreboard}i, qr{coverage}i,
    ) {
        unlike($vhdl_package, $forbidden, 'VHDL compatibility package stays inert');
    }
    like($vhdl_test, qr{claimed_vhdl_compile_support},
        'independent VHDL regression owns the compile nonclaim');
    is(
        sha256_hex(slurp(repo_path(split m{/}, $observation_source_id))),
        $source_sha,
        'side-by-side generation leaves the retained source byte-identical',
    );
};

subtest 'typed VIAL plan is separate from every legacy artifact' => sub {
    make_path($test_root);
    my $plan_rel = "$test_root_rel/plan";
    my ($status, $out, $err) = run_fsmgen(
        'vial', 'plan',
        '--dut', $hial_id,
        '--fixture', 'base_output_arbitration',
        '--profile', 'core_directed_single_clock_execution_v1',
        '--outdir', $plan_rel,
        $vial_id,
    );
    is($status, 0, 'documented migration plan exits zero');
    is($out, "VIAL plan planned ($plan_rel)\n",
        'migration plan reports the exact publication root');
    is($err, '', 'migration plan emits no diagnostic');

    my @paths = tree_files(repo_path(split m{/}, $plan_rel));
    is_deeply(
        \@paths,
        [qw(
            hial-vial-bridge.json
            review/ahb_lite_subordinate.fsm
            review/ahb_lite_subordinate.isf
            source/vial-normal.vial
            vial-plan.json
            vial-tool-manifest.json
        )],
        'migration plan publishes only the target-neutral review tree',
    );
    ok(
        !(grep { /observation_(?:uvm|vhdl)_pkg|verification-output-manifest/ }
            @paths),
        'target-neutral VIAL plan contains no legacy package or manifest',
    );

    my $bridge = decode_file(repo_path(
        split(m{/}, "$plan_rel/hial-vial-bridge.json"),
    ));
    is($bridge->{schema}, 'fsmgen.hial_vial_bridge_manifest.v1',
        'bridge schema is exact');
    is_deeply(
        [map { $_->{layer} } @{$bridge->{review_route}{stages}}],
        [qw(IAL2 IAL1 IAL0)],
        'migration preserves the reviewable HIAL route');
    ok(!$bridge->{review_route}{direct_ial2_to_verification},
        'migration creates no direct IAL2 verification shortcut');
    is_deeply($bridge->{observations}, [],
        'checked AHB HIAL adds no invented legacy observation');
    is_deeply(
        [map {
            [$_->{probe_id}, $_->{access}, $_->{adapter_requirement}]
        } @{$bridge->{probes}}],
        [[
            'probe/reg_data_q',
            'verification_probe',
            'equivalent_adapter_required',
        ]],
        'storage access uses one declared typed probe and adapter contract',
    );
    my %endpoint = map { $_->{endpoint_id} => $_ } @{$bridge->{endpoints}};
    for my $id (qw(endpoint/HREADYOUT endpoint/HRESP endpoint/HRDATA)) {
        is($endpoint{$id}{access}, 'public_port', "$id remains a public port");
    }
    unlike(
        $json->encode($bridge->{probes}),
        qr{dut[.]reg_data_q},
        'bridge exposes no backend hierarchy path',
    );

    my $plan = decode_file(repo_path(split(m{/}, "$plan_rel/vial-plan.json")));
    is($plan->{schema}, $execution->{plan_schema}, 'plan schema is machine-derived');
    is_deeply($plan->{logical_time}{phase_order},
        [qw(drive sample react check)], 'logical phase order is exact');

    my $sink = [];
    my $unsupported = execute_vial_tool_request(
        run_request('sv_uvm_qualified'),
        {
            source_catalog => {},
            artifact_sink => $sink,
            repository_root => $repo_root,
        },
    );
    ok(!$unsupported->{success}, 'unavailable native-UVM public run fails');
    is($unsupported->{diagnostics}[0]{code}, 'VIAL_BACKEND_UNSUPPORTED',
        'unavailable public backend diagnostic is exact');
    is_deeply($sink, [], 'unavailable backend publishes no artifact');
    is($unsupported->{bridge_manifest}, undef,
        'unavailable backend publishes no bridge');
    is($unsupported->{plan}, undef, 'unavailable backend publishes no plan');
    is($unsupported->{result_manifest}, undef,
        'unavailable backend invents no result');
};

subtest 'parallel successors and handwritten-oracle retention stay exact' => sub {
    my @gallery_checks = (
        [
            [qw(scripts refresh_vial_native_uvm_gallery.pl)],
            "native UVM gallery current: 9 source snapshots; 2 review evidence files; 75 source-map entries; 14 static checks; 5 review-closure checks\n",
        ],
        [
            [qw(scripts refresh_vial_vhdl_portable_gallery.pl)],
            "portable VHDL semantics gallery current: 6 VHDL sources; 11 evidence artifacts; 59 source-map entries; 21 static checks; 24 mappings; 7 review-closure checks\n",
        ],
        [
            [qw(scripts refresh_vial_vhdl_osvvm_gallery.pl)],
            "OSVVM 2026.05 VHDL gallery current: 7 VHDL sources; 9 evidence artifacts; 7 advanced mappings; 66 source-map entries; 12 static checks\n",
        ],
    );
    for my $case (@gallery_checks) {
        my ($status, $out, $err) = run_command(
            $^X,
            repo_path(@{$case->[0]}),
            '--check',
        );
        is($status, 0, "$case->[0][-1] checked gallery is current");
        is($out, $case->[1], "$case->[0][-1] reports the exact checked census");
        is($err, '', "$case->[0][-1] emits no diagnostic");
    }

    like($native_gallery, qr{sv_uvm_emit[.]accellera_2020_3_1},
        'native successor has a separate profile identity');
    like($native_gallery, qr{not been preprocessed, parsed, compiled, elaborated, or run},
        'native gallery preserves its compile/runtime nonclaim');
    is($vhdl_migration->{schema}, 'fsmgen.vial_vhdl_migration_proof.v1',
        'portable VHDL gallery has a dedicated migration proof');
    is($vhdl_migration->{legacy_surface}{cli_target},
        'vhdl-observation-package', 'proof names the retained legacy command');
    ok(!$vhdl_migration->{legacy_surface}{consumed_by_successor},
        'portable successor does not consume the legacy package');
    is($vhdl_migration->{separation}{migration_kind},
        'parallel_versioned_surface', 'VHDL successor is explicitly parallel');
    is($vhdl_migration->{separation}{legacy_artifacts_in_successor}, 0,
        'portable successor contains no legacy artifact');
    is($vhdl_migration->{separation}{legacy_imports_in_successor}, 0,
        'portable successor contains no legacy import');
    ok($osvvm_preservation->{guards}{normalized_result_unchanged},
        'OSVVM wrapper preserves normalized-result authority');
    ok(!(grep { !$_->{byte_identical} }
        @{$osvvm_preservation->{portable_sources}}),
        'OSVVM wrapper preserves every portable source byte');

    like($baseline, qr{BASE_ASSERT_SUCCESS accepts=%0d captures=%0d holds=%0d completions=%0d ready_low=%0d storage=%08x},
        'handwritten success record format remains present');
    like($baseline, qr{BASE_ASSERT_ERROR accepts=%0d captures=%0d holds=%0d completions=%0d error_cycles=%0d storage=%08x},
        'handwritten error record format remains present');
    like($parity_test, qr{BASE_ASSERT_SUCCESS accepts=1 captures=1 holds=2 completions=1 ready_low=15 storage=cafebabe},
        'executed parity oracle retains the exact success outcome');
    like($parity_test, qr{BASE_ASSERT_ERROR accepts=1 captures=1 holds=2 completions=1 error_cycles=2 storage=00000000},
        'executed parity oracle retains the exact error outcome');
    like($parity_test, qr{byte-identical DUT source from the public VIAL graph},
        'independent parity test preserves identical-DUT proof');
    like($parity_test, qr{not declared typed VIAL probes},
        'independent parity test preserves internal-counter exclusions');
    like($parity_test, qr{storage=cafebabe/storage=deadbeef},
        'independent parity test retains a shared-outcome RED control');
    like(
        $parity_module,
        qr{my \@field = qw\(\s*scenario_id status bus_accepts ready_low_cycles response_error_cycles\s+nonzero_read_data_cycles final_ready final_response final_read_data_hex\s+storage_hex\s*\)}s,
        'parity producer retains the closed compared field family',
    );
    like($chapter, qr{all\s+nineteen compared paths},
        'guide preserves the bounded comparator cardinality');
    like($chapter, qr{not general parity},
        'guide does not generalize the retained oracle');
};

subtest 'rollback, compatibility, and hostile edits fail closed' => sub {
    for my $root (qw(
        .artifacts/manual/vial-legacy-uvm
        .artifacts/manual/vial-legacy-vhdl
        .artifacts/manual/vial-migration-plan
        .artifacts/manual/vial-migration-run
    )) {
        like($chapter, qr{rm -rf \Q$root\E},
            "cleanup names only exact root $root");
        ok(!-e repo_path(split m{/}, $root),
            "manual example root $root is absent");
    }

    for my $nonclaim (
        'automatic translation',
        'public native-UVM',
        'mixed-language execution',
        'arbitrary hierarchy access',
        'general cross-backend parity',
        'retirement or deprecation',
    ) {
        like($chapter, qr{\Q$nonclaim\E}, "guide retains nonclaim $nonclaim");
    }
    for my $token (
        '(observe ...)',
        'retain + parallel successor',
        'uvm_passive_monitor_skeleton',
        'vhdl_observation_package_skeleton',
        'sv_uvm_emit.accellera_2020_3_1',
        'fsmgen.hial_vial_bridge_manifest.v1',
        'probe/reg_data_q',
        $baseline_id,
        'VIAL_BACKEND_UNSUPPORTED',
        'not general parity',
        '.artifacts/manual/vial-migration-run',
    ) {
        my $mutated = $chapter;
        my $count = ($mutated =~ s/\Q$token\E/removed-migration-token/g);
        $count or die "cannot mutate migration token '$token'\n";
        ok(scalar(migration_errors($mutated)),
            "removing $token is rejected");
    }
};

done_testing;

sub migration_errors {
    my ($text) = @_;
    my @errors;
    for my $token (
        'retain',
        'parallel successor',
        'retain + parallel successor',
        'migrate',
        '(observe ...)',
        $observation_source_id,
        'verification_bridge: null',
        'uvm-passive-monitor',
        'uvm_passive_monitor_skeleton',
        'UVM 1.2',
        'claimed_uvm_compile_support: false',
        'sv_uvm_emit.accellera_2020_3_1',
        'vhdl-observation-package',
        'vhdl_observation_package_skeleton',
        'claimed_vhdl_compile_support: false',
        'claimed_psl_support: false',
        'vhdl_portable_ghdl',
        'vhdl_osvvm_qualified',
        $hial_id,
        $vial_id,
        'fsmgen.hial_vial_bridge_manifest.v1',
        'public_port',
        'probe/reg_data_q',
        'verification_probe',
        'equivalent_adapter_required',
        'drive -> sample -> react -> check',
        'sv_portable_verilator',
        $baseline_id,
        'vial.parity.ahb_base_output_arbitration.v1',
        'nineteen compared paths',
        'automatic translation',
        'VIAL_BACKEND_UNSUPPORTED',
        'not general parity',
        'general cross-backend parity',
        'retirement or deprecation',
    ) {
        push @errors, "missing migration token $token"
            if index($text, $token) < 0;
    }
    for my $command (
        './bin/fsmgen --emit-schedule-json',
        '--emit-verification-output uvm-passive-monitor',
        '--emit-verification-output vhdl-observation-package',
        'perl scripts/refresh_vial_native_uvm_gallery.pl --check',
        'perl scripts/refresh_vial_vhdl_portable_gallery.pl --check',
        'perl scripts/refresh_vial_vhdl_osvvm_gallery.pl --check',
        './bin/fsmgen vial plan',
        './bin/fsmgen vial run',
        './bin/fsmgen --capability-manifest',
        './bin/fsmgen vial capabilities --json',
    ) {
        push @errors, "missing migration command $command"
            if index($text, $command) < 0;
    }
    for my $root (qw(
        .artifacts/manual/vial-legacy-uvm
        .artifacts/manual/vial-legacy-vhdl
        .artifacts/manual/vial-migration-plan
        .artifacts/manual/vial-migration-run
    )) {
        push @errors, "missing migration root $root"
            if index($text, $root) < 0;
    }
    return @errors;
}

sub assert_manifest_matches_public_target {
    my ($manifest, $target_id, $cli_target) = @_;
    my ($target) = grep { $_->{id} eq $target_id }
        @{$capability_manifest->{verification_outputs}{targets}};
    ok($target, "$target_id remains publicly discoverable");
    is($target->{cli_target}, $cli_target, "$target_id CLI name is exact");
    is($target->{status}, 'shipped_bounded_public',
        "$target_id remains shipped bounded public");
    is_deeply($target->{source_suffixes}, ['.isf'],
        "$target_id remains IAL1-only");
    ok($target->{requires_verification_observations},
        "$target_id still requires observation metadata");
    is($manifest->{schema_version},
        $capability_manifest->{verification_outputs}{artifact_manifest}{schema_version},
        "$target_id manifest schema version is public-contract exact");
    is($manifest->{mode}, 'verification_output',
        "$target_id manifest mode is exact");
    is($manifest->{target}, $target_id,
        "$target_id manifest identity is exact");
    is($manifest->{actor}, 'verification_observation_metadata',
        "$target_id manifest actor is exact");
    ok($manifest->{validation}{artifact_shape_checked},
        "$target_id retains artifact-shape validation");
    ok($manifest->{validation}{inert_behavior_checked},
        "$target_id retains inert-behavior validation");
}

sub run_request {
    my ($backend) = @_;
    return {
        schema => $tooling->{request_schema},
        schema_version => 1,
        action => 'run',
        vial_source => source_envelope($vial_id, $vial_source, 'vial'),
        hial_source => source_envelope($hial_id, $hial_source, 'ppif'),
        options => {
            source_style => 'auto',
            output_style => undef,
            fixture_id => 'base_output_arbitration',
            scenario_ids => [],
            execution_profile => 'core_directed_single_clock_execution_v1',
            backend_profile => $backend,
            replay_manifest => undef,
            native_extension_catalogs => [],
            artifact_policy => {mode => 'virtual', artifact_root => undef},
            quiet => JSON::PP::false,
        },
    };
}

sub source_envelope {
    my ($source_id, $text, $kind) = @_;
    return {
        source_id => $source_id,
        source_kind_hint => $kind,
        text => $text,
        encoding => 'utf-8',
        origin => 'memory',
        display_name => $source_id,
        canonical_id => undef,
        relative_path => $source_id,
        metadata => {},
    };
}

sub run_fsmgen {
    return run_command($^X, repo_path(qw(bin fsmgen)), @_);
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

sub tree_files {
    my ($root) = @_;
    return () unless -d $root && !-l $root;
    my @files;
    walk($root, '', \@files);
    return sort @files;
}

sub walk {
    my ($root, $relative, $files) = @_;
    my $path = length($relative)
        ? File::Spec->catdir($root, split m{/}, $relative)
        : $root;
    opendir my $dh, $path or die "cannot inspect '$path': $!";
    my @entries = sort grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    closedir $dh or die "cannot close '$path': $!";
    for my $name (@entries) {
        my $rel = length($relative) ? "$relative/$name" : $name;
        my $entry = File::Spec->catfile($path, $name);
        if (-d $entry && !-l $entry) {
            walk($root, $rel, $files);
        }
        else {
            push @$files, $rel;
        }
    }
}

sub decode_file {
    my ($path) = @_;
    return JSON::PP->new->decode(slurp($path));
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

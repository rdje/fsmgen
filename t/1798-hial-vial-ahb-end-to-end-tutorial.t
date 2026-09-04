#!/usr/bin/env perl

use v5.20;
use strict;
use warnings;

use File::Path qw(make_path remove_tree);
use File::Spec;
use FindBin;
use IPC::Open3 qw(open3);
use JSON::PP ();
use Symbol qw(gensym);
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::VIALExecutionContract qw(build_vial_execution_contract);
use FSM::Support::VIALToolingContract qw(build_vial_tooling_contract);
use FSM::VIAL::Backend::ResultProducer;
use FSM::VIAL::Parser;
use FSM::VIAL::SourceProjection;
use FSM::VIAL::Tool qw(execute_vial_tool_request);

my $repo_root = File::Spec->rel2abs(
    File::Spec->catdir($FindBin::Bin, '..'),
);
my $book_root = repo_path(qw(docs book src));
my $chapter = slurp(repo_path(
    qw(docs book src 16dh-vial-ahb-end-to-end-tutorial.md),
));
my $summary = slurp(repo_path(qw(docs book src SUMMARY.md)));
my $overview = slurp(repo_path(
    qw(docs book src 16d-hial-vial-verification-architecture.md),
));
my $lifecycle = slurp(repo_path(
    qw(docs book src 16dg-vial-public-lifecycle-reference.md),
));
my $knowledge = slurp(repo_path(
    qw(docs knowledge hial-vial-verification-fixture-architecture.md),
));
my $runtime_test = slurp(repo_path(
    qw(t 1558-vial-verilator-run-integration.t),
));
my $parity_test = slurp(repo_path(
    qw(t 1559-vial-ahb-runtime-parity.t),
));
my $parity_module = slurp(repo_path(
    qw(perl FSM VIAL Parity AHBBaseOutput.pm),
));
my $portable_script = slurp(repo_path(
    qw(scripts run_vial_vhdl_portable_ghdl_qualification.pl),
));
my $osvvm_script = slurp(repo_path(
    qw(scripts run_vial_vhdl_osvvm_ghdl_qualification.pl),
));
my $portable_gallery = slurp(repo_path(qw(
    vial review_gallery vhdl_portable_ghdl
    ahb_base_output_portable_semantics README.md
)));
my $osvvm_gallery = slurp(repo_path(qw(
    vial review_gallery vhdl_osvvm_qualified
    ahb_base_output_advanced_services README.md
)));
my $portable_report = decode_file(repo_path(qw(
    vial qualification vhdl_portable_ghdl ghdl-6.0.0-qualification.json
)));
my $osvvm_report = decode_file(repo_path(qw(
    vial qualification vhdl_osvvm_ghdl
    osvvm-2026.05-ghdl-6.0.0-qualification.json
)));
my $osvvm_preservation = decode_file(repo_path(qw(
    vial review_gallery vhdl_osvvm_qualified
    ahb_base_output_advanced_services evidence semantic-preservation.json
)));
my $vial_id = 'vial/ahb_subordinate_base_output_arbitration.vial';
my $hial_id = 'ppif/ahb_lite_subordinate.ppif';
my $vial_text = slurp(repo_path(split m{/}, $vial_id));
my $hial_text = slurp(repo_path(split m{/}, $hial_id));
my $test_root_rel = ".artifacts/test/hial-vial-ahb-tutorial-$$";
my $test_root = repo_path(split m{/}, $test_root_rel);
my $tooling = build_vial_tooling_contract();
my $execution = build_vial_execution_contract();
my $json = JSON::PP->new->canonical;

my @plan_paths = qw(
    hial-vial-bridge.json
    review/ahb_lite_subordinate.fsm
    review/ahb_lite_subordinate.isf
    source/vial-normal.vial
    vial-plan.json
    vial-tool-manifest.json
);
my @runtime_paths = qw(
    backends/sv_portable_verilator/backend-manifest.json
    backends/sv_portable_verilator/backend-source-map.json
    backends/sv_portable_verilator/commands/compile-command.json
    backends/sv_portable_verilator/commands/run-command.json
    backends/sv_portable_verilator/evidence/compile-transcript.txt
    backends/sv_portable_verilator/evidence/run-transcript.txt
    backends/sv_portable_verilator/evidence/runtime-trace.jsonl
    backends/sv_portable_verilator/evidence/tool-profile.json
    backends/sv_portable_verilator/src/base_output_arbitration_tb.sv
    backends/sv_portable_verilator/src/dut/ahb-lite-subordinate.sv
    backends/sv_portable_verilator/src/fsmgen_vial_runtime_pkg.sv
    verification-output-manifest.json
);
my @outcome_fields = qw(
    scenario_id status bus_accepts ready_low_cycles response_error_cycles
    nonzero_read_data_cycles final_ready final_response final_read_data_hex
    storage_hex
);
my @parity_paths = map { "/outcomes/0/$_" } @outcome_fields;
push @parity_paths,
    map { "/outcomes/1/$_" }
    grep { $_ ne 'ready_low_cycles' } @outcome_fields;

END {
    remove_tree($test_root)
        if defined($test_root) && -d $test_root && !-l $test_root;
}

subtest 'book and Knowledge Map route one exact checked-source tutorial' => sub {
    like(
        $summary,
        qr{^    - \[End-to-End AHB HIAL/VIAL Tutorial\]\(16dh-vial-ahb-end-to-end-tutorial[.]md\)$}m,
        'SUMMARY nests the tutorial immediately below the lifecycle path',
    );
    like(
        $overview,
        qr{\[end-to-end AHB tutorial\]\(16dh-vial-ahb-end-to-end-tutorial[.]md\)},
        'the architecture overview routes readers into the tutorial',
    );
    like(
        $lifecycle,
        qr{\[end-to-end AHB tutorial\]\(16dh-vial-ahb-end-to-end-tutorial[.]md\)},
        'the public lifecycle routes readers into the tutorial',
    );
    like(
        $knowledge,
        qr{docs/book/src/16dh-vial-ahb-end-to-end-tutorial[.]md},
        'the canonical Knowledge Card routes the selected tutorial',
    );
    like(
        $knowledge,
        qr{t/1798-hial-vial-ahb-end-to-end-tutorial[.]t},
        'the Knowledge Card retains the tutorial watcher',
    );

    is_deeply(
        [tutorial_errors($chapter)],
        [],
        'the tutorial covers every selected command, artifact, result, parity, and support boundary',
    );
};

subtest 'documented check format and plan commands execute exactly' => sub {
    my ($check_status, $check_out, $check_err) = run_cli(
        'vial', 'check', '--style', 'auto', $vial_id,
    );
    is($check_status, 0, 'tutorial check command exits zero');
    is($check_out, "VIAL check passed (normal_v1)\n", 'check output is exact');
    is($check_err, '', 'check emits no diagnostic');

    my ($normal_status, $normal, $normal_err) = run_cli(
        'vial', 'format', '--style', 'normal', $vial_id,
    );
    my ($terse_status, $terse, $terse_err) = run_cli(
        'vial', 'format', '--style', 'terse', $vial_id,
    );
    is($normal_status, 0, 'normal formatter exits zero');
    is($terse_status, 0, 'terse formatter exits zero');
    is($normal_err . $terse_err, '', 'formatters emit no diagnostic');
    like($normal, qr{\A\(vial\n  \(version 1\)}, 'normal output has the documented root');
    like($terse, qr{\A\(vial 1\n}, 'terse output has the documented root');
    is(
        semantic_digest($normal),
        semantic_digest($terse),
        'normal and terse outputs reparse to one semantic meaning',
    );

    make_path($test_root);
    my $out_rel = "$test_root_rel/plan";
    my ($plan_status, $plan_out, $plan_err) = run_cli(
        'vial', 'plan',
        '--dut', $hial_id,
        '--fixture', 'base_output_arbitration',
        '--profile', 'core_directed_single_clock_execution_v1',
        '--outdir', $out_rel,
        $vial_id,
    );
    is($plan_status, 0, 'complete tutorial plan exits zero');
    is($plan_out, "VIAL plan planned ($out_rel)\n", 'first plan output is exact');
    is($plan_err, '', 'plan emits no diagnostic');
    is_deeply(
        [tree_files(repo_path(split m{/}, $out_rel))],
        \@plan_paths,
        'plan publishes the documented review tree',
    );

    my $bridge = decode_file(repo_path(
        split(m{/}, "$out_rel/hial-vial-bridge.json"),
    ));
    is_deeply(
        [map { $_->{layer} } @{$bridge->{review_route}{stages}}],
        [qw(IAL2 IAL1 IAL0)],
        'checked PPIF follows the documented review route',
    );
    ok(
        !$bridge->{review_route}{direct_ial2_to_verification},
        'bridge explicitly denies a direct IAL2 verification shortcut',
    );
    is_deeply(
        [map { $_->{probe_id} } @{$bridge->{probes}}],
        ['probe/reg_data_q'],
        'bridge exposes only the documented verification probe',
    );
    my %endpoint = map { $_->{endpoint_id} => $_ } @{$bridge->{endpoints}};
    is_deeply(
        [sort grep { $endpoint{$_} } qw(
            endpoint/HRDATA endpoint/HREADYOUT endpoint/HRESP
        )],
        [sort qw(endpoint/HRDATA endpoint/HREADYOUT endpoint/HRESP)],
        'bridge contains every documented public observation endpoint',
    );

    my $plan = decode_file(repo_path(split(m{/}, "$out_rel/vial-plan.json")));
    is($plan->{schema}, $execution->{plan_schema}, 'plan schema is exact');
    is($plan->{profile}, 'core_directed_single_clock_execution_v1', 'execution profile is exact');
    is_deeply(
        $plan->{logical_time}{phase_order},
        [qw(drive sample react check)],
        'logical phase order is exact',
    );
    is_deeply(
        $plan->{logical_time}{tie_break_order},
        [qw(domain_rank static_operation_rank local_emission_index semantic_id)],
        'logical-time tie-break order is exact',
    );
    is($plan->{logical_time}{scenario_cycle_origin}, 0, 'scenario cycle origin is exact');
    ok($plan->{logical_time}{timeout_last_cycle_inclusive}, 'timeout boundary is inclusive');
    is_deeply(
        [map { short_scenario($_->{scenario_id}) } @{$plan->{scenarios}}],
        [qw(success unsupported_size)],
        'omitting scenario selects both in authored order',
    );
    is(scalar(@{$plan->{random_decisions}}), 1, 'one checked seeded decision is present');
    is($plan->{random_decisions}[0]{seed}, 1, 'decision retains the authored seed');
    is($plan->{random_decisions}[0]{value}{value_hex}, '2', 'checked seed has a deterministic value');

    my $manifest = decode_file(repo_path(
        split(m{/}, "$out_rel/vial-tool-manifest.json"),
    ));
    ok($manifest->{cleanup}{atomic_commit_completed}, 'plan records completed atomic publication');
    ok($manifest->{cleanup}{staging_removed}, 'plan records removed staging');
    ok(
        !-e repo_path(split m{/}, $manifest->{cleanup}{staging_identity}),
        'operation-owned plan staging is absent',
    );

    my ($again_status, $again_out, $again_err) = run_cli(
        'vial', 'plan',
        '--dut', $hial_id,
        '--fixture', 'base_output_arbitration',
        '--profile', 'core_directed_single_clock_execution_v1',
        '--outdir', $out_rel,
        $vial_id,
    );
    is($again_status, 0, 'identical plan rerun exits zero');
    is($again_out, "VIAL plan unchanged ($out_rel)\n", 'rerun reports unchanged');
    is($again_err, '', 'unchanged rerun emits no diagnostic');
};

subtest 'public run result and bounded AHB parity stay tied to executable oracles' => sub {
    my ($entrypoint) = grep { /^fsmgen vial run / }
        @{$tooling->{implementation_entrypoints}};
    is(
        $entrypoint,
        'fsmgen vial run --dut HIAL_SOURCE --backend sv_portable_verilator [RUN_OPTIONS] SOURCE.vial',
        'machine contract selects only the documented public run backend',
    );
    like(
        $chapter,
        qr{[.]\/bin\/fsmgen vial run \\\n+  --dut ppif/ahb_lite_subordinate[.]ppif \\\n+  --backend sv_portable_verilator},
        'tutorial gives the exact checked-source public run command',
    );
    like(
        $runtime_test,
        qr{'vial', 'run', '--dut', \$hial_id, '--backend', 'sv_portable_verilator'},
        'independent runtime regression executes the same public route',
    );
    like(
        $runtime_test,
        qr{VIAL run executed \(\$out_rel\)},
        'runtime regression locks the documented first-run output',
    );
    like(
        $runtime_test,
        qr{VIAL run unchanged \(\$out_rel\)},
        'runtime regression locks the documented idempotent rerun',
    );
    for my $path (@runtime_paths) {
        like($chapter, qr{\Q$path\E}, "tutorial names runtime artifact $path");
        like($runtime_test, qr{\Q$path\E}, "runtime regression owns artifact $path");
    }
    like(
        $runtime_test,
        qr{fsmgen[.]verification_result_manifest[.]v1},
        'runtime regression validates the normalized result schema',
    );
    for my $key (@{FSM::VIAL::Backend::ResultProducer->logical_time_keys}) {
        like($chapter, qr{`\Q$key\E`}, "tutorial explains logical-time key $key");
    }

    is(scalar(@parity_paths), 19, 'producer-derived handwritten oracle has nineteen paths');
    for my $path (@parity_paths) {
        like($chapter, qr{^\Q$path\E$}m, "tutorial lists parity path $path");
    }
    like(
        $parity_module,
        qr{my \@field = qw\(\s*scenario_id status bus_accepts ready_low_cycles response_error_cycles\s+nonzero_read_data_cycles final_ready final_response final_read_data_hex\s+storage_hex\s*\)}s,
        'handwritten parity producer retains the documented field family',
    );
    like(
        $parity_test,
        qr{storage=cafebabe/storage=deadbeef},
        'independent parity test contains the documented RED control',
    );
    like(
        $parity_test,
        qr{/outcomes/0/storage_hex},
        'RED control requires the documented semantic mismatch path',
    );
    like(
        $parity_test,
        qr{not declared typed VIAL probes},
        'independent oracle preserves the documented internal-observation exclusion',
    );
};

subtest 'portable VHDL and OSVVM routes are checked without becoming public backends' => sub {
    like(
        $chapter,
        qr{perl scripts/refresh_vial_vhdl_portable_gallery[.]pl --check},
        'tutorial gives the portable gallery check',
    );
    like(
        $chapter,
        qr{perl scripts/run_vial_vhdl_portable_ghdl_qualification[.]pl --check},
        'tutorial gives the portable qualification check',
    );
    like(
        $chapter,
        qr{perl scripts/refresh_vial_vhdl_osvvm_gallery[.]pl --check},
        'tutorial gives the OSVVM gallery check',
    );
    like(
        $chapter,
        qr{perl scripts/run_vial_vhdl_osvvm_ghdl_qualification[.]pl --check},
        'tutorial gives the OSVVM qualification check',
    );
    like($portable_gallery, qr{Ordinary regeneration invokes no simulator},
        'portable gallery separates inspection from qualification');
    like($osvvm_gallery, qr{bounded qualification is not general provider breadth},
        'OSVVM gallery preserves its exact nonclaim');
    ok(index($portable_script, q{'check' => \$check}) >= 0,
        'portable runner implements checked-byte mode');
    ok(index($osvvm_script, q{'check' => \$check}) >= 0,
        'OSVVM runner implements checked-byte mode');

    is($portable_report->{schema}, 'fsmgen.vial_vhdl_portable_ghdl_qualification.v1',
        'portable qualification schema is exact');
    is($portable_report->{status}, 'qualified', 'portable report is qualified');
    is($portable_report->{backend_profile}, 'vhdl_portable_ghdl',
        'portable profile identity is exact');
    is($portable_report->{tool_profile}{qualified_version}, '6.0.0',
        'portable tool version is exact');
    is($portable_report->{result}{status}, 'pass', 'portable normalized result passes');
    is($portable_report->{portable_sv_parity}{status}, 'equivalent',
        'portable report retains equivalent portable-SV parity');
    is(scalar(@{$portable_report->{portable_sv_parity}{compared_paths}}), 19,
        'portable report retains nineteen analogous outcome paths');
    ok($portable_report->{cleanup}{removed}, 'portable qualification records cleanup');

    is($osvvm_report->{schema}, 'fsmgen.vial_vhdl_osvvm_ghdl_qualification.v1',
        'OSVVM qualification schema is exact');
    is($osvvm_report->{status}, 'qualified', 'OSVVM report is qualified');
    is($osvvm_report->{backend_profile}, 'vhdl_osvvm_qualified',
        'OSVVM profile identity is exact');
    is($osvvm_report->{tool_profile}{qualified_version}, '6.0.0',
        'OSVVM GHDL version is exact');
    is($osvvm_report->{provider_profile}{version}, '2026.05',
        'OSVVM provider version is exact');
    is($osvvm_report->{portable_result_parity}{status}, 'equivalent',
        'OSVVM report retains equivalent portable-result parity');
    is(scalar(@{$osvvm_report->{portable_result_parity}{compared_paths}}), 19,
        'OSVVM report retains nineteen analogous outcome paths');
    is(
        $osvvm_report->{result}{result_record_sha256},
        $portable_report->{result}{result_record_sha256},
        'OSVVM and portable qualifications retain the same normalized result record',
    );
    ok($osvvm_report->{cleanup}{removed}, 'OSVVM qualification records cleanup');
    ok(
        $osvvm_preservation->{guards}{normalized_result_unchanged},
        'checked wrapper evidence preserves normalized-result authority',
    );
    ok(
        $osvvm_preservation->{guards}{phase_order_unchanged},
        'checked wrapper evidence preserves logical phase authority',
    );
    ok(
        !(grep { !$_->{byte_identical} }
            @{$osvvm_preservation->{portable_sources}}),
        'every wrapped portable source is byte-identical',
    );
};

subtest 'unsupported public backends fail atomically and tutorial cleanup is exact' => sub {
    my $sink = [];
    my $request = run_request('vhdl_portable_ghdl');
    my $result = execute_vial_tool_request($request, {
        source_catalog => {},
        artifact_sink => $sink,
        repository_root => $repo_root,
    });
    ok(!$result->{success}, 'private portable VHDL profile is not a public run value');
    is($result->{diagnostics}[0]{code}, 'VIAL_BACKEND_UNSUPPORTED',
        'unsupported backend diagnostic is exact');
    is_deeply($sink, [], 'unsupported run publishes no virtual artifact');
    is($result->{bridge_manifest}, undef, 'unsupported run leaks no bridge');
    is($result->{plan}, undef, 'unsupported run leaks no plan');
    is($result->{result_manifest}, undef, 'unsupported run invents no result');

    for my $token (
        'complete four-state public runtime',
        'native-UVM runtime',
        'public VHDL run',
        'mixed-language execution',
        'general parity',
        'arbitrary-tool capacity',
    ) {
        like($chapter, qr{\Q$token\E}, "tutorial preserves nonclaim $token");
    }
    like(
        $chapter,
        qr{rm -rf [.]artifacts/manual/vial-ahb-tutorial-plan},
        'tutorial cleanup names only its exact plan root',
    );
    like(
        $chapter,
        qr{rm -rf [.]artifacts/manual/vial-ahb-tutorial-run},
        'tutorial cleanup names only its exact run root',
    );
    ok(
        !-d repo_path(qw(.artifacts manual vial-ahb-tutorial-plan)),
        'manual inspection plan was removed before watcher execution',
    );
};

subtest 'hostile tutorial mutations fail closed' => sub {
    for my $token (
        $vial_id,
        $hial_id,
        'normal_v1',
        'drive -> sample -> react -> check',
        'sv_portable_verilator',
        'verification-result-manifest.json',
        '/outcomes/0/storage_hex',
        'vhdl_portable_ghdl',
        'vhdl_osvvm_qualified',
        'VIAL_BACKEND_UNSUPPORTED',
        'mixed-language execution',
        '.artifacts/manual/vial-ahb-tutorial-run',
    ) {
        my $mutated = $chapter;
        my $count = ($mutated =~ s/\Q$token\E/removed-tutorial-token/g);
        $count or die "cannot mutate tutorial token '$token'\n";
        ok(
            scalar(tutorial_errors($mutated)),
            "removing $token is rejected",
        );
    }
};

done_testing;

sub tutorial_errors {
    my ($text) = @_;
    my @errors;
    for my $token (
        $vial_id,
        $hial_id,
        'normal_v1',
        'terse',
        'drive -> sample -> react -> check',
        'domain_id',
        'cycle',
        'phase',
        'ordinal',
        'sv_portable_verilator',
        'verification-result-manifest.json',
        'vial.parity.ahb_base_output_arbitration.v1',
        'vhdl_portable_ghdl',
        'vhdl_osvvm_qualified',
        'portable_result_parity',
        'VIAL_BACKEND_UNSUPPORTED',
        'VIAL_RUN_TOOL_ERROR',
        'mixed-language execution',
        'general parity',
        '.artifacts/manual/vial-ahb-tutorial-plan',
        '.artifacts/manual/vial-ahb-tutorial-run',
    ) {
        push @errors, "missing tutorial token $token"
            if index($text, $token) < 0;
    }
    for my $command (
        './bin/fsmgen vial check --style auto',
        './bin/fsmgen vial format --style normal',
        './bin/fsmgen vial format --style terse',
        './bin/fsmgen vial plan',
        './bin/fsmgen vial capabilities --json',
        './bin/fsmgen vial run',
        'perl scripts/refresh_vial_vhdl_portable_gallery.pl --check',
        'perl scripts/run_vial_vhdl_portable_ghdl_qualification.pl --check',
        'perl scripts/refresh_vial_vhdl_osvvm_gallery.pl --check',
        'perl scripts/run_vial_vhdl_osvvm_ghdl_qualification.pl --check',
    ) {
        push @errors, "missing tutorial command $command"
            if index($text, $command) < 0;
    }
    for my $path (@plan_paths, @runtime_paths, @parity_paths) {
        push @errors, "missing tutorial path $path"
            if index($text, $path) < 0;
    }
    return @errors;
}

sub semantic_digest {
    my ($text) = @_;
    my $parsed = FSM::VIAL::Parser->parse_source({
        text => $text,
        source_name => $vial_id,
        source_catalog => {},
    });
    return FSM::VIAL::SourceProjection->semantic_projection_sha256($parsed);
}

sub run_request {
    my ($backend) = @_;
    return {
        schema => $tooling->{request_schema},
        schema_version => 1,
        action => 'run',
        vial_source => source_envelope($vial_id, $vial_text, 'vial'),
        hial_source => source_envelope($hial_id, $hial_text, 'ppif'),
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

sub short_scenario {
    my ($id) = @_;
    my ($short) = $id =~ /::scenario::([^:]+)\z/;
    return $short;
}

sub run_cli {
    my (@args) = @_;
    my $stderr = gensym;
    my $pid = open3(
        my $stdin,
        my $stdout,
        $stderr,
        $^X,
        repo_path(qw(bin fsmgen)),
        @args,
    );
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

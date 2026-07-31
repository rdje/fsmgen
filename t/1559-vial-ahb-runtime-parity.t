#!/usr/bin/env perl

use strict;
use warnings;

use Digest::SHA qw(sha256_hex);
use File::Path qw(make_path remove_tree);
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP ();
use Scalar::Util qw(blessed);
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::RegressionCorpus qw(regression_corpus_entries);
use FSM::Support::VIALExecutionContract qw(build_vial_execution_contract);
use FSM::Support::VIALToolingContract qw(build_vial_tooling_contract);
use FSM::VIAL::Parity::AHBBaseOutput;
use FSM::VIAL::Tool qw(execute_vial_tool_request);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $vial_id = 'vial/ahb_subordinate_base_output_arbitration.vial';
my $hial_id = 'ppif/ahb_lite_subordinate.ppif';
my $baseline_id = 't/data/ahb_generated_subordinate_base_output_arbitration_tb.svt';
my $vial_text = slurp_raw(repo_path($vial_id));
my $hial_text = slurp_raw(repo_path($hial_id));
my $baseline_text = slurp_raw(repo_path($baseline_id));
my $json = JSON::PP->new->canonical(1);
my $test_root_rel = ".artifacts/test/vial-ahb-parity-$$";
my $test_root = repo_path($test_root_rel);

my ($version_ok, $version_output) = run_command(['verilator', '--version'], 10);
plan skip_all => 'exact qualified Verilator 5.046 build is not installed'
    unless $version_ok
        && $version_output eq "Verilator 5.046 2026-02-28 rev vUNKNOWN-built20260228\n";

END {
    remove_tree($test_root)
        if defined($test_root) && -d $test_root && !-l $test_root;
}

my ($public_result, $sink, $dut_artifact, $dut_sha, $baseline_stdout, $parity);

subtest 'handwritten and generated VIAL harnesses execute the identical generated DUT' => sub {
    $sink = [];
    $public_result = execute_vial_tool_request(run_request(), {
        source_catalog => {}, artifact_sink => $sink, repository_root => $repo_root,
    });
    ok($public_result->{success}, 'public generated-VIAL run succeeds');
    diag($json->encode($public_result->{diagnostics})) unless $public_result->{success};
    return unless $public_result->{success};

    ($dut_artifact) = grep {
        $_->{relpath} eq 'backends/sv_portable_verilator/src/dut/ahb-lite-subordinate.sv'
    } @$sink;
    ok($dut_artifact, 'public run exposes the exact generated DUT artifact');
    return unless $dut_artifact;
    $dut_sha = sha256_hex($dut_artifact->{content});

    make_path($test_root);
    my $dut_rel = "$test_root_rel/ahb-lite-subordinate.sv";
    my $object_rel = "$test_root_rel/obj";
    write_raw(repo_path($dut_rel), $dut_artifact->{content});
    make_path(repo_path($object_rel));
    my @compile = (
        'verilator', '--binary', '--timing', '--assert', '-j', '1',
        '--threads', '1', '--x-initial', '0', '--x-assign', '0',
        '--timescale', '1ns/1ps', '--top-module',
        'ahb_generated_subordinate_base_output_arbitration_tb',
        '--Mdir', $object_rel, $dut_rel, $baseline_id,
    );
    my ($compile_ok, $compile_output) = run_command(\@compile, 120);
    ok($compile_ok, 'exact qualified profile compiles the handwritten harness');
    diag($compile_output) unless $compile_ok;
    return unless $compile_ok;
    unlike($compile_output, qr/%Error:/, 'handwritten compile contains no Verilator error');

    my $binary_rel = "$object_rel/Vahb_generated_subordinate_base_output_arbitration_tb";
    ok(-x repo_path($binary_rel), 'compile produces the exact handwritten executable');
    my ($run_ok, $run_output) = run_command([$binary_rel], 30);
    ok($run_ok, 'handwritten AHB harness completes successfully');
    diag($run_output) unless $run_ok;
    return unless $run_ok;
    $baseline_stdout = $run_output;
    like(
        $baseline_stdout,
        qr/^BASE_ASSERT_SUCCESS accepts=1 captures=1 holds=2 completions=1 ready_low=15 storage=cafebabe$/m,
        'handwritten success oracle proves the exact public outcome',
    );
    like(
        $baseline_stdout,
        qr/^BASE_ASSERT_ERROR accepts=1 captures=1 holds=2 completions=1 error_cycles=2 storage=00000000$/m,
        'handwritten ERROR oracle proves the exact public outcome',
    );
    is(
        sha256_hex(slurp_raw(repo_path($dut_rel))),
        $dut_sha,
        'handwritten execution uses byte-identical DUT source from the public VIAL graph',
    );
};

subtest 'normalized shared AHB outcomes are eligible and equivalent' => sub {
    plan skip_all => 'runtime prerequisite failed' unless $public_result && $baseline_stdout;
    $parity = parity_compare();
    ok($parity->{ok}, 'bounded parity comparison succeeds');
    diag($json->encode($parity->{diagnostics})) unless $parity->{ok};
    return unless $parity->{ok};
    is($parity->{status}, 'equivalent', 'shared AHB outcomes are equivalent');
    is($parity->{report}{schema}, 'fsmgen.vial_parity_report.v1', 'parity report schema is exact');
    is($parity->{report}{schema_version}, 1, 'parity report schema version is exact');
    is($parity->{report}{plan_id}, $public_result->{result_manifest}{plan_id}, 'report preserves the candidate plan identity');
    like($parity->{report}{baseline_result_id}, qr{\Ahandwritten-ahb-oracle/[0-9a-f]{64}\z}, 'baseline oracle is content-addressed');
    is($parity->{report}{candidate_result_id}, $public_result->{result_manifest}{result_id}, 'candidate result identity is exact');
    ok($parity->{report}{eligible}, 'bounded comparison is eligible');
    ok($parity->{report}{equivalent}, 'bounded comparison is equivalent');
    is(scalar(@{$parity->{report}{compared_paths}}), 19, 'nineteen observed public/shared outcome paths are compared');
    is_deeply($parity->{report}{mismatches}, [], 'equivalent report has no mismatch');
    is_deeply($parity->{report}{diagnostics}, [], 'equivalent report has no diagnostic');
    is(scalar(@{$parity->{report}{exclusions}}), 2, 'internal-only observation families are explicitly excluded per scenario');
    like($parity->{report}{exclusions}[0]{reason}, qr/not declared typed VIAL probes/, 'exclusion states the typed-probe boundary');
    is($parity->{baseline_projection}{outcomes}[0]{ready_low_cycles}, 15, 'baseline success stall count is normalized');
    is($parity->{candidate_projection}{outcomes}[0]{ready_low_cycles}, 15, 'generated result has the same success stall count');
    is($parity->{candidate_projection}{outcomes}[1]{response_error_cycles}, 2, 'generated result has the same two-cycle ERROR');
    is($parity->{candidate_projection}{outcomes}[0]{storage_hex}, 'cafebabe', 'success storage oracle is exact');
    is($parity->{candidate_projection}{outcomes}[1]{storage_hex}, '00000000', 'ERROR storage oracle is exact');
    ok(!contains_non_json_reference($parity), 'parity result is wholly JSON-safe');

    my $again = parity_compare();
    is($json->encode($again), $json->encode($parity), 'parity comparison is byte-deterministic and defensive');
    $again->{report}{compared_paths}[0] = 'caller mutation';
    isnt($parity->{report}{compared_paths}[0], 'caller mutation', 'returned parity graphs do not share caller-mutable data');
};

subtest 'mismatches and malformed or ineligible evidence fail closed' => sub {
    plan skip_all => 'runtime prerequisite failed' unless $public_result && $baseline_stdout;
    my $changed = $baseline_stdout;
    $changed =~ s/storage=cafebabe/storage=deadbeef/;
    my $mismatch = parity_compare(baseline_stdout => $changed);
    ok($mismatch->{ok}, 'semantic mismatch is a valid comparison result');
    is($mismatch->{status}, 'mismatch', 'semantic mismatch has exact status');
    ok(!$mismatch->{report}{equivalent}, 'semantic mismatch is not equivalent');
    is(scalar(@{$mismatch->{report}{mismatches}}), 1, 'one changed outcome yields one mismatch');
    is($mismatch->{report}{mismatches}[0]{path}, '/outcomes/0/storage_hex', 'mismatch path is exact');
    is($mismatch->{report}{mismatches}[0]{semantic_id}, 'probe/reg_data_q', 'mismatch names the declared storage probe');

    my $duplicate = parity_compare(baseline_stdout => $baseline_stdout . "BASE_ASSERT_SUCCESS accepts=1 captures=1 holds=2 completions=1 ready_low=15 storage=cafebabe\n");
    ok(!$duplicate->{ok}, 'duplicate baseline record fails closed');
    is($duplicate->{diagnostics}[0]{code}, 'VIAL_PARITY_BASELINE_ERROR', 'duplicate baseline diagnostic is exact');
    my $nonzero = parity_compare(baseline_exit_code => 1);
    ok(!$nonzero->{ok}, 'nonzero handwritten execution fails closed');
    is($nonzero->{diagnostics}[0]{code}, 'VIAL_PARITY_BASELINE_ERROR', 'nonzero baseline diagnostic is exact');
    my $other_dut = parity_compare(baseline_dut_sha256 => ('0' x 64));
    ok(!$other_dut->{ok}, 'different DUT identity fails closed');
    is($other_dut->{diagnostics}[0]{code}, 'VIAL_PARITY_DUT_IDENTITY_ERROR', 'different DUT diagnostic is exact');
    my $ineligible_manifest = clone($public_result->{result_manifest});
    $ineligible_manifest->{portable_parity_eligible} = JSON::PP::false;
    my $ineligible = parity_compare(candidate_result => $ineligible_manifest);
    ok(!$ineligible->{ok}, 'ineligible candidate fails closed');
    is($ineligible->{diagnostics}[0]{code}, 'VIAL_PARITY_CANDIDATE_ERROR', 'ineligible candidate diagnostic is exact');
};

subtest 'support accounting claims only the bounded handwritten-oracle parity' => sub {
    my $execution = build_vial_execution_contract();
    my $tooling = build_vial_tooling_contract();
    is($execution->{selected_future_schemas}{parity_report}{status}, 'shipped_bounded_ahb_oracle', 'parity schema reports its bounded shipped status');
    is($execution->{backend_stage_status}{parity}, 'shipped_handwritten_ahb_oracle', 'backend stage reports exact bounded parity evidence');
    my %execution_cap = map { $_ => 1 } @{$execution->{capabilities}};
    my %tool_cap = map { $_ => 1 } @{$tooling->{capabilities}};
    ok($execution_cap{'vial.parity_report.v1'}, 'execution contract exposes parity report production');
    ok($execution_cap{'vial.parity.ahb_base_output_arbitration.v1'}, 'execution contract exposes the bounded AHB parity capability');
    ok($tool_cap{'vial.parity.ahb_base_output_arbitration.v1'}, 'public discovery exposes the bounded qualification evidence');
    my %nonclaim = map { $_ => 1 } @{$execution->{explicit_nonclaims}};
    ok($nonclaim{general_cross_backend_parity}, 'general cross-backend parity remains an explicit non-claim');
    my ($entry) = grep { $_->{id} eq 'feature.vial_ahb_base_output_runtime_parity' } regression_corpus_entries();
    is($entry->{coverage}, 'vial_ahb_handwritten_oracle_parity', 'bounded parity has a distinct support identity');
    is($entry->{classification}, 'supported_smoke', 'bounded parity support classification is exact');
};

done_testing();

sub parity_compare {
    my (%override) = @_;
    my %argument = (
        candidate_result => $public_result->{result_manifest},
        baseline_exit_code => 0,
        baseline_stdout => $baseline_stdout,
        baseline_source_sha256 => sha256_hex($baseline_text),
        baseline_dut_sha256 => $dut_sha,
        candidate_dut_sha256 => $dut_sha,
        %override,
    );
    return FSM::VIAL::Parity::AHBBaseOutput->compare(\%argument);
}

sub run_request {
    return {
        schema => 'fsmgen.vial_tool_request.v1', schema_version => 1, action => 'run',
        vial_source => source_envelope($vial_id, $vial_text, 'vial'),
        hial_source => source_envelope($hial_id, $hial_text, 'ppif'),
        options => {
            source_style => 'auto', output_style => undef,
            fixture_id => 'base_output_arbitration', scenario_ids => [],
            execution_profile => 'core_directed_single_clock_execution_v1',
            backend_profile => 'sv_portable_verilator', replay_manifest => undef,
            native_extension_catalogs => [],
            artifact_policy => {mode => 'virtual', artifact_root => undef},
            quiet => JSON::PP::false,
        },
    };
}

sub source_envelope {
    my ($source_id, $text, $kind) = @_;
    return {
        source_id => $source_id, source_kind_hint => $kind, text => $text,
        encoding => 'utf-8', origin => 'memory', display_name => $source_id,
        canonical_id => undef, relative_path => $source_id, metadata => {},
    };
}

sub run_command {
    my ($command, $timeout) = @_;
    my ($ok, undef, undef, $stdout, $stderr) = run(
        command => $command, timeout => $timeout,
    );
    return ($ok ? 1 : 0, join('', @{$stdout || []}, @{$stderr || []}));
}

sub write_raw {
    my ($path, $content) = @_;
    open my $fh, '>:raw', $path or die "cannot write $path: $!";
    print {$fh} $content or die "cannot write $path: $!";
    close $fh or die "cannot close $path: $!";
}

sub repo_path {
    my ($relative) = @_;
    return File::Spec->catfile($repo_root, split m{/}, $relative);
}

sub slurp_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read $path: $!";
    local $/;
    my $text = <$fh>;
    close $fh or die "cannot close $path: $!";
    return $text;
}

sub clone {
    my ($value) = @_;
    return $value unless ref($value);
    return $value ? JSON::PP::true : JSON::PP::false
        if blessed($value) && $value->isa('JSON::PP::Boolean');
    return {map { $_ => clone($value->{$_}) } keys %$value} if ref($value) eq 'HASH';
    return [map { clone($_) } @$value] if ref($value) eq 'ARRAY';
    die 'non-JSON test data';
}

sub contains_non_json_reference {
    my ($value) = @_;
    return 0 unless ref($value);
    return 0 if blessed($value) && $value->isa('JSON::PP::Boolean');
    return 1 if ref($value) ne 'HASH' && ref($value) ne 'ARRAY';
    return scalar grep { contains_non_json_reference($value->{$_}) } keys %$value
        if ref($value) eq 'HASH';
    return scalar grep { contains_non_json_reference($_) } @$value;
}

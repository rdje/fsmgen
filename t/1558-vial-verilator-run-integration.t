#!/usr/bin/env perl

use strict;
use warnings;

use bytes ();
use Digest::SHA qw(sha256_hex);
use File::Path qw(make_path remove_tree);
use File::Spec;
use FindBin;
use IPC::Open3 qw(open3);
use JSON::PP ();
use Scalar::Util qw(blessed);
use Symbol qw(gensym);
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::RegressionCorpus qw(regression_corpus_entries);
use FSM::Support::VIALExecutionContract qw(build_vial_execution_contract);
use FSM::Support::VIALToolingContract qw(build_vial_tooling_contract);
use FSM::VIAL::Tool qw(execute_vial_tool_request);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $vial_id = 'vial/ahb_subordinate_base_output_arbitration.vial';
my $hial_id = 'ppif/ahb_lite_subordinate.ppif';
my $vial_text = slurp_raw(repo_path($vial_id));
my $hial_text = slurp_raw(repo_path($hial_id));
my $json = JSON::PP->new->canonical(1);
my $test_root_rel = ".artifacts/test/vial-verilator-run-$$";
my $test_root = repo_path($test_root_rel);

my ($version_status, $version_output) = capture_command('verilator', '--version');
plan skip_all => 'exact qualified Verilator 5.046 build is not installed'
    unless $version_status == 0
        && $version_output eq "Verilator 5.046 2026-02-28 rev vUNKNOWN-built20260228\n";

END {
    remove_tree($test_root)
        if defined($test_root) && -d $test_root && !-l $test_root;
}

subtest 'public API executes the exact bounded backend and returns normalized results' => sub {
    my $sink = [];
    my $result = execute_vial_tool_request(run_request(), {
        source_catalog => {},
        artifact_sink => $sink,
        repository_root => $repo_root,
    });
    ok($result->{success}, 'selected VIAL/HIAL fixture executes successfully');
    diag($json->encode($result->{diagnostics})) unless $result->{success};
    is($result->{action}, 'run', 'public result preserves the run action');
    is($result->{status}, 'executed', 'public run status is executed');
    is($result->{implementation}{stage}, 'public_verilator_runtime', 'implementation stage is exact');
    is_deeply($result->{diagnostics}, [], 'successful run has no diagnostics');
    ok(!contains_non_json_reference($result), 'public run result is wholly JSON-safe');

    my @expected_paths = qw(
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
        hial-vial-bridge.json
        review/ahb_lite_subordinate.fsm
        review/ahb_lite_subordinate.isf
        source/vial-normal.vial
        verification-output-manifest.json
        vial-plan.json
        vial-tool-manifest.json
    );
    my @actual_paths = map { $_->{relpath} } @$sink;
    is(scalar(@actual_paths), 19, 'run publishes the selected 19-artifact graph');
    is_deeply(
        [grep { $_ !~ m{\Aresults/[0-9a-f]{64}/verification-result-manifest\.json\z} } @actual_paths],
        \@expected_paths,
        'every fixed artifact path is exact and sorted around one content-addressed result',
    );
    is(scalar(grep { m{\Aresults/[0-9a-f]{64}/verification-result-manifest\.json\z} } @actual_paths), 1, 'one content-addressed result manifest is present');
    is_deeply($result->{artifacts}, $sink, 'public result and caller sink carry equal defensive values');

    my %artifact = map { $_->{relpath} => $_ } @$sink;
    my $backend = $result->{tool_manifest}{backend_profile};
    is($backend, 'sv_portable_verilator', 'tool manifest names the exact backend');
    is($result->{tool_manifest}{status}, 'executed', 'tool manifest records execution');
    is($result->{tool_manifest}{capability_evidence}{compile}, 'passed', 'tool manifest records compile evidence');
    is($result->{tool_manifest}{capability_evidence}{runtime}, 'passed', 'tool manifest records runtime evidence');
    is($result->{tool_manifest}{capability_evidence}{result}, 'pass', 'tool manifest records result evidence');
    is($result->{tool_manifest}{capability_evidence}{parity}, 'not_evaluated', 'tool manifest does not invent parity');

    my $backend_manifest = JSON::PP->new->decode(
        $artifact{'backends/sv_portable_verilator/backend-manifest.json'}{content}
    );
    is($backend_manifest->{tool_profile}{selection_status}, 'executed_qualified', 'backend executed only the qualified tool profile');
    is($backend_manifest->{capability_evidence}{compile}, 'passed', 'backend compile gate passed');
    is($backend_manifest->{capability_evidence}{runtime}, 'passed', 'backend runtime gate passed');
    is($backend_manifest->{capability_evidence}{result}, 'pass', 'backend result gate passed');
    ok(!$backend_manifest->{capability_evidence}{four_state_observation}, 'backend preserves its complete-four-state non-claim');
    ok($backend_manifest->{capability_evidence}{known_value_trace_only}, 'backend records the known-value trace boundary');
    ok($backend_manifest->{cleanup}{removed}, 'backend records removed execution staging');
    is($backend_manifest->{cleanup}{state}, 'completed_removed', 'backend cleanup state is final');
    ok(!-e repo_path($backend_manifest->{cleanup}{staging_identity}), 'execution staging is absent after API return');

    my $compile = JSON::PP->new->decode(
        $artifact{'backends/sv_portable_verilator/commands/compile-command.json'}{content}
    );
    is_deeply(
        [@{$compile->{arguments}}[0 .. 12]],
        [qw(--binary --timing --assert -j 1 --threads 1 --x-initial 0 --x-assign 0 --timescale 1ns/1ps)],
        'compile record starts with the exact qualified flags',
    );
    ok(!grep { $_ eq '-Wno-fatal' || $_ eq '--timescale-override' } @{$compile->{arguments}}, 'compile record contains no warning suppression or timescale override');
    like($artifact{'backends/sv_portable_verilator/evidence/compile-transcript.txt'}{content}, qr/tool-version: Verilator 5\.046/, 'compile transcript records the exact tool release');
    like($artifact{'backends/sv_portable_verilator/evidence/run-transcript.txt'}{content}, qr/trace-records: [1-9][0-9]*/, 'run transcript records the validated trace count');

    my $trace = $artifact{'backends/sv_portable_verilator/evidence/runtime-trace.jsonl'}{content};
    unlike($trace, qr/^FSMGEN_VIAL_TRACE_V1\t/m, 'published trace is normalized JSONL without simulator framing');
    my @trace_records = map { JSON::PP->new->decode($_) } grep { length } split /\n/, $trace;
    ok(@trace_records > 100, 'runtime trace contains substantive machine evidence');
    is($trace_records[0]{record_kind}, 'header', 'trace begins with its closed header');
    is($trace_records[-1]{record_kind}, 'footer', 'trace ends with its closed footer');

    my $manifest = $result->{result_manifest};
    is($manifest->{schema}, 'fsmgen.verification_result_manifest.v1', 'normalized result schema is exact');
    is($manifest->{status}, 'pass', 'aggregate normalized result passes');
    ok($manifest->{portable_parity_eligible}, 'passing portable result is eligible for later parity comparison');
    is($manifest->{backend_profile}{tool_name}, 'verilator', 'result records the compiler/simulator identity');
    is($manifest->{backend_profile}{tool_version}, '5.046', 'result records the qualified version');
    is(scalar(@{$manifest->{scenario_results}}), 2, 'both selected scenarios have normalized outcomes');
    is_deeply([map { $_->{status} } @{$manifest->{scenario_results}}], [qw(pass pass)], 'success and unsupported-size scenarios both pass');
    is_deeply([map { $_->{completion_reason} } @{$manifest->{scenario_results}}], [qw(completed completed)], 'both scenarios complete normally');
    for my $family (qw(events drives samples transactions expectations models scoreboards coverage faults fibers)) {
        ok(@{$manifest->{$family}} > 0, "$family stream contains runtime evidence");
    }
    is($manifest->{metrics}{maximum_live_fibers}, 3, 'runtime result preserves the bounded concurrency maximum');
    is($manifest->{metrics}{maximum_scoreboard_depth}, 1, 'runtime result reports the observed scoreboard maximum');
    is($manifest->{metrics}{result_bytes}, bytes::length(result_artifact_content(\%artifact)), 'result byte metric matches the persisted result');
    is($manifest->{parity_projection}{status}, 'pass', 'portable parity projection records its own result status');

    is($result->{verification_output_manifest}{schema}, 'fsmgen.verification_output_manifest.v2', 'VIAL run publishes output manifest v2');
    is($result->{verification_output_manifest}{validation}{compile}, 'passed', 'output manifest records compile validation');
    is($result->{verification_output_manifest}{validation}{runtime}, 'passed', 'output manifest records runtime validation');
    is($result->{verification_output_manifest}{validation}{result}, 'pass', 'output manifest records result validation');
    is($result->{verification_output_manifest}{validation}{parity}, 'not_evaluated', 'output manifest preserves the parity boundary');
    unlike($json->encode($result), qr{(?:/Volumes/SSD|build_phase|raise_objection|uvm_event)}, 'public graph leaks no host path or target methodology plumbing');

    my $second_sink = [];
    my $second = execute_vial_tool_request(run_request(), {
        source_catalog => {}, artifact_sink => $second_sink, repository_root => $repo_root,
    });
    ok($second->{success}, 'repeated API run succeeds');
    is($json->encode($second), $json->encode($result), 'repeated API result is byte-deterministic');
    is($json->encode($second_sink), $json->encode($sink), 'repeated virtual artifact graph is byte-deterministic');
    ok(!-e repo_path($backend_manifest->{cleanup}{staging_identity}), 'repeated API run also removes exact execution staging');
};

subtest 'public CLI publishes atomically and identical reruns are unchanged' => sub {
    make_path($test_root);
    my $out_rel = "$test_root_rel/out";
    my ($status, $out, $err) = run_cli(
        'vial', 'run', '--dut', $hial_id, '--backend', 'sv_portable_verilator',
        '--outdir', $out_rel, $vial_id,
    );
    is($status, 0, 'first CLI run exits zero');
    is($out, "VIAL run executed ($out_rel)\n", 'first CLI run reports exact publication root');
    is($err, '', 'first CLI run has no stderr');
    my @files = tree_files(repo_path($out_rel));
    is(scalar(@files), 19, 'CLI publishes the complete run tree atomically');
    my $tool = JSON::PP->new->decode(slurp_raw(repo_path("$out_rel/vial-tool-manifest.json")));
    is($tool->{status}, 'executed', 'persisted tool manifest records execution');
    ok($tool->{cleanup}{atomic_commit_completed}, 'persisted tool manifest records completed atomic publication');
    ok($tool->{cleanup}{staging_removed}, 'persisted tool manifest records removed publication staging');
    ok(!-e repo_path($tool->{cleanup}{staging_identity}), 'publication staging is absent after CLI return');
    my %first_sha = map { $_ => sha256_hex(slurp_raw(repo_path("$out_rel/$_"))) } @files;

    my ($again_status, $again_out, $again_err) = run_cli(
        'vial', 'run', '--dut', $hial_id, '--backend', 'sv_portable_verilator',
        '--outdir', $out_rel, $vial_id,
    );
    is($again_status, 0, 'identical CLI rerun exits zero');
    is($again_out, "VIAL run unchanged ($out_rel)\n", 'identical CLI rerun reports unchanged');
    is($again_err, '', 'identical CLI rerun has no stderr');
    is_deeply([tree_files(repo_path($out_rel))], \@files, 'identical rerun preserves the exact file set');
    my %again_sha = map { $_ => sha256_hex(slurp_raw(repo_path("$out_rel/$_"))) } @files;
    is_deeply(\%again_sha, \%first_sha, 'identical rerun preserves every artifact byte');
    my @residue = tree_files(repo_path('.artifacts/tmp/vial'));
    ok(!-d repo_path('.artifacts/tmp/vial') || !@residue, 'no VIAL execution/publication staging residue remains');
};

subtest 'run failures are closed, atomic, and capability-honest' => sub {
    my $wrong = run_request();
    $wrong->{options}{backend_profile} = 'sv_uvm_qualified';
    my $sink = [];
    my $result = execute_vial_tool_request($wrong, {
        source_catalog => {}, artifact_sink => $sink, repository_root => $repo_root,
    });
    ok(!$result->{success}, 'unsupported backend fails');
    is($result->{diagnostics}[0]{code}, 'VIAL_BACKEND_UNSUPPORTED', 'unsupported backend has the exact diagnostic');
    is_deeply($sink, [], 'unsupported backend publishes no virtual artifact');
    is($result->{capability_evidence}{compile}, 'not_run', 'failed negotiation invents no compile evidence');
    is($result->{capability_evidence}{runtime}, 'not_run', 'failed negotiation invents no runtime evidence');
    is($result->{capability_evidence}{result}, 'not_produced', 'failed negotiation invents no result evidence');

    my $nonempty = [{caller_owned => 1}];
    my $rejected = execute_vial_tool_request(run_request(), {
        source_catalog => {}, artifact_sink => $nonempty, repository_root => $repo_root,
    });
    ok(!$rejected->{success}, 'nonempty caller sink fails before execution');
    is($rejected->{diagnostics}[0]{code}, 'VIAL_TOOL_INVOCATION_ERROR', 'nonempty sink is an invocation error');
    is_deeply($nonempty, [{caller_owned => 1}], 'rejected caller sink remains unchanged');
};

subtest 'parallel any uses authored-order tie breaking and cancels non-winners' => sub {
    my $any_text = $vial_text;
    $any_text =~ s/\(parallel all/\(parallel any/
        or die 'parallel-any mutation did not find the join';
    $any_text =~ s{\(within \(same \(sample ready_out\) #b0\) 1 256\)}
        {(within (event success_write completed) 1 256)}
        or die 'parallel-any mutation did not find the second child property';
    my $request = run_request();
    $request->{vial_source} = source_envelope($vial_id, $any_text, 'vial');
    $request->{options}{scenario_ids} = ['success'];
    my $sink = [];
    my $result = execute_vial_tool_request($request, {
        source_catalog => {}, artifact_sink => $sink, repository_root => $repo_root,
    });
    ok($result->{success}, 'parallel-any same-barrier tie executes successfully');
    diag($json->encode($result->{diagnostics})) unless $result->{success};
    is($result->{result_manifest}{status}, 'pass', 'parallel-any scenario passes');
    is(scalar(@{$result->{result_manifest}{scenario_results}[0]{cancelled_fiber_ids}}), 1, 'one non-winning child is cancelled');
    my @terminal = grep {
        $_->{status} ne 'started' && defined($_->{parent_fiber_id})
    } @{$result->{result_manifest}{fibers}};
    is_deeply([map { $_->{status} } @terminal], [qw(completed cancelled)], 'authored child order selects one winner and cancels its tied sibling');
    is($terminal[0]{winner_fiber_id}, $terminal[0]{fiber_id}, 'completed child names itself as the stable winner');
    is($terminal[1]{winner_fiber_id}, $terminal[0]{fiber_id}, 'cancelled child names the same stable winner');
    my ($backend_manifest) = grep { $_->{role} eq 'backend_manifest' } @$sink;
    my $backend = JSON::PP->new->decode($backend_manifest->{content});
    ok(!-e repo_path($backend->{cleanup}{staging_identity}), 'parallel-any execution staging is removed');
};

subtest 'discovery and support accounting expose only the qualified shipped boundary' => sub {
    my $tooling = build_vial_tooling_contract();
    my $execution = build_vial_execution_contract();
    my %tool_cap = map { $_ => 1 } @{$tooling->{capabilities}};
    ok($tool_cap{'vial.backend.sv_portable_verilator.v1'}, 'tooling exposes the portable backend');
    ok($tool_cap{'vial.result_manifest.v1'}, 'tooling exposes result production');
    ok($tool_cap{'vial.parity.ahb_base_output_arbitration.v1'}, 'tooling exposes bounded AHB qualification evidence');
    my %execution_cap = map { $_ => 1 } @{$execution->{capabilities}};
    ok($execution_cap{'vial.backend.sv_portable_verilator.runtime_trace_v1'}, 'execution exposes validated runtime traces');
    is($execution->{backend_limits}{compile_transcript_bytes}, 8_388_608,
        'execution support reports the Runner compile-capture limit');
    is($execution->{backend_limits}{run_transcript_bytes}, 67_108_864,
        'execution support reports the Runner runtime-capture limit');
    my %nonclaim = map { $_ => 1 } @{$execution->{explicit_nonclaims}};
    ok($nonclaim{complete_four_state} && $nonclaim{general_cross_backend_parity} && $nonclaim{uvm} && $nonclaim{vhdl_methodology}, 'four-state/general-parity/methodology non-claims remain explicit');
    my ($entry) = grep { $_->{id} eq 'feature.vial_sv_portable_verilator_runtime' } regression_corpus_entries();
    is($entry->{coverage}, 'vial_sv_portable_verilator_runtime_cli_api', 'runtime has a distinct support identity');
    is($entry->{classification}, 'supported_smoke', 'runtime support classification is exact');
};

done_testing();

sub run_request {
    return {
        schema => 'fsmgen.vial_tool_request.v1',
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
            backend_profile => 'sv_portable_verilator',
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

sub result_artifact_content {
    my ($artifact) = @_;
    my ($path) = grep { m{\Aresults/[0-9a-f]{64}/verification-result-manifest\.json\z} } keys %$artifact;
    return $artifact->{$path}{content};
}

sub capture_command {
    my (@argv) = @_;
    my $stderr = gensym;
    my ($stdin, $stdout);
    my $pid = eval { open3($stdin, $stdout, $stderr, @argv) };
    return (127, '') unless defined($pid) && !$@;
    close $stdin;
    local $/;
    my $out = <$stdout> // '';
    my $err = <$stderr> // '';
    waitpid($pid, 0);
    return ($? >> 8, $out . $err);
}

sub run_cli {
    my (@args) = @_;
    my $stderr = gensym;
    my $pid = open3(my $stdin, my $stdout, $stderr, $^X, repo_path('bin/fsmgen'), @args);
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
    my $path = length($relative) ? File::Spec->catdir($root, split m{/}, $relative) : $root;
    opendir my $dh, $path or die "cannot inspect $relative: $!";
    my @entries = sort grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    closedir $dh or die "cannot close directory $relative: $!";
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

sub contains_non_json_reference {
    my ($value) = @_;
    return 0 unless ref($value);
    return 0 if blessed($value) && $value->isa('JSON::PP::Boolean');
    return 1 if ref($value) ne 'HASH' && ref($value) ne 'ARRAY';
    return scalar grep { contains_non_json_reference($value->{$_}) } keys %$value
        if ref($value) eq 'HASH';
    return scalar grep { contains_non_json_reference($_) } @$value;
}

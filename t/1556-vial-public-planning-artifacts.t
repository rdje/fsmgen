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

use FSM::Adapter::IAL2::PPIF;
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::RegressionCorpus qw(regression_corpus_entries);
use FSM::Support::VIALToolingContract qw(build_vial_tooling_contract);
use FSM::VIAL::Tool qw(execute_vial_tool_request);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $vial_id = 'vial/ahb_subordinate_base_output_arbitration.vial';
my $hial_id = 'ppif/ahb_lite_subordinate.ppif';
my $ial0_id = 'fsm/ahb_lite_subordinate.fsm';
my $vial_text = slurp_raw(repo_path($vial_id));
my $hial_text = slurp_raw(repo_path($hial_id));
my $ial0_text = slurp_raw(repo_path($ial0_id));
my $json = JSON::PP->new->canonical;
my $test_root_rel = ".artifacts/test/vial-public-plan-$$";
my $test_root = repo_path($test_root_rel);

END {
    remove_tree($test_root) if defined($test_root) && -d $test_root && !-l $test_root;
}

subtest 'virtual API returns one closed deterministic target-neutral artifact graph' => sub {
    my $sink = [];
    my $result = execute_vial_tool_request(plan_request(), {
        source_catalog => {}, artifact_sink => $sink,
    });
    ok($result->{success}, 'checked IAL2/VIAL fixture plans successfully');
    diag($json->encode($result->{diagnostics})) unless $result->{success};
    is($result->{status}, 'planned', 'virtual plan reports planned');
    is($result->{implementation}{stage}, 'public_planning', 'result names the public planning stage');
    is($result->{bridge_manifest}{schema}, 'fsmgen.hial_vial_bridge_manifest.v1', 'public bridge projection is exact');
    is($result->{plan}{schema}, 'fsmgen.vial_plan.v1', 'public plan projection is exact');
    is($result->{tool_manifest}{schema}, 'fsmgen.vial_tool_manifest.v1', 'tool manifest schema is exact');
    is_deeply(
        [map { $_->{layer} } @{$result->{bridge_manifest}{review_route}{stages}}],
        [qw(IAL2 IAL1 IAL0)],
        'public planning preserves the canonical generated/reparsed IAL1 route',
    );
    ok(!$result->{bridge_manifest}{review_route}{direct_ial2_to_verification}, 'direct IAL2 bypass remains false');
    like($result->{plan}{plan_id}, qr{\Aplan/[0-9a-f]{64}\z}, 'plan identity is full SHA-256');
    like(
        $result->{tool_manifest}{artifact_root},
        qr{\A\.artifacts/vial/base-output-arbitration/[0-9a-f]{64}\z},
        'default artifact root uses fixture slug and full plan digest',
    );
    like($result->{tool_manifest}{operation_id}, qr{\Aop-[0-9a-f]{64}\z}, 'operation identity is deterministic');
    is_deeply($result->{diagnostics}, [], 'successful plan has no diagnostics');
    ok(!contains_non_json_reference($result), 'result contains JSON-safe data only');

    my @expected_paths = qw(
        hial-vial-bridge.json
        review/ahb_lite_subordinate.fsm
        review/ahb_lite_subordinate.isf
        source/vial-normal.vial
        vial-plan.json
        vial-tool-manifest.json
    );
    is_deeply([map { $_->{relpath} } @$sink], \@expected_paths, 'virtual sink is complete and path-sorted');
    is_deeply($result->{artifacts}, $sink, 'result and virtual sink carry equal defensive artifact values');
    my %artifact = map { $_->{relpath} => $_ } @$sink;
    like($artifact{'source/vial-normal.vial'}{content}, qr{\A\(vial\n  \(version 1\)}, 'source artifact is canonical normal VIAL');
    is(sha256_hex($artifact{'review/ahb_lite_subordinate.isf'}{content}), 'b0f3446874367787d0dd134701ff9e89a3b24af6ef9c03d6eb9dc484093f9e4c', 'generated IAL1 review hash is preserved');
    is(sha256_hex($artifact{'review/ahb_lite_subordinate.fsm'}{content}), '3d8fa7ac7c3a7f2c9ca063aca2cf707106b511219243d8b277ac3e2e8cf47bcf', 'generated IAL0 review hash is preserved');
    is(JSON::PP->new->decode($artifact{'hial-vial-bridge.json'}{content})->{manifest_id}, $result->{bridge_manifest}{manifest_id}, 'bridge artifact is the exact public projection');
    is(JSON::PP->new->decode($artifact{'vial-plan.json'}{content})->{plan_id}, $result->{plan}{plan_id}, 'plan artifact is the exact public projection');
    is_deeply(
        [sort keys %{$result->{tool_manifest}}],
        [sort qw(schema schema_version operation_id status action source_style source_identities fixture_id scenario_ids execution_profile backend_profile artifact_root artifacts reports capability_evidence support_accounting diagnostics cleanup)],
        'tool manifest has exactly the selected top-level keys',
    );
    is(scalar(@{$result->{tool_manifest}{artifacts}}), 5, 'tool manifest inventories every non-self artifact without recursive self-hashing');
    for my $entry (@{$result->{tool_manifest}{artifacts}}) {
        is($entry->{sha256}, sha256_hex($artifact{$entry->{relpath}}{content}), "$entry->{relpath} hash matches exact content");
        is($entry->{bytes}, bytes::length($artifact{$entry->{relpath}}{content}), "$entry->{relpath} byte count matches exact content");
        ok(!exists($entry->{content}), "$entry->{relpath} persisted metadata omits content");
    }
    is($result->{tool_manifest}{cleanup}{staging_identity}, undef, 'virtual plan has no filesystem staging identity');
    ok(!$result->{tool_manifest}{cleanup}{atomic_commit_completed}, 'virtual plan does not claim a filesystem commit');
    my $public_json = $json->encode($result);
    my @host_or_method_fragments = (
        '/Volumes/',
        join('/', '', 'private', 'tmp', ''),
        join('/', '', 'tmp', ''),
        qw(build_phase raise_objection uvm_event),
    );
    ok(
        !grep { index($public_json, $_) >= 0 } @host_or_method_fragments,
        'public projections contain no absolute host path or target methodology plumbing',
    );

    my $second_sink = [];
    my $second = execute_vial_tool_request(plan_request(), {
        source_catalog => {}, artifact_sink => $second_sink,
    });
    is($json->encode($second), $json->encode($result), 'repeated API plan is byte-deterministic');
    is($json->encode($second_sink), $json->encode($sink), 'repeated virtual graph is byte-deterministic');
    $sink->[0]{content} = 'mutated';
    isnt($result->{artifacts}[0]{content}, 'mutated', 'result does not share storage with caller sink');
    $result->{plan}{fixture}{fixture_name} = 'mutated';
    isnt($second->{plan}{fixture}{fixture_name}, 'mutated', 'results are defensive across calls');
};

subtest 'all three canonical HIAL routes reach public planning with capability-honest binding' => sub {
    my $ial0_smoke_sink = [];
    my $ial0_smoke = execute_vial_tool_request(plan_request(
        vial_source => source_envelope(
            'vial/ial0_endpoint_smoke.vial',
            ial0_endpoint_smoke_source(),
            'vial',
        ),
        hial_source => source_envelope($ial0_id, $ial0_text, 'fsm'),
        options => {fixture_id => 'smoke'},
    ), {source_catalog => {}, artifact_sink => $ial0_smoke_sink});
    ok($ial0_smoke->{success}, 'transaction-free endpoint fixture plans through direct IAL0');
    diag($json->encode($ial0_smoke->{diagnostics})) unless $ial0_smoke->{success};
    is_deeply(
        [map { $_->{layer} } @{$ial0_smoke->{bridge_manifest}{review_route}{stages}}],
        ['IAL0'],
        'direct IAL0 preserves its one-stage authored review route',
    );
    is_deeply(
        [grep { $_->{role} eq 'generated_hial_review' } @$ial0_smoke_sink],
        [],
        'direct IAL0 invents no generated review artifact',
    );

    my $ial2 = FSM::Adapter::IAL2::PPIF->new()->parse_source($hial_text, $hial_id);
    my $generated_ial1 = $ial2->{generated_ial1}{text};
    my $ial1_sink = [];
    my $ial1 = execute_vial_tool_request(plan_request(
        hial_source => source_envelope('review/ahb_lite_subordinate.isf', $generated_ial1, 'isf'),
    ), {source_catalog => {}, artifact_sink => $ial1_sink});
    ok($ial1->{success}, 'direct IAL1 with explicit reviewed bridge metadata plans successfully');
    diag($json->encode($ial1->{diagnostics})) unless $ial1->{success};
    is_deeply(
        [map { $_->{layer} } @{$ial1->{bridge_manifest}{review_route}{stages}}],
        [qw(IAL1 IAL0)],
        'direct IAL1 uses its canonical generated IAL0 review route',
    );
    is_deeply(
        [map { $_->{relpath} } grep { $_->{role} eq 'generated_hial_review' } @$ial1_sink],
        ['review/ahb_lite_subordinate.fsm'],
        'direct IAL1 publishes only its generated IAL0 review artifact',
    );

    my $ial0_sink = [];
    my $ial0 = execute_vial_tool_request(plan_request(
        hial_source => source_envelope($ial0_id, $ial0_text, 'fsm'),
    ), {source_catalog => {}, artifact_sink => $ial0_sink});
    ok(!$ial0->{success}, 'structural direct IAL0 cannot satisfy this AHB-protocol VIAL fixture');
    like($ial0->{diagnostics}[0]{code}, qr{\AVIAL_BIND_}, 'direct IAL0 reaches VIAL semantic binding rather than failing HIAL routing');
    is_deeply($ial0_sink, [], 'incompatible direct IAL0 publishes no partial artifacts');
    is($ial0->{bridge_manifest}, undef, 'failed binding leaks no partial bridge');
    is($ial0->{plan}, undef, 'failed binding leaks no partial plan');
};

subtest 'invocation, HIAL, runtime, and sink failures remain atomic and sanitized' => sub {
    my $bad_hial = $hial_text;
    $bad_hial =~ s/\(profile ahb\)/(profile apb)/ or die 'HIAL mutation did not match';
    my $bad_sink = [];
    my $bad = execute_vial_tool_request(plan_request(
        hial_source => source_envelope($hial_id, $bad_hial, 'ppif'),
    ), {source_catalog => {}, artifact_sink => $bad_sink});
    ok(!$bad->{success}, 'invalid HIAL source fails planning');
    is($bad->{diagnostics}[0]{code}, 'VIAL_HIAL_SOURCE_ERROR', 'HIAL parse/lowering failure has the selected wrapper code');
    is_deeply($bad_sink, [], 'HIAL failure leaves virtual sink empty');
    is($bad->{bridge_manifest}, undef, 'HIAL failure returns no bridge');
    is($bad->{tool_manifest}, undef, 'HIAL failure returns no tool manifest');
    unlike($json->encode($bad), qr{/Volumes/SSD|PlanBuilder\.pm line}, 'HIAL failure sanitizes host paths and stack locations');

    my $nonempty_sink = [{existing => 1}];
    my $nonempty = execute_vial_tool_request(plan_request(), {
        source_catalog => {}, artifact_sink => $nonempty_sink,
    });
    is($nonempty->{diagnostics}[0]{code}, 'VIAL_TOOL_INVOCATION_ERROR', 'non-empty sink fails before planning');
    is_deeply($nonempty_sink, [{existing => 1}], 'rejected sink remains caller-owned and unchanged');

    my $unsafe = plan_request();
    $unsafe->{options}{artifact_policy}{artifact_root} = '../outside';
    my $unsafe_sink = [];
    my $unsafe_result = execute_vial_tool_request($unsafe, {source_catalog => {}, artifact_sink => $unsafe_sink});
    is($unsafe_result->{diagnostics}[0]{code}, 'VIAL_TOOL_INVOCATION_ERROR', 'unsafe API artifact root fails invocation validation');
    is_deeply($unsafe_sink, [], 'unsafe root creates no virtual artifact');

    my $selection_sink = [];
    my $selection = execute_vial_tool_request(plan_request(
        options => {fixture_id => 'missing_fixture'},
    ), {source_catalog => {}, artifact_sink => $selection_sink});
    is($selection->{diagnostics}[0]{code}, 'VIAL_TOOL_INVOCATION_ERROR', 'unknown fixture is an option error, not a HIAL source error');
    is_deeply($selection_sink, [], 'invalid fixture selection publishes no artifacts');

    my $run_request = plan_request();
    $run_request->{action} = 'run';
    $run_request->{options}{backend_profile} = 'sv_portable_verilator';
    my $run_sink = [];
    my $run = execute_vial_tool_request($run_request, {source_catalog => {}, artifact_sink => $run_sink});
    is($run->{diagnostics}[0]{code}, 'VIAL_TOOL_INVOCATION_ERROR', 'run without the required repository root fails closed');
    is_deeply($run_sink, [], 'invalid run environment produces no artifacts');
};

subtest 'filesystem CLI atomically publishes, detects identity, collision, and unsafe paths' => sub {
    make_path($test_root);
    my $out_rel = "$test_root_rel/out";
    my ($first_status, $first_out, $first_err) = run_cli(
        'vial', 'plan', '--dut', $hial_id, '--outdir', $out_rel, $vial_id,
    );
    is($first_status, 0, 'first CLI plan exits zero');
    is($first_out, "VIAL plan planned ($out_rel)\n", 'first CLI plan reports exact relative root');
    is($first_err, '', 'first CLI plan has no stderr');
    my @files = tree_files(repo_path($out_rel));
    is_deeply(
        \@files,
        [qw(hial-vial-bridge.json review/ahb_lite_subordinate.fsm review/ahb_lite_subordinate.isf source/vial-normal.vial vial-plan.json vial-tool-manifest.json)],
        'CLI commits the complete declared tree only',
    );
    my $manifest = JSON::PP->new->decode(slurp_raw(repo_path("$out_rel/vial-tool-manifest.json")));
    is($manifest->{artifact_root}, $out_rel, 'persisted manifest records only the repository-relative root');
    ok($manifest->{cleanup}{atomic_commit_completed}, 'persisted manifest records completed atomic publication');
    ok(!-e repo_path($manifest->{cleanup}{staging_identity}), 'staging root is absent after commit');

    my ($again_status, $again_out, $again_err) = run_cli(
        'vial', 'plan', '--dut', $hial_id, '--outdir', $out_rel, $vial_id,
    );
    is($again_status, 0, 'identical CLI plan exits zero');
    is($again_out, "VIAL plan unchanged ($out_rel)\n", 'identical tree returns unchanged');
    is($again_err, '', 'identical tree has no stderr');

    my $native_rel = "$test_root_rel/empty-native-catalog.json";
    my $selected_rel = "$test_root_rel/selected";
    write_raw(repo_path($native_rel), "[]\n");
    my ($selected_status, $selected_out, $selected_err) = run_cli(
        'vial', 'plan', '--dut', $hial_id,
        '--fixture', 'base_output_arbitration',
        '--scenario', 'success',
        '--profile', 'core_directed_single_clock_execution_v1',
        '--native-catalog', $native_rel,
        '--outdir', $selected_rel,
        '--json', $vial_id,
    );
    is($selected_status, 0, 'explicit selection/profile/native-catalog CLI plan exits zero');
    is($selected_err, '', 'explicit JSON plan has no stderr');
    my $selected = JSON::PP->new->decode($selected_out);
    ok($selected->{success}, 'explicit JSON plan returns the public result envelope');
    is_deeply(
        $selected->{plan}{fixture}{scenario_ids},
        ['ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::success'],
        'CLI preserves the exact selected scenario only',
    );
    is($selected->{tool_manifest}{artifact_root}, $selected_rel, 'JSON plan reports the explicit root');

    my $collision_rel = "$test_root_rel/collision";
    make_path(repo_path($collision_rel));
    write_raw(repo_path("$collision_rel/undeclared.txt"), "owned collision\n");
    my ($collision_status, $collision_out, $collision_err) = run_cli(
        'vial', 'plan', '--dut', $hial_id, '--outdir', $collision_rel, $vial_id,
    );
    is($collision_status, 1, 'non-identical existing tree fails');
    is($collision_out, '', 'collision writes no stdout');
    like($collision_err, qr{Error \[VIAL_ARTIFACT_COLLISION\]}, 'collision has the selected diagnostic');
    is(slurp_raw(repo_path("$collision_rel/undeclared.txt")), "owned collision\n", 'collision does not overwrite existing content');
    ok(!-e repo_path($manifest->{cleanup}{staging_identity}), 'collision leaves no operation staging tree');

    my $symlink_target_rel = "$test_root_rel/symlink-target";
    my $symlink_rel = "$test_root_rel/symlink-out";
    make_path(repo_path($symlink_target_rel));
    my $symlink_ok = eval { symlink(repo_path($symlink_target_rel), repo_path($symlink_rel)) };
    if ($symlink_ok) {
        my ($link_status, $link_out, $link_err) = run_cli(
            'vial', 'plan', '--dut', $hial_id, '--outdir', $symlink_rel, $vial_id,
        );
        is($link_status, 2, 'symlink output root fails path validation');
        is($link_out, '', 'symlink failure writes no stdout');
        like($link_err, qr{Error \[VIAL_ARTIFACT_PATH_ERROR\]}, 'symlink output has path diagnostic');
        is_deeply([tree_files(repo_path($symlink_target_rel))], [], 'symlink target remains untouched');
        unlink repo_path($symlink_rel) or die "cannot remove test symlink: $!";
    }
    else {
        pass('platform does not permit the repository-local symlink probe');
        pass('platform does not permit the repository-local symlink probe');
        pass('platform does not permit the repository-local symlink probe');
        pass('platform does not permit the repository-local symlink probe');
    }

    my ($traversal_status, $traversal_out, $traversal_err) = run_cli(
        'vial', 'plan', '--dut', $hial_id, '--outdir', '../outside', $vial_id,
    );
    is($traversal_status, 2, 'traversal outdir fails before publication');
    is($traversal_out, '', 'traversal failure writes no stdout');
    like($traversal_err, qr{Error \[VIAL_TOOL_INVOCATION_ERROR\]}, 'traversal outdir has invocation diagnostic');
};

subtest 'capability and support accounting retain planning while adding bounded runtime' => sub {
    my $contract = build_vial_tooling_contract();
    is($contract->{status}, 'shipped_public_verilator_execution_result_and_ahb_parity', 'tooling status includes bounded execution/result and AHB parity');
    is_deeply($contract->{supported_actions}, [qw(capabilities check format plan run)], 'supported actions include plan and run');
    ok($contract->{writes_files}, 'tool contract records filesystem-adapter writes');
    my %capability = map { $_ => 1 } @{$contract->{capabilities}};
    ok($capability{'vial.artifact_layout.v1'} && $capability{'vial.tool_manifest.v1'} && $capability{'vial.verification_output_manifest.v2'}, 'planning capability family is exact');
    my %nonclaim = map { $_ => 1 } @{$contract->{explicit_nonclaims}};
    ok($nonclaim{complete_four_state} && $nonclaim{general_cross_backend_parity}, 'remaining general qualification non-claims are explicit');
    my ($entry) = grep { $_->{id} eq 'feature.vial_public_plan' } regression_corpus_entries();
    is($entry->{coverage}, 'vial_public_plan_cli_api', 'planning support entry uses its own coverage identity');
    my $manifest = build_capability_manifest();
    is($manifest->{language_surface}{file_surfaces}{entries}[-1]{suffix}, '.vial', '.vial remains the final explicit file surface');
    is($manifest->{language_surface}{file_surfaces}{entries}[-1]{status}, 'shipped_bounded_public_verilator_execution_result_and_ahb_parity', 'file-surface status includes bounded runtime/result and AHB parity');
};

done_testing();

sub ial0_endpoint_smoke_source {
    return <<'VIAL';
(vial
  (version 1)
  (package ial0_endpoint_smoke
    (imports)
    (types)
    (transactions)
    (models)
    (scoreboards)
    (fixtures
      (fixture smoke
        (dut dut
          (unit "unit/ahb_lite_subordinate")
          (domains
            (domain bus "domain/default"))
          (endpoints
            (endpoint ready "endpoint/HREADYOUT" (logic 1) public_port))
          (transactions))
        (instances)
        (coverage)
        (faults)
        (randomness
          (seed 1))
        (scenarios
          (scenario success
            (timeout (cycles bus 8))
            (steps
              (reset bus 1))))))))
VIAL
}

sub plan_request {
    my (%override) = @_;
    my $hial_source = delete($override{hial_source})
        // source_envelope($hial_id, $hial_text, 'ppif');
    my $options = {
        source_style => 'auto',
        output_style => undef,
        fixture_id => 'base_output_arbitration',
        scenario_ids => [],
        execution_profile => 'core_directed_single_clock_execution_v1',
        backend_profile => undef,
        replay_manifest => undef,
        native_extension_catalogs => [],
        artifact_policy => {mode => 'virtual', artifact_root => undef},
        quiet => JSON::PP::false,
        %{delete($override{options}) || {}},
    };
    return {
        schema => 'fsmgen.vial_tool_request.v1',
        schema_version => 1,
        action => 'plan',
        vial_source => source_envelope($vial_id, $vial_text, 'vial'),
        hial_source => $hial_source,
        options => $options,
        %override,
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

sub run_cli {
    my (@args) = @_;
    my $stderr = gensym;
    my $pid = open3(
        my $stdin, my $stdout, $stderr,
        $^X, repo_path('bin/fsmgen'), @args,
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

sub write_raw {
    my ($path, $content) = @_;
    open my $fh, '>:raw', $path or die "cannot write $path: $!";
    print {$fh} $content or die "cannot write content to $path: $!";
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

sub contains_non_json_reference {
    my ($value) = @_;
    return 0 unless ref($value);
    return 0 if blessed($value) && $value->isa('JSON::PP::Boolean');
    return 1 if ref($value) ne 'HASH' && ref($value) ne 'ARRAY';
    return scalar grep { contains_non_json_reference($value->{$_}) } keys %$value
        if ref($value) eq 'HASH';
    return scalar grep { contains_non_json_reference($_) } @$value;
}

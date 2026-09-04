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

use FSM::Support::HIALVIALBridgeContract qw(
    build_hial_vial_bridge_contract
);
use FSM::Support::VIALExecutionContract qw(build_vial_execution_contract);
use FSM::Support::VIALToolingContract qw(
    build_vial_tooling_contract
    build_vial_tooling_contract_v2
);
use FSM::VIAL::Parser;
use FSM::VIAL::SourceProjection;
use FSM::VIAL::Tool qw(execute_vial_tool_request);

my $repo_root = File::Spec->rel2abs(
    File::Spec->catdir($FindBin::Bin, '..'),
);
my $book_root = repo_path(qw(docs book src));
my $chapter_path = File::Spec->catfile(
    $book_root, '16dg-vial-public-lifecycle-reference.md',
);
my $chapter = slurp($chapter_path);
my $summary = slurp(File::Spec->catfile($book_root, 'SUMMARY.md'));
my $overview = slurp(File::Spec->catfile(
    $book_root, '16d-hial-vial-verification-architecture.md',
));
my $runtime_test = slurp(repo_path(
    't', '1558-vial-verilator-run-integration.t',
));
my $vial_id = 'vial/ahb_subordinate_base_output_arbitration.vial';
my $hial_id = 'ppif/ahb_lite_subordinate.ppif';
my $vial_text = slurp(repo_path(split m{/}, $vial_id));
my $hial_text = slurp(repo_path(split m{/}, $hial_id));
my $test_root_rel = ".artifacts/test/hial-vial-lifecycle-$$";
my $test_root = repo_path(split m{/}, $test_root_rel);
my $tooling = build_vial_tooling_contract();
my $tooling_v2 = build_vial_tooling_contract_v2();
my $bridge = build_hial_vial_bridge_contract();
my $execution = build_vial_execution_contract();
my $json = JSON::PP->new->canonical;

my @result_keys = qw(
    schema schema_version action success status source_identities source_style
    semantic_report formatted_source bridge_manifest plan tool_manifest
    verification_output_manifest result_manifest artifacts capability_evidence
    support_accounting diagnostics implementation
);
my @plan_paths = qw(
    hial-vial-bridge.json
    review/ahb_lite_subordinate.fsm
    review/ahb_lite_subordinate.isf
    source/vial-normal.vial
    vial-plan.json
    vial-tool-manifest.json
);

END {
    remove_tree($test_root)
        if defined($test_root) && -d $test_root && !-l $test_root;
}

subtest 'book routing and lifecycle prose are derived from public contracts' => sub {
    like(
        $summary,
        qr{^    - \[Public VIAL Lifecycle Reference\]\(16dg-vial-public-lifecycle-reference[.]md\)$}m,
        'SUMMARY nests the lifecycle reference below Start Here',
    );
    like(
        $overview,
        qr{\[Public VIAL Lifecycle Reference\]\(16dg-vial-public-lifecycle-reference[.]md\)},
        'the overview routes public workflow detail to the lifecycle reference',
    );

    my @errors = lifecycle_errors($chapter);
    is_deeply(
        \@errors,
        [],
        'the chapter covers exact actions, styles, routes, schemas, diagnostics, and boundaries',
    );

    for my $action (@{$tooling->{supported_actions}}) {
        like(
            $chapter,
            qr{[.]\/bin\/fsmgen vial \Q$action\E\b},
            "the $action action has a runnable repository-root command",
        );
    }
    for my $action (@{$tooling_v2->{supported_actions}}) {
        like(
            $chapter,
            qr{[.]\/bin\/fsmgen vial \Q$action\E\b.*?--language-version 2}s,
            "the v2 $action action has an explicit version-selected command",
        );
    }
    like(
        $chapter,
        qr{--outdir [.]artifacts/manual/vial-lifecycle-plan},
        'planning uses an explicit repository-owned manual root',
    );
    like(
        $chapter,
        qr{--outdir [.]artifacts/manual/vial-lifecycle-run},
        'runtime uses a distinct repository-owned manual root',
    );
};

subtest 'source-only CLI commands preserve one normal and terse meaning' => sub {
    my ($cap_status, $cap_out, $cap_err) = run_cli(
        'vial', 'capabilities', '--json',
    );
    is($cap_status, 0, 'documented JSON discovery exits zero');
    is($cap_err, '', 'documented JSON discovery has no diagnostic');
    my $capabilities = JSON::PP->new->decode($cap_out);
    is($capabilities->{schema}, $tooling->{result_schema}, 'discovery uses the public result schema');
    is_deeply(
        $capabilities->{capability_evidence}{supported_actions},
        $tooling->{supported_actions},
        'discovery actions equal the machine-owned contract',
    );
    is_deeply(
        $capabilities->{capability_evidence}{diagnostics},
        $tooling->{diagnostics},
        'discovery diagnostics equal the machine-owned contract',
    );

    my ($check_status, $check_out, $check_err) = run_cli(
        'vial', 'check', '--style', 'auto', '--json', $vial_id,
    );
    is($check_status, 0, 'documented JSON check exits zero');
    is($check_err, '', 'documented JSON check has no diagnostic');
    my $checked = JSON::PP->new->decode($check_out);
    ok($checked->{success}, 'canonical checked source succeeds');
    is($checked->{source_style}, 'normal_v1', 'canonical source reports normal projection');
    is_deeply([sort keys %$checked], [sort @result_keys], 'check result envelope is closed');
    is_deeply($checked->{artifacts}, [], 'check writes no artifact');

    my ($normal_status, $normal, $normal_err) = run_cli(
        'vial', 'format', '--style', 'normal', $vial_id,
    );
    my ($terse_status, $terse, $terse_err) = run_cli(
        'vial', 'format', '--style', 'terse', $vial_id,
    );
    is($normal_status, 0, 'documented normal formatter exits zero');
    is($terse_status, 0, 'documented terse formatter exits zero');
    is($normal_err . $terse_err, '', 'both formatters have no diagnostic');
    is(
        FSM::VIAL::SourceProjection->source_style({
            text => $normal, source_name => $vial_id,
        }),
        'normal',
        'normal command emits valid normal source',
    );
    is(
        FSM::VIAL::SourceProjection->source_style({
            text => $terse, source_name => $vial_id,
        }),
        'terse',
        'terse command emits valid terse source',
    );
    is(
        FSM::VIAL::SourceProjection->semantic_projection_sha256(
            FSM::VIAL::Parser->parse_source({
                text => $normal, source_name => $vial_id, source_catalog => {},
            }),
        ),
        FSM::VIAL::SourceProjection->semantic_projection_sha256(
            FSM::VIAL::Parser->parse_source({
                text => $terse, source_name => $vial_id, source_catalog => {},
            }),
        ),
        'normal and terse command outputs reparse to one semantic digest',
    );
};

subtest 'portable API returns the selected virtual plan and review route' => sub {
    my $sink = [];
    my $result = execute_vial_tool_request(plan_request(), {
        source_catalog => {},
        artifact_sink => $sink,
    });
    ok($result->{success}, 'public virtual plan succeeds');
    diag($json->encode($result->{diagnostics})) unless $result->{success};
    is($result->{schema}, $tooling->{result_schema}, 'API result schema is exact');
    is_deeply([sort keys %$result], [sort @result_keys], 'API result envelope is closed');
    is($result->{bridge_manifest}{schema}, $bridge->{manifest_schema}, 'bridge schema is exact');
    is($result->{plan}{schema}, $execution->{plan_schema}, 'plan schema is exact');
    is($result->{tool_manifest}{schema}, 'fsmgen.vial_tool_manifest.v1', 'tool manifest schema is exact');
    is_deeply(
        [map { $_->{layer} } @{$result->{bridge_manifest}{review_route}{stages}}],
        [qw(IAL2 IAL1 IAL0)],
        'IAL2 planning uses generated/reparsed IAL1 then generated IAL0',
    );
    ok(
        !$result->{bridge_manifest}{review_route}{direct_ial2_to_verification},
        'the public projection denies a direct IAL2 verification shortcut',
    );
    is_deeply([map { $_->{relpath} } @$sink], \@plan_paths, 'virtual artifact graph is exact and ordered');
    is_deeply($result->{artifacts}, $sink, 'result and caller sink contain equal graphs');
    is($result->{tool_manifest}{cleanup}{staging_identity}, undef, 'virtual mode has no staging root');
    ok(!$result->{tool_manifest}{cleanup}{atomic_commit_completed}, 'virtual mode claims no filesystem commit');
    my $public_json = $json->encode($result);
    my @forbidden = (
        '/Volumes/',
        join('/', '', 'private', 'tmp', ''),
        join('/', '', 'tmp', ''),
        qw(VIALSemanticIR VIALExecutionIR build_phase raise_objection),
    );
    ok(
        !grep { index($public_json, $_) >= 0 } @forbidden,
        'public result leaks no host path, private IR, or backend methodology object',
    );
};

subtest 'CLI planning publishes atomically and preserves collisions' => sub {
    make_path($test_root);
    my $out_rel = "$test_root_rel/plan";
    my ($status, $out, $err) = run_cli(
        'vial', 'plan',
        '--dut', $hial_id,
        '--fixture', 'base_output_arbitration',
        '--scenario', 'success',
        '--profile', 'core_directed_single_clock_execution_v1',
        '--outdir', $out_rel,
        '--json',
        $vial_id,
    );
    is($status, 0, 'documented explicit planning shape exits zero');
    is($err, '', 'documented explicit planning shape has no diagnostic');
    my $planned = JSON::PP->new->decode($out);
    is($planned->{status}, 'planned', 'first publication reports planned');
    is($planned->{tool_manifest}{artifact_root}, $out_rel, 'result records only the repository-relative root');
    is_deeply([tree_files(repo_path(split m{/}, $out_rel))], \@plan_paths, 'repository tree equals the virtual graph');
    ok($planned->{tool_manifest}{cleanup}{atomic_commit_completed}, 'manifest records atomic commit completion');
    ok($planned->{tool_manifest}{cleanup}{staging_removed}, 'manifest records staging removal');
    ok(
        !-e repo_path(split m{/}, $planned->{tool_manifest}{cleanup}{staging_identity}),
        'operation-owned staging root is absent after publication',
    );

    my ($again_status, $again_out, $again_err) = run_cli(
        'vial', 'plan',
        '--dut', $hial_id,
        '--fixture', 'base_output_arbitration',
        '--scenario', 'success',
        '--profile', 'core_directed_single_clock_execution_v1',
        '--outdir', $out_rel,
        '--json',
        $vial_id,
    );
    is($again_status, 0, 'identical planning rerun exits zero');
    is(
        JSON::PP->new->decode($again_out)->{status},
        'unchanged',
        'identical tree reports unchanged',
    );
    is($again_err, '', 'identical rerun has no diagnostic');

    my $collision_rel = "$test_root_rel/collision";
    make_path(repo_path(split m{/}, $collision_rel));
    my $sentinel = repo_path(split m{/}, "$collision_rel/caller-owned.txt");
    write_file($sentinel, "caller owned\n");
    my ($collision_status, $collision_out, $collision_err) = run_cli(
        'vial', 'plan', '--dut', $hial_id,
        '--outdir', $collision_rel, $vial_id,
    );
    is($collision_status, 1, 'non-identical target fails');
    is($collision_out, '', 'collision produces no success output');
    like($collision_err, qr{Error \[VIAL_ARTIFACT_COLLISION\]}, 'collision uses the selected diagnostic');
    is(slurp($sentinel), "caller owned\n", 'collision does not overwrite caller content');

    my ($traversal_status, $traversal_out, $traversal_err) = run_cli(
        'vial', 'plan', '--dut', $hial_id,
        '--outdir', '../outside', $vial_id,
    );
    is($traversal_status, 2, 'traversal root fails before publication');
    is($traversal_out, '', 'traversal failure has no success output');
    like($traversal_err, qr{Error \[VIAL_TOOL_INVOCATION_ERROR\]}, 'traversal uses the invocation diagnostic');
};

subtest 'public run command remains joined to qualified runtime evidence' => sub {
    my ($entrypoint) = grep {
        /^fsmgen vial run /
    } @{$tooling->{implementation_entrypoints}};
    is(
        $entrypoint,
        'fsmgen vial run --dut HIAL_SOURCE --backend sv_portable_verilator [RUN_OPTIONS] SOURCE.vial',
        'machine contract selects the documented public backend',
    );
    like(
        $chapter,
        qr{[.]\/bin\/fsmgen vial run \\\n+  --dut ppif/ahb_lite_subordinate[.]ppif \\\n+  --backend sv_portable_verilator},
        'chapter command uses the selected backend and checked HIAL source',
    );
    like(
        $runtime_test,
        qr{'vial', 'run', '--dut', \$hial_id, '--backend', 'sv_portable_verilator'},
        'independent runtime regression executes the same public route',
    );
    like(
        $runtime_test,
        qr{verification-result-manifest\\[.]json},
        'independent runtime regression validates normalized result publication',
    );

    my $unsupported = plan_request();
    $unsupported->{action} = 'run';
    $unsupported->{options}{backend_profile} = 'not_a_public_backend';
    my $sink = [];
    my $result = execute_vial_tool_request($unsupported, {
        source_catalog => {},
        artifact_sink => $sink,
        repository_root => $repo_root,
    });
    ok(!$result->{success}, 'unsupported backend fails closed');
    is($result->{diagnostics}[0]{code}, 'VIAL_BACKEND_UNSUPPORTED', 'unsupported backend is diagnosed exactly');
    is_deeply($sink, [], 'unsupported backend publishes no virtual artifact');
    is($result->{bridge_manifest}, undef, 'unsupported run leaks no partial bridge');
    is($result->{plan}, undef, 'unsupported run leaks no partial plan');
    is($result->{result_manifest}, undef, 'unsupported run invents no result');
};

subtest 'hostile lifecycle-document mutations fail closed' => sub {
    for my $token (
        'normal_v1',
        'direct IAL0',
        $tooling->{request_schema},
        $bridge->{manifest_schema},
        $execution->{plan_schema},
        'virtual',
        'unchanged',
        'VIAL_ARTIFACT_COLLISION',
        'private IR or backend construction APIs',
    ) {
        my $mutated = $chapter;
        my $replacements = ($mutated =~ s/\Q$token\E/removed-lifecycle-token/g);
        $replacements
            or die "cannot mutate lifecycle token '$token'\n";
        ok(
            scalar(lifecycle_errors($mutated)),
            "removing $token is rejected",
        );
    }
};

done_testing;

sub lifecycle_errors {
    my ($text) = @_;
    my @errors;

    for my $action (@{$tooling->{supported_actions}}) {
        push @errors, "missing action $action"
            if index($text, "`$action`") < 0;
    }
    for my $style (@{$tooling->{source_styles}}) {
        push @errors, "missing source style $style"
            if index($text, "`$style`") < 0;
    }
    for my $route ('direct IAL0', 'direct IAL1', 'generated and reparsed IAL1') {
        push @errors, "missing route $route" if index($text, $route) < 0;
    }
    for my $schema (
        $tooling->{request_schema},
        $tooling->{result_schema},
        $bridge->{manifest_schema},
        $execution->{plan_schema},
        $execution->{selected_future_schemas}{result_manifest}{schema},
        'fsmgen.vial_tool_manifest.v1',
        'fsmgen.verification_output_manifest.v2',
        $tooling_v2->{request_schema},
        $tooling_v2->{result_schema},
        'fsmgen.vial_plan.v2',
        $tooling_v2->{tool_manifest_schema},
        $tooling_v2->{migration_schema},
    ) {
        push @errors, "missing schema $schema" if index($text, $schema) < 0;
    }
    for my $code (@{$tooling->{diagnostics}}) {
        push @errors, "missing diagnostic $code" if index($text, $code) < 0;
    }
    for my $code (@{$tooling_v2->{diagnostics}}) {
        push @errors, "missing v2 diagnostic $code"
            if index($text, $code) < 0;
    }
    for my $action (@{$tooling_v2->{supported_actions}}) {
        push @errors, "missing v2 action $action"
            if index($text, "`$action`") < 0;
    }
    for my $style (@{$tooling_v2->{source_styles}}) {
        push @errors, "missing v2 source style $style"
            if index($text, "`$style`") < 0;
    }
    for my $key (@result_keys) {
        push @errors, "missing result key $key" if index($text, $key) < 0;
    }
    for my $token (
        'virtual',
        'repository',
        'unchanged',
        'initially empty caller-owned artifact sink',
        'repository-root-relative',
        'same graph',
        'failed plan or run returns no',
        'private IR or backend construction APIs',
        'mixed-language execution',
        'general cross-backend parity',
        '--language-version 2',
        'source_migration',
        'empty-family',
        'VIAL_VERSION_UNSUPPORTED',
    ) {
        push @errors, "missing boundary $token" if index($text, $token) < 0;
    }
    return @errors;
}

sub plan_request {
    return {
        schema => $tooling->{request_schema},
        schema_version => 1,
        action => 'plan',
        vial_source => source_envelope($vial_id, $vial_text, 'vial'),
        hial_source => source_envelope($hial_id, $hial_text, 'ppif'),
        options => {
            source_style => 'auto',
            output_style => undef,
            fixture_id => 'base_output_arbitration',
            scenario_ids => ['success'],
            execution_profile => 'core_directed_single_clock_execution_v1',
            backend_profile => undef,
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

sub write_file {
    my ($path, $text) = @_;
    open my $fh, '>:raw', $path or die "cannot write '$path': $!";
    print {$fh} $text or die "cannot write '$path': $!";
    close $fh or die "cannot close '$path': $!";
}

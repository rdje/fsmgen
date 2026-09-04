#!/usr/bin/env perl

use strict;
use warnings;

use bytes ();
use Digest::SHA qw(sha256_hex);
use File::Path qw(remove_tree);
use File::Spec;
use FindBin;
use IPC::Open3 qw(open3);
use JSON::PP ();
use Symbol qw(gensym);
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::RegressionCorpus qw(regression_corpus_entries);
use FSM::Support::VIALToolingContract qw(
    build_vial_tooling_contract
    build_vial_tooling_contract_v2
    vial_tooling_contract_v2_keys
);
use FSM::Support::VIALUsabilityArtifactQuality qw(
    build_vial_usability_artifact_quality_contract
);
use FSM::VIAL::Parser;
use FSM::VIAL::SourceProjection;
use FSM::VIAL::Tool qw(
    execute_vial_tool_request
    vial_tool_capabilities
    vial_tool_capabilities_v2
);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $v1_name = 'vial/ahb_subordinate_base_output_arbitration.vial';
my $v2_name = 'vial/ahb_subordinate_base_output_arbitration_v2.vial';
my $hial_name = 'ppif/ahb_lite_subordinate.ppif';
my $v1_text = slurp_raw(repo_path($v1_name));
my $v2_text = slurp_raw(repo_path($v2_name));
my $hial_text = slurp_raw(repo_path($hial_name));
my $json = JSON::PP->new->canonical(1)->utf8(1);
my $cli_root_rel = ".artifacts/test/vial-v2-public-foundation-$$";
my $cli_root = repo_path($cli_root_rel);

END {
    remove_tree($cli_root)
        if defined($cli_root) && -d $cli_root && !-l $cli_root;
}

my @result_keys_v2 = qw(
    schema schema_version action success status source_identities source_style
    semantic_report formatted_source bridge_manifest plan tool_manifest
    verification_output_manifest result_manifest artifacts capability_evidence
    support_accounting diagnostics implementation source_migration
);

sub repo_path {
    my ($relative) = @_;
    return File::Spec->catfile($repo_root, split m{/}, $relative);
}

sub slurp_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read $path: $!\n";
    local $/;
    my $text = <$fh> // '';
    close $fh or die "cannot close $path: $!\n";
    return $text;
}

sub source_envelope {
    my ($source_name, $text, $kind) = @_;
    return {
        source_id => $source_name,
        source_kind_hint => $kind,
        text => $text,
        encoding => 'utf-8',
        origin => 'memory',
        display_name => $source_name,
        canonical_id => undef,
        relative_path => $source_name,
        metadata => {},
    };
}

sub request_v2 {
    my (%override) = @_;
    my $action = delete($override{action}) // 'check';
    my $source_name = delete($override{source_name}) // $v2_name;
    my $text = delete($override{text}) // $v2_text;
    my $options = {
        source_style => $action eq 'capabilities' ? undef : 'auto',
        output_style => $action eq 'format' ? 'normal' : undef,
        fixture_id => ($action eq 'plan' || $action eq 'run')
            ? 'base_output_arbitration' : undef,
        scenario_ids => [],
        execution_profile => ($action eq 'plan' || $action eq 'run')
            ? 'core_directed_single_clock_execution_v2' : undef,
        backend_profile => undef,
        replay_manifest => undef,
        native_extension_catalogs => [],
        artifact_policy => ($action eq 'plan' || $action eq 'run')
            ? {mode => 'virtual', artifact_root => undef} : undef,
        quiet => JSON::PP::false,
        %{delete($override{options}) || {}},
    };
    return {
        schema => 'fsmgen.vial_tool_request.v2',
        schema_version => 2,
        action => $action,
        vial_source => $action eq 'capabilities'
            ? undef : source_envelope($source_name, $text, 'vial'),
        hial_source => ($action eq 'plan' || $action eq 'run')
            ? source_envelope($hial_name, $hial_text, 'ppif') : undef,
        options => $options,
        %override,
    };
}

sub request_v1_check {
    return {
        schema => 'fsmgen.vial_tool_request.v1',
        schema_version => 1,
        action => 'check',
        vial_source => source_envelope($v1_name, $v1_text, 'vial'),
        hial_source => undef,
        options => {
            source_style => 'auto', output_style => undef,
            fixture_id => undef, scenario_ids => [],
            execution_profile => undef, backend_profile => undef,
            replay_manifest => undef, native_extension_catalogs => [],
            artifact_policy => undef, quiet => JSON::PP::false,
        },
    };
}

sub environment {
    my ($catalog, $sink) = @_;
    return {source_catalog => $catalog || {}, artifact_sink => $sink || []};
}

sub changed {
    my ($source, $before, $after, $label) = @_;
    my $changed = $source;
    my $count = ($changed =~ s/\Q$before\E/$after/);
    die "$label mutation did not match exactly once\n" unless $count == 1;
    return $changed;
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

subtest 'v1 remains byte-exact while v2 capability truth is distinct' => sub {
    my $v1_contract = build_vial_tooling_contract();
    is(
        sha256_hex($json->encode($v1_contract)),
        '42db05da519dffd97c3e40ec254c82d09b5f20ef53a849e53025b976f5aded4e',
        'the pre-v2 public tooling contract remains byte-exact',
    );
    is_deeply(vial_tool_capabilities(), $v1_contract,
        'the legacy no-argument capability API remains version 1');

    my $contract = build_vial_tooling_contract_v2();
    is_deeply([sort keys %$contract],
        [sort @{vial_tooling_contract_v2_keys()}],
        'the v2 capability contract is closed');
    is_deeply(vial_tool_capabilities_v2(), $contract,
        'the v2 capability API returns the canonical defensive contract');
    is_deeply($contract->{supported_actions},
        [qw(capabilities check format migrate plan)],
        'v2 advertises only implemented public actions');
    is_deeply($contract->{unavailable_actions}, ['run'],
        'v2 run is explicitly unavailable');
    my %capability = map { $_ => 1 } @{$contract->{capabilities}};
    ok($capability{'vial.source.v2'}
        && $capability{'vial.semantic_ir.v2'}
        && $capability{'vial.source_migration.v1'}
        && $capability{'vial.plan.v2'},
        'v2 source, semantic, migration, and empty-plan capabilities are exact');
    is_deeply([sort grep { /\Avial[.]family[.]/ } keys %capability], [qw(
        vial.family.lifecycle_control.deadline.v1
        vial.family.lifecycle_control.v1
    )], 'only the implemented lifecycle family is advertised');
    ok(!$capability{'vial.backend.sv_portable_verilator.v2'}
        && !$capability{'vial.result_manifest.v2'},
        'no v2 backend or complete-result capability is advertised');
};

subtest 'v2 check and format expose one closed version-aware source result' => sub {
    my $checked = execute_vial_tool_request(request_v2(), environment());
    ok($checked->{success}, 'v2 check succeeds');
    is($checked->{schema}, 'fsmgen.vial_tool_result.v2',
        'v2 check uses its distinct result schema');
    is_deeply([sort keys %$checked], [sort @result_keys_v2],
        'v2 result exposes exactly its selected keys');
    is($checked->{source_style}, 'normal_v2',
        'v2 check reports its versioned style');
    is($checked->{semantic_report}{schema}, 'fsmgen.vial_semantic_report.v2',
        'v2 check returns only the sanitized semantic report');
    is_deeply($checked->{artifacts}, [], 'v2 check emits no artifact');

    my $import_name = 'vial/v2_public_shared.vial';
    my $import = changed(
        $v2_text,
        'package ahb_subordinate_base_output_arbitration',
        'package v2_public_shared',
        'v2 public import package',
    );
    my $root = changed(
        $v2_text, '(imports)',
        qq{(imports (import shared "$import_name"))},
        'v2 public root import',
    );
    is_deeply(FSM::VIAL::SourceProjection->import_source_names_v2({
        text => $root, source_name => $v2_name,
    }), [$import_name], 'v2 import discovery exposes authored catalog paths');
    my $imported = execute_vial_tool_request(request_v2(text => $root),
        environment({$import_name => $import}));
    ok($imported->{success}, 'v2 public check resolves a caller-owned catalog');
    is_deeply([map { $_->{source_name} } @{$imported->{source_identities}}],
        [$v2_name, $import_name],
        'v2 public result preserves root-then-depth-first source order');

    my $terse = execute_vial_tool_request(request_v2(
        action => 'format', options => {output_style => 'terse'},
    ), environment());
    ok($terse->{success}, 'v2 terse format succeeds');
    like($terse->{formatted_source}, qr/\A\(vial 2\n/,
        'v2 terse format preserves language version two');
    is($terse->{capability_evidence}{semantic_projection_sha256},
        $checked->{capability_evidence}{semantic_projection_sha256},
        'v2 normal and terse public routes have one semantic identity');
    is($terse->{capability_evidence}{compatibility_projection_sha256},
        $checked->{capability_evidence}{compatibility_projection_sha256},
        'v2 source routes expose one base compatibility identity');

    my $wrong = execute_vial_tool_request(request_v2(
        text => $v1_text, source_name => $v1_name,
    ), environment());
    ok(!$wrong->{success}, 'a v2 request rejects v1 source');
    is($wrong->{diagnostics}[0]{code}, 'VIAL_VERSION_UNSUPPORTED',
        'the mismatch names the version boundary');
    is_deeply([sort keys %{$wrong->{diagnostics}[0]}], [sort qw(
        schema schema_version severity code phase message semantic_path
        source_location notes
    )], 'v2 public diagnostics are closed');

    my $legacy = execute_vial_tool_request(
        request_v1_check(), environment(),
    );
    is($legacy->{schema}, 'fsmgen.vial_tool_result.v1',
        'an unchanged v1 request still returns the v1 result envelope');
    is($legacy->{source_style}, 'normal_v1',
        'the v1 request never upgrades its source');
};

subtest 'migration is deterministic, whole-catalog, mapped, and non-mutating' => sub {
    my $sink = [];
    my $request = request_v2(
        action => 'migrate', source_name => $v1_name, text => $v1_text,
    );
    my $first = execute_vial_tool_request($request, environment({}, $sink));
    my $second = execute_vial_tool_request($request, environment());
    ok($first->{success}, 'v1-to-v2 migration succeeds');
    is($first->{status}, 'migrated', 'migration status is exact');
    is_deeply($first, $second, 'migration is byte-deterministic');
    is_deeply($sink, [], 'migration writes no virtual artifact');
    is_deeply($first->{artifacts}, [], 'migration returns no artifact graph');
    my $migration = $first->{source_migration};
    is_deeply([sort keys %$migration], [sort qw(
        schema schema_version source_language_version target_language_version
        input_style output_style sources compatibility_projection_sha256
        diagnostics
    )], 'migration result has exactly its selected keys');
    is($migration->{schema}, 'fsmgen.vial_source_migration.v1',
        'migration schema identity is exact');
    is_deeply([$migration->{source_language_version},
        $migration->{target_language_version}], [1, 2],
        'migration direction is explicit');
    is_deeply([$migration->{input_style}, $migration->{output_style}],
        [qw(normal_v1 preserve_v2)], 'default migration preserves source style');
    is(scalar(@{$migration->{sources}}), 1,
        'single-source input returns one source record');
    my $record = $migration->{sources}[0];
    is_deeply([sort keys %$record], [sort qw(
        source_name input_sha256 output_sha256 formatted_source source_map
    )], 'migration source record is closed');
    is($record->{input_sha256}, sha256_hex($v1_text),
        'migration identifies original bytes');
    is($record->{output_sha256}, sha256_hex($record->{formatted_source}),
        'migration identifies returned bytes');
    my $output_ir = FSM::VIAL::Parser->parse_source({
        text => $record->{formatted_source}, source_name => $v1_name,
        source_catalog => {},
    });
    is($output_ir->language_version, 2,
        'returned source parses as VIAL language version two');
    my $input_ir = FSM::VIAL::Parser->parse_source({
        text => $v1_text, source_name => $v1_name, source_catalog => {},
    });
    is($migration->{compatibility_projection_sha256},
        FSM::VIAL::SourceProjection->compatibility_projection_sha256($input_ir),
        'migration publishes the independently derived input compatibility digest');
    is($migration->{compatibility_projection_sha256},
        FSM::VIAL::SourceProjection->compatibility_projection_sha256($output_ir),
        'the output independently reproduces the same compatibility digest');
    ok(@{$record->{source_map}} > 100,
        'migration returns a substantive semantic-path source map');
    is_deeply([map { $_->{semantic_path} } @{$record->{source_map}}],
        [sort map { $_->{semantic_path} } @{$record->{source_map}}],
        'migration source map is path-ordered');
    my ($closed_maps, $relative_maps, $bounded_maps) = (1, 1, 1);
    for my $entry (@{$record->{source_map}}) {
        $closed_maps &&= $json->encode([sort keys %$entry]) eq
            $json->encode([sort qw(
                semantic_path input_location output_location
            )]);
        $relative_maps &&= $entry->{input_location}{source_name} eq $v1_name
            && $entry->{output_location}{source_name} eq $v1_name;
        $bounded_maps &&=
            $entry->{input_location}{end_byte_exclusive}
                <= bytes::length($v1_text)
            && $entry->{output_location}{end_byte_exclusive}
                <= bytes::length($record->{formatted_source});
    }
    ok($closed_maps, 'every migration map entry has the exact closed shape');
    ok($relative_maps,
        'every migration map location retains its repository-relative source');
    ok($bounded_maps, 'every migration input and output span is in range');

    my $import_name = 'vial/migration_shared.vial';
    my $import = changed(
        $v1_text,
        'package ahb_subordinate_base_output_arbitration',
        'package migration_shared',
        'migration import package',
    );
    my $root = changed(
        $v1_text, '(imports)',
        qq{(imports (import shared "$import_name"))},
        'migration root import',
    );
    my $catalog_result = execute_vial_tool_request(request_v2(
        action => 'migrate', source_name => $v1_name, text => $root,
        options => {output_style => 'terse'},
    ), environment({$import_name => $import}));
    ok($catalog_result->{success}, 'whole imported catalog migrates');
    is_deeply(
        [map { $_->{source_name} }
            @{$catalog_result->{source_migration}{sources}}],
        [$v1_name, $import_name],
        'migration preserves root-then-depth-first authored source order',
    );
    is($catalog_result->{source_migration}{output_style}, 'terse_v2',
        'one explicit output style applies to the whole catalog');
    like($_->{formatted_source}, qr/\A\(vial 2\n/,
        "$_->{source_name} is canonical terse v2")
        for @{$catalog_result->{source_migration}{sources}};

    my $v2_import = changed(
        $v2_text,
        'package ahb_subordinate_base_output_arbitration',
        'package migration_shared',
        'mixed-version migration import package',
    );
    my $mixed = execute_vial_tool_request(request_v2(
        action => 'migrate', source_name => $v1_name, text => $root,
    ), environment({$import_name => $v2_import}));
    ok(!$mixed->{success}, 'mixed-version migration catalog fails closed');
    is($mixed->{diagnostics}[0]{code}, 'VIAL_IMPORT_VERSION_MISMATCH',
        'mixed-version migration preserves the exact import diagnostic');
    is_deeply($mixed->{source_migration}{sources}, [],
        'mixed-version migration publishes no partial source records');

    my $reverse = execute_vial_tool_request(request_v2(
        action => 'migrate', source_name => $v2_name, text => $v2_text,
    ), environment());
    ok(!$reverse->{success}, 'v2 input does not reverse-migrate');
    is($reverse->{diagnostics}[0]{code}, 'VIAL_MIGRATION_ERROR',
        'reverse migration has the exact failure code');
    is_deeply($reverse->{source_migration}{sources}, [],
        'failed reverse migration returns no source record');
    is($reverse->{source_migration}{compatibility_projection_sha256}, undef,
        'failed reverse migration returns no compatibility digest');
};

subtest 'v2 empty-base planning is atomic and run is unavailable pre-artifact' => sub {
    my $sink = [];
    my $planned = execute_vial_tool_request(
        request_v2(action => 'plan'), environment({}, $sink),
    );
    ok($planned->{success}, 'v2 empty-base plan succeeds');
    is($planned->{plan}{schema}, 'fsmgen.vial_plan.v2',
        'plan has a distinct v2 schema');
    is($planned->{tool_manifest}{schema}, 'fsmgen.vial_tool_manifest.v2',
        'tool manifest has a distinct v2 schema');
    is($planned->{bridge_manifest}{schema},
        'fsmgen.hial_vial_bridge_manifest.v1',
        'unchanged HIAL facts retain the v1 bridge schema');
    is_deeply($planned->{plan}{semantic_families}, [],
        'foundation plan carries no expressive family');
    is_deeply([map { $_->{relpath} } @{$planned->{artifacts}}],
        [sort map { $_->{relpath} } @{$planned->{artifacts}}],
        'v2 virtual artifact graph is path-sorted');
    is_deeply($sink, $planned->{artifacts},
        'successful v2 plan publishes one complete virtual sink');
    my ($plan_record) = grep { $_->{role} eq 'vial_plan' }
        @{$planned->{tool_manifest}{artifacts}};
    is($plan_record->{schema}, 'fsmgen.vial_plan.v2',
        'persisted plan metadata names the v2 plan schema');

    my $run_sink = [];
    my $run = execute_vial_tool_request(
        request_v2(action => 'run'), environment({}, $run_sink),
    );
    ok(!$run->{success}, 'v2 run fails closed');
    is($run->{diagnostics}[0]{code}, 'VIAL_VERSION_UNSUPPORTED',
        'v2 run names the unavailable versioned route');
    is($run->{capability_evidence}{action_state}{maturity}, 'unavailable',
        'run capability evidence is explicitly unavailable');
    is_deeply($run_sink, [], 'rejected v2 run publishes no virtual artifact');
    is_deeply($run->{artifacts}, [], 'rejected v2 run returns no artifact');
    is($run->{plan}, undef, 'rejected v2 run does not leak a private plan');
};

subtest 'CLI selects v2 explicitly and preserves the v1 default' => sub {
    my ($v1_status, $v1_out, $v1_err) =
        run_cli(qw(vial capabilities --json));
    is($v1_status, 0, 'default capability CLI succeeds');
    is(JSON::PP->new->decode($v1_out)->{schema},
        'fsmgen.vial_tool_result.v1', 'CLI default remains v1');
    is($v1_err, '', 'default v1 capability CLI is quiet on stderr');

    my ($cap_status, $cap_out, $cap_err) = run_cli(
        qw(vial capabilities --language-version 2 --json),
    );
    is($cap_status, 0, 'explicit v2 capability CLI succeeds');
    my $capability = JSON::PP->new->decode($cap_out);
    is($capability->{schema}, 'fsmgen.vial_tool_result.v2',
        'explicit v2 capability CLI uses the v2 result schema');
    is($cap_err, '', 'v2 capability CLI is quiet on stderr');

    my ($check_status, $check_out, $check_err) = run_cli(
        'vial', 'check', '--language-version', '2', $v2_name,
    );
    is($check_status, 0, 'v2 check CLI succeeds');
    is($check_out, "VIAL check passed (normal_v2)\n",
        'v2 human check names its versioned style');
    is($check_err, '', 'v2 check CLI is quiet on stderr');

    my $before_sha = sha256_hex(slurp_raw(repo_path($v1_name)));
    my ($migration_status, $migration_out, $migration_err) = run_cli(
        'vial', 'migrate', '--language-version', '2', '--json', $v1_name,
    );
    is($migration_status, 0, 'v2 migration CLI succeeds');
    my $migration = JSON::PP->new->decode($migration_out);
    is($migration->{source_migration}{schema},
        'fsmgen.vial_source_migration.v1',
        'migration CLI returns the complete migration record');
    is($migration_err, '', 'migration CLI is quiet on stderr');
    is(sha256_hex(slurp_raw(repo_path($v1_name))), $before_sha,
        'migration CLI does not overwrite its v1 input');

    my ($plan_status, $plan_out, $plan_err) = run_cli(
        'vial', 'plan', '--language-version', '2',
        '--dut', $hial_name, '--outdir', $cli_root_rel, $v2_name,
    );
    is($plan_status, 0, 'v2 plan CLI succeeds');
    is($plan_out, "VIAL plan planned ($cli_root_rel)\n",
        'v2 plan reports the exact repository-relative root');
    is($plan_err, '', 'v2 plan CLI is quiet on stderr');
    ok(-f File::Spec->catfile($cli_root, 'vial-plan.json'),
        'v2 plan atomically publishes its plan artifact');
    my $published = JSON::PP->new->decode(
        slurp_raw(File::Spec->catfile($cli_root, 'vial-tool-manifest.json')),
    );
    is($published->{schema}, 'fsmgen.vial_tool_manifest.v2',
        'published CLI manifest retains the v2 identity');

    my $run_root_rel = "$cli_root_rel-run";
    my ($run_status, $run_out, $run_err) = run_cli(
        'vial', 'run', '--language-version', '2', '--dut', $hial_name,
        '--outdir', $run_root_rel, $v2_name,
    );
    is($run_status, 1, 'v2 unavailable run has a semantic failure exit');
    is($run_out, '', 'v2 unavailable run writes no success output');
    like($run_err, qr/^Error \[VIAL_VERSION_UNSUPPORTED\]/,
        'v2 unavailable run emits its stable diagnostic');
    ok(!-e repo_path($run_root_rel),
        'v2 unavailable run creates no artifact root');
};

subtest 'support and usability authorities include the exact shipped v2 frontier' => sub {
    my @entries = grep { $_->{id} =~ /\Afeature[.]vial_v2_public_/ }
        regression_corpus_entries();
    is_deeply([map { $_->{id} } @entries], [qw(
        feature.vial_v2_public_source_migration
        feature.vial_v2_public_empty_base_plan
        feature.vial_v2_public_lifecycle_plan
    )], 'support corpus has exactly the three public v2 compiler entries');
    is_deeply([map { $_->{classification} } @entries],
        [qw(supported_smoke supported_smoke supported_smoke)],
        'source/migration, empty-base plan, and lifecycle plan have exact smoke support');
    my %contract_capability = map { $_ => 1 }
        @{build_vial_tooling_contract_v2()->{capabilities}};
    for my $entry (@entries) {
        ok(!scalar(grep { !$contract_capability{$_} }
                @{$entry->{required_capabilities}}),
            "$entry->{id} requires only advertised v2 capabilities");
        my %nonclaim = map { $_ => 1 } @{$entry->{explicit_nonclaims}};
        my $family_nonclaim = $entry->{id} =~ /lifecycle_plan\z/
            ? $nonclaim{non_lifecycle_expressive_family}
                && $nonclaim{result_production}
            : $nonclaim{expressive_family} && $nonclaim{result};
        ok($nonclaim{backend} && $nonclaim{runtime}
                && $nonclaim{parity} && $family_nonclaim,
            "$entry->{id} retains backend/family nonclaims");
    }
    my %fixture = map { $_ => 1 }
        @{build_vial_usability_artifact_quality_contract()
            ->{public_fixture_paths}};
    ok($fixture{$v1_name} && $fixture{$v2_name},
        'the executable author-quality gate owns both base source versions');
};

done_testing();

#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use IPC::Open3 qw(open3);
use JSON::PP ();
use Symbol qw(gensym);
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::RegressionCorpus qw(regression_corpus_entries);
use FSM::Support::VIALToolingContract qw(
    build_vial_tooling_contract
    vial_tooling_contract_keys
);
use FSM::VIAL::Parser;
use FSM::VIAL::SourceProjection;
use FSM::VIAL::Tool qw(execute_vial_tool_request vial_tool_capabilities);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $source_id = 'vial/ahb_subordinate_base_output_arbitration.vial';
my $source = slurp_raw(File::Spec->catfile($repo_root, split m{/}, $source_id));
my $json = JSON::PP->new->canonical;
my @result_keys = qw(
    schema schema_version action success status source_identities source_style
    semantic_report formatted_source bridge_manifest plan tool_manifest
    verification_output_manifest result_manifest artifacts capability_evidence
    support_accounting diagnostics implementation
);

sub request {
    my (%override) = @_;
    my $action = $override{action} || 'check';
    my $options = {
        source_style => $action eq 'capabilities' ? undef : 'auto',
        output_style => $action eq 'format' ? 'normal' : undef,
        fixture_id => undef,
        scenario_ids => [],
        execution_profile => undef,
        backend_profile => undef,
        replay_manifest => undef,
        native_extension_catalogs => [],
        artifact_policy => undef,
        quiet => JSON::PP::false,
        %{$override{options} || {}},
    };
    return {
        schema => 'fsmgen.vial_tool_request.v1',
        schema_version => 1,
        action => $action,
        vial_source => $action eq 'capabilities' ? undef : {
            source_id => $source_id,
            source_kind_hint => 'vial',
            text => exists($override{text}) ? $override{text} : $source,
            encoding => 'utf-8',
            origin => 'memory',
            display_name => $source_id,
            canonical_id => undef,
            relative_path => $source_id,
            metadata => {},
        },
        hial_source => undef,
        options => $options,
    };
}

sub environment {
    return { source_catalog => {}, artifact_sink => [] };
}

sub run_cli {
    my (@args) = @_;
    my $stderr = gensym;
    my $pid = open3(
        my $stdin,
        my $stdout,
        $stderr,
        $^X,
        File::Spec->catfile($repo_root, 'bin', 'fsmgen'),
        @args,
    );
    close $stdin;
    local $/;
    my $out = <$stdout> // '';
    my $err = <$stderr> // '';
    waitpid($pid, 0);
    return ($? >> 8, $out, $err);
}

subtest 'normal and terse are deterministic projections of one semantic meaning' => sub {
    my $normal = FSM::VIAL::SourceProjection->format_source({
        text => $source,
        source_name => $source_id,
        output_style => 'normal',
    });
    my $terse = FSM::VIAL::SourceProjection->format_source({
        text => $source,
        source_name => $source_id,
        output_style => 'terse',
    });
    is($normal->{input_style}, 'normal', 'checked source is detected as normal');
    is($terse->{output_style}, 'terse', 'terse output identity is explicit');
    like($normal->{text}, qr/\A\(vial\n  \(version 1\)/, 'normal output uses the explicit version wrapper');
    like($terse->{text}, qr/\A\(vial 1\n  \(package/, 'terse output uses the integer root discriminator');
    unlike($terse->{text}, qr/^    \((?:imports|types|transactions|models|scoreboards|fixtures)\b/m, 'terse package omits declaration-family wrappers');
    unlike($terse->{text}, qr/^        \((?:scenarios|steps)\b/m, 'terse fixture/scenario omit scenarios and steps wrappers');
    unlike($normal->{text}, qr/\r/, 'normal output uses LF only');
    unlike($terse->{text}, qr/\r/, 'terse output uses LF only');
    like($normal->{text}, qr/\n\z/, 'normal output has a final newline');
    unlike($normal->{text}, qr/\n\n\z/, 'normal output has exactly one final newline');

    my $normal_ir = FSM::VIAL::Parser->parse_source({
        text => $normal->{text}, source_name => $source_id, source_catalog => {},
    });
    my $terse_ir = FSM::VIAL::Parser->parse_source({
        text => $terse->{text}, source_name => $source_id, source_catalog => {},
    });
    my $normal_digest = FSM::VIAL::SourceProjection->semantic_projection_sha256($normal_ir);
    my $terse_digest = FSM::VIAL::SourceProjection->semantic_projection_sha256($terse_ir);
    is($terse_digest, $normal_digest, 'normal and terse reparses have one provenance-free meaning digest');
    is(
        FSM::VIAL::SourceProjection->format_source({
            text => $terse->{text}, source_name => $source_id, output_style => 'terse',
        })->{text},
        $terse->{text},
        'terse formatting is byte-idempotent',
    );
    is(
        FSM::VIAL::SourceProjection->format_source({
            text => $terse->{text}, source_name => $source_id, output_style => 'normal',
        })->{text},
        $normal->{text},
        'terse-to-normal formatting reaches the same canonical normal bytes',
    );

    my $out_of_order = $terse->{text};
    $out_of_order =~ s/(\n    \(scoreboard accepted_writes)/\n    (type late_t (logic 1))$1/
        or die 'terse declaration-order mutation did not match';
    my $out_of_order_check = FSM::VIAL::Parser->check_source({
        text => $out_of_order, source_name => $source_id, source_catalog => {},
    });
    ok(!$out_of_order_check->{ok}, 'terse declaration-family reordering fails closed');
    is($out_of_order_check->{diagnostics}[0]{code}, 'VIAL_SOURCE_STYLE_ERROR', 'terse declaration order has the style diagnostic');

    my $normal_without_steps = $normal->{text};
    $normal_without_steps =~ s/\n            \(steps\n/\n/
        or die 'normal steps-wrapper opening mutation did not match';
    $normal_without_steps =~ s/\(scoreboard_check writes\)\)\)/\(scoreboard_check writes\)\)/
        or die 'normal steps-wrapper closing mutation did not match';
    my $normal_without_steps_check = FSM::VIAL::Parser->check_source({
        text => $normal_without_steps, source_name => $source_id, source_catalog => {},
    });
    ok(!$normal_without_steps_check->{ok}, 'normal source with terse scenario actions fails closed');
    is($normal_without_steps_check->{diagnostics}[0]{code}, 'VIAL_SOURCE_STYLE_ERROR', 'flattened normal actions have the style diagnostic');
};

subtest 'portable API exposes closed defensive source-only results' => sub {
    my $checked = execute_vial_tool_request(request(), environment());
    ok($checked->{success}, 'public check succeeds');
    is($checked->{status}, 'checked', 'check status is exact');
    is($checked->{source_style}, 'normal_v1', 'check reports detected source projection');
    is_deeply([sort keys %{$checked}], [sort @result_keys], 'result envelope has exactly the selected keys');
    is_deeply($checked->{artifacts}, [], 'check emits no virtual artifact');
    is($checked->{bridge_manifest}, undef, 'check does not bind HIAL');
    is($checked->{plan}, undef, 'check does not expose a plan');
    is($checked->{result_manifest}, undef, 'check does not claim a runtime result');
    like($checked->{capability_evidence}{semantic_projection_sha256}, qr/\A[0-9a-f]{64}\z/, 'check reports exact meaning digest evidence');
    ok(!contains_non_json_reference($checked), 'check result contains JSON-safe data only');

    my $formatted = execute_vial_tool_request(request(
        action => 'format',
        options => { source_style => 'auto', output_style => 'terse' },
    ), environment());
    ok($formatted->{success}, 'public terse format succeeds');
    is($formatted->{status}, 'formatted', 'format status is exact');
    is(FSM::VIAL::SourceProjection->source_style({
        text => $formatted->{formatted_source}, source_name => $source_id,
    }), 'terse', 'formatted result is valid terse source');
    is(
        $formatted->{capability_evidence}{semantic_projection_sha256},
        $checked->{capability_evidence}{semantic_projection_sha256},
        'format proves the same semantic projection as check',
    );
    is_deeply($formatted->{artifacts}, [], 'format emits no virtual artifact');

    $checked->{semantic_report}{packages}[0]{name} = 'mutated';
    $checked->{capability_evidence}{capabilities}[0] = 'mutated';
    my $again = execute_vial_tool_request(request(), environment());
    isnt($again->{semantic_report}{packages}[0]{name}, 'mutated', 'semantic report is defensive across calls');
    isnt($again->{capability_evidence}{capabilities}[0], 'mutated', 'capability evidence is defensive across calls');

    my $imported = $source;
    $imported =~ s/package ahb_subordinate_base_output_arbitration/package imported_fixture/
        or die 'imported package mutation did not match';
    my $importing = $source;
    $importing =~ s/\(imports\)/\(imports (import common "vial\/common.vial")\)/
        or die 'import clause mutation did not match';
    $importing =~ s/\(address \(type address_t\)\)/\(address (type common.address_t)\)/
        or die 'qualified import mutation did not match';
    my $imported_result = execute_vial_tool_request(
        request(text => $importing),
        { source_catalog => { 'vial/common.vial' => $imported }, artifact_sink => [] },
    );
    ok($imported_result->{success}, 'public API resolves caller-owned source-catalog imports');
    is_deeply(
        [map { $_->{source_name} } @{$imported_result->{source_identities}}],
        [$source_id, 'vial/common.vial'],
        'public result preserves deterministic root-then-import source identity',
    );
};

subtest 'API invocation, style, syntax, and host-object boundaries fail closed' => sub {
    my $mismatch = execute_vial_tool_request(request(options => { source_style => 'terse' }), environment());
    ok(!$mismatch->{success}, 'explicit source-style mismatch fails');
    is($mismatch->{diagnostics}[0]{code}, 'VIAL_SOURCE_STYLE_ERROR', 'style mismatch has the selected code');

    my $mixed_text = $source;
    $mixed_text =~ s/\(version 1\)/1/ or die 'style mutation did not match';
    my $mixed = execute_vial_tool_request(request(text => $mixed_text), environment());
    ok(!$mixed->{success}, 'terse root with normal wrappers fails');
    is($mixed->{diagnostics}[0]{code}, 'VIAL_SOURCE_STYLE_ERROR', 'mixed source uses the source-style diagnostic');

    my $invalid = execute_vial_tool_request(request(text => "(vial\n"), environment());
    ok(!$invalid->{success}, 'invalid source fails');
    is($invalid->{diagnostics}[0]{code}, 'VIAL_PARSE_ERROR', 'existing parser code crosses the public boundary');
    is_deeply(
        [sort keys %{$invalid->{diagnostics}[0]}],
        [sort qw(code severity message source_locations semantic_path related notes hints)],
        'public diagnostic has the exact closed key family',
    );
    ok(!exists($invalid->{diagnostics}[0]{source_location}), 'private singular diagnostic location does not leak');

    my $unknown = request();
    $unknown->{unexpected} = 1;
    my $unknown_result = execute_vial_tool_request($unknown, environment());
    is($unknown_result->{diagnostics}[0]{code}, 'VIAL_TOOL_INVOCATION_ERROR', 'unknown request key fails as invocation');
    like($unknown_result->{diagnostics}[0]{message}, qr/unknown key/, 'invocation diagnostic identifies unknown key');

    my $callback_environment = environment();
    $callback_environment->{source_catalog}{'vial/callback.vial'} = sub { return $source };
    my $callback = execute_vial_tool_request(request(), $callback_environment);
    is($callback->{diagnostics}[0]{code}, 'VIAL_TOOL_INVOCATION_ERROR', 'host callback fails before parsing');
    unlike($json->encode($callback), qr/(?:CODE|GLOB|SCALAR\()/, 'host callback identity is sanitized from result');

    my $invalid_quiet = request(options => { quiet => 2 });
    my $invalid_quiet_result = execute_vial_tool_request($invalid_quiet, environment());
    is($invalid_quiet_result->{diagnostics}[0]{code}, 'VIAL_TOOL_INVOCATION_ERROR', 'non-Boolean quiet value fails closed');

    my $plan = execute_vial_tool_request(request(action => 'plan'), environment());
    ok(!$plan->{success}, 'plan without its required HIAL source fails closed');
    is($plan->{diagnostics}[0]{code}, 'VIAL_TOOL_INVOCATION_ERROR', 'missing HIAL source fails invocation validation');
};

subtest 'CLI is one adapter over the API and preserves legacy dispatch' => sub {
    my ($cap_status, $cap_out, $cap_err) = run_cli(qw(vial capabilities));
    is($cap_status, 0, 'human capabilities exits zero');
    like($cap_out, qr/VIAL tooling: capabilities, check, format, plan, run/, 'human capabilities names exact actions');
    is($cap_err, '', 'human capabilities has no stderr');

    my ($json_status, $json_out, $json_err) = run_cli(qw(vial capabilities --json));
    is($json_status, 0, 'JSON capabilities exits zero');
    my $cap_result = JSON::PP->new->decode($json_out);
    is($cap_result->{schema}, 'fsmgen.vial_tool_result.v1', 'CLI JSON uses the API result schema');
    is_deeply($cap_result->{capability_evidence}{supported_actions}, [qw(capabilities check format plan run)], 'CLI capability actions are exact');
    is($json_err, '', 'JSON capabilities has no stderr');

    my ($check_status, $check_out, $check_err) = run_cli('vial', 'check', $source_id);
    is($check_status, 0, 'human check exits zero');
    is($check_out, "VIAL check passed (normal_v1)\n", 'human check output is stable');
    is($check_err, '', 'human check has no stderr');

    my ($quiet_status, $quiet_out, $quiet_err) = run_cli('vial', 'check', '--quiet', $source_id);
    is($quiet_status, 0, 'quiet check exits zero');
    is($quiet_out, '', 'quiet check suppresses success text');
    is($quiet_err, '', 'quiet check has no stderr');

    my ($format_status, $format_out, $format_err) = run_cli('vial', 'format', '--style', 'terse', $source_id);
    is($format_status, 0, 'CLI terse format exits zero');
    is(FSM::VIAL::SourceProjection->source_style({ text => $format_out, source_name => $source_id }), 'terse', 'CLI emits valid terse source');
    is($format_err, '', 'CLI format has no stderr');

    my ($bad_status, $bad_out, $bad_err) = run_cli('vial', 'check', '--language', 'sv', $source_id);
    is($bad_status, 2, 'legacy option under vial fails with invocation exit');
    is($bad_out, '', 'human invocation failure does not write stdout');
    like($bad_err, qr/Error \[VIAL_TOOL_INVOCATION_ERROR\]/, 'legacy option under vial is diagnosed by the VIAL parser');

    my ($path_status, $path_out, $path_err) = run_cli('vial', 'check', '../outside.vial');
    is($path_status, 2, 'traversal source exits with host/invocation failure');
    is($path_out, '', 'traversal failure does not write stdout');
    like($path_err, qr/Error \[VIAL_HOST_ERROR\]/, 'traversal source fails before filesystem access');

    my ($legacy_status, $legacy_out, $legacy_err) = run_cli('--capability-manifest');
    is($legacy_status, 0, 'legacy capability-manifest dispatch remains intact');
    is(JSON::PP->new->decode($legacy_out)->{manifest_schema_version}, 1, 'legacy command still returns the full manifest');
    is($legacy_err, '', 'legacy capability manifest has no stderr');
};

subtest 'capability and support accounting compose source tooling with shipped planning' => sub {
    my $contract = build_vial_tooling_contract();
    is_deeply([sort keys %{$contract}], [sort @{vial_tooling_contract_keys()}], 'tooling contract keys are exact');
    is_deeply($contract, vial_tool_capabilities(), 'public capability function returns the canonical contract');
    is_deeply($contract->{supported_actions}, [qw(capabilities check format plan run)], 'contract advertises source, plan, and run actions');
    ok($contract->{writes_files}, 'tooling contract records atomic filesystem planning writes');
    ok($contract->{public_embedding_api}, 'tooling contract advertises bounded public API');
    my %nonclaim = map { $_ => 1 } @{$contract->{explicit_nonclaims}};
    ok($nonclaim{complete_four_state} && $nonclaim{general_cross_backend_parity}, 'four-state/general-parity non-claims remain explicit');

    my $manifest = build_capability_manifest();
    is_deeply($manifest->{language_surface}{vial_tooling}, $contract, 'ordinary manifest embeds exact VIAL-only tooling contract');
    my ($entry) = grep { $_->{id} eq 'feature.vial_public_check_format' } regression_corpus_entries();
    ok($entry, 'support accounting has a distinct public source-tooling identity');
    is($entry->{coverage}, 'vial_public_check_format_cli_api', 'support coverage is exact');
    is_deeply(
        $entry->{required_capabilities},
        [@{$contract->{capabilities}}[0 .. 4]],
        'source-tooling support entry retains the exact source-only capability subset',
    );
};

sub contains_non_json_reference {
    my ($value) = @_;
    return 0 unless ref($value);
    return 0 if blessed_boolean($value);
    return 1 if ref($value) ne 'HASH' && ref($value) ne 'ARRAY';
    return scalar grep { contains_non_json_reference($value->{$_}) } keys %{$value}
        if ref($value) eq 'HASH';
    return scalar grep { contains_non_json_reference($_) } @{$value};
}

sub blessed_boolean {
    my ($value) = @_;
    return eval { $value->isa('JSON::PP::Boolean') } ? 1 : 0;
}

sub slurp_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "Cannot read $path: $!";
    local $/;
    my $text = <$fh>;
    close $fh or die "Cannot close $path: $!";
    return $text;
}

done_testing();

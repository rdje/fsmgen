#!/usr/bin/env perl

use strict;
use warnings;

use Digest::SHA qw(sha256_hex);
use JSON::PP ();
use Test::More;

use lib 'perl';

use FSM::VIAL::Backend::GHDLLifecycle;

my $JSON = JSON::PP->new->canonical(1);

subtest 'portable capture evidence is rebound to policy and object bytes' => sub {
    my ($session, $record) = portable_tool_state();
    ok(validate_state($session, $record),
        'exact portable tool capture evidence is admitted');

    my $timeout = clone($record);
    $timeout->{evidence}{capture}{timeout_seconds} = 11;
    rejects_state($session, $timeout,
        'foreign portable timeout evidence rejects');

    my $bytes = clone($record);
    $bytes->{evidence}{capture}{output_bytes} = 6;
    rejects_state($session, $bytes,
        'portable output bytes must equal the sealed transcript object');

    my $status = clone($record);
    $status->{evidence}{capture}{ok} = '1';
    rejects_state($session, $status,
        'string success cannot masquerade as supervisor boolean true');

    my $timing = clone($record);
    $timing->{evidence}{capture}{execution_ns} = 19;
    rejects_state($session, $timing,
        'portable capture timing arithmetic is authenticated');

    my $digest = clone($record);
    $digest->{evidence}{version_sha256} = 'f' x 64;
    rejects_state($session, $digest,
        'portable transcript digest must equal the sealed object identity');
};

subtest 'OSVVM capture evidence is rebound to its profile policy' => sub {
    my ($session, $record) = osvvm_analysis_state();
    ok(validate_state($session, $record),
        'exact OSVVM analysis capture evidence is admitted');

    my $limit = clone($record);
    $limit->{evidence}{captures}[0]{capture_limit_bytes} = 65_536;
    rejects_state($session, $limit,
        'foreign OSVVM provider capture ceiling rejects');

    my $empty = clone($record);
    $empty->{evidence}{captures}[0]{first_output_monotonic_ns} = 115;
    $empty->{evidence}{captures}[0]{exec_to_first_output_ns} = 5;
    $empty->{evidence}{captures}[0]{first_output_to_exit_ns} = 15;
    rejects_state($session, $empty,
        'zero-byte OSVVM capture cannot claim first-output timing');

    my $digest = clone($record);
    $digest->{evidence}{output_sha256}[0] = 'f' x 64;
    rejects_state($session, $digest,
        'OSVVM transcript digest must equal its sealed object identity');
};

subtest 'OSVVM runtime and report-set evidence is rebound to sealed objects' => sub {
    my ($session, $record) = osvvm_run_state();
    ok(validate_state($session, $record),
        'exact OSVVM runtime and report-set evidence is admitted');

    my $fixture_limit = clone($record);
    $fixture_limit->{evidence}{fixture_captures}[0]
        {capture_limit_bytes} = 8_388_608;
    rejects_state($session, $fixture_limit,
        'OSVVM fixture capture retains its distinct 64-MiB ceiling');

    my $reports = clone($record);
    $reports->{evidence}{provider_report_sha256}[0] = 'f' x 64;
    rejects_state($session, $reports,
        'OSVVM report-set digest must derive from all sealed report objects');

    my $determinism = clone($record);
    $determinism->{evidence}{deterministic} = JSON::PP::true;
    rejects_state($session, $determinism,
        'one runtime repetition cannot claim deterministic-rerun evidence');
};

done_testing();

sub portable_tool_state {
    my $transcript = object('tool_version_output', 'b', 7);
    return ({
        role => 'qualification',
        storage_context => {containment => 'lifecycle_process_group'},
        validation => {run_repetitions => 1},
        commands => {},
    }, {
        state => 'tool_verified',
        objects => [object('lifecycle_authority', 'a', 11), $transcript],
        evidence => {
            version_sha256 => $transcript->{sha256},
            capture => capture(10, 65_536, 7),
            workspace_files => [],
            workspace_sha256 => '0' x 64,
        },
    });
}

sub osvvm_analysis_state {
    my $provider = object('provider_analysis_output_00', 'd', 0);
    my $generated = object('generated_analysis_output', 'e', 0);
    return ({
        role => 'osvvm_qualification',
        storage_context => {containment => 'lifecycle_process_group'},
        validation => {run_repetitions => 1},
        commands => {
            provider_analyze => [[]],
            provider_reports => [],
            resource_controls => {
                version_timeout_seconds => 10,
                provider_analysis_timeout_seconds_per_source => 120,
                generated_analysis_timeout_seconds => 120,
                elaboration_timeout_seconds => 60,
                execution_timeout_seconds => 30,
                version_capture_limit_bytes => 65_536,
                provider_capture_limit_bytes => 8_388_608,
                fixture_capture_limit_bytes => 67_108_864,
            },
        },
    }, {
        state => 'analyzed',
        objects => [
            object('lifecycle_authority', 'a', 11),
            object('generated_settings', 'b', 13),
            object('tool_version_output', 'c', 7),
            $provider,
            $generated,
        ],
        evidence => {
            command_digests => ['1' x 64],
            captures => [capture(120, 8_388_608, 0)],
            output_sha256 => [$provider->{sha256}],
            generated_command_digest => '2' x 64,
            generated_capture => capture(120, 8_388_608, 0),
            generated_output_sha256 => $generated->{sha256},
            workspace_files => [],
            workspace_sha256 => '0' x 64,
        },
    });
}

sub osvvm_run_state {
    my @report_name = qw(
        OsvvmRun.yml AlertLogTop_alerts.yml AlertLogTop_cov.yml
        AlertLogTop_sb_slv.yml
    );
    my @report_object = map {
        object("provider_report_0_$_", $_ + 1, $_ + 1)
    } 0 .. $#report_name;
    my @report_identity = map {{
        name => $report_name[$_],
        bytes => $report_object[$_]{bytes},
        sha256 => $report_object[$_]{sha256},
    }} 0 .. $#report_name;
    my $fixture = object('fixture_runtime_output_0', 'd', 5);
    my $provider = object('provider_runtime_output_0', 'e', 6);
    my $resource = osvvm_resources();
    return ({
        role => 'osvvm_qualification',
        storage_context => {containment => 'lifecycle_process_group'},
        validation => {run_repetitions => 1},
        commands => {
            provider_analyze => [[]],
            provider_reports => [map {{
                name => $_,
                relpath => ".artifacts/tmp/tests/provider_reports/$_",
            }} @report_name],
            resource_controls => $resource,
        },
    }, {
        state => 'ran',
        objects => [
            object('lifecycle_authority', '6', 11),
            object('generated_settings', '7', 13),
            object('tool_version_output', '8', 7),
            object('provider_analysis_output_00', '9', 0),
            object('generated_analysis_output', 'a', 0),
            object('fixture_elaboration_output', 'b', 0),
            object('provider_probe_elaboration_output', 'c', 0),
            $fixture,
            $provider,
            @report_object,
        ],
        evidence => {
            command_digests => {
                fixture => '1' x 64,
                provider_probe => '2' x 64,
            },
            fixture_captures => [capture(
                $resource->{execution_timeout_seconds},
                $resource->{fixture_capture_limit_bytes},
                $fixture->{bytes},
            )],
            provider_captures => [capture(
                $resource->{execution_timeout_seconds},
                $resource->{provider_capture_limit_bytes},
                $provider->{bytes},
            )],
            fixture_output_sha256 => [$fixture->{sha256}],
            provider_output_sha256 => [$provider->{sha256}],
            provider_report_sha256 => [
                sha256_hex($JSON->encode(\@report_identity)),
            ],
            deterministic => JSON::PP::false,
            workspace_files => [],
            workspace_sha256 => '0' x 64,
        },
    });
}

sub osvvm_resources {
    return {
        version_timeout_seconds => 10,
        provider_analysis_timeout_seconds_per_source => 120,
        generated_analysis_timeout_seconds => 120,
        elaboration_timeout_seconds => 60,
        execution_timeout_seconds => 30,
        version_capture_limit_bytes => 65_536,
        provider_capture_limit_bytes => 8_388_608,
        fixture_capture_limit_bytes => 67_108_864,
    };
}

sub object {
    my ($kind, $hex, $bytes) = @_;
    return {
        kind => $kind,
        sha256 => $hex x 64,
        bytes => $bytes,
        executable => JSON::PP::false,
        relative_path => ".artifacts/tmp/tests/objects/$hex",
    };
}

sub capture {
    my ($timeout, $limit, $bytes) = @_;
    return {
        ok => JSON::PP::true,
        exit_code => 0,
        signal => 0,
        timed_out => JSON::PP::false,
        output_limited => JSON::PP::false,
        exec_failed => JSON::PP::false,
        exec_error => undef,
        started_monotonic_ns => 100,
        exec_handoff_monotonic_ns => 110,
        first_output_monotonic_ns => $bytes ? 120 : undef,
        finished_monotonic_ns => 130,
        spawn_to_exec_ns => 10,
        execution_ns => 20,
        exec_to_first_output_ns => $bytes ? 10 : undef,
        first_output_to_exit_ns => $bytes ? 10 : undef,
        containment => 'lifecycle_process_group',
        timeout_seconds => $timeout,
        capture_limit_bytes => $limit,
        output_bytes => $bytes,
    };
}

sub validate_state {
    my ($session, $record) = @_;
    my $ok = eval {
        FSM::VIAL::Backend::GHDLLifecycle::_validate_state_shape(
            $session, $record,
        );
        1;
    };
    return $ok ? 1 : 0;
}

sub rejects_state {
    my ($session, $record, $label) = @_;
    my $ok = eval {
        FSM::VIAL::Backend::GHDLLifecycle::_validate_state_shape(
            $session, $record,
        );
        1;
    };
    ok(!$ok, $label);
    isa_ok($@, 'FSM::VIAL::Backend::GHDLLifecycle::Failure');
    is(ref($@) ? $@->{code} : undef,
        'VIAL_GHDL_LIFECYCLE_STATE_ERROR',
        "$label uses state-admission authority");
}

sub clone {
    return $JSON->decode($JSON->encode($_[0]));
}

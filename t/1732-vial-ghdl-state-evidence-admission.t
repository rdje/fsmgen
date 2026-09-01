#!/usr/bin/env perl

use strict;
use warnings;

use Digest::SHA qw(sha256_hex);
use JSON::PP ();
use Test::More;

use lib 'perl';

use FSM::VIAL::Backend::GHDLLifecycle;

my $JSON = JSON::PP->new->canonical(1);

subtest 'admission and preparation evidence is reconstructed' => sub {
    my $session = portable_session();
    my $admitted = state_record($session, 'admitted');
    ok(validate_state($session, $admitted),
        'exact admitted evidence is accepted');

    my $authority = clone($admitted);
    $authority->{evidence}{authority_sha256} = 'f' x 64;
    rejects_state($session, $authority,
        'admitted authority digest must be reconstructed');

    my $workspace = clone($admitted);
    $workspace->{evidence}{workspace_sha256} = 'f' x 64;
    rejects_state($session, $workspace,
        'workspace digest must be reconstructed from its inventory');

    my $prepared = state_record($session, 'prepared');
    ok(validate_state($session, $prepared),
        'exact portable preparation evidence is accepted');

    my $source_count = clone($prepared);
    $source_count->{evidence}{source_count} = 3;
    rejects_state($session, $source_count,
        'portable source count must equal selected sources');

    my $library = clone($prepared);
    $library->{evidence}{library_identity} .= '-foreign';
    rejects_state($session, $library,
        'portable library identity must equal selected storage');

    my $osvvm_session = osvvm_session();
    my $osvvm_prepared = state_record($osvvm_session, 'prepared');
    ok(validate_state($osvvm_session, $osvvm_prepared),
        'exact OSVVM preparation evidence is accepted');

    my $settings = clone($osvvm_prepared);
    $settings->{evidence}{settings_sha256} = 'e' x 64;
    rejects_state($osvvm_session, $settings,
        'OSVVM settings digest must equal selected settings');

    my $libraries = clone($osvvm_prepared);
    $libraries->{evidence}{library_identities}{osvvm} .= '-foreign';
    rejects_state($osvvm_session, $libraries,
        'OSVVM library identities must equal selected storage');
};

subtest 'portable and OSVVM command evidence is reconstructed' => sub {
    my $session = portable_session();
    my $analyzed = state_record($session, 'analyzed');
    ok(validate_state($session, $analyzed),
        'exact portable analysis evidence is accepted');

    my $analysis = clone($analyzed);
    $analysis->{evidence}{command_digest} = 'f' x 64;
    rejects_state($session, $analysis,
        'portable analysis command digest must equal the selected command');

    my $elaborated = state_record($session, 'elaborated');
    ok(validate_state($session, $elaborated),
        'exact portable elaboration evidence is accepted');
    my $elaboration = clone($elaborated);
    $elaboration->{evidence}{command_digest} = 'f' x 64;
    rejects_state($session, $elaboration,
        'portable elaboration digest must equal the selected command');

    my $ran = state_record($session, 'ran');
    ok(validate_state($session, $ran),
        'exact portable runtime evidence is accepted');

    my $run = clone($ran);
    $run->{evidence}{command_digest} = 'f' x 64;
    rejects_state($session, $run,
        'portable run command digest must equal the selected command');

    my $osvvm_session = osvvm_session();
    my $osvvm = state_record($osvvm_session, 'analyzed');
    ok(validate_state($osvvm_session, $osvvm),
        'exact OSVVM analysis evidence is accepted');

    my $provider = clone($osvvm);
    $provider->{evidence}{command_digests}[0] = 'f' x 64;
    rejects_state($osvvm_session, $provider,
        'OSVVM provider command digest must equal the selected command');

    my $generated = clone($osvvm);
    $generated->{evidence}{generated_command_digest} = 'f' x 64;
    rejects_state($osvvm_session, $generated,
        'OSVVM generated command digest must equal the selected command');

    my $osvvm_elaborated = state_record($osvvm_session, 'elaborated');
    ok(validate_state($osvvm_session, $osvvm_elaborated),
        'exact OSVVM elaboration evidence is accepted');
    my $osvvm_elaboration = clone($osvvm_elaborated);
    $osvvm_elaboration->{evidence}{command_digests}[1] = 'f' x 64;
    rejects_state($osvvm_session, $osvvm_elaboration,
        'OSVVM elaboration digests must equal both selected commands');

    my $osvvm_ran = state_record($osvvm_session, 'ran');
    ok(validate_state($osvvm_session, $osvvm_ran),
        'exact OSVVM runtime command evidence is accepted');
    my $osvvm_run = clone($osvvm_ran);
    $osvvm_run->{evidence}{command_digests}{provider_probe} = 'f' x 64;
    rejects_state($osvvm_session, $osvvm_run,
        'OSVVM runtime digests must equal both selected commands');
};

subtest 'trace, result, and assembly evidence is rebound to sealed payloads' => sub {
    my $session = portable_session();
    my $trace_payload = {
        trace => {
            trace_sha256 => '7' x 64,
            record_count => 13,
        },
    };
    my $result_payload = {schema => 'focused-result', status => 'pass'};
    my $assembly_payload = {
        schema => 'fsmgen.vial_ghdl_lifecycle_assembly.v1',
        schema_version => 1,
        lifecycle_identity => $session->{lifecycle_identity},
        runtime_output_sha256 => '5' x 64,
        trace_validation_sha256 => sha256_hex(canonical_line($trace_payload)),
        normalized_result_sha256 => sha256_hex(canonical_line($result_payload)),
    };
    my %payload = (
        validated_trace => canonical_line($trace_payload),
        normalized_result => canonical_line($result_payload),
        assembly_payload => canonical_line($assembly_payload),
    );

    no warnings 'redefine';
    local *FSM::VIAL::Backend::GHDLLifecycle::_object_content_from = sub {
        my ($ignored_session, $ignored_objects, $kind) = @_;
        die "unexpected focused object '$kind'\n" unless exists $payload{$kind};
        return $payload{$kind};
    };

    my $trace = state_record($session, 'trace_validated', \%payload);
    ok(validate_state($session, $trace),
        'exact trace evidence is accepted');
    my $trace_count = clone($trace);
    $trace_count->{evidence}{record_count} = 12;
    rejects_state($session, $trace_count,
        'trace record count must equal the sealed validation payload');
    my $trace_digest = clone($trace);
    $trace_digest->{evidence}{validation_sha256} = 'f' x 64;
    rejects_state($session, $trace_digest,
        'trace validation digest must equal the sealed payload');

    my $result = state_record($session, 'result_produced', \%payload);
    ok(validate_state($session, $result),
        'exact result evidence is accepted');
    my $status = clone($result);
    $status->{evidence}{result_status} = 'fail';
    rejects_state($session, $status,
        'result status must equal the admitted passing payload contract');
    my $result_digest = clone($result);
    $result_digest->{evidence}{result_sha256} = 'f' x 64;
    rejects_state($session, $result_digest,
        'result digest must equal the sealed normalized payload');

    my $assembled = state_record($session, 'assembled', \%payload);
    ok(validate_state($session, $assembled),
        'exact assembly evidence is accepted');
    my $count = clone($assembled);
    $count->{evidence}{object_count}--;
    rejects_state($session, $count,
        'assembly object count must equal the exact state inventory');
    my $assembly_digest = clone($assembled);
    $assembly_digest->{evidence}{assembly_sha256} = 'f' x 64;
    rejects_state($session, $assembly_digest,
        'assembly digest must equal the sealed assembly payload');
};

done_testing();

sub portable_session {
    return {
        role => 'qualification',
        lifecycle_identity => 'lifecycle/' . ('1' x 64),
        authority => {profile => 'vhdl_portable_ghdl'},
        library_rel => '.artifacts/tmp/tests/vial-ghdl-state-evidence/work',
        source_set => [
            {relpath => 'generated/one.vhd'},
            {relpath => 'generated/two.vhd'},
        ],
        storage_context => {containment => 'lifecycle_process_group'},
        validation => {run_repetitions => 1},
        commands => {
            version => ['providers/ghdl', '--version'],
            analyze => ['providers/ghdl', '-a', 'generated/one.vhd'],
            elaborate => ['providers/ghdl', '-e', 'fixture'],
            run => ['providers/ghdl', '-r', 'fixture'],
        },
    };
}

sub osvvm_session {
    my $session = portable_session();
    $session->{role} = 'osvvm_qualification';
    $session->{commands} = {
        libraries => {
            root => '.artifacts/tmp/tests/vial-ghdl-state-evidence',
            osvvm => '.artifacts/tmp/tests/vial-ghdl-state-evidence/osvvm',
            osvvm_common =>
                '.artifacts/tmp/tests/vial-ghdl-state-evidence/common',
            fsmgen_vial =>
                '.artifacts/tmp/tests/vial-ghdl-state-evidence/fsmgen',
        },
        generated_settings => {sha256 => '9' x 64},
        provider_analyze => [
            ['providers/ghdl', '-a', 'providers/osvvm/one.vhd'],
        ],
        analyze_generated =>
            ['providers/ghdl', '-a', 'generated/adapter.vhd'],
        elaborate_fixture => ['providers/ghdl', '-e', 'fixture'],
        elaborate_provider_probe => ['providers/ghdl', '-e', 'probe'],
        run_fixture => ['providers/ghdl', '-r', 'fixture'],
        run_provider_probe => ['providers/ghdl', '-r', 'probe'],
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
    };
    return $session;
}

sub state_record {
    my ($session, $state, $payload) = @_;
    my @kind = qw(lifecycle_authority);
    if ($session->{role} =~ /osvvm/) {
        push @kind, 'generated_settings' if ordinal($state) >= 1;
        push @kind, 'tool_version_output' if ordinal($state) >= 2;
        push @kind, qw(provider_analysis_output_00 generated_analysis_output)
            if ordinal($state) >= 3;
        push @kind, qw(
            fixture_elaboration_output provider_probe_elaboration_output
        ) if ordinal($state) >= 4;
        push @kind, qw(fixture_runtime_output_0 provider_runtime_output_0)
            if ordinal($state) >= 5;
    }
    else {
        push @kind, 'tool_version_output' if ordinal($state) >= 2;
        push @kind, 'analysis_output' if ordinal($state) >= 3;
        push @kind, 'elaboration_output' if ordinal($state) >= 4;
        push @kind, 'runtime_output_0' if ordinal($state) >= 5;
    }
    push @kind, 'validated_trace' if ordinal($state) >= 6;
    push @kind, 'normalized_result' if ordinal($state) >= 7;
    push @kind, 'assembly_payload' if ordinal($state) >= 8;
    my @objects = map {
        my $content = $payload && exists($payload->{$_})
            ? $payload->{$_} : $_;
        object($_, $content);
    } @kind;
    my %object = map { $_->{kind} => $_ } @objects;
    my $workspace = [];
    my $selected;
    if ($state eq 'admitted') {
        $selected = {
            authority_sha256 => sha256_hex($JSON->encode($session->{authority})),
        };
    }
    elsif ($state eq 'prepared') {
        $selected = $session->{role} =~ /osvvm/ ? {
            library_identities => clone($session->{commands}{libraries}),
            source_count => scalar(@{$session->{source_set}}),
            settings_sha256 =>
                $session->{commands}{generated_settings}{sha256},
        } : {
            library_identity => $session->{library_rel},
            source_count => scalar(@{$session->{source_set}}),
        };
    }
    elsif ($state eq 'analyzed') {
        $selected = $session->{role} =~ /osvvm/ ? {
            command_digests => [
                command_digest($session->{commands}{provider_analyze}[0]),
            ],
            captures => [capture(120, 8_388_608, $object{provider_analysis_output_00}{bytes})],
            output_sha256 => [$object{provider_analysis_output_00}{sha256}],
            generated_command_digest =>
                command_digest($session->{commands}{analyze_generated}),
            generated_capture => capture(
                120, 8_388_608, $object{generated_analysis_output}{bytes},
            ),
            generated_output_sha256 =>
                $object{generated_analysis_output}{sha256},
        } : {
            command_digest => command_digest($session->{commands}{analyze}),
            output_sha256 => $object{analysis_output}{sha256},
            capture => capture(120, 8_388_608, $object{analysis_output}{bytes}),
        };
    }
    elsif ($state eq 'elaborated') {
        $selected = $session->{role} =~ /osvvm/ ? {
            command_digests => [map { command_digest($_) }
                @{$session->{commands}}{qw(
                    elaborate_fixture elaborate_provider_probe
                )}],
            captures => [
                capture(60, 8_388_608,
                    $object{fixture_elaboration_output}{bytes}),
                capture(60, 8_388_608,
                    $object{provider_probe_elaboration_output}{bytes}),
            ],
            output_sha256 => [
                $object{fixture_elaboration_output}{sha256},
                $object{provider_probe_elaboration_output}{sha256},
            ],
        } : {
            command_digest => command_digest($session->{commands}{elaborate}),
            output_sha256 => $object{elaboration_output}{sha256},
            capture => capture(
                60, 8_388_608, $object{elaboration_output}{bytes},
            ),
        };
    }
    elsif ($state eq 'ran') {
        $selected = $session->{role} =~ /osvvm/ ? {
            command_digests => {
                fixture => command_digest($session->{commands}{run_fixture}),
                provider_probe =>
                    command_digest($session->{commands}{run_provider_probe}),
            },
            fixture_captures => [capture(
                30, 67_108_864, $object{fixture_runtime_output_0}{bytes},
            )],
            provider_captures => [capture(
                30, 8_388_608, $object{provider_runtime_output_0}{bytes},
            )],
            fixture_output_sha256 =>
                [$object{fixture_runtime_output_0}{sha256}],
            provider_output_sha256 =>
                [$object{provider_runtime_output_0}{sha256}],
            provider_report_sha256 => [sha256_hex($JSON->encode([]))],
            deterministic => JSON::PP::false,
        } : {
            command_digest => command_digest($session->{commands}{run}),
            captures => [capture(30, 67_108_864, $object{runtime_output_0}{bytes})],
            output_sha256 => [$object{runtime_output_0}{sha256}],
            deterministic => JSON::PP::false,
        };
    }
    elsif ($state eq 'trace_validated') {
        $selected = {
            trace_sha256 => '7' x 64,
            record_count => 13,
            validation_sha256 => sha256_hex(
                $JSON->encode($JSON->decode($payload->{validated_trace})),
            ),
        };
    }
    elsif ($state eq 'result_produced') {
        $selected = {
            result_sha256 => sha256_hex(
                $JSON->encode($JSON->decode($payload->{normalized_result})),
            ),
            result_status => 'pass',
        };
    }
    elsif ($state eq 'assembled') {
        $selected = {
            assembly_sha256 => sha256_hex(
                $JSON->encode($JSON->decode($payload->{assembly_payload})),
            ),
            object_count => scalar(@objects),
        };
    }
    else {
        die "unsupported focused state '$state'\n";
    }
    $selected = clone($selected);
    $selected->{workspace_files} = $workspace;
    $selected->{workspace_sha256} = sha256_hex($JSON->encode($workspace));
    return {state => $state, objects => \@objects, evidence => $selected};
}

sub object {
    my ($kind, $content) = @_;
    my $digest = sha256_hex($content);
    return {
        kind => $kind,
        sha256 => $digest,
        bytes => length($content),
        executable => JSON::PP::false,
        relative_path => ".artifacts/tmp/tests/objects/$digest",
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

sub ordinal {
    my ($state) = @_;
    my @state = qw(
        admitted prepared tool_verified analyzed elaborated ran
        trace_validated result_produced assembled
    );
    my %ordinal = map { $state[$_] => $_ } 0 .. $#state;
    return $ordinal{$state};
}

sub command_digest {
    return sha256_hex($JSON->encode($_[0]));
}

sub canonical_line {
    return $JSON->encode($_[0]) . "\n";
}

sub validate_state {
    my ($session, $record) = @_;
    return eval {
        FSM::VIAL::Backend::GHDLLifecycle::_validate_state_shape(
            $session, $record,
        );
        1;
    } ? 1 : 0;
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

package FSM::VIAL::Backend::ResultProducer;

use v5.20;
use strict;
use warnings;
use bytes ();
use Carp qw(confess);
use Digest::SHA qw(sha256_hex);
use JSON::PP ();
use Scalar::Util qw(blessed);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

my $JSON = JSON::PP->new->canonical(1);
my @RESULT_KEYS = qw(ok status manifest content diagnostics);
my @MANIFEST_KEYS = qw(
    schema schema_version result_id plan_id fixture_id execution_profile
    backend_profile status portable_parity_eligible capability_evidence
    scenario_results random_decisions events drives samples transactions
    expectations models scoreboards coverage faults fibers native_extensions
    diagnostics metrics exclusions parity_projection parity_digest
    backend_evidence
);
my @SCENARIO_KEYS = qw(
    run_id scenario_id status start_time end_time completion_reason
    expectation_ids diagnostic_ids cancelled_fiber_ids logical_cycle_count
);
my %TRACE_FAMILY = map { $_ => 1 } qw(
    events drives samples transactions expectations models scoreboards coverage
    faults fibers
);
my @BACKEND_CAPABILITIES = qw(
    vial.backend.sv_portable_verilator.v1
    vial.backend.sv_portable_verilator.declared_probe_adapter_v1
    vial.backend.sv_portable_verilator.inactive_edge_scheduler_v1
    vial.backend.sv_portable_verilator.known_value_runtime_v1
    vial.backend.sv_portable_verilator.runtime_trace_v1
    vial.result_manifest.v1
);

sub result_keys($class) {
    confess __PACKAGE__ . "->result_keys requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return [@RESULT_KEYS];
}

sub manifest_keys($class) {
    confess __PACKAGE__ . "->manifest_keys requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return [@MANIFEST_KEYS];
}

sub scenario_keys($class) {
    confess __PACKAGE__ . "->scenario_keys requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return [@SCENARIO_KEYS];
}

sub produce($class, @args) {
    return _failure('VIAL_RESULT_INVOCATION_ERROR', 'produce requires the exact ResultProducer class invocant', '/')
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return _failure('VIAL_RESULT_INVOCATION_ERROR', 'produce expects one closed argument hash', '/')
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    my $result = eval { _produce($args[0]) };
    return $result if defined $result;
    my $error = $@;
    return _failure($error->{code}, $error->{message}, $error->{path})
        if blessed($error) && $error->isa('FSM::VIAL::Backend::ResultProducer::Failure');
    return _failure('VIAL_RESULT_HOST_ERROR', _sanitize_exception($error), '/');
}

sub _produce($raw) {
    _require_exact_keys($raw, [qw(
        execution_ir trace_validation negotiation tool_profile
        backend_manifest_id compile_id simulation_id
        generated_artifact_sha256s transcript_sha256
    )], 'result production');
    _throw('VIAL_RESULT_INVOCATION_ERROR', 'execution_ir must be an exact FSM::VIAL::ExecutionIR object', '/execution_ir')
        unless blessed($raw->{execution_ir})
            && ref($raw->{execution_ir}) eq 'FSM::VIAL::ExecutionIR';
    _throw('VIAL_RESULT_TRACE_ERROR', 'trace_validation must be one successful closed trace projection', '/trace_validation')
        unless ref($raw->{trace_validation}) eq 'HASH'
            && !blessed($raw->{trace_validation})
            && $raw->{trace_validation}{ok};
    for my $key (qw(negotiation tool_profile)) {
        _throw('VIAL_RESULT_INVOCATION_ERROR', "$key must be one unblessed hash", "/$key")
            unless ref($raw->{$key}) eq 'HASH' && !blessed($raw->{$key});
    }
    for my $key (qw(backend_manifest_id compile_id simulation_id transcript_sha256)) {
        _throw('VIAL_RESULT_INVOCATION_ERROR', "$key must be a non-empty scalar", "/$key")
            unless defined($raw->{$key}) && !ref($raw->{$key}) && length($raw->{$key});
    }
    _throw('VIAL_RESULT_INVOCATION_ERROR', 'generated_artifact_sha256s must be an array', '/generated_artifact_sha256s')
        unless ref($raw->{generated_artifact_sha256s}) eq 'ARRAY';

    my $execution = $raw->{execution_ir}->as_hashref;
    my @records = @{$raw->{trace_validation}{records}};
    my (%stream, %ordinal, %maximum_cycle);
    for my $record (@records) {
        next unless $TRACE_FAMILY{$record->{record_kind} // ''};
        my $payload = _clone($record->{payload});
        if (exists $payload->{logical_time}) {
            my $private = delete $payload->{logical_time};
            my $phase = _phase($private->{phase_rank});
            my $ordinal_key = join("\0", $record->{run_id}, $private->{cycle}, $phase);
            $payload->{logical_time} = {
                domain_id => $execution->{domains}[0]{domain_id},
                cycle => 0 + $private->{cycle},
                phase => $phase,
                ordinal => $ordinal{$ordinal_key}++,
            };
            $maximum_cycle{$record->{run_id}} = $private->{cycle}
                if !defined($maximum_cycle{$record->{run_id}})
                    || $private->{cycle} > $maximum_cycle{$record->{run_id}};
        }
        push @{$stream{$record->{record_kind}}}, $payload;
    }
    $stream{$_} ||= [] for sort keys %TRACE_FAMILY;
    $stream{native_extensions} = [];

    my %end = map {
        defined($_->{run_id}) && $_->{record_kind} eq 'scenario_end'
            ? ($_->{run_id} => $_->{payload}) : ()
    } @records;
    my @scenario_results;
    for my $scenario (@{$execution->{scenarios}}) {
        my $run_id = "run/$execution->{plan_id}/$scenario->{scenario_id}";
        my $payload = $end{$run_id};
        _throw('VIAL_RESULT_TRACE_ERROR', 'trace is missing one selected scenario result', '/scenario_results')
            unless $payload;
        my $trace_status = $payload->{status} // 'error';
        my $status = $trace_status eq 'passed' ? 'pass'
            : $trace_status eq 'failed' ? 'fail'
            : $trace_status eq 'timeout' ? 'timeout' : 'error';
        my @expectation = map { $_->{expectation_id} }
            grep { ($_->{run_id} // '') eq $run_id } @{$stream{expectations}};
        my @diagnostic = map { $_->{diagnostic_id} }
            grep { defined($_->{diagnostic_id}) && length($_->{diagnostic_id}) }
            grep { ($_->{run_id} // '') eq $run_id && !$_->{outcome} }
            @{$stream{expectations}};
        my @cancelled = map { $_->{fiber_id} }
            grep { ($_->{run_id} // '') eq $run_id && ($_->{status} // '') eq 'cancelled' }
            @{$stream{fibers}};
        my $cycles = exists($payload->{logical_cycle_count})
            ? $payload->{logical_cycle_count}
            : (($maximum_cycle{$run_id} // 0) + 1);
        my $completion = $status eq 'pass' ? 'completed'
            : $status eq 'timeout' ? 'timeout'
            : $status eq 'fail' ? 'expectation_failed' : 'runtime_error';
        my $start_time = {
            domain_id => $execution->{domains}[0]{domain_id},
            cycle => 0,
            phase => 'drive',
            ordinal => 0,
        };
        my $end_cycle = $cycles ? $cycles - 1 : 0;
        my $end_time = {
            domain_id => $execution->{domains}[0]{domain_id},
            cycle => 0 + $end_cycle,
            phase => 'check',
            ordinal => 0,
        };
        my $entry = {
            run_id => $run_id,
            scenario_id => $scenario->{scenario_id},
            status => $status,
            start_time => $start_time,
            end_time => $end_time,
            completion_reason => $completion,
            expectation_ids => \@expectation,
            diagnostic_ids => \@diagnostic,
            cancelled_fiber_ids => \@cancelled,
            logical_cycle_count => 0 + $cycles,
        };
        _require_manifest_keys($entry, \@SCENARIO_KEYS, 'scenario result');
        push @scenario_results, $entry;
    }

    my $status = (grep { $_->{status} eq 'error' } @scenario_results) ? 'error'
        : (grep { $_->{status} eq 'timeout' } @scenario_results) ? 'timeout'
        : (grep { $_->{status} eq 'fail' } @scenario_results) ? 'fail' : 'pass';
    my $parity_projection = {
        schema => 'fsmgen.vial_parity_projection.v1',
        schema_version => 1,
        plan_id => $execution->{plan_id},
        fixture_id => $execution->{fixture}{fixture_id},
        status => $status,
        scenario_results => _clone(\@scenario_results),
        random_decisions => _clone($execution->{randomness}{decisions}),
        (map { $_ => _clone($stream{$_}) } qw(
            events drives samples transactions expectations models scoreboards
            coverage faults fibers native_extensions
        )),
        exclusions => [],
    };
    $parity_projection->{native_extensions} = [];
    my $parity_digest = sha256_hex($JSON->encode($parity_projection));
    my $manifest = {
        schema => 'fsmgen.verification_result_manifest.v1',
        schema_version => 1,
        result_id => undef,
        plan_id => $execution->{plan_id},
        fixture_id => $execution->{fixture}{fixture_id},
        execution_profile => $execution->{profile},
        backend_profile => {
            id => 'sv_portable_verilator',
            target_language => 'SystemVerilog',
            methodology => 'plain_sv_no_uvm',
            tool_name => $raw->{tool_profile}{tool_name},
            tool_version => $raw->{tool_profile}{qualified_version},
            uvm_revision => undef,
            vhdl_standard => undef,
            capabilities => [sort @BACKEND_CAPABILITIES],
        },
        status => $status,
        portable_parity_eligible => $status eq 'pass' ? JSON::PP::true : JSON::PP::false,
        capability_evidence => {
            required => _clone($raw->{negotiation}{required}),
            satisfied => _clone($raw->{negotiation}{satisfied}),
            unsatisfied => _clone($raw->{negotiation}{unsatisfied}),
            native_only => _clone($raw->{negotiation}{native_only}),
        },
        scenario_results => \@scenario_results,
        random_decisions => _clone($execution->{randomness}{decisions}),
        (map { $_ => _clone($stream{$_}) } qw(
            events drives samples transactions expectations models scoreboards
            coverage faults fibers
        )),
        native_extensions => [],
        diagnostics => [],
        metrics => _metrics($execution, \%stream, \@scenario_results),
        exclusions => [],
        parity_projection => $parity_projection,
        parity_digest => $parity_digest,
        backend_evidence => {
            artifact_manifest_id => $raw->{backend_manifest_id},
            compile_id => $raw->{compile_id},
            simulation_id => $raw->{simulation_id},
            generated_artifact_sha256s => [sort @{$raw->{generated_artifact_sha256s}}],
            transcript_sha256 => $raw->{transcript_sha256},
            waveform_sha256 => undef,
        },
    };
    _require_manifest_keys($manifest, \@MANIFEST_KEYS, 'result manifest');
    my ($content, $bytes) = _stabilize_identity_and_size($manifest);
    $manifest->{metrics}{result_bytes} = $bytes;
    return _result({
        ok => JSON::PP::true,
        status => $status,
        manifest => $manifest,
        content => $content,
        diagnostics => [],
    });
}

sub _metrics($execution, $stream, $scenarios) {
    my %count = map { ($_ . '_records') => scalar(@{$stream->{$_}}) }
        qw(events drives samples transactions expectations models scoreboards coverage faults fibers native_extensions);
    my $logical_cycles = 0;
    $logical_cycles += $_->{logical_cycle_count} for @$scenarios;
    my $maximum_live_fibers = 0;
    for my $scenario (@{$execution->{scenarios}}) {
        $maximum_live_fibers = @{$scenario->{fibers}}
            if @{$scenario->{fibers}} > $maximum_live_fibers;
    }
    my $maximum_scoreboard_depth = 0;
    for my $record (@{$stream->{scoreboards}}) {
        for my $key (qw(queue_depth_expected queue_depth_actual)) {
            $maximum_scoreboard_depth = $record->{$key}
                if defined($record->{$key}) && $record->{$key} > $maximum_scoreboard_depth;
        }
    }
    return {
        logical_cycles => $logical_cycles,
        %count,
        maximum_live_fibers => $maximum_live_fibers,
        maximum_scoreboard_depth => $maximum_scoreboard_depth,
        result_bytes => 0,
    };
}

sub _stabilize_identity_and_size($manifest) {
    my $bytes = 0;
    for (1 .. 16) {
        $manifest->{metrics}{result_bytes} = $bytes;
        my $identity = _clone($manifest);
        delete $identity->{result_id};
        $manifest->{result_id} = 'result/' . sha256_hex($JSON->encode($identity));
        my $content = _json_text($manifest);
        my $next = bytes::length($content);
        return ($content, $next) if $next == $bytes;
        $bytes = $next;
    }
    _throw('VIAL_RESULT_SCHEMA_ERROR', 'result byte count did not stabilize', '/metrics/result_bytes');
}

sub _phase($rank) {
    my @phase = qw(drive sample react check);
    _throw('VIAL_RESULT_TRACE_ERROR', 'trace logical phase rank is invalid', '/records/logical_time/phase_rank')
        unless defined($rank) && !ref($rank) && $rank =~ /\A[0-3]\z/;
    return $phase[$rank];
}

sub _json_text($value) {
    my $text = JSON::PP->new->ascii->canonical->pretty->encode($value);
    $text .= "\n" unless $text =~ /\n\z/;
    return $text;
}

sub _require_exact_keys($value, $keys, $label) {
    _throw('VIAL_RESULT_INVOCATION_ERROR', "$label must be one unblessed hash", '/')
        unless ref($value) eq 'HASH' && !blessed($value);
    my %expected = map { $_ => 1 } @$keys;
    my @unknown = sort grep { !$expected{$_} } keys %$value;
    my @missing = grep { !exists($value->{$_}) } @$keys;
    _throw('VIAL_RESULT_INVOCATION_ERROR', "$label has unknown key '$unknown[0]'", '/') if @unknown;
    _throw('VIAL_RESULT_INVOCATION_ERROR', "$label is missing key '$missing[0]'", '/') if @missing;
}

sub _require_manifest_keys($value, $keys, $label) {
    my %expected = map { $_ => 1 } @$keys;
    confess "$label has unknown key(s)" if grep { !$expected{$_} } keys %$value;
    confess "$label is missing key(s)" if grep { !exists($value->{$_}) } @$keys;
}

sub _throw($code, $message, $path) {
    die bless {code => $code, message => $message, path => $path},
        'FSM::VIAL::Backend::ResultProducer::Failure';
}

sub _failure($code, $message, $path) {
    return _result({
        ok => JSON::PP::false,
        status => 'error',
        manifest => undef,
        content => undef,
        diagnostics => [{code => $code, severity => 'error', message => $message, path => $path}],
    });
}

sub _result($value) {
    _require_manifest_keys($value, \@RESULT_KEYS, 'result producer result');
    return _clone($value);
}

sub _sanitize_exception($error) {
    my $message = defined($error) ? "$error" : 'unknown result host failure';
    $message =~ s/\s+at\s+\S+\s+line\s+\d+\.?\s*\z//s;
    $message =~ s{(?:[A-Za-z]:)?[/\\][^\s:]+[/\\][^\s:]+}{<host-path>}g;
    $message =~ s/[\r\n]+/ /g;
    $message =~ s/\s+/ /g;
    $message =~ s/\A\s+|\s+\z//g;
    return length($message) ? $message : 'unknown result host failure';
}

sub _clone($value) {
    return undef unless defined $value;
    return $value ? JSON::PP::true : JSON::PP::false
        if blessed($value) && $value->isa('JSON::PP::Boolean');
    return {map { $_ => _clone($value->{$_}) } sort keys %$value}
        if ref($value) eq 'HASH';
    return [map { _clone($_) } @$value] if ref($value) eq 'ARRAY';
    confess 'result projection contains an unsupported reference' if ref($value);
    return $value;
}

package FSM::VIAL::Backend::ResultProducer::Failure;

use overload '""' => sub { $_[0]{message} // 'VIAL result production failure' }, fallback => 1;

1;

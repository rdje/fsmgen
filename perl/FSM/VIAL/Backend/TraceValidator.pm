package FSM::VIAL::Backend::TraceValidator;

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

my $PREFIX = "FSMGEN_VIAL_TRACE_V1\t";
my $SCHEMA = 'fsmgen.vial_sv_runtime_trace.v1';
my $JSON = JSON::PP->new->canonical(1);
my @RESULT_KEYS = qw(
    ok status trace_schema plan_id records projection diagnostics
);
my @RECORD_KEYS = qw(
    schema schema_version record_kind plan_id run_id sequence payload
);
my %RECORD_KIND = map { $_ => 1 } qw(
    header scenario_start events drives samples transactions expectations
    models scoreboards coverage faults fibers scenario_end footer
);
my %SEMANTIC_KEYS = (
    events => [qw(
        event_id event_occurrence_index logical_time record_id run_id semantic_id
    )],
    drives => [qw(
        effective_value endpoint_id logical_time operation_id record_id run_id
        transaction_field_id
    )],
    samples => [qw(
        logical_time record_id run_id sample_id semantic_id value
    )],
    transactions => [qw(
        accept_time binding_id complete_time correlation effective_fields handle_id
        logical_time record_id request_time run_id status
    )],
    expectations => [qw(
        activation_time actual_value diagnostic_id expectation_id expected_value
        logical_time name outcome property_operation record_id resolution_time run_id
    )],
    models => [qw(
        logical_time model_instance_id new_value old_value record_id run_id state_id
        trigger_event_record_id
    )],
    scoreboards => [qw(
        actual_value expected_value instance_id key logical_time operation outcome
        queue_depth_actual queue_depth_expected record_id run_id
    )],
    coverage => [qw(
        bin_id coverpoint_id cross_id cumulative_count delta hit_kind logical_time
        record_id run_id sampled_value
    )],
    faults => [qw(
        fault_id logical_time original_value record_id run_id status
        substituted_value target_id
    )],
    fibers => [qw(
        cancel_scope_id cause_id fiber_id logical_time parent_fiber_id record_id
        run_id status winner_fiber_id
    )],
);

sub result_keys($class) {
    confess __PACKAGE__ . "->result_keys requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return [@RESULT_KEYS];
}

sub record_keys($class) {
    confess __PACKAGE__ . "->record_keys requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return [@RECORD_KEYS];
}

sub validate($class, @args) {
    return _failure('VIAL_TRACE_INVOCATION_ERROR', 'validate requires the exact TraceValidator class invocant', '/')
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return _failure('VIAL_TRACE_INVOCATION_ERROR', 'validate expects one closed argument hash', '/')
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    my $result = eval { _validate($args[0]) };
    return $result if defined $result;
    my $error = $@;
    return _failure($error->{code}, $error->{message}, $error->{path})
        if blessed($error) && $error->isa('FSM::VIAL::Backend::TraceValidator::Failure');
    return _failure('VIAL_TRACE_HOST_ERROR', _sanitize_exception($error), '/');
}

sub _validate($raw) {
    _require_exact_keys($raw, [qw(execution_ir trace_text simulator_exit_code)], 'trace validation');
    _throw('VIAL_TRACE_INVOCATION_ERROR', 'execution_ir must be an exact FSM::VIAL::ExecutionIR object', '/execution_ir')
        unless blessed($raw->{execution_ir})
            && ref($raw->{execution_ir}) eq 'FSM::VIAL::ExecutionIR';
    _throw('VIAL_TRACE_INVOCATION_ERROR', 'trace_text must be a scalar byte string', '/trace_text')
        unless defined($raw->{trace_text}) && !ref($raw->{trace_text});
    _throw('VIAL_TRACE_INVOCATION_ERROR', 'simulator_exit_code must be a non-negative integer', '/simulator_exit_code')
        unless defined($raw->{simulator_exit_code}) && !ref($raw->{simulator_exit_code})
            && $raw->{simulator_exit_code} =~ /\A[0-9]+\z/;
    _throw('VIAL_TRACE_TOOL_EXIT_ERROR', 'simulator exit was nonzero', '/simulator_exit_code')
        unless $raw->{simulator_exit_code} == 0;
    _throw('VIAL_TRACE_LIMIT_EXCEEDED', 'runtime trace exceeds the 64 MiB cap', '/trace_text')
        if bytes::length($raw->{trace_text}) > 67_108_864;
    _throw('VIAL_TRACE_SCHEMA_ERROR', 'runtime trace must use LF records with one final newline', '/trace_text')
        unless length($raw->{trace_text}) && $raw->{trace_text} =~ /\n\z/
            && $raw->{trace_text} !~ /\r/;

    my @line = split /\n/, $raw->{trace_text}, -1;
    pop @line;
    _throw('VIAL_TRACE_LIMIT_EXCEEDED', 'runtime trace exceeds the 8,000,002-record cap', '/trace_text')
        if @line > 8_000_002;
    _throw('VIAL_TRACE_SCHEMA_ERROR', 'runtime trace must contain header and footer records', '/trace_text')
        if @line < 2;
    my $execution = $raw->{execution_ir}->as_hashref;
    my @records;
    for my $index (0 .. $#line) {
        my $line = $line[$index];
        _throw('VIAL_TRACE_SCHEMA_ERROR', 'trace line is missing the exact machine prefix', "/records/$index")
            unless index($line, $PREFIX) == 0;
        my $json_text = substr($line, length($PREFIX));
        my $record = eval { JSON::PP->new->decode($json_text) };
        _throw('VIAL_TRACE_SCHEMA_ERROR', 'trace line is not one JSON object', "/records/$index")
            unless defined($record) && ref($record) eq 'HASH' && !blessed($record);
        _require_record_keys($record, $index);
        _throw('VIAL_TRACE_SCHEMA_ERROR', 'trace JSON is not canonical', "/records/$index")
            unless $JSON->encode($record) eq $json_text;
        _throw('VIAL_TRACE_SCHEMA_ERROR', 'trace schema identity is wrong', "/records/$index/schema")
            unless $record->{schema} eq $SCHEMA && $record->{schema_version} == 1;
        _throw('VIAL_TRACE_IDENTITY_ERROR', 'trace plan identity is wrong', "/records/$index/plan_id")
            unless $record->{plan_id} eq $execution->{plan_id};
        _throw('VIAL_TRACE_SEQUENCE_ERROR', 'trace sequence must start at zero and remain contiguous', "/records/$index/sequence")
            unless !ref($record->{sequence}) && $record->{sequence} =~ /\A[0-9]+\z/
                && $record->{sequence} == $index;
        _throw('VIAL_TRACE_SCHEMA_ERROR', 'trace record kind is not in the closed vocabulary', "/records/$index/record_kind")
            unless $RECORD_KIND{$record->{record_kind} // ''};
        _throw('VIAL_TRACE_SCHEMA_ERROR', 'trace payload must be one object', "/records/$index/payload")
            unless ref($record->{payload}) eq 'HASH' && !blessed($record->{payload});
        _validate_semantic_payload($record, $execution, $index)
            if $SEMANTIC_KEYS{$record->{record_kind}};
        push @records, $record;
    }
    _throw('VIAL_TRACE_SCHEMA_ERROR', 'first trace record must be header', '/records/0/record_kind')
        unless $records[0]{record_kind} eq 'header';
    _throw('VIAL_TRACE_SCHEMA_ERROR', 'last trace record must be footer', '/records/-1/record_kind')
        unless $records[-1]{record_kind} eq 'footer';
    _throw('VIAL_TRACE_SCHEMA_ERROR', 'header/footer run_id must be null', '/records')
        if defined($records[0]{run_id}) || defined($records[-1]{run_id});
    _validate_header($records[0], $execution);
    my ($scenario_runs, $scenario_status) = _validate_scenario_stream(\@records, $execution);
    my $counts = _counts(\@records);
    _validate_footer($records[-1], $scenario_runs, $scenario_status, $counts);
    _validate_logical_order(\@records);

    my $normalized = join("\n", map { $JSON->encode($_) } @records) . "\n";
    return _result({
        ok => JSON::PP::true,
        status => 'validated',
        trace_schema => $SCHEMA,
        plan_id => $execution->{plan_id},
        records => \@records,
        projection => {
            schema => 'fsmgen.vial_sv_trace_projection.v1',
            schema_version => 1,
            plan_id => $execution->{plan_id},
            status => $records[-1]{payload}{status},
            scenario_runs => $scenario_runs,
            scenario_completion_summaries => $records[-1]{payload}{scenario_completion_summaries},
            counts => $counts,
            clean_termination => JSON::PP::true,
            record_count => scalar(@records),
            trace_sha256 => sha256_hex($normalized),
            result_manifest_status => 'not_produced',
        },
        diagnostics => [],
    });
}

sub _validate_semantic_payload($record, $execution, $index) {
    my $kind = $record->{record_kind};
    my $payload = $record->{payload};
    my $path = "/records/$index/payload";
    _require_keys($payload, $SEMANTIC_KEYS{$kind}, "$kind payload", $path);
    _throw('VIAL_TRACE_IDENTITY_ERROR', "$kind payload run identity is wrong", "$path/run_id")
        unless defined($record->{run_id}) && !ref($record->{run_id})
            && defined($payload->{run_id}) && !ref($payload->{run_id})
            && $payload->{run_id} eq $record->{run_id};
    my ($scenario_id) = $record->{run_id} =~ m{\Arun/\Q$execution->{plan_id}\E/(.+)\z};
    _throw('VIAL_TRACE_IDENTITY_ERROR', "$kind payload record identity is wrong", "$path/record_id")
        unless defined($scenario_id)
            && defined($payload->{record_id}) && !ref($payload->{record_id})
            && index($payload->{record_id}, "record/$scenario_id/$kind/") == 0;

    if ($kind eq 'events') {
        my %event = map { $_->{event_id} => $_ } @{$execution->{events}};
        my $event = $event{$payload->{event_id} // ''};
        _throw('VIAL_TRACE_IDENTITY_ERROR', 'event record names an unknown event', "$path/event_id")
            unless $event && ($payload->{semantic_id} // '') eq $event->{semantic_id};
        _nonnegative_integer($payload->{event_occurrence_index}, "$path/event_occurrence_index");
    }
    elsif ($kind eq 'drives') {
        my %operation = map { $_->{operation_id} => 1 } @{$execution->{operation_graph}{operations}};
        _throw('VIAL_TRACE_IDENTITY_ERROR', 'drive record names an unknown operation', "$path/operation_id")
            unless $operation{$payload->{operation_id} // ''};
    }
    elsif ($kind eq 'transactions') {
        _throw('VIAL_TRACE_SCHEMA_ERROR', 'transaction status is not closed', "$path/status")
            unless ($payload->{status} // '') =~ /\A(?:completed|failed|cancelled)\z/;
    }
    elsif ($kind eq 'expectations') {
        my %expectation = map { $_ => 1 }
            map { @{$_->{plan_summary}{expectation_ids}} } @{$execution->{scenarios}};
        _throw('VIAL_TRACE_IDENTITY_ERROR', 'expectation record names an unknown expectation', "$path/expectation_id")
            unless $expectation{$payload->{expectation_id} // ''};
        _json_boolean($payload->{outcome}, "$path/outcome");
    }
    elsif ($kind eq 'models') {
        my %model = map { $_->{instance_id} => 1 } @{$execution->{models}};
        _throw('VIAL_TRACE_IDENTITY_ERROR', 'model record names an unknown instance', "$path/model_instance_id")
            unless $model{$payload->{model_instance_id} // ''};
    }
    elsif ($kind eq 'scoreboards') {
        my %scoreboard = map { $_->{instance_id} => 1 } @{$execution->{scoreboards}};
        _throw('VIAL_TRACE_IDENTITY_ERROR', 'scoreboard record names an unknown instance', "$path/instance_id")
            unless $scoreboard{$payload->{instance_id} // ''};
        _throw('VIAL_TRACE_SCHEMA_ERROR', 'scoreboard operation is not closed', "$path/operation")
            unless ($payload->{operation} // '') =~ /\A(?:enqueue_expected|enqueue_actual|match|mismatch|check)\z/;
        _json_boolean($payload->{outcome}, "$path/outcome");
        _nonnegative_integer($payload->{queue_depth_actual}, "$path/queue_depth_actual");
        _nonnegative_integer($payload->{queue_depth_expected}, "$path/queue_depth_expected");
    }
    elsif ($kind eq 'coverage') {
        my %bin = map { map { $_->{semantic_id} => 1 } @{$_->{bins}} }
            @{$execution->{coverage}{coverpoints}};
        _throw('VIAL_TRACE_IDENTITY_ERROR', 'coverage record names an unknown bin', "$path/bin_id")
            unless $bin{$payload->{bin_id} // ''};
        _nonnegative_integer($payload->{cumulative_count}, "$path/cumulative_count");
        _nonnegative_integer($payload->{delta}, "$path/delta");
    }
    elsif ($kind eq 'faults') {
        my %fault = map { $_->{semantic_id} => 1 } @{$execution->{faults}};
        _throw('VIAL_TRACE_IDENTITY_ERROR', 'fault record names an unknown fault', "$path/fault_id")
            unless $fault{$payload->{fault_id} // ''};
        _throw('VIAL_TRACE_SCHEMA_ERROR', 'fault status is not closed', "$path/status")
            unless ($payload->{status} // '') =~ /\A(?:armed|applied|expired)\z/;
    }
    elsif ($kind eq 'fibers') {
        my %fiber = map { map { $_->{fiber_id} => 1 } @{$_->{fibers}} }
            @{$execution->{scenarios}};
        _throw('VIAL_TRACE_IDENTITY_ERROR', 'fiber record names an unknown fiber', "$path/fiber_id")
            unless $fiber{$payload->{fiber_id} // ''};
        _throw('VIAL_TRACE_SCHEMA_ERROR', 'fiber status is not closed', "$path/status")
            unless ($payload->{status} // '') =~ /\A(?:started|completed|failed|cancelled)\z/;
    }
}

sub _nonnegative_integer($value, $path) {
    _throw('VIAL_TRACE_SCHEMA_ERROR', 'semantic count must be a non-negative integer', $path)
        unless defined($value) && !ref($value) && $value =~ /\A[0-9]+\z/;
}

sub _json_boolean($value, $path) {
    _throw('VIAL_TRACE_SCHEMA_ERROR', 'semantic outcome must be a JSON Boolean', $path)
        unless blessed($value) && $value->isa('JSON::PP::Boolean');
}

sub _validate_header($record, $execution) {
    _require_keys($record->{payload}, [qw(
        fixture_id execution_profile backend_profile scenario_runs decision_digest
    )], 'header payload', '/records/0/payload');
    _throw('VIAL_TRACE_IDENTITY_ERROR', 'header fixture identity is wrong', '/records/0/payload/fixture_id')
        unless $record->{payload}{fixture_id} eq $execution->{fixture}{fixture_id};
    _throw('VIAL_TRACE_IDENTITY_ERROR', 'header execution profile is wrong', '/records/0/payload/execution_profile')
        unless $record->{payload}{execution_profile} eq $execution->{profile};
    _throw('VIAL_TRACE_IDENTITY_ERROR', 'header backend profile is wrong', '/records/0/payload/backend_profile')
        unless $record->{payload}{backend_profile} eq 'sv_portable_verilator';
    my @expected = map {
        {scenario_id => $_->{scenario_id}, run_id => _run_id($execution->{plan_id}, $_->{scenario_id})}
    } @{$execution->{scenarios}};
    _throw('VIAL_TRACE_IDENTITY_ERROR', 'header scenario/run identities are wrong', '/records/0/payload/scenario_runs')
        unless $JSON->encode($record->{payload}{scenario_runs}) eq $JSON->encode(\@expected);
    my $digest = sha256_hex($JSON->encode($execution->{randomness}{decisions}));
    _throw('VIAL_TRACE_IDENTITY_ERROR', 'header decision digest is wrong', '/records/0/payload/decision_digest')
        unless $record->{payload}{decision_digest} eq $digest;
}

sub _validate_scenario_stream($records, $execution) {
    my @expected = @{$execution->{scenarios}};
    my @runs;
    my %status;
    my $scenario_index = -1;
    my $active_run;
    for my $index (1 .. $#$records - 1) {
        my $record = $records->[$index];
        _throw('VIAL_TRACE_SCHEMA_ERROR', 'header/footer may occur only at stream boundaries', "/records/$index/record_kind")
            if $record->{record_kind} eq 'header' || $record->{record_kind} eq 'footer';
        if ($record->{record_kind} eq 'scenario_start') {
            _throw('VIAL_TRACE_ORDER_ERROR', 'scenario_start cannot nest', "/records/$index")
                if defined($active_run);
            $scenario_index++;
            _throw('VIAL_TRACE_ORDER_ERROR', 'trace contains an unexpected scenario', "/records/$index")
                if $scenario_index > $#expected;
            my $scenario = $expected[$scenario_index];
            my $run_id = _run_id($execution->{plan_id}, $scenario->{scenario_id});
            _throw('VIAL_TRACE_IDENTITY_ERROR', 'scenario_start run_id is wrong', "/records/$index/run_id")
                unless defined($record->{run_id}) && !ref($record->{run_id})
                    && $record->{run_id} eq $run_id;
            _require_keys($record->{payload}, [qw(scenario_id)], 'scenario_start payload', "/records/$index/payload");
            _throw('VIAL_TRACE_IDENTITY_ERROR', 'scenario_start scenario_id is wrong', "/records/$index/payload/scenario_id")
                unless $record->{payload}{scenario_id} eq $scenario->{scenario_id};
            $active_run = $run_id;
            push @runs, {scenario_id => $scenario->{scenario_id}, run_id => $run_id};
            next;
        }
        _throw('VIAL_TRACE_ORDER_ERROR', 'scenario-owned record appears outside a scenario', "/records/$index")
            unless defined($active_run);
        _throw('VIAL_TRACE_IDENTITY_ERROR', 'scenario-owned record run_id is wrong', "/records/$index/run_id")
            unless defined($record->{run_id}) && !ref($record->{run_id})
                && $record->{run_id} eq $active_run;
        if ($record->{record_kind} eq 'scenario_end') {
            _require_keys($record->{payload}, [qw(
                logical_cycle_count scenario_id status
            )], 'scenario_end payload', "/records/$index/payload");
            my $scenario = $expected[$scenario_index];
            _throw('VIAL_TRACE_IDENTITY_ERROR', 'scenario_end scenario_id is wrong', "/records/$index/payload/scenario_id")
                unless $record->{payload}{scenario_id} eq $scenario->{scenario_id};
            _throw('VIAL_TRACE_SCHEMA_ERROR', 'scenario status is not closed', "/records/$index/payload/status")
                unless ($record->{payload}{status} // '') =~ /\A(?:passed|failed|timeout|error)\z/;
            _throw('VIAL_TRACE_SCHEMA_ERROR', 'scenario logical cycle count must be a positive integer', "/records/$index/payload/logical_cycle_count")
                unless !ref($record->{payload}{logical_cycle_count})
                    && $record->{payload}{logical_cycle_count} =~ /\A[1-9][0-9]*\z/;
            $status{$active_run} = $record->{payload}{status};
            undef $active_run;
        }
    }
    _throw('VIAL_TRACE_ORDER_ERROR', 'trace ended with an incomplete scenario', '/records')
        if defined($active_run);
    _throw('VIAL_TRACE_ORDER_ERROR', 'trace did not contain every selected scenario in authored order', '/records')
        unless @runs == @expected;
    return (\@runs, \%status);
}

sub _validate_footer($record, $scenario_runs, $scenario_status, $counts) {
    _require_keys($record->{payload}, [qw(
        status scenario_completion_summaries counts clean_termination
    )], 'footer payload', '/records/-1/payload');
    _throw('VIAL_TRACE_TERMINATION_ERROR', 'trace footer does not record clean termination', '/records/-1/payload/clean_termination')
        unless blessed($record->{payload}{clean_termination})
            && $record->{payload}{clean_termination}->isa('JSON::PP::Boolean')
            && $record->{payload}{clean_termination};
    _throw('VIAL_TRACE_SCHEMA_ERROR', 'footer status is not closed', '/records/-1/payload/status')
        unless ($record->{payload}{status} // '') =~ /\A(?:passed|failed|error)\z/;
    _throw('VIAL_TRACE_COUNT_ERROR', 'footer record-family counts do not match the trace', '/records/-1/payload/counts')
        unless $JSON->encode($record->{payload}{counts}) eq $JSON->encode($counts);
    my @summary = map {
        {scenario_id => $_->{scenario_id}, run_id => $_->{run_id}, status => $scenario_status->{$_->{run_id}}}
    } @$scenario_runs;
    _throw('VIAL_TRACE_COUNT_ERROR', 'footer scenario summaries do not match completed scenarios', '/records/-1/payload/scenario_completion_summaries')
        unless $JSON->encode($record->{payload}{scenario_completion_summaries}) eq $JSON->encode(\@summary);
}

sub _validate_logical_order($records) {
    my %previous;
    for my $index (0 .. $#$records) {
        my $record = $records->[$index];
        next unless defined($record->{run_id}) && exists($record->{payload}{logical_time});
        my $time = $record->{payload}{logical_time};
        _require_keys($time, [qw(
            cycle phase_rank domain_rank static_operation_rank
            local_emission_index semantic_id
        )], 'logical_time', "/records/$index/payload/logical_time");
        my @tuple = @$time{qw(
            cycle phase_rank domain_rank static_operation_rank local_emission_index
        )};
        _throw('VIAL_TRACE_ORDER_ERROR', 'logical-time ordinal must contain non-negative integers', "/records/$index/payload/logical_time")
            if grep { !defined($_) || ref($_) || $_ !~ /\A[0-9]+\z/ } @tuple;
        push @tuple, $time->{semantic_id};
        if (my $prior = $previous{$record->{run_id}}) {
            if (_tuple_cmp(\@tuple, $prior) < 0) {
                _throw(
                    'VIAL_TRACE_ORDER_ERROR',
                    'logical-time records are out of deterministic order: prior=['
                        . join(',', @$prior) . '] current=[' . join(',', @tuple) . ']',
                    "/records/$index/payload/logical_time",
                );
            }
        }
        $previous{$record->{run_id}} = \@tuple;
    }
}

sub _tuple_cmp($left, $right) {
    for my $index (0 .. 4) {
        my $cmp = $left->[$index] <=> $right->[$index];
        return $cmp if $cmp;
    }
    return $left->[5] cmp $right->[5];
}

sub _counts($records) {
    my %counts;
    $counts{$_->{record_kind}}++ for @$records;
    return {map { $_ => $counts{$_} } sort keys %counts};
}

sub _run_id($plan_id, $scenario_id) {
    return "run/$plan_id/$scenario_id";
}

sub _require_record_keys($record, $index) {
    _require_keys($record, \@RECORD_KEYS, 'trace record', "/records/$index");
}

sub _require_exact_keys($value, $keys, $label) {
    _require_keys($value, $keys, $label, '/');
}

sub _require_keys($value, $keys, $label, $path) {
    my %expected = map { $_ => 1 } @$keys;
    my @unknown = sort grep { !$expected{$_} } keys %$value;
    my @missing = grep { !exists($value->{$_}) } @$keys;
    _throw('VIAL_TRACE_SCHEMA_ERROR', "$label has unknown key '$unknown[0]'", $path) if @unknown;
    _throw('VIAL_TRACE_SCHEMA_ERROR', "$label is missing key '$missing[0]'", $path) if @missing;
}

sub _throw($code, $message, $path) {
    die bless {code => $code, message => $message, path => $path},
        'FSM::VIAL::Backend::TraceValidator::Failure';
}

sub _failure($code, $message, $path) {
    return _result({
        ok => JSON::PP::false,
        status => 'error',
        trace_schema => $SCHEMA,
        plan_id => undef,
        records => [],
        projection => undef,
        diagnostics => [{code => $code, severity => 'error', message => $message, path => $path}],
    });
}

sub _result($value) {
    my %expected = map { $_ => 1 } @RESULT_KEYS;
    confess 'trace validator result has unknown key(s)' if grep { !$expected{$_} } keys %$value;
    confess 'trace validator result is missing key(s)' if grep { !exists($value->{$_}) } @RESULT_KEYS;
    return _clone($value);
}

sub _sanitize_exception($error) {
    my $message = defined($error) ? "$error" : 'unknown trace host failure';
    $message =~ s/\s+at\s+\S+\s+line\s+\d+\.?\s*\z//s;
    $message =~ s{(?:[A-Za-z]:)?[/\\][^\s:]+[/\\][^\s:]+}{<host-path>}g;
    $message =~ s/[\r\n]+/ /g;
    $message =~ s/\s+/ /g;
    $message =~ s/\A\s+|\s+\z//g;
    return length($message) ? $message : 'unknown trace host failure';
}

sub _clone($value) {
    return undef unless defined $value;
    return $value ? JSON::PP::true : JSON::PP::false
        if blessed($value) && $value->isa('JSON::PP::Boolean');
    return {map { $_ => _clone($value->{$_}) } sort keys %$value}
        if ref($value) eq 'HASH';
    return [map { _clone($_) } @$value] if ref($value) eq 'ARRAY';
    confess 'trace projection contains an unsupported reference' if ref($value);
    return $value;
}

1;

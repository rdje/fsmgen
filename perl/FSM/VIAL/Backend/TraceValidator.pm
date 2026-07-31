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
            _require_keys($record->{payload}, [qw(scenario_id status)], 'scenario_end payload', "/records/$index/payload");
            my $scenario = $expected[$scenario_index];
            _throw('VIAL_TRACE_IDENTITY_ERROR', 'scenario_end scenario_id is wrong', "/records/$index/payload/scenario_id")
                unless $record->{payload}{scenario_id} eq $scenario->{scenario_id};
            _throw('VIAL_TRACE_SCHEMA_ERROR', 'scenario status is not closed', "/records/$index/payload/status")
                unless ($record->{payload}{status} // '') =~ /\A(?:passed|failed|timeout|error)\z/;
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
            _throw('VIAL_TRACE_ORDER_ERROR', 'logical-time records are out of deterministic order', "/records/$index/payload/logical_time")
                if _tuple_cmp(\@tuple, $prior) < 0;
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

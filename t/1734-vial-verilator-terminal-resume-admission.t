#!/usr/bin/env perl

use strict;
use warnings;

use Digest::SHA qw(sha256_hex);
use JSON::PP ();
use Test::More;

use lib 'perl';

use FSM::VIAL::Backend::VerilatorLifecycle;

my $JSON = JSON::PP->new->canonical(1);

subtest 'qualified version and terminal payloads are reconstructed' => sub {
    for my $seam (qw(
        _validate_terminal_payloads _reconstruct_trace_payload
        _reconstruct_result_payload _reconstruct_assembly_payload
    )) {
        ok(FSM::VIAL::Backend::VerilatorLifecycle->can($seam),
            "$seam exists") or return;
    }

    my $version = 'Verilator 5.046 qualified';
    my $trace = {
        ok => JSON::PP::true,
        projection => {trace_sha256 => '1' x 64, record_count => 4},
    };
    my $trace_bundle = {
        validation => $trace,
        trace_jsonl => "trace\n",
        ordinary => ['ordinary'],
    };
    my $result = {
        trace => $trace,
        result => {
            status => 'pass',
            manifest => {result_id => 'result/' . ('2' x 64)},
        },
    };
    my $assembly = {
        artifact => {},
        result => $result->{result},
        result_rel => 'results/example.json',
    };
    my %payload = (
        tool_version_output => $version,
        validated_trace => canonical($trace),
        runtime_trace_jsonl => $trace_bundle->{trace_jsonl},
        runtime_ordinary_lines => canonical($trace_bundle->{ordinary}),
        result_production_payload => canonical($result),
        assembly_payload => canonical($assembly),
    );
    my $session = {
        selected_profile => {qualified_version_output => $version},
        storage_context => {mode => 'public_runner'},
    };
    my $record = {
        state => 'assembled',
        objects => [map { object($_, $payload{$_} // $_) } qw(
            authority_execution_ir authority_emission tool_version_output
            compile_raw_output compiled_executable runtime_raw_output
            runtime_process_evidence validated_trace runtime_trace_jsonl
            runtime_ordinary_lines result_production_payload assembly_payload
        )],
    };

    no warnings 'redefine';
    local *FSM::VIAL::Backend::VerilatorLifecycle::_read_object_content = sub {
        my ($ignored_session, $object) = @_;
        die "unexpected focused object '$object->{kind}'\n"
            unless exists $payload{$object->{kind}};
        return $payload{$object->{kind}};
    };
    local *FSM::VIAL::Backend::VerilatorLifecycle::_reconstruct_trace_payload =
        sub { clone($trace_bundle) };
    local *FSM::VIAL::Backend::VerilatorLifecycle::_reconstruct_result_payload =
        sub { clone($result) };
    local *FSM::VIAL::Backend::VerilatorLifecycle::_reconstruct_assembly_payload =
        sub {
            return {
                assembly => clone($assembly),
                stored => clone($assembly),
            };
        };

    ok(validate_terminal($session, $record),
        'exact qualified version and reconstructed payloads admit');

    local $payload{tool_version_output} = 'Verilator foreign';
    rejects_terminal($session, $record,
        'foreign sealed tool version rejects');

    local $payload{tool_version_output} = $version;
    local $payload{validated_trace} = canonical({
        ok => JSON::PP::true,
        projection => {trace_sha256 => 'f' x 64, record_count => 4},
    });
    rejects_terminal($session, $record,
        'foreign canonical trace validation rejects');

    local $payload{validated_trace} = canonical($trace);
    local $payload{runtime_trace_jsonl} = "foreign trace\n";
    rejects_terminal($session, $record,
        'foreign extracted trace bytes reject');

    local $payload{runtime_trace_jsonl} = $trace_bundle->{trace_jsonl};
    local $payload{result_production_payload} = canonical({
        result => {status => 'pass'},
    });
    rejects_terminal($session, $record,
        'minimal canonical passing result rejects');

    local $payload{result_production_payload} = canonical($result);
    local $payload{assembly_payload} = canonical({artifact => {}});
    rejects_terminal($session, $record,
        'foreign canonical public assembly rejects');
};

subtest 'successor objects preserve the complete predecessor prefix' => sub {
    ok(FSM::VIAL::Backend::VerilatorLifecycle->can(
        '_validate_object_history'),
        'append-only object-history seam exists') or return;

    my $execution = object('authority_execution_ir', 'execution');
    my $emission = object('authority_emission', 'emission');
    my $version = object('tool_version_output', 'version');
    my $previous = [$execution, $emission];
    my $successor = [clone($execution), clone($emission), $version];
    ok(validate_history($previous, $successor),
        'exact predecessor prefix admits');

    my $replaced = clone($successor);
    $replaced->[1] = object('authority_emission', 'foreign-emission');
    rejects_history($previous, $replaced,
        'replaced predecessor object rejects');

    my $reordered = clone($successor);
    @{$reordered}[0, 1] = @{$reordered}[1, 0];
    rejects_history($previous, $reordered,
        'reordered predecessor objects reject');

    rejects_history($previous, [clone($execution)],
        'missing predecessor object rejects');
};

done_testing();

sub validate_terminal {
    my ($session, $record) = @_;
    return eval {
        FSM::VIAL::Backend::VerilatorLifecycle::_validate_terminal_payloads(
            $session, $record,
        );
        1;
    } ? 1 : 0;
}

sub rejects_terminal {
    my ($session, $record, $label) = @_;
    my $ok = eval {
        FSM::VIAL::Backend::VerilatorLifecycle::_validate_terminal_payloads(
            $session, $record,
        );
        1;
    };
    ok(!$ok, $label);
    isa_ok($@, 'FSM::VIAL::Backend::VerilatorLifecycle::Failure');
    is(ref($@) ? $@->{code} : undef, 'VIAL_LIFECYCLE_STATE_ERROR',
        "$label uses state-admission authority");
}

sub validate_history {
    my ($previous, $current) = @_;
    return eval {
        FSM::VIAL::Backend::VerilatorLifecycle::_validate_object_history(
            $previous, $current,
        );
        1;
    } ? 1 : 0;
}

sub rejects_history {
    my ($previous, $current, $label) = @_;
    my $ok = eval {
        FSM::VIAL::Backend::VerilatorLifecycle::_validate_object_history(
            $previous, $current,
        );
        1;
    };
    ok(!$ok, $label);
    isa_ok($@, 'FSM::VIAL::Backend::VerilatorLifecycle::Failure');
    is(ref($@) ? $@->{code} : undef, 'VIAL_LIFECYCLE_STATE_ERROR',
        "$label uses state-admission authority");
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

sub canonical {
    return $JSON->encode($_[0]);
}

sub clone {
    return $JSON->decode($JSON->encode($_[0]));
}

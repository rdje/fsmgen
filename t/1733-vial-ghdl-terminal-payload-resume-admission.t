#!/usr/bin/env perl

use strict;
use warnings;

use Digest::SHA qw(sha256_hex);
use JSON::PP ();
use Test::More;

use lib 'perl';

use FSM::VIAL::Backend::GHDLLifecycle;

my $JSON = JSON::PP->new->canonical(1);

subtest 'terminal payloads are reconstructed before resumed output' => sub {
    ok(FSM::VIAL::Backend::GHDLLifecycle->can(
        '_validate_terminal_payloads'),
        'terminal semantic reconstruction seam exists') or return;

    my $trace = {
        ok => JSON::PP::true,
        trace => {trace_sha256 => '1' x 64, record_count => 4},
    };
    my $result = {
        schema => 'fsmgen.verification_result_manifest.v1',
        schema_version => 1,
        status => 'pass',
    };
    my $assembly = {
        schema => 'fsmgen.vial_ghdl_lifecycle_assembly.v1',
        schema_version => 1,
        lifecycle_identity => 'lifecycle/' . ('2' x 64),
    };
    my %payload = (
        validated_trace => canonical_line($trace),
        normalized_result => canonical_line($result),
        assembly_payload => canonical_line($assembly),
    );
    my $session = {
        role => 'qualification',
        lifecycle_identity => $assembly->{lifecycle_identity},
    };
    my $record = {
        state => 'assembled',
        objects => [map { object($_, $payload{$_} // $_) } qw(
            lifecycle_authority tool_version_output analysis_output
            elaboration_output runtime_output_0 validated_trace
            normalized_result assembly_payload
        )],
    };

    no warnings 'redefine';
    local *FSM::VIAL::Backend::GHDLLifecycle::_object_content_from = sub {
        my ($ignored_session, $ignored_objects, $kind) = @_;
        die "unexpected focused object '$kind'\n" unless exists $payload{$kind};
        return $payload{$kind};
    };
    local *FSM::VIAL::Backend::GHDLLifecycle::_reconstruct_trace_payload =
        sub { clone($trace) };
    local *FSM::VIAL::Backend::GHDLLifecycle::_reconstruct_result_payload =
        sub { clone($result) };
    local *FSM::VIAL::Backend::GHDLLifecycle::_expected_assembly_payload =
        sub { clone($assembly) };

    ok(validate_terminal($session, $record),
        'exact reconstructed terminal payloads are admitted');

    local $payload{validated_trace} = canonical_line({
        ok => JSON::PP::true,
        trace => {trace_sha256 => 'f' x 64, record_count => 4},
    });
    rejects_terminal($session, $record,
        'foreign canonical trace validation rejects');

    local $payload{validated_trace} = canonical_line($trace);
    local $payload{normalized_result} = canonical_line({
        schema => 'focused-result', status => 'pass',
    });
    rejects_terminal($session, $record,
        'minimal canonical passing result rejects');

    local $payload{normalized_result} = canonical_line($result);
    local $payload{assembly_payload} = canonical_line({
        schema => 'focused-assembly',
        lifecycle_identity => $session->{lifecycle_identity},
    });
    rejects_terminal($session, $record,
        'foreign canonical assembly payload rejects');
};

subtest 'cumulative state objects preserve the predecessor prefix' => sub {
    ok(FSM::VIAL::Backend::GHDLLifecycle->can(
        '_validate_object_history'),
        'append-only object-history seam exists') or return;

    my $authority = object('lifecycle_authority', 'authority');
    my $version = object('tool_version_output', 'version');
    my $analysis = object('analysis_output', 'analysis');
    my $previous = [$authority, $version];
    my $successor = [clone($authority), clone($version), $analysis];
    ok(validate_history($previous, $successor),
        'exact predecessor prefix is admitted');

    my $replaced = clone($successor);
    $replaced->[1] = object('tool_version_output', 'foreign-version');
    rejects_history($previous, $replaced,
        'replaced predecessor object rejects');

    my $reordered = clone($successor);
    @{$reordered}[0, 1] = @{$reordered}[1, 0];
    rejects_history($previous, $reordered,
        'reordered predecessor objects reject');

    my $short = [clone($authority)];
    rejects_history($previous, $short,
        'missing predecessor object rejects');
};

done_testing();

sub validate_terminal {
    my ($session, $record) = @_;
    return eval {
        FSM::VIAL::Backend::GHDLLifecycle::_validate_terminal_payloads(
            $session, $record,
        );
        1;
    } ? 1 : 0;
}

sub rejects_terminal {
    my ($session, $record, $label) = @_;
    my $ok = eval {
        FSM::VIAL::Backend::GHDLLifecycle::_validate_terminal_payloads(
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

sub validate_history {
    my ($previous, $current) = @_;
    return eval {
        FSM::VIAL::Backend::GHDLLifecycle::_validate_object_history(
            $previous, $current,
        );
        1;
    } ? 1 : 0;
}

sub rejects_history {
    my ($previous, $current, $label) = @_;
    my $ok = eval {
        FSM::VIAL::Backend::GHDLLifecycle::_validate_object_history(
            $previous, $current,
        );
        1;
    };
    ok(!$ok, $label);
    isa_ok($@, 'FSM::VIAL::Backend::GHDLLifecycle::Failure');
    is(ref($@) ? $@->{code} : undef,
        'VIAL_GHDL_LIFECYCLE_STATE_ERROR',
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

sub canonical_line {
    return $JSON->encode($_[0]) . "\n";
}

sub clone {
    return $JSON->decode($JSON->encode($_[0]));
}

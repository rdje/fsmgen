package FSM::VIAL::Backend::Runner;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use JSON::PP ();
use Scalar::Util qw(blessed);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::VIAL::Backend::VerilatorLifecycle;

my @RESULT_KEYS = qw(
    ok status operation_id backend_profile backend_manifest result_manifest
    artifacts diagnostics cleanup
);

sub result_keys($class) {
    confess __PACKAGE__ . "->result_keys requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return [@RESULT_KEYS];
}

sub run($class, @args) {
    return _failure(
        'VIAL_RUN_INVOCATION_ERROR',
        'run requires the exact Runner class invocant', '/', undef,
    ) unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return _failure(
        'VIAL_RUN_INVOCATION_ERROR',
        'run expects one closed argument hash', '/', undef,
    ) unless @args == 1 && ref($args[0]) eq 'HASH'
        && !blessed($args[0]);

    my $lifecycle = eval {
        FSM::VIAL::Backend::VerilatorLifecycle
            ->execute_atomic($args[0]);
    };
    return _failure(
        'VIAL_RUN_HOST_ERROR', _sanitize_exception($@), '/', undef,
    ) unless defined $lifecycle;

    my $result = eval { _map_lifecycle($lifecycle) };
    return $result if defined $result;
    return _failure(
        'VIAL_RUN_HOST_ERROR', _sanitize_exception($@), '/', undef,
    );
}

sub _map_lifecycle($lifecycle) {
    return _failure(
        $lifecycle->{diagnostics}[0]{code},
        $lifecycle->{diagnostics}[0]{message},
        $lifecycle->{diagnostics}[0]{path},
        $lifecycle,
    ) unless $lifecycle->{ok};

    my $assembled = $lifecycle->{assembled_result};
    return _failure(
        'VIAL_RUN_HOST_ERROR',
        'shared Verilator lifecycle omitted its assembled result',
        '/lifecycle', $lifecycle,
    ) unless ref($assembled) eq 'HASH' && !blessed($assembled);
    my %expected = map { $_ => 1 } @RESULT_KEYS;
    return _failure(
        'VIAL_RUN_HOST_ERROR',
        'shared Verilator lifecycle assembled a non-closed Runner result',
        '/lifecycle', $lifecycle,
    ) if grep { !$expected{$_} } keys %$assembled;
    return _failure(
        'VIAL_RUN_HOST_ERROR',
        'shared Verilator lifecycle assembled an incomplete Runner result',
        '/lifecycle', $lifecycle,
    ) if grep { !exists($assembled->{$_}) } @RESULT_KEYS;
    return _result($assembled);
}

sub _failure($code, $message, $path, $lifecycle) {
    my $cleanup = {
        staging_identity => undef,
        removed => JSON::PP::false,
    };
    my $operation_id;
    if (defined($lifecycle) && ref($lifecycle) eq 'HASH') {
        $operation_id = $lifecycle->{operation_id};
        $cleanup = {
            staging_identity =>
                $lifecycle->{cleanup}{staging_identity},
            removed => $lifecycle->{cleanup}{removed}
                ? JSON::PP::true : JSON::PP::false,
        };
    }
    return _result({
        ok => JSON::PP::false,
        status => 'error',
        operation_id => $operation_id,
        backend_profile => 'sv_portable_verilator',
        backend_manifest => undef,
        result_manifest => undef,
        artifacts => [],
        diagnostics => [{
            code => $code,
            severity => 'error',
            message => $message,
            path => $path,
        }],
        cleanup => $cleanup,
    });
}

sub _result($value) {
    my %expected = map { $_ => 1 } @RESULT_KEYS;
    confess 'runner result has unknown key(s)'
        if grep { !$expected{$_} } keys %$value;
    confess 'runner result is missing key(s)'
        if grep { !exists($value->{$_}) } @RESULT_KEYS;
    return _clone($value);
}

sub _sanitize_exception($error) {
    my $message = defined($error) ? "$error" : 'unknown runner host failure';
    $message =~ s/\s+at\s+\S+\s+line\s+\d+\.?\s*\z//s;
    $message =~ s{(?:[A-Za-z]:)?[/\\][^\s:]+[/\\][^\s:]+}{<host-path>}g;
    $message =~ s/[\r\n]+/ /g;
    $message =~ s/\s+/ /g;
    $message =~ s/\A\s+|\s+\z//g;
    return length($message) ? $message : 'unknown runner host failure';
}

sub _clone($value) {
    return undef unless defined $value;
    return $value ? JSON::PP::true : JSON::PP::false
        if blessed($value) && $value->isa('JSON::PP::Boolean');
    return {map { $_ => _clone($value->{$_}) } sort keys %$value}
        if ref($value) eq 'HASH';
    return [map { _clone($_) } @$value] if ref($value) eq 'ARRAY';
    confess 'runner projection contains an unsupported reference'
        if ref($value);
    return $value;
}

1;

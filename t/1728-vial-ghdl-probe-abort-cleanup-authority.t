#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use JSON::PP ();
use Scalar::Util qw(refaddr);
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::Backend::GHDLLifecycle;
use FSM::VIAL::Backend::VHDLPortableGHDLQualification;

my $request = {repo_root => '.', authority => 'probe-abort-control'};
my $handle = {state_identity => 'state/probe-abort-control'};

subtest 'successful abort preserves the original probe diagnostic' => sub {
    my $probe_error = probe_failure();
    my ($error, $observed) = abort_with(
        abort_success(), $probe_error,
    );

    is(refaddr($error), refaddr($probe_error),
        'successful cleanup rethrows the exact probe failure object');
    is($error->{code}, 'VIAL_VHDL_QUALIFICATION_TIMEOUT',
        'successful cleanup preserves probe diagnostic authority');
    is_deeply($observed, {%$request, handle => $handle},
        'abort receives the exact lifecycle authority and current handle');
};

subtest 'failed abort makes cleanup authoritative' => sub {
    my ($error) = abort_with({
        ok => JSON::PP::false,
        status => 'error',
        diagnostics => [{
            code => 'VIAL_GHDL_LIFECYCLE_CLEANUP_ERROR',
            severity => 'error',
            message => 'forced lifecycle cleanup failure',
            path => '/cleanup',
        }],
        cleanup => {
            removed => JSON::PP::false,
            residue => ['.artifacts/tmp/probe-abort-control'],
        },
    }, probe_failure());

    isa_ok($error,
        'FSM::VIAL::Backend::VHDLPortableGHDLQualification::Failure');
    is($error->{code}, 'VIAL_VHDL_QUALIFICATION_CLEANUP_ERROR',
        'failed abort has the stable qualifier cleanup diagnostic');
    is($error->{path}, '/cleanup',
        'failed abort points to cleanup rather than the probe phase');
    is($error->{message},
        'shared GHDL lifecycle probe abort failed: '
            . 'forced lifecycle cleanup failure',
        'failed abort retains the bounded lifecycle reason');
};

subtest 'unproved removal fails closed' => sub {
    my ($error) = abort_with({
        ok => JSON::PP::true,
        status => 'aborted_cleaned',
        diagnostics => [],
        cleanup => {
            removed => JSON::PP::false,
            residue => ['.artifacts/tmp/probe-abort-control'],
        },
    }, probe_failure());

    is($error->{code}, 'VIAL_VHDL_QUALIFICATION_CLEANUP_ERROR',
        'success without removal proof is a cleanup failure');
    is($error->{path}, '/cleanup',
        'unproved removal retains cleanup authority');
};

subtest 'unexpected abort exception is sanitized as cleanup failure' => sub {
    my $host_path = File::Spec->catfile(
        File::Spec->rel2abs(File::Spec->catdir($FindBin::Bin, '..')),
        'private', 'abort.pm',
    );
    my ($error) = abort_with(
        sub { die "unexpected abort failure at $host_path line 9.\n" },
        probe_failure(),
    );

    is($error->{code}, 'VIAL_VHDL_QUALIFICATION_CLEANUP_ERROR',
        'unexpected abort exception has cleanup authority');
    is($error->{path}, '/cleanup',
        'unexpected abort exception uses the cleanup path');
    unlike($error->{message}, qr{\Q$host_path\E},
        'unexpected abort exception does not expose a host path');
};

done_testing();

sub abort_with {
    my ($abort, $probe_error) = @_;
    my $observed;
    no warnings 'redefine';
    local *FSM::VIAL::Backend::GHDLLifecycle::abort_session = sub {
        my ($class, $raw) = @_;
        $observed = clone($raw);
        return $abort->() if ref($abort) eq 'CODE';
        return clone($abort);
    };

    my $ok = eval {
        FSM::VIAL::Backend::VHDLPortableGHDLQualification::_abort_probe_session(
            $request, $handle, $probe_error,
        );
        1;
    };
    ok(!$ok, 'probe failure remains rejecting after abort');
    return ($@, $observed);
}

sub probe_failure {
    return bless {
        code => 'VIAL_VHDL_QUALIFICATION_TIMEOUT',
        message => 'four-state probe exceeded its exact deadline',
        path => '/resource_controls',
    }, 'FSM::VIAL::Backend::VHDLPortableGHDLQualification::Failure';
}

sub abort_success {
    return {
        ok => JSON::PP::true,
        status => 'aborted_cleaned',
        diagnostics => [],
        cleanup => {
            removed => JSON::PP::true,
            residue => [],
        },
    };
}

sub clone {
    return JSON::PP->new->decode(JSON::PP->new->encode($_[0]));
}

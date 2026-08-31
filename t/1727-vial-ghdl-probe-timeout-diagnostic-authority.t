#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::Backend::ProcessSupervisor;
use FSM::VIAL::Backend::VHDLPortableGHDLQualification;

my $repo_root = File::Spec->rel2abs(
    File::Spec->catdir($FindBin::Bin, '..'),
);
my $binary = 't/data/vial_fake_ghdl_provider/bin/ghdl';

subtest 'probe timeout is authoritative over generic execution failure' => sub {
    my $error = capture_failure(process_result(timed_out => 1));
    is($error->{code}, 'VIAL_VHDL_QUALIFICATION_TIMEOUT',
        'timeout has the stable qualification diagnostic');
    is($error->{path}, '/resource_controls',
        'timeout points to the bounded resource policy');
    is($error->{message},
        'four-state probe exceeded its exact deadline',
        'timeout message retains the exact phase label');
};

subtest 'timeout is authoritative when the capture ceiling also crosses' => sub {
    my $error = capture_failure(process_result(
        timed_out => 1, output_limited => 1,
    ));
    is($error->{code}, 'VIAL_VHDL_QUALIFICATION_TIMEOUT',
        'combined timeout and overflow retain timeout authority');
    is($error->{path}, '/resource_controls',
        'combined failure retains the timeout policy path');
};

subtest 'capture-only and nonzero-exit diagnostics remain distinct' => sub {
    my $limited = capture_failure(process_result(output_limited => 1));
    is($limited->{code}, 'VIAL_VHDL_QUALIFICATION_LIMIT_ERROR',
        'capture-only excess retains the limit diagnostic');
    is($limited->{path}, '/resource_controls',
        'capture-only excess retains the resource path');

    my $execution = capture_failure(process_result(
        exit_code => 7, signal => 0,
    ));
    is($execution->{code}, 'VIAL_VHDL_QUALIFICATION_EXECUTION_ERROR',
        'ordinary nonzero exit retains the execution diagnostic');
    is($execution->{path}, '/execution',
        'ordinary nonzero exit retains the execution path');
};

subtest 'successful bounded capture remains byte exact' => sub {
    my $result = capture_success(process_result(
        ok => 1, exit_code => 0, signal => 0,
        output => "probe pass\n", output_bytes => 11,
    ));
    is_deeply($result, {
        output => "probe pass\n", output_bytes => 11,
    }, 'successful probe capture projection is unchanged');
};

done_testing();

sub capture_failure {
    my ($capture) = @_;
    my $result;
    my $ok = eval {
        capture_with($capture, sub { $result = shift; });
        1;
    };
    ok(!$ok, 'controlled process failure rejects');
    my $error = $@;
    isa_ok($error,
        'FSM::VIAL::Backend::VHDLPortableGHDLQualification::Failure');
    return ref($error) ? $error : {};
}

sub capture_success {
    my ($capture) = @_;
    my $result;
    capture_with($capture, sub { $result = shift; });
    return $result;
}

sub capture_with {
    my ($capture, $consumer) = @_;
    no warnings 'redefine';
    local *FSM::VIAL::Backend::ProcessSupervisor::capture = sub {
        return clone($capture);
    };
    my $result =
        FSM::VIAL::Backend::VHDLPortableGHDLQualification::_capture(
            $repo_root,
            [$binary, '--version'],
            10,
            65_536,
            'four-state probe',
        );
    $consumer->($result);
}

sub process_result {
    my (%override) = @_;
    return {
        ok => JSON::PP::false,
        exit_code => 143,
        signal => 15,
        timed_out => JSON::PP::false,
        output_limited => JSON::PP::false,
        exec_failed => JSON::PP::false,
        exec_error => undef,
        output => '',
        output_bytes => 0,
        %override,
    };
}

sub clone {
    return JSON::PP->new->decode(JSON::PP->new->encode($_[0]));
}

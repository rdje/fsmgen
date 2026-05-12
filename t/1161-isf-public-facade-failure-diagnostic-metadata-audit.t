#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::ISFPublicInterfaceContract qw(
    build_isf_public_interface_contract
    isf_public_interface_facade_failure_diagnostic_shape
);

subtest 'direct ISF facade failure diagnostic metadata is exact' => sub {
    assert_failure_diagnostic_metadata(
        build_isf_public_interface_contract(),
        'direct ISF public-interface contract',
    );
};

subtest 'manifest ISF facade failure diagnostic metadata is exact' => sub {
    my @views = (
        {
            label => 'in-process capability manifest',
            payload => build_capability_manifest(),
        },
        {
            label => 'CLI capability manifest',
            payload => run_capability_manifest('--capability-manifest'),
        },
        {
            label => 'CLI capability manifest alias',
            payload => run_capability_manifest('--emit-capability-manifest'),
        },
    );

    for my $view (@views) {
        my $label = $view->{label};
        assert_failure_diagnostic_metadata(
            $view->{payload}{embedding}{isf_public_interface},
            "$label ISF public-interface contract",
        );
    }
};

subtest 'public facade boundary failures emit bounded scalar diagnostics' => sub {
    my $adapter = FSM::Adapter::ISF->new();
    my $scheduler = FSM::Scheduler::ISF->new();

    for my $case (
        [
            'constructor odd option list',
            sub { FSM::Adapter::ISF->new('debug') },
            qr/\AFSM::Adapter::ISF->new expects an even-length option\/value list/,
        ],
        [
            'parser missing path',
            sub { $adapter->parse_file() },
            qr/\AFSM::Adapter::ISF->parse_file expects exactly 1 scalar argument\(s\)/,
        ],
        [
            'scheduler missing actor shell',
            sub { $scheduler->lower({}) },
            qr/\AFSM::Scheduler::ISF->lower actor must include scalar actor_name/,
        ],
    ) {
        my ($label, $code, $pattern) = @$case;
        assert_bounded_failure($code, $pattern, $label);
    }
};

done_testing();

sub assert_failure_diagnostic_metadata {
    my ($contract, $label) = @_;

    is(
        $contract->{facade_failure_diagnostic_shape},
        isf_public_interface_facade_failure_diagnostic_shape(),
        "$label facade_failure_diagnostic_shape is exact",
    );
}

sub assert_bounded_failure {
    my ($code, $pattern, $label) = @_;
    my $ok = eval { $code->(); 1 };
    my $diagnostic = $@;

    ok(!$ok, "$label fails at the public facade boundary");
    ok(!ref($diagnostic), "$label diagnostic is scalar");
    like($diagnostic, $pattern, "$label diagnostic matches the public boundary");
}

sub run_capability_manifest {
    my ($mode) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', $mode],
    );

    ok($success, "$mode succeeds");
    is(join('', @{$stderr_buf || []}), '', "$mode keeps stderr clean");

    return decode_json(join('', @{$stdout_buf || []}));
}

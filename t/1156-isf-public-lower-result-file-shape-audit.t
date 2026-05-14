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
    isf_public_interface_lower_result_file_name_shape
    isf_public_interface_lower_result_file_text_shape
);

subtest 'direct ISF lower-result file-shape metadata is exact' => sub {
    assert_lower_file_metadata(
        build_isf_public_interface_contract(),
        'direct ISF public-interface contract',
    );
};

subtest 'manifest ISF lower-result file-shape metadata is exact' => sub {
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
        assert_lower_file_metadata(
            $view->{payload}{embedding}{isf_public_interface},
            "$label ISF public-interface contract",
        );
    }
};

subtest 'public lower-result files follow advertised filename and text shapes' => sub {
    assert_lower_result_files('apb_requester.isf');
    assert_lower_result_files('spawn_parent.isf');
};

done_testing();

sub assert_lower_file_metadata {
    my ($contract, $label) = @_;

    is(
        $contract->{lower_result_file_name_shape},
        isf_public_interface_lower_result_file_name_shape(),
        "$label lower_result_file_name_shape is exact",
    );
    is(
        $contract->{lower_result_file_text_shape},
        isf_public_interface_lower_result_file_text_shape(),
        "$label lower_result_file_text_shape is exact",
    );
}

sub assert_lower_result_files {
    my ($fixture) = @_;
    my $lowered = lower_fixture($fixture);

    ok(ref($lowered->{files}) eq 'HASH', "$fixture lower result exposes a files map");
    for my $basename (sort keys %{$lowered->{files}}) {
        my $source = $lowered->{files}{$basename};
        my $stem = $basename;
        $stem =~ s/\.fsm\z//;

        like($basename, qr/\A[^\/\\]+\.fsm\z/, "$fixture file key is a .fsm basename");
        ok(!ref($source), "$fixture $basename source text is scalar");
        if ($stem =~ /_top\z/) {
            like($source, qr/\A\(\?top:\Q$stem\E\b/, "$fixture $basename generated top root matches basename stem");
        } else {
            like($source, qr/\A\(\?fsm:\Q$stem\E\b/, "$fixture $basename source root matches basename stem");
        }
    }
}

sub lower_fixture {
    my ($fixture) = @_;
    my $path = File::Spec->catfile($FindBin::Bin, '..', 'isf', $fixture);
    my $actor = FSM::Adapter::ISF->new()->parse_file($path);
    return FSM::Scheduler::ISF->new()->lower($actor);
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

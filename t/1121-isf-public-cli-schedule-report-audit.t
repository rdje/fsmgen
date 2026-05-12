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
use FSM::Support::ISFPublicInterfaceContract qw(
    isf_public_interface_schedule_report_top_level_keys
);

subtest 'CLI schedule JSON matches the in-process scheduler report' => sub {
    my $isf_file = File::Spec->catfile($FindBin::Bin, '..', 'isf', 'apb_requester.isf');
    my $cli_report = run_schedule_json($isf_file);

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_file);
    my $in_process_report = decode_json(FSM::Scheduler::ISF->new()->report($actor));

    is_deeply(
        $cli_report,
        $in_process_report,
        '--emit-schedule-json emits the same public report as the in-process scheduler',
    );
    is_deeply(
        sorted([keys %$cli_report]),
        sorted(isf_public_interface_schedule_report_top_level_keys()),
        'CLI schedule report exposes the advertised top-level key family',
    );
    is_deeply(
        [map { $_->{name} } @{$cli_report->{dt_blocks}}],
        [qw(apb_transfer_cc_inc access_phase done_phase penable psel setup_phase)],
        'CLI schedule report preserves deterministic DT block order',
    );
};

done_testing();

sub run_schedule_json {
    my ($path) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $path],
    );

    ok($success, '--emit-schedule-json succeeds');
    is(join('', @{$stderr_buf || []}), '', '--emit-schedule-json keeps stderr clean');

    return decode_json(join('', @{$stdout_buf || []}));
}

sub sorted {
    my ($values) = @_;
    return [sort @{$values || []}];
}

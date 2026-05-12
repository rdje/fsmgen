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
    build_isf_public_interface_contract
    isf_public_interface_schedule_report_compile_issues_success_shape
);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');

subtest 'contract advertises successful compile_issues shape' => sub {
    my $contract = build_isf_public_interface_contract();

    is(
        $contract->{schedule_report_compile_issues_success_shape},
        isf_public_interface_schedule_report_compile_issues_success_shape(),
        'contract publishes the success shape for compile_issues',
    );
    ok(
        key_list_contains(
            $contract->{public_top_level_presence_keys},
            'schedule_report_compile_issues_success_shape',
        ),
        'compile_issues success shape is part of the public contract surface',
    );
};

subtest 'successful public schedule reports expose empty compile_issues' => sub {
    my $fixture = repo_file('isf/apb_requester.isf');

    assert_successful_compile_issues(
        in_process_report($fixture),
        'in-process scheduler report',
    );
    assert_successful_compile_issues(
        cli_report($fixture),
        'CLI --emit-schedule-json report',
    );
};

done_testing();

sub in_process_report {
    my ($path) = @_;
    my $actor = FSM::Adapter::ISF->new()->parse_file($path);
    return decode_json(FSM::Scheduler::ISF->new()->report($actor));
}

sub cli_report {
    my ($path) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $path],
    );

    ok($success, 'CLI report command succeeds');
    is(join('', @{$stderr_buf || []}), '', 'CLI report command keeps stderr clean');

    return decode_json(join('', @{$stdout_buf || []}));
}

sub assert_successful_compile_issues {
    my ($report, $label) = @_;

    ok(exists $report->{compile_issues}, "$label exposes compile_issues");
    is(ref($report->{compile_issues}), 'ARRAY', "$label compile_issues is an array");
    is_deeply($report->{compile_issues}, [], "$label compile_issues is empty on success");
}

sub repo_file {
    my ($relpath) = @_;
    return File::Spec->catfile($repo_root, split m{/}, $relpath);
}

sub key_list_contains {
    my ($keys, $needle) = @_;
    return scalar grep { $_ eq $needle } @{$keys || []};
}

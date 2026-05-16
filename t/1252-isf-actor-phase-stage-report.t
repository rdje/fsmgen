#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Support::ISFPublicInterfaceContract qw(
    isf_public_interface_schedule_report_actor_phase_keys
    isf_public_interface_schedule_report_actor_stage_keys
    isf_public_interface_schedule_report_top_level_keys
);

subtest 'actor-level phase and stage metadata reaches bounded schedule report' => sub {
    my $actor = FSM::Adapter::ISF->new()->parse_source(actor_metadata_source(), 'actor-metadata-report.isf');
    my $scheduler = FSM::Scheduler::ISF->new();
    my $report = decode_json($scheduler->report($actor));

    is_deeply(
        sorted([keys %$report]),
        sorted(isf_public_interface_schedule_report_top_level_keys()),
        'report exposes exactly the advertised top-level keys',
    );

    is_deeply(
        sorted([keys %{$report->{actor_phases}[0]}]),
        sorted(isf_public_interface_schedule_report_actor_phase_keys()),
        'actor phase entries expose the advertised keys',
    );
    is_deeply(
        sorted([keys %{$report->{actor_stages}[0]}]),
        sorted(isf_public_interface_schedule_report_actor_stage_keys()),
        'actor stage entries expose the advertised keys',
    );
    is_deeply(
        $report->{actor_phases},
        [
            {
                name => 'setup',
                body => [
                    ['outputs', 'done'],
                    ['next',    'finish'],
                ],
            },
        ],
        'actor phase report preserves parser-validated name and body',
    );
    is_deeply(
        $report->{actor_stages},
        [
            {
                name => 'pass_through',
                body => [
                    ['input',   'start'],
                    ['output',  'done'],
                    ['latency', ['max', '3']],
                ],
            },
        ],
        'actor stage report preserves parser-validated name and body',
    );

    my $lowered = $scheduler->lower($actor);
    my $fsm = $lowered->{files}{'actor_metadata_report.fsm'};
    like($fsm, qr/\bmain_idle_0\b/, 'actor still lowers normally');
    unlike($fsm, qr/pass_through|setup/, 'actor-level metadata does not create scheduled states');
};

subtest 'CLI schedule JSON preserves actor-level metadata projection' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $path = File::Spec->catfile($tempdir, 'actor_metadata_report.isf');
    write_file($path, actor_metadata_source());

    my $cli_report = run_schedule_json($path);
    my $actor = FSM::Adapter::ISF->new()->parse_file($path);
    my $in_process_report = decode_json(FSM::Scheduler::ISF->new()->report($actor));

    is_deeply(
        $cli_report->{actor_phases},
        $in_process_report->{actor_phases},
        'CLI preserves the in-process actor phase projection',
    );
    is_deeply(
        $cli_report->{actor_stages},
        $in_process_report->{actor_stages},
        'CLI preserves the in-process actor stage projection',
    );
};

done_testing();

sub actor_metadata_source {
    return <<'ISF';
(actor actor_metadata_report
  (clock clk)
  (interface
    (input start)
    (output done))
  (phase setup (outputs done) (next finish))
  (stage pass_through (input start) (output done) (latency (max 3)))
  (transaction main
    (on start)
    (complete done)))
ISF
}

sub run_schedule_json {
    my ($path) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $path],
    );

    ok($success, '--emit-schedule-json succeeds');
    is(join('', @{$stderr_buf || []}), '', '--emit-schedule-json keeps stderr clean');

    return decode_json(join('', @{$stdout_buf || []}));
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

sub sorted {
    my ($values) = @_;
    return [sort @{$values || []}];
}

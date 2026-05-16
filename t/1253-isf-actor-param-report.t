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
    isf_public_interface_schedule_report_actor_param_keys
    isf_public_interface_schedule_report_top_level_keys
);

subtest 'actor-level parameter defaults reach bounded schedule report' => sub {
    my $actor = FSM::Adapter::ISF->new()->parse_source(actor_param_source(), 'actor-param-report.isf');
    my $scheduler = FSM::Scheduler::ISF->new();
    my $report = decode_json($scheduler->report($actor));

    is_deeply(
        sorted([keys %$report]),
        sorted(isf_public_interface_schedule_report_top_level_keys()),
        'report exposes exactly the advertised top-level keys',
    );
    is_deeply(
        sorted([keys %{$report->{actor_params}[0]}]),
        sorted(isf_public_interface_schedule_report_actor_param_keys()),
        'actor parameter entries expose the advertised keys',
    );
    is_deeply(
        $report->{actor_params},
        [
            { name => 'WIDTH', value => '8' },
            { name => 'LANES', value => ['1', '2'] },
        ],
        'actor parameter report preserves scalar and list defaults',
    );

    my $lowered = $scheduler->lower($actor);
    like(
        $lowered->{files}{'actor_param_report.fsm'},
        qr/\(\+params\s+\(WIDTH 8\)\s+\(LANES \(1 2\)\)\s+\)/,
        'actor parameter report does not change scheduled +params emission',
    );
};

subtest 'CLI schedule JSON preserves actor parameter projection' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $path = File::Spec->catfile($tempdir, 'actor_param_report.isf');
    write_file($path, actor_param_source());

    my $cli_report = run_schedule_json($path);
    my $actor = FSM::Adapter::ISF->new()->parse_file($path);
    my $in_process_report = decode_json(FSM::Scheduler::ISF->new()->report($actor));

    is_deeply(
        $cli_report->{actor_params},
        $in_process_report->{actor_params},
        'CLI preserves the in-process actor parameter projection',
    );
};

done_testing();

sub actor_param_source {
    return <<'ISF';
(actor actor_param_report
  (clock clk)
  (params
    (WIDTH 8)
    (LANES (1 2)))
  (interface
    (input start)
    (output done))
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

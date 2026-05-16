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
    isf_public_interface_schedule_report_storage_role_values
);

my $ROLE = 'temporal_contract_monitor';

subtest 'temporal contract monitor storage reports advertised roles' => sub {
    my $report = report_source(contract_source(), 'temporal-contract-storage-report.isf');
    my %advertised_role = map { $_ => 1 } @{isf_public_interface_schedule_report_storage_role_values()};

    ok($advertised_role{$ROLE}, "storage role '$ROLE' is advertised");

    my $entries = contract_storage_entries($report);
    is_deeply(
        $entries,
        [
            {
                name  => 'main_contract_1_age',
                kind  => 'counter',
                role  => $ROLE,
                width => 2,
            },
            {
                name  => 'main_contract_1_fail',
                kind  => 'register',
                role  => $ROLE,
                width => 1,
            },
            {
                name  => 'main_contract_1_pending',
                kind  => 'register',
                role  => $ROLE,
                width => 1,
            },
        ],
        'contract pending/fail registers and age counter expose stable storage roles',
    );

    my @arm_entries = grep { ($_->{name} // '') eq 'main_contract_1_arm' } @{$report->{inferred_storage} || []};
    is(scalar(@arm_entries), 0, 'combinational contract arm request is not reported as inferred storage');
};

subtest 'CLI schedule report matches in-process temporal contract storage roles' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $path = File::Spec->catfile($tempdir, 'temporal_contract_storage_report.isf');
    write_file($path, contract_source());

    my $cli_report = run_schedule_json($path);
    my $actor = FSM::Adapter::ISF->new()->parse_file($path);
    my $in_process_report = decode_json(FSM::Scheduler::ISF->new()->report($actor));

    is_deeply(
        contract_storage_entries($cli_report),
        contract_storage_entries($in_process_report),
        'CLI preserves in-process temporal contract storage role projection',
    );
};

done_testing();

sub contract_source {
    return <<'ISF';
(actor temporal_contract_storage_report
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input ack)
    (output done))
  (transaction main
    (on start)
    (contract ack_seen (eventually ack (within 3)))
    (complete done)))
ISF
}

sub report_source {
    my ($source, $label) = @_;
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, $label);
    return decode_json(FSM::Scheduler::ISF->new()->report($actor));
}

sub contract_storage_entries {
    my ($report) = @_;
    my @entries = grep {
        defined($_->{role}) && $_->{role} eq $ROLE
    } @{$report->{inferred_storage} || []};
    return [sort { $a->{name} cmp $b->{name} } @entries];
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

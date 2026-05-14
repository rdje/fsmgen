#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP ();

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

sub names_by_key {
    my ($items, $key) = @_;
    return sort map { $_->{$key} } @$items;
}

sub entry_by_name {
    my ($items, $name) = @_;
    my ($entry) = grep { $_->{name} eq $name } @$items;
    return $entry;
}

subtest 'schedule JSON report describes APB requester lowering IR' => sub {
    my $isf_file = File::Spec->catfile($FindBin::Bin, '..', 'isf', 'apb_requester.isf');
    my $actor    = FSM::Adapter::ISF->new()->parse_file($isf_file);
    my $json     = FSM::Scheduler::ISF->new()->report($actor);
    my $report   = JSON::PP->new->decode($json);

    is($report->{source},        'apb_requester.isf', 'source name');
    is($report->{scheduled_fsm}, 'apb_requester.fsm', 'scheduled fsm name');
    is($report->{clock},         'clk',               'clock name');
    is($report->{watchdog},      '65536',             'watchdog is parser-carried scalar');

    is_deeply(
        $report->{reset},
        { name => 'rst_n', kind => 'async', polarity => 'active_low' },
        'reset summary',
    );

    is($report->{port_count}, 15, 'port count');
    is($report->{inputs},      7, 'input count');
    is($report->{outputs},     8, 'output count');
    is($report->{state_count}, 7, 'state count');
    is(scalar(@{$report->{compatible_fanin_groups}}), 1, 'one compatible fan-in group reported');
    is($report->{generated_composition}, undef, 'APB report has no generated composition top');
    my $done_fanin = $report->{compatible_fanin_groups}[0];
    is($done_fanin->{kind}, 'pulse', 'done compatible fan-in group is a pulse group');
    is($done_fanin->{target}, 'done', 'done compatible fan-in group names the done target');
    is_deeply(
        [
            sort
            map { join(':', $_->{owner}, $_->{source_kind}, $_->{target}) }
            @{$done_fanin->{sources}}
        ],
        ['apb_transfer:complete_pulse:done', 'apb_transfer:timeout_pulse:done'],
        'done compatible fan-in group reports completion and timeout pulse sources',
    );
    is_deeply($report->{compile_issues}, [], 'no compile issues reported');

    my $transactions = $report->{transactions};
    is(scalar(@$transactions), 1, 'one transaction summary');
    is($transactions->[0]{name},  'apb_transfer', 'transaction name');
    is($transactions->[0]{count}, 7,              'transaction state count');
    is_deeply(
        $transactions->[0]{states},
        [qw(
          apb_transfer_idle_0
          apb_transfer_drive_1
          apb_transfer_drive_2
          apb_transfer_await_3
          apb_transfer_drive_4
          apb_transfer_done_5
          apb_transfer_timeout
        )],
        'transaction state order',
    );

    is_deeply(
        [names_by_key($report->{dt_blocks}, 'name')],
        [qw(access_phase apb_transfer_cc_inc done_phase penable psel setup_phase)],
        'dt block names',
    );

    my $setup_phase = entry_by_name($report->{dt_blocks}, 'setup_phase');
    is($setup_phase->{kind},        'drive', 'setup_phase kind');
    is($setup_phase->{assignments}, 5,       'setup_phase assignment count');

    my $latency_dt = entry_by_name($report->{dt_blocks}, 'apb_transfer_cc_inc');
    is($latency_dt->{kind},        'latency_counter', 'latency counter dt kind');
    is($latency_dt->{assignments}, 1,                 'latency dt assignment count');

    my $storage_names = [names_by_key($report->{inferred_storage}, 'name')];
    is_deeply(
        $storage_names,
        [qw(
          addr
          apb_transfer_cc
          apb_transfer_wd
          done
          is_write
          last_error
          penable_start
          penable_val
          psel_start
          psel_val
          rdata
          slverr
          wdata
        )],
        'inferred storage names',
    );

    my $penable_start = entry_by_name($report->{inferred_storage}, 'penable_start');
    is($penable_start->{kind},  'counter', 'drive start is reported as counter storage');
    is($penable_start->{width}, 1,         'drive start width');

    my $done = entry_by_name($report->{inferred_storage}, 'done');
    is($done->{kind}, 'register', 'completion pulse storage is reported as register storage');
};

done_testing();

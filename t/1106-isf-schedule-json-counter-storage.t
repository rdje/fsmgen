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

sub entry_by_name {
    my ($items, $name) = @_;
    my ($entry) = grep { $_->{name} eq $name } @$items;
    return $entry;
}

subtest 'schedule JSON reports assigned counters with inferred widths' => sub {
    my $isf_file = File::Spec->catfile($FindBin::Bin, '..', 'isf', 'apb_requester.isf');
    my $actor    = FSM::Adapter::ISF->new()->parse_file($isf_file);
    my $json     = FSM::Scheduler::ISF->new()->report($actor);
    my $report   = JSON::PP->new->decode($json);
    my $storage  = $report->{inferred_storage};

    my @watchdogs = grep { $_->{name} eq 'apb_transfer_wd' } @$storage;
    is(scalar(@watchdogs), 1, 'watchdog counter appears once');
    is($watchdogs[0]{kind},  'counter', 'watchdog storage is classified as a counter');
    is($watchdogs[0]{width}, 17,        'watchdog storage keeps the inferred width');

    my $latency_counter = entry_by_name($storage, 'apb_transfer_cc');
    is($latency_counter->{kind},  'counter', 'latency storage is classified as a counter');
    is($latency_counter->{width}, 5,         'latency storage keeps the max-bound inferred width');

    my $drive_start = entry_by_name($storage, 'penable_start');
    is($drive_start->{kind},  'counter', 'combinational drive start still comes from the counter table');
    is($drive_start->{width}, 1,         'combinational drive start keeps its counter-table width');

    my $last_error = entry_by_name($storage, 'last_error');
    is($last_error->{kind}, 'register', 'ordinary flopped output remains register storage');
    ok(!exists $last_error->{width}, 'ordinary register storage does not borrow a counter width');
};

done_testing();

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
    is($watchdogs[0]{role},  'watchdog_counter', 'watchdog storage reports its scheduler role');
    is($watchdogs[0]{width}, 17,        'watchdog storage keeps the inferred width');

    my $latency_counter = entry_by_name($storage, 'apb_transfer_cc');
    is($latency_counter->{kind},  'counter', 'latency storage is classified as a counter');
    is($latency_counter->{role},  'latency_counter', 'latency storage reports its scheduler role');
    is($latency_counter->{width}, 5,         'latency storage keeps the max-bound inferred width');

    my $last_error = entry_by_name($storage, 'last_error');
    is($last_error->{kind}, 'register', 'ordinary flopped output remains register storage');
    is($last_error->{width}, 1, 'ordinary register storage reports its known width');
};

subtest 'generated named-drive requests retain counter metadata' => sub {
    my $path = File::Spec->catfile($FindBin::Bin, '..', 'isf', 'spawn_parent.isf');
    my $actor = FSM::Adapter::ISF->new()->parse_file($path);
    my $report = JSON::PP->new->decode(FSM::Scheduler::ISF->new()->report($actor));
    my @instances = @{$report->{generated_composition}{instances} || []};

    is_deeply([map { $_->{instance} } @instances], [qw(w0 w1 w2)],
        'fixture exposes each generated child instance');
    for my $instance (@instances) {
        my $label = $instance->{instance};
        my ($handoff) = grep { $_->{drive} eq 'rdata' }
            @{$instance->{drive_handoffs} || []};
        ok($handoff, "$label exposes its named-drive handoff");
        next unless $handoff;

        # Follow the public binding instead of assuming an allocated signal name.
        my $name = $handoff->{request}{parent_port};
        ok(defined($name) && length($name), "$label names its parent request signal");
        next unless defined($name) && length($name);
        my $entry = entry_by_name($report->{inferred_storage}, $name);
        ok($entry, "$label request appears in inferred storage");
        next unless $entry;

        is($entry->{kind}, 'counter', "$label request retains its counter-table kind");
        is($entry->{role}, 'drive_request', "$label request reports its drive role");
        is($entry->{width}, 1, "$label request retains its one-bit counter-table width");
    }
};

done_testing();

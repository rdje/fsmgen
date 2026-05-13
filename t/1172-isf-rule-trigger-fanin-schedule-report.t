#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Spec;
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

my $source = <<'ISF';
(actor rule_trigger_fanin
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input a)
    (input b)
    (output done))
  (transaction work
    (on work_start)
    (complete done))
  (rule r0 a
    (trigger work))
  (rule r1 b
    (trigger work)))
ISF

my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'rule-trigger-fanin.isf');
my $report = decode_json(FSM::Scheduler::ISF->new()->report($actor));

is_deeply(
    $report->{dt_blocks},
    [
        { name => 'r0',                 kind => 'rule',               assignments => 1 },
        { name => 'r1',                 kind => 'rule',               assignments => 1 },
        { name => 'work_trigger_fanin', kind => 'rule_trigger_fanin', assignments => 1 },
    ],
    'schedule report exposes rule trigger fan-in DT order, kind, and assignment count',
);

my %storage_by_name = map { $_->{name} => $_ } @{$report->{inferred_storage}};
for my $name (qw(r0_work r1_work work_start)) {
    ok(exists $storage_by_name{$name}, "schedule report exposes inferred storage for $name");
    is($storage_by_name{$name}{kind}, 'counter', "$name is reported as scheduler-inferred storage");
    is($storage_by_name{$name}{width}, 1, "$name is reported as one-bit storage");
}

is_deeply($report->{compile_issues}, [], 'rule trigger fan-in schedule report has no compile issues');

done_testing();

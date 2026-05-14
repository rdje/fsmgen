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

my $source = <<'ISF';
(actor compatible_fanin
  (clock clk)
  (interface
    (input start)
    (input kick)
    (input a)
    (input b)
    (output done)
    (output valid))
  (transaction work
    (on start)
    (complete done))
  (transaction parent
    (on kick)
    (do work)
    (complete done))
  (rule r0 a
    (valid 1)
    (trigger work))
  (rule r1 b
    (valid 1)
    (trigger work)))
ISF

subtest 'in-process report projects compatible fan-in groups' => sub {
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'compatible-fanin.isf');
    my $report = decode_json(FSM::Scheduler::ISF->new()->report($actor));

    assert_compatible_fanin_projection($report, 'in-process schedule report');
};

subtest 'CLI schedule report projects compatible fan-in groups' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $path = File::Spec->catfile($dir, 'compatible_fanin.isf');

    open my $fh, '>', $path or die "cannot write $path: $!";
    print {$fh} $source;
    close $fh or die "cannot close $path: $!";

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $path],
    );

    ok($success, 'CLI report command succeeds with compatible fan-in groups');
    is(join('', @{$stderr_buf || []}), '', 'CLI report command keeps stderr clean');

    my $report = decode_json(join('', @{$stdout_buf || []}));
    assert_compatible_fanin_projection($report, 'CLI schedule report');
};

done_testing();

sub assert_compatible_fanin_projection {
    my ($report, $label) = @_;

    ok(exists $report->{compatible_fanin_groups}, "$label exposes compatible_fanin_groups");
    is(ref($report->{compatible_fanin_groups}), 'ARRAY', "$label compatible_fanin_groups is an array");
    is(scalar(@{$report->{compatible_fanin_groups}}), 4, "$label exposes the expected compatible fan-in groups");

    for my $group (@{$report->{compatible_fanin_groups}}) {
        assert_group_keys_are_bounded($group, $label);
        for my $source_summary (@{$group->{sources} || []}) {
            assert_source_summary_is_bounded($source_summary, $label);
        }
    }

    my $same_valid = find_group($report, kind => 'same_target_value', target => 'valid');
    is($same_valid->{domain}, 'data', "$label same-target group keeps data domain");
    is($same_valid->{operator}, '<-', "$label same-target group keeps assignment operator");
    is("$same_valid->{rhs}", '1', "$label same-target group keeps RHS");
    is_deeply(
        sorted_sources($same_valid),
        ['r0:rule_action:valid', 'r1:rule_action:valid'],
        "$label same-target group preserves rule action sources",
    );

    my $request_work = find_group($report, kind => 'request', target => 'work_start');
    is_deeply(
        sorted_sources($request_work),
        ['parent:do_start:work_start', 'work:rule_trigger_fanin:work_start'],
        "$label request group preserves request sources",
    );

    my $pulse_done = find_group($report, kind => 'pulse', target => 'done');
    is($pulse_done->{operator}, '<1', "$label pulse group keeps pulse operator");
    is("$pulse_done->{rhs}", '1', "$label pulse group keeps pulse value");
    is_deeply(
        sorted_sources($pulse_done),
        ['parent:complete_pulse:done', 'work:complete_pulse:done'],
        "$label pulse group preserves completion sources",
    );

    my $trigger_work = find_group($report, kind => 'rule_trigger_fanin', target_transaction => 'work');
    is($trigger_work->{domain}, 'request', "$label trigger fan-in group is a request group");
    is($trigger_work->{fanin_target}, 'work_start', "$label trigger fan-in group names the generated start target");
    ok(!exists $trigger_work->{target}, "$label trigger fan-in group does not invent a target key");
    is_deeply(
        sorted_sources($trigger_work),
        ['r0:rule_trigger_source:r0_work', 'r1:rule_trigger_source:r1_work'],
        "$label trigger fan-in group preserves per-rule trigger sources",
    );
}

sub assert_group_keys_are_bounded {
    my ($group, $label) = @_;
    my %allowed = map { $_ => 1 } qw(
        kind domain sources target target_transaction fanin_target operator rhs
    );
    for my $key (qw(kind domain sources)) {
        ok(exists $group->{$key}, "$label fan-in group keeps required key $key");
    }
    for my $key (sort keys %$group) {
        ok($allowed{$key}, "$label fan-in group key $key is advertised");
    }
}

sub assert_source_summary_is_bounded {
    my ($source_summary, $label) = @_;

    is_deeply(
        [sort keys %$source_summary],
        [sort qw(owner owner_kind source_kind target operator rhs domain)],
        "$label fan-in source summary uses the bounded public key set",
    );
    ok(!exists $source_summary->{activation}, "$label fan-in source summary omits activation internals");
    ok(!exists $source_summary->{assignment_index}, "$label fan-in source summary omits assignment index internals");
    ok(!exists $source_summary->{priority_suppressed_by}, "$label fan-in source summary omits priority internals");
}

sub find_group {
    my ($report, %want) = @_;
    GROUP:
    for my $group (@{$report->{compatible_fanin_groups} || []}) {
        for my $key (sort keys %want) {
            next GROUP unless defined($group->{$key}) && $group->{$key} eq $want{$key};
        }
        return $group;
    }
    fail('found compatible fan-in group for ' . join(', ', map { "$_=$want{$_}" } sort keys %want));
    return {};
}

sub sorted_sources {
    my ($group) = @_;
    return [
        sort
        map { join(':', $_->{owner}, $_->{source_kind}, $_->{target}) }
        @{$group->{sources} || []}
    ];
}

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
(actor arbitration_report
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input force)
    (input high_req)
    (input low_req)
    (input high_bundle_req)
    (input low_bundle_req)
    (output done)
    (output out)
    (output valid)
    (output err)
    (output flag)
    (output warn))
  (priority force_out over main)
  (priority high over low)
  (priority high_bundle over low_bundle)
  (resources
    (resource shared_slot
      (kind rule_slot)
      (arbiter priority)
      (users high low))
    (resource response_outputs
      (kind output_bundle)
      (arbiter priority)
      (users high_bundle low_bundle)))
  (transaction main
    (on start)
    (update out 0)
    (complete done))
  (rule force_out force
    (out 1))
  (rule high high_req
    (valid 1))
  (rule low low_req
    (err 1))
  (rule high_bundle high_bundle_req
    (flag 1))
  (rule low_bundle low_bundle_req
    (warn 1)))
ISF

subtest 'in-process report projects arbitration summaries' => sub {
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'arbitration-report.isf');
    my $report = decode_json(FSM::Scheduler::ISF->new()->report($actor));

    assert_arbitration_projection($report, 'in-process schedule report');
};

subtest 'CLI schedule report projects arbitration summaries' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $path = File::Spec->catfile($dir, 'arbitration_report.isf');
    write_file($path, $source);

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $path],
    );

    ok($success, 'CLI report command succeeds with arbitration summaries');
    is(join('', @{$stderr_buf || []}), '', 'CLI report command keeps stderr clean');

    my $report = decode_json(join('', @{$stdout_buf || []}));
    assert_arbitration_projection($report, 'CLI schedule report');
};

done_testing();

sub assert_arbitration_projection {
    my ($report, $label) = @_;

    ok(exists $report->{priority_resolutions}, "$label exposes priority_resolutions");
    is(ref($report->{priority_resolutions}), 'ARRAY', "$label priority_resolutions is an array");
    is_deeply(
        $report->{priority_resolutions},
        [
            {
                target      => 'out',
                winner      => 'force_out',
                winner_kind => 'rule',
                loser       => 'main',
                loser_kind  => 'transaction',
            },
        ],
        "$label priority_resolutions records rule-over-transaction suppression",
    );

    ok(exists $report->{resource_arbitration}, "$label exposes resource_arbitration");
    is(ref($report->{resource_arbitration}), 'ARRAY', "$label resource_arbitration is an array");
    is(scalar(@{$report->{resource_arbitration}}), 4, "$label exposes rule_slot and output_bundle resource users");

    for my $entry (@{$report->{priority_resolutions}}) {
        is_deeply(
            [sort keys %$entry],
            [sort qw(target winner winner_kind loser loser_kind)],
            "$label priority resolution entry is bounded",
        );
    }
    for my $entry (@{$report->{resource_arbitration}}) {
        is_deeply(
            [sort keys %$entry],
            [sort qw(resource kind arbiter user user_kind suppressed_by)],
            "$label resource arbitration entry is bounded",
        );
    }

    my $high = find_resource_entry($report, user => 'high');
    is($high->{resource}, 'shared_slot', "$label high grant names resource");
    is($high->{kind}, 'rule_slot', "$label high grant names resource kind");
    is($high->{arbiter}, 'priority', "$label high grant names arbiter");
    is($high->{user_kind}, 'rule', "$label high grant names user kind");
    is_deeply($high->{suppressed_by}, [], "$label highest user has no suppressors");

    my $low = find_resource_entry($report, user => 'low');
    is_deeply($low->{suppressed_by}, ['high'], "$label low user records higher suppressor");

    my $high_bundle = find_resource_entry($report, user => 'high_bundle');
    is($high_bundle->{resource}, 'response_outputs', "$label high output_bundle grant names resource");
    is($high_bundle->{kind}, 'output_bundle', "$label high output_bundle grant names resource kind");
    is($high_bundle->{arbiter}, 'priority', "$label high output_bundle grant names arbiter");
    is($high_bundle->{user_kind}, 'rule', "$label high output_bundle grant names user kind");
    is_deeply($high_bundle->{suppressed_by}, [], "$label highest output_bundle user has no suppressors");

    my $low_bundle = find_resource_entry($report, user => 'low_bundle');
    is_deeply($low_bundle->{suppressed_by}, ['high_bundle'], "$label low output_bundle user records higher suppressor");
}

sub find_resource_entry {
    my ($report, %want) = @_;

    ENTRY:
    for my $entry (@{$report->{resource_arbitration} || []}) {
        for my $key (sort keys %want) {
            next ENTRY unless defined($entry->{$key}) && $entry->{$key} eq $want{$key};
        }
        return $entry;
    }

    fail('found resource arbitration entry for ' . join(', ', map { "$_=$want{$_}" } sort keys %want));
    return {};
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

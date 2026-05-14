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
(actor rule_drive_unproven
  (clock clk)
  (interface
    (input start)
    (input ready)
    (output done)
    (output out))
  (drive (set_out val)
    (out val))
  (transaction main
    (on start)
    (drive set_out 0)
    (complete done))
  (rule force_out ready
    (out 1)))
ISF

subtest 'in-process report projects nonfatal conflict issues' => sub {
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'rule-drive-unproven.isf');
    my $report = decode_json(FSM::Scheduler::ISF->new()->report($actor));

    assert_compile_issue_projection($report, 'in-process schedule report');
};

subtest 'CLI schedule report projects nonfatal conflict issues' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $path = File::Spec->catfile($dir, 'rule_drive_unproven.isf');

    open my $fh, '>', $path or die "cannot write $path: $!";
    print {$fh} $source;
    close $fh or die "cannot close $path: $!";

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $path],
    );

    ok($success, 'CLI report command succeeds with nonfatal compile issues');
    is(join('', @{$stderr_buf || []}), '', 'CLI report command keeps stderr clean');

    my $report = decode_json(join('', @{$stdout_buf || []}));
    assert_compile_issue_projection($report, 'CLI schedule report');
};

done_testing();

sub assert_compile_issue_projection {
    my ($report, $label) = @_;

    ok(exists $report->{compile_issues}, "$label exposes compile_issues");
    is(ref($report->{compile_issues}), 'ARRAY', "$label compile_issues is an array");
    is(scalar(@{$report->{compile_issues}}), 1, "$label exposes one nonfatal compile issue");

    my $issue = $report->{compile_issues}[0];
    is_deeply(
        [sort keys %$issue],
        [sort qw(code severity target domain proof_status reason sources)],
        "$label compile issue uses the bounded public key set",
    );
    is($issue->{code}, 'isf_unproven_rule_drive_overlap', "$label issue code is stable");
    is($issue->{severity}, 'warning', "$label issue severity is warning");
    is($issue->{target}, 'out', "$label issue names the target");
    is($issue->{domain}, 'data', "$label issue names the conflict domain");
    is($issue->{proof_status}, 'not_doable', "$label issue records not_doable proof status");
    like($issue->{reason}, qr/proof.*not doable/i, "$label issue keeps human diagnostic reason");

    is(ref($issue->{sources}), 'ARRAY', "$label issue sources is an array");
    is(scalar(@{$issue->{sources}}), 2, "$label issue exposes both source summaries");

    for my $source_summary (@{$issue->{sources}}) {
        is_deeply(
            [sort keys %$source_summary],
            [sort qw(owner owner_kind source_kind target operator rhs domain)],
            "$label source summary uses the bounded public key set",
        );
        ok(!exists $source_summary->{activation}, "$label source summary omits activation internals");
        ok(!exists $source_summary->{assignment_index}, "$label source summary omits assignment index internals");
        ok(!exists $source_summary->{priority_suppressed_by}, "$label source summary omits priority internals");
    }

    my %source_by_owner = map { join(':', $_->{owner_kind}, $_->{owner}) => $_ } @{$issue->{sources}};
    is($source_by_owner{'rule:force_out'}{source_kind}, 'rule_action', "$label names the rule source kind");
    is($source_by_owner{'rule:force_out'}{operator}, '<-', "$label preserves the rule operator");
    is("$source_by_owner{'rule:force_out'}{rhs}", '1', "$label preserves the rule value");
    is($source_by_owner{'drive:set_out'}{source_kind}, 'drive_body', "$label names the drive source kind");
    is($source_by_owner{'drive:set_out'}{operator}, '<-', "$label preserves the drive operator");
    is("$source_by_owner{'drive:set_out'}{rhs}", 'set_out_val', "$label preserves the bounded drive RHS");
}

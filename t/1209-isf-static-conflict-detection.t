#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF::LoweringIR;

sub lower_ir {
    my ($source) = @_;
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'static-conflict.isf');
    return FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
}

subtest 'conflicting rule writes fail closed at compile time' => sub {
    my $ok = eval {
        lower_ir(<<'ISF');
(actor conflicting_rules
  (clock clk)
  (interface
    (input start)
    (input a)
    (input b)
    (output done)
    (output valid))
  (transaction main
    (on start)
    (complete done))
  (rule r0 a
    (valid 1))
  (rule r1 b
    (valid 0)))
ISF
        1;
    };
    my $diagnostic = $@;

    ok(!$ok, 'conflicting rule writes are rejected');
    like($diagnostic, qr/ISF conflict 'isf_conflicting_rule_writes' on target 'valid'/, 'diagnostic names conflict code and target');
    like($diagnostic, qr/rule 'r0'.*<- 1.*rule 'r1'.*<- 0/s, 'diagnostic names conflicting rule owners and values');
};

subtest 'same-value rule writes remain compatible' => sub {
    my $ir = lower_ir(<<'ISF');
(actor compatible_rules
  (clock clk)
  (interface
    (input start)
    (input a)
    (input b)
    (output done)
    (output valid))
  (transaction main
    (on start)
    (complete done))
  (rule r0 a
    (valid 1))
  (rule r1 b
    (valid 1)))
ISF

    is_deeply($ir->{conflict_issues}, [], 'same-value rule writes do not create conflict issues');
};

subtest 'rule/drive overlap is flagged when proof is not doable' => sub {
    my $ir = lower_ir(<<'ISF');
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

    my ($issue) = grep { ($_->{code} // '') eq 'isf_unproven_rule_drive_overlap' } @{$ir->{conflict_issues}};
    ok($issue, 'rule/drive overlap creates an unproven compile-time issue');
    is($issue->{severity}, 'warning', 'unproven rule/drive issue is a warning');
    is($issue->{proof_status}, 'not_doable', 'unproven rule/drive issue records proof status for a not doable case');
    is($issue->{target}, 'out', 'unproven rule/drive issue names target');
    is_deeply(
        [sort map { "$_->{owner_kind}:$_->{owner}:$_->{source_kind}" } @{$issue->{sources}}],
        ['drive:set_out:drive_body', 'rule:force_out:rule_action'],
        'unproven rule/drive issue preserves source owners',
    );
};

subtest 'mutually exclusive transaction state assignments remain accepted' => sub {
    my $ir = lower_ir(<<'ISF');
(actor state_mux_behavior
  (clock clk)
  (interface
    (input start)
    (input sel)
    (output done)
    (output out))
  (transaction main
    (on start)
    (switch sel
      (0 (update out 0))
      (1 (update out 1)))
    (complete done)))
ISF

    is_deeply($ir->{conflict_issues}, [], 'ordinary mutually exclusive state assignments are preserved');
};

done_testing();

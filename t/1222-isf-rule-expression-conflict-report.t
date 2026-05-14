#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::LoweringIR;

sub parse_actor {
    my ($source) = @_;
    return FSM::Adapter::ISF->new()->parse_source($source, 'rule-expression-conflict-report.isf');
}

sub lower_ir {
    my ($source) = @_;
    return FSM::Scheduler::ISF::LoweringIR->new()->build_module(parse_actor($source));
}

sub report_for {
    my ($source) = @_;
    return decode_json(FSM::Scheduler::ISF->new()->report(parse_actor($source)));
}

subtest 'same expression rule writes are reported as compatible fan-in' => sub {
    my $source = <<'ISF';
(actor expression_compatible_fanin
  (clock clk)
  (interface
    (input start)
    (input sel0)
    (input sel1)
    (input req_valid)
    (input error_seen)
    (output out)
    (output done))
  (transaction main
    (on start)
    (complete done))
  (rule r0 sel0
    (out (| req_valid error_seen)))
  (rule r1 sel1
    (out (| req_valid error_seen))))
ISF

    my $ir = lower_ir($source);
    is_deeply($ir->{conflict_issues}, [], 'same expression rule writes do not create conflicts');

    my $report = report_for($source);
    my @rule_blocks = grep { ($_->{kind} // '') eq 'rule' } @{$report->{dt_blocks}};
    is_deeply(
        [map { [$_->{name}, $_->{assignments}] } @rule_blocks],
        [['r0', 1], ['r1', 1]],
        'schedule report counts expression-valued rule assignments',
    );

    my ($group) = grep {
        ($_->{kind} // '') eq 'same_target_value'
            && ($_->{target} // '') eq 'out'
            && ($_->{rhs} // '') eq '(| req_valid error_seen)'
    } @{$report->{compatible_fanin_groups}};

    ok($group, 'schedule report exposes compatible same-expression fan-in');
    is($group->{operator}, '<-', 'compatible expression fan-in keeps the flopped operator');
    is_deeply(
        [sort map { "$_->{owner}:$_->{source_kind}:$_->{rhs}" } @{$group->{sources}}],
        [
            'r0:rule_action:(| req_valid error_seen)',
            'r1:rule_action:(| req_valid error_seen)',
        ],
        'compatible fan-in sources preserve expression RHS provenance',
    );
};

subtest 'different expression rule writes fail closed as data conflicts' => sub {
    my $ok = eval {
        lower_ir(<<'ISF');
(actor expression_conflict
  (clock clk)
  (interface
    (input start)
    (input sel0)
    (input sel1)
    (input req_valid)
    (input error_seen)
    (output out)
    (output done))
  (transaction main
    (on start)
    (complete done))
  (rule r0 sel0
    (out (| req_valid error_seen)))
  (rule r1 sel1
    (out (& req_valid error_seen))))
ISF
        1;
    };
    my $diagnostic = $@;

    ok(!$ok, 'different expression rule writes are rejected');
    like($diagnostic, qr/ISF conflict 'isf_conflicting_rule_writes' on target 'out'/, 'diagnostic names expression conflict');
    like($diagnostic, qr/rule 'r0'.*<- \(\| req_valid error_seen\).*rule 'r1'.*<- \(& req_valid error_seen\)/s, 'diagnostic preserves expression RHS values');
};

subtest 'priority resolves expression-valued rule conflicts' => sub {
    my $source = <<'ISF';
(actor expression_priority_resolution
  (clock clk)
  (interface
    (input start)
    (input high_req)
    (input low_req)
    (input req_valid)
    (input error_seen)
    (output out)
    (output done))
  (priority high over low)
  (transaction main
    (on start)
    (complete done))
  (rule high high_req
    (out (| req_valid error_seen)))
  (rule low low_req
    (out (& req_valid error_seen))))
ISF

    my $ir = lower_ir($source);
    is_deeply($ir->{conflict_issues}, [], 'priority-resolved expression writes have no conflict issues');

    my $report = report_for($source);
    my ($resolution) = grep {
        ($_->{target} // '') eq 'out'
            && ($_->{winner} // '') eq 'high'
            && ($_->{loser} // '') eq 'low'
    } @{$report->{priority_resolutions}};

    ok($resolution, 'schedule report exposes expression priority resolution');
    is($resolution->{winner_kind}, 'rule', 'winner kind remains rule');
    is($resolution->{loser_kind}, 'rule', 'loser kind remains rule');
};

done_testing();

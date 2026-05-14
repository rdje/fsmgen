#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::HDL::FlattenedDT;
use FSM::Pipeline::SourceFrontend;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::LoweringIR;

sub parse_actor {
    my ($source) = @_;
    return FSM::Adapter::ISF->new()->parse_source($source, 'rule-transaction-priority.isf');
}

sub lower_ir {
    my ($source) = @_;
    return FSM::Scheduler::ISF::LoweringIR->new()->build_module(parse_actor($source));
}

sub assert_lower_rejected {
    my ($source, $label, $diagnostic_re) = @_;
    my $ok = eval {
        lower_ir($source);
        1;
    };

    ok(!$ok, "$label is rejected");
    like($@, $diagnostic_re, "$label diagnostic is targeted");
}

subtest 'rule-over-transaction priority suppresses the transaction assignment' => sub {
    my $source = <<'ISF';
(actor rule_over_transaction_priority
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input force)
    (output done)
    (output out))
  (priority force_out over main)
  (transaction main
    (on start)
    (update out 0)
    (complete done))
  (rule force_out force
    (out 1)))
ISF

    my $ir = lower_ir($source);
    is_deeply($ir->{conflict_issues}, [], 'rule-over-transaction priority resolves the data conflict');

    my $transaction_out = find_record($ir, owner => 'main', owner_kind => 'transaction', target => 'out');
    is_deeply(
        $transaction_out->{priority_suppressed_by},
        ['force_out'],
        'transaction assignment records the suppressing rule',
    );

    my $fsm = FSM::Scheduler::ISF->new()->lower(parse_actor($source))->{files}{'rule_over_transaction_priority.fsm'};
    like(
        $fsm,
        qr/\(main_update_\d+\s+\(<- \(out> 0\) <\(! force\)\)/s,
        'scheduled .fsm guards the transaction assignment with the inverse rule condition',
    );
    like(
        $fsm,
        qr/\(-force_out\s+<force\s+\(<- \(out> 1\)\)\s+\)/s,
        'scheduled .fsm keeps the winning rule action active under the rule DTE',
    );
    assert_fsm_reaches_hdl($fsm, 'rule_over_transaction_priority');
};

subtest 'unordered rule/transaction conflict fails closed' => sub {
    assert_lower_rejected(<<'ISF', 'unordered rule/transaction data conflict', qr/isf_conflicting_rule_transaction_writes/);
(actor unordered_rule_transaction_priority
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input force)
    (output done)
    (output out))
  (transaction main
    (on start)
    (update out 0)
    (complete done))
  (rule force_out force
    (out 1)))
ISF
};

subtest 'rule/transaction priority cycles fail closed' => sub {
    assert_lower_rejected(<<'ISF', 'cyclic rule/transaction priority', qr/isf_priority_cycle_conflict/);
(actor cyclic_rule_transaction_priority
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input force)
    (output done)
    (output out))
  (priority force_out over main)
  (priority main over force_out)
  (transaction main
    (on start)
    (update out 0)
    (complete done))
  (rule force_out force
    (out 1)))
ISF
};

subtest 'transaction-over-rule priority fails until state-active rule guards ship' => sub {
    assert_lower_rejected(<<'ISF', 'transaction-over-rule priority', qr/isf_priority_transaction_winner_unsupported.*state-active guards/s);
(actor transaction_over_rule_priority
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input force)
    (output done)
    (output out))
  (priority main over force_out)
  (transaction main
    (on start)
    (update out 0)
    (complete done))
  (rule force_out force
    (out 1)))
ISF
};

done_testing();

sub find_record {
    my ($ir, %want) = @_;

    RECORD:
    for my $record (@{$ir->{assignment_provenance} || []}) {
        for my $key (sort keys %want) {
            next RECORD unless defined($record->{$key}) && $record->{$key} eq $want{$key};
        }
        return $record;
    }

    fail('found provenance record for ' . join(', ', map { "$_=$want{$_}" } sort keys %want));
    return {};
}

sub assert_fsm_reaches_hdl {
    my ($fsm, $module_name) = @_;
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, "$module_name.fsm");
    write_file($fsm_path, $fsm);

    my $raw_ast = FSM::Pipeline::SourceFrontend->parse_fsm_file(
        fsm_file    => $fsm_path,
        debug_level => 0,
    );
    my $fsm_module = FSM::Pipeline::SourceFrontend->create_fsm_module(
        raw_ast     => $raw_ast,
        debug_level => 0,
    );
    ok($fsm_module, 'rule/transaction priority scheduled .fsm parses through the normal .fsm frontend');

    my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($fsm_module);
    like($hdl, qr/\bmodule\s+\Q$module_name\E\b/, 'rule/transaction priority scheduled .fsm reaches HDL generation');
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

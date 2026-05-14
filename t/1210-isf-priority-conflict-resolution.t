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
    return FSM::Adapter::ISF->new()->parse_source($source, 'priority-conflict-resolution.isf');
}

sub lower_ir {
    my ($source) = @_;
    return FSM::Scheduler::ISF::LoweringIR->new()->build_module(parse_actor($source));
}

subtest 'rule-local priority suppresses the lower-priority rule assignment' => sub {
    my $source = <<'ISF';
(actor local_priority_conflict
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input a)
    (input b)
    (output done)
    (output valid))
  (transaction main
    (on start)
    (complete done))
  (rule high a
    (priority over low)
    (valid 1))
  (rule low b
    (valid 0)))
ISF

    my $ir = lower_ir($source);
    is_deeply($ir->{conflict_issues}, [], 'priority-resolved rule conflict has no conflict issues');

    my $low = find_record($ir, owner => 'low', target => 'valid');
    is_deeply($low->{priority_suppressed_by}, ['high'], 'low-priority rule records the suppressing rule');

    my $fsm = FSM::Scheduler::ISF->new()->lower(parse_actor($source))->{files}{'local_priority_conflict.fsm'};
    like(
        $fsm,
        qr/\(-low\s+<b\s+\(<- \(valid> 0\) <\(! a\)\)\s+\)/s,
        'scheduled .fsm gates the lower-priority assignment with the inverse high-priority rule condition',
    );
    assert_fsm_reaches_hdl($fsm, 'local_priority_conflict');
};

subtest 'actor-level priority resolves a same-target rule conflict' => sub {
    my $ir = lower_ir(<<'ISF');
(actor actor_priority_conflict
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input a)
    (input b)
    (output done)
    (output valid))
  (priority high over low)
  (transaction main
    (on start)
    (complete done))
  (rule high a
    (valid 1))
  (rule low b
    (valid 0)))
ISF

    is_deeply($ir->{conflict_issues}, [], 'actor-level priority resolves the rule conflict');
    my $low = find_record($ir, owner => 'low', target => 'valid');
    is_deeply($low->{priority_suppressed_by}, ['high'], 'actor-level priority suppresses the lower-priority record');
};

subtest 'priority cycles fail closed' => sub {
    my $ok = eval {
        lower_ir(<<'ISF');
(actor priority_cycle_conflict
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input a)
    (input b)
    (output done)
    (output valid))
  (priority high over low)
  (priority low over high)
  (transaction main
    (on start)
    (complete done))
  (rule high a
    (valid 1))
  (rule low b
    (valid 0)))
ISF
        1;
    };
    my $diagnostic = $@;

    ok(!$ok, 'priority cycle is rejected');
    like($diagnostic, qr/ISF conflict 'isf_priority_cycle_conflict' on target 'valid'/, 'cycle diagnostic names the target');
    like($diagnostic, qr/priority cycle leaves no unique winner/, 'cycle diagnostic explains the priority failure');
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
    ok($fsm_module, 'priority-gated scheduled .fsm parses through the normal .fsm frontend');

    my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($fsm_module);
    like($hdl, qr/\bmodule\s+\Q$module_name\E\b/, 'priority-gated scheduled .fsm reaches HDL generation');
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

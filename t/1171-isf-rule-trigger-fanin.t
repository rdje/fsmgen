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
my $result = FSM::Scheduler::ISF->new()->lower($actor);
my $fsm = $result->{files}{'rule_trigger_fanin.fsm'};

like($fsm, qr/\(r0_work 1\)/, 'rule r0 trigger source is declared as one-bit storage');
like($fsm, qr/\(r1_work 1\)/, 'rule r1 trigger source is declared as one-bit storage');
like($fsm, qr/\(work_start 1\)/, 'transaction start fan-in target is declared as one-bit storage');
like(
    $fsm,
    qr/\(-r0\s+<a\s+\(<1 \(r0_work 1\)\)\s+\)/s,
    'first rule pulses its own trigger source under a guarded-DT DTE',
);
like(
    $fsm,
    qr/\(-r1\s+<b\s+\(<1 \(r1_work 1\)\)\s+\)/s,
    'second rule pulses its own trigger source under a guarded-DT DTE',
);
like(
    $fsm,
    qr/\(-work_trigger_fanin\s+\(= \(work_start \(\| r0_work r1_work\)\)\)\s+\)/s,
    'generated fan-in DT ORs rule trigger sources into the transaction start',
);
unlike(
    $fsm,
    qr/\(<1 \(work_start 1\)/,
    'rules no longer assign the transaction start signal directly',
);

my $tempdir = tempdir(CLEANUP => 1);
my $fsm_path = File::Spec->catfile($tempdir, 'rule_trigger_fanin.fsm');
write_file($fsm_path, $fsm);

my $raw_ast = FSM::Pipeline::SourceFrontend->parse_fsm_file(
    fsm_file => $fsm_path,
    debug_level => 0,
);
my $fsm_module = FSM::Pipeline::SourceFrontend->create_fsm_module(
    raw_ast => $raw_ast,
    debug_level => 0,
);
ok($fsm_module, 'rule trigger fan-in .fsm parses through the normal .fsm frontend');

my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($fsm_module);
like($hdl, qr/\bmodule\s+rule_trigger_fanin\b/, 'rule trigger fan-in reaches HDL generation');

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

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
(actor rule_guard_factoring
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input ready)
    (output valid)
    (output done))
  (transaction main_transfer
    (on main_transfer_start)
    (complete done))
  (rule always_ready
    (when ready)
    (valid 1)
    (trigger main_transfer)))
ISF

my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'rule-guard-factoring.isf');
my $result = FSM::Scheduler::ISF->new()->lower($actor);
my $fsm = $result->{files}{'rule_guard_factoring.fsm'};

like(
    $fsm,
    qr/\(-always_ready\s+\(<ready\s+\(<- \(valid 1\)\)\s+\(<1 \(main_transfer_start 1\)\)\s+\)\s+\)/s,
    'rule DT emits one factored guard block with delayed-pulse trigger assignment',
);
unlike(
    $fsm,
    qr/\(<- \(valid 1\) <ready\)/,
    'rule DT no longer repeats the rule guard on each assignment',
);
unlike(
    $fsm,
    qr/\(<1 \(main_transfer_start 1\) <ready\)/,
    'rule trigger pulse also lives under the factored guard block',
);
unlike(
    $fsm,
    qr/\(<- \(main_transfer_start 1\)\)/,
    'rule trigger no longer lowers as a sticky flopped assignment',
);

my $tempdir = tempdir(CLEANUP => 1);
my $fsm_path = File::Spec->catfile($tempdir, 'rule_guard_factoring.fsm');
write_file($fsm_path, $fsm);

my $raw_ast = FSM::Pipeline::SourceFrontend->parse_fsm_file(
    fsm_file => $fsm_path,
    debug_level => 0,
);
my $fsm_module = FSM::Pipeline::SourceFrontend->create_fsm_module(
    raw_ast => $raw_ast,
    debug_level => 0,
);
ok($fsm_module, 'factored rule guard .fsm parses through the normal .fsm frontend');

my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($fsm_module);
like($hdl, qr/\bmodule\s+rule_guard_factoring\b/, 'factored rule guard .fsm reaches HDL generation');

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

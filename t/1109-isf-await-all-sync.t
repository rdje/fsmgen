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

sub state_block {
    my ($fsm, $state_name) = @_;
    my ($block) = ($fsm =~ /(  \(\Q$state_name\E\b.*?\n  \))/s);
    return $block // '';
}

subtest 'await_all emits one compound transition guard for every collected spawned done signal' => sub {
    my $source = <<'ISF';
(actor await_all_parent
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (output done)
    (output out))
  (drive (out val) (out val))
  (transaction worker
    (on start)
    (drive out 1)
    (complete done))
  (transaction parent
    (on start)
    (spawn worker as w0)
    (spawn worker as w1)
    (spawn worker as w2)
    (await_all done)
    (complete done)))
ISF

    my $actor  = FSM::Adapter::ISF->new()->parse_source($source, 'await-all-inline.isf');
    my $result = FSM::Scheduler::ISF->new()->lower($actor);
    my $fsm    = $result->{files}{'await_all_parent.fsm'};
    my $block  = state_block($fsm, 'parent_await_all_4');

    like($block, qr/\(-> parent_done_5 <\(& w0_done w1_done w2_done\)\)/,
        'await_all emits one transition guarded by the AND of all collected done ports');
    unlike($block, qr/\(<w2_done\s+\(<w1_done\s+\(<w0_done/s,
        'await_all no longer nests done-port guards before the transition');
    for my $done_port (qw(w0_done w1_done w2_done)) {
        like($block, qr/\b$done_port\b/, "await_all includes $done_port");
    }

    my @targets = ($block =~ /\(-> parent_done_5\b/g);
    is(scalar(@targets), 1, 'await_all advances through one all-guards transition');

    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'await_all_parent.fsm');
    write_file($fsm_path, $fsm);
    my $raw_ast = FSM::Pipeline::SourceFrontend->parse_fsm_file(
        fsm_file => $fsm_path,
        debug_level => 0,
    );
    my $fsm_module = FSM::Pipeline::SourceFrontend->create_fsm_module(
        raw_ast => $raw_ast,
        debug_level => 0,
    );
    ok($fsm_module, 'await_all compound transition guard parses through the normal .fsm frontend');
    my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($fsm_module);
    like($hdl, qr/\bw0_done\s*&\s*w1_done\s*&\s*w2_done\b/, 'await_all compound guard reaches HDL as a logical AND');
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

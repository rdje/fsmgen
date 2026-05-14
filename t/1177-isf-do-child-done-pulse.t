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
(actor do_child_done_pulse
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input payload (width 8))
    (output done)
    (output out (width 8)))
  (transaction child
    (on start)
    (update out payload)
    (complete done))
  (transaction parent
    (on start)
    (do child)
    (do child)
    (complete done)))
ISF

my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'do-child-done-pulse.isf');
my $result = FSM::Scheduler::ISF->new()->lower($actor);
my $fsm = $result->{files}{'do_child_done_pulse.fsm'};

my $child_done = state_block($fsm, 'child_done_2');
like($child_done, qr/\(<1 \(child_done 1\)\)/, 'blocking do child completion handoff uses a delayed pulse');
unlike($child_done, qr/\(<- \(child_done 1\)\)/, 'blocking do child completion handoff is not sticky');
like($child_done, qr/\(<1 \(done> 1\)\)/, 'public child completion remains a delayed pulse');

my $first_parent_do = state_block($fsm, 'parent_do_1');
my $second_parent_do = state_block($fsm, 'parent_do_2');
like($first_parent_do, qr/<child_done\s+\(-> parent_do_2\)/, 'first parent do waits for the child completion pulse');
like($second_parent_do, qr/<child_done\s+\(-> parent_done_3\)/, 'second parent do waits for a fresh child completion pulse');

my $tempdir = tempdir(CLEANUP => 1);
my $fsm_path = File::Spec->catfile($tempdir, 'do_child_done_pulse.fsm');
write_file($fsm_path, $fsm);

my $raw_ast = FSM::Pipeline::SourceFrontend->parse_fsm_file(
    fsm_file => $fsm_path,
    debug_level => 0,
);
my $fsm_module = FSM::Pipeline::SourceFrontend->create_fsm_module(
    raw_ast => $raw_ast,
    debug_level => 0,
);
ok($fsm_module, 'scheduled do-child pulse .fsm parses through the normal .fsm frontend');

my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($fsm_module);
like($hdl, qr/\bmodule\s+do_child_done_pulse\b/, 'scheduled do-child pulse .fsm reaches HDL generation');

done_testing();

sub state_block {
    my ($text, $state_name) = @_;
    my ($block) = ($text =~ /(  \(\Q$state_name\E\b.*?\n  \))/s);
    return $block // '';
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

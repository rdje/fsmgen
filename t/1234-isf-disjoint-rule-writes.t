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

subtest 'provably disjoint rule guards may drive one storage target' => sub {
    my $source = <<'ISF';
(actor disjoint_fifo_rule_writes
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input push)
    (input pop)
    (input full)
    (input empty)
    (input wdata (width 8))
    (output write_fire)
    (output read_fire)
    (output idle_fire))
  (storage
    (register wr_ptr (width 2))
    (register rd_ptr (width 2))
    (register occupancy (width 3))
    (bank data (width 8) (depth 4)))
  (rule idle_case (& (! push) (! pop))
    (idle_fire 1)
    (occupancy occupancy))
  (rule push_only (& push (! pop) (! full))
    (write_fire 1)
    (wr_ptr (+ wr_ptr 1))
    (occupancy (+ occupancy 1)))
  (rule pop_only (& pop (! push) (! empty))
    (read_fire 1)
    (rd_ptr (+ rd_ptr 1))
    (occupancy (- occupancy 1)))
  (rule push_pop (& push pop (! empty))
    (write_fire 1)
    (read_fire 1)
    (wr_ptr (+ wr_ptr 1))
    (rd_ptr (+ rd_ptr 1))
    (occupancy occupancy)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'disjoint-fifo-rule-writes.isf');
    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    is_deeply($ir->{conflict_issues}, [], 'disjoint rule writes produce no conflict issues');

    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'disjoint_fifo_rule_writes.fsm'};
    like(
        $fsm,
        qr/\(-push_only\s+<\(& push \(! pop\) \(! full\)\)[\s\S]*\(<- \(occupancy \(\+ occupancy 1\)\)\)/,
        'push-only rule emits the increment under the expression DTE',
    );
    like(
        $fsm,
        qr/\(-pop_only\s+<\(& pop \(! push\) \(! empty\)\)[\s\S]*\(<- \(occupancy \(- occupancy 1\)\)\)/,
        'pop-only rule emits the decrement under the expression DTE',
    );
    like(
        $fsm,
        qr/\(-push_pop\s+<\(& push pop \(! empty\)\)[\s\S]*\(<- \(occupancy occupancy\)\)/,
        'simultaneous push-pop rule may preserve occupancy under a disjoint expression DTE',
    );
    like($fsm, qr/\(data_0\s+8\)/, '4-entry FIFO fixture emits data_0 storage');
    like($fsm, qr/\(data_3\s+8\)/, '4-entry FIFO fixture emits data_3 storage');

    assert_fsm_reaches_hdl($fsm, 'disjoint_fifo_rule_writes');
};

subtest 'overlapping expression-guard rule writes still fail closed' => sub {
    my $ok = eval {
        my $actor = FSM::Adapter::ISF->new()->parse_source(<<'ISF', 'overlap-rule-writes.isf');
(actor overlapping_rule_writes
  (clock clk)
  (interface
    (input push)
    (input ready)
    (input full)
    (output valid))
  (rule r0 (& push ready)
    (valid 1))
  (rule r1 (& push (! full))
    (valid 0)))
ISF
        FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
        1;
    };
    my $diagnostic = $@;

    ok(!$ok, 'overlapping expression-guard rule writes are rejected');
    like(
        $diagnostic,
        qr/ISF conflict 'isf_conflicting_rule_writes' on target 'valid'/,
        'overlapping diagnostic keeps the existing conflict code',
    );
};

done_testing();

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
    ok($fsm_module, 'disjoint-rule scheduled .fsm parses through the normal .fsm frontend');

    my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($fsm_module);
    like($hdl, qr/\bmodule\s+\Q$module_name\E\b/, 'disjoint-rule scheduled .fsm reaches HDL generation');
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

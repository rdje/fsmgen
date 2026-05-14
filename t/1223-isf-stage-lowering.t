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

sub lower_source {
    my ($source) = @_;
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'stage-lowering.isf');
    return FSM::Scheduler::ISF->new()->lower($actor);
}

sub lower_rejected {
    my ($source) = @_;
    my $ok = eval {
        lower_source($source);
        1;
    };
    return ($ok, $@);
}

subtest 'top-level transaction stage lowers to ready-gated valid state' => sub {
    my $lowered = lower_source(<<'ISF');
(actor stage_lowering
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input ready)
    (output valid)
    (output done))
  (transaction main
    (on start)
    (stage accept (input ready) (output valid))
    (complete done)))
ISF

    my $fsm = $lowered->{files}{'stage_lowering.fsm'};
    like(
        $fsm,
        qr/\(main_stage_1\n\s+\(= \(valid> 1\)\)\n\s+\(<ready\n\s+\(-> main_done_2\)\n\s+\)\n\s+\)/,
        'stage state drives valid combinationally and advances only under ready',
    );

    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'stage_lowering.fsm');
    write_file($fsm_path, $fsm);

    my $raw_ast = FSM::Pipeline::SourceFrontend->parse_fsm_file(
        fsm_file => $fsm_path,
        debug_level => 0,
    );
    my $fsm_module = FSM::Pipeline::SourceFrontend->create_fsm_module(
        raw_ast => $raw_ast,
        debug_level => 0,
    );
    ok($fsm_module, 'scheduled .fsm with a stage state parses through the normal .fsm frontend');

    my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($fsm_module);
    like($hdl, qr/\bmodule\s+stage_lowering\b/, 'stage lowering reaches SystemVerilog generation');
};

subtest 'pending samples materialize before a stalled stage' => sub {
    my $lowered = lower_source(<<'ISF');
(actor stage_sample_boundary
  (clock clk)
  (interface
    (input start)
    (input ready)
    (input req)
    (output valid)
    (output done))
  (transaction main
    (on start)
    (sample req as captured)
    (stage accept (input ready) (output valid))
    (complete done)))
ISF

    my $fsm = $lowered->{files}{'stage_sample_boundary.fsm'};
    like(
        $fsm,
        qr/\(main_sample_1\n\s+\(<= \(captured req\)\)\n\s+\(-> main_stage_2\)\n\s+\)/,
        'pending sample is emitted as a separate state before the stage',
    );
    like(
        $fsm,
        qr/\(main_stage_2\n\s+\(= \(valid> 1\)\)\n\s+\(<ready\n\s+\(-> main_done_3\)\n\s+\)\n\s+\)/,
        'stage follows the sample state and keeps the ready-gated transition',
    );
};

subtest 'unsupported stage positions and endpoint bindings fail closed' => sub {
    my ($ok_nested, $nested_diag) = lower_rejected(<<'ISF');
(actor nested_stage
  (clock clk)
  (interface
    (input start)
    (input ready)
    (output valid)
    (output done))
  (transaction main
    (on start)
    (when ready
      (stage accept (input ready) (output valid)))
    (complete done)))
ISF

    ok(!$ok_nested, 'nested stage is rejected');
    like(
        $nested_diag,
        qr/\ATransaction 'main': pipeline '\(stage \.\.\.\)' clauses are supported only as top-level transaction clauses/,
        'nested stage diagnostic is targeted',
    );

    my ($ok_ready, $ready_diag) = lower_rejected(<<'ISF');
(actor bad_stage_ready
  (clock clk)
  (interface
    (input start)
    (output ready)
    (output valid)
    (output done))
  (transaction main
    (on start)
    (stage accept (input ready) (output valid))
    (complete done)))
ISF

    ok(!$ok_ready, 'stage ready endpoint must be an actor input');
    like(
        $ready_diag,
        qr/\ATransaction 'main': stage 'accept' input 'ready' is not an actor input/,
        'ready endpoint diagnostic is targeted',
    );

    my ($ok_valid, $valid_diag) = lower_rejected(<<'ISF');
(actor bad_stage_valid
  (clock clk)
  (interface
    (input start)
    (input ready)
    (input valid)
    (output done))
  (transaction main
    (on start)
    (stage accept (input ready) (output valid))
    (complete done)))
ISF

    ok(!$ok_valid, 'stage valid endpoint must be an actor output');
    like(
        $valid_diag,
        qr/\ATransaction 'main': stage 'accept' output 'valid' is not an actor output/,
        'valid endpoint diagnostic is targeted',
    );
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

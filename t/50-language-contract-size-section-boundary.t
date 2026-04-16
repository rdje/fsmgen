#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw/ tempdir /;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::Pipeline::HDLGenerator;
use FSM::HDL::FlattenedDT;

my $tempdir = tempdir(CLEANUP => 1);

subtest 'empty +size remains a supported legacy no-op' => sub {
    my $fsm_module = parse_success(<<'FSM');
(?fsm:empty_size_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size)
  (+size
    (OUT 1)
    (IN 1)
  )
  (idle
    (OUT <= IN)
  )
)
FSM

    ok($fsm_module, 'FSM with empty +size parses successfully');
    my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($fsm_module);
    like($hdl, qr/module\s+empty_size_contract\b/s, 'empty +size fixture still generates HDL');
};

subtest 'malformed +size payload entries are rejected explicitly' => sub {
    my $error = parse_failure(<<'FSM');
(?fsm:bad_size_payload
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size BROKEN)
  (idle
    (OUT <= 1)
  )
)
FSM

    like($error, qr/Malformed '\+size' entry/, 'malformed +size payload gets a targeted entry diagnostic');
};

subtest 'malformed +size entries are rejected explicitly' => sub {
    my $shape_error = parse_failure(<<'FSM');
(?fsm:bad_size_entry_shape
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (A)
  )
  (idle
    (OUT <= 1)
  )
)
FSM

    like($shape_error, qr/Malformed '\+size' entry/, 'short +size entry shape gets a targeted diagnostic');

    my $width_error = parse_failure(<<'FSM');
(?fsm:bad_size_entry_width
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (A 0)
  )
  (idle
    (OUT <= 1)
  )
)
FSM

    like($width_error, qr/Malformed '\+size' entry for signal 'A'/, 'non-positive width gets a targeted diagnostic');
};

subtest '+size width entries accept constant-expression values' => sub {
    my ($fsm_module, $adapter) = parse_success_with_adapter(<<'FSM');
(?fsm:size_expression_contract
  (+system
    (clock clk)
    (sreset reset)
  )
  (+constants
    (BASE_W 2)
    (INC_W 1)
    (WIDTHS (4 8))
  )
  (+enums
    (width_e
      (FLAG 1)
    )
  )
  (+params
    (PARAM_W (+ BASE_W INC_W))
    (PARAM_DEC_W (+ 0d10 -2))
  )
  (+size
    (A (+ BASE_W INC_W))
    (B (+ PARAM_W width_e.FLAG))
    (C WIDTHS[1])
    (D 0x4)
    (E (and 7 3))
    (F PARAM_DEC_W)
    (G (+ 8'sd9 8'sd-1))
    (H (+ 'h8 0d1))
  )
  (idle
    (A <= 1)
    (B <= A)
    (C <= B)
    (D <= C)
    (E <= A)
    (F <= C)
    (G <= F)
    (H <= G)
  )
)
FSM

    ok($fsm_module, 'FSM with expression-backed +size widths parses successfully');
    is($adapter->{signal_manager}->get_signal('A')->width, 3, '+size resolves nested constant arithmetic');
    is($adapter->{signal_manager}->get_signal('B')->width, 4, '+size resolves params and enum leaves');
    is($adapter->{signal_manager}->get_signal('C')->width, 8, '+size resolves aggregate scalar leaves');
    is($adapter->{signal_manager}->get_signal('D')->width, 4, '+size resolves unsized hex literal widths');
    is($adapter->{signal_manager}->get_signal('E')->width, 3, '+size resolves Lisp-ish bitwise aliases');
    is($adapter->{signal_manager}->get_signal('F')->width, 8, '+size resolves 0d literals and negative terms through scalar params');
    is($adapter->{signal_manager}->get_signal('G')->width, 8, '+size resolves direct signed based negative terms');
    is($adapter->{signal_manager}->get_signal('H')->width, 9, '+size resolves unsized SV and prefixed decimal literals directly');
};

subtest 'pipeline and CLI do not emit HDL for malformed +size sections' => sub {
    my $fsm_path = write_fsm('bad_size_cli.fsm', <<'FSM');
(?fsm:bad_size_cli
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size BROKEN)
  (idle
    (OUT <= 1)
  )
)
FSM

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug => 0,
    );
    my $pipeline_error = eval {
        $pipeline->generate_hdl_from_file($fsm_path);
        undef;
    };
    $pipeline_error = $@ if !$pipeline_error;
    ok($pipeline_error, 'pipeline rejects malformed +size payload');
    like($pipeline_error, qr/Malformed '\+size' entry/, 'pipeline surfaces the explicit +size boundary');

    my $out_path = File::Spec->catfile($tempdir, 'bad_size_cli.sv');
    my $success = system($^X, '-I', 'perl', 'bin/fsmgen', '--output', $out_path, $fsm_path) == 0;
    ok(!$success, 'CLI rejects malformed +size payload');
    ok(!-e $out_path, 'CLI does not emit output for malformed +size payload');
};

done_testing();

sub parse_success {
    my ($fsm_text) = @_;
    my $fsm_path = write_fsm('parse_success_' . int(rand(1_000_000)) . '.fsm', $fsm_text);
    my $raw_ast = Lispish::multi($fsm_path);
    my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);
    return $adapter->parse_fsm($raw_ast);
}

sub parse_success_with_adapter {
    my ($fsm_text) = @_;
    my $fsm_path = write_fsm('parse_success_' . int(rand(1_000_000)) . '.fsm', $fsm_text);
    my $raw_ast = Lispish::multi($fsm_path);
    my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);
    my $module = $adapter->parse_fsm($raw_ast);
    return ($module, $adapter);
}

sub parse_failure {
    my ($fsm_text) = @_;
    my $fsm_path = write_fsm('parse_failure_' . int(rand(1_000_000)) . '.fsm', $fsm_text);
    my $raw_ast = Lispish::multi($fsm_path);
    my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);

    my $error = eval {
        $adapter->parse_fsm($raw_ast);
        undef;
    };
    $error = $@ if !$error;
    ok($error, "parse fails for generated fixture");
    return $error;
}

sub write_fsm {
    my ($filename, $content) = @_;
    my $path = File::Spec->catfile($tempdir, $filename);
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
    return $path;
}

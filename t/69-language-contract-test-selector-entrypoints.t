#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Cmd qw(run);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

my $tempdir = tempdir(CLEANUP => 1);

subtest 'pipeline and CLI do not emit HDL for bare symbolic test selectors' => sub {
    my $fsm_path = write_fsm('bare_symbolic_test_selector.fsm', <<'FSM');
(?fsm:bad_test_selector_symbol
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (MODE 2)
    (A 1)
  )
  (s0
    (?MODE
      (BUSY
        (A = 1)
      )
    )
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
    ok($pipeline_error, 'pipeline rejects bare symbolic test selector');
    like($pipeline_error, qr/Malformed test selector 'BUSY'/, 'pipeline surfaces the explicit bare-symbolic-selector boundary');

    my $out_path = File::Spec->catfile($tempdir, 'bare_symbolic_test_selector.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $out_path, '--quiet', $fsm_path],
    );

    ok(!$success, 'CLI rejects bare symbolic test selector');
    ok(!-e $out_path, 'CLI does not emit output for bare symbolic test selector');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/Malformed test selector 'BUSY'/, 'CLI surfaces the explicit bare-symbolic-selector boundary');
};

subtest 'pipeline and CLI do not emit HDL for bare numeric test selectors' => sub {
    my $fsm_path = write_fsm('bare_numeric_test_selector.fsm', <<'FSM');
(?fsm:bad_test_selector_numeric
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (MODE 2)
    (A 1)
  )
  (s0
    (?MODE
      (0
        (A = 1)
      )
    )
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
    ok($pipeline_error, 'pipeline rejects bare numeric test selector');
    like($pipeline_error, qr/Malformed test selector '0'/, 'pipeline surfaces the explicit bare-numeric-selector boundary');

    my $out_path = File::Spec->catfile($tempdir, 'bare_numeric_test_selector.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $out_path, '--quiet', $fsm_path],
    );

    ok(!$success, 'CLI rejects bare numeric test selector');
    ok(!-e $out_path, 'CLI does not emit output for bare numeric test selector');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/Malformed test selector '0'/, 'CLI surfaces the explicit bare-numeric-selector boundary');
};

done_testing();

sub write_fsm {
    my ($filename, $content) = @_;
    my $path = File::Spec->catfile($tempdir, $filename);
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
    return $path;
}

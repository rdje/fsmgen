#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Cmd qw(run);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::Pipeline::HDLGenerator;

my $tempdir = tempdir(CLEANUP => 1);

subtest 'duplicate +system clock entries are rejected explicitly' => sub {
    my $error = parse_failure(<<'FSM');
(?fsm:duplicate_system_clock
  (+system
    (clock clk)
    (clock clk)
    (sreset rstn)
  )
  (-dt
    (A = 1)
  )
)
FSM

    like($error, qr/Duplicate '\+system' entry 'clock'/, 'duplicate clock entry gets a targeted diagnostic');
};

subtest 'duplicate +system reset declarations are rejected explicitly' => sub {
    my $same_reset_error = parse_failure(<<'FSM');
(?fsm:duplicate_same_reset
  (+system
    (clock clk)
    (sreset rstn)
    (sreset rstn)
  )
  (-dt
    (A = 1)
  )
)
FSM

    like($same_reset_error, qr/Duplicate '\+system' entry 'sreset'/, 'duplicate same-keyword reset entry gets a targeted diagnostic');

    my $mixed_reset_error = parse_failure(<<'FSM');
(?fsm:duplicate_mixed_reset
  (+system
    (clock clk)
    (sreset rstn)
    (asreset rstn)
  )
  (-dt
    (A = 1)
  )
)
FSM

    like($mixed_reset_error, qr/Duplicate '\+system' reset declaration 'asreset'/, 'mixed reset declarations get a targeted reset-duplicate diagnostic');
};

subtest 'pipeline and CLI do not emit HDL for duplicate +system declarations' => sub {
    my $clock_fsm_path = write_fsm('duplicate_system_clock_cli.fsm', <<'FSM');
(?fsm:duplicate_system_clock_cli
  (+system
    (clock clk)
    (clock clk)
    (sreset rstn)
  )
  (-dt
    (A = 1)
  )
)
FSM

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug => 0,
    );
    my $clock_pipeline_error = eval {
        $pipeline->generate_hdl_from_file($clock_fsm_path);
        undef;
    };
    $clock_pipeline_error = $@ if !$clock_pipeline_error;
    ok($clock_pipeline_error, 'pipeline rejects duplicate +system clock entry');
    like($clock_pipeline_error, qr/Duplicate '\+system' entry 'clock'/, 'pipeline surfaces the duplicate clock-entry boundary');

    my $clock_out_path = File::Spec->catfile($tempdir, 'duplicate_system_clock_cli.sv');
    my ($clock_success, $clock_error_message, $clock_full_buf, $clock_stdout_buf, $clock_stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $clock_out_path, '--quiet', $clock_fsm_path],
    );

    ok(!$clock_success, 'CLI rejects duplicate +system clock entry');
    ok(!-e $clock_out_path, 'CLI does not emit output for duplicate +system clock entry');

    my $clock_combined_output = join(
        '',
        @{ $clock_stdout_buf || [] },
        @{ $clock_stderr_buf || [] },
        ($clock_error_message || ''),
    );

    like($clock_combined_output, qr/Duplicate '\+system' entry 'clock'/, 'CLI surfaces the duplicate clock-entry boundary');

    my $reset_fsm_path = write_fsm('duplicate_system_reset_cli.fsm', <<'FSM');
(?fsm:duplicate_system_reset_cli
  (+system
    (clock clk)
    (sreset rstn)
    (asreset rstn)
  )
  (-dt
    (A = 1)
  )
)
FSM

    my $reset_pipeline_error = eval {
        $pipeline->generate_hdl_from_file($reset_fsm_path);
        undef;
    };
    $reset_pipeline_error = $@ if !$reset_pipeline_error;
    ok($reset_pipeline_error, 'pipeline rejects duplicate +system reset declaration');
    like($reset_pipeline_error, qr/Duplicate '\+system' reset declaration 'asreset'/, 'pipeline surfaces the duplicate reset-declaration boundary');

    my $reset_out_path = File::Spec->catfile($tempdir, 'duplicate_system_reset_cli.sv');
    my ($reset_success, $reset_error_message, $reset_full_buf, $reset_stdout_buf, $reset_stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $reset_out_path, '--quiet', $reset_fsm_path],
    );

    ok(!$reset_success, 'CLI rejects duplicate +system reset declaration');
    ok(!-e $reset_out_path, 'CLI does not emit output for duplicate +system reset declaration');

    my $reset_combined_output = join(
        '',
        @{ $reset_stdout_buf || [] },
        @{ $reset_stderr_buf || [] },
        ($reset_error_message || ''),
    );

    like($reset_combined_output, qr/Duplicate '\+system' reset declaration 'asreset'/, 'CLI surfaces the duplicate reset-declaration boundary');
};

done_testing();

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
    ok($error, 'parse failed as expected');
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

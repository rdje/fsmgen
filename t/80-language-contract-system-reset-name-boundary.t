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

subtest 'non-conventional +system reset names are rejected explicitly' => sub {
    my $sync_error = parse_failure(<<'FSM');
(?fsm:bad_sync_reset_name
  (+system
    (clock clk)
    (sreset reset_n)
  )
  (-dt
    (A = 1)
  )
)
FSM

    like($sync_error, qr/Unsupported '\+system' reset name 'reset_n'/, 'bad sreset name gets a targeted diagnostic');

    my $async_error = parse_failure(<<'FSM');
(?fsm:bad_async_reset_name
  (+system
    (clock clk)
    (asreset reset_async_n)
  )
  (-dt
    (A = 1)
  )
)
FSM

    like($async_error, qr/Unsupported '\+system' reset name 'reset_async_n'/, 'bad asreset name gets a targeted diagnostic');
};

subtest 'pipeline and CLI do not emit HDL for non-conventional +system reset names' => sub {
    assert_pipeline_and_cli_reject(
        'bad_sync_reset_name_cli.fsm',
        <<'FSM',
(?fsm:bad_sync_reset_name_cli
  (+system
    (clock clk)
    (sreset reset_n)
  )
  (-dt
    (A = 1)
  )
)
FSM
        qr/Unsupported '\+system' reset name 'reset_n'/,
        'non-conventional sreset name',
    );

    assert_pipeline_and_cli_reject(
        'bad_async_reset_name_cli.fsm',
        <<'FSM',
(?fsm:bad_async_reset_name_cli
  (+system
    (clock clk)
    (asreset reset_async_n)
  )
  (-dt
    (A = 1)
  )
)
FSM
        qr/Unsupported '\+system' reset name 'reset_async_n'/,
        'non-conventional asreset name',
    );
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

sub assert_pipeline_and_cli_reject {
    my ($filename, $fsm_text, $error_re, $label) = @_;

    my $fsm_path = write_fsm($filename, $fsm_text);
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug => 0,
    );

    my $pipeline_error = eval {
        $pipeline->generate_hdl_from_file($fsm_path);
        undef;
    };
    $pipeline_error = $@ if !$pipeline_error;
    ok($pipeline_error, "pipeline rejects $label");
    like($pipeline_error, $error_re, "pipeline surfaces the explicit boundary for $label");

    my $out_path = File::Spec->catfile($tempdir, $filename . '.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $out_path, '--quiet', $fsm_path],
    );

    ok(!$success, "CLI rejects $label");
    ok(!-e $out_path, "CLI does not emit output for $label");

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );
    like($combined_output, $error_re, "CLI surfaces the explicit boundary for $label");
}

sub write_fsm {
    my ($filename, $content) = @_;
    my $path = File::Spec->catfile($tempdir, $filename);
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
    return $path;
}

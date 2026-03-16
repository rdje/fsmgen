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

subtest 'pipeline and CLI do not emit HDL for malformed +constants sections' => sub {
    my $fsm_path = write_fsm('bad_constants_cli.fsm', <<'FSM');
(?fsm:bad_constants_cli
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+constants
    BROKEN
  )
  (-dt
    (OUT = 1)
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
    ok($pipeline_error, 'pipeline rejects malformed +constants payload');
    like($pipeline_error, qr/Malformed '\+constants' entry/, 'pipeline surfaces the explicit +constants boundary');

    my $out_path = File::Spec->catfile($tempdir, 'bad_constants_cli.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $out_path, '--quiet', $fsm_path],
    );

    ok(!$success, 'CLI rejects malformed +constants payload');
    ok(!-e $out_path, 'CLI does not emit output for malformed +constants payload');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );
    like($combined_output, qr/Malformed '\+constants' entry/, 'CLI surfaces the explicit +constants boundary');
};

subtest 'pipeline and CLI do not emit HDL for malformed +define directives' => sub {
    my $fsm_path = write_fsm('bad_define_cli.fsm', <<'FSM');
(?fsm:bad_define_cli
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+define
    (D0)
  )
  (-dt
    (OUT = 1)
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
    ok($pipeline_error, 'pipeline rejects malformed +define payload');
    like($pipeline_error, qr/Malformed '\+define' entry for name 'D0'/, 'pipeline surfaces the explicit +define boundary');

    my $out_path = File::Spec->catfile($tempdir, 'bad_define_cli.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $out_path, '--quiet', $fsm_path],
    );

    ok(!$success, 'CLI rejects malformed +define payload');
    ok(!-e $out_path, 'CLI does not emit output for malformed +define payload');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );
    like($combined_output, qr/Malformed '\+define' entry for name 'D0'/, 'CLI surfaces the explicit +define boundary');
};

subtest 'pipeline and CLI do not emit HDL for malformed +params sections' => sub {
    my $fsm_path = write_fsm('bad_params_cli.fsm', <<'FSM');
(?fsm:bad_params_cli
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+params
    (P0)
  )
  (-dt
    (OUT = 1)
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
    ok($pipeline_error, 'pipeline rejects malformed +params payload');
    like($pipeline_error, qr/Malformed '\+params' entry for parameter 'P0'/, 'pipeline surfaces the explicit +params boundary');

    my $out_path = File::Spec->catfile($tempdir, 'bad_params_cli.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $out_path, '--quiet', $fsm_path],
    );

    ok(!$success, 'CLI rejects malformed +params payload');
    ok(!-e $out_path, 'CLI does not emit output for malformed +params payload');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );
    like($combined_output, qr/Malformed '\+params' entry for parameter 'P0'/, 'CLI surfaces the explicit +params boundary');
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

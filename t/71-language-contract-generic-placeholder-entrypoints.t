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

subtest 'pipeline and CLI do not emit HDL for legacy placeholder test selectors' => sub {
    my $fsm_path = write_fsm('placeholder_selector.fsm', <<'FSM');
(?fsm:placeholder_selector
  (+system (clock clk) (sreset rstn))
  (+size (X 1))
  (s0
    (?[READ]
      (=1 (X = 1))
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
    ok($pipeline_error, 'pipeline rejects legacy placeholder test selector');
    like($pipeline_error, qr/Unsupported generic\/template test selector '\?\[READ\]'/, 'pipeline surfaces the explicit placeholder-selector boundary');

    my $out_path = File::Spec->catfile($tempdir, 'placeholder_selector.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $out_path, '--quiet', $fsm_path],
    );

    ok(!$success, 'CLI rejects legacy placeholder test selector');
    ok(!-e $out_path, 'CLI does not emit output for legacy placeholder test selector');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/Unsupported generic\/template test selector '\?\[READ\]'/, 'CLI surfaces the explicit placeholder-selector boundary');
};

subtest 'pipeline and CLI do not emit HDL for legacy repeat macros' => sub {
    my $fsm_path = write_fsm('repeat_macro.fsm', <<'FSM');
(?fsm:repeat_macro
  (+system (clock clk) (sreset rstn))
  (+size (X 1))
  (s0
    (?repeat:[MAX_COUNT]
      (X = 1)
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
    ok($pipeline_error, 'pipeline rejects legacy repeat macro');
    like($pipeline_error, qr/Unsupported generic\/template repeat action '\?repeat:\[MAX_COUNT\]'/, 'pipeline surfaces the explicit repeat-macro boundary');

    my $out_path = File::Spec->catfile($tempdir, 'repeat_macro.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $out_path, '--quiet', $fsm_path],
    );

    ok(!$success, 'CLI rejects legacy repeat macro');
    ok(!-e $out_path, 'CLI does not emit output for legacy repeat macro');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/Unsupported generic\/template repeat action '\?repeat:\[MAX_COUNT\]'/, 'CLI surfaces the explicit repeat-macro boundary');
};

subtest 'pipeline and CLI do not emit HDL for legacy placeholder expression tokens' => sub {
    my $fsm_path = write_fsm('placeholder_token.fsm', <<'FSM');
(?fsm:placeholder_token
  (+system (clock clk) (sreset rstn))
  (+size (X 8))
  (s0
    (X = [DATAIN])
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
    ok($pipeline_error, 'pipeline rejects legacy placeholder expression token');
    like($pipeline_error, qr/Unsupported generic\/template placeholder token '\[DATAIN\]'/, 'pipeline surfaces the explicit placeholder-token boundary');

    my $out_path = File::Spec->catfile($tempdir, 'placeholder_token.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $out_path, '--quiet', $fsm_path],
    );

    ok(!$success, 'CLI rejects legacy placeholder expression token');
    ok(!-e $out_path, 'CLI does not emit output for legacy placeholder expression token');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/Unsupported generic\/template placeholder token '\[DATAIN\]'/, 'CLI surfaces the explicit placeholder-token boundary');
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

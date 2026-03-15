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

subtest 'pipeline and CLI do not emit HDL for unknown top-level + directives' => sub {
    my $fsm_path = write_fsm('unknown_top_level_directive.fsm', <<'FSM');
(?fsm:bad_top_level_directive
  (+bogus
    (foo bar)
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
    my $pipeline_error = eval {
        $pipeline->generate_hdl_from_file($fsm_path);
        undef;
    };
    $pipeline_error = $@ if !$pipeline_error;
    ok($pipeline_error, 'pipeline rejects unknown top-level + directive');
    like($pipeline_error, qr/Unsupported top-level directive '\+bogus'/, 'pipeline surfaces the explicit unknown-+directive boundary');

    my $out_path = File::Spec->catfile($tempdir, 'unknown_top_level_directive.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $out_path, '--quiet', $fsm_path],
    );

    ok(!$success, 'CLI rejects unknown top-level + directive');
    ok(!-e $out_path, 'CLI does not emit output for unknown top-level + directive');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/Unsupported top-level directive '\+bogus'/, 'CLI surfaces the explicit unknown-+directive boundary');
};

subtest 'pipeline and CLI do not emit HDL for unsupported future-style top-level directives' => sub {
    my $fsm_path = write_fsm('future_style_top_level_directive.fsm', <<'FSM');
(?fsm:future_clock_directive
  (+clock clk)
  (+asreset rstn)
  (-dt
    (A = 1)
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
    ok($pipeline_error, 'pipeline rejects unsupported future-style + directive');
    like($pipeline_error, qr/Unsupported top-level directive '\+clock'/, 'pipeline surfaces the explicit unsupported-future-directive boundary');

    my $out_path = File::Spec->catfile($tempdir, 'future_style_top_level_directive.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $out_path, '--quiet', $fsm_path],
    );

    ok(!$success, 'CLI rejects unsupported future-style + directive');
    ok(!-e $out_path, 'CLI does not emit output for unsupported future-style + directive');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/Unsupported top-level directive '\+clock'/, 'CLI surfaces the explicit unsupported-future-directive boundary');
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

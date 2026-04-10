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

subtest 'pipeline and CLI do not emit HDL for non-conventional +system clock names' => sub {
    my $fsm_path = write_fsm('bad_system_clock_name.fsm', <<'FSM');
(?fsm:bad_clock_name
  (+system
    (clock core_clk)
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
    my $pipeline_error = eval {
        $pipeline->generate_hdl_from_file($fsm_path);
        undef;
    };
    $pipeline_error = $@ if !$pipeline_error;
    ok($pipeline_error, 'pipeline rejects non-conventional +system clock name');
    like($pipeline_error, qr/Unsupported '\+system' clock name 'core_clk'/, 'pipeline surfaces the explicit +system clock-name boundary');

    my $out_path = File::Spec->catfile($tempdir, 'bad_system_clock_name.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $out_path, '--quiet', $fsm_path],
    );

    ok(!$success, 'CLI rejects non-conventional +system clock name');
    ok(!-e $out_path, 'CLI does not emit output for non-conventional +system clock name');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/Unsupported '\+system' clock name 'core_clk'/, 'CLI surfaces the explicit +system clock-name boundary');
};

subtest 'pipeline and CLI emit HDL for canonical areset +system directives' => sub {
    my $fsm_path = write_fsm('canonical_areset_system_directive.fsm', <<'FSM');
(?fsm:canonical_areset_system_directive
  (+system
    (clock clk)
    (areset rst_n)
  )
  (+size
    (A 1)
  )
  (-dt
    (A <= 1)
  )
)
FSM

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug => 0,
    );
    my $pipeline_result = eval {
        $pipeline->generate_hdl_from_file($fsm_path);
    };
    my $pipeline_error = $@;
    is($pipeline_error, '', 'pipeline accepts canonical areset +system directive');
    like($pipeline_result->{hdl_code}, qr/always_ff \@\(posedge clk or negedge rst_n\) begin\s+if \(!rst_n\) begin/s, 'pipeline emits asynchronous active-low reset behavior for areset');

    my $out_path = File::Spec->catfile($tempdir, 'canonical_areset_system_directive.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $out_path, '--quiet', $fsm_path],
    );

    ok($success, 'CLI accepts canonical areset +system directive');
    ok(-e $out_path, 'CLI emits output for canonical areset +system directive');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    unlike($combined_output, qr/Unsupported '\+system' entry 'areset'|Error parsing FSM/s, 'CLI output does not report a rejected areset +system directive');
    like(read_file($out_path), qr/always_ff \@\(posedge clk or negedge rst_n\) begin\s+if \(!rst_n\) begin/s, 'CLI output emits asynchronous active-low reset behavior for areset');
};

subtest 'pipeline and CLI do not emit HDL for incomplete +system sections' => sub {
    my $fsm_path = write_fsm('incomplete_system_section.fsm', <<'FSM');
(?fsm:incomplete_system
  (+system
    (clock clk)
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
    ok($pipeline_error, 'pipeline rejects incomplete +system section');
    like($pipeline_error, qr/Incomplete '\+system' section/, 'pipeline surfaces the explicit incomplete-+system boundary');

    my $out_path = File::Spec->catfile($tempdir, 'incomplete_system_section.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $out_path, '--quiet', $fsm_path],
    );

    ok(!$success, 'CLI rejects incomplete +system section');
    ok(!-e $out_path, 'CLI does not emit output for incomplete +system section');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/Incomplete '\+system' section/, 'CLI surfaces the explicit incomplete-+system boundary');
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

sub read_file {
    my ($path) = @_;
    open my $fh, '<', $path or die "Cannot open $path for read: $!";
    local $/;
    my $content = <$fh>;
    close $fh or die "Cannot close $path: $!";
    return $content;
}

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

subtest 'pipeline and CLI emit HDL for authored +system clock identifiers' => sub {
    my $fsm_path = write_fsm('custom_system_clock_name.fsm', <<'FSM');
(?fsm:custom_clock_name
  (+system
    (clock core_clk)
    (sreset rstn)
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
    is($pipeline_error, '', 'pipeline accepts authored +system clock identifiers');
    like($pipeline_result->{hdl_code}, qr/\binput\s+wire\s+core_clk\b/s, 'pipeline declares the authored clock port');
    like($pipeline_result->{hdl_code}, qr/always_ff\s*@\(posedge\s+core_clk\)/s, 'pipeline uses the authored clock in sequential logic');

    my $out_path = File::Spec->catfile($tempdir, 'custom_system_clock_name.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $out_path, '--quiet', $fsm_path],
    );

    ok($success, 'CLI accepts authored +system clock identifiers');
    ok(-e $out_path, 'CLI emits output for authored +system clock identifiers');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    unlike($combined_output, qr/Unsupported '\+system' clock name 'core_clk'|Error parsing FSM/s, 'CLI output does not report rejected authored clock identifiers');
    like(read_file($out_path), qr/\binput\s+wire\s+core_clk\b/s, 'CLI output declares the authored clock port');
    like(read_file($out_path), qr/always_ff\s*@\(posedge\s+core_clk\)/s, 'CLI output uses the authored clock in sequential logic');
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

subtest 'pipeline and CLI emit HDL for clock-only no-reset +system sections' => sub {
    my $fsm_path = write_fsm('clock_only_system_section.fsm', <<'FSM');
(?fsm:clock_only_system
  (+system
    (clock clk)
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
    is($pipeline_error, '', 'pipeline accepts clock-only +system sections');
    like($pipeline_result->{hdl_code}, qr/\binput\s+wire\s+clk\b/s, 'pipeline declares the authored clock port');
    unlike($pipeline_result->{hdl_code}, qr/\binput\s+wire\s+(?:rst_n|reset|rstn)\b/s, 'pipeline does not declare a reset port');
    like($pipeline_result->{hdl_code}, qr/always_ff\s*@\(posedge\s+clk\)\s+begin\s+(?!if\s*\()/s,
        'pipeline emits clock-only sequential logic');

    my $out_path = File::Spec->catfile($tempdir, 'clock_only_system_section.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $out_path, '--quiet', $fsm_path],
    );

    ok($success, 'CLI accepts clock-only +system sections');
    ok(-e $out_path, 'CLI emits output for clock-only +system sections');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    unlike($combined_output, qr/Incomplete '\+system' section|Error parsing FSM/s,
        'CLI output does not report an incomplete +system section');
    my $cli_hdl = read_file($out_path);
    like($cli_hdl, qr/\binput\s+wire\s+clk\b/s, 'CLI output declares the authored clock port');
    unlike($cli_hdl, qr/\binput\s+wire\s+(?:rst_n|reset|rstn)\b/s, 'CLI output does not declare a reset port');
    like($cli_hdl, qr/always_ff\s*@\(posedge\s+clk\)\s+begin\s+(?!if\s*\()/s,
        'CLI output emits clock-only sequential logic');
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

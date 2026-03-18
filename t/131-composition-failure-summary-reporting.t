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

subtest 'pipeline derives blocked composition failure summaries from top-scoped failures' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'unsupported_child_failure_summary_top.fsm');

    write_file(
        $composition_path,
        <<'FSM'
(?top:unsupported_child_failure_summary_top
  (?bogus:child foo)
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $exception = eval {
        $pipeline->generate_hdl_from_file($composition_path);
        undef;
    };
    $exception = $@;

    my $report = $pipeline->build_composition_failure_report($exception);

    ok($report, 'pipeline derives a composition failure report from blocked unsupported-child failures');
    is($report->{top_name}, 'unsupported_child_failure_summary_top', 'failure report preserves the composition top name');
    is($report->{context_label}, 'Child', 'failure report classifies child-header context');
    is($report->{context_value}, "'?bogus:child'", 'failure report preserves the offending child header as context');
    is($report->{context_summary}, "Child '?bogus:child'", 'failure report exposes a concise child context summary');
    is($report->{blocked_boundary}, 'composition child kind support', 'failure report preserves the blocked boundary');
    is($report->{blocked_boundary_label}, 'child kind support', 'failure report exposes a CLI-friendly blocked-boundary label');
    is(
        $report->{blocked_reason},
        "the active composition parser currently accepts only '?fsmc', '?dtc', '?rtl', '?ports', and '?toplink'",
        'failure report preserves the concise blocked reason for parser-scoped failures',
    );
};

subtest 'pipeline derives top-port context from blocked top-port failures' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'c1_width_mismatch_failure_summary_top.fsm');

    write_file(
        $composition_path,
        <<'FSM'
(?top:c1_width_mismatch_failure_summary_top
  (?ports:public_io
    clk
    rstn
    output_data>4
  )
  (?fsmc:child child_src)
)

(?fsm:child_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (output_data> <= 8'1)
  )
  (+size
    (output_data 8)
  )
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $exception = eval {
        $pipeline->generate_hdl_from_file($composition_path);
        undef;
    };
    $exception = $@;

    my $report = $pipeline->build_composition_failure_report($exception);

    ok($report, 'pipeline derives a composition failure report from blocked top-port failures');
    is($report->{top_name}, 'c1_width_mismatch_failure_summary_top', 'failure report preserves the top name for top-port failures');
    is($report->{context_label}, 'Top port', 'failure report classifies top-port context');
    is($report->{context_value}, "'output_data'", 'failure report preserves the blocked top-port name');
    is($report->{context_summary}, "Top port 'output_data'", 'failure report exposes a concise top-port context summary');
    is($report->{blocked_boundary}, 'C1 passthrough exposure', 'failure report preserves the blocked top-port boundary');
    is($report->{blocked_reason}, "child port 'output_data' has width 8", 'failure report preserves the concise top-port failure reason');
};

subtest 'pipeline derives blocked composition failure summaries from rtl-module failures' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'missing_rtlif_failure_summary_top.fsm');

    write_file(
        $composition_path,
        <<'FSM'
(?top:missing_rtlif_failure_summary_top
  (?ports:public_io
    clk
    rstn
    serial_out>
  )
  (?fsmc:producer producer_src)
  (?rtl:uart_tx)
  (?toplink:wiring
    /producer.output_data/uart_tx.data_in/
    /uart_tx.txd/serial_out/
  )
)

(?fsm:producer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (output_data> <= 8'1)
  )
  (+size
    (output_data 8)
  )
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $exception = eval {
        $pipeline->generate_hdl_from_file($composition_path);
        undef;
    };
    $exception = $@;

    my $report = $pipeline->build_composition_failure_report($exception);

    ok($report, 'pipeline derives a composition failure report from blocked rtlif failures');
    is($report->{rtl_module_name}, 'uart_tx', 'failure report preserves the external RTL module name');
    is($report->{blocked_boundary}, 'RTL interface metadata resolution', 'failure report preserves the blocked rtlif boundary');
    is($report->{blocked_boundary_label}, 'RTL interface metadata resolution', 'failure report keeps the RTL boundary label readable');
    is(
        $report->{blocked_reason},
        "no declared interface metadata file 'uart_tx.rtlif' was found",
        'failure report trims the blocked reason before search-root follow-up details',
    );
};

subtest 'CLI prints composition failure summary for non-quiet blocked composition runs' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'unsupported_child_failure_cli_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'unsupported_child_failure_cli_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:unsupported_child_failure_cli_top
  (?bogus:child foo)
)
FSM
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, $composition_path],
    );

    ok(!$success, 'CLI fails for blocked unsupported-child composition fixture');
    ok(!-e $output_path, 'CLI does not emit HDL output for blocked unsupported-child fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/=== Composition Failure Summary ===/s, 'CLI prints the composition failure summary section');
    like($combined_output, qr/Top:\s+unsupported_child_failure_cli_top/s, 'CLI reports the failing composition top name');
    like($combined_output, qr/Context:\s+Child '\?bogus:child'/s, 'CLI reports the concise child context');
    like($combined_output, qr/Blocked boundary:\s+child kind support/s, 'CLI reports the blocked composition boundary');
    like(
        $combined_output,
        qr/Reason:\s+the active composition parser currently accepts only '\?fsmc', '\?dtc', '\?rtl', '\?ports', and '\?toplink'/s,
        'CLI reports the concise blocked reason',
    );
    like($combined_output, qr/composition child kind support is blocked because the active composition parser currently accepts only '\?fsmc', '\?dtc', '\?rtl', '\?ports', and '\?toplink'/s, 'CLI still surfaces the original blocked diagnostic text');
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

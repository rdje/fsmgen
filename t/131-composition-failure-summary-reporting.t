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
    ok(!defined($report->{construct}), 'failure report does not invent a construct for unsupported child headers');
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

subtest 'pipeline derives top-port context from blocked duplicate top-port declarations' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'duplicate_top_port_failure_summary_top.fsm');

    write_file(
        $composition_path,
        <<'FSM'
(?top:duplicate_top_port_failure_summary_top
  (?ports:public_io
    clk
    rstn
    output_data>8
    output_data>8
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

    ok($report, 'pipeline derives a composition failure report from blocked duplicate top-port declarations');
    is($report->{top_name}, 'duplicate_top_port_failure_summary_top', 'failure report preserves the top name for blocked duplicate top-port declarations');
    is($report->{construct}, '?ports', 'failure report preserves the top-interface construct for blocked duplicate top-port declarations');
    is($report->{context_label}, 'Top port', 'failure report classifies duplicate top-port declarations as top-port context');
    is($report->{context_value}, "'output_data'", 'failure report preserves the duplicated top-port name');
    is($report->{context_summary}, "Top port 'output_data'", 'failure report exposes a concise duplicate top-port summary');
    is($report->{blocked_boundary}, 'composition shape', 'failure report preserves the blocked composition-shape boundary for duplicate top-port declarations');
    is($report->{blocked_reason}, 'the active composition lanes require each top port name to be unique', 'failure report preserves the concise duplicate top-port reason');
};

subtest 'pipeline derives child context from blocked duplicate child-instance declarations' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'duplicate_child_instance_failure_summary_top.fsm');

    write_file(
        $composition_path,
        <<'FSM'
(?top:duplicate_child_instance_failure_summary_top
  (?ports:public_io
    clk
    rstn
    start
    result_data>8
  )
  (?fsmc:dup producer_src)
  (?fsmc:dup consumer_src)
  (?toplink:wiring
    /start/dup.go/
    /dup.output_data/result_data/
  )
)

(?fsm:producer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (<go
      (output_data> <= 8'2)
    )
  )
  (+size
    (go 1)
    (output_data 8)
  )
)

(?fsm:consumer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (<go
      (output_data> <= 8'3)
    )
  )
  (+size
    (go 1)
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

    ok($report, 'pipeline derives a composition failure report from blocked duplicate child-instance declarations');
    is($report->{top_name}, 'duplicate_child_instance_failure_summary_top', 'failure report preserves the top name for blocked duplicate child-instance declarations');
    ok(!defined($report->{construct}), 'failure report does not invent a construct for duplicate child-instance declarations');
    is($report->{context_label}, 'Child', 'failure report classifies duplicate child-instance declarations as child context');
    is($report->{context_value}, "'dup'", 'failure report preserves the duplicated child-instance name');
    is($report->{context_summary}, "Child 'dup'", 'failure report exposes a concise duplicate child-instance summary');
    is($report->{blocked_boundary}, 'composition shape', 'failure report preserves the blocked composition-shape boundary for duplicate child-instance declarations');
    is($report->{blocked_reason}, 'the active composition lanes require each realized child instance name to be unique', 'failure report preserves the concise duplicate child-instance reason');
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
    is($report->{construct}, '?ports', 'failure report preserves the active top-interface construct for top-port failures');
    is($report->{construct_summary}, '?ports', 'failure report exposes a concise top-interface construct summary');
    is($report->{context_label}, 'Top port', 'failure report classifies top-port context');
    is($report->{context_value}, "'output_data'", 'failure report preserves the blocked top-port name');
    is($report->{context_summary}, "Top port 'output_data'", 'failure report exposes a concise top-port context summary');
    is($report->{blocked_boundary}, 'C1 passthrough exposure', 'failure report preserves the blocked top-port boundary');
    is($report->{blocked_reason}, "child port 'output_data' has width 8", 'failure report preserves the concise top-port failure reason');
};

subtest 'pipeline derives active composition lane when blocked diagnostics expose it' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'c1_missing_exposure_failure_summary_top.fsm');

    write_file(
        $composition_path,
        <<'FSM'
(?top:c1_missing_exposure_failure_summary_top
  (?ports:public_io
    clk
    rstn
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

    ok($report, 'pipeline derives a composition failure report from blocked lane-visible failures');
    is($report->{top_name}, 'c1_missing_exposure_failure_summary_top', 'failure report preserves the top name for lane-visible failures');
    is($report->{lane}, 'C1', 'failure report preserves the active composition lane when the blocked diagnostic exposes it');
    is($report->{context_label}, 'Child port', 'failure report classifies the blocked child port as context');
    is($report->{context_value}, "'output_data'", 'failure report preserves the blocked child-port name');
    is($report->{blocked_boundary}, 'C1 passthrough exposure', 'failure report preserves the blocked boundary for lane-visible failures');
};

subtest 'pipeline derives explicit-link lane-entry summaries without inventing context' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'missing_toplink_failure_summary_top.fsm');

    write_file(
        $composition_path,
        <<'FSM'
(?top:missing_toplink_failure_summary_top
  (?ports:public_io
    clk
    rstn
    result_data>8
  )
  (?fsmc:producer producer_src)
  (?fsmc:consumer consumer_src)
)

(?fsm:producer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (output_data> <= 8'3)
  )
  (+size
    (output_data 8)
  )
)

(?fsm:consumer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (final_data> <= 8'5)
  )
  (+size
    (final_data 8)
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

    ok($report, 'pipeline derives a composition failure report from blocked explicit-link lane-entry failures');
    is($report->{top_name}, 'missing_toplink_failure_summary_top', 'failure report preserves the top name for blocked explicit-link lane-entry failures');
    is($report->{lane}, 'C2', 'failure report preserves the active C2 lane for blocked explicit-link lane-entry failures');
    is($report->{construct}, '?toplink', 'failure report preserves the explicit-link construct for blocked lane-entry failures');
    ok(!defined($report->{context_label}), 'failure report does not invent context for blocked explicit-link lane-entry failures');
    is($report->{blocked_boundary}, 'explicit-link lane entry', 'failure report preserves the blocked explicit-link lane-entry boundary');
    is($report->{blocked_reason}, "the current active C2 lane requires explicit '?toplink' wiring", 'failure report preserves the concise explicit-link lane-entry reason');
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
    is($report->{lane}, 'C3', 'failure report preserves the active composition lane for rtlif failures');
    is($report->{construct}, '?rtl', 'failure report preserves the external RTL construct for rtlif failures');
    is($report->{construct_summary}, '?rtl', 'failure report exposes a concise external RTL construct summary');
    is($report->{blocked_boundary}, 'RTL interface metadata resolution', 'failure report preserves the blocked rtlif boundary');
    is($report->{blocked_boundary_label}, 'RTL interface metadata resolution', 'failure report keeps the RTL boundary label readable');
    is(
        $report->{blocked_reason},
        "no declared interface metadata file 'uart_tx.rtlif' was found",
        'failure report trims the blocked reason before search-root follow-up details',
    );
};

subtest 'pipeline derives RTL metadata file artifacts from blocked metadata-structure failures' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'bad_rtlif_root_failure_summary_top.fsm');
    my $metadata_path = File::Spec->catfile($tempdir, 'uart_tx.rtlif');

    write_file(
        $composition_path,
        <<'FSM'
(?top:bad_rtlif_root_failure_summary_top
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

    write_file(
        $metadata_path,
        <<'FSM'
(?rtlif:wrong_uart
  data_in<8:data
  txd>:data
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

    ok($report, 'pipeline derives a composition failure report from blocked rtl metadata-structure failures');
    is($report->{rtl_module_name}, 'uart_tx', 'failure report preserves the external RTL module name for metadata-structure failures');
    is($report->{construct}, '?rtl', 'failure report preserves the external RTL construct for metadata-structure failures');
    is($report->{artifact_label}, 'RTL metadata file', 'failure report classifies the resolved rtlif file as artifact context');
    is($report->{artifact_value}, "'$metadata_path'", 'failure report preserves the resolved rtlif file path');
    is($report->{artifact_summary}, "RTL metadata file '$metadata_path'", 'failure report exposes a concise rtlif file summary');
    is($report->{context_label}, 'RTL root', 'failure report preserves the missing rtlif root token as summary context');
    is($report->{context_value}, "'?rtlif:uart_tx'", 'failure report preserves the missing rtlif root token');
    is($report->{blocked_boundary}, 'RTL interface metadata structure', 'failure report preserves the blocked rtlif structure boundary');
    is($report->{blocked_reason}, "does not contain a '?rtlif:uart_tx' root", 'failure report trims the blocked rtlif reason to the first real structure problem');
};

subtest 'pipeline keeps rtl root context alongside RTL metadata file artifacts for blocked empty-port failures' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'empty_port_failure_summary_top.fsm');
    my $metadata_path = File::Spec->catfile($tempdir, 'uart_tx.rtlif');

    write_file(
        $composition_path,
        <<'FSM'
(?top:empty_port_failure_summary_top
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

    write_file(
        $metadata_path,
        <<'RTLIF'
(?rtlif:uart_tx)
RTLIF
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

    ok($report, 'pipeline derives a composition failure report from blocked empty-port rtlif failures');
    is($report->{rtl_module_name}, 'uart_tx', 'failure report preserves the external RTL module name for empty-port failures');
    is($report->{construct}, '?rtl', 'failure report preserves the external RTL construct for empty-port failures');
    is($report->{artifact_label}, 'RTL metadata file', 'failure report classifies the resolved rtlif file as artifact context for empty-port failures');
    is($report->{artifact_value}, "'$metadata_path'", 'failure report preserves the resolved rtlif file path for empty-port failures');
    is($report->{context_label}, 'RTL root', 'failure report preserves the empty-port rtlif root token as summary context');
    is($report->{context_value}, "'?rtlif:uart_tx'", 'failure report preserves the empty-port rtlif root token');
    is($report->{blocked_boundary}, 'RTL interface metadata port presence', 'failure report preserves the blocked rtlif port-presence boundary');
    is($report->{blocked_reason}, "declares no ports under '?rtlif:uart_tx'", 'failure report trims the blocked empty-port reason without repeating the metadata file path');
};

subtest 'pipeline keeps rtl root context alongside RTL metadata file artifacts for blocked flatness failures' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'nested_rtlif_failure_summary_top.fsm');
    my $metadata_path = File::Spec->catfile($tempdir, 'uart_tx.rtlif');

    write_file(
        $composition_path,
        <<'FSM'
(?top:nested_rtlif_failure_summary_top
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

    write_file(
        $metadata_path,
        <<'RTLIF'
(?rtlif:uart_tx
  clk:clock
  rstn:reset
  (group
    data_in<8:data
  )
  txd>:data
)
RTLIF
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

    ok($report, 'pipeline derives a composition failure report from blocked rtlif flatness failures');
    is($report->{rtl_module_name}, 'uart_tx', 'failure report preserves the external RTL module name for flatness failures');
    is($report->{construct}, '?rtl', 'failure report preserves the external RTL construct for flatness failures');
    is($report->{artifact_label}, 'RTL metadata file', 'failure report classifies the resolved rtlif file as artifact context for flatness failures');
    is($report->{artifact_value}, "'$metadata_path'", 'failure report preserves the resolved rtlif file path for flatness failures');
    is($report->{context_label}, 'RTL root', 'failure report preserves the flatness rtlif root token as summary context');
    is($report->{context_value}, "'?rtlif:uart_tx'", 'failure report preserves the flatness rtlif root token');
    is($report->{blocked_boundary}, 'RTL interface metadata flatness', 'failure report preserves the blocked rtlif flatness boundary');
    is($report->{blocked_reason}, "contains nested structure under '?rtlif:uart_tx'", 'failure report trims the blocked flatness reason without repeating the metadata file path');
};

subtest 'pipeline keeps token context alongside RTL metadata file artifacts for blocked token failures' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'invalid_token_failure_summary_top.fsm');
    my $metadata_path = File::Spec->catfile($tempdir, 'uart_tx.rtlif');

    write_file(
        $composition_path,
        <<'FSM'
(?top:invalid_token_failure_summary_top
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

    write_file(
        $metadata_path,
        <<'RTLIF'
(?rtlif:uart_tx
  clk:clock
  rstn:reset
  data-in<8:data
  txd>:data
)
RTLIF
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

    ok($report, 'pipeline derives a composition failure report from blocked rtlif token failures');
    is($report->{rtl_module_name}, 'uart_tx', 'failure report preserves the external RTL module name for token failures');
    is($report->{construct}, '?rtl', 'failure report preserves the external RTL construct for token failures');
    is($report->{artifact_label}, 'RTL metadata file', 'failure report classifies the resolved rtlif file as artifact context for token failures');
    is($report->{artifact_value}, "'$metadata_path'", 'failure report preserves the resolved rtlif file path for token failures');
    is($report->{context_label}, 'Token', 'failure report preserves token context when the metadata file is already surfaced as an artifact');
    is($report->{context_value}, "'data-in<8:data'", 'failure report preserves the invalid token as summary context');
    is($report->{blocked_boundary}, 'RTL interface metadata token shape', 'failure report preserves the blocked rtlif token boundary');
    is($report->{blocked_reason}, "token 'data-in<8:data' is an invalid port token for the current '.rtlif' contract", 'failure report trims the blocked rtlif token reason without repeating the metadata file path');
};

subtest 'pipeline keeps token context alongside RTL metadata file artifacts for blocked width failures' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'invalid_width_failure_summary_top.fsm');
    my $metadata_path = File::Spec->catfile($tempdir, 'uart_tx.rtlif');

    write_file(
        $composition_path,
        <<'FSM'
(?top:invalid_width_failure_summary_top
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

    write_file(
        $metadata_path,
        <<'RTLIF'
(?rtlif:uart_tx
  clk:clock
  rstn:reset
  data_in<0:data
  txd>:data
)
RTLIF
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

    ok($report, 'pipeline derives a composition failure report from blocked rtlif width failures');
    is($report->{rtl_module_name}, 'uart_tx', 'failure report preserves the external RTL module name for width failures');
    is($report->{construct}, '?rtl', 'failure report preserves the external RTL construct for width failures');
    is($report->{artifact_label}, 'RTL metadata file', 'failure report classifies the resolved rtlif file as artifact context for width failures');
    is($report->{artifact_value}, "'$metadata_path'", 'failure report preserves the resolved rtlif file path for width failures');
    is($report->{context_label}, 'Token', 'failure report preserves token context when the metadata file is already surfaced as an artifact for width failures');
    is($report->{context_value}, "'data_in<0:data'", 'failure report preserves the invalid-width token as summary context');
    is($report->{blocked_boundary}, 'RTL interface metadata port sizing', 'failure report preserves the blocked rtlif width boundary');
    is($report->{blocked_reason}, "token 'data_in<0:data' declares non-positive port width '0'", 'failure report trims the blocked rtlif width reason without repeating the metadata file path');
};

subtest 'pipeline keeps token context alongside RTL metadata file artifacts for blocked type failures' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'invalid_type_failure_summary_top.fsm');
    my $metadata_path = File::Spec->catfile($tempdir, 'uart_tx.rtlif');

    write_file(
        $composition_path,
        <<'FSM'
(?top:invalid_type_failure_summary_top
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

    write_file(
        $metadata_path,
        <<'RTLIF'
(?rtlif:uart_tx
  clk:clock
  rstn:reset
  data_in<8:status
  txd>:data
)
RTLIF
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

    ok($report, 'pipeline derives a composition failure report from blocked rtlif type failures');
    is($report->{rtl_module_name}, 'uart_tx', 'failure report preserves the external RTL module name for type failures');
    is($report->{construct}, '?rtl', 'failure report preserves the external RTL construct for type failures');
    is($report->{artifact_label}, 'RTL metadata file', 'failure report classifies the resolved rtlif file as artifact context for type failures');
    is($report->{artifact_value}, "'$metadata_path'", 'failure report preserves the resolved rtlif file path for type failures');
    is($report->{context_label}, 'Token', 'failure report preserves token context when the metadata file is already surfaced as an artifact for type failures');
    is($report->{context_value}, "'data_in<8:status'", 'failure report preserves the unsupported-type token as summary context');
    is($report->{blocked_boundary}, 'RTL interface metadata port typing', 'failure report preserves the blocked rtlif type boundary');
    is($report->{blocked_reason}, "token 'data_in<8:status' resolves to unsupported port type 'status'", 'failure report trims the blocked rtlif type reason without repeating the metadata file path');
};

subtest 'pipeline keeps rtl port context alongside RTL metadata file artifacts for blocked duplicate-port failures' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'duplicate_port_failure_summary_top.fsm');
    my $metadata_path = File::Spec->catfile($tempdir, 'uart_tx.rtlif');

    write_file(
        $composition_path,
        <<'FSM'
(?top:duplicate_port_failure_summary_top
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

    write_file(
        $metadata_path,
        <<'RTLIF'
(?rtlif:uart_tx
  clk:clock
  rstn:reset
  data_in<8:data
  txd>:data
  txd>:data
)
RTLIF
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

    ok($report, 'pipeline derives a composition failure report from blocked duplicate-port rtlif failures');
    is($report->{rtl_module_name}, 'uart_tx', 'failure report preserves the external RTL module name for duplicate-port failures');
    is($report->{construct}, '?rtl', 'failure report preserves the external RTL construct for duplicate-port failures');
    is($report->{artifact_label}, 'RTL metadata file', 'failure report classifies the resolved rtlif file as artifact context for duplicate-port failures');
    is($report->{artifact_value}, "'$metadata_path'", 'failure report preserves the resolved rtlif file path for duplicate-port failures');
    is($report->{context_label}, 'RTL port', 'failure report preserves repeated rtlif port context when the metadata file is already surfaced as an artifact');
    is($report->{context_value}, "'txd'", 'failure report preserves the repeated rtlif port as summary context');
    is($report->{blocked_boundary}, 'RTL interface metadata port declaration uniqueness', 'failure report preserves the blocked rtlif duplicate-port boundary');
    is($report->{blocked_reason}, "repeats port 'txd'", 'failure report trims the blocked duplicate-port reason without repeating the metadata file path');
};

subtest 'pipeline derives rtl root context from blocked embedded-root uniqueness failures' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'duplicate_embedded_root_failure_summary_top.fsm');

    write_file(
        $composition_path,
        <<'FSM'
(?top:duplicate_embedded_root_failure_summary_top
  (?ports:public_io
    clk
    rst_n
    serial_out>
  )
  (?dtc:router route_src)
  (?rtl:uart_tx)
  (?toplink:wiring
    /router.route_data/uart_tx.data_in/
    /uart_tx.txd/serial_out/
  )
)

(?dt:route_src
  (-route
    (route_data> = payload_in)
  )
  (+size
    (payload_in 8)
    (route_data 8)
  )
)

(?rtlif:uart_tx
  clk:clock
  rst_n:reset
  data_in<8:data
  txd>:data
)

(?rtlif:uart_tx
  clk
  rst_n
  txd>
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

    ok($report, 'pipeline derives a composition failure report from blocked embedded rtlif duplicate-root failures');
    is($report->{construct}, '?rtl', 'failure report preserves the external RTL construct for embedded duplicate-root failures');
    is($report->{context_label}, 'RTL root', 'failure report preserves embedded rtlif root context when no external metadata artifact line exists');
    is($report->{context_value}, "'?rtlif:uart_tx'", 'failure report preserves the duplicate embedded rtlif root as summary context');
    is($report->{context_summary}, "RTL root '?rtlif:uart_tx'", 'failure report exposes a concise duplicate embedded-root summary');
    is($report->{blocked_boundary}, 'RTL interface metadata embedded-root uniqueness', 'failure report preserves the blocked embedded-root uniqueness boundary');
    is(
        $report->{blocked_reason},
        'the active RTL interface contract allows at most one embedded interface root per external RTL module name in the same source',
        'failure report preserves the concise embedded-root uniqueness reason',
    );
};

subtest 'pipeline derives child-source file context from blocked generated-child realization failures' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'wrong_fsmc_kind_failure_summary_top.fsm');
    my $child_path = File::Spec->catfile($tempdir, 'route_src.fsm');

    write_file(
        $composition_path,
        <<'FSM'
(?top:wrong_fsmc_kind_failure_summary_top
  (?ports:public_io
    data_in<8
    route_data>8
  )
  (?fsmc:router route_src)
)
FSM
    );

    write_file(
        $child_path,
        <<'FSM'
(?dt:route_src
  (-route
    (route_data> = data_in)
  )
  (+size
    (data_in 8)
    (route_data 8)
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

    ok($report, 'pipeline derives a composition failure report from blocked generated-child realization failures');
    is($report->{top_name}, 'wrong_fsmc_kind_failure_summary_top', 'failure report preserves the top name for blocked generated-child realization failures');
    is($report->{construct}, '?fsmc', 'failure report preserves the generated-child construct for blocked generated-child realization failures');
    is($report->{artifact_label}, 'Child source file', 'failure report classifies the resolved generated-child file as artifact context');
    is($report->{artifact_value}, "'$child_path'", 'failure report preserves the resolved generated-child file path');
    is($report->{artifact_summary}, "Child source file '$child_path'", 'failure report exposes a concise generated-child file summary');
    is($report->{context_label}, 'Child', 'failure report preserves the generated-child name as logical context');
    is($report->{context_value}, "'route_src'", 'failure report preserves the offending generated-child source name');
    is($report->{blocked_boundary}, 'child-source realization', 'failure report preserves the blocked generated-child realization boundary');
    is(
        $report->{blocked_reason},
        "that resolved file is not an active FSM child source (detected root '?dt:route_src')",
        'failure report trims the blocked generated-child reason before the corrective note',
    );
};

subtest 'pipeline derives child-endpoint context from blocked explicit-link endpoint failures' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'missing_child_endpoint_failure_summary_top.fsm');

    write_file(
        $composition_path,
        <<'FSM'
(?top:missing_child_endpoint_failure_summary_top
  (?ports:public_io
    clk
    rstn
    serial_out>
  )
  (?fsmc:producer producer_src)
  (?fsmc:consumer consumer_src)
  (?toplink:wiring
    /missing.output_data/serial_out/
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

(?fsm:consumer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (ack> <= 1'0)
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

    ok($report, 'pipeline derives a composition failure report from blocked missing-child-endpoint failures');
    is($report->{top_name}, 'missing_child_endpoint_failure_summary_top', 'failure report preserves the top name for blocked missing-child-endpoint failures');
    is($report->{construct}, '?toplink', 'failure report preserves the explicit-link construct for blocked child-endpoint failures');
    is($report->{context_label}, 'Child endpoint', 'failure report classifies missing child endpoints as endpoint context');
    is($report->{context_value}, "'missing.output_data'", 'failure report preserves the missing child endpoint');
    is($report->{context_summary}, "Child endpoint 'missing.output_data'", 'failure report exposes a concise missing child-endpoint summary');
    is($report->{blocked_boundary}, 'explicit link endpoint resolution', 'failure report preserves the blocked endpoint-resolution boundary');
    is($report->{blocked_reason}, "no realized child instance named 'missing' exists", 'failure report preserves the concise missing child-instance reason');
};

subtest 'pipeline derives child-endpoint context from blocked existing-instance missing-port failures' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'missing_child_port_failure_summary_top.fsm');
    my $rtl_metadata_path = File::Spec->catfile($tempdir, 'uart_tx.rtlif');

    write_file(
        $composition_path,
        <<'FSM'
(?top:missing_child_port_failure_summary_top
  (?ports:public_io
    clk
    rstn
    serial_out>
  )
  (?fsmc:producer producer_src)
  (?rtl:uart_tx)
  (?toplink:wiring
    /producer.output_data/uart_tx.missing_port/
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

    write_file(
        $rtl_metadata_path,
        <<'RTLIF'
(?rtlif:uart_tx
  clk
  rstn
  data_in<8:data
  txd>:data
)
RTLIF
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

    ok($report, 'pipeline derives a composition failure report from blocked existing-instance missing-port failures');
    is($report->{top_name}, 'missing_child_port_failure_summary_top', 'failure report preserves the top name for blocked existing-instance missing-port failures');
    is($report->{construct}, '?toplink', 'failure report preserves the explicit-link construct for blocked existing-instance missing-port failures');
    is($report->{context_label}, 'Child endpoint', 'failure report classifies existing-instance missing-port failures as child-endpoint context');
    is($report->{context_value}, "'uart_tx.missing_port'", 'failure report preserves the missing child endpoint on the existing instance');
    is($report->{context_summary}, "Child endpoint 'uart_tx.missing_port'", 'failure report exposes a concise existing-instance missing-port summary');
    is($report->{blocked_boundary}, 'explicit link endpoint resolution', 'failure report preserves the blocked endpoint-resolution boundary for existing-instance missing-port failures');
    is($report->{blocked_reason}, "instance 'uart_tx' has no port named 'missing_port'", 'failure report preserves the concise existing-instance missing-port reason');
};

subtest 'pipeline derives child-endpoint context from blocked explicit-link direction-mismatch failures' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'direction_mismatch_failure_summary_top.fsm');
    my $rtl_metadata_path = File::Spec->catfile($tempdir, 'uart_tx.rtlif');

    write_file(
        $composition_path,
        <<'FSM'
(?top:direction_mismatch_failure_summary_top
  (?ports:public_io
    clk
    rstn
  )
  (?fsmc:producer producer_src)
  (?rtl:uart_tx)
  (?toplink:wiring
    /producer.output_data/uart_tx.txd/
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

    write_file(
        $rtl_metadata_path,
        <<'RTLIF'
(?rtlif:uart_tx
  clk
  rstn
  data_in<8:data
  txd>:data
)
RTLIF
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

    ok($report, 'pipeline derives a composition failure report from blocked explicit-link direction-mismatch failures');
    is($report->{top_name}, 'direction_mismatch_failure_summary_top', 'failure report preserves the top name for blocked explicit-link direction-mismatch failures');
    is($report->{construct}, '?toplink', 'failure report preserves the explicit-link construct for blocked direction-mismatch failures');
    is($report->{context_label}, 'Child endpoint', 'failure report classifies direction-mismatch failures as child-endpoint context');
    is($report->{context_value}, "'uart_tx.txd'", 'failure report preserves the blocked child endpoint for direction-mismatch failures');
    is($report->{context_summary}, "Child endpoint 'uart_tx.txd'", 'failure report exposes a concise direction-mismatch child-endpoint summary');
    is($report->{blocked_boundary}, 'explicit link', 'failure report preserves the blocked explicit-link boundary for direction-mismatch failures');
    is($report->{blocked_reason}, 'that child port is output instead of input', 'failure report preserves the concise direction-mismatch reason');
};

subtest 'pipeline derives top-port context from blocked explicit-link top-port role mismatches' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'top_port_direction_mismatch_failure_summary_top.fsm');
    my $rtl_metadata_path = File::Spec->catfile($tempdir, 'uart_tx.rtlif');

    write_file(
        $composition_path,
        <<'FSM'
(?top:top_port_direction_mismatch_failure_summary_top
  (?ports:public_io
    clk
    rstn
    result_data>8
  )
  (?fsmc:producer producer_src)
  (?rtl:uart_tx)
  (?toplink:wiring
    /result_data/uart_tx.data_in/
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

    write_file(
        $rtl_metadata_path,
        <<'RTLIF'
(?rtlif:uart_tx
  clk
  rstn
  data_in<8:data
  txd>:data
)
RTLIF
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

    ok($report, 'pipeline derives a composition failure report from blocked explicit-link top-port role mismatches');
    is($report->{top_name}, 'top_port_direction_mismatch_failure_summary_top', 'failure report preserves the top name for blocked explicit-link top-port role mismatches');
    is($report->{construct}, '?toplink', 'failure report preserves the explicit-link construct for blocked top-port role mismatches');
    is($report->{context_label}, 'Top port', 'failure report classifies top-port role mismatches as top-port context');
    is($report->{context_value}, "'result_data'", 'failure report preserves the blocked top port for role mismatches');
    is($report->{context_summary}, "Top port 'result_data'", 'failure report exposes a concise top-port role-mismatch summary');
    is($report->{blocked_boundary}, 'explicit link', 'failure report preserves the blocked explicit-link boundary for top-port role mismatches');
    is($report->{blocked_reason}, 'that top port is declared as output instead of input', 'failure report preserves the concise top-port role-mismatch reason');
};

subtest 'pipeline derives top-port context from blocked explicit-link duplicate-driver failures' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'duplicate_driver_failure_summary_top.fsm');

    write_file(
        $composition_path,
        <<'FSM'
(?top:duplicate_driver_failure_summary_top
  (?ports:public_io
    clk
    rstn
    result_data>8
  )
  (?fsmc:producer_a producer_a_src)
  (?fsmc:producer_b producer_b_src)
  (?toplink:wiring
    /producer_a.output_data/result_data/
    /producer_b.output_data/result_data/
  )
)

(?fsm:producer_a_src
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

(?fsm:producer_b_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (output_data> <= 8'2)
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

    ok($report, 'pipeline derives a composition failure report from blocked explicit-link duplicate-driver failures');
    is($report->{top_name}, 'duplicate_driver_failure_summary_top', 'failure report preserves the top name for blocked explicit-link duplicate-driver failures');
    is($report->{construct}, '?toplink', 'failure report preserves the explicit-link construct for blocked duplicate-driver failures');
    is($report->{context_label}, 'Top port', 'failure report classifies duplicate-driver target conflicts as top-port context');
    is($report->{context_value}, "'result_data'", 'failure report preserves the conflicted top-port target for duplicate-driver failures');
    is($report->{context_summary}, "Top port 'result_data'", 'failure report exposes a concise duplicate-driver target summary');
    is($report->{blocked_boundary}, 'explicit link', 'failure report preserves the blocked explicit-link boundary for duplicate-driver failures');
    is($report->{blocked_reason}, "that target is already driven by explicit link 'producer_a.output_data'", 'failure report preserves the concise duplicate-driver reason');
};

subtest 'pipeline derives child-endpoint context from blocked explicit-link duplicate-driver failures' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'duplicate_driver_failure_summary_child.fsm');

    write_file(
        $composition_path,
        <<'FSM'
(?top:duplicate_driver_failure_summary_child
  (?ports:public_io
    clk
    rstn
    result_data>8
  )
  (?fsmc:producer_a producer_a_src)
  (?fsmc:producer_b producer_b_src)
  (?fsmc:consumer consumer_src)
  (?toplink:wiring
    /producer_a.output_data/consumer.input_data/
    /producer_b.output_data/consumer.input_data/
    /consumer.final_data/result_data/
  )
)

(?fsm:producer_a_src
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

(?fsm:producer_b_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (output_data> <= 8'2)
  )
  (+size
    (output_data 8)
  )
)

(?fsm:consumer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (final_data> <= input_data)
  )
  (+size
    (input_data 8)
    (final_data 8)
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

    ok($report, 'pipeline derives a composition failure report from blocked explicit-link duplicate-driver child-target failures');
    is($report->{top_name}, 'duplicate_driver_failure_summary_child', 'failure report preserves the top name for blocked explicit-link duplicate-driver child-target failures');
    is($report->{construct}, '?toplink', 'failure report preserves the explicit-link construct for blocked duplicate-driver child-target failures');
    is($report->{context_label}, 'Child endpoint', 'failure report classifies duplicate-driver child-target conflicts as child-endpoint context');
    is($report->{context_value}, "'consumer.input_data'", 'failure report preserves the conflicted child-endpoint target for duplicate-driver failures');
    is($report->{context_summary}, "Child endpoint 'consumer.input_data'", 'failure report exposes a concise duplicate-driver child-target summary');
    is($report->{blocked_boundary}, 'explicit link', 'failure report preserves the blocked explicit-link boundary for duplicate-driver child-target failures');
    is($report->{blocked_reason}, "that target is already driven by explicit link 'producer_a.output_data'", 'failure report preserves the concise duplicate-driver child-target reason');
};

subtest 'pipeline derives child-endpoint context from blocked explicit-link width-mismatch failures' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'width_mismatch_failure_summary_child.fsm');

    write_file(
        $composition_path,
        <<'FSM'
(?top:width_mismatch_failure_summary_child
  (?ports:public_io
    clk
    rstn
    result_data>4
  )
  (?fsmc:producer producer_src)
  (?fsmc:consumer consumer_src)
  (?toplink:wiring
    /producer.output_data/consumer.input_data/
    /consumer.final_data/result_data/
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

(?fsm:consumer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (final_data> <= input_data)
  )
  (+size
    (input_data 4)
    (final_data 4)
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

    ok($report, 'pipeline derives a composition failure report from blocked explicit-link width-mismatch failures');
    is($report->{top_name}, 'width_mismatch_failure_summary_child', 'failure report preserves the top name for blocked explicit-link width-mismatch failures');
    is($report->{construct}, '?toplink', 'failure report preserves the explicit-link construct for blocked width-mismatch failures');
    is($report->{context_label}, 'Child endpoint', 'failure report classifies explicit-link width mismatches as child-endpoint context');
    is($report->{context_value}, "'consumer.input_data'", 'failure report preserves the blocked child-endpoint target for width mismatches');
    is($report->{context_summary}, "Child endpoint 'consumer.input_data'", 'failure report exposes a concise explicit-link width-mismatch summary');
    is($report->{blocked_boundary}, 'explicit link', 'failure report preserves the blocked explicit-link boundary for width mismatches');
    is($report->{blocked_reason}, 'the current active composition lanes require exact width agreement', 'failure report preserves the concise explicit-link width-mismatch reason');
};

subtest 'pipeline derives top-port context from blocked explicit-link width-mismatch failures' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'width_mismatch_failure_summary_top.fsm');

    write_file(
        $composition_path,
        <<'FSM'
(?top:width_mismatch_failure_summary_top
  (?ports:public_io
    clk
    rstn
    result_data>4
  )
  (?fsmc:producer producer_src)
  (?fsmc:consumer consumer_src)
  (?toplink:wiring
    /producer.output_data/consumer.input_data/
    /consumer.final_data/result_data/
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

(?fsm:consumer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (final_data> <= input_data)
  )
  (+size
    (input_data 8)
    (final_data 8)
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

    ok($report, 'pipeline derives a composition failure report from blocked explicit-link top-port width-mismatch failures');
    is($report->{top_name}, 'width_mismatch_failure_summary_top', 'failure report preserves the top name for blocked explicit-link top-port width-mismatch failures');
    is($report->{construct}, '?toplink', 'failure report preserves the explicit-link construct for blocked top-port width-mismatch failures');
    is($report->{context_label}, 'Top port', 'failure report classifies explicit-link top-port width mismatches as top-port context');
    is($report->{context_value}, "'result_data'", 'failure report preserves the blocked top-port target for width mismatches');
    is($report->{context_summary}, "Top port 'result_data'", 'failure report exposes a concise explicit-link top-port width-mismatch summary');
    is($report->{blocked_boundary}, 'explicit link', 'failure report preserves the blocked explicit-link boundary for top-port width mismatches');
    is($report->{blocked_reason}, 'the current active composition lanes require exact width agreement', 'failure report preserves the concise explicit-link top-port width-mismatch reason');
};

subtest 'pipeline derives child-endpoint context from blocked explicit-link multi-top-output topology failures' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'multi_top_output_topology_failure_summary_top.fsm');

    write_file(
        $composition_path,
        <<'FSM'
(?top:multi_top_output_topology_failure_summary_top
  (?ports:public_io
    clk
    rstn
    result_data_a>8
    result_data_b>8
  )
  (?fsmc:producer producer_src)
  (?fsmc:consumer consumer_src)
  (?toplink:wiring
    /producer.output_data/result_data_a/
    /producer.output_data/result_data_b/
    /producer.output_data/consumer.input_data/
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

(?fsm:consumer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (final_data> <= input_data)
  )
  (+size
    (input_data 8)
    (final_data 8)
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

    ok($report, 'pipeline derives a composition failure report from blocked explicit-link multi-top-output topology failures');
    is($report->{top_name}, 'multi_top_output_topology_failure_summary_top', 'failure report preserves the top name for blocked explicit-link multi-top-output topology failures');
    is($report->{lane}, 'C2', 'failure report preserves the active C2 lane for blocked multi-top-output topology failures');
    is($report->{construct}, '?toplink', 'failure report preserves the explicit-link construct for blocked multi-top-output topology failures');
    is($report->{context_label}, 'Child endpoint', 'failure report classifies multi-top-output topology failures as child-endpoint context');
    is($report->{context_value}, "'producer.output_data'", 'failure report preserves the blocked resolved source endpoint for multi-top-output topology failures');
    is($report->{context_summary}, "Child endpoint 'producer.output_data'", 'failure report exposes a concise multi-top-output topology summary');
    is($report->{blocked_boundary}, 'explicit-link topology', 'failure report preserves the blocked explicit-link topology boundary');
    is($report->{blocked_reason}, 'the current active C2 lane supports at most one top-output target per resolved source', 'failure report preserves the concise multi-top-output topology reason');
};

subtest 'pipeline derives top-port context from blocked explicit-link top-to-top topology failures' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'top_to_top_topology_failure_summary_top.fsm');

    write_file(
        $composition_path,
        <<'FSM'
(?top:top_to_top_topology_failure_summary_top
  (?ports:public_io
    clk
    rstn
    start<8
    result_data>8
  )
  (?fsmc:producer producer_src)
  (?fsmc:consumer consumer_src)
  (?toplink:wiring
    /start/result_data/
  )
)

(?fsm:producer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (output_data> <= 8'3)
  )
  (+size
    (output_data 8)
  )
)

(?fsm:consumer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (final_data> <= 8'5)
  )
  (+size
    (final_data 8)
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

    ok($report, 'pipeline derives a composition failure report from blocked explicit-link top-to-top topology failures');
    is($report->{top_name}, 'top_to_top_topology_failure_summary_top', 'failure report preserves the top name for blocked explicit-link top-to-top topology failures');
    is($report->{lane}, 'C2', 'failure report preserves the active C2 lane for blocked top-to-top topology failures');
    is($report->{construct}, '?toplink', 'failure report preserves the explicit-link construct for blocked top-to-top topology failures');
    is($report->{context_label}, 'Top port', 'failure report classifies top-to-top topology failures as top-port context');
    is($report->{context_value}, "'start'", 'failure report preserves the blocked top-input source for top-to-top topology failures');
    is($report->{context_summary}, "Top port 'start'", 'failure report exposes a concise top-to-top topology summary');
    is($report->{blocked_boundary}, 'explicit-link topology', 'failure report preserves the blocked explicit-link topology boundary');
    is($report->{blocked_reason}, 'the current active C2 lane only supports top inputs driving child inputs', 'failure report preserves the concise top-to-top topology reason');
};

subtest 'pipeline derives explicit-endpoint context from blocked endpoint-syntax failures' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'unsupported_endpoint_failure_summary_top.fsm');

    write_file(
        $composition_path,
        <<'FSM'
(?top:unsupported_endpoint_failure_summary_top
  (?ports:public_io
    clk
    rstn
    serial_out>
  )
  (?fsmc:producer producer_src)
  (?fsmc:consumer consumer_src)
  (?toplink:wiring
    /producer.output_data.extra/serial_out/
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

(?fsm:consumer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (ack> <= 1'0)
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

    ok($report, 'pipeline derives a composition failure report from blocked unsupported-endpoint failures');
    is($report->{top_name}, 'unsupported_endpoint_failure_summary_top', 'failure report preserves the top name for blocked unsupported-endpoint failures');
    is($report->{construct}, '?toplink', 'failure report preserves the explicit-link construct for blocked unsupported-endpoint failures');
    is($report->{context_label}, 'Endpoint', 'failure report classifies unsupported explicit endpoints as endpoint context');
    is($report->{context_value}, "'producer.output_data.extra'", 'failure report preserves the unsupported explicit endpoint');
    is($report->{context_summary}, "Endpoint 'producer.output_data.extra'", 'failure report exposes a concise unsupported-endpoint summary');
    is($report->{blocked_boundary}, 'explicit link endpoint resolution', 'failure report preserves the blocked endpoint-resolution boundary for unsupported endpoints');
    is($report->{blocked_reason}, 'that syntax is unsupported', 'failure report preserves the concise unsupported-endpoint reason');
};

subtest 'pipeline derives top-endpoint context from blocked missing top-endpoint failures' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'missing_top_endpoint_failure_summary_top.fsm');

    write_file(
        $composition_path,
        <<'FSM'
(?top:missing_top_endpoint_failure_summary_top
  (?ports:public_io
    clk
    rstn
    result_data>8
  )
  (?fsmc:producer producer_src)
  (?fsmc:consumer consumer_src)
  (?toplink:wiring
    /missing_top/result_data/
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

(?fsm:consumer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (ack> <= 1'0)
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

    ok($report, 'pipeline derives a composition failure report from blocked missing-top-endpoint failures');
    is($report->{top_name}, 'missing_top_endpoint_failure_summary_top', 'failure report preserves the top name for blocked missing-top-endpoint failures');
    is($report->{construct}, '?toplink', 'failure report preserves the explicit-link construct for blocked missing-top-endpoint failures');
    is($report->{context_label}, 'Top endpoint', 'failure report classifies missing top endpoints as endpoint context');
    is($report->{context_value}, "'missing_top'", 'failure report preserves the missing top endpoint');
    is($report->{context_summary}, "Top endpoint 'missing_top'", 'failure report exposes a concise missing top-endpoint summary');
    is($report->{blocked_boundary}, 'explicit link endpoint resolution', 'failure report preserves the blocked endpoint-resolution boundary for missing top endpoints');
    is($report->{blocked_reason}, "'?ports' declares no top port with that name", 'failure report preserves the concise missing top-endpoint reason');
};

subtest 'CLI prints top-port context for blocked C1 top-port failures' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'c1_width_mismatch_failure_summary_cli_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'c1_width_mismatch_failure_summary_cli_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:c1_width_mismatch_failure_summary_cli_top
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

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, $composition_path],
    );

    ok(!$success, 'CLI fails for blocked C1 top-port mismatch fixture');
    ok(!-e $output_path, 'CLI does not emit HDL output for blocked C1 top-port mismatch fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/=== Composition Failure Summary ===/s, 'CLI prints the composition failure summary section for blocked C1 top-port failures');
    like($combined_output, qr/Construct:\s+\?ports/s, 'CLI reports the top-interface construct for blocked top-port failures');
    like($combined_output, qr/Context:\s+Top port 'output_data'/s, 'CLI reports the blocked top port as summary context');
    like($combined_output, qr/Blocked boundary:\s+C1 passthrough exposure/s, 'CLI reports the blocked C1 exposure boundary for top-port failures');
    like($combined_output, qr/Reason:\s+child port 'output_data' has width 8/s, 'CLI reports the concise top-port mismatch reason');
};

subtest 'CLI prints top-port context for blocked duplicate top-port declarations' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'duplicate_top_port_failure_summary_cli_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'duplicate_top_port_failure_summary_cli_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:duplicate_top_port_failure_summary_cli_top
  (?ports:public_io
    clk
    rstn
    output_data>8
    output_data>8
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

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, $composition_path],
    );

    ok(!$success, 'CLI fails for blocked duplicate top-port declaration fixture');
    ok(!-e $output_path, 'CLI does not emit HDL output for blocked duplicate top-port declaration fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/=== Composition Failure Summary ===/s, 'CLI prints the composition failure summary section for duplicate top-port declarations');
    like($combined_output, qr/Construct:\s+\?ports/s, 'CLI reports the top-interface construct for blocked duplicate top-port declarations');
    like($combined_output, qr/Context:\s+Top port 'output_data'/s, 'CLI reports the duplicated top port as summary context');
    like($combined_output, qr/Blocked boundary:\s+shape/s, 'CLI reports the blocked composition-shape boundary for duplicate top-port declarations');
    like($combined_output, qr/Reason:\s+the active composition lanes require each top port name to be unique/s, 'CLI reports the concise duplicate top-port reason');
};

subtest 'CLI prints child context for blocked duplicate child-instance declarations' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'duplicate_child_instance_failure_summary_cli_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'duplicate_child_instance_failure_summary_cli_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:duplicate_child_instance_failure_summary_cli_top
  (?ports:public_io
    clk
    rstn
    start
    result_data>8
  )
  (?fsmc:dup producer_src)
  (?fsmc:dup consumer_src)
  (?toplink:wiring
    /start/dup.go/
    /dup.output_data/result_data/
  )
)

(?fsm:producer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (<go
      (output_data> <= 8'2)
    )
  )
  (+size
    (go 1)
    (output_data 8)
  )
)

(?fsm:consumer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (<go
      (output_data> <= 8'3)
    )
  )
  (+size
    (go 1)
    (output_data 8)
  )
)
FSM
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, $composition_path],
    );

    ok(!$success, 'CLI fails for blocked duplicate child-instance declaration fixture');
    ok(!-e $output_path, 'CLI does not emit HDL output for blocked duplicate child-instance declaration fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/=== Composition Failure Summary ===/s, 'CLI prints the composition failure summary section for duplicate child-instance declarations');
    unlike($combined_output, qr/Construct:/s, 'CLI does not invent a construct line for duplicate child-instance declarations');
    like($combined_output, qr/Context:\s+Child 'dup'/s, 'CLI reports the duplicated child instance as summary context');
    like($combined_output, qr/Blocked boundary:\s+shape/s, 'CLI reports the blocked composition-shape boundary for duplicate child-instance declarations');
    like($combined_output, qr/Reason:\s+the active composition lanes require each realized child instance name to be unique/s, 'CLI reports the concise duplicate child-instance reason');
};

subtest 'CLI prints child-port context for blocked C1 child-port failures' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'c1_missing_exposure_failure_summary_cli_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'c1_missing_exposure_failure_summary_cli_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:c1_missing_exposure_failure_summary_cli_top
  (?ports:public_io
    clk
    rstn
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

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, $composition_path],
    );

    ok(!$success, 'CLI fails for blocked C1 child-port exposure fixture');
    ok(!-e $output_path, 'CLI does not emit HDL output for blocked C1 child-port exposure fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/=== Composition Failure Summary ===/s, 'CLI prints the composition failure summary section for blocked C1 child-port failures');
    like($combined_output, qr/Lane:\s+C1/s, 'CLI reports the C1 lane for blocked child-port failures');
    like($combined_output, qr/Context:\s+Child port 'output_data'/s, 'CLI reports the blocked child port as summary context');
    like($combined_output, qr/Blocked boundary:\s+C1 passthrough exposure/s, 'CLI reports the blocked C1 exposure boundary for child-port failures');
    like($combined_output, qr/Reason:\s+the current active C1 lane requires every child port to be explicitly exposed in '\?ports'/s, 'CLI reports the concise child-port omission reason');
};

subtest 'CLI prints composition failure lane when blocked diagnostics expose it' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'missing_rtlif_failure_summary_cli_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'missing_rtlif_failure_summary_cli_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:missing_rtlif_failure_summary_cli_top
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

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, $composition_path],
    );

    ok(!$success, 'CLI fails for blocked missing-rtlif composition fixture');
    ok(!-e $output_path, 'CLI does not emit HDL output for blocked missing-rtlif fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/=== Composition Failure Summary ===/s, 'CLI prints the composition failure summary section for missing-rtlif failures');
    like($combined_output, qr/RTL module:\s+uart_tx/s, 'CLI reports the external RTL module for missing-rtlif failures');
    like($combined_output, qr/Lane:\s+C3/s, 'CLI reports the active lane when the blocked diagnostic exposes it');
    like($combined_output, qr/Construct:\s+\?rtl/s, 'CLI reports the external RTL construct when the blocked diagnostic exposes it');
    like($combined_output, qr/Reason:\s+no declared interface metadata file 'uart_tx\.rtlif' was found/s, 'CLI reports the concise missing-rtlif reason');
};

subtest 'CLI prints the C2 lane for blocked C2 lane-selection failures' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'single_generated_explicit_link_failure_summary_cli_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'single_generated_explicit_link_failure_summary_cli_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:single_generated_explicit_link_failure_summary_cli_top
  (?ports:public_io
    clk
    rstn
    result_data>8
  )
  (?fsmc:producer producer_src)
  (?toplink:wiring
    /producer.output_data/result_data/
  )
)

(?fsm:producer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (output_data> <= 8'3)
  )
  (+size
    (output_data 8)
  )
)
FSM
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, $composition_path],
    );

    ok(!$success, 'CLI fails for blocked C2 lane-selection fixture');
    ok(!-e $output_path, 'CLI does not emit HDL output for blocked C2 lane-selection fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/=== Composition Failure Summary ===/s, 'CLI prints the composition failure summary section for blocked C2 lane-selection failures');
    like($combined_output, qr/Lane:\s+C2/s, 'CLI reports the C2 lane for blocked C2 lane-selection failures');
    like($combined_output, qr/Blocked boundary:\s+C2 lane selection/s, 'CLI reports the blocked C2 lane-selection boundary');
    like($combined_output, qr/Reason:\s+the current active C2 lane requires at least two generated child instances such as '\?fsmc' or '\?dtc'/s, 'CLI reports the concise C2 lane-selection reason');
};

subtest 'CLI prints explicit-link lane-entry summaries without inventing context' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'missing_toplink_failure_summary_cli_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'missing_toplink_failure_summary_cli_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:missing_toplink_failure_summary_cli_top
  (?ports:public_io
    clk
    rstn
    result_data>8
  )
  (?fsmc:producer producer_src)
  (?fsmc:consumer consumer_src)
)

(?fsm:producer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (output_data> <= 8'3)
  )
  (+size
    (output_data 8)
  )
)

(?fsm:consumer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (final_data> <= 8'5)
  )
  (+size
    (final_data 8)
  )
)
FSM
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, $composition_path],
    );

    ok(!$success, 'CLI fails for blocked explicit-link lane-entry fixture');
    ok(!-e $output_path, 'CLI does not emit HDL output for blocked explicit-link lane-entry fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/=== Composition Failure Summary ===/s, 'CLI prints the composition failure summary section for blocked explicit-link lane-entry failures');
    like($combined_output, qr/Lane:\s+C2/s, 'CLI reports the active C2 lane for blocked explicit-link lane-entry failures');
    like($combined_output, qr/Construct:\s+\?toplink/s, 'CLI reports the explicit-link construct for blocked lane-entry failures');
    unlike($combined_output, qr/Context:/s, 'CLI does not invent a context line for blocked explicit-link lane-entry failures');
    like($combined_output, qr/Blocked boundary:\s+explicit-link lane entry/s, 'CLI reports the blocked explicit-link lane-entry boundary');
    like($combined_output, qr/Reason:\s+the current active C2 lane requires explicit '\?toplink' wiring/s, 'CLI reports the concise explicit-link lane-entry reason');
};

subtest 'CLI prints the C4 lane and =port context for blocked declared connect-by-name failures' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'connect_by_name_unknown_failure_summary_cli_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'connect_by_name_unknown_failure_summary_cli_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:connect_by_name_unknown_failure_summary_cli_top
  (?ports:public_io
    clk
    rstn
    =missing_port>8
  )
  (?fsmc:producer producer_src)
  (?fsmc:consumer consumer_src)
  (?toplink:wiring
    /producer.output_data/consumer.input_data/
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

(?fsm:consumer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (final_data> <= input_data)
  )
  (+size
    (input_data 8)
    (final_data 8)
  )
)
FSM
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, $composition_path],
    );

    ok(!$success, 'CLI fails for blocked C4 declared connect-by-name fixture');
    ok(!-e $output_path, 'CLI does not emit HDL output for blocked C4 declared connect-by-name fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/=== Composition Failure Summary ===/s, 'CLI prints the composition failure summary section for blocked C4 declared connect-by-name failures');
    like($combined_output, qr/Lane:\s+C4/s, 'CLI reports the C4 lane for blocked declared connect-by-name failures');
    like($combined_output, qr/Construct:\s+=port/s, 'CLI reports the =port construct for blocked declared connect-by-name failures');
    like($combined_output, qr/Context:\s+Top port 'missing_port'/s, 'CLI reports the blocked =port top port as summary context');
    like($combined_output, qr/Blocked boundary:\s+declared connect-by-name/s, 'CLI reports the blocked declared connect-by-name boundary');
    like($combined_output, qr/Reason:\s+no realized child endpoint with that name exists/s, 'CLI reports the concise missing-endpoint reason for blocked declared connect-by-name failures');
};

subtest 'CLI keeps ambiguous C4 candidate lists in blocked declared connect-by-name summaries' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'connect_by_name_ambiguous_failure_summary_cli_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'connect_by_name_ambiguous_failure_summary_cli_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:connect_by_name_ambiguous_failure_summary_cli_top
  (?ports:public_io
    clk
    rstn
    =shared_status>8
  )
  (?fsmc:left left_src)
  (?fsmc:right right_src)
)

(?fsm:left_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (shared_status> <= 8'1)
  )
  (+size
    (shared_status 8)
  )
)

(?fsm:right_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (shared_status> <= 8'2)
  )
  (+size
    (shared_status 8)
  )
)
FSM
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, $composition_path],
    );

    ok(!$success, 'CLI fails for blocked ambiguous C4 declared connect-by-name fixture');
    ok(!-e $output_path, 'CLI does not emit HDL output for blocked ambiguous C4 declared connect-by-name fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/=== Composition Failure Summary ===/s, 'CLI prints the composition failure summary section for blocked ambiguous C4 declared connect-by-name failures');
    like($combined_output, qr/Lane:\s+C4/s, 'CLI reports the C4 lane for blocked ambiguous declared connect-by-name failures');
    like($combined_output, qr/Construct:\s+=port/s, 'CLI reports the =port construct for blocked ambiguous declared connect-by-name failures');
    like($combined_output, qr/Context:\s+Top port 'shared_status'/s, 'CLI reports the blocked ambiguous =port top port as summary context');
    like($combined_output, qr/Blocked boundary:\s+declared connect-by-name/s, 'CLI reports the blocked declared connect-by-name boundary for ambiguous matches');
    like($combined_output, qr/Reason:\s+that name resolves ambiguously to multiple compatible child endpoints: left\.shared_status, right\.shared_status/s, 'CLI preserves the ambiguous same-name candidate list in the concise reason');
};

subtest 'CLI keeps width-mismatch C4 endpoint sets in blocked declared connect-by-name summaries' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'connect_by_name_width_mismatch_failure_summary_cli_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'connect_by_name_width_mismatch_failure_summary_cli_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:connect_by_name_width_mismatch_failure_summary_cli_top
  (?ports:public_io
    clk
    rstn
    =final_data>4
  )
  (?fsmc:producer producer_src)
  (?fsmc:consumer consumer_src)
  (?toplink:wiring
    /producer.output_data/consumer.input_data/
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

(?fsm:consumer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (final_data> <= input_data)
  )
  (+size
    (input_data 8)
    (final_data 8)
  )
)
FSM
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, $composition_path],
    );

    ok(!$success, 'CLI fails for blocked width-mismatch C4 declared connect-by-name fixture');
    ok(!-e $output_path, 'CLI does not emit HDL output for blocked width-mismatch C4 declared connect-by-name fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/=== Composition Failure Summary ===/s, 'CLI prints the composition failure summary section for blocked width-mismatch C4 declared connect-by-name failures');
    unlike($combined_output, qr/Lane:\s+C4/s, 'CLI does not invent a C4 lane when the width-mismatch diagnostic only names the active composition lanes');
    like($combined_output, qr/Construct:\s+=port/s, 'CLI reports the =port construct for blocked width-mismatch declared connect-by-name failures');
    like($combined_output, qr/Context:\s+Top port 'final_data'/s, 'CLI reports the blocked width-mismatch =port top port as summary context');
    like($combined_output, qr/Blocked boundary:\s+declared connect-by-name/s, 'CLI reports the blocked declared connect-by-name boundary for width mismatches');
    like($combined_output, qr/Reason:\s+same-name child endpoints do not all match the declared width 4\. Seen same-name child endpoints: consumer\.final_data\[output, width=8\]/s, 'CLI preserves the conflicting same-name endpoint set in the concise width-mismatch reason');
};

subtest 'CLI keeps incompatible-direction C4 endpoint sets in blocked declared connect-by-name summaries' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'connect_by_name_direction_mismatch_failure_summary_cli_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'connect_by_name_direction_mismatch_failure_summary_cli_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:connect_by_name_direction_mismatch_failure_summary_cli_top
  (?ports:public_io
    =foo<8
    =bar>8
  )
  (?dtc:producer producer_src)
  (?dtc:consumer consumer_src)
)

(?dt:producer_src
  (-route
    (foo> = bar)
  )
  (+size
    (foo 8)
    (bar 8)
  )
)

(?dt:consumer_src
  (-route
    (bar> = foo)
  )
  (+size
    (foo 8)
    (bar 8)
  )
)
FSM
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, $composition_path],
    );

    ok(!$success, 'CLI fails for blocked incompatible-direction C4 declared connect-by-name fixture');
    ok(!-e $output_path, 'CLI does not emit HDL output for blocked incompatible-direction C4 declared connect-by-name fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/=== Composition Failure Summary ===/s, 'CLI prints the composition failure summary section for blocked incompatible-direction C4 declared connect-by-name failures');
    like($combined_output, qr/Lane:\s+C4/s, 'CLI reports the C4 lane for blocked incompatible-direction declared connect-by-name failures');
    like($combined_output, qr/Construct:\s+=port/s, 'CLI reports the =port construct for blocked incompatible-direction declared connect-by-name failures');
    like($combined_output, qr/Context:\s+Top port 'foo'/s, 'CLI reports the blocked incompatible-direction =port top port as summary context');
    like($combined_output, qr/Blocked boundary:\s+declared connect-by-name/s, 'CLI reports the blocked declared connect-by-name boundary for incompatible-direction matches');
    like($combined_output, qr/Reason:\s+same-name child endpoints include incompatible directions for a top input port\. Seen same-name child endpoints: producer\.foo\[output, width=8\], consumer\.foo\[input, width=8\]/s, 'CLI preserves the conflicting same-name endpoint set in the concise incompatible-direction reason');
};

subtest 'CLI keeps shared-system-port C4 failures concise without inventing a lane' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'system_byname_failure_summary_cli_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'system_byname_failure_summary_cli_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:system_byname_failure_summary_cli_top
  (?ports:public_io
    =clk
    result_data>8
  )
  (?fsmc:child child_src)
)

(?fsm:child_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (result_data> <= 8'1)
  )
  (+size
    (result_data 8)
  )
)
FSM
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, $composition_path],
    );

    ok(!$success, 'CLI fails for blocked shared-system-port declared connect-by-name fixture');
    ok(!-e $output_path, 'CLI does not emit HDL output for blocked shared-system-port declared connect-by-name fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/=== Composition Failure Summary ===/s, 'CLI prints the composition failure summary section for blocked shared-system-port declared connect-by-name failures');
    unlike($combined_output, qr/Lane:\s+C4/s, 'CLI does not invent a C4 lane for shared-system-port failures that do not name one');
    like($combined_output, qr/Construct:\s+=port/s, 'CLI reports the =port construct for blocked shared-system-port declared connect-by-name failures');
    like($combined_output, qr/Context:\s+Top port 'clk'/s, 'CLI reports the blocked shared-system top port as summary context');
    like($combined_output, qr/Blocked boundary:\s+declared connect-by-name/s, 'CLI reports the blocked declared connect-by-name boundary for shared-system-port failures');
    like($combined_output, qr/Reason:\s+the shared system ports '.*' already use the dedicated system-input contract and must not be declared with '=port' connect-by-name syntax/s, 'CLI preserves the concise shared-system-port reason');
};

subtest 'CLI prints RTL metadata file artifacts for blocked metadata-structure failures' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'bad_rtlif_root_failure_summary_cli_top.fsm');
    my $metadata_path = File::Spec->catfile($tempdir, 'uart_tx.rtlif');
    my $output_path = File::Spec->catfile($tempdir, 'bad_rtlif_root_failure_summary_cli_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:bad_rtlif_root_failure_summary_cli_top
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

    write_file(
        $metadata_path,
        <<'FSM'
(?rtlif:wrong_uart
  data_in<8:data
  txd>:data
)
FSM
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, $composition_path],
    );

    ok(!$success, 'CLI fails for blocked rtl metadata-structure composition fixture');
    ok(!-e $output_path, 'CLI does not emit HDL output for blocked rtl metadata-structure fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/=== Composition Failure Summary ===/s, 'CLI prints the composition failure summary section for blocked rtl metadata-structure failures');
    like($combined_output, qr/RTL module:\s+uart_tx/s, 'CLI reports the external RTL module for blocked rtl metadata-structure failures');
    like($combined_output, qr/Construct:\s+\?rtl/s, 'CLI reports the external RTL construct for blocked rtl metadata-structure failures');
    like($combined_output, qr/RTL metadata file:\s+'\Q$metadata_path\E'/s, 'CLI reports the resolved rtlif file path');
    like($combined_output, qr/Context:\s+RTL root '\?rtlif:uart_tx'/s, 'CLI reports the missing rtlif root token alongside the rtlif file artifact');
    like($combined_output, qr/Blocked boundary:\s+RTL interface metadata structure/s, 'CLI reports the blocked rtlif structure boundary');
    like($combined_output, qr/Reason:\s+does not contain a '\?rtlif:uart_tx' root/s, 'CLI reports the concise rtlif structure reason');
};

subtest 'CLI prints rtl root context alongside RTL metadata file artifacts for blocked empty-port failures' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'empty_port_failure_summary_cli_top.fsm');
    my $metadata_path = File::Spec->catfile($tempdir, 'uart_tx.rtlif');
    my $output_path = File::Spec->catfile($tempdir, 'empty_port_failure_summary_cli_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:empty_port_failure_summary_cli_top
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

    write_file(
        $metadata_path,
        <<'RTLIF'
(?rtlif:uart_tx)
RTLIF
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, $composition_path],
    );

    ok(!$success, 'CLI fails for blocked empty-port rtlif composition fixture');
    ok(!-e $output_path, 'CLI does not emit HDL output for blocked empty-port rtlif fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/=== Composition Failure Summary ===/s, 'CLI prints the composition failure summary section for blocked rtlif empty-port failures');
    like($combined_output, qr/RTL module:\s+uart_tx/s, 'CLI reports the external RTL module for blocked rtlif empty-port failures');
    like($combined_output, qr/Construct:\s+\?rtl/s, 'CLI reports the external RTL construct for blocked rtlif empty-port failures');
    like($combined_output, qr/RTL metadata file:\s+'\Q$metadata_path\E'/s, 'CLI reports the resolved rtlif file path for blocked rtlif empty-port failures');
    like($combined_output, qr/Context:\s+RTL root '\?rtlif:uart_tx'/s, 'CLI keeps rtlif root context alongside the rtlif file artifact for empty-port failures');
    like($combined_output, qr/Blocked boundary:\s+RTL interface metadata port presence/s, 'CLI reports the blocked rtlif empty-port boundary');
    like($combined_output, qr/Reason:\s+declares no ports under '\?rtlif:uart_tx'/s, 'CLI reports the concise rtlif empty-port reason without repeating the metadata file path');
};

subtest 'CLI prints rtl root context alongside RTL metadata file artifacts for blocked flatness failures' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'nested_rtlif_failure_summary_cli_top.fsm');
    my $metadata_path = File::Spec->catfile($tempdir, 'uart_tx.rtlif');
    my $output_path = File::Spec->catfile($tempdir, 'nested_rtlif_failure_summary_cli_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:nested_rtlif_failure_summary_cli_top
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

    write_file(
        $metadata_path,
        <<'RTLIF'
(?rtlif:uart_tx
  clk:clock
  rstn:reset
  (group
    data_in<8:data
  )
  txd>:data
)
RTLIF
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, $composition_path],
    );

    ok(!$success, 'CLI fails for blocked rtlif flatness composition fixture');
    ok(!-e $output_path, 'CLI does not emit HDL output for blocked rtlif flatness fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/=== Composition Failure Summary ===/s, 'CLI prints the composition failure summary section for blocked rtlif flatness failures');
    like($combined_output, qr/RTL module:\s+uart_tx/s, 'CLI reports the external RTL module for blocked rtlif flatness failures');
    like($combined_output, qr/Construct:\s+\?rtl/s, 'CLI reports the external RTL construct for blocked rtlif flatness failures');
    like($combined_output, qr/RTL metadata file:\s+'\Q$metadata_path\E'/s, 'CLI reports the resolved rtlif file path for blocked rtlif flatness failures');
    like($combined_output, qr/Context:\s+RTL root '\?rtlif:uart_tx'/s, 'CLI keeps rtlif root context alongside the rtlif file artifact for flatness failures');
    like($combined_output, qr/Blocked boundary:\s+RTL interface metadata flatness/s, 'CLI reports the blocked rtlif flatness boundary');
    like($combined_output, qr/Reason:\s+contains nested structure under '\?rtlif:uart_tx'/s, 'CLI reports the concise rtlif flatness reason without repeating the metadata file path');
};

subtest 'CLI prints token context alongside RTL metadata file artifacts for blocked token failures' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'invalid_token_failure_summary_cli_top.fsm');
    my $metadata_path = File::Spec->catfile($tempdir, 'uart_tx.rtlif');
    my $output_path = File::Spec->catfile($tempdir, 'invalid_token_failure_summary_cli_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:invalid_token_failure_summary_cli_top
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

    write_file(
        $metadata_path,
        <<'RTLIF'
(?rtlif:uart_tx
  clk:clock
  rstn:reset
  data-in<8:data
  txd>:data
)
RTLIF
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, $composition_path],
    );

    ok(!$success, 'CLI fails for blocked rtlif token composition fixture');
    ok(!-e $output_path, 'CLI does not emit HDL output for blocked rtlif token fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/=== Composition Failure Summary ===/s, 'CLI prints the composition failure summary section for blocked rtlif token failures');
    like($combined_output, qr/RTL module:\s+uart_tx/s, 'CLI reports the external RTL module for blocked rtlif token failures');
    like($combined_output, qr/Construct:\s+\?rtl/s, 'CLI reports the external RTL construct for blocked rtlif token failures');
    like($combined_output, qr/RTL metadata file:\s+'\Q$metadata_path\E'/s, 'CLI reports the resolved rtlif file path for blocked rtlif token failures');
    like($combined_output, qr/Context:\s+Token 'data-in<8:data'/s, 'CLI keeps token context alongside the rtlif file artifact');
    like($combined_output, qr/Blocked boundary:\s+RTL interface metadata token shape/s, 'CLI reports the blocked rtlif token boundary');
    like($combined_output, qr/Reason:\s+token 'data-in<8:data' is an invalid port token for the current '\.rtlif' contract/s, 'CLI reports the concise rtlif token reason without repeating the metadata file path');
};

subtest 'CLI prints token context alongside RTL metadata file artifacts for blocked width failures' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'invalid_width_failure_summary_cli_top.fsm');
    my $metadata_path = File::Spec->catfile($tempdir, 'uart_tx.rtlif');
    my $output_path = File::Spec->catfile($tempdir, 'invalid_width_failure_summary_cli_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:invalid_width_failure_summary_cli_top
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

    write_file(
        $metadata_path,
        <<'RTLIF'
(?rtlif:uart_tx
  clk:clock
  rstn:reset
  data_in<0:data
  txd>:data
)
RTLIF
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, $composition_path],
    );

    ok(!$success, 'CLI fails for blocked rtlif width composition fixture');
    ok(!-e $output_path, 'CLI does not emit HDL output for blocked rtlif width fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/=== Composition Failure Summary ===/s, 'CLI prints the composition failure summary section for blocked rtlif width failures');
    like($combined_output, qr/RTL module:\s+uart_tx/s, 'CLI reports the external RTL module for blocked rtlif width failures');
    like($combined_output, qr/Construct:\s+\?rtl/s, 'CLI reports the external RTL construct for blocked rtlif width failures');
    like($combined_output, qr/RTL metadata file:\s+'\Q$metadata_path\E'/s, 'CLI reports the resolved rtlif file path for blocked rtlif width failures');
    like($combined_output, qr/Context:\s+Token 'data_in<0:data'/s, 'CLI keeps token context alongside the rtlif file artifact for width failures');
    like($combined_output, qr/Blocked boundary:\s+RTL interface metadata port sizing/s, 'CLI reports the blocked rtlif width boundary');
    like($combined_output, qr/Reason:\s+token 'data_in<0:data' declares non-positive port width '0'/s, 'CLI reports the concise rtlif width reason without repeating the metadata file path');
};

subtest 'CLI prints token context alongside RTL metadata file artifacts for blocked type failures' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'invalid_type_failure_summary_cli_top.fsm');
    my $metadata_path = File::Spec->catfile($tempdir, 'uart_tx.rtlif');
    my $output_path = File::Spec->catfile($tempdir, 'invalid_type_failure_summary_cli_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:invalid_type_failure_summary_cli_top
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

    write_file(
        $metadata_path,
        <<'RTLIF'
(?rtlif:uart_tx
  clk:clock
  rstn:reset
  data_in<8:status
  txd>:data
)
RTLIF
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, $composition_path],
    );

    ok(!$success, 'CLI fails for blocked rtlif type composition fixture');
    ok(!-e $output_path, 'CLI does not emit HDL output for blocked rtlif type fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/=== Composition Failure Summary ===/s, 'CLI prints the composition failure summary section for blocked rtlif type failures');
    like($combined_output, qr/RTL module:\s+uart_tx/s, 'CLI reports the external RTL module for blocked rtlif type failures');
    like($combined_output, qr/Construct:\s+\?rtl/s, 'CLI reports the external RTL construct for blocked rtlif type failures');
    like($combined_output, qr/RTL metadata file:\s+'\Q$metadata_path\E'/s, 'CLI reports the resolved rtlif file path for blocked rtlif type failures');
    like($combined_output, qr/Context:\s+Token 'data_in<8:status'/s, 'CLI keeps token context alongside the rtlif file artifact for type failures');
    like($combined_output, qr/Blocked boundary:\s+RTL interface metadata port typing/s, 'CLI reports the blocked rtlif type boundary');
    like($combined_output, qr/Reason:\s+token 'data_in<8:status' resolves to unsupported port type 'status'/s, 'CLI reports the concise rtlif type reason without repeating the metadata file path');
};

subtest 'CLI prints rtl port context alongside RTL metadata file artifacts for blocked duplicate-port failures' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'duplicate_port_failure_summary_cli_top.fsm');
    my $metadata_path = File::Spec->catfile($tempdir, 'uart_tx.rtlif');
    my $output_path = File::Spec->catfile($tempdir, 'duplicate_port_failure_summary_cli_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:duplicate_port_failure_summary_cli_top
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

    write_file(
        $metadata_path,
        <<'RTLIF'
(?rtlif:uart_tx
  clk:clock
  rstn:reset
  data_in<8:data
  txd>:data
  txd>:data
)
RTLIF
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, $composition_path],
    );

    ok(!$success, 'CLI fails for blocked rtlif duplicate-port composition fixture');
    ok(!-e $output_path, 'CLI does not emit HDL output for blocked rtlif duplicate-port fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/=== Composition Failure Summary ===/s, 'CLI prints the composition failure summary section for blocked rtlif duplicate-port failures');
    like($combined_output, qr/RTL module:\s+uart_tx/s, 'CLI reports the external RTL module for blocked rtlif duplicate-port failures');
    like($combined_output, qr/Construct:\s+\?rtl/s, 'CLI reports the external RTL construct for blocked rtlif duplicate-port failures');
    like($combined_output, qr/RTL metadata file:\s+'\Q$metadata_path\E'/s, 'CLI reports the resolved rtlif file path for blocked rtlif duplicate-port failures');
    like($combined_output, qr/Context:\s+RTL port 'txd'/s, 'CLI keeps repeated rtlif port context alongside the rtlif file artifact');
    like($combined_output, qr/Blocked boundary:\s+RTL interface metadata port declaration uniqueness/s, 'CLI reports the blocked rtlif duplicate-port boundary');
    like($combined_output, qr/Reason:\s+repeats port 'txd'/s, 'CLI reports the concise rtlif duplicate-port reason without repeating the metadata file path');
};

subtest 'CLI prints rtl root context for blocked embedded-root uniqueness failures' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'duplicate_embedded_root_failure_summary_cli_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'duplicate_embedded_root_failure_summary_cli_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:duplicate_embedded_root_failure_summary_cli_top
  (?ports:public_io
    clk
    rst_n
    serial_out>
  )
  (?dtc:router route_src)
  (?rtl:uart_tx)
  (?toplink:wiring
    /router.route_data/uart_tx.data_in/
    /uart_tx.txd/serial_out/
  )
)

(?dt:route_src
  (-route
    (route_data> = payload_in)
  )
  (+size
    (payload_in 8)
    (route_data 8)
  )
)

(?rtlif:uart_tx
  clk:clock
  rst_n:reset
  data_in<8:data
  txd>:data
)

(?rtlif:uart_tx
  clk
  rst_n
  txd>
)
FSM
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, $composition_path],
    );

    ok(!$success, 'CLI fails for blocked embedded rtlif duplicate-root composition fixture');
    ok(!-e $output_path, 'CLI does not emit HDL output for blocked embedded rtlif duplicate-root fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/=== Composition Failure Summary ===/s, 'CLI prints the composition failure summary section for blocked embedded rtlif duplicate-root failures');
    like($combined_output, qr/Construct:\s+\?rtl/s, 'CLI reports the external RTL construct for blocked embedded rtlif duplicate-root failures');
    unlike($combined_output, qr/RTL metadata file:/s, 'CLI does not invent an external metadata artifact line for embedded rtlif duplicate-root failures');
    like($combined_output, qr/Context:\s+RTL root '\?rtlif:uart_tx'/s, 'CLI reports the duplicate embedded rtlif root as summary context');
    like($combined_output, qr/Blocked boundary:\s+RTL interface metadata embedded-root uniqueness/s, 'CLI reports the blocked embedded-root uniqueness boundary');
    like($combined_output, qr/Reason:\s+the active RTL interface contract allows at most one embedded interface root per external RTL module name in the same source/s, 'CLI reports the concise embedded-root uniqueness reason');
};

subtest 'CLI prints child-source file context for blocked generated-child realization failures' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'wrong_fsmc_kind_failure_summary_cli_top.fsm');
    my $child_path = File::Spec->catfile($tempdir, 'route_src.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'wrong_fsmc_kind_failure_summary_cli_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:wrong_fsmc_kind_failure_summary_cli_top
  (?ports:public_io
    data_in<8
    route_data>8
  )
  (?fsmc:router route_src)
)
FSM
    );

    write_file(
        $child_path,
        <<'FSM'
(?dt:route_src
  (-route
    (route_data> = data_in)
  )
  (+size
    (data_in 8)
    (route_data 8)
  )
)
FSM
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, $composition_path],
    );

    ok(!$success, 'CLI fails for blocked wrong-kind generated-child composition fixture');
    ok(!-e $output_path, 'CLI does not emit HDL output for blocked wrong-kind generated-child fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/=== Composition Failure Summary ===/s, 'CLI prints the composition failure summary section for blocked generated-child realization failures');
    like($combined_output, qr/Top:\s+wrong_fsmc_kind_failure_summary_cli_top/s, 'CLI reports the failing top for blocked generated-child realization failures');
    like($combined_output, qr/Construct:\s+\?fsmc/s, 'CLI reports the generated-child construct for blocked generated-child realization failures');
    like($combined_output, qr/Child source file:\s+'\Q$child_path\E'/s, 'CLI reports the resolved generated-child file path');
    like($combined_output, qr/Context:\s+Child 'route_src'/s, 'CLI reports the generated-child source name as context');
    like($combined_output, qr/Blocked boundary:\s+child-source realization/s, 'CLI reports the blocked generated-child realization boundary');
    like($combined_output, qr/Reason:\s+that resolved file is not an active FSM child source \(detected root '\?dt:route_src'\)/s, 'CLI reports the concise blocked generated-child reason');
};

subtest 'CLI prints endpoint context for blocked explicit-link endpoint failures' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'missing_child_endpoint_failure_summary_cli_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'missing_child_endpoint_failure_summary_cli_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:missing_child_endpoint_failure_summary_cli_top
  (?ports:public_io
    clk
    rstn
    serial_out>
  )
  (?fsmc:producer producer_src)
  (?fsmc:consumer consumer_src)
  (?toplink:wiring
    /missing.output_data/serial_out/
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

(?fsm:consumer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (ack> <= 1'0)
  )
)
FSM
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, $composition_path],
    );

    ok(!$success, 'CLI fails for blocked missing-child-endpoint composition fixture');
    ok(!-e $output_path, 'CLI does not emit HDL output for blocked missing-child-endpoint fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/=== Composition Failure Summary ===/s, 'CLI prints the composition failure summary section for missing child endpoints');
    like($combined_output, qr/Construct:\s+\?toplink/s, 'CLI reports the explicit-link construct for blocked child-endpoint failures');
    like($combined_output, qr/Context:\s+Child endpoint 'missing\.output_data'/s, 'CLI reports the missing child endpoint as summary context');
    like($combined_output, qr/Blocked boundary:\s+explicit link endpoint resolution/s, 'CLI reports the blocked explicit-link endpoint boundary');
    like($combined_output, qr/Reason:\s+no realized child instance named 'missing' exists/s, 'CLI reports the concise missing child-instance reason');
};

subtest 'CLI prints unsupported explicit-endpoint syntax in blocked explicit-link summaries' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'unsupported_endpoint_failure_summary_cli_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'unsupported_endpoint_failure_summary_cli_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:unsupported_endpoint_failure_summary_cli_top
  (?ports:public_io
    clk
    rstn
    result_data>8
  )
  (?fsmc:producer producer_src)
  (?fsmc:consumer consumer_src)
  (?toplink:wiring
    /producer.output_data.extra/result_data/
  )
)

(?fsm:producer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (output_data> <= 8'2)
  )
  (+size
    (output_data 8)
  )
)

(?fsm:consumer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (final_data> <= 8'3)
  )
  (+size
    (final_data 8)
  )
)
FSM
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, $composition_path],
    );

    ok(!$success, 'CLI fails for blocked unsupported-explicit-endpoint composition fixture');
    ok(!-e $output_path, 'CLI does not emit HDL output for blocked unsupported-explicit-endpoint fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/=== Composition Failure Summary ===/s, 'CLI prints the composition failure summary section for unsupported explicit endpoints');
    like($combined_output, qr/Construct:\s+\?toplink/s, 'CLI reports the explicit-link construct for blocked unsupported-endpoint failures');
    like($combined_output, qr/Context:\s+Endpoint 'producer\.output_data\.extra'/s, 'CLI reports the unsupported explicit endpoint as summary context');
    like($combined_output, qr/Blocked boundary:\s+explicit link endpoint resolution/s, 'CLI reports the blocked explicit-link endpoint boundary for unsupported endpoint syntax');
    like($combined_output, qr/Reason:\s+that syntax is unsupported/s, 'CLI reports the concise unsupported-endpoint reason');
};

subtest 'CLI prints existing-instance missing-port context in blocked explicit-link summaries' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'missing_child_port_failure_summary_cli_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'missing_child_port_failure_summary_cli_top.sv');
    my $rtl_metadata_path = File::Spec->catfile($tempdir, 'uart_tx.rtlif');

    write_file(
        $composition_path,
        <<'FSM'
(?top:missing_child_port_failure_summary_cli_top
  (?ports:public_io
    clk
    rstn
    serial_out>
  )
  (?fsmc:producer producer_src)
  (?rtl:uart_tx)
  (?toplink:wiring
    /producer.output_data/uart_tx.missing_port/
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

    write_file(
        $rtl_metadata_path,
        <<'RTLIF'
(?rtlif:uart_tx
  clk
  rstn
  data_in<8:data
  txd>:data
)
RTLIF
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, $composition_path],
    );

    ok(!$success, 'CLI fails for blocked existing-instance missing-port composition fixture');
    ok(!-e $output_path, 'CLI does not emit HDL output for blocked existing-instance missing-port fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/=== Composition Failure Summary ===/s, 'CLI prints the composition failure summary section for existing-instance missing-port failures');
    like($combined_output, qr/Construct:\s+\?toplink/s, 'CLI reports the explicit-link construct for blocked existing-instance missing-port failures');
    like($combined_output, qr/Context:\s+Child endpoint 'uart_tx\.missing_port'/s, 'CLI reports the missing child endpoint on the existing instance as summary context');
    like($combined_output, qr/Blocked boundary:\s+explicit link endpoint resolution/s, 'CLI reports the blocked explicit-link endpoint boundary for existing-instance missing-port failures');
    like($combined_output, qr/Reason:\s+instance 'uart_tx' has no port named 'missing_port'/s, 'CLI reports the concise existing-instance missing-port reason');
};

subtest 'CLI prints child-endpoint context for blocked explicit-link direction-mismatch summaries' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'direction_mismatch_failure_summary_cli_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'direction_mismatch_failure_summary_cli_top.sv');
    my $rtl_metadata_path = File::Spec->catfile($tempdir, 'uart_tx.rtlif');

    write_file(
        $composition_path,
        <<'FSM'
(?top:direction_mismatch_failure_summary_cli_top
  (?ports:public_io
    clk
    rstn
  )
  (?fsmc:producer producer_src)
  (?rtl:uart_tx)
  (?toplink:wiring
    /producer.output_data/uart_tx.txd/
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

    write_file(
        $rtl_metadata_path,
        <<'RTLIF'
(?rtlif:uart_tx
  clk
  rstn
  data_in<8:data
  txd>:data
)
RTLIF
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, $composition_path],
    );

    ok(!$success, 'CLI fails for blocked explicit-link direction-mismatch composition fixture');
    ok(!-e $output_path, 'CLI does not emit HDL output for blocked explicit-link direction-mismatch fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/=== Composition Failure Summary ===/s, 'CLI prints the composition failure summary section for explicit-link direction-mismatch failures');
    like($combined_output, qr/Construct:\s+\?toplink/s, 'CLI reports the explicit-link construct for blocked direction-mismatch failures');
    like($combined_output, qr/Context:\s+Child endpoint 'uart_tx\.txd'/s, 'CLI reports the blocked child endpoint as summary context for direction-mismatch failures');
    like($combined_output, qr/Blocked boundary:\s+explicit link/s, 'CLI reports the blocked explicit-link boundary for direction-mismatch failures');
    like($combined_output, qr/Reason:\s+that child port is output instead of input/s, 'CLI reports the concise direction-mismatch reason');
};

subtest 'CLI prints top-port context for blocked explicit-link top-port role mismatches' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'top_port_direction_mismatch_failure_summary_cli_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'top_port_direction_mismatch_failure_summary_cli_top.sv');
    my $rtl_metadata_path = File::Spec->catfile($tempdir, 'uart_tx.rtlif');

    write_file(
        $composition_path,
        <<'FSM'
(?top:top_port_direction_mismatch_failure_summary_cli_top
  (?ports:public_io
    clk
    rstn
    result_data>8
  )
  (?fsmc:producer producer_src)
  (?rtl:uart_tx)
  (?toplink:wiring
    /result_data/uart_tx.data_in/
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

    write_file(
        $rtl_metadata_path,
        <<'RTLIF'
(?rtlif:uart_tx
  clk
  rstn
  data_in<8:data
  txd>:data
)
RTLIF
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, $composition_path],
    );

    ok(!$success, 'CLI fails for blocked explicit-link top-port role-mismatch fixture');
    ok(!-e $output_path, 'CLI does not emit HDL output for blocked explicit-link top-port role-mismatch fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/=== Composition Failure Summary ===/s, 'CLI prints the composition failure summary section for explicit-link top-port role mismatches');
    like($combined_output, qr/Construct:\s+\?toplink/s, 'CLI reports the explicit-link construct for blocked top-port role mismatches');
    like($combined_output, qr/Context:\s+Top port 'result_data'/s, 'CLI reports the blocked top port as summary context for top-port role mismatches');
    like($combined_output, qr/Blocked boundary:\s+explicit link/s, 'CLI reports the blocked explicit-link boundary for top-port role mismatches');
    like($combined_output, qr/Reason:\s+that top port is declared as output instead of input/s, 'CLI reports the concise top-port role-mismatch reason');
};

subtest 'CLI prints top-port context for blocked explicit-link duplicate-driver summaries' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'duplicate_driver_failure_summary_cli_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'duplicate_driver_failure_summary_cli_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:duplicate_driver_failure_summary_cli_top
  (?ports:public_io
    clk
    rstn
    result_data>8
  )
  (?fsmc:producer_a producer_a_src)
  (?fsmc:producer_b producer_b_src)
  (?toplink:wiring
    /producer_a.output_data/result_data/
    /producer_b.output_data/result_data/
  )
)

(?fsm:producer_a_src
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

(?fsm:producer_b_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (output_data> <= 8'2)
  )
  (+size
    (output_data 8)
  )
)
FSM
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, $composition_path],
    );

    ok(!$success, 'CLI fails for blocked explicit-link duplicate-driver fixture');
    ok(!-e $output_path, 'CLI does not emit HDL output for blocked explicit-link duplicate-driver fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/=== Composition Failure Summary ===/s, 'CLI prints the composition failure summary section for explicit-link duplicate-driver failures');
    like($combined_output, qr/Construct:\s+\?toplink/s, 'CLI reports the explicit-link construct for blocked duplicate-driver failures');
    like($combined_output, qr/Context:\s+Top port 'result_data'/s, 'CLI reports the conflicted top-port target as summary context for duplicate-driver failures');
    like($combined_output, qr/Blocked boundary:\s+explicit link/s, 'CLI reports the blocked explicit-link boundary for duplicate-driver failures');
    like($combined_output, qr/Reason:\s+that target is already driven by explicit link 'producer_a\.output_data'/s, 'CLI reports the concise duplicate-driver reason');
};

subtest 'CLI prints child-endpoint context for blocked explicit-link duplicate-driver summaries' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'duplicate_driver_failure_summary_cli_child.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'duplicate_driver_failure_summary_cli_child.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:duplicate_driver_failure_summary_cli_child
  (?ports:public_io
    clk
    rstn
    result_data>8
  )
  (?fsmc:producer_a producer_a_src)
  (?fsmc:producer_b producer_b_src)
  (?fsmc:consumer consumer_src)
  (?toplink:wiring
    /producer_a.output_data/consumer.input_data/
    /producer_b.output_data/consumer.input_data/
    /consumer.final_data/result_data/
  )
)

(?fsm:producer_a_src
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

(?fsm:producer_b_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (output_data> <= 8'2)
  )
  (+size
    (output_data 8)
  )
)

(?fsm:consumer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (final_data> <= input_data)
  )
  (+size
    (input_data 8)
    (final_data 8)
  )
)
FSM
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, $composition_path],
    );

    ok(!$success, 'CLI fails for blocked explicit-link duplicate-driver child-target fixture');
    ok(!-e $output_path, 'CLI does not emit HDL output for blocked explicit-link duplicate-driver child-target fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/=== Composition Failure Summary ===/s, 'CLI prints the composition failure summary section for explicit-link duplicate-driver child-target failures');
    like($combined_output, qr/Construct:\s+\?toplink/s, 'CLI reports the explicit-link construct for blocked duplicate-driver child-target failures');
    like($combined_output, qr/Context:\s+Child endpoint 'consumer\.input_data'/s, 'CLI reports the conflicted child-endpoint target as summary context for duplicate-driver failures');
    like($combined_output, qr/Blocked boundary:\s+explicit link/s, 'CLI reports the blocked explicit-link boundary for duplicate-driver child-target failures');
    like($combined_output, qr/Reason:\s+that target is already driven by explicit link 'producer_a\.output_data'/s, 'CLI reports the concise duplicate-driver child-target reason');
};

subtest 'CLI prints child-endpoint context for blocked explicit-link width-mismatch summaries' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'width_mismatch_failure_summary_cli_child.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'width_mismatch_failure_summary_cli_child.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:width_mismatch_failure_summary_cli_child
  (?ports:public_io
    clk
    rstn
    result_data>4
  )
  (?fsmc:producer producer_src)
  (?fsmc:consumer consumer_src)
  (?toplink:wiring
    /producer.output_data/consumer.input_data/
    /consumer.final_data/result_data/
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

(?fsm:consumer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (final_data> <= input_data)
  )
  (+size
    (input_data 4)
    (final_data 4)
  )
)
FSM
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, $composition_path],
    );

    ok(!$success, 'CLI fails for blocked explicit-link width-mismatch fixture');
    ok(!-e $output_path, 'CLI does not emit HDL output for blocked explicit-link width-mismatch fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/=== Composition Failure Summary ===/s, 'CLI prints the composition failure summary section for explicit-link width-mismatch failures');
    like($combined_output, qr/Construct:\s+\?toplink/s, 'CLI reports the explicit-link construct for blocked width-mismatch failures');
    like($combined_output, qr/Context:\s+Child endpoint 'consumer\.input_data'/s, 'CLI reports the blocked child-endpoint target as summary context for width mismatches');
    like($combined_output, qr/Blocked boundary:\s+explicit link/s, 'CLI reports the blocked explicit-link boundary for width-mismatch failures');
    like($combined_output, qr/Reason:\s+the current active composition lanes require exact width agreement/s, 'CLI reports the concise explicit-link width-mismatch reason');
};

subtest 'CLI prints top-port context for blocked explicit-link width-mismatch summaries' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'width_mismatch_failure_summary_cli_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'width_mismatch_failure_summary_cli_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:width_mismatch_failure_summary_cli_top
  (?ports:public_io
    clk
    rstn
    result_data>4
  )
  (?fsmc:producer producer_src)
  (?fsmc:consumer consumer_src)
  (?toplink:wiring
    /producer.output_data/consumer.input_data/
    /consumer.final_data/result_data/
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

(?fsm:consumer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (final_data> <= input_data)
  )
  (+size
    (input_data 8)
    (final_data 8)
  )
)
FSM
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, $composition_path],
    );

    ok(!$success, 'CLI fails for blocked explicit-link top-port width-mismatch fixture');
    ok(!-e $output_path, 'CLI does not emit HDL output for blocked explicit-link top-port width-mismatch fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/=== Composition Failure Summary ===/s, 'CLI prints the composition failure summary section for explicit-link top-port width-mismatch failures');
    like($combined_output, qr/Construct:\s+\?toplink/s, 'CLI reports the explicit-link construct for blocked top-port width-mismatch failures');
    like($combined_output, qr/Context:\s+Top port 'result_data'/s, 'CLI reports the blocked top-port target as summary context for width mismatches');
    like($combined_output, qr/Blocked boundary:\s+explicit link/s, 'CLI reports the blocked explicit-link boundary for top-port width-mismatch failures');
    like($combined_output, qr/Reason:\s+the current active composition lanes require exact width agreement/s, 'CLI reports the concise explicit-link top-port width-mismatch reason');
};

subtest 'CLI prints child-endpoint context for blocked explicit-link multi-top-output topology summaries' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'multi_top_output_topology_failure_summary_cli_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'multi_top_output_topology_failure_summary_cli_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:multi_top_output_topology_failure_summary_cli_top
  (?ports:public_io
    clk
    rstn
    result_data_a>8
    result_data_b>8
  )
  (?fsmc:producer producer_src)
  (?fsmc:consumer consumer_src)
  (?toplink:wiring
    /producer.output_data/result_data_a/
    /producer.output_data/result_data_b/
    /producer.output_data/consumer.input_data/
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

(?fsm:consumer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (final_data> <= input_data)
  )
  (+size
    (input_data 8)
    (final_data 8)
  )
)
FSM
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, $composition_path],
    );

    ok(!$success, 'CLI fails for blocked explicit-link multi-top-output topology fixture');
    ok(!-e $output_path, 'CLI does not emit HDL output for blocked explicit-link multi-top-output topology fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/=== Composition Failure Summary ===/s, 'CLI prints the composition failure summary section for explicit-link multi-top-output topology failures');
    like($combined_output, qr/Lane:\s+C2/s, 'CLI reports the active C2 lane for blocked multi-top-output topology failures');
    like($combined_output, qr/Construct:\s+\?toplink/s, 'CLI reports the explicit-link construct for blocked multi-top-output topology failures');
    like($combined_output, qr/Context:\s+Child endpoint 'producer\.output_data'/s, 'CLI reports the blocked resolved source endpoint as summary context for multi-top-output topology failures');
    like($combined_output, qr/Blocked boundary:\s+explicit-link topology/s, 'CLI reports the blocked explicit-link topology boundary');
    like($combined_output, qr/Reason:\s+the current active C2 lane supports at most one top-output target per resolved source/s, 'CLI reports the concise multi-top-output topology reason');
};

subtest 'CLI prints top-port context for blocked explicit-link top-to-top topology summaries' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'top_to_top_topology_failure_summary_cli_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'top_to_top_topology_failure_summary_cli_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:top_to_top_topology_failure_summary_cli_top
  (?ports:public_io
    clk
    rstn
    start<8
    result_data>8
  )
  (?fsmc:producer producer_src)
  (?fsmc:consumer consumer_src)
  (?toplink:wiring
    /start/result_data/
  )
)

(?fsm:producer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (output_data> <= 8'3)
  )
  (+size
    (output_data 8)
  )
)

(?fsm:consumer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (final_data> <= 8'5)
  )
  (+size
    (final_data 8)
  )
)
FSM
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, $composition_path],
    );

    ok(!$success, 'CLI fails for blocked explicit-link top-to-top topology fixture');
    ok(!-e $output_path, 'CLI does not emit HDL output for blocked explicit-link top-to-top topology fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/=== Composition Failure Summary ===/s, 'CLI prints the composition failure summary section for explicit-link top-to-top topology failures');
    like($combined_output, qr/Lane:\s+C2/s, 'CLI reports the active C2 lane for blocked top-to-top topology failures');
    like($combined_output, qr/Construct:\s+\?toplink/s, 'CLI reports the explicit-link construct for blocked top-to-top topology failures');
    like($combined_output, qr/Context:\s+Top port 'start'/s, 'CLI reports the blocked top-input source as summary context for top-to-top topology failures');
    like($combined_output, qr/Blocked boundary:\s+explicit-link topology/s, 'CLI reports the blocked explicit-link topology boundary');
    like($combined_output, qr/Reason:\s+the current active C2 lane only supports top inputs driving child inputs/s, 'CLI reports the concise top-to-top topology reason');
};

subtest 'CLI prints missing top-endpoint context in blocked explicit-link summaries' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'missing_top_endpoint_failure_summary_cli_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'missing_top_endpoint_failure_summary_cli_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:missing_top_endpoint_failure_summary_cli_top
  (?ports:public_io
    clk
    rstn
    result_data>8
  )
  (?fsmc:producer producer_src)
  (?fsmc:consumer consumer_src)
  (?toplink:wiring
    /missing_top/result_data/
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

(?fsm:consumer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (ack> <= 1'0)
  )
)
FSM
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, $composition_path],
    );

    ok(!$success, 'CLI fails for blocked missing-top-endpoint composition fixture');
    ok(!-e $output_path, 'CLI does not emit HDL output for blocked missing-top-endpoint fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/=== Composition Failure Summary ===/s, 'CLI prints the composition failure summary section for missing top endpoints');
    like($combined_output, qr/Construct:\s+\?toplink/s, 'CLI reports the explicit-link construct for blocked missing-top-endpoint failures');
    like($combined_output, qr/Context:\s+Top endpoint 'missing_top'/s, 'CLI reports the missing top endpoint as summary context');
    like($combined_output, qr/Blocked boundary:\s+explicit link endpoint resolution/s, 'CLI reports the blocked explicit-link endpoint boundary for missing top endpoints');
    like($combined_output, qr/Reason:\s+'\?ports' declares no top port with that name/s, 'CLI reports the concise missing top-endpoint reason');
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
    unlike($combined_output, qr/Construct:/s, 'CLI does not invent a construct line for unsupported child headers');
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

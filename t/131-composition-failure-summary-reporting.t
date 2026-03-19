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

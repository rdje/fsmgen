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
use FSM::Composition::Net;
use FSM::Composition::Plan;

subtest 'multi-rtl composition supports explicit C3 child-to-child wiring' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'rtl_bridge_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'rtl_bridge_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:rtl_bridge_top
  (?ports:public_io
    core_clk
    rst_async_n
    serial_in
    serial_out>
  )
  (?rtl:uart_rx)
  (?rtl:uart_tx)
  (?toplink:wiring
    /serial_in/uart_rx.rxd/
    /uart_rx.data_out/uart_tx.data_in/
    /uart_tx.txd/serial_out/
  )
)

(?rtlif:uart_rx
  core_clk:clock
  rst_async_n:reset
  rxd<:data
  data_out>8:data
)

(?rtlif:uart_tx
  core_clk:clock
  rst_async_n:reset
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

    my $result = $pipeline->generate_hdl_from_file($composition_path);

    isa_ok($result->{composition_plan}, 'FSM::Composition::Plan');
    is($result->{composition_plan}->lane, 'C3', 'multi-rtl explicit-link composition uses the C3 lane');
    is(scalar(@{$result->{composition_plan}->instances}), 2, 'multi-rtl composition realizes two rtl children');
    is_deeply(
        [map { $_->kind } @{$result->{composition_plan}->instances}],
        ['rtl', 'rtl'],
        'multi-rtl composition keeps both realized children as rtl instances',
    );
    is(scalar(@{$result->{composition_plan}->nets}), 1, 'multi-rtl composition materializes one deterministic internal net');
    isa_ok($result->{composition_plan}->nets->[0], 'FSM::Composition::Net');
    is($result->{composition_plan}->nets->[0]->name, 'comp_link_uart_rx_data_out', 'multi-rtl composition uses deterministic net naming');

    my %rx_bindings = map { $_->{port_name} => $_->{signal_name} } @{$result->{composition_plan}->instances->[0]->port_bindings};
    my %tx_bindings = map { $_->{port_name} => $_->{signal_name} } @{$result->{composition_plan}->instances->[1]->port_bindings};

    is($rx_bindings{core_clk}, 'core_clk', 'first rtl child clock is auto-wired');
    is($rx_bindings{rst_async_n}, 'rst_async_n', 'first rtl child reset is auto-wired');
    is($rx_bindings{rxd}, 'serial_in', 'first rtl child input is wired from the top input');
    is($rx_bindings{data_out}, 'comp_link_uart_rx_data_out', 'first rtl child output drives the deterministic carrier net');
    is($tx_bindings{core_clk}, 'core_clk', 'second rtl child clock is auto-wired');
    is($tx_bindings{rst_async_n}, 'rst_async_n', 'second rtl child reset is auto-wired');
    is($tx_bindings{data_in}, 'comp_link_uart_rx_data_out', 'second rtl child input is fed from the deterministic carrier net');
    is($tx_bindings{txd}, 'serial_out', 'second rtl child output is wired to the top output');

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\buart_rx\s+uart_rx\s*\(/s, 'generated top instantiates the first rtl child');
    like($hdl, qr/\buart_tx\s+uart_tx\s*\(/s, 'generated top instantiates the second rtl child');
    unlike($hdl, qr/\bmodule\s+uart_rx\b/s, 'generated HDL does not regenerate the first rtl child');
    unlike($hdl, qr/\bmodule\s+uart_tx\b/s, 'generated HDL does not regenerate the second rtl child');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );

    ok($success, 'CLI succeeds for multi-rtl explicit-link composition');
    ok(-e $output_path, 'CLI writes HDL for multi-rtl explicit-link composition');
};

subtest 'mixed generated-child plus multiple rtl children supports explicit C3 wiring' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'dt_plus_two_rtl_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'dt_plus_two_rtl_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:dt_plus_two_rtl_top
  (?ports:public_io
    core_clk
    rst_async_n
    payload_in<8
    serial_out>
    echoed_out>8
  )
  (?dtc:router route_src)
  (?rtl:uart_tx)
  (?rtl:payload_probe)
  (?toplink:wiring
    /payload_in/router.data_in/
    /router.route_data/uart_tx.data_in/
    /router.route_data/payload_probe.sample_in/
    /uart_tx.txd/serial_out/
    /payload_probe.sample_seen/echoed_out/
  )
)

(?dt:route_src
  (-route
    (route_data> = data_in)
  )
  (+size
    (data_in 8)
    (route_data 8)
  )
)

(?rtlif:uart_tx
  core_clk:clock
  rst_async_n:reset
  data_in<8:data
  txd>:data
)

(?rtlif:payload_probe
  core_clk:clock
  rst_async_n:reset
  sample_in<8:data
  sample_seen>8:data
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $result = $pipeline->generate_hdl_from_file($composition_path);

    isa_ok($result->{composition_plan}, 'FSM::Composition::Plan');
    is($result->{composition_plan}->lane, 'C3', 'generated-child plus multiple rtl composition uses the C3 lane');
    is_deeply(
        [map { $_->kind } @{$result->{composition_plan}->instances}],
        ['dtc', 'rtl', 'rtl'],
        'mixed multi-rtl composition realizes one dtc child and two rtl children',
    );
    is(scalar(@{$result->{composition_plan}->nets}), 1, 'generated-child plus multiple rtl composition materializes one shared deterministic net');
    is($result->{composition_plan}->nets->[0]->name, 'comp_link_router_route_data', 'mixed multi-rtl composition uses deterministic net naming');

    my %router_bindings = map { $_->{port_name} => $_->{signal_name} } @{$result->{composition_plan}->instances->[0]->port_bindings};
    my %uart_bindings = map { $_->{port_name} => $_->{signal_name} } @{$result->{composition_plan}->instances->[1]->port_bindings};
    my %probe_bindings = map { $_->{port_name} => $_->{signal_name} } @{$result->{composition_plan}->instances->[2]->port_bindings};

    is($router_bindings{data_in}, 'payload_in', 'generated child input is wired from the top input');
    is($router_bindings{route_data}, 'comp_link_router_route_data', 'generated child output drives the deterministic carrier net');
    is($uart_bindings{core_clk}, 'core_clk', 'first rtl child clock is auto-wired in mixed multi-rtl composition');
    is($uart_bindings{rst_async_n}, 'rst_async_n', 'first rtl child reset is auto-wired in mixed multi-rtl composition');
    is($uart_bindings{data_in}, 'comp_link_router_route_data', 'first rtl child consumes the generated carrier net');
    is($uart_bindings{txd}, 'serial_out', 'first rtl child output is wired to the top output');
    is($probe_bindings{core_clk}, 'core_clk', 'second rtl child clock is auto-wired in mixed multi-rtl composition');
    is($probe_bindings{rst_async_n}, 'rst_async_n', 'second rtl child reset is auto-wired in mixed multi-rtl composition');
    is($probe_bindings{sample_in}, 'comp_link_router_route_data', 'second rtl child also consumes the generated carrier net');
    is($probe_bindings{sample_seen}, 'echoed_out', 'second rtl child output is wired to the top output');

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\bmodule\s+route_src\b/s, 'generated HDL includes the dt child module');
    like($hdl, qr/\buart_tx\s+uart_tx\s*\(/s, 'generated HDL instantiates the first rtl child');
    like($hdl, qr/\bpayload_probe\s+payload_probe\s*\(/s, 'generated HDL instantiates the second rtl child');
    unlike($hdl, qr/\bmodule\s+uart_tx\b/s, 'generated HDL does not regenerate the first rtl child');
    unlike($hdl, qr/\bmodule\s+payload_probe\b/s, 'generated HDL does not regenerate the second rtl child');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );

    ok($success, 'CLI succeeds for generated-child plus multiple rtl composition');
    ok(-e $output_path, 'CLI writes HDL for generated-child plus multiple rtl composition');
};

subtest 'one rtl interface can be instantiated several times with explicit instance aliases' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'aliased_reused_rtl_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'aliased_reused_rtl_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:aliased_reused_rtl_top
  (?ports:public_io
    core_clk
    rst_async_n
    payload_a<8
    payload_b<8
    serial_a>
    serial_b>
  )
  (?rtl:u_uart_a uart_tx)
  (?rtl:u_uart_b uart_tx)
  (?toplink:wiring
    /payload_a/u_uart_a.data_in/
    /u_uart_a.txd/serial_a/
    /payload_b/u_uart_b.data_in/
    /u_uart_b.txd/serial_b/
  )
)

(?rtlif:uart_tx
  core_clk:clock
  rst_async_n:reset
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

    my $result = $pipeline->generate_hdl_from_file($composition_path);

    isa_ok($result->{composition_plan}, 'FSM::Composition::Plan');
    is($result->{composition_plan}->lane, 'C3', 'aliased repeated rtl composition uses the C3 lane');
    is(scalar(@{$result->{composition_plan}->instances}), 2, 'aliased repeated rtl composition realizes two rtl children');
    is_deeply(
        [map { $_->instance_name } @{$result->{composition_plan}->instances}],
        ['u_uart_a', 'u_uart_b'],
        'aliased repeated rtl composition keeps distinct instance names',
    );
    is_deeply(
        [map { $_->module_name } @{$result->{composition_plan}->instances}],
        ['uart_tx', 'uart_tx'],
        'aliased repeated rtl composition reuses one rtl module/interface contract',
    );

    my %first_bindings = map { $_->{port_name} => $_->{signal_name} } @{$result->{composition_plan}->instances->[0]->port_bindings};
    my %second_bindings = map { $_->{port_name} => $_->{signal_name} } @{$result->{composition_plan}->instances->[1]->port_bindings};

    is($first_bindings{core_clk}, 'core_clk', 'first aliased rtl instance clock is auto-wired');
    is($first_bindings{rst_async_n}, 'rst_async_n', 'first aliased rtl instance reset is auto-wired');
    is($first_bindings{data_in}, 'payload_a', 'first aliased rtl instance uses its own input payload');
    is($first_bindings{txd}, 'serial_a', 'first aliased rtl instance drives its own top output');
    is($second_bindings{core_clk}, 'core_clk', 'second aliased rtl instance clock is auto-wired');
    is($second_bindings{rst_async_n}, 'rst_async_n', 'second aliased rtl instance reset is auto-wired');
    is($second_bindings{data_in}, 'payload_b', 'second aliased rtl instance uses its own input payload');
    is($second_bindings{txd}, 'serial_b', 'second aliased rtl instance drives its own top output');

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\buart_tx\s+u_uart_a\s*\(/s, 'generated HDL instantiates the first aliased rtl child');
    like($hdl, qr/\buart_tx\s+u_uart_b\s*\(/s, 'generated HDL instantiates the second aliased rtl child');
    unlike($hdl, qr/\bmodule\s+uart_tx\b/s, 'generated HDL still does not regenerate the reused external rtl child');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );

    ok($success, 'CLI succeeds for aliased repeated rtl composition');
    ok(-e $output_path, 'CLI writes HDL for aliased repeated rtl composition');
};

subtest 'rtl instance parameter overrides lower through structural IR into SV instance parameters' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'parameterized_rtl_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'parameterized_rtl_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:parameterized_rtl_top
  (+constants
    (OVERRIDE_WIDTH 16)
    (LOCAL_LANES (8'hA5 8'h3C))
  )
  (+enums
    (frame_mode
      (RUN 2'b10)
    )
  )
  (+import
    param_pkg
  )
  (?ports:public_io
    core_clk
    rst_async_n
    payload_in<16
    serial_out>
  )
  (?rtl:u_uart
    (module uart_tx)
    (params
      (WIDTH OVERRIDE_WIDTH)
      (RESET_VALUE param_pkg.RESET_A5)
      (LANES LOCAL_LANES)
      (FRAME ((mode frame_mode.RUN) (flag param_pkg.FLAG_ON)))
      (EXPR_WIDTH (+ OVERRIDE_WIDTH 1))
      (LANES_MASKED (and LOCAL_LANES param_pkg.DEFAULT_LANE_MASK))
    )
  )
  (?toplink:wiring
    /payload_in/u_uart.data_in/
    /u_uart.txd/serial_out/
  )
)

(?rtlif:uart_tx
  (params
    (WIDTH param_pkg.DEFAULT_WIDTH)
    (RESET_VALUE param_pkg.DEFAULT_RESET)
    (LANES param_pkg.DEFAULT_LANES)
    (FRAME param_pkg.DEFAULT_FRAME)
    (EXPR_WIDTH (+ param_pkg.DEFAULT_WIDTH 1))
    (LANES_MASKED (and param_pkg.DEFAULT_LANES param_pkg.DEFAULT_LANE_MASK))
  )
  core_clk:clock
  rst_async_n:reset
  data_in<16:data
  txd>:data
)

(?pkg:param_pkg
  (+constants
    (DEFAULT_WIDTH 8)
    (DEFAULT_RESET 8'h00)
    (DEFAULT_LANES (8'h00 8'h00))
    (DEFAULT_LANE_MASK (8'hF0 8'h0F))
    (DEFAULT_FRAME ((mode 2'b00) (flag 0)))
    (RESET_A5 8'hA5)
    (FLAG_ON 1)
  )
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $result = $pipeline->generate_hdl_from_file($composition_path);

    isa_ok($result->{composition_plan}, 'FSM::Composition::Plan');
    is($result->{composition_plan}->lane, 'C3', 'parameterized rtl explicit-link composition uses the C3 lane');
    my $parameter_overrides = $result->{composition_plan}->instances->[0]->parameter_overrides;
    is_deeply(
        [map { $_->{name} } @$parameter_overrides],
        [qw(WIDTH RESET_VALUE LANES FRAME EXPR_WIDTH LANES_MASKED)],
        'composition plan preserves validated parameter override order',
    );
    my %overrides = map { $_->{name} => $_ } @$parameter_overrides;
    is($overrides{WIDTH}{value_text}, '16', 'composition plan preserves scalar decimal parameter override text');
    is($overrides{WIDTH}{value_kind}, 'scalar', 'composition plan marks scalar parameter overrides');
    is($overrides{WIDTH}{raw_value}, 'OVERRIDE_WIDTH', 'composition plan preserves local-symbol raw scalar parameter override token');
    is($overrides{WIDTH}{origin_kind}, 'rtl_instance_parameter_override', 'composition plan keeps parameter override provenance');
    is($overrides{RESET_VALUE}{value_text}, "8'hA5", 'composition plan preserves sized based scalar parameter override text');
    is($overrides{RESET_VALUE}{raw_value}, 'param_pkg.RESET_A5', 'composition plan preserves package-symbol raw scalar parameter override token');
    is($overrides{RESET_VALUE}{value_width}, 8, 'composition plan infers width for sized based scalar parameter overrides');
    is($overrides{LANES}{value_text}, "16'b1010010100111100", 'composition plan packs list aggregate parameter overrides');
    is($overrides{LANES}{value_kind}, 'list', 'composition plan marks list aggregate parameter overrides');
    is($overrides{LANES}{raw_value}, 'LOCAL_LANES', 'composition plan preserves local aggregate raw parameter override token');
    is($overrides{LANES}{value_width}, 16, 'composition plan infers packed width for list aggregate parameter overrides');
    is($overrides{FRAME}{value_text}, "3'b101", 'composition plan packs record aggregate parameter overrides');
    is($overrides{FRAME}{value_kind}, 'map', 'composition plan marks record-like aggregate parameter overrides');
    is_deeply(
        $overrides{FRAME}{value_type_spec}{member_order},
        [qw(mode flag)],
        'composition plan preserves record aggregate member order for parameter overrides',
    );
    is($overrides{EXPR_WIDTH}{value_text}, '(16 + 1)', 'composition plan preserves scalar expression parameter override text');
    is($overrides{EXPR_WIDTH}{value_kind}, 'scalar', 'composition plan marks scalar expression parameter overrides as scalar values');
    is($overrides{LANES_MASKED}{value_text}, "16'b1010000000001100", 'composition plan folds aggregate bitwise parameter override expressions');
    is($overrides{LANES_MASKED}{value_kind}, 'list', 'composition plan keeps aggregate bitwise override expressions as aggregate values');
    my %declarations = map { $_->{name} => $_ } @{$result->{composition_plan}->instances->[0]->module_info->{parameter_declarations}};
    is($declarations{WIDTH}{raw_default_value}, 'param_pkg.DEFAULT_WIDTH', 'rtlif defaults preserve package-symbol raw scalar token');
    is($declarations{WIDTH}{default_value_text}, '8', 'rtlif defaults resolve package-backed scalar values');
    is($declarations{EXPR_WIDTH}{default_value_text}, '(8 + 1)', 'rtlif defaults resolve package-backed scalar expressions');
    is($declarations{LANES_MASKED}{default_value_text}, "16'b0000000000000000", 'rtlif defaults resolve package-backed aggregate bitwise expressions');
    is($declarations{LANES}{raw_default_value}, 'param_pkg.DEFAULT_LANES', 'rtlif defaults preserve package-symbol raw aggregate token');
    is($declarations{LANES}{default_value_text}, "16'b0000000000000000", 'rtlif defaults resolve package-backed list aggregate shape');
    is_deeply(
        $declarations{FRAME}{default_value_type_spec}{member_order},
        [qw(mode flag)],
        'rtlif defaults resolve package-backed record aggregate shape',
    );
    is_deeply(
        $result->{structural_rtl_ir}{instances}[0]{parameter_overrides},
        $result->{composition_plan}->instances->[0]->parameter_overrides,
        'structural RTL IR preserves parameter override values for backend lowering',
    );
    is_deeply(
        $result->{intent_hir}{composition_children}[0]{parameter_overrides},
        $result->{composition_plan}->instances->[0]->parameter_overrides,
        'intent HIR child export preserves parameter override values for reporting and later lowering',
    );
    is(
        $result->{intent_hir}{composition_children}[0]{parameter_override_count},
        6,
        'intent HIR child export reports the parameter override count',
    );

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\buart_tx\s+#\(\s*\.WIDTH\(16\),\s*\.RESET_VALUE\(8'hA5\),\s*\.LANES\(16'b1010010100111100\),\s*\.FRAME\(3'b101\),\s*\.EXPR_WIDTH\(\(16 \+ 1\)\),\s*\.LANES_MASKED\(16'b1010000000001100\)\s*\)\s+u_uart\s*\(/s, 'generated HDL emits SV parameter overrides on the external RTL instance');
    unlike($hdl, qr/\bmodule\s+uart_tx\b/s, 'generated HDL does not regenerate the parameterized external rtl child');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );

    ok($success, 'CLI succeeds for parameterized external RTL instance composition');
    ok(-e $output_path, 'CLI writes HDL for parameterized external RTL instance composition');
};

subtest 'rtlif parameter default value names must resolve before generation' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'unknown_rtlif_parameter_default_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'unknown_rtlif_parameter_default_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:unknown_rtlif_parameter_default_top
  (+import
    param_pkg
  )
  (?ports:public_io
    core_clk
    rst_async_n
    payload_in<8
    serial_out>
  )
  (?rtl:u_uart uart_tx
    (params
      (WIDTH 8)
    )
  )
  (?toplink:wiring
    /payload_in/u_uart.data_in/
    /u_uart.txd/serial_out/
  )
)

(?rtlif:uart_tx
  (params
    (WIDTH param_pkg.NO_SUCH_DEFAULT)
  )
  core_clk:clock
  rst_async_n:reset
  data_in<8:data
  txd>:data
)

(?pkg:param_pkg
  (+constants
    (RESET_A5 8'hA5)
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
    $exception = $@ if !$exception;

    like(
        $exception,
        qr/parameter\/generic 'WIDTH'.*param_pkg\.NO_SUCH_DEFAULT/s,
        'pipeline rejects unresolved RTL interface parameter default value symbols',
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );
    ok(!$success, 'CLI rejects unresolved RTL interface parameter default value symbols');
    ok(!-e $output_path, 'CLI does not emit HDL when RTL interface parameter default value resolution fails');
    my $combined_output = join('', @{$stdout_buf || []}, @{$stderr_buf || []}, ($error_message || ''));
    like(
        $combined_output,
        qr/parameter\/generic 'WIDTH'.*param_pkg\.NO_SUCH_DEFAULT/s,
        'CLI surfaces unresolved RTL interface parameter default value diagnostics',
    );
};

subtest 'rtl aggregate parameter overrides must match the rtlif default shape' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'bad_aggregate_rtl_parameter_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'bad_aggregate_rtl_parameter_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:bad_aggregate_rtl_parameter_top
  (?ports:public_io
    core_clk
    rst_async_n
    payload_in<16
    serial_out>
  )
  (?rtl:u_uart
    (module uart_tx)
    (params
      (LANES (8'hA5))
    )
  )
  (?toplink:wiring
    /payload_in/u_uart.data_in/
    /u_uart.txd/serial_out/
  )
)

(?rtlif:uart_tx
  (params
    (LANES (8'h00 8'h00))
  )
  core_clk:clock
  rst_async_n:reset
  data_in<16:data
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
    $exception = $@ if !$exception;

    like(
        $exception,
        qr/RTL parameter\/generic override validation is blocked because override 'LANES' uses list<.*> while interface metadata '.*bad_aggregate_rtl_parameter_top\.fsm:\?rtlif:uart_tx' declares list<.*>.*Aggregate parameter\/generic overrides must match the aggregate shape/s,
        'pipeline rejects aggregate parameter overrides that do not match the rtlif default shape',
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );
    ok(!$success, 'CLI rejects aggregate RTL parameter shape mismatches');
    ok(!-e $output_path, 'CLI does not emit HDL when aggregate RTL parameter shape validation fails');
    my $combined_output = join('', @{$stdout_buf || []}, @{$stderr_buf || []}, ($error_message || ''));
    like(
        $combined_output,
        qr/override 'LANES' uses list<.*> while interface metadata '.*bad_aggregate_rtl_parameter_top\.fsm:\?rtlif:uart_tx' declares list<.*>/s,
        'CLI surfaces aggregate RTL parameter shape validation diagnostics',
    );
};

subtest 'rtl instance parameter overrides must be declared by the rtlif contract' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'unknown_rtl_parameter_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'unknown_rtl_parameter_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:unknown_rtl_parameter_top
  (?ports:public_io
    core_clk
    rst_async_n
    payload_in<8
    serial_out>
  )
  (?rtl:u_uart uart_tx
    (params
      (MODE 1)
    )
  )
  (?toplink:wiring
    /payload_in/u_uart.data_in/
    /u_uart.txd/serial_out/
  )
)

(?rtlif:uart_tx
  (params
    (WIDTH 8)
  )
  core_clk:clock
  rst_async_n:reset
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
    $exception = $@ if !$exception;

    like(
        $exception,
        qr/RTL parameter\/generic override validation is blocked because override 'MODE' has no matching declaration in interface metadata/s,
        'pipeline rejects overrides that are not declared in the rtlif contract',
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );
    ok(!$success, 'CLI rejects undeclared RTL parameter override');
    ok(!-e $output_path, 'CLI does not emit HDL when RTL parameter override validation fails');
    my $combined_output = join('', @{$stdout_buf || []}, @{$stderr_buf || []}, ($error_message || ''));
    like(
        $combined_output,
        qr/override 'MODE' has no matching declaration in interface metadata/s,
        'CLI surfaces undeclared RTL parameter override validation diagnostics',
    );
};

subtest 'rtl instance parameter override value names must resolve before generation' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'unknown_rtl_parameter_value_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'unknown_rtl_parameter_value_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:unknown_rtl_parameter_value_top
  (?ports:public_io
    core_clk
    rst_async_n
    payload_in<8
    serial_out>
  )
  (?rtl:u_uart uart_tx
    (params
      (WIDTH NO_SUCH_SYMBOL)
    )
  )
  (?toplink:wiring
    /payload_in/u_uart.data_in/
    /u_uart.txd/serial_out/
  )
)

(?rtlif:uart_tx
  (params
    (WIDTH 8)
  )
  core_clk:clock
  rst_async_n:reset
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
    $exception = $@ if !$exception;

    like(
        $exception,
        qr/parameter override 'WIDTH'.*NO_SUCH_SYMBOL/s,
        'pipeline rejects unresolved RTL parameter override value symbols',
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );
    ok(!$success, 'CLI rejects unresolved RTL parameter override value symbols');
    ok(!-e $output_path, 'CLI does not emit HDL when RTL parameter override value resolution fails');
    my $combined_output = join('', @{$stdout_buf || []}, @{$stderr_buf || []}, ($error_message || ''));
    like(
        $combined_output,
        qr/parameter override 'WIDTH'.*NO_SUCH_SYMBOL/s,
        'CLI surfaces unresolved RTL parameter override value diagnostics',
    );
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

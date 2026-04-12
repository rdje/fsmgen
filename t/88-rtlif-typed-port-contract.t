#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Cmd qw(run);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Composition::RTLInterfaceLoader;
use FSM::Pipeline::HDLGenerator;
use FSM::Composition::Plan;

subtest '.rtlif typed tokens preserve direction, width, and port type' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $metadata_path = File::Spec->catfile($tempdir, 'uart_tx.rtlif');

    write_file(
        $metadata_path,
        <<'RTLIF'
(?rtlif:uart_tx
  core_clk:clock
  rst_async_n:reset
  data_in<8:data
  txd>:data
)
RTLIF
    );

    my $loader = FSM::Composition::RTLInterfaceLoader->new();
    my $loaded = $loader->load_interface(
        module_name => 'uart_tx',
        source_file => File::Spec->catfile($tempdir, 'dummy_top.fsm'),
    );

    is($loaded->{metadata_path}, $metadata_path, 'loader resolves the typed metadata file');
    is_deeply(
        [map { $_->name } @{$loaded->{interface_ports}}],
        ['core_clk', 'rst_async_n', 'data_in', 'txd'],
        'typed metadata preserves declared port order',
    );

    my %ports = map { $_->name => $_ } @{$loaded->{interface_ports}};
    is($ports{core_clk}->direction, 'input', 'typed clock token defaults to input direction');
    is($ports{core_clk}->type, 'clock', 'typed clock token preserves clock type');
    is($ports{rst_async_n}->direction, 'input', 'typed reset token defaults to input direction');
    is($ports{rst_async_n}->type, 'reset', 'typed reset token preserves reset type');
    is($ports{data_in}->direction, 'input', 'typed data input token preserves input direction');
    is($ports{data_in}->width, 8, 'typed data input token preserves explicit width');
    is($ports{data_in}->type, 'data', 'typed data input token preserves explicit data type');
    is($ports{txd}->direction, 'output', 'typed data output token preserves output direction');
    is($ports{txd}->type, 'data', 'typed data output token preserves explicit data type');
};

subtest '.rtlif parameter declarations preserve canonical defaults' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $metadata_path = File::Spec->catfile($tempdir, 'uart_tx.rtlif');

    write_file(
        $metadata_path,
        <<'RTLIF'
(?rtlif:uart_tx
  (params
    (WIDTH 0x10)
    (RESET_VALUE 8'hA5)
    (LANES (8'hA5 8'h3C))
    (LANES_MASKED (and (8'hA5 8'h3C) (8'hF0 8'h0F)))
    (FRAME ((mode 2'b10) (flag 1)))
  )
  core_clk:clock
  rst_async_n:reset
  data_in<16:data
  txd>:data
)
RTLIF
    );

    my $loader = FSM::Composition::RTLInterfaceLoader->new();
    my $loaded = $loader->load_interface(
        module_name => 'uart_tx',
        source_file => File::Spec->catfile($tempdir, 'dummy_top.fsm'),
    );

    is_deeply(
        [map { $_->{name} } @{$loaded->{parameter_declarations}}],
        [qw(WIDTH RESET_VALUE LANES LANES_MASKED FRAME)],
        'loader preserves declared RTL parameter/generic default order',
    );
    my %params = map { $_->{name} => $_ } @{$loaded->{parameter_declarations}};
    is($params{WIDTH}{default_value_text}, "'h10", 'loader canonicalizes unsized hex-style parameter defaults');
    is($params{WIDTH}{default_value_kind}, 'scalar', 'loader marks scalar parameter defaults');
    is_deeply(
        $params{WIDTH}{default_value_payload},
        { kind => 'scalar', payload => "'h10" },
        'loader keeps the canonical scalar parameter payload',
    );
    is($params{WIDTH}{raw_default_value}, '0x10', 'loader preserves the raw scalar parameter default token');
    is($params{WIDTH}{origin_kind}, 'rtlif_parameter_declaration', 'loader keeps parameter declaration provenance');
    is($params{RESET_VALUE}{default_value_text}, "8'hA5", 'loader preserves sized based parameter defaults');
    is($params{RESET_VALUE}{default_value_width}, 8, 'loader infers width for sized based scalar parameter defaults');
    is($params{LANES}{default_value_text}, "16'b1010010100111100", 'loader packs list aggregate parameter defaults for backend lowering');
    is($params{LANES}{default_value_kind}, 'list', 'loader marks list aggregate parameter defaults');
    is($params{LANES}{default_value_width}, 16, 'loader infers packed width for list aggregate parameter defaults');
    is_deeply(
        [map { $_->{payload} } @{$params{LANES}{default_value_payload}{items}}],
        ["8'hA5", "8'h3C"],
        'loader keeps the ordered list aggregate parameter payload',
    );
    is($params{LANES_MASKED}{default_value_text}, "16'b1010000000001100", 'loader folds aggregate bitwise parameter defaults for backend lowering');
    is($params{LANES_MASKED}{default_value_kind}, 'list', 'loader keeps folded aggregate bitwise parameter defaults as aggregate values');
    is($params{LANES_MASKED}{default_value_width}, 16, 'loader infers packed width for folded aggregate bitwise parameter defaults');
    is($params{FRAME}{default_value_text}, "3'b101", 'loader packs record aggregate parameter defaults for backend lowering');
    is($params{FRAME}{default_value_kind}, 'map', 'loader marks record-like aggregate parameter defaults');
    is_deeply(
        $params{FRAME}{default_value_type_spec}{member_order},
        [qw(mode flag)],
        'loader preserves record aggregate member order for parameter defaults',
    );
    is_deeply(
        [map { $_->name } @{$loaded->{interface_ports}}],
        ['core_clk', 'rst_async_n', 'data_in', 'txd'],
        'parameter declaration blocks do not disturb declared port order',
    );
};

subtest 'mixed composition auto-wires custom typed rtl clock/reset ports' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'typed_rtl_system_ports_top.fsm');
    my $metadata_path = File::Spec->catfile($tempdir, 'uart_tx.rtlif');
    my $output_path = File::Spec->catfile($tempdir, 'typed_rtl_system_ports_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:typed_rtl_system_ports_top
  (?ports:public_io
    core_clk
    rst_async_n
    payload_in<8
    serial_out>
  )
  (?dtc:router route_src)
  (?rtl:uart_tx)
  (?toplink:wiring
    /payload_in/router.payload_in/
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
FSM
    );

    write_file(
        $metadata_path,
        <<'RTLIF'
(?rtlif:uart_tx
  core_clk:clock
  rst_async_n:reset
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

    my $result = $pipeline->generate_hdl_from_file($composition_path);

    isa_ok($result->{composition_plan}, 'FSM::Composition::Plan');
    is($result->{composition_plan}->lane, 'C3', 'mixed dtc plus rtl composition still uses the C3 lane');

    my %rtl_bindings = map { $_->{port_name} => $_->{signal_name} } @{$result->{composition_plan}->instances->[1]->port_bindings};
    is($rtl_bindings{core_clk}, 'core_clk', 'typed rtl clock port auto-wires from the custom top system input');
    is($rtl_bindings{rst_async_n}, 'rst_async_n', 'typed rtl reset port auto-wires from the custom top system input');
    is($rtl_bindings{data_in}, 'comp_link_router_route_data', 'typed rtl data input still uses the explicit deterministic net');
    is($rtl_bindings{txd}, 'serial_out', 'typed rtl output still uses the explicit top-output link');

    my %rtl_ports = map { $_->name => $_ } @{$result->{composition_plan}->instances->[1]->interface_ports};
    is($rtl_ports{core_clk}->type, 'clock', 'realized rtl interface preserves the explicit clock type');
    is($rtl_ports{rst_async_n}->type, 'reset', 'realized rtl interface preserves the explicit reset type');

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\.core_clk\(core_clk\)/s, 'generated HDL wires the custom typed clock port directly');
    like($hdl, qr/\.rst_async_n\(rst_async_n\)/s, 'generated HDL wires the custom typed reset port directly');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );

    ok($success, 'CLI succeeds for mixed composition with typed rtl system ports');
    ok(-e $output_path, 'CLI writes HDL for mixed composition with typed rtl system ports');
};

subtest '.rtlif rejects unsupported explicit port types' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $metadata_path = File::Spec->catfile($tempdir, 'uart_tx.rtlif');

    write_file(
        $metadata_path,
        <<'RTLIF'
(?rtlif:uart_tx
  core_clk:clock
  txd>:status
)
RTLIF
    );

    my $loader = FSM::Composition::RTLInterfaceLoader->new();
    my $error = eval {
        $loader->load_interface(
            module_name => 'uart_tx',
            source_file => File::Spec->catfile($tempdir, 'dummy_top.fsm'),
        );
        undef;
    };
    $error = $@ if !$error;

    like($error, qr/unsupported port type 'status'/, 'loader rejects unsupported explicit type names');
};

subtest '.rtlif rejects clock and reset outputs' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'bad_rtl_system_direction_top.fsm');
    my $metadata_path = File::Spec->catfile($tempdir, 'uart_tx.rtlif');
    my $output_path = File::Spec->catfile($tempdir, 'bad_rtl_system_direction_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:bad_rtl_system_direction_top
  (?ports:public_io
    core_clk
    rst_async_n
    payload_in<8
    serial_out>
  )
  (?rtl:uart_tx)
  (?toplink:wiring
    /payload_in/uart_tx.data_in/
    /uart_tx.txd/serial_out/
  )
)
FSM
    );

    write_file(
        $metadata_path,
        <<'RTLIF'
(?rtlif:uart_tx
  core_clk>:clock
  rst_async_n>:reset
  data_in<8:data
  txd>:data
)
RTLIF
    );

    my $loader = FSM::Composition::RTLInterfaceLoader->new();
    my $loader_error = eval {
        $loader->load_interface(
            module_name => 'uart_tx',
            source_file => $composition_path,
        );
        undef;
    };
    $loader_error = $@ if !$loader_error;

    like(
        $loader_error,
        qr/system-port direction is blocked because token 'core_clk>:clock'.*treats 'clock' and 'reset' ports as system inputs only/s,
        'loader rejects output-direction clock/reset tokens before composition planning',
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );
    my $pipeline_error = eval {
        $pipeline->generate_hdl_from_file($composition_path);
        undef;
    };
    $pipeline_error = $@ if !$pipeline_error;

    like(
        $pipeline_error,
        qr/RTL metadata file:\s+'\Q$metadata_path\E'.*system-port direction is blocked because token 'core_clk>:clock'/s,
        'pipeline preserves sidecar metadata context for blocked rtlif system-port direction',
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );
    ok(!$success, 'CLI rejects output-direction clock/reset rtlif tokens');
    ok(!-e $output_path, 'CLI does not emit HDL for invalid rtlif system-port direction');
    my $combined_output = join('', @{$stdout_buf || []}, @{$stderr_buf || []}, ($error_message || ''));
    like(
        $combined_output,
        qr/system-port direction is blocked because token 'core_clk>:clock'/s,
        'CLI surfaces blocked rtlif system-port direction diagnostics',
    );
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

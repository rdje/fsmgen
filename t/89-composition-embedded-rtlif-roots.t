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
use Lispish;

subtest 'embedded ?rtlif roots take precedence over sidecar metadata' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'embedded_rtlif_top.fsm');
    my $sidecar_path = File::Spec->catfile($tempdir, 'uart_tx.rtlif');

    write_file(
        $composition_path,
        <<'FSM'
(?top:embedded_rtlif_top
  (?ports:public_io
    core_clk
    rst_async_n
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
  (-state0
    (output_data> <= 8'3)
  )
  (+size
    (output_data 8)
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

    write_file(
        $sidecar_path,
        <<'RTLIF'
(?rtlif:uart_tx
  clk
  rstn
  txd>
)
RTLIF
    );

    my $raw_ast = Lispish::multi($composition_path);
    my $loader = FSM::Composition::RTLInterfaceLoader->new();
    my $loaded = $loader->load_interface(
        module_name => 'uart_tx',
        source_file => $composition_path,
        embedded_raw_ast => $raw_ast,
    );

    is(
        $loaded->{metadata_path},
        "$composition_path:?rtlif:uart_tx",
        'loader records the embedded ?rtlif root as the active metadata source',
    );
    is_deeply(
        [map { $_->name } @{$loaded->{interface_ports}}],
        ['core_clk', 'rst_async_n', 'data_in', 'txd'],
        'loader preserves declaration order from the embedded ?rtlif root',
    );

    my %ports = map { $_->name => $_ } @{$loaded->{interface_ports}};
    is($ports{core_clk}->type, 'clock', 'embedded typed clock metadata wins over any sidecar');
    is($ports{rst_async_n}->type, 'reset', 'embedded typed reset metadata wins over any sidecar');
    is($ports{data_in}->width, 8, 'embedded typed input width is preserved');
};

subtest 'mixed composition can realize ?rtl children from embedded ?rtlif metadata' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'embedded_rtlif_mixed_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'embedded_rtlif_mixed_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:embedded_rtlif_mixed_top
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
    is($result->{composition_plan}->lane, 'C3', 'embedded ?rtlif metadata still uses the mixed C3 lane');
    is(
        $result->{composition_plan}->instances->[1]->module_info->{metadata_path},
        "$composition_path:?rtlif:uart_tx",
        'mixed composition records the embedded ?rtlif root as metadata provenance',
    );

    my %rtl_bindings = map { $_->{port_name} => $_->{signal_name} } @{$result->{composition_plan}->instances->[1]->port_bindings};
    is($rtl_bindings{core_clk}, 'core_clk', 'embedded typed rtl clock port auto-wires from the custom top system input');
    is($rtl_bindings{rst_async_n}, 'rst_async_n', 'embedded typed rtl reset port auto-wires from the custom top system input');
    is($rtl_bindings{data_in}, 'comp_link_router_route_data', 'embedded typed rtl data input still uses the explicit deterministic net');
    is($rtl_bindings{txd}, 'serial_out', 'embedded typed rtl output still uses the explicit top-output link');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );

    ok($success, 'CLI succeeds for mixed composition with embedded ?rtlif metadata');
    ok(-e $output_path, 'CLI writes HDL for mixed composition with embedded ?rtlif metadata');
};

subtest 'duplicate embedded ?rtlif roots fail explicitly' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'duplicate_embedded_rtlif_top.fsm');

    write_file(
        $composition_path,
        <<'FSM'
(?top:duplicate_embedded_rtlif_top
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

    my $raw_ast = Lispish::multi($composition_path);
    my $loader = FSM::Composition::RTLInterfaceLoader->new();
    my $error = eval {
        $loader->load_interface(
            module_name => 'uart_tx',
            source_file => $composition_path,
            embedded_raw_ast => $raw_ast,
        );
        undef;
    };
    $error = $@ if !$error;

    like(
        $error,
        qr/multiple embedded '\?rtlif:uart_tx' roots/,
        'loader rejects duplicate embedded interface roots for the same RTL module',
    );
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

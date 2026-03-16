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
use FSM::Composition::Plan;

subtest 'single ?rtl child supports C1 passthrough top exposure' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'single_rtl_passthrough_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'single_rtl_passthrough_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:single_rtl_passthrough_top
  (?ports:public_io
    core_clk
    rst_async_n
    data_in<8
    txd>
  )
  (?rtl:uart_tx)
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
    is($result->{composition_plan}->lane, 'C1', 'single rtl passthrough uses the C1 lane');
    is(scalar(@{$result->{composition_plan}->instances}), 1, 'single rtl passthrough realizes one child instance');
    is($result->{composition_plan}->instances->[0]->kind, 'rtl', 'single rtl passthrough realizes the external rtl child');
    is(
        $result->{composition_plan}->instances->[0]->module_info->{metadata_path},
        "$composition_path:?rtlif:uart_tx",
        'single rtl passthrough records embedded ?rtlif provenance',
    );

    my %rtl_bindings = map { $_->{port_name} => $_->{signal_name} } @{$result->{composition_plan}->instances->[0]->port_bindings};
    is($rtl_bindings{core_clk}, 'core_clk', 'single rtl passthrough wires the typed clock port directly');
    is($rtl_bindings{rst_async_n}, 'rst_async_n', 'single rtl passthrough wires the typed reset port directly');
    is($rtl_bindings{data_in}, 'data_in', 'single rtl passthrough wires the input directly by name');
    is($rtl_bindings{txd}, 'txd', 'single rtl passthrough wires the output directly by name');

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\buart_tx\s+uart_tx\s*\(/s, 'generated top instantiates the external rtl child');
    unlike($hdl, qr/\bmodule\s+uart_tx\b/s, 'generated top does not regenerate the external rtl child');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );

    ok($success, 'CLI succeeds for single rtl passthrough composition');
    ok(-e $output_path, 'CLI writes HDL for single rtl passthrough composition');
};

subtest 'single ?rtl child supports C3 explicit toplink renaming' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'single_rtl_explicit_toplink_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'single_rtl_explicit_toplink_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:single_rtl_explicit_toplink_top
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
    is($result->{composition_plan}->lane, 'C3', 'single rtl explicit toplinks use the C3 lane');

    my %rtl_bindings = map { $_->{port_name} => $_->{signal_name} } @{$result->{composition_plan}->instances->[0]->port_bindings};
    is($rtl_bindings{core_clk}, 'core_clk', 'single rtl explicit toplinks still auto-wire the typed clock port');
    is($rtl_bindings{rst_async_n}, 'rst_async_n', 'single rtl explicit toplinks still auto-wire the typed reset port');
    is($rtl_bindings{data_in}, 'payload_in', 'single rtl explicit toplinks allow renamed top inputs');
    is($rtl_bindings{txd}, 'serial_out', 'single rtl explicit toplinks allow renamed top outputs');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );

    ok($success, 'CLI succeeds for single rtl explicit-toplink composition');
    ok(-e $output_path, 'CLI writes HDL for single rtl explicit-toplink composition');
};

subtest 'single ?rtl child supports C4 declared connect-by-name' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'single_rtl_by_name_top.fsm');

    write_file(
        $composition_path,
        <<'FSM'
(?top:single_rtl_by_name_top
  (?ports:public_io
    core_clk
    rst_async_n
    =data_in<8
    =txd>
  )
  (?rtl:uart_tx)
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
    is($result->{composition_plan}->lane, 'C4', 'single rtl declared by-name uses the C4 lane');

    my %rtl_bindings = map { $_->{port_name} => $_->{signal_name} } @{$result->{composition_plan}->instances->[0]->port_bindings};
    is($rtl_bindings{core_clk}, 'core_clk', 'single rtl by-name keeps typed clock auto-wiring');
    is($rtl_bindings{rst_async_n}, 'rst_async_n', 'single rtl by-name keeps typed reset auto-wiring');
    is($rtl_bindings{data_in}, 'data_in', 'single rtl by-name resolves the unique same-name input');
    is($rtl_bindings{txd}, 'txd', 'single rtl by-name resolves the unique same-name output');
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

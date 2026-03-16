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

subtest 'single generated fsm child supports declared connect-by-name without explicit toplinks' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'single_fsm_by_name_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'single_fsm_by_name_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:single_fsm_by_name_top
  (?ports:public_io
    clk
    rst_n
    =enable<
    =output_data>8
  )
  (?fsmc:child child_src)
)

(?fsm:child_src
  (-state0
    (? enable
      (=1 (output_data> <= 8'1))
      (=0 (output_data> <= 8'0))
    )
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

    my $result = $pipeline->generate_hdl_from_file($composition_path);

    isa_ok($result->{composition_plan}, 'FSM::Composition::Plan');
    is($result->{composition_plan}->lane, 'C4', 'single generated fsm child uses the C4 by-name lane');
    is(scalar(@{$result->{composition_plan}->links}), 2, 'single-child by-name plan records both top input and top output links');
    is_deeply(
        [map { $_->{port_name}.'=>'.$_->{signal_name} } @{$result->{composition_plan}->instances->[0]->port_bindings}],
        ['clk=>clk', 'rst_n=>rst_n', 'enable=>enable', 'output_data=>output_data'],
        'single generated fsm child binds system and user ports directly by name',
    );

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\bmodule\s+single_fsm_by_name_top\b/s, 'generated HDL includes the single-child by-name top');
    like($hdl, qr/\.enable\(enable\)/s, 'generated HDL wires the by-name input directly');
    like($hdl, qr/\.output_data\(output_data\)/s, 'generated HDL wires the by-name output directly');
    unlike($hdl, qr/\bcomp_link_child_enable\b/s, 'single-child by-name input does not create a synthetic carrier net');
    unlike($hdl, qr/\bcomp_link_child_output_data\b/s, 'single-child by-name output does not create a synthetic carrier net');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );

    ok($success, 'CLI succeeds for single fsm child by-name composition');
    ok(-e $output_path, 'CLI writes HDL for single fsm child by-name composition');
};

subtest 'single combinational dt child supports declared connect-by-name without fake system ports' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'single_dt_by_name_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'single_dt_by_name_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:single_dt_by_name_top
  (?ports:public_io
    =data_in<8
    =result_data>8
  )
  (?dtc:router route_src)
)

(?dt:route_src
  (-route
    (result_data> = data_in)
  )
  (+size
    (data_in 8)
    (result_data 8)
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
    is($result->{composition_plan}->lane, 'C4', 'single combinational dt child uses the C4 by-name lane');
    is(scalar(@{$result->{composition_plan}->links}), 2, 'single dt child by-name plan records both top input and top output links');
    is_deeply(
        [map { $_->name } @{$result->{composition_plan}->instances->[0]->interface_ports}],
        ['data_in', 'result_data'],
        'single combinational dt child still keeps an honest non-system interface',
    );
    is_deeply(
        [map { $_->{port_name}.'=>'.$_->{signal_name} } @{$result->{composition_plan}->instances->[0]->port_bindings}],
        ['data_in=>data_in', 'result_data=>result_data'],
        'single dt child binds user ports directly by name',
    );

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\bmodule\s+single_dt_by_name_top\b/s, 'generated HDL includes the single dt child by-name top');
    like($hdl, qr/\.data_in\(data_in\)/s, 'generated HDL wires the by-name dt input directly');
    like($hdl, qr/\.result_data\(result_data\)/s, 'generated HDL wires the by-name dt output directly');
    unlike($hdl, qr/\binput\s+clk\b/s, 'single combinational dt child by-name top does not declare a fake clk input');
    unlike($hdl, qr/\binput\s+rst_n\b/s, 'single combinational dt child by-name top does not declare a fake rst_n input');
    unlike($hdl, qr/\bcomp_link_router_data_in\b/s, 'single dt child by-name input does not create a synthetic carrier net');
    unlike($hdl, qr/\bcomp_link_router_result_data\b/s, 'single dt child by-name output does not create a synthetic carrier net');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );

    ok($success, 'CLI succeeds for single dt child by-name composition');
    ok(-e $output_path, 'CLI writes HDL for single dt child by-name composition');
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

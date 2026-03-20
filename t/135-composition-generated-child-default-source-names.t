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

subtest 'named ?fsmc child defaults omitted source token to its own name' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'default_named_fsm_child_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'default_named_fsm_child_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:default_named_fsm_child_top
  (?ports:public_io
    clk
    rst_n
    output_data>8
  )
  (?fsmc:child_ctrl)
)

(?fsm:child_ctrl
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

    my $result = $pipeline->generate_hdl_from_file($composition_path);

    isa_ok($result->{composition_plan}, 'FSM::Composition::Plan');
    is($result->{composition_plan}->lane, 'C1', 'single-child named ?fsmc default-source composition stays in C1');
    is($result->{composition_plan}->instances->[0]->kind, 'fsmc', 'realized child stays fsmc');
    is($result->{composition_plan}->instances->[0]->instance_name, 'child_ctrl', 'instance name stays the declared child name');
    is($result->{composition_plan}->instances->[0]->source_name, 'child_ctrl', 'omitted ?fsmc source defaults to the child name');
    is($result->{composition_plan}->instances->[0]->module_name, 'child_ctrl', 'realized module name comes from the defaulted child source');

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\bmodule\s+child_ctrl\b/s, 'generated HDL includes the embedded child FSM module');
    like($hdl, qr/\bmodule\s+default_named_fsm_child_top\b/s, 'generated HDL includes the top module');

    my ($success) = run(
        command => ['./bin/fsmgen', '--quiet', '-o', $output_path, $composition_path],
    );

    ok($success, 'CLI succeeds when a named ?fsmc child omits its source token');
    ok(-e $output_path, 'CLI writes HDL for named ?fsmc default-source composition');
};

subtest 'named ?dtc child defaults omitted source token to its own name through --path lookup' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $libdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'default_named_dt_child_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'default_named_dt_child_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:default_named_dt_child_top
  (?ports:public_io
    data_in<8
    result_data>8
  )
  (?dtc:route_src)
)
FSM
    );

    write_file(
        File::Spec->catfile($libdir, 'route_src.fsm'),
        <<'FSM'
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
        source_search_paths => [$libdir],
    );

    my $result = $pipeline->generate_hdl_from_file($composition_path);

    isa_ok($result->{composition_plan}, 'FSM::Composition::Plan');
    is($result->{composition_plan}->lane, 'C1', 'single-child named ?dtc default-source composition stays in C1');
    is($result->{composition_plan}->instances->[0]->kind, 'dtc', 'realized child stays dtc');
    is($result->{composition_plan}->instances->[0]->instance_name, 'route_src', 'instance name stays the declared dt child name');
    is($result->{composition_plan}->instances->[0]->source_name, 'route_src', 'omitted ?dtc source defaults to the child name');
    is($result->{composition_plan}->instances->[0]->module_name, 'route_src', 'realized module name comes from the defaulted dt child source');

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\bmodule\s+route_src\b/s, 'generated HDL includes the external dt child module');
    like($hdl, qr/\bmodule\s+default_named_dt_child_top\b/s, 'generated HDL includes the top module');

    my ($success) = run(
        command => ['./bin/fsmgen', '--quiet', '--path', $libdir, '-o', $output_path, $composition_path],
    );

    ok($success, 'CLI succeeds when a named ?dtc child omits its source token');
    ok(-e $output_path, 'CLI writes HDL for named ?dtc default-source composition');
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

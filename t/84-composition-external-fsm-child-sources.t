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
use FSM::Composition::Net;

subtest 'single-child composition resolves sibling external child FSM source' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'external_single_child_top.fsm');
    my $child_path = File::Spec->catfile($tempdir, 'child_ctrl_src.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'external_single_child_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:external_single_child_top
  (?ports:public_io
    clk
    rst_n
    output_data>8
  )
  (?fsmc:child_ctrl child_ctrl_src)
)
FSM
    );

    write_file(
        $child_path,
        <<'FSM'
(?fsm:child_ctrl_src
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
    is($result->{composition_plan}->lane, 'C1', 'single-child external-child composition still records C1');
    is($result->{composition_plan}->instances->[0]->module_name, 'child_ctrl_src', 'realized child keeps module name from sibling source file');
    is($result->{composition_plan}->instances->[0]->interface_ports->[0]->name, 'clk', 'sibling external child exposes implicit clock');
    is($result->{composition_plan}->instances->[0]->interface_ports->[1]->name, 'rst_n', 'sibling external child exposes implicit rst_n');

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\bmodule\s+child_ctrl_src\b/s, 'generated HDL includes the realized sibling child module');
    like($hdl, qr/\bmodule\s+external_single_child_top\b/s, 'generated HDL includes the top module');
    like($hdl, qr/\.rst_n\(rst_n\)/s, 'generated top wires implicit rst_n deterministically');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );

    ok($success, 'CLI succeeds for sibling external child-FSM composition');
    ok(-e $output_path, 'CLI writes HDL output for sibling external child-FSM composition');
};

subtest 'multi-child composition resolves external child FSM sources through --path roots' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $libdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'external_two_child_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'external_two_child_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:external_two_child_top
  (?ports:public_io
    clk
    rst_n
    result_data>8
  )
  (?fsmc:producer producer_src)
  (?fsmc:consumer consumer_src)
  (?toplink:wiring
    /producer.output_data/consumer.input_data/
    /consumer.final_data/result_data/
  )
)
FSM
    );

    write_file(
        File::Spec->catfile($libdir, 'producer_src.fsm'),
        <<'FSM'
(?fsm:producer_src
  (-state0
    (output_data> <= 8'3)
  )
  (+size
    (output_data 8)
  )
)
FSM
    );

    write_file(
        File::Spec->catfile($libdir, 'consumer_src.fsm'),
        <<'FSM'
(?fsm:consumer_src
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
        source_search_paths => [$libdir],
    );

    my $result = $pipeline->generate_hdl_from_file($composition_path);

    isa_ok($result->{composition_plan}, 'FSM::Composition::Plan');
    is($result->{composition_plan}->lane, 'C2', 'multi-child external-child composition records C2');
    is(scalar(@{$result->{composition_plan}->instances}), 2, 'two external child FSM sources are realized');
    is(scalar(@{$result->{composition_plan}->nets}), 1, 'deterministic child-to-child net is still materialized');
    isa_ok($result->{composition_plan}->nets->[0], 'FSM::Composition::Net');
    is($result->{composition_plan}->instances->[0]->instance_name, 'producer', 'producer instance stays first');
    is($result->{composition_plan}->instances->[1]->instance_name, 'consumer', 'consumer instance stays second');

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\bmodule\s+producer_src\b/s, 'generated HDL includes producer module from external source');
    like($hdl, qr/\bmodule\s+consumer_src\b/s, 'generated HDL includes consumer module from external source');
    like($hdl, qr/\bwire\s+\[7:0\]\s+comp_link_producer_output_data;/s, 'generated top includes deterministic internal link net');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', '--path', $libdir, $composition_path],
    );

    ok($success, 'CLI succeeds for external child-FSM composition through --path');
    ok(-e $output_path, 'CLI writes HDL output for external child-FSM composition through --path');
};

subtest '--path roots override FSMLIB for composition child FSM source resolution' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $explicit_dir = tempdir(CLEANUP => 1);
    my $env_dir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'priority_child_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'priority_child_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:priority_child_top
  (?ports:public_io
    clk
    rst_n
    output_data>8
  )
  (?fsmc:child priority_child)
)
FSM
    );

    write_file(
        File::Spec->catfile($explicit_dir, 'priority_child.fsm'),
        <<'FSM'
(?fsm:from_explicit_child_root
  (-state0
    (output_data> <= 8'5)
  )
  (+size
    (output_data 8)
  )
)
FSM
    );

    write_file(
        File::Spec->catfile($env_dir, 'priority_child.fsm'),
        <<'FSM'
(?fsm:from_env_child_root
  (-state0
    (output_data> <= 8'9)
  )
  (+size
    (output_data 8)
  )
)
FSM
    );

    local $ENV{FSMLIB} = $env_dir;
    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', '--path', $explicit_dir, $composition_path],
    );

    ok($success, 'CLI succeeds when both --path and FSMLIB offer a matching child source');
    ok(-e $output_path, 'CLI writes HDL output for precedence fixture');

    my $hdl = slurp($output_path);
    like($hdl, qr/\bmodule\s+from_explicit_child_root\b/s, 'composition child source resolves from explicit --path root first');
    unlike($hdl, qr/\bmodule\s+from_env_child_root\b/s, 'FSMLIB candidate is ignored when explicit --path provides the child source');
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "Cannot open $path: $!";
    local $/ = undef;
    my $content = <$fh>;
    close $fh or die "Cannot close $path: $!";
    return $content;
}

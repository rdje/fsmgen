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

my $tempdir = tempdir(CLEANUP => 1);
my $pipeline = FSM::Pipeline::HDLGenerator->new(
    debug_level => 0,
    target_language => 'systemverilog',
    quiet => 1,
);

subtest 'implicit no-+system contract defaults to clk and rst_n' => sub {
    my $fsm_path = File::Spec->catfile($tempdir, 'implicit_defaults.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'implicit_defaults.sv');

    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:implicit_defaults
  (-drive_outputs
    (ready <= 1)
  )
)
FSM
    );

    my $result = $pipeline->generate_hdl_from_file($fsm_path);
    my $system = $result->{fsm_module}->effective_system_contract;
    my $hdl = $result->{hdl_code};

    is($system->{clock}, 'clk', 'implicit default keeps clk as the clock name');
    is($system->{reset}, 'rst_n', 'implicit default uses rst_n as the reset name');
    is($system->{reset_kind}, 'async', 'implicit default uses asynchronous reset semantics');
    is($system->{reset_active_level}, 0, 'implicit default uses active-low reset semantics');
    ok($system->{implicit}, 'implicit default marks the system contract as implicit');
    like($hdl, qr/\binput\s+wire\s+clk\b/s, 'generated HDL declares clk as an input');
    like($hdl, qr/\binput\s+wire\s+rst_n\b/s, 'generated HDL declares rst_n as an input');
    like($hdl, qr/always_ff\s*@\(posedge\s+clk\s+or\s+negedge\s+rst_n\)/s, 'generated HDL uses rst_n in sequential sensitivity lists');
    like($hdl, qr/if\s*\(!rst_n\)/s, 'generated HDL uses rst_n in reset tests');
    unlike($hdl, qr/\brstn\b/s, 'generated HDL does not leak the old implicit rstn name');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $fsm_path],
    );

    ok($success, 'CLI succeeds for an FSM that relies on implicit system defaults');
    ok(-e $output_path, 'CLI writes HDL output for implicit-system FSMs');
    my $cli_hdl = slurp($output_path);
    like($cli_hdl, qr/\binput\s+wire\s+rst_n\b/s, 'CLI output also uses rst_n as the implicit reset name');
};

subtest 'explicit legacy sreset name still overrides the implicit rst_n default but uses active-high sync semantics' => sub {
    my $fsm_path = File::Spec->catfile($tempdir, 'explicit_system_override.fsm');

    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:explicit_system_override
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-drive_outputs
    (ready <= 1)
  )
)
FSM
    );

    my $result = $pipeline->generate_hdl_from_file($fsm_path);
    my $system = $result->{fsm_module}->effective_system_contract;
    my $hdl = $result->{hdl_code};

    is($system->{clock}, 'clk', 'explicit +system keeps clk as the clock name');
    is($system->{reset}, 'rstn', 'explicit +system keeps rstn as the declared reset name');
    is($system->{reset_kind}, 'sync', 'sreset records synchronous reset semantics');
    is($system->{reset_active_level}, 1, 'sreset records active-high reset semantics');
    ok(!$system->{implicit}, 'explicit +system is not marked as implicit');
    like($hdl, qr/\binput\s+wire\s+rstn\b/s, 'generated HDL declares rstn for explicit +system');
    like($hdl, qr/always_ff\s*@\(posedge\s+clk\)/s, 'generated HDL uses synchronous reset event control for sreset');
    like($hdl, qr/if\s*\(rstn\)/s, 'generated HDL uses active-high reset test for sreset');
    unlike($hdl, qr/\brst_n\b/s, 'explicit +system does not get rewritten to rst_n');
};

subtest 'multi-child composition auto-wires implicit child system ports as clk and rst_n' => sub {
    my $composition_path = File::Spec->catfile($tempdir, 'implicit_multi_child_top.fsm');

    write_file(
        $composition_path,
        <<'FSM'
(?top:implicit_multi_child_top
  (?ports:public_io
    clk
    rst_n
    result_data>
  )
  (?fsmc:producer producer_src)
  (?fsmc:consumer consumer_src)
  (?wiring:wiring
    /producer.output_data/consumer.input_data/
    /consumer.result_data/result_data/
  )
)

(?fsm:producer_src
  (-drive_outputs
    (output_data> = 1)
  )
)

(?fsm:consumer_src
  (-drive_outputs
    (result_data> = input_data)
  )
)
FSM
    );

    my $result = $pipeline->generate_hdl_from_file($composition_path);
    my $producer = $result->{composition_plan}->instances->[0];
    my $consumer = $result->{composition_plan}->instances->[1];
    my @producer_interface_names = map { $_->name } @{$producer->interface_ports};
    my @consumer_interface_names = map { $_->name } @{$consumer->interface_ports};
    my $hdl = $result->{hdl_code};
    my $rst_bind_count = () = $hdl =~ /\.rst_n\(rst_n\)/g;
    my $clk_bind_count = () = $hdl =~ /\.clk\(clk\)/g;

    isa_ok($result->{composition_plan}, 'FSM::Composition::Plan');
    is($producer_interface_names[0], 'clk', 'producer interface still exposes clk first');
    is($producer_interface_names[1], 'rst_n', 'producer interface exposes rst_n for implicit-system children');
    is($consumer_interface_names[0], 'clk', 'consumer interface still exposes clk first');
    is($consumer_interface_names[1], 'rst_n', 'consumer interface exposes rst_n for implicit-system children');
    like($hdl, qr/\bmodule\s+producer_src\b/s, 'generated HDL includes the first implicit-system child FSM');
    like($hdl, qr/\bmodule\s+consumer_src\b/s, 'generated HDL includes the second implicit-system child FSM');
    like($hdl, qr/\binput\s+rst_n\b/s, 'generated top HDL declares rst_n as a top input');
    is($clk_bind_count, 2, 'generated top HDL auto-wires clk into both implicit-system children');
    is($rst_bind_count, 2, 'generated top HDL auto-wires rst_n into both implicit-system children');
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

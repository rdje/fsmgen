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

my $tempdir = tempdir(CLEANUP => 1);

subtest 'combinational peer-read shared-datapath families now synthesize one top-facing shared carrier' => sub {
    my $composition_path = write_fsm('shared_datapath_comb_runtime_top.fsm', <<'FSM');
(?top:shared_datapath_comb_runtime_top
  (?ports:public_io
    select
    left_status>8
    right_status>8
    result_data>8
  )
  (?fsmc:left left_src)
  (?fsmc:right right_src)
  (?fsmc:consumer consumer_src)
  (?toplink:wiring
    /select/left.select/
    /select/right.select/
    /select/consumer.select/
    /left.status_bus/left_status/
    /left.status_bus/consumer.status_bus/
    /right.status_bus/right_status/
    /consumer.result_data/result_data/
  )
)

(?fsm:left_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-path_a
    (<select==1'b0
      (status_bus> = 8'1)
    )
  )
  (+size
    (select 1)
    (status_bus 8)
  )
)

(?fsm:right_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-path_a
    (<select==1'b0
      (status_bus> = 8'2)
    )
  )
  (+size
    (select 1)
    (status_bus 8)
  )
)

(?fsm:consumer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-path_a
    (<select==1'b0
      (result_data> = status_bus)
    )
  )
  (+size
    (select 1)
    (status_bus 8)
    (result_data 8)
  )
)
FSM

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
    );

    my $result = $pipeline->generate_hdl_from_file($composition_path);
    my $candidate = $result->{module_info}{composition_shared_datapath_candidates}[0];
    my $hdl = $result->{hdl_code};

    is($candidate->{lifted_runtime_kind}, 'combinational_shared_reexport', 'shared candidate now records the bounded combinational top-facing runtime kind');
    is($candidate->{lifted_runtime_signal}, 'status_bus_shared_comb', 'shared candidate records the lifted combinational shared carrier');

    like($hdl, qr/\blogic\s+\[7:0\]\s+status_bus_shared_comb;/s, 'top HDL declares the lifted combinational shared carrier');
    like($hdl, qr/always_comb begin\s+status_bus_shared_comb = 1'b0;/s, 'top HDL defaults the lifted combinational shared carrier to zero');
    like($hdl, qr/if \(status_bus__8_d1_shared_en\) begin\s+status_bus_shared_comb = 8'd1;/s, 'top HDL updates the shared combinational carrier from the first aggregate value family');
    like($hdl, qr/if \(status_bus__8_d2_shared_en\) begin\s+status_bus_shared_comb = 8'd2;/s, 'top HDL updates the shared combinational carrier from the second aggregate value family');
    unlike($hdl, qr/\balways_ff\b/s, 'top HDL does not invent lifted sequential state for the combinational carrier');

    like($hdl, qr/\bwire\s+\[7:0\]\s+shared_dp_raw_left_status_bus;/s, 'top HDL declares the raw left contributor output binding');
    like($hdl, qr/\bwire\s+\[7:0\]\s+shared_dp_raw_right_status_bus;/s, 'top HDL declares the raw right contributor output binding');
    like($hdl, qr/left_src left \([\s\S]*?\.status_bus\(shared_dp_raw_left_status_bus\)/s, 'left contributor output now binds to a private raw source net');
    like($hdl, qr/right_src right \([\s\S]*?\.status_bus\(shared_dp_raw_right_status_bus\)/s, 'right contributor output now binds to a private raw source net');
    like($hdl, qr/consumer_src consumer \([\s\S]*?\.status_bus\(status_bus_shared_comb\)/s, 'peer-read child input now binds to the lifted combinational shared carrier');

    like($hdl, qr/assign left_status = status_bus_shared_comb;/s, 'top HDL preserves the first public top output from the shared combinational carrier');
    like($hdl, qr/assign right_status = status_bus_shared_comb;/s, 'top HDL preserves the second public top output from the shared combinational carrier');
};

subtest 'CLI reports the bounded combinational top-facing shared carrier runtime' => sub {
    my $composition_path = write_fsm('shared_datapath_comb_runtime_cli_top.fsm', <<'FSM');
(?top:shared_datapath_comb_runtime_cli_top
  (?ports:public_io
    select
    left_status>8
    right_status>8
    result_data>8
  )
  (?fsmc:left left_src)
  (?fsmc:right right_src)
  (?fsmc:consumer consumer_src)
  (?toplink:wiring
    /select/left.select/
    /select/right.select/
    /select/consumer.select/
    /left.status_bus/left_status/
    /left.status_bus/consumer.status_bus/
    /right.status_bus/right_status/
    /consumer.result_data/result_data/
  )
)

(?fsm:left_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-path_a
    (<select==1'b0
      (status_bus> = 8'1)
    )
  )
  (+size
    (select 1)
    (status_bus 8)
  )
)

(?fsm:right_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-path_a
    (<select==1'b0
      (status_bus> = 8'2)
    )
  )
  (+size
    (select 1)
    (status_bus 8)
  )
)

(?fsm:consumer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-path_a
    (<select==1'b0
      (result_data> = status_bus)
    )
  )
  (+size
    (select 1)
    (status_bus 8)
    (result_data 8)
  )
)
FSM

    my $output_path = File::Spec->catfile($tempdir, 'shared_datapath_comb_runtime_cli_top.sv');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, $composition_path],
    );

    ok($success, 'CLI succeeds for combinational shared-datapath runtime fixture');
    ok(-e $output_path, 'CLI writes HDL for combinational shared-datapath runtime fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/\* lifted runtime: combinational shared top-facing carrier active/s, 'CLI reports the active combinational shared-carrier runtime');
    like($combined_output, qr/\* lifted signal: status_bus_shared_comb/s, 'CLI reports the lifted combinational shared carrier name');
};

done_testing();

sub write_fsm {
    my ($filename, $content) = @_;
    my $path = File::Spec->catfile($tempdir, $filename);
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
    return $path;
}

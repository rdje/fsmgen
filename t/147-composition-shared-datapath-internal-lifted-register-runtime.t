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

subtest 'registered peer-read shared-datapath families now lift internally without public re-exports' => sub {
    my $composition_path = write_fsm('shared_datapath_internal_lift_top.fsm', <<'FSM');
(?top:shared_datapath_internal_lift_top
  (?ports:public_io
    clk
    rstn
    select
    left_result>8
    right_result>8
  )
  (?fsmc:left left_src)
  (?fsmc:right right_src)
  (?fsmc:consumer_left consumer_left_src)
  (?fsmc:consumer_right consumer_right_src)
  (?toplink:wiring
    /select/left.select/
    /select/right.select/
    /select/consumer_left.select/
    /select/consumer_right.select/
    /left.status_bus/consumer_left.status_bus/
    /right.status_bus/consumer_right.status_bus/
    /consumer_left.left_result/left_result/
    /consumer_right.right_result/right_result/
  )
)

(?fsm:left_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-path_a
    (<select==1'b0
      (status_bus> <= 8'1)
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
      (status_bus> <= 8'2)
    )
  )
  (+size
    (select 1)
    (status_bus 8)
  )
)

(?fsm:consumer_left_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-path_a
    (<select==1'b0
      (left_result> <= status_bus)
    )
  )
  (+size
    (select 1)
    (status_bus 8)
    (left_result 8)
  )
)

(?fsm:consumer_right_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-path_a
    (<select==1'b0
      (right_result> <= status_bus)
    )
  )
  (+size
    (select 1)
    (status_bus 8)
    (right_result 8)
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

    is_deeply($candidate->{top_output_signals}, [], 'shared candidate keeps no public top-output contributors in the internal-only case');
    is_deeply($candidate->{planned_reexport_top_output_signals}, [], 'shared candidate plans no public re-exports in the internal-only case');
    is($candidate->{reset_value}, "8'h00", 'shared candidate preserves the consistent lifted reset contract');
    is($candidate->{lifted_runtime_kind}, 'registered_shared_internal', 'shared candidate now records the internal-only lifted runtime kind');
    is($candidate->{lifted_runtime_next_signal}, 'status_bus_shared_next', 'shared candidate records the lifted next-value signal');
    is($candidate->{lifted_runtime_signal}, 'status_bus_shared_q', 'shared candidate records the lifted registered shared signal');
    is($candidate->{lifted_runtime_reset_value}, "8'h00", 'shared candidate records the lifted runtime reset value');

    like($hdl, qr/\blogic\s+\[7:0\]\s+status_bus_shared_next;/s, 'top HDL declares the lifted next-value register input');
    like($hdl, qr/\blogic\s+\[7:0\]\s+status_bus_shared_q;/s, 'top HDL declares the lifted shared register');
    like($hdl, qr/always_comb begin\s+status_bus_shared_next = status_bus_shared_q;/s, 'top HDL defaults the lifted next value from the lifted register');
    like($hdl, qr/if \(status_bus__8_d1_shared_en\) begin\s+status_bus_shared_next = 8'd1;/s, 'top HDL updates the lifted next value from the first aggregate value family');
    like($hdl, qr/if \(status_bus__8_d2_shared_en\) begin\s+status_bus_shared_next = 8'd2;/s, 'top HDL updates the lifted next value from the second aggregate value family');
    like($hdl, qr/always_ff \@\(posedge clk or negedge rstn\) begin\s+if \(!rstn\) begin\s+status_bus_shared_q <= 8'h00;/s, 'top HDL emits the lifted shared register with the recovered reset value');

    like($hdl, qr/\bwire\s+\[7:0\]\s+shared_dp_raw_left_status_bus;/s, 'top HDL declares the raw left contributor output binding');
    like($hdl, qr/\bwire\s+\[7:0\]\s+shared_dp_raw_right_status_bus;/s, 'top HDL declares the raw right contributor output binding');
    like($hdl, qr/left_src left \([\s\S]*?\.status_bus\(shared_dp_raw_left_status_bus\)/s, 'left contributor output now binds to a private raw source net');
    like($hdl, qr/right_src right \([\s\S]*?\.status_bus\(shared_dp_raw_right_status_bus\)/s, 'right contributor output now binds to a private raw source net');
    like($hdl, qr/consumer_left_src consumer_left \([\s\S]*?\.status_bus\(status_bus_shared_q\)/s, 'first peer-read child input now binds to the lifted shared register');
    like($hdl, qr/consumer_right_src consumer_right \([\s\S]*?\.status_bus\(status_bus_shared_q\)/s, 'second peer-read child input now binds to the lifted shared register');

    unlike($hdl, qr/\bassign\s+\w+\s*=\s*status_bus_shared_q;/s, 'top HDL keeps the lifted shared register internal when no public re-export is planned');
};

subtest 'CLI reports the internal-only lifted shared-register runtime for registered peer-read families' => sub {
    my $composition_path = write_fsm('shared_datapath_internal_lift_cli_top.fsm', <<'FSM');
(?top:shared_datapath_internal_lift_cli_top
  (?ports:public_io
    clk
    rstn
    select
    left_result>8
    right_result>8
  )
  (?fsmc:left left_src)
  (?fsmc:right right_src)
  (?fsmc:consumer_left consumer_left_src)
  (?fsmc:consumer_right consumer_right_src)
  (?toplink:wiring
    /select/left.select/
    /select/right.select/
    /select/consumer_left.select/
    /select/consumer_right.select/
    /left.status_bus/consumer_left.status_bus/
    /right.status_bus/consumer_right.status_bus/
    /consumer_left.left_result/left_result/
    /consumer_right.right_result/right_result/
  )
)

(?fsm:left_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-path_a
    (<select==1'b0
      (status_bus> <= 8'1)
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
      (status_bus> <= 8'2)
    )
  )
  (+size
    (select 1)
    (status_bus 8)
  )
)

(?fsm:consumer_left_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-path_a
    (<select==1'b0
      (left_result> <= status_bus)
    )
  )
  (+size
    (select 1)
    (status_bus 8)
    (left_result 8)
  )
)

(?fsm:consumer_right_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-path_a
    (<select==1'b0
      (right_result> <= status_bus)
    )
  )
  (+size
    (select 1)
    (status_bus 8)
    (right_result 8)
  )
)
FSM

    my $output_path = File::Spec->catfile($tempdir, 'shared_datapath_internal_lift_cli_top.sv');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, $composition_path],
    );

    ok($success, 'CLI succeeds for internal-only lifted shared-datapath runtime fixture');
    ok(-e $output_path, 'CLI writes HDL for internal-only lifted shared-datapath runtime fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/\* lifted runtime: registered shared internal lift active/s, 'CLI reports the active internal-only lifted shared-register runtime');
    like($combined_output, qr/\* lifted signal: status_bus_shared_q/s, 'CLI reports the lifted shared signal name');
    like($combined_output, qr/\* lifted reset: 8'h00/s, 'CLI reports the lifted shared reset value');
    unlike($combined_output, qr/\* planned top re-exports:/s, 'CLI does not invent planned public re-exports for the internal-only lifted case');
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

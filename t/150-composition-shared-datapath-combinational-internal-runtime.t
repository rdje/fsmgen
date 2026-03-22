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

subtest 'combinational peer-read shared-datapath families now synthesize one top-local shared carrier without public re-exports' => sub {
    my $composition_path = write_fsm('shared_datapath_comb_internal_top.fsm', <<'FSM');
(?top:shared_datapath_comb_internal_top
  (?ports:public_io
    select
    left_result>8
    right_result>8
  )
  (?fsmc:left left_src)
  (?fsmc:right right_src)
  (?fsmc:left_consumer left_consumer_src)
  (?fsmc:right_consumer right_consumer_src)
  (?toplink:wiring
    /select/left.select/
    /select/right.select/
    /select/left_consumer.select/
    /select/right_consumer.select/
    /left.status_bus/left_consumer.status_bus/
    /right.status_bus/right_consumer.status_bus/
    /left_consumer.result_data/left_result/
    /right_consumer.result_data/right_result/
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

(?fsm:left_consumer_src
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

(?fsm:right_consumer_src
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
    my ($candidate) = grep {
        ($_->{signal_name} || '') eq 'status_bus'
    } @{$result->{module_info}{composition_shared_datapath_candidates} || []};
    my $hdl = $result->{hdl_code};

    ok($candidate, 'shared-datapath candidate metadata includes the internal-only status_bus family');

    is($candidate->{storage_class}, 'combinational', 'shared candidate is classified as combinational');
    is($candidate->{peer_input_count}, 2, 'shared candidate reports both peer-read input endpoints');
    is($candidate->{default_lifted_visibility}, 'top_local', 'shared combinational internal-only family now lifts into one top-local carrier');
    is($candidate->{peer_read_policy}, 'top_local_only', 'shared combinational internal-only family advertises the top-local carrier policy');
    is(
        $candidate->{peer_read_block_reason},
        'combinational shared families may lift only into top-local combinational carriers and are not internalized into lifted state',
        'shared combinational internal-only family surfaces the bounded top-local carrier constraint',
    );
    is_deeply(
        $candidate->{planned_reexport_top_output_signals},
        [],
        'shared combinational internal-only family does not invent public re-exports',
    );
    is($candidate->{lifted_runtime_kind}, 'combinational_shared_internal', 'shared candidate records the bounded internal-only combinational runtime kind');
    is($candidate->{lifted_runtime_signal}, 'status_bus_shared_comb', 'shared candidate records the lifted top-local combinational carrier');

    like($hdl, qr/\blogic\s+\[7:0\]\s+status_bus_shared_comb;/s, 'top HDL declares the lifted top-local combinational carrier');
    like($hdl, qr/always_comb begin\s+status_bus_shared_comb = 1'b0;/s, 'top HDL defaults the lifted top-local combinational carrier to zero');
    like($hdl, qr/if \(status_bus__8_d1_shared_en\) begin\s+status_bus_shared_comb = 8'd1;/s, 'top HDL updates the top-local combinational carrier from the first aggregate value family');
    like($hdl, qr/if \(status_bus__8_d2_shared_en\) begin\s+status_bus_shared_comb = 8'd2;/s, 'top HDL updates the top-local combinational carrier from the second aggregate value family');
    unlike($hdl, qr/\balways_ff\b/s, 'top HDL does not invent lifted sequential state for the internal-only combinational carrier');

    like($hdl, qr/\bwire\s+\[7:0\]\s+shared_dp_raw_left_status_bus;/s, 'top HDL declares the raw left contributor output binding');
    like($hdl, qr/\bwire\s+\[7:0\]\s+shared_dp_raw_right_status_bus;/s, 'top HDL declares the raw right contributor output binding');
    like($hdl, qr/left_src left \([\s\S]*?\.status_bus\(shared_dp_raw_left_status_bus\)/s, 'left contributor output now binds to a private raw source net');
    like($hdl, qr/right_src right \([\s\S]*?\.status_bus\(shared_dp_raw_right_status_bus\)/s, 'right contributor output now binds to a private raw source net');
    like($hdl, qr/left_consumer_src left_consumer \([\s\S]*?\.status_bus\(status_bus_shared_comb\)/s, 'first peer-read child input now binds to the lifted top-local combinational carrier');
    like($hdl, qr/right_consumer_src right_consumer \([\s\S]*?\.status_bus\(status_bus_shared_comb\)/s, 'second peer-read child input now binds to the lifted top-local combinational carrier');
    unlike($hdl, qr/assign\s+\w+\s*=\s*status_bus_shared_comb;/s, 'top HDL does not invent public re-export assignments for the internal-only combinational carrier');
};

subtest 'CLI reports the bounded internal-only combinational shared carrier runtime' => sub {
    my $composition_path = write_fsm('shared_datapath_comb_internal_cli_top.fsm', <<'FSM');
(?top:shared_datapath_comb_internal_cli_top
  (?ports:public_io
    select
    left_result>8
    right_result>8
  )
  (?fsmc:left left_src)
  (?fsmc:right right_src)
  (?fsmc:left_consumer left_consumer_src)
  (?fsmc:right_consumer right_consumer_src)
  (?toplink:wiring
    /select/left.select/
    /select/right.select/
    /select/left_consumer.select/
    /select/right_consumer.select/
    /left.status_bus/left_consumer.status_bus/
    /right.status_bus/right_consumer.status_bus/
    /left_consumer.result_data/left_result/
    /right_consumer.result_data/right_result/
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

(?fsm:left_consumer_src
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

(?fsm:right_consumer_src
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

    my $output_path = File::Spec->catfile($tempdir, 'shared_datapath_comb_internal_cli_top.sv');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, $composition_path],
    );

    ok($success, 'CLI succeeds for internal-only combinational shared-datapath runtime fixture');
    ok(-e $output_path, 'CLI writes HDL for internal-only combinational shared-datapath runtime fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/\* default lifted visibility: top_local/s, 'CLI reports the top-local default lifted visibility');
    like($combined_output, qr/\* peer-read policy: top-local-combinational-only/s, 'CLI reports the top-local combinational peer-read policy');
    like(
        $combined_output,
        qr/\* peer-read constraint: combinational shared families may lift only into top-local combinational carriers and are not internalized into lifted state/s,
        'CLI reports the internal-only combinational peer-read constraint',
    );
    like($combined_output, qr/\* lifted runtime: combinational shared top-local carrier active/s, 'CLI reports the active internal-only combinational shared carrier runtime');
    like($combined_output, qr/\* lifted signal: status_bus_shared_comb/s, 'CLI reports the lifted internal-only combinational carrier name');
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

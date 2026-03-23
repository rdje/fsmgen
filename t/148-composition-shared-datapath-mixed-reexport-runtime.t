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

subtest 'registered peer-read shared-datapath families now lift across mixed public and internal carriers' => sub {
    my $composition_path = write_fsm('shared_datapath_mixed_reexport_top.fsm', <<'FSM');
(?top:shared_datapath_mixed_reexport_top
  (?ports:public_io
    clk
    rstn
    select
    left_status>8
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
    /left.status_bus/left_status/
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

    is_deeply($candidate->{top_output_signals}, ['left_status'], 'shared candidate preserves the one public top-output contributor in the mixed case');
    is_deeply($candidate->{planned_reexport_top_output_signals}, ['left_status'], 'shared candidate plans only the real public re-export in the mixed case');
    is($candidate->{peer_input_count}, 2, 'shared candidate preserves both actual peer-read endpoints');
    is_deeply(
        $candidate->{peer_input_endpoints},
        [
            {
                instance_name => 'consumer_left',
                module_name => 'consumer_left_src',
                endpoint => 'consumer_left.status_bus',
                bound_signal => 'left_status',
                bound_signals => ['left_status'],
            },
            {
                instance_name => 'consumer_right',
                module_name => 'consumer_right_src',
                endpoint => 'consumer_right.status_bus',
                bound_signal => 'comp_link_right_status_bus',
                bound_signals => ['comp_link_right_status_bus'],
            },
        ],
        'shared candidate keeps only peer inputs actually bound to contributor carriers',
    );
    is($candidate->{lifted_runtime_kind}, 'registered_shared_reexport', 'shared candidate still uses the public re-export runtime kind in the mixed case');
    is($candidate->{lifted_runtime_signal}, 'status_bus_shared_q', 'shared candidate records the lifted registered shared signal');

    like($hdl, qr/\blogic\s+\[7:0\]\s+status_bus_shared_q;/s, 'top HDL declares the lifted shared register');
    like($hdl, qr/assign left_status = status_bus_shared_q;/s, 'top HDL re-exports the preserved public top output from the lifted register');
    like($hdl, qr/consumer_left_src consumer_left \([\s\S]*?\.status_bus\(status_bus_shared_q\)/s, 'first peer-read child input now binds to the lifted shared register');
    like($hdl, qr/consumer_right_src consumer_right \([\s\S]*?\.status_bus\(status_bus_shared_q\)/s, 'second peer-read child input now binds to the lifted shared register');
    like($hdl, qr/left_src left \([\s\S]*?\.status_bus\(shared_dp_raw_left_status_bus\)/s, 'left contributor output now binds to a private raw source net');
    like($hdl, qr/right_src right \([\s\S]*?\.status_bus\(shared_dp_raw_right_status_bus\)/s, 'right contributor output now binds to a private raw source net');
    unlike($hdl, qr/assign comp_link_right_status_bus = status_bus_shared_q;/s, 'top HDL does not invent a public-style re-export for the internal carrier side');
};

subtest 'CLI reports mixed-boundary lifted shared-register runtime with only the preserved public re-export' => sub {
    my $composition_path = write_fsm('shared_datapath_mixed_reexport_cli_top.fsm', <<'FSM');
(?top:shared_datapath_mixed_reexport_cli_top
  (?ports:public_io
    clk
    rstn
    select
    left_status>8
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
    /left.status_bus/left_status/
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

    my $output_path = File::Spec->catfile($tempdir, 'shared_datapath_mixed_reexport_cli_top.sv');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, $composition_path],
    );

    ok($success, 'CLI succeeds for mixed-boundary lifted shared-datapath runtime fixture');
    ok(-e $output_path, 'CLI writes HDL for mixed-boundary lifted shared-datapath runtime fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/\* planned top re-exports: left_status/s, 'CLI reports only the preserved public re-export in the mixed case');
    like($combined_output, qr/\* lifted runtime: registered shared re-export active/s, 'CLI reports the active lifted shared-register runtime');
    like($combined_output, qr/\* lifted signal: status_bus_shared_q/s, 'CLI reports the lifted shared signal name');
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

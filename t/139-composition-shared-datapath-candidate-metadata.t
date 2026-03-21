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

subtest 'composition module_info surfaces shared-datapath candidates across multi-fsm child outputs' => sub {
    my $composition_path = write_fsm('shared_datapath_candidate_top.fsm', <<'FSM');
(?top:shared_datapath_candidate_top
  (?ports:public_io
    clk
    rstn
    left_status>8
    right_status>8
  )
  (?fsmc:left left_src)
  (?fsmc:right right_src)
  (?toplink:wiring
    /left.status_bus/left_status/
    /right.status_bus/right_status/
  )
)

(?fsm:left_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (status_bus> <= 8'1)
  )
  (+size
    (status_bus 8)
  )
)

(?fsm:right_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (status_bus> <= 8'2)
  )
  (+size
    (status_bus 8)
  )
)
FSM

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
    );

    my $result = $pipeline->generate_hdl_from_file($composition_path);
    my $module_info = $result->{module_info};

    is($result->{composition_plan}->lane, 'C2', 'two fsm children with explicit top wiring stay in C2');
    is($module_info->{composition_shared_datapath_candidate_count}, 1, 'top module_info reports one shared-datapath candidate family');
    is($result->{statistics}{composition_shared_datapath_candidate_count}, 1, 'statistics report one shared-datapath candidate family');
    is_deeply(
        $module_info->{composition_shared_datapath_candidates},
        [
            {
                signal_name => 'status_bus',
                width => 8,
                interface_type => 'data',
                contributor_count => 2,
                contributors => [
                    {
                        instance_name => 'left',
                        module_name => 'left_src',
                        endpoint => 'left.status_bus',
                        bound_signal => 'left_status',
                        drive_intent => {
                            multiplexer_type => 'flop',
                            default_value => 'status_bus',
                            driver_count => 1,
                            driver_blocks => ['-state0'],
                            rhs_values => ["8'd1"],
                            driver_enable_signals => ['state0_status_bus__8_d1_en'],
                            family_enable_signals => ['status_bus__8_d1_en'],
                            rhs_enable_families => [
                                {
                                    rhs_value => "8'd1",
                                    family_enable_signal => 'status_bus__8_d1_en',
                                    driver_blocks => ['-state0'],
                                    driver_enable_signals => ['state0_status_bus__8_d1_en'],
                                },
                            ],
                        },
                    },
                    {
                        instance_name => 'right',
                        module_name => 'right_src',
                        endpoint => 'right.status_bus',
                        bound_signal => 'right_status',
                        drive_intent => {
                            multiplexer_type => 'flop',
                            default_value => 'status_bus',
                            driver_count => 1,
                            driver_blocks => ['-state0'],
                            rhs_values => ["8'd2"],
                            driver_enable_signals => ['state0_status_bus__8_d2_en'],
                            family_enable_signals => ['status_bus__8_d2_en'],
                            rhs_enable_families => [
                                {
                                    rhs_value => "8'd2",
                                    family_enable_signal => 'status_bus__8_d2_en',
                                    driver_blocks => ['-state0'],
                                    driver_enable_signals => ['state0_status_bus__8_d2_en'],
                                },
                            ],
                        },
                    },
                ],
                top_output_signals => ['left_status', 'right_status'],
                aggregate_target_enable_signal => 'status_bus_shared_en',
                aggregate_enable_family_count => 2,
                aggregate_enable_families => [
                    {
                        rhs_value => "8'd1",
                        aggregate_enable_signal => 'status_bus__8_d1_shared_en',
                        contributor_count => 1,
                        contributors => [
                            {
                                endpoint => 'left.status_bus',
                                family_enable_signal => 'status_bus__8_d1_en',
                                driver_blocks => ['-state0'],
                                driver_enable_signals => ['state0_status_bus__8_d1_en'],
                            },
                        ],
                    },
                    {
                        rhs_value => "8'd2",
                        aggregate_enable_signal => 'status_bus__8_d2_shared_en',
                        contributor_count => 1,
                        contributors => [
                            {
                                endpoint => 'right.status_bus',
                                family_enable_signal => 'status_bus__8_d2_en',
                                driver_blocks => ['-state0'],
                                driver_enable_signals => ['state0_status_bus__8_d2_en'],
                            },
                        ],
                    },
                ],
            },
        ],
        'top module_info groups same-name fsm child outputs into one shared-datapath candidate family',
    );
};

subtest 'CLI prints shared-datapath candidate summary for composition tops' => sub {
    my $composition_path = write_fsm('shared_datapath_candidate_cli_top.fsm', <<'FSM');
(?top:shared_datapath_candidate_cli_top
  (?ports:public_io
    clk
    rstn
    left_status>8
    right_status>8
  )
  (?fsmc:left left_src)
  (?fsmc:right right_src)
  (?toplink:wiring
    /left.status_bus/left_status/
    /right.status_bus/right_status/
  )
)

(?fsm:left_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (status_bus> <= 8'1)
  )
  (+size
    (status_bus 8)
  )
)

(?fsm:right_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (status_bus> <= 8'2)
  )
  (+size
    (status_bus 8)
  )
)
FSM
    my $output_path = File::Spec->catfile($tempdir, 'shared_datapath_candidate_cli_top.sv');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, $composition_path],
    );

    ok($success, 'CLI succeeds for shared-datapath candidate summary fixture');
    ok(-e $output_path, 'CLI writes HDL for shared-datapath candidate summary fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/Shared-Datapath Candidates:/s, 'CLI prints shared-datapath candidate summary header');
    like($combined_output, qr/Count:\s+1/s, 'CLI reports one shared-datapath candidate family');
    like($combined_output, qr/status_bus \[width=8, type=data\] from left\.status_bus, right\.status_bus \(top outputs: left_status, right_status\)/s, 'CLI prints the grouped same-name output family');
    like($combined_output, qr/\* aggregate target enable: status_bus_shared_en/s, 'CLI prints the shared target aggregate enable name');
    like($combined_output, qr/\* aggregate value 8'd1 => status_bus__8_d1_shared_en from left\.status_bus\/status_bus__8_d1_en/s, 'CLI prints the first aggregate value-enable family');
    like($combined_output, qr/\* aggregate value 8'd2 => status_bus__8_d2_shared_en from right\.status_bus\/status_bus__8_d2_en/s, 'CLI prints the second aggregate value-enable family');
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

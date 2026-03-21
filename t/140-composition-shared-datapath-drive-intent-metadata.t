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

subtest 'realized fsm children surface output drive-family metadata for shared-datapath planning' => sub {
    my $composition_path = write_fsm('shared_datapath_drive_intent_top.fsm', <<'FSM');
(?top:shared_datapath_drive_intent_top
  (?ports:public_io
    clk
    rstn
    select
    left_status>8
    right_status>8
  )
  (?fsmc:left left_src)
  (?fsmc:right right_src)
  (?toplink:wiring
    /select/left.select/
    /select/right.select/
    /left.status_bus/left_status/
    /right.status_bus/right_status/
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
  (-path_b
    (<select==1'b1
      (status_bus> <= 8'2)
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
      (status_bus> <= 8'3)
    )
  )
  (-path_b
    (<select==1'b1
      (status_bus> <= 8'4)
    )
  )
  (+size
    (select 1)
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
    my $left_info = $result->{composition_plan}->instances->[0]->module_info;
    my $module_info = $result->{module_info};

    is($left_info->{output_drive_family_count}, 1, 'realized left fsm child reports one output drive family');
    is_deeply(
        $left_info->{output_drive_families},
        [
            {
                signal_name => 'status_bus',
                width => 8,
                multiplexer_type => 'flop',
                default_value => 'status_bus',
                driver_count => 2,
                driver_blocks => ['-path_a', '-path_b'],
                rhs_values => ["8'd1", "8'd2"],
                driver_enable_signals => [
                    'path_a_status_bus__8_d1_en',
                    'path_b_status_bus__8_d2_en',
                ],
                family_enable_signals => [
                    'status_bus__8_d1_en',
                    'status_bus__8_d2_en',
                ],
                rhs_enable_families => [
                    {
                        rhs_value => "8'd1",
                        family_enable_signal => 'status_bus__8_d1_en',
                        driver_blocks => ['-path_a'],
                        driver_enable_signals => ['path_a_status_bus__8_d1_en'],
                    },
                    {
                        rhs_value => "8'd2",
                        family_enable_signal => 'status_bus__8_d2_en',
                        driver_blocks => ['-path_b'],
                        driver_enable_signals => ['path_b_status_bus__8_d2_en'],
                    },
                ],
            },
        ],
        'realized fsm child preserves output drive-family metadata',
    );

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
                            driver_count => 2,
                            driver_blocks => ['-path_a', '-path_b'],
                            rhs_values => ["8'd1", "8'd2"],
                            driver_enable_signals => [
                                'path_a_status_bus__8_d1_en',
                                'path_b_status_bus__8_d2_en',
                            ],
                            family_enable_signals => [
                                'status_bus__8_d1_en',
                                'status_bus__8_d2_en',
                            ],
                            rhs_enable_families => [
                                {
                                    rhs_value => "8'd1",
                                    family_enable_signal => 'status_bus__8_d1_en',
                                    driver_blocks => ['-path_a'],
                                    driver_enable_signals => ['path_a_status_bus__8_d1_en'],
                                },
                                {
                                    rhs_value => "8'd2",
                                    family_enable_signal => 'status_bus__8_d2_en',
                                    driver_blocks => ['-path_b'],
                                    driver_enable_signals => ['path_b_status_bus__8_d2_en'],
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
                            driver_count => 2,
                            driver_blocks => ['-path_a', '-path_b'],
                            rhs_values => ["8'd3", "8'd4"],
                            driver_enable_signals => [
                                'path_a_status_bus__8_d3_en',
                                'path_b_status_bus__8_d4_en',
                            ],
                            family_enable_signals => [
                                'status_bus__8_d3_en',
                                'status_bus__8_d4_en',
                            ],
                            rhs_enable_families => [
                                {
                                    rhs_value => "8'd3",
                                    family_enable_signal => 'status_bus__8_d3_en',
                                    driver_blocks => ['-path_a'],
                                    driver_enable_signals => ['path_a_status_bus__8_d3_en'],
                                },
                                {
                                    rhs_value => "8'd4",
                                    family_enable_signal => 'status_bus__8_d4_en',
                                    driver_blocks => ['-path_b'],
                                    driver_enable_signals => ['path_b_status_bus__8_d4_en'],
                                },
                            ],
                        },
                    },
                ],
                top_output_signals => ['left_status', 'right_status'],
                aggregate_target_enable_signal => 'status_bus_shared_en',
                multi_value_conflict_signal => 'status_bus_multi_value_conflict',
                aggregate_enable_family_count => 4,
                aggregate_enable_families => [
                    {
                        rhs_value => "8'd1",
                        aggregate_enable_signal => 'status_bus__8_d1_shared_en',
                        same_value_conflict_signal => 'status_bus__8_d1_multi_src_conflict',
                        contributor_count => 1,
                        contributors => [
                            {
                                endpoint => 'left.status_bus',
                                family_enable_signal => 'status_bus__8_d1_en',
                                driver_blocks => ['-path_a'],
                                driver_enable_signals => ['path_a_status_bus__8_d1_en'],
                            },
                        ],
                    },
                    {
                        rhs_value => "8'd2",
                        aggregate_enable_signal => 'status_bus__8_d2_shared_en',
                        same_value_conflict_signal => 'status_bus__8_d2_multi_src_conflict',
                        contributor_count => 1,
                        contributors => [
                            {
                                endpoint => 'left.status_bus',
                                family_enable_signal => 'status_bus__8_d2_en',
                                driver_blocks => ['-path_b'],
                                driver_enable_signals => ['path_b_status_bus__8_d2_en'],
                            },
                        ],
                    },
                    {
                        rhs_value => "8'd3",
                        aggregate_enable_signal => 'status_bus__8_d3_shared_en',
                        same_value_conflict_signal => 'status_bus__8_d3_multi_src_conflict',
                        contributor_count => 1,
                        contributors => [
                            {
                                endpoint => 'right.status_bus',
                                family_enable_signal => 'status_bus__8_d3_en',
                                driver_blocks => ['-path_a'],
                                driver_enable_signals => ['path_a_status_bus__8_d3_en'],
                            },
                        ],
                    },
                    {
                        rhs_value => "8'd4",
                        aggregate_enable_signal => 'status_bus__8_d4_shared_en',
                        same_value_conflict_signal => 'status_bus__8_d4_multi_src_conflict',
                        contributor_count => 1,
                        contributors => [
                            {
                                endpoint => 'right.status_bus',
                                family_enable_signal => 'status_bus__8_d4_en',
                                driver_blocks => ['-path_b'],
                                driver_enable_signals => ['path_b_status_bus__8_d4_en'],
                            },
                        ],
                    },
                ],
            },
        ],
        'shared-datapath candidates now carry per-child drive intent from generated assignment analysis',
    );
};

subtest 'CLI prints per-child drive intent for shared-datapath candidates' => sub {
    my $composition_path = write_fsm('shared_datapath_drive_intent_cli_top.fsm', <<'FSM');
(?top:shared_datapath_drive_intent_cli_top
  (?ports:public_io
    clk
    rstn
    select
    left_status>8
    right_status>8
  )
  (?fsmc:left left_src)
  (?fsmc:right right_src)
  (?toplink:wiring
    /select/left.select/
    /select/right.select/
    /left.status_bus/left_status/
    /right.status_bus/right_status/
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
  (-path_b
    (<select==1'b1
      (status_bus> <= 8'2)
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
      (status_bus> <= 8'3)
    )
  )
  (-path_b
    (<select==1'b1
      (status_bus> <= 8'4)
    )
  )
  (+size
    (select 1)
    (status_bus 8)
  )
)
FSM
    my $output_path = File::Spec->catfile($tempdir, 'shared_datapath_drive_intent_cli_top.sv');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, $composition_path],
    );

    ok($success, 'CLI succeeds for shared-datapath drive-intent summary fixture');
    ok(-e $output_path, 'CLI writes HDL for shared-datapath drive-intent summary fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/Shared-Datapath Candidates:/s, 'CLI prints shared-datapath candidate summary header');
    like($combined_output, qr/status_bus \[width=8, type=data\] from left\.status_bus, right\.status_bus \(top outputs: left_status, right_status\)/s, 'CLI still prints the grouped shared-datapath family');
    like($combined_output, qr/\* aggregate target enable: status_bus_shared_en/s, 'CLI prints the whole-target aggregate enable for the candidate');
    like($combined_output, qr/\* multi-value conflict: status_bus_multi_value_conflict/s, 'CLI prints the whole-target multi-value conflict name');
    like($combined_output, qr/\* aggregate value 8'd1 => status_bus__8_d1_shared_en from left\.status_bus\/status_bus__8_d1_en/s, 'CLI prints the first aggregate value-enable family');
    like($combined_output, qr/\* same-value conflict 8'd1 => status_bus__8_d1_multi_src_conflict/s, 'CLI prints the first same-value conflict name');
    like($combined_output, qr/\* aggregate value 8'd4 => status_bus__8_d4_shared_en from right\.status_bus\/status_bus__8_d4_en/s, 'CLI prints the last aggregate value-enable family');
    like($combined_output, qr/\* same-value conflict 8'd4 => status_bus__8_d4_multi_src_conflict/s, 'CLI prints the last same-value conflict name');
    like($combined_output, qr/\* left\.status_bus drives via flop blocks \[-path_a, -path_b\] with RHS \[8'd1, 8'd2\]/s, 'CLI prints per-child drive intent for the left contributor');
    like($combined_output, qr/\* right\.status_bus drives via flop blocks \[-path_a, -path_b\] with RHS \[8'd3, 8'd4\]/s, 'CLI prints per-child drive intent for the right contributor');
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

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

subtest 'shared-datapath candidates aggregate same-value enable families across contributors' => sub {
    my $composition_path = write_fsm('shared_datapath_aggregate_enable_top.fsm', <<'FSM');
(?top:shared_datapath_aggregate_enable_top
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
      (status_bus> <= 8'1)
    )
  )
  (-path_b
    (<select==1'b1
      (status_bus> <= 8'3)
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
    my $candidate = $result->{module_info}{composition_shared_datapath_candidates}[0];

    is($candidate->{aggregate_target_enable_signal}, 'status_bus_shared_en', 'candidate reports one deterministic whole-target aggregate enable');
    is($candidate->{multi_value_conflict_signal}, 'status_bus_multi_value_conflict', 'candidate reports one deterministic whole-target multi-value conflict name');
    is_deeply(
        $candidate->{multi_value_assertion},
        {
            kind => 'onehot0',
            result_signal => 'status_bus_multi_value_conflict',
            input_count => 3,
            input_enable_signals => [
                'status_bus__8_d1_shared_en',
                'status_bus__8_d2_shared_en',
                'status_bus__8_d3_shared_en',
            ],
        },
        'candidate surfaces onehot0-style whole-target assertion metadata over aggregate value enables',
    );
    is($candidate->{aggregate_enable_family_count}, 3, 'candidate reports three aggregate value-enable families');
    is_deeply(
        $candidate->{aggregate_enable_families},
        [
            {
                rhs_value => "8'd1",
                aggregate_enable_signal => 'status_bus__8_d1_shared_en',
                same_value_conflict_signal => 'status_bus__8_d1_multi_src_conflict',
                same_value_assertion => {
                    kind => 'onehot0',
                    result_signal => 'status_bus__8_d1_multi_src_conflict',
                    input_count => 2,
                    input_enable_signals => [
                        'left_status_bus__8_d1_src_en',
                        'right_status_bus__8_d1_src_en',
                    ],
                },
                contributor_count => 2,
                contributors => [
                    {
                        endpoint => 'left.status_bus',
                        family_enable_signal => 'status_bus__8_d1_en',
                        source_enable_signal => 'left_status_bus__8_d1_src_en',
                        driver_blocks => ['-path_a'],
                        driver_enable_signals => ['path_a_status_bus__8_d1_en'],
                    },
                    {
                        endpoint => 'right.status_bus',
                        family_enable_signal => 'status_bus__8_d1_en',
                        source_enable_signal => 'right_status_bus__8_d1_src_en',
                        driver_blocks => ['-path_a'],
                        driver_enable_signals => ['path_a_status_bus__8_d1_en'],
                    },
                ],
            },
            {
                rhs_value => "8'd2",
                aggregate_enable_signal => 'status_bus__8_d2_shared_en',
                same_value_conflict_signal => 'status_bus__8_d2_multi_src_conflict',
                same_value_assertion => {
                    kind => 'onehot0',
                    result_signal => 'status_bus__8_d2_multi_src_conflict',
                    input_count => 1,
                    input_enable_signals => ['left_status_bus__8_d2_src_en'],
                },
                contributor_count => 1,
                contributors => [
                    {
                        endpoint => 'left.status_bus',
                        family_enable_signal => 'status_bus__8_d2_en',
                        source_enable_signal => 'left_status_bus__8_d2_src_en',
                        driver_blocks => ['-path_b'],
                        driver_enable_signals => ['path_b_status_bus__8_d2_en'],
                    },
                ],
            },
            {
                rhs_value => "8'd3",
                aggregate_enable_signal => 'status_bus__8_d3_shared_en',
                same_value_conflict_signal => 'status_bus__8_d3_multi_src_conflict',
                same_value_assertion => {
                    kind => 'onehot0',
                    result_signal => 'status_bus__8_d3_multi_src_conflict',
                    input_count => 1,
                    input_enable_signals => ['right_status_bus__8_d3_src_en'],
                },
                contributor_count => 1,
                contributors => [
                    {
                        endpoint => 'right.status_bus',
                        family_enable_signal => 'status_bus__8_d3_en',
                        source_enable_signal => 'right_status_bus__8_d3_src_en',
                        driver_blocks => ['-path_b'],
                        driver_enable_signals => ['path_b_status_bus__8_d3_en'],
                    },
                ],
            },
        ],
        'candidate groups same-value contributor families under one aggregate enable family',
    );
};

subtest 'CLI prints shared aggregate enable families for same-value contributors' => sub {
    my $composition_path = write_fsm('shared_datapath_aggregate_enable_cli_top.fsm', <<'FSM');
(?top:shared_datapath_aggregate_enable_cli_top
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
      (status_bus> <= 8'1)
    )
  )
  (-path_b
    (<select==1'b1
      (status_bus> <= 8'3)
    )
  )
  (+size
    (select 1)
    (status_bus 8)
  )
)
FSM
    my $output_path = File::Spec->catfile($tempdir, 'shared_datapath_aggregate_enable_cli_top.sv');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, $composition_path],
    );

    ok($success, 'CLI succeeds for shared aggregate-enable summary fixture');
    ok(-e $output_path, 'CLI writes HDL for shared aggregate-enable summary fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/\* aggregate target enable: status_bus_shared_en/s, 'CLI prints the whole-target aggregate enable');
    like($combined_output, qr/\* multi-value conflict: status_bus_multi_value_conflict/s, 'CLI prints the whole-target multi-value conflict name');
    like($combined_output, qr/\* multi-value onehot0 over status_bus__8_d1_shared_en, status_bus__8_d2_shared_en, status_bus__8_d3_shared_en => status_bus_multi_value_conflict/s, 'CLI prints the whole-target onehot0 assertion inputs');
    like($combined_output, qr/\* aggregate value 8'd1 => status_bus__8_d1_shared_en from left\.status_bus\/status_bus__8_d1_en, right\.status_bus\/status_bus__8_d1_en/s, 'CLI prints the same-value aggregate family across both contributors');
    like($combined_output, qr/\* same-value conflict 8'd1 => status_bus__8_d1_multi_src_conflict/s, 'CLI prints the same-value multi-source conflict name');
    like($combined_output, qr/\* same-value onehot0 8'd1 over left_status_bus__8_d1_src_en, right_status_bus__8_d1_src_en => status_bus__8_d1_multi_src_conflict/s, 'CLI prints the same-value onehot0 assertion inputs for shared contributors');
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

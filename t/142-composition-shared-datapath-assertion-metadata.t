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

subtest 'shared-datapath candidates surface source-enable aliases and onehot0 assertion metadata' => sub {
    my $composition_path = write_fsm('shared_datapath_assertion_top.fsm', <<'FSM');
(?top:shared_datapath_assertion_top
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
    my ($shared_value_family) = grep {
        ($_->{rhs_value} || '') eq "8'd1";
    } @{$candidate->{aggregate_enable_families} || []};

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
        'candidate exposes a onehot0-style whole-target assertion over aggregate value enables',
    );

    is_deeply(
        $shared_value_family->{same_value_assertion},
        {
            kind => 'onehot0',
            result_signal => 'status_bus__8_d1_multi_src_conflict',
            input_count => 2,
            input_enable_signals => [
                'left_status_bus__8_d1_src_en',
                'right_status_bus__8_d1_src_en',
            ],
        },
        'shared value family exposes a onehot0-style same-value assertion over contributor source enables',
    );

    is_deeply(
        [
            map { $_->{source_enable_signal} } @{$shared_value_family->{contributors} || []}
        ],
        [
            'left_status_bus__8_d1_src_en',
            'right_status_bus__8_d1_src_en',
        ],
        'shared value family contributors expose deterministic shared-datapath source-enable aliases',
    );
};

subtest 'CLI prints shared-datapath onehot0 assertion planning' => sub {
    my $composition_path = write_fsm('shared_datapath_assertion_cli_top.fsm', <<'FSM');
(?top:shared_datapath_assertion_cli_top
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
    my $output_path = File::Spec->catfile($tempdir, 'shared_datapath_assertion_cli_top.sv');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, $composition_path],
    );

    ok($success, 'CLI succeeds for shared-datapath assertion summary fixture');
    ok(-e $output_path, 'CLI writes HDL for shared-datapath assertion summary fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/\* multi-value onehot0 over status_bus__8_d1_shared_en, status_bus__8_d2_shared_en, status_bus__8_d3_shared_en => status_bus_multi_value_conflict/s, 'CLI prints the whole-target onehot0 planning line');
    like($combined_output, qr/\* same-value onehot0 8'd1 over left_status_bus__8_d1_src_en, right_status_bus__8_d1_src_en => status_bus__8_d1_multi_src_conflict/s, 'CLI prints the shared-value onehot0 planning line');
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

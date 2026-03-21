#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

my $tempdir = tempdir(CLEANUP => 1);

subtest 'composition HDL now emits shared-datapath source-export bindings and aggregate conflict logic' => sub {
    my $composition_path = write_fsm('shared_datapath_runtime_hdl_top.fsm', <<'FSM');
(?top:shared_datapath_runtime_hdl_top
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
    my $hdl = $result->{hdl_code};
    my $left_info = $result->{composition_plan}->instances->[0]->module_info;

    is($left_info->{shared_datapath_source_export_count}, 2, 'realized fsm child reports two shared-datapath source exports');
    is_deeply(
        $left_info->{shared_datapath_source_exports},
        [
            {
                signal_name => 'status_bus',
                rhs_value => "8'd1",
                source_signal => 'status_bus__8_d1_en',
                port_name => 'shared_dp_export_status_bus_8_d1_en',
            },
            {
                signal_name => 'status_bus',
                rhs_value => "8'd2",
                source_signal => 'status_bus__8_d2_en',
                port_name => 'shared_dp_export_status_bus_8_d2_en',
            },
        ],
        'realized child preserves exported shared-datapath source-enable metadata',
    );

    like($hdl, qr/module left_src \([\s\S]*?output\s+wire\s+shared_dp_export_status_bus_8_d1_en/s, 'left child module exposes the first shared-datapath source export port');
    like($hdl, qr/module left_src \([\s\S]*?output\s+wire\s+shared_dp_export_status_bus_8_d2_en/s, 'left child module exposes the second shared-datapath source export port');
    like($hdl, qr/assign shared_dp_export_status_bus_8_d1_en = status_bus__8_d1_en;/s, 'left child module exports the first source-enable signal');
    like($hdl, qr/assign shared_dp_export_status_bus_8_d2_en = status_bus__8_d2_en;/s, 'left child module exports the second source-enable signal');

    like($hdl, qr/left_src left \([\s\S]*?\.shared_dp_export_status_bus_8_d1_en\(left_status_bus__8_d1_src_en\)/s, 'top binds the left child first source-enable export');
    like($hdl, qr/right_src right \([\s\S]*?\.shared_dp_export_status_bus_8_d1_en\(right_status_bus__8_d1_src_en\)/s, 'top binds the right child shared-value source-enable export');

    like($hdl, qr/wire left_status_bus__8_d1_src_en;/s, 'top declares the left source-enable alias net');
    like($hdl, qr/wire right_status_bus__8_d1_src_en;/s, 'top declares the right shared-value source-enable alias net');
    like($hdl, qr/wire status_bus__8_d1_shared_en;/s, 'top declares the shared aggregate enable net');
    like($hdl, qr/wire status_bus__8_d1_multi_src_conflict;/s, 'top declares the same-value conflict wire');
    like($hdl, qr/wire status_bus_multi_value_conflict;/s, 'top declares the whole-target conflict wire');

    like($hdl, qr/assign status_bus__8_d1_shared_en = left_status_bus__8_d1_src_en \| right_status_bus__8_d1_src_en;/s, 'top emits the shared-value aggregate enable logic');
    like($hdl, qr/assign status_bus__8_d1_multi_src_conflict = \(left_status_bus__8_d1_src_en & right_status_bus__8_d1_src_en\);/s, 'top emits the same-value conflict logic');
    like($hdl, qr/assign status_bus_shared_en = status_bus__8_d1_shared_en \| status_bus__8_d2_shared_en \| status_bus__8_d3_shared_en;/s, 'top emits the whole-target aggregate enable logic');
    like(
        $hdl,
        qr/assign status_bus_multi_value_conflict = \(status_bus__8_d1_shared_en & status_bus__8_d2_shared_en\) \| \(status_bus__8_d1_shared_en & status_bus__8_d3_shared_en\) \| \(status_bus__8_d2_shared_en & status_bus__8_d3_shared_en\);/s,
        'top emits the whole-target multi-value conflict logic',
    );
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

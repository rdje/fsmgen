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

subtest 'systemverilog composition tops now emit shared-datapath onehot0 guard assertions' => sub {
    my $composition_path = write_fsm('shared_datapath_assertion_runtime_top.fsm', <<'FSM');
(?top:shared_datapath_assertion_runtime_top
  (?ports:public_io
    clk
    rstn
    select
    left_status>8
    right_status>8
  )
  (?fsmc:left left_src)
  (?fsmc:right right_src)
  (?wiring:wiring
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

    like($hdl, qr/`ifndef SYNTHESIS\s+always_comb begin/s, 'top HDL guards shared-datapath assertions behind a non-synthesis block');
    like(
        $hdl,
        qr/assert \(!status_bus__8_d1_multi_src_conflict\)\s+else \$error\("shared-datapath same-value conflict: status_bus 8'd1"\);/s,
        'top HDL emits the shared-value same-value conflict assertion',
    );
    like(
        $hdl,
        qr/assert \(!status_bus_multi_value_conflict\)\s+else \$error\("shared-datapath multi-value conflict: status_bus"\);/s,
        'top HDL emits the whole-target multi-value conflict assertion',
    );
};

subtest 'verilog composition tops keep shared-datapath assertion emission disabled' => sub {
    my $composition_path = write_fsm('shared_datapath_assertion_runtime_verilog_top.fsm', <<'FSM');
(?top:shared_datapath_assertion_runtime_verilog_top
  (?ports:public_io
    clk
    rstn
    select
    left_status>8
    right_status>8
  )
  (?fsmc:left left_src)
  (?fsmc:right right_src)
  (?wiring:wiring
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
        target_language => 'verilog',
        debug_level => 0,
        quiet => 1,
    );

    my $result = $pipeline->generate_hdl_from_file($composition_path);
    my $hdl = $result->{hdl_code};

    unlike($hdl, qr/`ifndef SYNTHESIS/s, 'verilog top HDL does not emit the shared-datapath assertion guard block');
    unlike($hdl, qr/\bassert\s*\(/s, 'verilog top HDL does not emit SystemVerilog assertion statements');
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

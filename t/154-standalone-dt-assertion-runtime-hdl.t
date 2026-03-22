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

subtest 'standalone dt roots now emit SystemVerilog onehot0 guard assertions for grouped multi-drive targets' => sub {
    my $dt_path = write_fsm('standalone_dt_assertion_runtime.fsm', <<'DT');
(?dt:standalone_dt_assertion_runtime
  (+size
    (SEL 1)
    (A 8)
    (B 8)
    (OUT 8)
  )
  (-from_a
    (<SEL==1'b0
      (OUT = A)
    )
  )
  (-from_b
    (<SEL==1'b1
      (OUT = B)
    )
  )
)
DT

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
    );
    my $result = $pipeline->generate_hdl_from_file($dt_path);
    my $hdl = $result->{hdl_code};

    is(
        $result->{module_info}{standalone_dt_multi_drive_targets}[0]{multi_drive_assertion}{input_count},
        2,
        'module_info records the grouped multi-drive assertion inputs',
    );
    like($hdl, qr/`ifndef SYNTHESIS\s+always_comb begin\s+assert \(\$onehot0\(\{from_a_out_a_en, from_b_out_b_en\}\)\) else \$error\("standalone-dt multi-drive conflict: OUT"\);\s+end\s+`endif/s, 'SystemVerilog HDL emits the standalone dt onehot0 guard assertion');
};

subtest 'Verilog standalone dt output stays free of onehot0 guard assertions' => sub {
    my $dt_path = write_fsm('standalone_dt_assertion_runtime_verilog.fsm', <<'DT');
(?dt:standalone_dt_assertion_runtime_verilog
  (+size
    (SEL 1)
    (A 8)
    (B 8)
    (OUT 8)
  )
  (-from_a
    (<SEL==1'b0
      (OUT = A)
    )
  )
  (-from_b
    (<SEL==1'b1
      (OUT = B)
    )
  )
)
DT

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'verilog',
        debug_level => 0,
        quiet => 1,
    );
    my $result = $pipeline->generate_hdl_from_file($dt_path);
    my $hdl = $result->{hdl_code};

    unlike($hdl, qr/\$onehot0/s, 'Verilog HDL does not emit standalone dt onehot0 assertions');
    unlike($hdl, qr/standalone-dt multi-drive conflict/s, 'Verilog HDL does not emit standalone dt assertion error text');
};

subtest 'realized ?dtc children now emit standalone dt onehot0 guard assertions inside generated composition HDL' => sub {
    my $composition_path = write_fsm('dtc_assertion_runtime_top.fsm', <<'TOP');
(?top:dtc_assertion_runtime_top
  (?ports:public_io
    sel
    data_a<8
    data_b<8
    final_out>8
  )
  (?dtc:router_a route_a)
  (?dtc:router_b route_b)
  (?toplink:wiring
    /sel/router_a.sel/
    /data_a/router_a.a/
    /data_b/router_a.b/
    /router_a.out/router_b.in/
    /router_b.final_out/final_out/
  )
)

(?dt:route_a
  (+size
    (sel 1)
    (a 8)
    (b 8)
    (out 8)
  )
  (-from_a
    (<sel==1'b0
      (out> = a)
    )
  )
  (-from_b
    (<sel==1'b1
      (out> = b)
    )
  )
)

(?dt:route_b
  (+size
    (in 8)
    (final_out 8)
  )
  (-route
    (final_out> = in)
  )
)
TOP

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
    );
    my $result = $pipeline->generate_hdl_from_file($composition_path);
    my $hdl = $result->{hdl_code};

    like($hdl, qr/module route_a \([\s\S]*?assert \(\$onehot0\(\{from_a_out_a_en, from_b_out_b_en\}\)\) else \$error\("standalone-dt multi-drive conflict: out"\);[\s\S]*?endmodule/s, 'composition HDL preserves the standalone dt onehot0 guard assertion inside the realized dt child module');
    unlike($hdl, qr/module route_b \([\s\S]*?standalone-dt multi-drive conflict/s, 'single-drive realized dt child modules do not emit standalone dt guard assertions');
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

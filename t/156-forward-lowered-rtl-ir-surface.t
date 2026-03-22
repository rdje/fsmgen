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

subtest 'direct standalone dt roots now surface a forward lowered_rtl_ir summary' => sub {
    my $dt_path = write_fsm('lowered_rtl_ir_direct_dt.fsm', <<'DT');
(?dt:lowered_rtl_ir_direct_dt
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
    my $lowered_rtl_ir = $result->{lowered_rtl_ir};

    is($lowered_rtl_ir->{module_name}, 'lowered_rtl_ir_direct_dt', 'direct result exposes the module name through lowered_rtl_ir');
    is($lowered_rtl_ir->{source_root_kind}, 'dt', 'direct result exposes the dt root kind through lowered_rtl_ir');
    is($lowered_rtl_ir->{target_language}, 'systemverilog', 'direct result exposes the target language through lowered_rtl_ir');
    is($lowered_rtl_ir->{output_drive_family_count}, 1, 'direct result exposes grouped output-drive-family count through lowered_rtl_ir');
    is($lowered_rtl_ir->{standalone_dt_multi_drive_target_count}, 1, 'direct result exposes grouped standalone-DT shared-target count through lowered_rtl_ir');
    is_deeply(
        [map { $_->{signal_name} } @{$lowered_rtl_ir->{output_drive_families}}],
        ['OUT'],
        'direct result exposes stable output-drive-family signal names through lowered_rtl_ir',
    );
    ok($result->{module_info}{lowered_rtl_ir}, 'module_info preserves the same serialized lowered_rtl_ir summary');
    is_deeply(
        $result->{module_info}{lowered_rtl_ir},
        $lowered_rtl_ir,
        'module_info carries the same serialized forward lowered_rtl_ir surface',
    );
};

subtest 'realized generated children preserve their forward lowered_rtl_ir summary through composition' => sub {
    my $composition_path = write_fsm('lowered_rtl_ir_child_top.fsm', <<'TOP');
(?top:lowered_rtl_ir_child_top
  (?ports:public_io
    clk
    rstn
    select
    data_a<8
    data_b<8
    routed_out>8
  )
  (?fsmc:producer producer_src)
  (?dtc:router route_src)
  (?toplink:wiring
    /select/producer.select/
    /producer.output_data/router.IN_A/
    /data_a/router.A/
    /data_b/router.B/
    /router.OUT/routed_out/
  )
)

(?fsm:producer_src
  (+system
    (clock clk)
    (asreset rstn)
  )
  (+size
    (select 1)
    (output_data 8)
  )
  (-emit_zero
    (<select==1'b0
      (output_data> <= 8'0)
    )
  )
  (-emit_ff
    (<select==1'b1
      (output_data> <= 8'255)
    )
  )
)

(?dt:route_src
  (+size
    (IN_A 8)
    (A 8)
    (B 8)
    (OUT 8)
  )
  (-from_in_a
    (OUT = IN_A)
  )
  (-from_a
    (OUT = A)
  )
  (-from_b
    (OUT = B)
  )
)
TOP

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
    );
    my $result = $pipeline->generate_hdl_from_file($composition_path);
    my ($producer_info, $router_info) = map { $_->module_info } @{$result->{composition_plan}->instances};

    is($producer_info->{lowered_rtl_ir}{module_name}, 'producer_src', 'realized fsm child preserves the source module name in lowered_rtl_ir');
    is($producer_info->{lowered_rtl_ir}{source_root_kind}, 'fsm', 'realized fsm child preserves the fsm root kind in lowered_rtl_ir');
    is($producer_info->{lowered_rtl_ir}{output_drive_family_count}, 1, 'realized fsm child reports one output-drive family in lowered_rtl_ir');
    is($producer_info->{lowered_rtl_ir}{standalone_dt_multi_drive_target_count}, 0, 'realized fsm child keeps standalone-DT grouped targets empty in lowered_rtl_ir');
    is_deeply(
        [map { $_->{signal_name} } @{$producer_info->{lowered_rtl_ir}{output_drive_families}}],
        ['output_data'],
        'realized fsm child preserves output-drive-family signal names in lowered_rtl_ir',
    );

    is($router_info->{lowered_rtl_ir}{module_name}, 'route_src', 'realized dt child preserves the source module name in lowered_rtl_ir');
    is($router_info->{lowered_rtl_ir}{source_root_kind}, 'dt', 'realized dt child preserves the dt root kind in lowered_rtl_ir');
    is($router_info->{lowered_rtl_ir}{output_drive_family_count}, 1, 'realized dt child reports one output-drive family in lowered_rtl_ir');
    is($router_info->{lowered_rtl_ir}{standalone_dt_multi_drive_target_count}, 1, 'realized dt child preserves grouped standalone-DT shared targets in lowered_rtl_ir');
    is_deeply(
        [map { $_->{signal_name} } @{$router_info->{lowered_rtl_ir}{standalone_dt_multi_drive_targets}}],
        ['OUT'],
        'realized dt child preserves grouped standalone-DT target names in lowered_rtl_ir',
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

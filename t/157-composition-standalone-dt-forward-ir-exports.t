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

subtest 'composition standalone-DT child exports now preserve forward intent and lowered IR summaries' => sub {
    my $composition_path = write_fsm('composition_standalone_dt_forward_ir_exports_top.fsm', <<'FSM');
(?top:composition_standalone_dt_forward_ir_exports_top
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
FSM

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
    );

    my $result = $pipeline->generate_hdl_from_file($composition_path);
    my $intent_hir = $result->{intent_hir};
    my ($router_a, $router_b) = @{$result->{module_info}{composition_standalone_dt_children}};

    is_deeply(
        $intent_hir->{composition_standalone_dt_children},
        $result->{module_info}{composition_standalone_dt_children},
        'composition module_info mirrors reusable standalone-DT child exports from intent_hir',
    );

    is($router_a->{intent_hir}{module_name}, 'route_a', 'first exported dt child preserves module name in intent_hir');
    is($router_a->{intent_hir}{source_root_kind}, 'dt', 'first exported dt child preserves dt root kind in intent_hir');
    is($router_a->{intent_hir}{standalone_dt_count}, 2, 'first exported dt child preserves standalone block count in intent_hir');
    is_deeply(
        $router_a->{intent_hir}{standalone_dt_enable_families},
        [
            { dt_name => '-from_a', enable_signal => 'from_a_en' },
            { dt_name => '-from_b', enable_signal => 'from_b_en' },
        ],
        'first exported dt child preserves standalone dt enable families in intent_hir',
    );
    is($router_a->{lowered_rtl_ir}{module_name}, 'route_a', 'first exported dt child preserves module name in lowered_rtl_ir');
    is($router_a->{lowered_rtl_ir}{source_root_kind}, 'dt', 'first exported dt child preserves dt root kind in lowered_rtl_ir');
    is($router_a->{lowered_rtl_ir}{output_drive_family_count}, 1, 'first exported dt child preserves output-drive family count in lowered_rtl_ir');
    is($router_a->{lowered_rtl_ir}{standalone_dt_multi_drive_target_count}, 1, 'first exported dt child preserves grouped shared-target count in lowered_rtl_ir');
    is($router_a->{structural_rtl_ir}{module_name}, 'route_a', 'first exported dt child preserves module name in structural_rtl_ir');
    is($router_a->{structural_rtl_ir}{port_count}, 4, 'first exported dt child preserves module boundary port count in structural_rtl_ir');
    is_deeply(
        [sort map { $_->{name} } @{$router_a->{structural_rtl_ir}{ports}}],
        [qw(a b out sel)],
        'first exported dt child preserves module boundary port names in structural_rtl_ir',
    );

    is($router_b->{intent_hir}{module_name}, 'route_b', 'second exported dt child preserves module name in intent_hir');
    is($router_b->{intent_hir}{standalone_dt_count}, 1, 'second exported dt child preserves standalone block count in intent_hir');
    is($router_b->{lowered_rtl_ir}{module_name}, 'route_b', 'second exported dt child preserves module name in lowered_rtl_ir');
    is($router_b->{lowered_rtl_ir}{output_drive_family_count}, 1, 'second exported dt child preserves output-drive family count in lowered_rtl_ir');
    is($router_b->{lowered_rtl_ir}{standalone_dt_multi_drive_target_count}, 0, 'second exported dt child preserves empty grouped shared-target count in lowered_rtl_ir');
    is($router_b->{structural_rtl_ir}{module_name}, 'route_b', 'second exported dt child preserves module name in structural_rtl_ir');
    is($router_b->{structural_rtl_ir}{port_count}, 2, 'second exported dt child preserves module boundary port count in structural_rtl_ir');
    is_deeply(
        [sort map { $_->{name} } @{$router_b->{structural_rtl_ir}{ports}}],
        [qw(final_out in)],
        'second exported dt child preserves module boundary port names in structural_rtl_ir',
    );
    is($intent_hir->{composition_standalone_dt_child_count}, 2, 'composition intent_hir reports realized standalone-DT child count');
    is($intent_hir->{composition_standalone_dt_block_count}, 3, 'composition intent_hir reports aggregated standalone-DT block count');
    is($intent_hir->{composition_standalone_dt_multi_drive_target_count}, 1, 'composition intent_hir reports aggregated standalone-DT grouped shared-target count');
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

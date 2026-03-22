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

subtest 'composition tops now surface forward intent_hir and lowered_rtl_ir summaries' => sub {
    my $composition_path = write_fsm('composition_top_forward_ir_surface.fsm', <<'FSM');
(?top:composition_top_forward_ir_surface
  (?ports:public_io
    clk
    rstn
    select
    data_a<8
    data_b<8
    result_data>8
  )
  (?fsmc:producer producer_src)
  (?dtc:router route_src)
  (?toplink:wiring
    /select/producer.select/
    /producer.output_data/router.IN_A/
    /data_a/router.A/
    /data_b/router.B/
    /router.OUT/result_data/
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
  (IDLE
    (<select==1'b0
      (output_data> <= 8'1)
    )
  )
  (ACTIVE
    (<select==1'b1
      (output_data> <= 8'2)
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
FSM

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
    );

    my $result = $pipeline->generate_hdl_from_file($composition_path);
    my $intent_hir = $result->{intent_hir};
    my $lowered_rtl_ir = $result->{lowered_rtl_ir};
    my $structural_rtl_ir = $result->{structural_rtl_ir};
    my $module_info = $result->{module_info};

    ok($intent_hir, 'composition top now exposes a top-level intent_hir summary');
    ok($lowered_rtl_ir, 'composition top now exposes a top-level lowered_rtl_ir summary');
    ok($structural_rtl_ir, 'composition top now exposes a top-level structural_rtl_ir summary');
    is_deeply(
        $module_info->{intent_hir},
        $intent_hir,
        'composition module_info preserves the same serialized intent_hir summary',
    );
    is_deeply(
        $module_info->{lowered_rtl_ir},
        $lowered_rtl_ir,
        'composition module_info preserves the same serialized lowered_rtl_ir summary',
    );

    is($intent_hir->{module_name}, 'composition_top_forward_ir_surface', 'composition intent_hir preserves the top module name');
    is($intent_hir->{source_root_kind}, 'top', 'composition intent_hir reports the top root kind');
    is_deeply(
        $intent_hir->{signal_names},
        ['clk', 'rstn', 'select', 'data_a', 'data_b', 'result_data'],
        'composition intent_hir preserves top-port signal names',
    );
    is($intent_hir->{signal_count}, 6, 'composition intent_hir reports top-port count');
    is($intent_hir->{composition_child_count}, 2, 'composition intent_hir reports realized child count');
    is($intent_hir->{composition_generated_child_count}, 2, 'composition intent_hir reports realized generated child count');
    is($intent_hir->{composition_generated_fsm_child_count}, 1, 'composition intent_hir reports realized generated fsm child count');
    is($intent_hir->{composition_generated_dt_child_count}, 1, 'composition intent_hir reports realized generated dt child count');
    is_deeply(
        [map { $_->{instance_name} } @{$intent_hir->{composition_generated_children}}],
        ['producer', 'router'],
        'composition intent_hir preserves realized generated child export order',
    );
    is_deeply(
        $intent_hir->{composition_generated_children},
        $module_info->{composition_generated_children},
        'composition module_info mirrors the broader generated-child export from intent_hir',
    );
    is($intent_hir->{composition_standalone_dt_child_count}, 1, 'composition intent_hir reports reusable standalone-DT child count');
    is($intent_hir->{composition_standalone_dt_block_count}, 3, 'composition intent_hir reports reusable standalone-DT block count');
    is($intent_hir->{composition_standalone_dt_multi_drive_target_count}, 1, 'composition intent_hir reports reusable standalone-DT grouped shared-target count');
    is_deeply(
        [map { $_->{instance_name} } @{$intent_hir->{composition_standalone_dt_children}}],
        ['router'],
        'composition intent_hir preserves reusable standalone-DT child export order',
    );
    is_deeply(
        $intent_hir->{composition_standalone_dt_children},
        $module_info->{composition_standalone_dt_children},
        'composition module_info mirrors the reusable standalone-DT child export from intent_hir',
    );
    is($intent_hir->{composition_lane}, 'C2', 'composition intent_hir preserves the composition lane');
    is($intent_hir->{regular_state_count}, 0, 'composition intent_hir keeps top roots separate from regular FSM state counts');
    is($intent_hir->{standalone_dt_count}, 0, 'composition intent_hir keeps top roots separate from standalone-DT counts');

    is($lowered_rtl_ir->{module_name}, 'composition_top_forward_ir_surface', 'composition lowered_rtl_ir preserves the top module name');
    is($lowered_rtl_ir->{source_root_kind}, 'top', 'composition lowered_rtl_ir reports the top root kind');
    is($lowered_rtl_ir->{target_language}, 'systemverilog', 'composition lowered_rtl_ir preserves the target language');
    is($lowered_rtl_ir->{output_drive_family_count}, 0, 'composition lowered_rtl_ir keeps grouped child output-drive families separate at this slice');
    is($lowered_rtl_ir->{standalone_dt_multi_drive_target_count}, 0, 'composition lowered_rtl_ir keeps grouped child standalone-DT shared targets separate at this slice');
    is($lowered_rtl_ir->{composition_shared_datapath_candidate_count}, 0, 'composition lowered_rtl_ir reports zero shared-datapath candidates when no bounded multi-fsm family exists');
    is_deeply(
        $lowered_rtl_ir->{composition_shared_datapath_candidates},
        [],
        'composition lowered_rtl_ir preserves an explicit empty shared-datapath candidate list in that case',
    );
    is($lowered_rtl_ir->{internal_net_count}, 1, 'composition lowered_rtl_ir reports internal composition net count');
    is_deeply(
        $lowered_rtl_ir->{internal_net_names},
        ['comp_link_producer_output_data'],
        'composition lowered_rtl_ir preserves internal composition net names',
    );
    is($lowered_rtl_ir->{instance_count}, 2, 'composition lowered_rtl_ir reports realized instance count');
    is_deeply(
        $lowered_rtl_ir->{instance_names},
        ['producer', 'router'],
        'composition lowered_rtl_ir preserves realized instance names',
    );
    is($lowered_rtl_ir->{auxiliary_assignment_count}, 0, 'composition lowered_rtl_ir reports auxiliary assignment count');
    is(
        $lowered_rtl_ir->{internal_net_count},
        $structural_rtl_ir->{net_count},
        'composition lowered_rtl_ir now derives internal net count from structural_rtl_ir',
    );
    is_deeply(
        $lowered_rtl_ir->{internal_net_names},
        [map { $_->{name} } @{$structural_rtl_ir->{nets}}],
        'composition lowered_rtl_ir now derives internal net names from structural_rtl_ir',
    );
    is(
        $lowered_rtl_ir->{instance_count},
        $structural_rtl_ir->{instance_count},
        'composition lowered_rtl_ir now derives instance count from structural_rtl_ir',
    );
    is_deeply(
        $lowered_rtl_ir->{instance_names},
        [map { $_->{instance_name} } @{$structural_rtl_ir->{instances}}],
        'composition lowered_rtl_ir now derives instance names from structural_rtl_ir',
    );
    is(
        $lowered_rtl_ir->{auxiliary_assignment_count},
        $structural_rtl_ir->{auxiliary_assignment_count},
        'composition lowered_rtl_ir now derives auxiliary assignment count from structural_rtl_ir',
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

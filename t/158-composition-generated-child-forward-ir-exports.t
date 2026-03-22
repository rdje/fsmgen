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

subtest 'composition tops now export forward IR summaries for realized generated children' => sub {
    my $composition_path = write_fsm('composition_generated_child_forward_ir_exports_top.fsm', <<'FSM');
(?top:composition_generated_child_forward_ir_exports_top
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
    my $module_info = $result->{module_info};
    my ($producer_instance, $router_instance) = @{$result->{composition_plan}->instances};
    my ($producer_export, $router_export) = @{$module_info->{composition_generated_children}};

    is($module_info->{composition_generated_child_count}, 2, 'top module_info counts realized generated children');
    is($module_info->{composition_generated_fsm_child_count}, 1, 'top module_info counts realized generated fsm children');
    is($module_info->{composition_generated_dt_child_count}, 1, 'top module_info counts realized generated dt children');
    is_deeply(
        [map { $_->{instance_name} } @{$module_info->{composition_generated_children}}],
        ['producer', 'router'],
        'top module_info preserves realized generated child order',
    );
    is($intent_hir->{composition_generated_child_count}, 2, 'top intent_hir counts realized generated children');
    is($intent_hir->{composition_generated_fsm_child_count}, 1, 'top intent_hir counts realized generated fsm children');
    is($intent_hir->{composition_generated_dt_child_count}, 1, 'top intent_hir counts realized generated dt children');
    is_deeply(
        [map { $_->{instance_name} } @{$intent_hir->{composition_generated_children}}],
        ['producer', 'router'],
        'top intent_hir preserves realized generated child order',
    );
    is_deeply(
        $intent_hir->{composition_generated_children},
        $module_info->{composition_generated_children},
        'top module_info mirrors the broader generated-child export from intent_hir',
    );

    is($producer_export->{kind}, 'fsmc', 'first exported generated child keeps its composition kind');
    is($producer_export->{source_root_kind}, 'fsm', 'first exported generated child keeps its source root kind');
    is($producer_export->{regular_state_count}, 2, 'first exported generated child reports regular-state count');
    is($producer_export->{output_drive_family_count}, 1, 'first exported generated child reports output-drive family count');
    is_deeply(
        $producer_export->{intent_hir},
        $producer_instance->module_info->{intent_hir},
        'first exported generated child preserves the same intent_hir as its realized module_info',
    );
    is_deeply(
        $producer_export->{lowered_rtl_ir},
        $producer_instance->module_info->{lowered_rtl_ir},
        'first exported generated child preserves the same lowered_rtl_ir as its realized module_info',
    );

    is($router_export->{kind}, 'dtc', 'second exported generated child keeps its composition kind');
    is($router_export->{source_root_kind}, 'dt', 'second exported generated child keeps its source root kind');
    is($router_export->{standalone_dt_count}, 3, 'second exported generated child reports standalone-DT block count');
    is($router_export->{output_drive_family_count}, 1, 'second exported generated child reports output-drive family count');
    is($router_export->{standalone_dt_multi_drive_target_count}, 1, 'second exported generated child reports grouped standalone-DT shared-target count');
    is_deeply(
        $router_export->{intent_hir},
        $router_instance->module_info->{intent_hir},
        'second exported generated child preserves the same intent_hir as its realized module_info',
    );
    is_deeply(
        $router_export->{lowered_rtl_ir},
        $router_instance->module_info->{lowered_rtl_ir},
        'second exported generated child preserves the same lowered_rtl_ir as its realized module_info',
    );
};

subtest 'CLI prints a concise generated child summary from the exported forward IR surface' => sub {
    my $composition_path = write_fsm('composition_generated_child_forward_ir_exports_cli_top.fsm', <<'FSM');
(?top:composition_generated_child_forward_ir_exports_cli_top
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
    my $output_path = File::Spec->catfile($tempdir, 'composition_generated_child_forward_ir_exports_cli_top.sv');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, $composition_path],
    );

    ok($success, 'CLI succeeds for generated child export summary fixture');
    ok(-e $output_path, 'CLI writes HDL for generated child export summary fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/Generated Children:/s, 'CLI prints generated child summary header');
    like($combined_output, qr/Count:\s+2/s, 'CLI reports realized generated child count');
    like($combined_output, qr/FSM children:\s+1/s, 'CLI reports realized generated fsm child count');
    like($combined_output, qr/Standalone-DT children:\s+1/s, 'CLI reports realized generated dt child count');
    like($combined_output, qr/producer => producer_src \(kind: \?fsmc, root: \?fsm, source: producer_src, states: 2, output drive families: 1\)/s, 'CLI prints the exported generated fsm child summary');
    like($combined_output, qr/router => route_src \(kind: \?dtc, root: \?dt, source: route_src, blocks: 3, output drive families: 1, grouped shared targets: 1\)/s, 'CLI prints the exported generated dt child summary');
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

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

subtest 'composition tops now export unified forward child summaries across generated and rtl children' => sub {
    my $composition_path = write_fsm('composition_child_forward_ir_exports_top.fsm', <<'FSM');
(?top:composition_child_forward_ir_exports_top
  (?ports:public_io
    trigger
    serial_out>
  )
  (?dtc:producer producer_src)
  (?rtl:uart_tx)
  (?toplink:wiring
    /trigger/producer.trigger/
    /producer.serial_payload/uart_tx.data_in/
    /uart_tx.serial_out/serial_out/
  )
)

(?dt:producer_src
  (-route
    (<trigger
      (serial_payload> = 8'1)
    )
    (<!trigger
      (serial_payload> = 8'0)
    )
  )
  (+size
    (trigger 1)
    (serial_payload 8)
  )
)

(?rtlif:uart_tx
  core_clk:clock
  rst_async_n:reset
  data_in<8:data
  serial_out>:data
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
    my $structural_rtl_ir = $result->{structural_rtl_ir};
    my $report = $result->{composition_report};
    my ($producer_instance, $uart_tx_instance) = @{$result->{composition_plan}->instances};
    my ($producer_export, $uart_tx_export) = @{$module_info->{composition_children}};
    my ($input_override) = grep {
        ($_->{kind} || '') eq 'explicit_toplink_overrides_same_name_top_input_convention'
    } @{$report->{override_events} || []};
    my ($output_override) = grep {
        ($_->{kind} || '') eq 'explicit_toplink_overrides_same_name_top_output_convention'
    } @{$report->{override_events} || []};

    is($intent_hir->{composition_child_count}, 2, 'top intent_hir counts all realized children');
    is($module_info->{composition_child_count}, 2, 'top module_info counts all realized children');
    is_deeply(
        [map { $_->{instance_name} } @{$intent_hir->{composition_children}}],
        ['producer', 'uart_tx'],
        'top intent_hir preserves unified realized child order',
    );
    is_deeply(
        [map { $_->{kind} } @{$intent_hir->{composition_children}}],
        ['dtc', 'rtl'],
        'top intent_hir preserves unified realized child kinds',
    );
    is_deeply(
        [map { $_->{source_root_kind} } @{$intent_hir->{composition_children}}],
        ['dt', 'rtl'],
        'top intent_hir preserves unified realized child root kinds',
    );
    is_deeply(
        $intent_hir->{composition_children},
        $module_info->{composition_children},
        'top module_info mirrors the unified realized child export from intent_hir',
    );
    is_deeply(
        [
            map {
                +{
                    kind => $_->{kind},
                    instance_name => $_->{instance_name},
                    module_name => $_->{module_name},
                    source_name => $_->{source_name},
                }
            } @{$module_info->{composition_children}}
        ],
        [
            map {
                +{
                    kind => $_->{kind},
                    instance_name => $_->{instance_name},
                    module_name => $_->{module_name},
                    source_name => ($_->{source_name} // $_->{module_name}),
                }
            } @{$structural_rtl_ir->{instances}}
        ],
        'unified child export now derives child identity and order from structural_rtl_ir instances',
    );

    is($producer_export->{kind}, 'dtc', 'generated dt child keeps its composition kind in the unified export');
    is($producer_export->{source_name}, 'producer_src', 'generated dt child keeps its source name in the unified export');
    is($producer_export->{source_root_kind}, 'dt', 'generated dt child keeps its source root kind in the unified export');
    is_deeply(
        $producer_export->{intent_hir},
        $producer_instance->module_info->{intent_hir},
        'generated dt child preserves the same intent_hir as its realized module_info',
    );
    is_deeply(
        $producer_export->{lowered_rtl_ir},
        $producer_instance->module_info->{lowered_rtl_ir},
        'generated dt child preserves the same lowered_rtl_ir as its realized module_info',
    );
    is_deeply(
        $producer_export->{structural_rtl_ir},
        $producer_instance->module_info->{structural_rtl_ir},
        'generated dt child preserves the same structural_rtl_ir as its realized module_info',
    );

    is($uart_tx_export->{kind}, 'rtl', 'rtl child keeps its composition kind in the unified export');
    is($uart_tx_export->{module_name}, 'uart_tx', 'rtl child keeps its module name in the unified export');
    is($uart_tx_export->{source_name}, 'uart_tx', 'rtl child now keeps a stable source identity in the unified export');
    is($uart_tx_export->{source_root_kind}, 'rtl', 'rtl child keeps its source root kind in the unified export');
    is_deeply($uart_tx_export->{intent_hir}, {}, 'rtl child keeps an explicit empty intent_hir summary until a richer rtl semantic layer exists');
    is_deeply($uart_tx_export->{lowered_rtl_ir}, {}, 'rtl child keeps an explicit empty lowered_rtl_ir summary until a richer rtl lowered layer exists');
    is_deeply($uart_tx_export->{structural_rtl_ir}, {}, 'rtl child keeps an explicit empty structural_rtl_ir summary until a richer rtl structural layer exists');

    is_deeply(
        $input_override->{target_context}{intent_hir},
        $producer_export->{intent_hir},
        'override reporting now reuses the unified child export semantic context for generated children',
    );
    is(
        $output_override->{source_context}{source_root_kind},
        $uart_tx_export->{source_root_kind},
        'override reporting now reuses the unified child export root-kind context for rtl children',
    );
    is(
        $output_override->{source_context}{module_name},
        $uart_tx_export->{module_name},
        'override reporting now reuses the unified child export module identity for rtl children',
    );
    is(
        $output_override->{source_context}{source_name},
        $uart_tx_export->{source_name},
        'override reporting now reuses the unified child export source identity for rtl children',
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

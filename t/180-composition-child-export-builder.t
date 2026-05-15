#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Composition::ChildExportBuilder;
use FSM::Pipeline::HDLGenerator;

my $tempdir = tempdir(CLEANUP => 1);

subtest 'composition child export builder owns unified and narrowed child export surfaces' => sub {
    my $composition_path = write_fsm('composition_child_export_builder_top.fsm', <<'FSM');
(?top:composition_child_export_builder_top
  (?ports:public_io
    trigger
    serial_out>
  )
  (?dtc:producer producer_src)
  (?rtl:uart_tx)
  (?wiring:wiring
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
    my $child_exports = FSM::Composition::ChildExportBuilder->build_child_exports(
        composition_plan => $result->{composition_plan},
        structural_rtl_ir => $result->{structural_rtl_ir},
        target_language => 'systemverilog',
    );
    my $generated_child_exports = FSM::Composition::ChildExportBuilder->build_generated_child_exports(
        composition_child_exports => $child_exports,
    );
    my $standalone_dt_child_exports = FSM::Composition::ChildExportBuilder->build_standalone_dt_child_exports(
        composition_child_exports => $child_exports,
    );

    is_deeply(
        $child_exports,
        {
            child_count => $result->{module_info}{composition_child_count},
            children => $result->{module_info}{composition_children},
        },
        'builder now owns the unified composition child export surface',
    );
    is_deeply(
        $generated_child_exports,
        {
            child_count => $result->{module_info}{composition_generated_child_count},
            fsm_child_count => $result->{module_info}{composition_generated_fsm_child_count},
            dt_child_count => $result->{module_info}{composition_generated_dt_child_count},
            children => $result->{module_info}{composition_generated_children},
        },
        'builder now owns the narrowed generated-child export surface',
    );
    is_deeply(
        $standalone_dt_child_exports,
        {
            child_count => $result->{module_info}{composition_standalone_dt_child_count},
            block_count => $result->{module_info}{composition_standalone_dt_block_count},
            multi_drive_target_count => $result->{module_info}{composition_standalone_dt_multi_drive_target_count},
            children => $result->{module_info}{composition_standalone_dt_children},
        },
        'builder now owns the narrowed standalone-dt child export surface',
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

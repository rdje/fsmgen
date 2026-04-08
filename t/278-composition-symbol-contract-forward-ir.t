#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;
use FSM::Pipeline::GeneratedModuleInfoBuilder;

subtest 'composition tops preserve a bounded symbol contract through intent_hir and module_info' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'composition_symbol_contract_forward_ir.fsm');

    write_file(
        $composition_path,
        <<'FSM'
(?top:composition_symbol_contract_forward_ir
  (+import shared_external)
  (+types
    (type byte_t (bits 8))
    (type flag_t bit)
  )
  (+constants
    (BYTES (8'hA5 8'h3C 0))
    (FRAME ((mode 3) (flag 1)))
  )
  (+enums
    (mode
      (IDLE 0)
      (BUSY 1)
    )
  )
  (?ports:public_io
    choose
    result_data>8
  )
  (?dtc:producer producer_src)
  (?dtc:router route_src)
  (?toplink:wiring
    /choose/producer.choose/
    /=BYTES[1]/producer.local_seed/
    /=shared_external.RESET_BYTE/producer.package_seed/
    /producer.output_data/router.IN_A/
    /=BYTES[0]/router.B/
    /choose/router.SELECT/
    /router.OUT/result_data/
  )
)

(?dt:producer_src
  (+size
    (choose 1)
    (local_seed 8)
    (package_seed 8)
    (output_data 8)
  )
  (-from_local
    (<choose
      (output_data> = local_seed)
    )
  )
  (-from_package
    (<!choose
      (output_data> = package_seed)
    )
  )
)

(?dt:route_src
  (+size
    (IN_A 8)
    (B 8)
    (SELECT 1)
    (OUT 8)
  )
  (-from_input
    (<SELECT
      (OUT = IN_A)
    )
  )
  (-from_b
    (<!SELECT
      (OUT = B)
    )
  )
)

(?pkg:shared_external
  (+constants
    (RESET_BYTE 8'h5A)
    (FRAME ((mode 3) (flag 1)))
  )
  (+enums
    (wire_mode
      (IDLE 0)
      (BUSY 1)
    )
  )
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        quiet => 1,
        target_language => 'systemverilog',
    );
    my $result = $pipeline->generate_hdl_from_file($composition_path);
    my $intent_hir = $result->{intent_hir};
    my $module_info = $result->{module_info};
    my $symbol_contract = $intent_hir->{symbol_contract};

    ok($symbol_contract, 'composition intent_hir preserves a symbol contract payload');
    is($symbol_contract->{constant_count}, 2, 'symbol contract counts declared local constant roots');
    is_deeply($symbol_contract->{constant_names}, ['BYTES', 'FRAME'], 'symbol contract preserves stable local constant names');
    is($symbol_contract->{enum_count}, 1, 'symbol contract counts declared local enums');
    is_deeply($symbol_contract->{enum_names}, ['mode'], 'symbol contract preserves stable local enum names');
    is($symbol_contract->{type_count}, 2, 'symbol contract counts declared local types');
    is_deeply($symbol_contract->{type_names}, ['byte_t', 'flag_t'], 'symbol contract preserves stable local type names');
    is($symbol_contract->{types}{byte_t}{width}, 8, 'symbol contract preserves canonical scalar type widths');
    is($symbol_contract->{types}{flag_t}{width}, 1, 'symbol contract preserves bit-like scalar type widths');
    is($symbol_contract->{constants}{FRAME}{kind}, 'map', 'symbol contract preserves aggregate constant payload shape');
    is_deeply($symbol_contract->{constants}{FRAME}{member_order}, ['mode', 'flag'], 'symbol contract preserves authored aggregate member order');
    is($symbol_contract->{constants}{FRAME}{members}{flag}{payload}, '1', 'symbol contract preserves nested aggregate scalar payloads');
    is($symbol_contract->{constant_scalar_leaves}{'BYTES[1]'}, "8'h3C", 'symbol contract exposes scalar-leaf convenience payloads');
    is($symbol_contract->{constant_scalar_leaves}{'FRAME.flag'}, '1', 'symbol contract exposes aggregate member scalar leaves');
    is_deeply(
        $symbol_contract->{constant_aggregate_paths},
        ['BYTES', 'FRAME'],
        'symbol contract exposes stable aggregate root paths',
    );
    is($symbol_contract->{enums}{mode}{BUSY}, '1', 'symbol contract preserves canonical enum member payloads');
    is($symbol_contract->{package_import_count}, 1, 'symbol contract counts imported packages');
    is_deeply($symbol_contract->{package_imports}, ['shared_external'], 'symbol contract preserves imported package names');

    is_deeply(
        $module_info->{symbol_contract},
        $symbol_contract,
        'module_info mirrors the same composition-top symbol contract surface',
    );
    is_deeply(
        FSM::Pipeline::GeneratedModuleInfoBuilder->intent_hir_from_module_info($module_info)->{symbol_contract},
        $symbol_contract,
        'module-info query path also preserves the same composition-top symbol contract surface',
    );
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

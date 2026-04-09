#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Composition::SharedDatapathCandidateBuilder;
use FSM::Pipeline::HDLGenerator;

subtest 'shared-datapath candidate builder rebuilds the bounded candidate surface from explicit inputs' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'composition_shared_dp_candidate_builder_top.fsm');

    write_file(
        $composition_path,
        <<'FSM'
(?top:composition_shared_dp_candidate_builder_top
  (?ports:public_io
    clk
    rstn
    left_status>8
    right_status>8
  )
  (?fsmc:left left_src)
  (?fsmc:right right_src)
  (?toplink:wiring
    /left.status_bus/left_status/
    /right.status_bus/right_status/
  )
)

(?fsm:left_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (IDLE
    (status_bus> <= 8'1)
  )
  (+size
    (status_bus 8)
  )
)

(?fsm:right_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (IDLE
    (status_bus> <= 8'2)
  )
  (+size
    (status_bus 8)
  )
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
    );

    my $result = $pipeline->generate_hdl_from_file($composition_path);
    my $rebuilt_candidates = FSM::Composition::SharedDatapathCandidateBuilder->candidates_for_plan(
        composition_plan => $result->{composition_plan},
        structural_rtl_ir => $result->{structural_rtl_ir},
        intent_hir => $result->{intent_hir},
        target_language => 'systemverilog',
    );

    is_deeply(
        $rebuilt_candidates,
        $result->{module_info}{composition_shared_datapath_candidates},
        'builder returns the same bounded shared-datapath candidate surface already attached to the realized composition plan',
    );
};

subtest 'shared-datapath candidate builder preserves one uniform declared type contract across typed contributors' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $libdir = File::Spec->catdir($tempdir, 'pkg_lib');
    mkdir $libdir or die "Cannot create $libdir: $!";

    my $package_path = File::Spec->catfile($libdir, 'shared_types.fsm');
    my $composition_path = File::Spec->catfile($tempdir, 'composition_shared_dp_typed_candidate_top.fsm');

    write_file(
        $package_path,
        <<'FSM'
(?pkg:shared_types
  (+types
    (type byte_t (four_state (signed (bits 8))))
  )
)
FSM
    );

    write_file(
        $composition_path,
        <<'FSM'
(?top:composition_shared_dp_typed_candidate_top
  (?ports:public_io
    clk
    rstn
    left_status>8
    right_status>8
  )
  (?fsmc:left left_src)
  (?fsmc:right right_src)
  (?toplink:wiring
    /left.status_bus/left_status/
    /right.status_bus/right_status/
  )
)

(?fsm:left_src
  (+import shared_types)
  (+system
    (clock clk)
    (sreset rstn)
  )
  (IDLE
    (status_bus> <= 8'1)
  )
  (+size
    (status_bus shared_types.byte_t)
  )
)

(?fsm:right_src
  (+import shared_types)
  (+system
    (clock clk)
    (sreset rstn)
  )
  (IDLE
    (status_bus> <= 8'2)
  )
  (+size
    (status_bus shared_types.byte_t)
  )
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
        source_search_paths => [$libdir],
    );

    my $result = $pipeline->generate_hdl_from_file($composition_path);
    my $candidate = $result->{module_info}{composition_shared_datapath_candidates}[0];

    is($result->{module_info}{composition_shared_datapath_candidate_count}, 1, 'typed width-equal contributors still form one shared-datapath candidate');
    is($candidate->{declared_type_name}, 'shared_types.byte_t', 'shared-datapath candidate preserves the uniform declared type name');
    is($candidate->{declared_type_spec}{width}, 8, 'shared-datapath candidate preserves the uniform declared type width');
    is($candidate->{declared_type_spec}{signed}, 1, 'shared-datapath candidate preserves the uniform declared type signedness');
    is($candidate->{contributors}[0]{declared_type_name}, 'shared_types.byte_t', 'candidate contributor metadata preserves the typed child output name');
    is($candidate->{contributors}[1]{declared_type_spec}{state_model}, 'four_state', 'candidate contributor metadata preserves the typed child output state model');
};

subtest 'shared-datapath candidate builder refuses one family when typed contributors disagree on declared type contract' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $libdir = File::Spec->catdir($tempdir, 'pkg_lib');
    mkdir $libdir or die "Cannot create $libdir: $!";

    my $package_path = File::Spec->catfile($libdir, 'shared_types.fsm');
    my $composition_path = File::Spec->catfile($tempdir, 'composition_shared_dp_typed_conflict_top.fsm');

    write_file(
        $package_path,
        <<'FSM'
(?pkg:shared_types
  (+types
    (type signed_byte_t (four_state (signed (bits 8))))
    (type plain_byte_t (bits 8))
  )
)
FSM
    );

    write_file(
        $composition_path,
        <<'FSM'
(?top:composition_shared_dp_typed_conflict_top
  (?ports:public_io
    clk
    rstn
    left_status>8
    right_status>8
  )
  (?fsmc:left left_src)
  (?fsmc:right right_src)
  (?toplink:wiring
    /left.status_bus/left_status/
    /right.status_bus/right_status/
  )
)

(?fsm:left_src
  (+import shared_types)
  (+system
    (clock clk)
    (sreset rstn)
  )
  (IDLE
    (status_bus> <= 8'1)
  )
  (+size
    (status_bus shared_types.signed_byte_t)
  )
)

(?fsm:right_src
  (+import shared_types)
  (+system
    (clock clk)
    (sreset rstn)
  )
  (IDLE
    (status_bus> <= 8'2)
  )
  (+size
    (status_bus shared_types.plain_byte_t)
  )
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
        source_search_paths => [$libdir],
    );

    my $result = $pipeline->generate_hdl_from_file($composition_path);

    is($result->{module_info}{composition_shared_datapath_candidate_count}, 0, 'typed contributors with incompatible declared contracts do not collapse into one shared-datapath family');
    is_deeply($result->{module_info}{composition_shared_datapath_candidates}, [], 'shared-datapath candidate metadata stays empty for the conflicting typed family');
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

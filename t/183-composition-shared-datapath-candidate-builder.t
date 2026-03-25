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

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

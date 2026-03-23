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

subtest 'shared-datapath candidate contributors now preserve forward child IR summaries' => sub {
    my $composition_path = write_fsm('shared_datapath_forward_ir_exports_top.fsm', <<'FSM');
(?top:shared_datapath_forward_ir_exports_top
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

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
    );

    my $result = $pipeline->generate_hdl_from_file($composition_path);
    my ($left_instance, $right_instance) = @{$result->{composition_plan}->instances};
    my %children_by_instance = map {
        (($_->{instance_name}) => $_)
    } @{$result->{intent_hir}{composition_children} || []};
    my $lowered_rtl_ir = $result->{lowered_rtl_ir};
    my $candidate = $result->{module_info}{composition_shared_datapath_candidates}[0];
    my ($left_contributor, $right_contributor) = @{$candidate->{contributors}};

    is($lowered_rtl_ir->{composition_shared_datapath_candidate_count}, 1, 'composition top lowered_rtl_ir reports one shared-datapath candidate family');
    is_deeply(
        $lowered_rtl_ir->{composition_shared_datapath_candidates},
        $result->{module_info}{composition_shared_datapath_candidates},
        'composition top lowered_rtl_ir preserves the same shared-datapath candidate surface as module_info',
    );

    is($left_contributor->{kind}, 'fsmc', 'first contributor preserves generated child kind');
    is($left_contributor->{source_name}, 'left_src', 'first contributor preserves generated child source name');
    is_deeply(
        $left_contributor->{intent_hir},
        $left_instance->module_info->{intent_hir},
        'first contributor preserves the same intent_hir as its realized child module_info',
    );
    is_deeply(
        $left_contributor->{lowered_rtl_ir},
        $left_instance->module_info->{lowered_rtl_ir},
        'first contributor preserves the same lowered_rtl_ir as its realized child module_info',
    );
    is_deeply(
        $left_contributor->{structural_rtl_ir},
        $left_instance->module_info->{structural_rtl_ir},
        'first contributor preserves the same structural_rtl_ir as its realized child module_info',
    );
    is_deeply(
        $left_contributor->{output_drive_family},
        $left_instance->module_info->{lowered_rtl_ir}{output_drive_families}[0],
        'first contributor preserves the exact selected output_drive_family from its child lowered_rtl_ir',
    );
    is_deeply(
        $left_contributor->{intent_hir},
        $children_by_instance{left}{intent_hir},
        'first contributor now also matches the unified composition_children intent_hir export',
    );
    is_deeply(
        $left_contributor->{lowered_rtl_ir},
        $children_by_instance{left}{lowered_rtl_ir},
        'first contributor now also matches the unified composition_children lowered_rtl_ir export',
    );
    is_deeply(
        $left_contributor->{structural_rtl_ir},
        $children_by_instance{left}{structural_rtl_ir},
        'first contributor now also matches the unified composition_children structural_rtl_ir export',
    );

    is($right_contributor->{kind}, 'fsmc', 'second contributor preserves generated child kind');
    is($right_contributor->{source_name}, 'right_src', 'second contributor preserves generated child source name');
    is_deeply(
        $right_contributor->{intent_hir},
        $right_instance->module_info->{intent_hir},
        'second contributor preserves the same intent_hir as its realized child module_info',
    );
    is_deeply(
        $right_contributor->{lowered_rtl_ir},
        $right_instance->module_info->{lowered_rtl_ir},
        'second contributor preserves the same lowered_rtl_ir as its realized child module_info',
    );
    is_deeply(
        $right_contributor->{structural_rtl_ir},
        $right_instance->module_info->{structural_rtl_ir},
        'second contributor preserves the same structural_rtl_ir as its realized child module_info',
    );
    is_deeply(
        $right_contributor->{output_drive_family},
        $right_instance->module_info->{lowered_rtl_ir}{output_drive_families}[0],
        'second contributor preserves the exact selected output_drive_family from its child lowered_rtl_ir',
    );
    is_deeply(
        $right_contributor->{intent_hir},
        $children_by_instance{right}{intent_hir},
        'second contributor now also matches the unified composition_children intent_hir export',
    );
    is_deeply(
        $right_contributor->{lowered_rtl_ir},
        $children_by_instance{right}{lowered_rtl_ir},
        'second contributor now also matches the unified composition_children lowered_rtl_ir export',
    );
    is_deeply(
        $right_contributor->{structural_rtl_ir},
        $children_by_instance{right}{structural_rtl_ir},
        'second contributor now also matches the unified composition_children structural_rtl_ir export',
    );
};

subtest 'CLI prints contributor context from shared-datapath forward child IR exports' => sub {
    my $composition_path = write_fsm('shared_datapath_forward_ir_exports_cli_top.fsm', <<'FSM');
(?top:shared_datapath_forward_ir_exports_cli_top
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
    my $output_path = File::Spec->catfile($tempdir, 'shared_datapath_forward_ir_exports_cli_top.sv');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $output_path, $composition_path],
    );

    ok($success, 'CLI succeeds for shared-datapath forward IR export summary fixture');
    ok(-e $output_path, 'CLI writes HDL for shared-datapath forward IR export summary fixture');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/Shared-Datapath Candidates:/s, 'CLI prints shared-datapath candidate summary header');
    like($combined_output, qr/\* contributor context: left\.status_bus => \?fsm \(states: 1, output drive families: 1, source: left_src\)/s, 'CLI prints first contributor forward-IR context');
    like($combined_output, qr/\* contributor context: right\.status_bus => \?fsm \(states: 1, output drive families: 1, source: right_src\)/s, 'CLI prints second contributor forward-IR context');
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

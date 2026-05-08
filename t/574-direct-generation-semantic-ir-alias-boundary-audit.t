#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

subtest 'direct generation separates top-level semantic IR projections from module_info mirrors' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_semantic_ir_alias_top.fsm');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_semantic_ir_alias_top
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (OUT 1)
  )
  (idle
    (= (OUT 0))
  )
)
FSM
    );

    my $result = generate_result($fsm_path);
    for my $key (qw(intent_hir lowered_rtl_ir structural_rtl_ir)) {
        is_deeply(
            $result->{$key},
            $result->{module_info}{$key},
            "$key starts equivalent to its module_info mirror",
        );
    }

    $result->{intent_hir}{module_name} = 'mutated_top_level_intent';
    $result->{lowered_rtl_ir}{module_name} = 'mutated_top_level_lowered';
    $result->{structural_rtl_ir}{module_name} = 'mutated_top_level_structural';

    is(
        $result->{module_info}{intent_hir}{module_name},
        'direct_semantic_ir_alias_top',
        'mutating top-level intent_hir does not contaminate module_info intent_hir',
    );
    is(
        $result->{module_info}{lowered_rtl_ir}{module_name},
        'direct_semantic_ir_alias_top',
        'mutating top-level lowered_rtl_ir does not contaminate module_info lowered_rtl_ir',
    );
    is(
        $result->{module_info}{structural_rtl_ir}{module_name},
        'direct_semantic_ir_alias_top',
        'mutating top-level structural_rtl_ir does not contaminate module_info structural_rtl_ir',
    );

    my $second_result = generate_result($fsm_path);
    $second_result->{module_info}{intent_hir}{module_name} = 'mutated_module_info_intent';
    $second_result->{module_info}{lowered_rtl_ir}{module_name} = 'mutated_module_info_lowered';
    $second_result->{module_info}{structural_rtl_ir}{module_name} = 'mutated_module_info_structural';

    is(
        $second_result->{intent_hir}{module_name},
        'direct_semantic_ir_alias_top',
        'mutating module_info intent_hir does not contaminate top-level intent_hir',
    );
    is(
        $second_result->{lowered_rtl_ir}{module_name},
        'direct_semantic_ir_alias_top',
        'mutating module_info lowered_rtl_ir does not contaminate top-level lowered_rtl_ir',
    );
    is(
        $second_result->{structural_rtl_ir}{module_name},
        'direct_semantic_ir_alias_top',
        'mutating module_info structural_rtl_ir does not contaminate top-level structural_rtl_ir',
    );
};

done_testing();

sub generate_result {
    my ($path) = @_;
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );
    return $pipeline->generate_hdl_from_file($path);
}

sub write_file {
    my ($path, $contents) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $contents or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

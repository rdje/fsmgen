#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use Scalar::Util qw(refaddr);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

subtest 'composition generation separates module_info summary projections from embedded intent_hir mirrors' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'composition_module_info_forward_ir_alias_top.fsm');
    write_file(
        $composition_path,
        <<'FSM'
(?top:composition_module_info_forward_ir_alias_top
  (?ports:public_io
    clk
    rstn
    select
    output_data>8
  )
  (?fsmc:producer producer_src)
)

(?fsm:producer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (select 1)
    (output_data 8)
  )
  (IDLE
    (<select==1'b0
      (<= (output_data> 8'1))
    )
  )
)
FSM
    );

    my $result = generate_result($composition_path);
    my $module_info = $result->{module_info};

    for my $key (qw(signal_analysis composition_children composition_generated_children)) {
        is_deeply(
            $module_info->{$key},
            $module_info->{intent_hir}{$key},
            "$key starts equivalent to its embedded intent_hir mirror",
        );
        isnt(
            refaddr($module_info->{$key}),
            refaddr($module_info->{intent_hir}{$key}),
            "$key does not reuse its embedded intent_hir container",
        );
    }

    $module_info->{signal_analysis}{outputs}[0]{name} = 'mutated_summary_output';
    $module_info->{composition_children}[0]{intent_hir}{module_name} = 'mutated_summary_child';
    $module_info->{composition_generated_children}[0]{lowered_rtl_ir}{output_drive_families}[0]{signal_name}
        = 'mutated_summary_generated_child';

    is(
        $module_info->{intent_hir}{signal_analysis}{outputs}[0]{name},
        'output_data',
        'mutating module_info signal_analysis summary does not contaminate embedded intent_hir signal_analysis',
    );
    is(
        $module_info->{intent_hir}{composition_children}[0]{intent_hir}{module_name},
        'producer_src',
        'mutating module_info composition_children summary does not contaminate embedded intent_hir composition_children',
    );
    is(
        $module_info->{intent_hir}{composition_generated_children}[0]{lowered_rtl_ir}{output_drive_families}[0]{signal_name},
        'output_data',
        'mutating module_info generated-child summary does not contaminate embedded intent_hir generated children',
    );

    my $second_result = generate_result($composition_path);
    my $second_module_info = $second_result->{module_info};
    $second_module_info->{intent_hir}{signal_analysis}{outputs}[0]{name} = 'mutated_embedded_output';
    $second_module_info->{intent_hir}{composition_children}[0]{intent_hir}{module_name}
        = 'mutated_embedded_child';
    $second_module_info->{intent_hir}{composition_generated_children}[0]{lowered_rtl_ir}{output_drive_families}[0]{signal_name}
        = 'mutated_embedded_generated_child';

    is(
        $second_module_info->{signal_analysis}{outputs}[0]{name},
        'output_data',
        'mutating embedded intent_hir signal_analysis does not contaminate module_info signal_analysis summary',
    );
    is(
        $second_module_info->{composition_children}[0]{intent_hir}{module_name},
        'producer_src',
        'mutating embedded intent_hir composition_children does not contaminate module_info composition_children summary',
    );
    is(
        $second_module_info->{composition_generated_children}[0]{lowered_rtl_ir}{output_drive_families}[0]{signal_name},
        'output_data',
        'mutating embedded intent_hir generated children does not contaminate module_info generated-child summary',
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

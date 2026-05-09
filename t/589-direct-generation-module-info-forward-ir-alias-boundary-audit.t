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

subtest 'direct generation separates module_info forward summaries from embedded intent_hir mirrors' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_module_info_forward_ir_alias_top.fsm');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_module_info_forward_ir_alias_top
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (input_data 8)
    (output_data 8)
  )
  (idle
    (<input_data==8'hA5
      (<= (output_data> 8'1))
    )
  )
)
FSM
    );

    my $result = generate_result($fsm_path);
    my $module_info = $result->{module_info};

    for my $key (qw(signal_analysis signal_names)) {
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
    $module_info->{signal_names}[0] = 'mutated_summary_signal_name';

    is(
        $module_info->{intent_hir}{signal_analysis}{outputs}[0]{name},
        'output_data',
        'mutating module_info signal_analysis summary does not contaminate embedded intent_hir signal_analysis',
    );
    is(
        $module_info->{intent_hir}{signal_names}[0],
        'input_data',
        'mutating module_info signal_names summary does not contaminate embedded intent_hir signal_names',
    );

    my $second_result = generate_result($fsm_path);
    my $second_module_info = $second_result->{module_info};
    $second_module_info->{intent_hir}{signal_analysis}{outputs}[0]{name} = 'mutated_embedded_output';
    $second_module_info->{intent_hir}{signal_names}[0] = 'mutated_embedded_signal_name';

    is(
        $second_module_info->{signal_analysis}{outputs}[0]{name},
        'output_data',
        'mutating embedded intent_hir signal_analysis does not contaminate module_info signal_analysis summary',
    );
    is(
        $second_module_info->{signal_names}[0],
        'input_data',
        'mutating embedded intent_hir signal_names does not contaminate module_info signal_names summary',
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

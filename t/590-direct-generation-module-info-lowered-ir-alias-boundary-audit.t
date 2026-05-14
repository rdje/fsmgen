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

subtest 'direct generation separates module_info lowered summaries from embedded lowered_rtl_ir mirrors' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_module_info_lowered_ir_alias_top.fsm');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_module_info_lowered_ir_alias_top
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (output_data 8)
  )
  (idle
    (<= (output_data> 8'1))
  )
)
FSM
    );

    my $result = generate_result($fsm_path);
    my $module_info = $result->{module_info};

    for my $key (qw(output_drive_families selector_conflict_targets standalone_dt_multi_drive_targets)) {
        is_deeply(
            $module_info->{$key},
            $module_info->{lowered_rtl_ir}{$key},
            "$key starts equivalent to its embedded lowered_rtl_ir mirror",
        );
        isnt(
            refaddr($module_info->{$key}),
            refaddr($module_info->{lowered_rtl_ir}{$key}),
            "$key does not reuse its embedded lowered_rtl_ir container",
        );
    }

    $module_info->{output_drive_families}[0]{signal_name} = 'mutated_summary_output';
    push @{$module_info->{standalone_dt_multi_drive_targets}}, {
        signal_name => 'mutated_summary_dt_target',
    };
    push @{$module_info->{selector_conflict_targets}}, {
        signal_name => 'mutated_summary_selector_target',
    };

    is(
        $module_info->{lowered_rtl_ir}{output_drive_families}[0]{signal_name},
        'output_data',
        'mutating module_info output_drive_families summary does not contaminate embedded lowered_rtl_ir output_drive_families',
    );
    is_deeply(
        $module_info->{lowered_rtl_ir}{standalone_dt_multi_drive_targets},
        [],
        'mutating module_info standalone_dt_multi_drive_targets summary does not contaminate embedded lowered_rtl_ir targets',
    );
    is_deeply(
        $module_info->{lowered_rtl_ir}{selector_conflict_targets},
        [],
        'mutating module_info selector_conflict_targets summary does not contaminate embedded lowered_rtl_ir targets',
    );

    my $second_result = generate_result($fsm_path);
    my $second_module_info = $second_result->{module_info};
    $second_module_info->{lowered_rtl_ir}{output_drive_families}[0]{signal_name} = 'mutated_embedded_output';
    push @{$second_module_info->{lowered_rtl_ir}{standalone_dt_multi_drive_targets}}, {
        signal_name => 'mutated_embedded_dt_target',
    };
    push @{$second_module_info->{lowered_rtl_ir}{selector_conflict_targets}}, {
        signal_name => 'mutated_embedded_selector_target',
    };

    is(
        $second_module_info->{output_drive_families}[0]{signal_name},
        'output_data',
        'mutating embedded lowered_rtl_ir output_drive_families does not contaminate module_info output_drive_families summary',
    );
    is_deeply(
        $second_module_info->{standalone_dt_multi_drive_targets},
        [],
        'mutating embedded lowered_rtl_ir standalone_dt_multi_drive_targets does not contaminate module_info summary targets',
    );
    is_deeply(
        $second_module_info->{selector_conflict_targets},
        [],
        'mutating embedded lowered_rtl_ir selector_conflict_targets does not contaminate module_info summary targets',
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

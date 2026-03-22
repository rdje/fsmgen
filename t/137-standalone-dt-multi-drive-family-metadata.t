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

subtest 'standalone dt roots surface grouped multi-drive target metadata' => sub {
    my $dt_path = write_fsm('standalone_dt_multi_drive_metadata.fsm', <<'DT');
(?dt:standalone_dt_multi_drive_metadata
  (+size
    (SEL 1)
    (A 8)
    (B 8)
    (OUT 8)
  )
  (-from_a
    (<SEL==1'b0
      (OUT = A)
    )
  )
  (-from_b
    (<SEL==1'b1
      (OUT = B)
    )
  )
)
DT

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
    );
    my $result = $pipeline->generate_hdl_from_file($dt_path);

    is($result->{module_info}{standalone_dt_multi_drive_target_count}, 1, 'module_info reports one grouped multi-drive target');
    is_deeply(
        $result->{module_info}{standalone_dt_multi_drive_targets},
        [
            {
                signal_name => 'OUT',
                multiplexer_type => 'comb',
                dt_names => ['-from_a', '-from_b'],
                rhs_values => ['A', 'B'],
                dt_enable_signals => ['from_a_out_a_en', 'from_b_out_b_en'],
                lhs_enable_signals => ['out_a_en', 'out_b_en'],
                multi_drive_assertion => {
                    kind => 'onehot0',
                    target_signal => 'OUT',
                    input_count => 2,
                    input_enable_signals => ['from_a_out_a_en', 'from_b_out_b_en'],
                },
            },
        ],
        'module_info reports the grouped multi-drive target family with dt names, rhs values, and enable-signal families',
    );
};

subtest 'realized ?dtc children preserve grouped multi-drive target metadata' => sub {
    my $composition_path = write_fsm('dtc_multi_drive_metadata_top.fsm', <<'TOP');
(?top:dtc_multi_drive_metadata_top
  (?dtc:router route_src)
)

(?dt:route_src
  (+size
    (SEL 1)
    (A 8)
    (B 8)
    (OUT 8)
  )
  (-from_a
    (<SEL==1'b0
      (OUT = A)
    )
  )
  (-from_b
    (<SEL==1'b1
      (OUT = B)
    )
  )
)
TOP

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
    );
    my $result = $pipeline->generate_hdl_from_file($composition_path);
    my $child_info = $result->{composition_plan}->instances->[0]->module_info;

    is($child_info->{standalone_dt_multi_drive_target_count}, 1, 'realized dt child reports one grouped multi-drive target');
    is_deeply(
        $child_info->{standalone_dt_multi_drive_targets},
        [
            {
                signal_name => 'OUT',
                multiplexer_type => 'comb',
                dt_names => ['-from_a', '-from_b'],
                rhs_values => ['A', 'B'],
                dt_enable_signals => ['from_a_out_a_en', 'from_b_out_b_en'],
                lhs_enable_signals => ['out_a_en', 'out_b_en'],
                multi_drive_assertion => {
                    kind => 'onehot0',
                    target_signal => 'OUT',
                    input_count => 2,
                    input_enable_signals => ['from_a_out_a_en', 'from_b_out_b_en'],
                },
            },
        ],
        'realized dt child preserves grouped multi-drive target metadata through composition',
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

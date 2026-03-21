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

subtest 'standalone dt roots surface block-level and module-level enable families in module_info' => sub {
    my $dt_path = write_fsm('standalone_dt_enable_metadata.fsm', <<'DT');
(?dt:standalone_dt_enable_metadata
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

    is($result->{module_info}{standalone_dt_count}, 2, 'module_info reports two standalone dt blocks');
    is_deeply(
        $result->{module_info}{standalone_dt_names},
        ['-from_a', '-from_b'],
        'module_info reports standalone dt block names as plain scalars',
    );
    is_deeply(
        $result->{module_info}{standalone_dt_enable_families},
        [
            { dt_name => '-from_a', enable_signal => 'from_a_en' },
            { dt_name => '-from_b', enable_signal => 'from_b_en' },
        ],
        'module_info reports stable per-block enable-signal families for standalone dt roots',
    );
    is_deeply(
        $result->{module_info}{standalone_dt_module_enable_family},
        {
            dt_names => ['-from_a', '-from_b'],
            enable_signals => ['from_a_en', 'from_b_en'],
        },
        'module_info groups the block enables into one module-level standalone dt family summary',
    );
};

subtest 'realized ?dtc children preserve standalone dt enable-family metadata' => sub {
    my $composition_path = write_fsm('dtc_enable_family_metadata_top.fsm', <<'TOP');
(?top:dtc_enable_family_metadata_top
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

    is($result->{composition_plan}->instances->[0]->instance_name, 'router', 'composition still keeps the declared dt child instance name');
    is($child_info->{standalone_dt_count}, 2, 'realized dt child module_info reports two standalone dt blocks');
    is_deeply(
        $child_info->{standalone_dt_enable_families},
        [
            { dt_name => '-from_a', enable_signal => 'from_a_en' },
            { dt_name => '-from_b', enable_signal => 'from_b_en' },
        ],
        'realized dt child preserves standalone dt enable-family metadata through composition',
    );
    is_deeply(
        $child_info->{standalone_dt_module_enable_family},
        {
            dt_names => ['-from_a', '-from_b'],
            enable_signals => ['from_a_en', 'from_b_en'],
        },
        'realized dt child preserves the module-level standalone dt enable family summary',
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

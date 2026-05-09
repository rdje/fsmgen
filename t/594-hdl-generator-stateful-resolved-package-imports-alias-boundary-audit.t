#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

subtest 'stateful facade reuse returns fresh resolved_package_imports maps per generation' => sub {
    my $fsm_path = write_package_import_fixture();
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $first = $pipeline->generate_hdl_from_file($fsm_path);
    is(
        ref($first->{resolved_package_imports}{shared_local}),
        'FSM::Package::Spec',
        'first generation returns the raw package spec map',
    );

    $first->{resolved_package_imports}{shared_local} = 'mutated_spec_entry';
    $first->{resolved_package_imports}{mutated_import} = 'mutated_extra_entry';

    my $second = $pipeline->generate_hdl_from_file($fsm_path);
    is_deeply(
        [sort keys %{$second->{resolved_package_imports}}],
        [qw(shared_local)],
        'later generation on the same facade does not inherit caller-added package imports',
    );
    is(
        ref($second->{resolved_package_imports}{shared_local}),
        'FSM::Package::Spec',
        'later generation on the same facade does not inherit caller-replaced package spec entries',
    );
};

done_testing();

sub write_package_import_fixture {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'stateful_resolved_package_imports_alias_top.fsm');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:stateful_resolved_package_imports_alias_top
  (+import shared_local)
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (OUT 8)
  )
  (idle
    (OUT = shared_local.RESET_BYTE)
  )
)

(?pkg:shared_local
  (+constants
    (RESET_BYTE 8'hA5)
  )
)
FSM
    );
    return $fsm_path;
}

sub write_file {
    my ($path, $contents) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $contents or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

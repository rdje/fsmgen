#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

subtest 'stateful facade reuse returns fresh external resolved package specs per generation' => sub {
    my $fixture = write_external_package_fixture();
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
        source_search_paths => [$fixture->{libdir}],
    );

    my $first = $pipeline->generate_hdl_from_file($fixture->{fsm_path});
    is(
        $first->{resolved_package_imports}{shared_external}->symbols->resolve_actual_payload('RESET_BYTE'),
        "8'hA5",
        'first generation resolves the expected external package constant',
    );

    $first->{resolved_package_imports}{shared_external}{name} = 'mutated_shared_external';
    $first->{resolved_package_imports}{shared_external}{symbols}{constants}{RESET_BYTE}{payload} = "8'h00";
    $first->{resolved_package_imports}{shared_external}{raw_ast}[0] = '?pkg:mutated_shared_external';

    my $second = $pipeline->generate_hdl_from_file($fixture->{fsm_path});
    is(
        $second->{resolved_package_imports}{shared_external}->name,
        'shared_external',
        'later generation on the same facade does not inherit caller mutation of external package name',
    );
    is(
        $second->{resolved_package_imports}{shared_external}->symbols->resolve_actual_payload('RESET_BYTE'),
        "8'hA5",
        'later generation on the same facade does not inherit caller mutation of external package symbols',
    );
    is(
        $second->{resolved_package_imports}{shared_external}->raw_ast->[0],
        '?pkg:shared_external',
        'later generation on the same facade does not inherit caller mutation of external package raw AST',
    );
};

done_testing();

sub write_external_package_fixture {
    my $tempdir = tempdir(CLEANUP => 1);
    my $libdir = File::Spec->catdir($tempdir, 'pkg_lib');
    mkdir $libdir or die "Cannot create $libdir: $!";

    my $fsm_path = File::Spec->catfile($tempdir, 'stateful_external_resolved_package_spec_alias_top.fsm');
    my $package_path = File::Spec->catfile($libdir, 'shared_external.fsm');
    write_file(
        $package_path,
        <<'FSM'
(?pkg:shared_external
  (+constants
    (RESET_BYTE 8'hA5)
  )
)
FSM
    );
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:stateful_external_resolved_package_spec_alias_top
  (+import shared_external)
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (OUT 8)
  )
  (idle
    (OUT = shared_external.RESET_BYTE)
  )
)
FSM
    );

    return {
        fsm_path => $fsm_path,
        libdir => $libdir,
    };
}

sub write_file {
    my ($path, $contents) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $contents or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

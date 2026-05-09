#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

subtest 'stateful facade reuse returns fresh resolved package specs per generation' => sub {
    my $fsm_path = write_package_import_fixture();
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $first = $pipeline->generate_hdl_from_file($fsm_path);
    is(
        $first->{resolved_package_imports}{shared_local}->symbols->resolve_actual_payload('RESET_BYTE'),
        "8'hA5",
        'first generation resolves the expected package constant',
    );

    $first->{resolved_package_imports}{shared_local}{name} = 'mutated_shared_local';
    $first->{resolved_package_imports}{shared_local}{symbols}{constants}{RESET_BYTE}{payload} = "8'h00";
    $first->{resolved_package_imports}{shared_local}{raw_ast}[0] = '?pkg:mutated_shared_local';

    my $second = $pipeline->generate_hdl_from_file($fsm_path);
    is(
        $second->{resolved_package_imports}{shared_local}->name,
        'shared_local',
        'later generation on the same facade does not inherit caller mutation of package name',
    );
    is(
        $second->{resolved_package_imports}{shared_local}->symbols->resolve_actual_payload('RESET_BYTE'),
        "8'hA5",
        'later generation on the same facade does not inherit caller mutation of package symbols',
    );
    is(
        $second->{resolved_package_imports}{shared_local}->raw_ast->[0],
        '?pkg:shared_local',
        'later generation on the same facade does not inherit caller mutation of package raw AST',
    );
};

done_testing();

sub write_package_import_fixture {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'stateful_resolved_package_spec_alias_top.fsm');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:stateful_resolved_package_spec_alias_top
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

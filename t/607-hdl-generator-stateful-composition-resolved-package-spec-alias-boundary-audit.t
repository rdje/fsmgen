#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

subtest 'stateful facade reuse returns fresh composition resolved package specs per generation' => sub {
    my $composition_path = write_composition_fixture();
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $first = $pipeline->generate_hdl_from_file($composition_path);
    is(
        $first->{resolved_package_imports}{shared_local}->symbols->resolve_actual_payload('mode.BUSY'),
        1,
        'first top-level composition result resolves the expected package enum value',
    );
    is(
        $first->{source_info}{resolved_package_imports}{shared_local}->symbols->resolve_actual_payload('mode.BUSY'),
        1,
        'first source_info composition result resolves the expected package enum value',
    );

    $first->{resolved_package_imports}{shared_local}{name} = 'mutated_top_level_package';
    $first->{resolved_package_imports}{shared_local}{symbols}{enums}{mode}{BUSY} = 9;
    $first->{resolved_package_imports}{shared_local}{raw_ast}[0] = '?pkg:mutated_top_level_package';
    $first->{source_info}{resolved_package_imports}{shared_local}{name} = 'mutated_source_info_package';
    $first->{source_info}{resolved_package_imports}{shared_local}{symbols}{enums}{mode}{BUSY} = 7;
    $first->{source_info}{resolved_package_imports}{shared_local}{raw_ast}[0] = '?pkg:mutated_source_info_package';

    my $second = $pipeline->generate_hdl_from_file($composition_path);
    is(
        $second->{resolved_package_imports}{shared_local}->name,
        'shared_local',
        'later generation on the same facade does not inherit top-level package name mutation',
    );
    is(
        $second->{resolved_package_imports}{shared_local}->symbols->resolve_actual_payload('mode.BUSY'),
        1,
        'later generation on the same facade does not inherit top-level package symbol mutation',
    );
    is(
        $second->{source_info}{resolved_package_imports}{shared_local}->name,
        'shared_local',
        'later generation on the same facade does not inherit source_info package name mutation',
    );
    is(
        $second->{source_info}{resolved_package_imports}{shared_local}->symbols->resolve_actual_payload('mode.BUSY'),
        1,
        'later generation on the same facade does not inherit source_info package symbol mutation',
    );
    is(
        $second->{source_info}{resolved_package_imports}{shared_local}->raw_ast->[0],
        '?pkg:shared_local',
        'later generation on the same facade rebuilds the source_info package raw AST',
    );
};

done_testing();

sub write_composition_fixture {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'stateful_composition_resolved_spec_alias_top.fsm');
    write_file(
        $composition_path,
        <<'FSM'
(?top:stateful_composition_resolved_spec_alias_top
  (+import shared_local)
  (?ports:public_io
    shared_flag>
  )
  (?rtl:uart_tx)
  (?toplink:wiring
    /=shared_local.mode.BUSY/shared_flag/
    /=shared_local.mode.BUSY/uart_tx.enable/
  )
)

(?pkg:shared_local
  (+enums
    (mode
      (IDLE 0)
      (BUSY 1)
    )
  )
)

(?rtlif:uart_tx
  enable<1:data
)
FSM
    );
    return $composition_path;
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

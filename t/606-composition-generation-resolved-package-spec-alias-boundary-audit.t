#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

subtest 'composition generation separates resolved package spec object mirrors' => sub {
    my $composition_path = write_composition_fixture();

    my $result = generate_result($composition_path);
    is(
        $result->{resolved_package_imports}{shared_local}->symbols->resolve_actual_payload('mode.BUSY'),
        1,
        'top-level resolved imports expose the expected package enum value',
    );
    is(
        $result->{source_info}{resolved_package_imports}{shared_local}->symbols->resolve_actual_payload('mode.BUSY'),
        1,
        'source_info resolved imports expose the expected package enum value',
    );

    $result->{resolved_package_imports}{shared_local}{name} = 'mutated_top_level_package';
    $result->{resolved_package_imports}{shared_local}{symbols}{enums}{mode}{BUSY} = 9;
    $result->{resolved_package_imports}{shared_local}{raw_ast}[0] = '?pkg:mutated_top_level_package';

    is(
        $result->{source_info}{resolved_package_imports}{shared_local}->name,
        'shared_local',
        'mutating top-level package spec name does not contaminate source_info package spec',
    );
    is(
        $result->{source_info}{resolved_package_imports}{shared_local}->symbols->resolve_actual_payload('mode.BUSY'),
        1,
        'mutating top-level package spec symbols does not contaminate source_info package spec',
    );
    is(
        $result->{source_info}{resolved_package_imports}{shared_local}->raw_ast->[0],
        '?pkg:shared_local',
        'mutating top-level package spec raw AST does not contaminate source_info package spec',
    );

    my $second_result = generate_result($composition_path);
    $second_result->{source_info}{resolved_package_imports}{shared_local}{name}
        = 'mutated_source_info_package';
    $second_result->{source_info}{resolved_package_imports}{shared_local}{symbols}{enums}{mode}{BUSY}
        = 7;
    $second_result->{source_info}{resolved_package_imports}{shared_local}{raw_ast}[0]
        = '?pkg:mutated_source_info_package';

    is(
        $second_result->{resolved_package_imports}{shared_local}->name,
        'shared_local',
        'mutating source_info package spec name does not contaminate top-level package spec',
    );
    is(
        $second_result->{resolved_package_imports}{shared_local}->symbols->resolve_actual_payload('mode.BUSY'),
        1,
        'mutating source_info package spec symbols does not contaminate top-level package spec',
    );
    is(
        $second_result->{resolved_package_imports}{shared_local}->raw_ast->[0],
        '?pkg:shared_local',
        'mutating source_info package spec raw AST does not contaminate top-level package spec',
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

sub write_composition_fixture {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'composition_resolved_spec_alias_top.fsm');
    write_file(
        $composition_path,
        <<'FSM'
(?top:composition_resolved_spec_alias_top
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

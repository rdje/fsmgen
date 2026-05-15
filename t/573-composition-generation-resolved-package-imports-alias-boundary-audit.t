#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

subtest 'composition generation separates top-level resolved_package_imports from source_info payloads' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'composition_resolved_import_alias_top.fsm');
    write_file(
        $composition_path,
        <<'FSM'
(?top:composition_resolved_import_alias_top
  (+import shared_local)
  (?ports:public_io
    shared_flag>
  )
  (?rtl:uart_tx)
  (?wiring:wiring
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

    my $result = generate_result($composition_path);
    is(
        ref($result->{resolved_package_imports}{shared_local}),
        'FSM::Package::Spec',
        'top-level result carries a resolved package spec',
    );
    is(
        ref($result->{source_info}{resolved_package_imports}{shared_local}),
        'FSM::Package::Spec',
        'source_info payload carries its own resolved package spec entry',
    );

    $result->{resolved_package_imports}{shared_local} = 'mutated_top_level_result_branch';
    is(
        ref($result->{source_info}{resolved_package_imports}{shared_local}),
        'FSM::Package::Spec',
        'mutating top-level resolved_package_imports does not contaminate source_info resolved imports',
    );

    my $second_result = generate_result($composition_path);
    $second_result->{source_info}{resolved_package_imports}{shared_local} = 'mutated_source_info_branch';
    is(
        ref($second_result->{resolved_package_imports}{shared_local}),
        'FSM::Package::Spec',
        'mutating source_info resolved imports does not contaminate top-level resolved_package_imports',
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
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

subtest 'stateful facade reuse returns fresh composition resolved package import maps per generation' => sub {
    my $composition_path = write_composition_fixture();
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $first = $pipeline->generate_hdl_from_file($composition_path);
    is_deeply(
        [sort keys %{$first->{resolved_package_imports}}],
        [qw(shared_local)],
        'first top-level composition result has the expected resolved import map',
    );
    is_deeply(
        [sort keys %{$first->{source_info}{resolved_package_imports}}],
        [qw(shared_local)],
        'first source_info composition result has the expected resolved import map',
    );

    $first->{resolved_package_imports}{shared_local} = 'mutated_top_level_entry';
    $first->{resolved_package_imports}{mutated_top_level_import} = 'mutated_top_level_extra';
    $first->{source_info}{resolved_package_imports}{shared_local} = 'mutated_source_info_entry';
    $first->{source_info}{resolved_package_imports}{mutated_source_info_import} = 'mutated_source_info_extra';

    my $second = $pipeline->generate_hdl_from_file($composition_path);
    is_deeply(
        [sort keys %{$second->{resolved_package_imports}}],
        [qw(shared_local)],
        'later generation on the same facade does not inherit top-level resolved import map mutation',
    );
    is(
        ref($second->{resolved_package_imports}{shared_local}),
        'FSM::Package::Spec',
        'later generation on the same facade does not inherit top-level resolved import entry replacement',
    );
    is_deeply(
        [sort keys %{$second->{source_info}{resolved_package_imports}}],
        [qw(shared_local)],
        'later generation on the same facade does not inherit source_info resolved import map mutation',
    );
    is(
        ref($second->{source_info}{resolved_package_imports}{shared_local}),
        'FSM::Package::Spec',
        'later generation on the same facade does not inherit source_info resolved import entry replacement',
    );
};

done_testing();

sub write_composition_fixture {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'stateful_composition_resolved_import_map_alias_top.fsm');
    write_file(
        $composition_path,
        <<'FSM'
(?top:stateful_composition_resolved_import_map_alias_top
  (+import shared_local)
  (?ports:public_io
    OUT>8
  )
  (?rtl:uart_tx)
  (?toplink:wiring
    /=shared_local.RESET_BYTE/OUT/
    /=shared_local.RESET_BYTE/uart_tx.data_in/
  )
)

(?pkg:shared_local
  (+constants
    (RESET_BYTE 8'hA5)
  )
)

(?rtlif:uart_tx
  data_in<8:data
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
